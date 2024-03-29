defmodule Moonwalk.Schema.Builder do
  alias Moonwalk.Schema.Key
  alias Moonwalk.Schema.BooleanSchema
  alias Moonwalk.Schema.Ref
  alias Moonwalk.Schema.RNS
  alias Moonwalk.Schema.Resolver
  alias Moonwalk.Schema.Resolver.Resolved

  @derive {Inspect, only: [:resolver, :staged]}
  defstruct [:resolver, staged: [], vocabularies: nil, ns: nil]

  def new(opts) do
    struct!(__MODULE__, Map.new(opts))
  end

  def stage_build(%{staged: staged} = bld, buildable) do
    %__MODULE__{bld | staged: append_unique(staged, buildable)}
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

  def ensure_resolved(%{resolver: resolver} = bld, resolvable) do
    case Resolver.resolve(resolver, resolvable) do
      {:ok, resolver} -> {:ok, %__MODULE__{bld | resolver: resolver}}
      {:error, _} = err -> err
    end
  end

  def fetch_resolved(%{resolver: resolver}, key) do
    Resolver.fetch_resolved(resolver, key)
  end

  defp take_staged(%{staged: []}) do
    :empty
  end

  defp take_staged(%{staged: [staged | tail]} = bld) do
    {staged, %__MODULE__{bld | staged: tail}}
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
    # We split the buildables in three cases:
    # - One dynamic refs will lead to build all existing dynamic refs not
    #   already built.
    # - Resolvables such as ID and Ref will be resolved and turned into
    #   :resolved tuples.
    # - :resolved tuples assume to be already resolved and will be built into
    #   validators.
    #
    # We need to do that 2-pass in the stage list because some resolvables
    # (dynamic refs) lead to stage and build multiple validators.

    case take_staged(bld) do
      {{:resolved, vkey}, %{resolver: resolver} = bld} ->
        with :buildable <- check_buildable(all_validators, vkey),
             {:ok, resolved} <- Resolver.fetch_resolved(resolver, vkey),
             {:ok, schema_validators, bld} <- build_resolved(bld, vkey, resolved) do
          build_all(bld, Map.put(all_validators, vkey, put_scope(schema_validators, vkey)))
        else
          {:already_built, _} -> build_all(bld, all_validators)
          {:error, _} = err -> err
        end

      {%Ref{dynamic?: true}, bld} ->
        bld = stage_all_dynamic(bld)
        build_all(bld, all_validators)

      {resolvable, bld} when is_binary(resolvable) when is_struct(resolvable, Ref) when :root == resolvable ->
        with :buildable <- check_buildable(all_validators, Key.of(resolvable)),
             {:ok, bld} <- resolve_and_stage(bld, resolvable) do
          build_all(bld, all_validators)
        else
          {:already_built, _} -> build_all(bld, all_validators)
          {:error, _} = err -> err
        end

      # Finally there is nothing more to build
      :empty ->
        {:ok, all_validators}
    end
  end

  defp put_scope(%BooleanSchema{} = schema_validators, _vkey) do
    schema_validators
  end

  defp put_scope(schema_validators, vkey) when is_map(schema_validators) do
    Map.put(schema_validators, :__scope__, Key.namespace_of(vkey))
  end

  defp put_scope({:alias_of, _} = aliased, _vkey) do
    aliased
  end

  defp resolve_and_stage(bld, resolvable) do
    %{resolver: resolver, staged: staged} = bld
    vkey = Key.of(resolvable)

    case Resolver.resolve(resolver, resolvable) do
      {:ok, new_resolver} -> {:ok, %__MODULE__{bld | resolver: new_resolver, staged: [{:resolved, vkey} | staged]}}
      {:error, _} = err -> err
    end
  end

  defp stage_all_dynamic(bld) do
    # To build all dynamic references we tap into the resolver. The resolver
    # also conveniently allows to fetch by its own keys ({:dynamic_anchor, _,
    # _}) instead of passing the original ref.
    #
    # Everytime we encounter a dynamic ref in build_all/2 we insert all dynamic
    # references into the staged list. But if we insert the reft itself it will
    # lead to an infinite loop, since we do that when we find a ref in this
    # loop.
    #
    # So instead of inserting the ref we insert the Key, and the Key module and
    # Resolver accept to work with that kind of schema identifier (that is,
    # {:dynamic_anchor, _, _} tuple).

    # new items can appear when we build subschemas that stage a ref in the
    # build struct.
    #
    # But to keep it clean we just scan the whole list every time.
    dynamic_buildables =
      Enum.flat_map(bld.resolver.resolved, fn
        {{:dynamic_anchor, _, _} = vkey, _resolved} -> [{:resolved, vkey}]
        _ -> []
      end)

    %__MODULE__{bld | staged: dynamic_buildables ++ bld.staged}
  end

  defp check_buildable(all_validators, vkey) do
    case is_map_key(all_validators, vkey) do
      true -> {:already_built, vkey}
      false -> :buildable
    end
  end

  defp build_resolved(bld, vkey, %Resolved{} = resolved) do
    case Resolver.fetch_vocabularies_for(bld.resolver, resolved) do
      {:ok, vocabularies} when is_list(vocabularies) ->
        bld = %__MODULE__{bld | vocabularies: vocabularies, ns: Key.namespace_of(vkey)}
        do_build_sub(resolved.raw, bld)

      {:error, _} = err ->
        err
    end
  end

  defp build_resolved(bld, _vkey, {:alias_of, key}) do
    # If the resolver returns an alias we know the target of the alias is
    # already resolved, so we can just stage it as so.
    {:ok, {:alias_of, key}, stage_build(bld, {:resolved, key})}
  end

  def build_sub(%{"$id" => id}, %__MODULE__{} = bld) do
    with {:ok, key} <- RNS.derive(bld.ns, id) do
      {:ok, {:alias_of, key}, stage_build(bld, key)}
    end
  end

  def build_sub(raw_schema, %__MODULE__{} = bld) when is_map(raw_schema) when is_boolean(raw_schema) do
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
  alias Moonwalk.Schema.Key
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
         bld = Builder.stage_build(bld, resolver.root),
         root_key = Key.of(resolver.root),
         {:ok, validators} <- Builder.build_all(bld) do
      {:ok, %Schema{validators: validators, root_key: root_key}}
    end
  end

  def build(valid?, _opts) when is_boolean(valid?) do
    {:ok, %Schema{root_key: :root, validators: %{root: BooleanSchema.of(valid?)}}}
  end
end
