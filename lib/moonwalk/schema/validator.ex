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
    validate_multi(data, validators)
  end

  defp validate_multi(data, schemas) do
    schemas
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

  def validate(data, {:all_properties, {properties, patterns, additional}}) when is_map(data) do
    errors = []
    seen = MapSet.new()

    {data, errors, seen} = validate_properties(data, properties, errors, seen)
    {data, errors, seen} = validate_pattern_properties(data, patterns, errors, seen)
    {data, errors} = validate_additional_properties(data, additional, errors, seen)

    case errors do
      [] -> {:ok, data}
      _ -> {:error, Error.group(errors)}
    end
  end

  def validate(data, {:all_properties, _}) do
    {:ok, data}
  end

  def validate(data, {:const, expected}) do
    case data == expected do
      true -> {:ok, data}
      false -> {:error, Error.of(:const, data, expected: expected)}
    end
  end

  def validate(data, {:items, subschema}) when is_list(data) do
    data
    |> Enum.with_index()
    |> Enum.reduce({[], []}, fn {item, index}, {items, errors} ->
      item |> IO.inspect(label: ~S/item/)
      index |> IO.inspect(label: ~S/index/)
      subschema |> IO.inspect(label: ~S/subschema/)

      case validate(item, subschema) |> dbg() do
        {:ok, casted} ->
          {[casted | items], errors}

        {:error, reason} ->
          {items, [Error.of(:item_error, item, index: index, reason: reason) | errors]}
      end
    end)
    |> case do
      {items, []} -> {:ok, :lists.reverse(items)}
      {_, errors} -> {:error, Error.group(errors)}
    end
  end

  def validate(data, {:prefix_items, schemas}) when is_list(data) do
    validate_prefix_items(data, schemas)
  end

  def validate(data, {:minimum, min}) when is_number(data) do
    if data >= min,
      do: {:ok, data},
      else: {:error, Error.of(:minimum, data, minimum: min)}
  end

  def validate(data, {:minimum, _}) do
    {:ok, data}
  end

  def validate(data, {:maximum, max}) when is_number(data) do
    if data <= max,
      do: {:ok, data},
      else: {:error, Error.of(:maximum, data, maximum: max)}
  end

  def validate(data, {:maximum, _}) do
    {:ok, data}
  end

  def validate(data, {:max_items, max}) when is_list(data) do
    len = length(data)

    if len <= max,
      do: {:ok, data},
      else: {:error, Error.of(:max_items, data, max_items: max, len: len)}
  end

  def validate(data, {:min_items, min}) when is_list(data) do
    len = length(data)

    if len >= min,
      do: {:ok, data},
      else: {:error, Error.of(:min_items, data, min_items: min, len: len)}
  end

  def validate(data, {:all_of, schemas}) do
    validate_multi(data, schemas)
  end

  def validate(data, {:boolean_schema, valid?}) do
    if valid?, do: {:ok, data}, else: {:error, Error.of(:boolean_schema, data, [])}
  end

  def validate(data, {:required, keys}) when is_map(data) do
    case Enum.reject(keys, &Map.has_key?(data, &1)) do
      [] -> {:ok, data}
      missing -> {:error, Error.of(:required, data, missing: missing)}
    end
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

  defp validate_properties(data, nil, errors, seen) do
    {data, errors, seen}
  end

  defp validate_properties(data, schema_map, errors, seen) do
    Enum.reduce(schema_map, {data, errors, seen}, fn {key, subschema}, {data, errors, seen} ->
      case Map.fetch(data, key) do
        :error ->
          {data, errors, seen}

        {:ok, value} ->
          seen = MapSet.put(seen, key)

          case validate(value, subschema) do
            {:ok, casted} ->
              {Map.put(data, key, casted), errors, seen}

            {:error, reason} ->
              {data, [Error.of(:properties, value, key: key, reason: reason) | errors], seen}
          end
      end
    end)
  end

  defp validate_pattern_properties(data, nil, errors, seen) do
    {data, errors, seen}
  end

  defp validate_pattern_properties(data, schema_map, errors, seen) do
    for {{pattern, regex}, subschema} <- schema_map,
        {key, value} <- data,
        Regex.match?(regex, key),
        reduce: {data, errors, seen} do
      {data, errors, seen} ->
        seen = MapSet.put(seen, key)

        case validate(value, subschema) do
          {:ok, casted} ->
            {Map.put(data, key, casted), errors, seen}

          {:error, reason} ->
            error =
              Error.of(:pattern_properties, value,
                key: key,
                pattern: pattern,
                reason: reason
              )

            {data, [error | errors], seen}
        end
    end
  end

  defp validate_additional_properties(data, nil, errors, _seen) do
    {data, errors}
  end

  defp validate_additional_properties(data, subschema, errors, seen) do
    for {key, value} <- data, not MapSet.member?(seen, key), reduce: {data, errors} do
      {data, errors} ->
        case validate(value, subschema) do
          {:ok, casted} ->
            {Map.put(data, key, casted), errors}

          {:error, reason} ->
            error =
              Error.of(:additional_properties, value,
                key: key,
                reason: reason
              )

            {data, [error | errors]}
        end
    end
  end

  defp validate_prefix_items(values, schemas) do
    validate_prefix_items(values, schemas, 0, [], [])
  end

  defp validate_prefix_items([vh | vt], [sh | st], index, validated, errors) do
    case validate(vh, sh) do
      {:ok, data} ->
        validate_prefix_items(vt, st, index + 1, [data | validated], errors)

      {:error, reason} ->
        validate_prefix_items(vt, st, index + 1, validated, [
          Error.of(:item_error, vh, index: index, reason: reason, prefix: true) | errors
        ])
    end
  end

  defp validate_prefix_items(vt, [], _, validated, []) do
    {:ok, :lists.reverse(validated, vt)}
  end
end
