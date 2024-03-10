defmodule Moonwalk.Schema.Vocabulary.V202012.Applicator do
  alias Moonwalk.Helpers
  alias Moonwalk.Schema
  alias Moonwalk.Schema.Validator
  alias Moonwalk.Schema.Validator.Context
  use Moonwalk.Schema.Vocabulary

  def init_validators do
    []
  end

  todo_take_keywords(~w(
    additionalItems
    contains
    else
    if
    items
    not
    propertyNames
    then
  ))

  def take_keyword({"properties", properties}, acc, ctx) do
    properties
    |> Helpers.reduce_while_ok({%{}, ctx}, fn {k, pschema}, {acc, ctx} ->
      case Schema.denormalize_sub(pschema, ctx) do
        {:ok, subvalidators, ctx} -> {:ok, {Map.put(acc, k, subvalidators), ctx}}
        {:error, _} = err -> err
      end
    end)
    |> case do
      {:ok, {subvalidators, ctx}} -> {:ok, [{:properties, subvalidators} | acc], ctx}
      {:error, _} = err -> err
    end
  end

  def take_keyword({"additionalProperties", additional_properties}, acc, ctx) do
    with {:ok, subvalidators, ctx} <- Schema.denormalize_sub(additional_properties, ctx) do
      {:ok, [{:additional_properties, subvalidators} | acc], ctx}
    end
  end

  def take_keyword({"patternProperties", pattern_properties}, acc, ctx) do
    pattern_properties
    |> Helpers.reduce_while_ok({%{}, ctx}, fn {k, pschema}, {acc, ctx} ->
      with {:ok, re} <- Regex.compile(k),
           {:ok, subvalidators, ctx} <- Schema.denormalize_sub(pschema, ctx) do
        {:ok, {Map.put(acc, {k, re}, subvalidators), ctx}}
      end
    end)
    |> case do
      {:ok, {subvalidators, ctx}} -> {:ok, [{:pattern_properties, subvalidators} | acc], ctx}
      {:error, _} = err -> err
    end
  end

  def take_keyword({"allOf", [_ | _] = all_of}, acc, ctx) do
    case build_sub_list(all_of, ctx) do
      {:ok, subvalidators, ctx} -> {:ok, [{:all_of, :lists.reverse(subvalidators)} | acc], ctx}
      {:error, _} = err -> err
    end
  end

  def take_keyword({"anyOf", [_ | _] = any_of}, acc, ctx) do
    case build_sub_list(any_of, ctx) do
      {:ok, subvalidators, ctx} -> {:ok, [{:any_of, :lists.reverse(subvalidators)} | acc], ctx}
      {:error, _} = err -> err
    end
  end

  def take_keyword({"oneOf", [_ | _] = one_of}, acc, ctx) do
    case build_sub_list(one_of, ctx) do
      {:ok, subvalidators, ctx} -> {:ok, [{:one_of, :lists.reverse(subvalidators)} | acc], ctx}
      {:error, _} = err -> err
    end
  end

  ignore_any_keyword()

  # ---------------------------------------------------------------------------

  defp build_sub_list(subschemas, ctx) do
    Helpers.reduce_while_ok(subschemas, {[], ctx}, fn subschema, {acc, ctx} ->
      case Schema.denormalize_sub(subschema, ctx) do
        {:ok, subvalidators, ctx} -> {:ok, {[subvalidators | acc], ctx}}
        {:error, _} = err -> err
      end
    end)
    |> case do
      {:ok, {subvalidators, ctx}} -> {:ok, :lists.reverse(subvalidators), ctx}
      {:error, _} = err -> err
    end
  end

  # ---------------------------------------------------------------------------
  def finalize_validators([]) do
    :ignore
  end

  def finalize_validators(validators) do
    {properties, validators} = Keyword.pop(validators, :properties, nil)
    {pattern_properties, validators} = Keyword.pop(validators, :pattern_properties, nil)
    {additional_properties, validators} = Keyword.pop(validators, :additional_properties, nil)

    case {properties, pattern_properties, additional_properties} do
      {nil, nil, nil} -> validators
      some -> Keyword.put(validators, :all_properties, some)
    end
  end

  # ---------------------------------------------------------------------------

  def validate(data, vds, ctx) do
    run_validators(data, vds, ctx, :validate_keyword)
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
      _ -> {:error, Context.group_error(ctx, data, errors)}
    end
  end

  defp validate_keyword(data, {:all_properties, _}, _ctx) do
    {:ok, data}
  end

  defp validate_keyword(data, {:one_of, subvalidators}, ctx) do
    case validate_split(subvalidators, data, ctx) do
      {[{_, data}], _} ->
        {:ok, data}

      {[], _} ->
        {:error, Context.make_error(ctx, :one_of, data, validated_schemas: [])}

      {[_ | _] = too_much, _} ->
        validated_schemas = Enum.map(too_much, &elem(&1, 0))
        {:error, Context.make_error(ctx, :one_of, data, validated_schemas: validated_schemas)}
    end
  end

  defp validate_keyword(data, {:any_of, subvalidators}, ctx) do
    case validate_split(subvalidators, data, ctx) do
      # If multiple schemas validate the data, we take the casted value of the
      # first one, arbitrarily.
      {[{_, data} | _], _} -> {:ok, data}
      {[], _} -> {:error, Context.make_error(ctx, :any_of, data, validated_schemas: [])}
    end
  end

  defp validate_keyword(data, {:all_of, subvalidators}, ctx) do
    case validate_split(subvalidators, data, ctx) do
      # If multiple schemas validate the data, we take the casted value of the
      # first one, arbitrarily.
      {[{_, data} | _], []} -> {:ok, data}
      {_, [_ | _] = invalid} -> {:error, Context.make_error(ctx, :all_of, data, invalidated_schemas: invalid)}
    end
  end

  # ---------------------------------------------------------------------------

  # inversed split: we split the validators between those that validate the data
  # and those who don't.
  defp validate_split(validators, data, ctx) do
    {valids, invalids} =
      Enum.reduce(validators, {[], []}, fn vd, {valids, invalids} ->
        case Validator.validate_sub(data, vd, ctx) do
          {:ok, data} -> {[{vd, data} | valids], invalids}
          {:error, reason} -> {valids, [{vd, reason} | invalids]}
        end
      end)

    {:lists.reverse(valids), :lists.reverse(invalids)}
  end

  defp validate_properties(data, nil, _ctx, errors, seen) do
    {data, errors, seen}
  end

  defp validate_properties(data, schema_map, ctx, errors, seen) do
    Enum.reduce(schema_map, {data, errors, seen}, fn
      {key, subvalidators}, {data, errors, seen} when is_map_key(data, key) ->
        seen = MapSet.put(seen, key)
        value = Map.fetch!(data, key)

        case Validator.validate_sub(value, subvalidators, ctx) do
          {:ok, casted} ->
            {Map.put(data, key, casted), errors, seen}

          {:error, reason} ->
            {data, [Context.make_error(ctx, :properties, value, key: key, reason: reason) | errors], seen}
        end

      _, acc ->
        acc
    end)
  end

  defp validate_pattern_properties(data, nil, _ctx, errors, seen) do
    {data, errors, seen}
  end

  defp validate_pattern_properties(data, schema_map, ctx, errors, seen) do
    for {{pattern, regex}, subvalidators} <- schema_map,
        {key, value} <- data,
        Regex.match?(regex, key),
        reduce: {data, errors, seen} do
      {data, errors, seen} ->
        seen = MapSet.put(seen, key)

        case Validator.validate_sub(value, subvalidators, ctx) do
          {:ok, casted} ->
            {Map.put(data, key, casted), errors, seen}

          {:error, reason} ->
            error =
              Context.make_error(ctx, :pattern_properties, value,
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

  defp validate_additional_properties(data, subvalidators, ctx, errors, seen) do
    for {key, value} <- data, not MapSet.member?(seen, key), reduce: {data, errors} do
      {data, errors} ->
        case Validator.validate_sub(value, subvalidators, ctx) do
          {:ok, casted} ->
            {Map.put(data, key, casted), errors}

          {:error, reason} ->
            error =
              Context.make_error(ctx, :additional_properties, value,
                key: key,
                reason: reason
              )

            {data, [error | errors]}
        end
    end
  end
end
