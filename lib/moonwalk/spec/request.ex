defmodule Moonwalk.Spec.Request do
  defstruct [:method, :content_type]

  def define(opts) do
    acc = %__MODULE__{method: "GET"}
    Enum.reduce(opts, acc, &collect_opt/2)
  end

  defp collect_opt({:method, method}, acc) when is_binary(method) do
    %__MODULE__{acc | method: method}
  end

  defp collect_opt({:content_type, content_type}, acc) when is_binary(content_type) do
    %__MODULE__{acc | content_type: content_type}
  end

  # def with_info(%{info: info} = api, key, value) when is_binary(key) do
  #   info = Map.put(info, Moonwalk.json_key!(key), Moonwalk.json_serializable!(value))
  #   %__MODULE__{api | info: info}
  # end

  def normalize_spec(api) do
    api
    |> Map.from_struct()
    |> Enum.reduce(%{}, fn
      {_, nil}, acc -> acc
      pair, acc -> normalize(pair, acc)
    end)
  end

  defp normalize({:method, method}, raw), do: Map.put(raw, "method", method)

  defp normalize({:content_type, content_type}, raw),
    do: Map.put(raw, "contentType", content_type)
end
