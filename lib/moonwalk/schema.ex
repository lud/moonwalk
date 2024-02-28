defmodule Moonwalk.Schema do
  defstruct [:meta, :layers]

  def denormalize(%{"$schema" => vsn} = json_schema) do
    denormalize(json_schema, %{vsn: vsn})
  end

  def denormalize(json_schema, meta) do
    {:ok, Enum.reduce(json_schema, %__MODULE__{meta: meta, layers: []}, &denorm/2)}
  end

  defp denorm({"$schema", vsn}, %{meta: meta} = s) do
    %__MODULE__{s | meta: Map.put(meta, :vsn, vsn)}
  end

  defp denorm({"type", type}, s) do
    type = valid_type!(type)
    layer = layer_of(:type)
    put_checker(s, layer, {:type, type})
  end

  defp layer_of(:type), do: 0

  defp put_checker(%__MODULE__{layers: layers} = s, layer, checker) do
    binding() |> IO.inspect(label: ~S/binding()/)
    layers = put_in_layer(layers, layer, checker)
    %__MODULE__{s | layers: layers}
  end

  defp put_in_layer([], 0, checker) do
    [[checker]]
  end

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
