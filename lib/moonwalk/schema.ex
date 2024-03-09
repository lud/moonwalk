defmodule Moonwalk.Schema.BooleanSchema do
  defstruct [:value]
end

defmodule Moonwalk.Schema do
  # TODO remove french plan
  @doc """
  1. Le schema est représenté par une map, avec a minima une clé :root qui
     contient les validateurs pour le schéma principal.
  2. Le schéma est récursif/nested, "properties" ou "items" contient des
     sous-maps.
  3. Lors de la dénormalization on passe un contexte, et on retourne le
     contexte, donc denormalize!/2 est basé sur denormalize/2.
  4. Quand on trouve une $ref, on la résout dans le contexte, ce dernier
     contient donc les versions raw de toutes les URLs demandées.
  5. Le schéma pointé par la ref est parsé et on le transforme aussi en
     validateurs. Le réslutat est ajouté au sous la clé {ns, fragment}.
  6. Finalement le schema root est lui même ajouté au context sous la clé :root.
  7. Le schéma final est donc simplement le contexte,
  8. Les validateurs sont une map avec comme clé le vocabulary et en valeur le
     résultat de son parsing.
  9. À la fin on cleanup les resolved en remplaçant la map par :cleaned.
  """
  alias Moonwalk.Schema.Ref
  alias Moonwalk.Schema.BuildContext
  alias __MODULE__

  defstruct validators: %{}
  @opaque t :: %__MODULE__{}

  defdelegate validate(data, schema), to: Moonwalk.Schema.Validator

  def denormalize(raw_schema, opts \\ []) do
    opts_map = opts |> Keyword.validate!(BuildContext.default_opts_list()) |> Map.new()

    ctx = BuildContext.new_root(raw_schema, opts_map)
    meta_uri = Map.fetch!(raw_schema, "$schema")

    with {:ok, ctx} <- BuildContext.load_vocabulary(ctx, meta_uri),
         {:ok, validators, _ctx} <- build_validators(ctx) do
      {:ok, %Schema{validators: validators}}
    end
  end

  def denormalize_sub(bool, ctx) when is_boolean(bool) do
    {:ok, %Moonwalk.Schema.BooleanSchema{value: bool}, ctx}
  end

  def denormalize_sub(raw_sub, ctx) do
    build_validators(raw_sub, ctx)
  end

  def build_validators(ctx) do
    with {:ok, validators, ctx} <- build_root(ctx) do
      build_staged_recursive(validators, ctx)
    end
  end

  defp build_root(ctx) do
    root_ns = ctx.ns
    root_raw_schema = Map.fetch!(ctx.resolved, root_ns)

    with {:ok, schema_validators, ctx} <- build_validators(root_raw_schema, ctx) do
      {:ok, %{{root_ns, "#"} => schema_validators, _root: {root_ns, "#"}}, ctx}
    end
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
        vds_key = Ref.to_key(ref) |> dbg()

        with {:already_done?, false} <- {:already_done?, Map.has_key?(validators, vds_key)} |> dbg(),
             {:ok, schema_validators, ctx} <- build_ref(ref, ctx) do
          validators = Map.put(validators, vds_key, schema_validators)
          build_staged_recursive(validators, ctx)
        else
          {:already_done?, true} -> build_staged_recursive(validators, ctx)
        end
    end
  end

  defp build_ref(%Ref{} = ref, ctx) do
    with {:ok, raw_schema, ctx} <- BuildContext.ensure_resolved(ctx, ref),
         {:ok, raw_sub} <- fetch_docpath(raw_schema, ref.docpath) do
      build_validators(raw_sub, ctx)
    end
  end

  defp fetch_docpath(raw_schema, docpath) do
    fetch_docpath(raw_schema, docpath, docpath)
  end

  defp fetch_docpath(raw_schema, [], _docpath) do
    {:ok, raw_schema}
  end

  defp fetch_docpath(raw_schema, [h | t], docpath) do
    case Map.fetch(raw_schema, h) do
      {:ok, sub} -> fetch_docpath(sub, t)
      :error -> {:error, {:invalid_docpath, docpath}}
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
