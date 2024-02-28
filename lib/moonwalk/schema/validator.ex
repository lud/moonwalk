defmodule Moonwalk.Schema.Validator.Error do
  defstruct [:kind, :data, :args]

  def of(kind, data, args) do
    %__MODULE__{kind: kind, data: data, args: args}
  end

  def type_error(data, type) do
    of(:type, data, type: type)
  end

  def group(errors) do
    {:multiple_errors, errors}
  end
end

defmodule Moonwalk.Schema.Validator do
  alias Moonwalk.Schema
  alias Moonwalk.Schema.Validator.Error

  defp validate_layer(data, validators) do
    validators
    |> Enum.map(&validate(data, &1))
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Enum.into(%{error: []})
    |> case do
      %{error: []} -> {:ok, data}
      %{error: errors} -> {:error, Error.group(errors)}
    end
  end

  def validate(data, %Schema{} = schema) do
    Enum.reduce_while(schema.layers, {:ok, data}, fn layer, {:ok, data} ->
      case validate_layer(data, layer) do
        {:ok, data} -> {:cont, {:ok, data}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  def validate(data, {:type, list}) when is_list(list) do
    Enum.find_value(list, fn type ->
      case validate(data, {:type, type}) do
        {:ok, data} -> {:ok, data}
        {:error, _} -> nil
      end
    end)
    |> case do
      {:ok, data} -> {:ok, data}
      nil -> {:error, Error.type_error(data, list)}
    end
  end

  def validate(data, {:type, t}) do
    case validate_type(data, t) do
      true -> {:ok, data}
      false -> {:error, Error.type_error(data, t)}
      {:swap, new_data} -> {:ok, new_data}
    end
  end

  def validate(data, {:const, expected}) do
    case data == expected do
      true -> {:ok, data}
      false -> {:error, Error.of(:const, data, expected: expected)}
    end
  end

  def validate(data, {:boolean_schema, valid?}) do
    if valid?, do: {:ok, data}, else: {:error, Error.of(:boolean_schema, data, [])}
  end

  defp validate_type(data, :array), do: is_list(data)
  defp validate_type(data, :object), do: is_map(data)
  defp validate_type(data, :null), do: data === nil
  defp validate_type(data, :boolean), do: is_boolean(data)
  defp validate_type(data, :string), do: is_binary(data)

  defp validate_type(data, :integer) when is_float(data) do
    fractional_is_zero?(data) && {:swap, trunc(data)}
  end

  defp validate_type(data, :integer), do: is_integer(data)
  defp validate_type(data, :number), do: is_number(data)

  # TODO this will not work with large numbers
  defp fractional_is_zero?(n) do
    n - trunc(n) === 0.0
  end
end
