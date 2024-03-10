defmodule Moonwalk.Schema.BooleanSchema do
  defstruct [:value]
end

defmodule Moonwalk.Schema do
  alias ElixirLS.LanguageServer.Build
  alias Moonwalk.Schema.Ref
  alias Moonwalk.Schema.BuildContext
  alias __MODULE__

  defstruct validators: %{}
  @opaque t :: %__MODULE__{}

  defdelegate validate(data, schema), to: Moonwalk.Schema.Validator

  def denormalize(raw_schema, opts \\ []) do
    opts_map = opts |> Keyword.validate!(BuildContext.default_opts_list()) |> Map.new()

    with {:ok, ctx} <- BuildContext.for_root(raw_schema, opts_map),
         {:ok, validators, _ctx} <- build_validators(ctx) do
      {:ok, %Schema{validators: validators}}
    end
  end

  def denormalize_sub(raw_sub, ctx) when is_map(raw_sub) do
    build_validators(raw_sub, ctx)
  end

  def denormalize_sub(bool, ctx) when is_boolean(bool) do
    {:ok, %Moonwalk.Schema.BooleanSchema{value: bool}, ctx}
  end

  def build_validators(ctx) do
    with {:ok, validators, ctx} <- build_root(ctx) do
      build_staged_recursive(validators, ctx)
    end
  end

  defp build_root(ctx) do
    BuildContext.as_root(ctx, fn root_raw_schema, ctx ->
      with {:ok, schema_validators, ctx} <- build_validators(root_raw_schema, ctx) do
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
    case BuildContext.take_staged(ctx) do
      {:empty, ctx} ->
        {:ok, validators, ctx}

      {ref, ctx} ->
        vds_key = Ref.to_key(ref)

        with {:already_done?, false} <- {:already_done?, Map.has_key?(validators, vds_key)},
             {:ok, schema_validators, ctx} <- build_ref(ref, ctx) do
          validators = Map.put(validators, vds_key, schema_validators)
          build_staged_recursive(validators, ctx)
        else
          {:already_done?, true} -> build_staged_recursive(validators, ctx)
        end
    end
  end

  defp build_ref(%Ref{} = ref, ctx) do
    with {:ok, ctx} <- BuildContext.ensure_resolved(ctx, ref) do
      BuildContext.as_ref(ctx, ref, fn raw_schema, ctx ->
        build_validators(raw_schema, ctx)
      end)
    end
  end

  def build_validators(raw_schema, ctx) do
    # For each vocabulary module we build its validator map. On the first
    # iteration, raw_schema will be a map but then it will be a list of pairs,
    # the leftovers of the previous iteration.
    raw_schema = Map.drop(raw_schema, ["$schema", "$id"])

    {leftovers, validators, ctx} =
      Enum.reduce(ctx.vocabularies, {raw_schema, %{}, ctx}, fn module, {raw_schema, acc, ctx} ->
        # For one vocabulary module we reduce over the raw schema keywords to
        # accumulate the validator map.
        {raw_schema, built_mod, ctx} = build_validators_for_module(raw_schema, module, ctx)

        case built_mod do
          :ignore -> {raw_schema, acc, ctx}
          _ -> {raw_schema, Map.put(acc, module, built_mod), ctx}
        end
      end)

    case leftovers do
      [] -> :ok
      map when map_size(map) == 0 -> :ok
      other -> IO.warn("got some leftovers: #{inspect(other)}", [])
    end

    {:ok, validators, ctx}
  catch
    {:build_validator, _pair, reason} -> {:error, reason}
  end

  defp build_validators_for_module(raw_schema, module, ctx) do
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
