defmodule Moonwalk.Spec.Paths do
  require JSV
  use Moonwalk.Internal.Normalizer

  # Holds the relative paths to individual endpoints and their operations.
  def schema do
    JSV.Schema.normalize(%{
      title: "Paths",
      type: :object,
      description:
        "Holds the relative paths to individual endpoints and their operations, mapping each path to a Path Item Object.",
      additionalProperties: Moonwalk.Spec.PathItem
    })
  end

  @impl true
  def normalize!(data, ctx) do
    data
    |> make(__MODULE__, ctx)
    |> normalize_subs(fn _key, value, ctx ->
      {_value, _ctx} =
        Moonwalk.Internal.Normalizer.normalize!(value, Moonwalk.Spec.PathItem, ctx)
    end)
    |> collect()
  end

  def from_router(router) when is_atom(router) do
    from_routes(router.__routes__())
  end

  defp from_routes(routes) do
    routes
    |> Enum.flat_map(fn route ->
      with %{path: path, plug: controller, plug_opts: action, verb: verb} when is_atom(action) <-
             route,
           true <- Code.ensure_loaded?(controller),
           true <- function_exported?(controller, :__moonwalk__, 3),
           {:ok, op} <- controller.__moonwalk__(:operation, action, verb) do
        path = encode_router_path(path)
        [{[Access.key(path, %{}), Access.key(verb, %{})], op}]
      else
        _ -> []
      end
    end)
    |> Enum.reduce(%{}, fn {access_path, op}, acc -> put_in(acc, access_path, op) end)
  end

  defp encode_router_path(path) do
    path
    |> String.split("/")
    |> Enum.map_join("/", fn
      ":" <> param -> "{#{param}}"
      segment -> segment
    end)
  end
end
