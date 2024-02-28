defmodule Moonwalk.Schema do
  defstruct [:meta, :layers]

  def denormalize(%{"$schema" => vsn} = json_schema) do
    denormalize(json_schema, %{vsn: vsn})
  end

  def denormalize(json_schema, meta) do
    {:ok, Enum.reduce(json_schema, %__MODULE__{meta: meta, layers: []}, &denorm/2)} |> dbg()
  end

  defp denorm({"$schema", vsn}, %{meta: meta} = s) do
    %__MODULE__{s | meta: Map.put(meta, :vsn, vsn)}
  end

  defp denorm({"type", type}, s) do
    type = valid_type!(type)
    layer = layer_of(:type)
    put_checker(s, layer, {:type, type})
  end

  # Passthrough schema properties – we do not use them but we must accept them
  # as they are part of the defined properties of a schema.

  [
    content_encoding: "contentEncoding",
    content_media_type: "contentMediaType",
    content_schema: "contentSchema"
  ]
  |> Enum.each(fn {internal, external} ->
    defp denorm({unquote(external), value}, s) do
      put_checker(s, layer_of(unquote(internal)), {unquote(internal), value})
    end
  end)

  layers = [
    [:type],
    [:content_encoding],
    [:content_media_type],
    [:content_schema]
  ]

  for {checkers, n} <- Enum.with_index(layers), c <- checkers do
    defp layer_of(unquote(c)), do: unquote(n)
  end

  defp put_checker(%__MODULE__{layers: layers} = s, layer, checker) do
    layers = put_in_layer(layers, layer, checker)
    %__MODULE__{s | layers: layers}
  end

  defp put_in_layer([h | t], 0, checker), do: [[checker | h] | t]
  defp put_in_layer([h | t], n, checker), do: [h | put_in_layer(t, n - 1, checker)]
  defp put_in_layer([], 0, checker), do: [[checker]]
  defp put_in_layer([], n, checker), do: [[] | put_in_layer([], n - 1, checker)]

  defp valid_type!(list) when is_list(list), do: Enum.map(list, &valid_type!/1)
  defp valid_type!("array"), do: :array
  defp valid_type!("object"), do: :object
  defp valid_type!("null"), do: :null
  defp valid_type!("boolean"), do: :boolean
  defp valid_type!("string"), do: :string
  defp valid_type!("integer"), do: :integer
  defp valid_type!("number"), do: :number

  defdelegate validate(data, schema), to: Moonwalk.Schema.Validator
end
