defmodule Moonwalk.Schema.Builder do
  alias Moonwalk.Schema.Key
  alias Moonwalk.Schema.BooleanSchema
  alias Moonwalk.Schema.Ref
  alias Moonwalk.Schema.RNS
  alias Moonwalk.Schema.Resolver
  alias Moonwalk.Schema.Resolver.Resolved

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
    {Key.of(buildable), %__MODULE__{bld | staged: append_unique(staged, buildable)}}
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

  defp take_staged(%{staged: []}) do
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
        vkey = Key.of(buildable)

        with :buildable <- check_buildable(all_validators, vkey),
             {:ok, schema_validators, %__MODULE__{} = bld} <- build_schema_validators(bld, buildable) do
          build_all(bld, Map.put(all_validators, vkey, schema_validators))
        else
          :already_built -> build_all(bld, all_validators)
          {:error, _} = err -> err
        end
    end
  end

  defp check_buildable(all_validators, vkey) do
    case is_map_key(all_validators, vkey) do
      true -> :already_built
      false -> :buildable
    end
  end

  defp build_schema_validators(%__MODULE__{} = bld, resolvable) do
    with {:ok, %Resolver{} = resolver} <- Resolver.resolve(bld.resolver, resolvable),
         {:ok, %Resolved{} = resolved} <- Resolver.fetch_resolved(resolver, resolvable),
         {:ok, vocabularies} when is_list(vocabularies) <- Resolver.fetch_vocabularies_for(resolver, resolved) do
      bld = %__MODULE__{bld | resolver: resolver, vocabularies: vocabularies, ns: Key.namespace_of(resolvable)}

      do_build_sub(resolved.raw, bld)
    else
      {:error, _} = err -> err
    end
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
    {:ok, BooleanSchema.of(valid?), bld}
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
    {leftovers, mod_acc, %__MODULE__{} = bld} =
      Enum.reduce(raw_schema, {[], module.init_validators(), bld}, fn pair, {leftovers, mod_acc, bld} ->
        # "keyword" refers to the schema keywod, e.g. "type", "properties", etc,
        # supported by a vocabulary.

        case module.take_keyword(pair, mod_acc, bld) do
          {:ok, mod_acc, bld} -> {leftovers, mod_acc, bld}
          :ignore -> {[pair | leftovers], mod_acc, bld}
        end
      end)

    {leftovers, module.finalize_validators(mod_acc), bld}
  end
end

defmodule Moonwalk.Schema do
  alias Moonwalk.Schema.BooleanSchema
  alias Moonwalk.Schema.Builder
  alias Moonwalk.Schema.Resolver
  alias __MODULE__

  defstruct validators: %{}, root_key: nil
  @opaque t :: %__MODULE__{}

  defdelegate validate(data, schema), to: Moonwalk.Schema.Validator

  def build(raw_schema, opts) when is_map(raw_schema) do
    resolver_impl = Keyword.fetch!(opts, :resolver)

    with {:ok, resolver} <- Resolver.new_root(raw_schema, %{resolver: resolver_impl}),
         bld = Builder.new(resolver: resolver),
         {root_key, bld} = Builder.stage_build(bld, resolver.root),
         {:ok, validators} <- Builder.build_all(bld) do
      {:ok, %Schema{validators: validators, root_key: root_key}}
    end
  end

  def build(valid?, _opts) when is_boolean(valid?) do
    {:ok, %Schema{root_key: :root, validators: %{root: BooleanSchema.of(valid?)}}}
  end
end
