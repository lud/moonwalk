defmodule Moonwalk.Schema.BooleanSchema do
  defstruct [:value]

  def of(true) do
    %__MODULE__{value: true}
  end

  def of(false) do
    %__MODULE__{value: false}
  end
end

defmodule Moonwalk.Schema.Builder do
  alias Moonwalk.Schema.BooleanSchema
  alias Moonwalk.Schema.Ref
  alias Moonwalk.Schema.RNS
  alias Moonwalk.Schema.Resolver
  alias Moonwalk.Schema.Resolver.Resolved
  alias Moonwalk.Helpers

  @derive {Inspect, only: [:resolver, :staged]}
  defstruct [:resolver, staged: [], vocabularies: nil, ns: nil]

  # defimpl Inspect do
  #   def inspect(t, _) do
  #     "#Builder<>"
  #   end
  # end

  def new(opts) do
    struct!(__MODULE__, Map.new(opts))
  end

  def stage_build(%{staged: staged} = bld, buildable)
      when is_binary(buildable)
      when is_struct(buildable, Ref)
      when buildable == :root do
    key = to_build_key(buildable)
    {key, %__MODULE__{bld | staged: append_unique(staged, buildable)}}
  end

  defp to_build_key(binary) when is_binary(binary) do
    binary
  end

  defp to_build_key(%Ref{} = ref) do
    Ref.to_key(ref)
  end

  defp to_build_key(:root) do
    :root
  end

  defp to_build_key({:anchor, _, _} = k) do
    k
  end

  defp append_unique([key | t], key) do
    append_unique(t, key)
  end

  defp append_unique([h | t], key) do
    [h | append_unique(t, key)]
  end

  defp append_unique([], key) do
    [key]
  end

  defp take_staged(%{staged: []} = bld) do
    :empty
  end

  defp take_staged(%{staged: [h | t]} = bld) do
    {h, %__MODULE__{bld | staged: t}}
  end

  # * all_validators represent the map of schema_id_or_ref => validators for
  #   this schema
  # * schema validators is the validators corresponding to one schema document
  # * mod_validators are the created validators from part of a schema
  #   keywords+values and a vocabulary module

  def build_all(bld) do
    build_all(bld, %{})
  end

  defp build_all(bld, all_validators) do
    case take_staged(bld) do
      :empty ->
        {:ok, all_validators}

      {buildable, bld} ->
        vkey = validator_key(buildable)

        if is_map_key(all_validators, vkey) do
          build_all(bld, all_validators)
        else
          with {:ok, schema_validators, %__MODULE__{} = bld} <- build_schema_validators(bld, buildable) do
            build_all(bld, Map.put(all_validators, vkey, schema_validators))
          else
            {:error, _} = err -> err
          end
        end
    end
  end

  defp build_schema_validators(%__MODULE__{} = bld, resolvable) do
    with {:ok, %Resolver{} = resolver} <- Resolver.resolve(bld.resolver, resolvable),
         {:ok, %Resolved{} = resolved} <- Resolver.fetch_resolved(resolver, resolvable),
         {:ok, vocabularies} when is_list(vocabularies) <- Resolver.fetch_vocabularies_for(resolver, resolved) do
      bld = %__MODULE__{bld | resolver: resolver, vocabularies: vocabularies, ns: namespace_of(resolvable)}

      do_build_sub(resolved.raw, bld)
    else
      {:error, _} = err -> err
    end
  end

  defp namespace_of(binary) when is_binary(binary) do
    binary
  end

  defp namespace_of(:root) do
    :root
  end

  defp namespace_of(%Ref{ns: ns}) do
    ns
  end

  defp validator_key(binary) when is_binary(binary) do
    binary
  end

  defp validator_key(%Ref{} = ref) do
    Ref.to_key(ref)
  end

  defp validator_key(:root) do
    :root
  end

  defp validator_key({:anchor, _, _} = k) do
    k
  end

  def build_sub(%{"$id" => id}, %__MODULE__{} = bld) do
    with {:ok, key} <- RNS.derive(bld.ns, id) do
      {:ok, {:alias_of, key}, bld}
    end
  end

  def build_sub(raw_schema, %__MODULE__{} = bld) do
    do_build_sub(raw_schema, bld)
  end

  defp do_build_sub(valid?, %__MODULE__{} = bld) when is_boolean(valid?) do
    {:ok, %BooleanSchema{value: valid?}, bld}
  end

  defp do_build_sub(raw_schema, %__MODULE__{} = bld) when is_map(raw_schema) do
    {_leftovers, schema_validators, %__MODULE__{} = bld} =
      Enum.reduce(bld.vocabularies, {raw_schema, %{}, bld}, fn module, {raw_schema, schema_validators, bld} ->
        # For one vocabulary module we reduce over the raw schema keywords to
        # accumulate the validator map.
        {consumed_raw_schema, mod_validators, %__MODULE__{} = bld} = build_mod_validators(raw_schema, module, bld)

        case mod_validators do
          :ignore -> {consumed_raw_schema, schema_validators, bld}
          _ -> {consumed_raw_schema, Map.put(schema_validators, module, mod_validators), bld}
        end
      end)

    # TODO we should warn if the dialect did not pick all elements from the
    # schema. But this should be opt-in
    # case leftovers do
    #   [] -> :ok
    #   map when map_size(map) == 0 -> :ok
    #   other -> IO.warn("got some leftovers: #{inspect(other)}", [])
    # end

    {:ok, schema_validators, bld}
  end

  defp build_mod_validators(raw_schema, module, bld) do
    raw_schema |> IO.inspect(label: "raw_schema")

    {leftovers, mod_acc, %__MODULE__{} = bld} =
      Enum.reduce(raw_schema, {[], module.init_validators(), bld}, fn pair, {leftovers, mod_acc, bld} ->
        # "keyword" refers to the schema keywod, e.g. "type", "properties", etc,
        # supported by a vocabulary.

        case module.take_keyword(pair, mod_acc, bld) do
          {:ok, mod_acc, bld} -> {leftovers, mod_acc, bld}
          :ignore -> {[pair | leftovers], mod_acc, bld}
          {:error, reason} -> throw({:build_validator, pair, reason})
        end
      end)

    {leftovers, module.finalize_validators(mod_acc), bld}
  end
