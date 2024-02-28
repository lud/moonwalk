defmodule Moonwalk.Spec.Api do
  defstruct [:openapi, :info]

  def define(opts) do
    acc = %__MODULE__{openapi: "4.0.0", info: %{}}
    Enum.reduce(opts, acc, &collect_opt/2)
  end

  defp collect_opt({key, value}, acc) when is_atom(key) do
    with_info(acc, Moonwalk.json_key!(key), value)
  end

  def with_info(%{info: info} = api, key, value) when is_binary(key) do
    info = Map.put(info, Moonwalk.json_key!(key), Moonwalk.json_serializable!(value))
    %__MODULE__{api | info: info}
  end

  def normalize_spec(api) do
    api
    |> Map.from_struct()
    |> Enum.reduce(%{}, fn
      {_, nil}, acc -> acc
      {:info, map}, acc when map_size(map) == 0 -> acc
      {:info, map}, acc -> Map.put(acc, "info", map)
      pair, acc -> normalize(pair, acc)
    end)
  end

  defp normalize({:openapi, vsn}, raw) do
    Map.put(raw, "openapi", vsn)
  end
end
