defmodule Moonwalk.Schema.OldValidator.Error do
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

defmodule Moonwalk.Schema.OldValidator.Context do
  defstruct [:root]

  def new(root_schema) do
    %__MODULE__{root: root_schema}
  end

  defimpl Inspect do
    def inspect(%{root: _root}, _opts) do
      "#Context<>"
    end
  end
end

defmodule Moonwalk.Schema.OldValidator do
  alias Moonwalk.Schema.BooleanSchema
  alias Moonwalk.Schema
  alias Moonwalk.Schema.OldValidator.Error
  alias Moonwalk.Schema.OldValidator.Context

  defp validate_layer(data, validators, ctx) do
    validate_multi(data, validators, ctx)
  end

  defp validate_multi(data, schemas, ctx) do
    schemas
    |> Enum.map(&validate_keyword(data, &1, ctx))
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Enum.into(%{error: []})
    |> case do
      %{error: []} -> {:ok, data}
      %{error: errors} -> {:error, Error.group(errors)}
    end
  end

  # split the list of schemas, the first list is a list of {schema, data} tuples
  # for schemas that validate the data, the second list is the {schema, errors}
  # tuples for schemas that did not validate.
  defp validate_split(data, schemas, ctx) do
    {valids, invalids} =
      Enum.reduce(schemas, {[], []}, fn schema, {valids, invalids} ->
        case validate_keyword(data, schema, ctx) do
          {:ok, data} -> {[{schema, data} | valids], invalids}
          {:error, reason} -> {valids, [{schema, reason} | invalids]}
        end
      end)

    {:lists.reverse(valids), :lists.reverse(invalids)}
  end

  def validate(data, %Schema{} = schema) do
    validate_keyword(data, schema, Context.new(schema))
  end

  def validate(data, %BooleanSchema{value: valid?}) do
    if valid? do
      {:ok, data}
    else
      {:error, Error.of(:boolean_schema, data, [])}
    end
  end

  defp validate_keyword(data, %Schema{} = schema, ctx) do
    Enum.reduce_while(schema.validators, {:ok, data}, fn vd, {:ok, data} ->
      case validate_keyword(data, vd, ctx) do
        {:ok, data} -> {:cont, {:ok, data}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp validate_keyword(data, {:type, list}, ctx) when is_list(list) do
    Enum.find_value(list, fn type ->
      case validate_keyword(data, {:type, type}, ctx) do
        {:ok, data} -> {:ok, data}
        {:error, _} -> nil
      end
    end)
    |> case do
      {:ok, data} -> {:ok, data}
      nil -> {:error, Error.type_error(data, list)}
    end
  end

  defp validate_keyword(data, {:type, t}, _ctx) do
    case validate_type(data, t) do
      true -> {:ok, data}
      false -> {:error, Error.type_error(data, t)}
      {:swap, new_data} -> {:ok, new_data}
    end
  end

  defp validate_keyword(data, {:all_properties, {properties, patterns, additional}}, ctx)
       when is_map(data) do
    errors = []
    seen = MapSet.new()

    {data, errors, seen} = validate_properties(data, properties, ctx, errors, seen)
    {data, errors, seen} = validate_pattern_properties(data, patterns, ctx, errors, seen)
    {data, errors} = validate_additional_properties(data, additional, ctx, errors, seen)

    case errors do
      [] -> {:ok, data}
      _ -> {:error, Error.group(errors)}
    end
  end

  defp validate_keyword(data, {:all_properties, _}, _ctx) do
    {:ok, data}
  end

  defp validate_keyword(data, {:const, expected}, _ctx) do
    case data == expected do
      true -> {:ok, data}
      false -> {:error, Error.of(:const, data, expected: expected)}
    end
  end

  defp validate_keyword(data, {:enum, enum}, _ctx) do
    case enum_member?(enum, data) do
      true -> {:ok, data}
      false -> {:error, Error.of(:enum, data, enum: enum)}
    end
  end

  defp validate_keyword(data, {:all_items, {item_schema, prefix_items_schemas}}, ctx)
       when is_list(data) do
    with {:ok, casted_prefix, offset} <- validate_prefix_items(data, prefix_items_schemas, ctx),
         rest_items = data |> Enum.drop(offset) |> Enum.with_index(offset),
         {:ok, casted_items} <- validate_items(rest_items, item_schema, ctx) do
      {:ok, casted_prefix ++ casted_items}
    end
  end

  defp validate_keyword(data, {:all_items, _}, _ctx) do
    # not a list
    {:ok, data}
  end

  defp validate_keyword(data, {:maximum, max}, _ctx) when is_number(data) do
    if data <= max do
      {:ok, data}
    else
      {:error, Error.of(:maximum, data, maximum: max)}
    end
  end

  defp validate_keyword(data, {:maximum, _}, _ctx) do
    {:ok, data}
  end

  defp validate_keyword(data, {:exclusive_maximum, max}, _ctx) when is_number(data) do
    if data < max do
      {:ok, data}
    else
      {:error, Error.of(:exclusive_maximum, data, exclusive_maximum: max)}
    end
  end

  defp validate_keyword(data, {:exclusive_maximum, _}, _ctx) do
    {:ok, data}
  end

  defp validate_keyword(data, {:minimum, min}, _ctx) when is_number(data) do
    if data >= min do
      {:ok, data}
    else
      {:error, Error.of(:minimum, data, minimum: min)}
    end
  end

  defp validate_keyword(data, {:minimum, _}, _ctx) do
    {:ok, data}
  end

  defp validate_keyword(data, {:exclusive_minimum, min}, _ctx) when is_number(data) do
    if data > min do
      {:ok, data}
    else
      {:error, Error.of(:exclusive_minimum, data, exclusive_minimum: min)}
    end
  end

  defp validate_keyword(data, {:exclusive_minimum, _}, _ctx) do
    {:ok, data}
  end

  defp validate_keyword(data, {:multiple_of, n}, _ctx) when is_integer(data) do
    case rem(data, n) do
      0 -> {:ok, data}
      _ -> {:error, Error.of(:multiple_of, data, multiple_of: n)}
    end
  end

  defp validate_keyword(data, {:max_items, max}, _ctx) when is_list(data) do
    len = length(data)

    if len <= max do
      {:ok, data}
    else
      {:error, Error.of(:max_items, data, max_items: max, len: len)}
    end
  end

  defp validate_keyword(data, {:min_items, min}, _ctx) when is_list(data) do
    len = length(data)

    if len >= min do
      {:ok, data}
    else
      {:error, Error.of(:min_items, data, min_items: min, len: len)}
    end
  end

  defp validate_keyword(data, {:max_length, max}, _ctx) when is_binary(data) do
    len = String.length(data)

    if len <= max do
      {:ok, data}
    else
      {:error, Error.of(:max_length, data, max_items: max, len: len)}
    end
  end

  defp validate_keyword(data, {:max_length, _}, _ctx) do
    {:ok, data}
  end

  defp validate_keyword(data, {:min_length, min}, _ctx) when is_binary(data) do
    len = String.length(data)

    if len >= min do
      {:ok, data}
    else
      {:error, Error.of(:min_length, data, min_items: min, len: len)}
    end
  end

  defp validate_keyword(data, {:min_length, _}, _ctx) do
    {:ok, data}
  end

  defp validate_keyword(data, {:all_of, schemas}, ctx) do
    validate_multi(data, schemas, ctx)
  end

  defp validate_keyword(data, {:one_of, schemas}, ctx) do
    case validate_split(data, schemas, ctx) do
      {[{_, data}], _} ->
        {:ok, data}

      {[], _} ->
        {:error, Error.of(:one_of, data, validated_schemas: [])}

      {[_ | _] = too_much, _} ->
        validated_schemas = Enum.map(too_much, &elem(&1, 0))
        {:error, Error.of(:one_of, data, validated_schemas: validated_schemas)}
    end
  end

  defp validate_keyword(data, {:any_of, schemas}, ctx) do
    case validate_split(data, schemas, ctx) do
      # If multiple schemas validate the data, we take the casted value of the
      # first one, arbitrarily.
      {[{_, data} | _], _} -> {:ok, data}
      {[], _} -> {:error, Error.of(:any_of, data, validated_schemas: [])}
    end
  end

  defp validate_keyword(data, {:required, keys}, _ctx) when is_map(data) do
    case Enum.reject(keys, &Map.has_key?(data, &1)) do
      [] -> {:ok, data}
      missing -> {:error, Error.of(:required, data, missing: missing)}
    end
  end

  defp validate_keyword(data, %BooleanSchema{value: valid?}, _) do
    if valid? do
      {:ok, data}
    else
      {:error, Error.of(:boolean_schema, data, [])}
    end
  end

  defp validate_keyword(data, {:"$ref", %{ns: ns, fragment: fg}}, ctx) do
    case ctx.root.defs do
      %{{^ns, ^fg} => schema} -> validate_keyword(data, schema, ctx)
    end
  end

  defp validate_type(data, :array) do
    is_list(data)
  end

  defp validate_type(data, :object) do
    is_map(data)
  end

  defp validate_type(data, :null) do
    data === nil
  end

  defp validate_type(data, :boolean) do
    is_boolean(data)
  end

  defp validate_type(data, :string) do
    is_binary(data)
  end

  defp validate_type(data, :integer) when is_float(data) do
    fractional_is_zero?(data) && {:swap, trunc(data)}
  end

  defp validate_type(data, :integer) do
    is_integer(data)
  end

  defp validate_type(data, :number) do
    is_number(data)
  end

  # TODO this will not work with large numbers
  defp fractional_is_zero?(n) do
    n - trunc(n) === 0.0
  end

  defp validate_properties(data, nil, _ctx, errors, seen) do
    {data, errors, seen}
  end

  defp validate_properties(data, schema_map, ctx, errors, seen) do
    Enum.reduce(schema_map, {data, errors, seen}, fn
      {key, subschema}, {data, errors, seen} when is_map_key(data, key) ->
        seen = MapSet.put(seen, key)
        value = Map.fetch!(data, key)

        case validate_keyword(value, subschema, ctx) do
          {:ok, casted} ->
            {Map.put(data, key, casted), errors, seen}

          {:error, reason} ->
            {data, [Error.of(:properties, value, key: key, reason: reason) | errors], seen}
        end

      _, acc ->
        acc
    end)
  end

  defp validate_pattern_properties(data, nil, _ctx, errors, seen) do
    {data, errors, seen}
  end

  defp validate_pattern_properties(data, schema_map, ctx, errors, seen) do
    for {{pattern, regex}, subschema} <- schema_map,
        {key, value} <- data,
        Regex.match?(regex, key),
        reduce: {data, errors, seen} do
      {data, errors, seen} ->
        seen = MapSet.put(seen, key)

        case validate_keyword(value, subschema, ctx) do
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

  defp validate_additional_properties(data, nil, _ctx, errors, _seen) do
    {data, errors}
  end

  defp validate_additional_properties(data, subschema, ctx, errors, seen) do
    for {key, value} <- data, not MapSet.member?(seen, key), reduce: {data, errors} do
      {data, errors} ->
        case validate_keyword(value, subschema, ctx) do
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

  defp validate_items(items_with_index, nil = _items_chema, _ctx) do
    {:ok, Enum.map(items_with_index, fn {item, _index} -> item end)}
  end

  defp validate_items(items_with_index, items_chema, ctx) do
    items_with_index
    |> Enum.reduce({[], []}, fn {item, index}, {items, errors} ->
      case validate_keyword(item, items_chema, ctx) do
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

  defp validate_prefix_items(_values, nil = _prefix_schemas, _ctx) do
    {:ok, [], 0}
  end

  defp validate_prefix_items(values, schemas, ctx) do
    validate_prefix_items(values, schemas, ctx, 0, [], [])
  end

  defp validate_prefix_items([vh | vt], [sh | st], ctx, index, validated, errors) do
    case validate_keyword(vh, sh, ctx) do
      {:ok, data} ->
        validate_prefix_items(vt, st, ctx, index + 1, [data | validated], errors)

      {:error, reason} ->
        validate_prefix_items(vt, st, ctx, index + 1, validated, [
          Error.of(:item_error, vh, index: index, reason: reason, prefix: true) | errors
        ])
    end
  end

  defp validate_prefix_items(_vt, _, _ctx, _, _, [_ | _] = errors) do
    # we do not return the tail
    {:error, Error.group(errors)}
  end

  defp validate_prefix_items(_vt, [], _ctx, offset, validated, []) do
    # we do not return the tail
    {:ok, :lists.reverse(validated), offset}
  end

  defp validate_prefix_items([], [_schema | _], _ctx, offset, validated, []) do
    # fewer items than prefix is valid
    {:ok, :lists.reverse(validated), offset}
  end

  # special case when the data itself is an enum
  defp enum_member?(enum, data) when is_list(data) do
    Enum.find(enum, &match_enum_list(&1, data)) != nil
  end

  defp enum_member?(enum, n) when is_number(n) do
    Enum.member?(enum, n) ||
      case fractional_is_zero?(n) do
        true -> Enum.member?(enum, trunc(n))
        false -> false
      end
  end

  defp enum_member?(enum, item) do
    Enum.member?(enum, item)
  end

  # match the data list with a member of an enum that should also be a nested
  # list.
  defp match_enum_list([same | candidate], [same | data]) do
    match_enum_list(candidate, data)
  end

  # handle integer/float matching with `==`
  defp match_enum_list([ch | candidate], [dh | data]) when ch == dh do
    match_enum_list(candidate, data)
  end

  defp match_enum_list([], []) do
    true
  end

  defp match_enum_list(_, _) do
    false
  end
end