end

defmodule Moonwalk.Schema do
  alias Moonwalk.Schema.BooleanSchema
  alias Moonwalk.Schema.Builder
  alias Moonwalk.Schema.Ref
  alias Moonwalk.Schema.Resolver
  alias __MODULE__

  defstruct validators: %{}, root_key: nil
  @opaque t :: %__MODULE__{}

  defdelegate validate(data, schema), to: Moonwalk.Schema.Validator

  def build(raw_schema, opts \\ [])

  def build(raw_schema, opts) when is_map(raw_schema) do
    resolver_impl = Keyword.fetch!(opts, :resolver)

    with {:ok, resolver} <- Resolver.new_root(raw_schema, %{resolver: resolver_impl}),
         bld = Builder.new(resolver: resolver),
         {root_key, bld} = Builder.stage_build(bld, resolver.root) |> dbg(),
         #  bld = stage_build_all(bld),
         {:ok, validators} <- Builder.build_all(bld) do
      {:ok, %Schema{validators: validators, root_key: root_key}}
    end
  end

  def build(valid?, _opts) when is_boolean(valid?) do
    {:ok, %Schema{root_key: :root, validators: %{root: %BooleanSchema{value: valid?}}}}
  end

  # defp stage_build_all(bld) do
  #   bld.resolver.resolved
  #   |> Map.keys()
  #   |> Enum.reject(&match?({:meta, _}, &1))
  #   |> Enum.reduce(bld, fn k, bld ->
  #     {_, bld} = Builder.stage_build(bld, k)
  #     bld
  #   end)
  # end

  # def denormalize_sub(raw_sub, ctx) do
  #   Resolver.as_sub(ctx, raw_sub, &x_todo_build_validators/2)
  # end

  # def denormalize_sub(bool, ctx) when is_boolean(bool) do
  #   {:ok, %Moonwalk.Schema.BooleanSchema{value: bool}, ctx}
  # end

  # Schema validators are the collection of validators for each namespace. Here
  # "schema" means the top document and all other referenced documents.
  def build_schema_validators(ctx) do
    with {:ok, validators, ctx} <- build_root(ctx) do
      build_staged_recursive(validators, ctx)
    end
  end

  defp build_root(ctx) do
    Resolver.as_root(ctx, fn root_raw_schema, ctx ->
      with {:ok, schema_validators, ctx} <- x_todo_build_validators(root_raw_schema, ctx) do
        all_validators =
          case ctx.ns do
            :root -> %{root: schema_validators}
            ns -> %{ns => schema_validators, root: {:alias_of, ns}}
          end

        {:ok, all_validators, ctx}
      end
    end)
  end

  # For each staged ref in the context, we ensute that the schema top document
  # is resolved, and then build the validators and put the {ns, fragment} as in
  # the validators. Those newly built validators may have staged new refs, so we
  # repeat the process until there are no more staged refs.
  defp build_staged_recursive(validators, ctx) do
    case Resolver.take_staged(ctx) do
      {:empty, ctx} ->
        {:ok, validators, ctx}

      {ref, ctx} ->
        refschema_key = Ref.to_key(ref)

        with {:already_built, false} <- {:already_built, Map.has_key?(validators, refschema_key)},
             {:ok, schema_validators, ctx} <- build_ref(ref, ctx) do
          validators = Map.put(validators, refschema_key, schema_validators)
          build_staged_recursive(validators, ctx)
        else
          {:already_built, true} -> build_staged_recursive(validators, ctx)
          {:error, _} = err -> err
        end
    end
  end

  defp build_ref(%Ref{} = ref, ctx) do
    with {:ok, ctx} <- Resolver.resolve(ctx, ref) do
      Resolver.as_ref(ctx, ref, fn raw_schema, subctx ->
        x_todo_build_validators(raw_schema, subctx)
      end)
    end
  end

  def x_todo_build_validators(raw_schema, ctx) when is_boolean(raw_schema) do
    {:ok, BooleanSchema.of(raw_schema), ctx}
  end

  def x_todo_build_validators(raw_schema, ctx) do
    # For each vocabulary module we build its validator map. On the first
    # iteration, raw_schema will be a map but then it will be a list of pairs,
    # the leftovers of the previous iteration.

    raw_schema = Map.drop(raw_schema, ["$schema", "$id"])

    {_leftovers, validators, ctx} =
      Enum.reduce(ctx.vocabularies, {raw_schema, %{}, ctx}, fn module, {raw_schema, acc, ctx} ->
        # For one vocabulary module we reduce over the raw schema keywords to
        # accumulate the validator map.
        {raw_schema, built_mod, ctx} = x_todo_build_validators_for_module(raw_schema, module, ctx)

        case built_mod do
          :ignore -> {raw_schema, acc, ctx}
          _ -> {raw_schema, Map.put(acc, module, built_mod), ctx}
        end
      end)

    # TODO we should warn if the dialect did not pick all elements from the
    # schema. But this should be opt-in
    # case leftovers do
    #   [] -> :ok
    #   map when map_size(map) == 0 -> :ok
    #   other -> IO.warn("got some leftovers: #{inspect(other)}", [])
    # end

    {:ok, validators, ctx}
  catch
    {:build_validator, _pair, reason} -> {:error, reason}
  end

  defp x_todo_build_validators_for_module(raw_schema, module, ctx) do
    {leftovers, mod_acc, ctx} =
      Enum.reduce(raw_schema, {[], module.init_validators(), ctx}, fn pair, {leftovers, mod_acc, ctx} ->
        # "keyword" refers to the schema keywod, e.g. "type", "properties", etc,
        # supported by a vocabulary.

        case module.take_keyword(pair, mod_acc, ctx) do
          {:ok, mod_acc, ctx} -> {leftovers, mod_acc, ctx}
          :ignore -> {[pair | leftovers], mod_acc, ctx}
          {:error, reason} -> throw({:build_validator, pair, reason})
        end
      end)

    {leftovers, module.finalize_validators(mod_acc), ctx}
  end
end
