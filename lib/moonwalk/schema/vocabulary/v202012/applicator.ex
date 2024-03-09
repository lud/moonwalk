defmodule Moonwalk.Schema.Vocabulary.V202012.Applicator do
  alias Moonwalk.Schema
  alias Moonwalk.Schema.Validator
  alias Moonwalk.Schema.Validator.Context
  use Moonwalk.Schema.Vocabulary

  def init_validators do
    []
  end

  todo_take_keywords(~w(
    additionalItems
    allOf
    anyOf
    contains
    else
    if
    items
    not
    oneOf
    propertyNames
    then
  ))

  def take_keyword({"properties", properties}, acc, ctx) do
    properties
    |> Enum.reduce_while({:ok, %{}, ctx}, fn {k, pschema}, {:ok, acc, ctx} ->
      case Schema.denormalize_sub(pschema, ctx) do
        {:ok, subvalidators, ctx} -> {:cont, {:ok, Map.put(acc, k, subvalidators), ctx}}
        {:error, _} = err -> {:halt, err}
      end
    end)
    |> case do
      {:ok, subvds, ctx} -> {:ok, [{:properties, subvds} | acc], ctx}
      {:error, _} = err -> err
    end
  end

  def take_keyword({"additionalProperties", additional_properties}, acc, ctx) do
    with {:ok, subvds, ctx} <- Schema.denormalize_sub(additional_properties, ctx) do
      {:ok, [{:additional_properties, subvds} | acc], ctx}
    end
  end

  def take_keyword({"patternProperties", pattern_properties}, acc, ctx) do
    pattern_properties
    |> Enum.reduce_while({:ok, %{}, ctx}, fn {k, pschema}, {:ok, acc, ctx} ->
      with {:ok, re} <- Regex.compile(k),
           {:ok, subvalidators, ctx} <- Schema.denormalize_sub(pschema, ctx) do
        {:cont, {:ok, Map.put(acc, {k, re}, subvalidators), ctx}}
      else
        {:error, _} = err -> {:halt, err}
      end
    end)
    |> case do
      {:ok, subvds, ctx} -> {:ok, [{:pattern_properties, subvds} | acc], ctx}
      {:error, _} = err -> err
    end
  end

  ignore_any_keyword()

  def finalize_validators([]) do
    :ignore
  end

  def finalize_validators(validators) do
    {properties, validators} = Keyword.pop(validators, :properties, nil)
    {pattern_properties, validators} = Keyword.pop(validators, :pattern_properties, nil)
    {additional_properties, validators} = Keyword.pop(validators, :additional_properties, nil)

    Keyword.put(
      validators,
      :all_properties,
      {properties, pattern_properties, additional_properties}
    )
  end

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

  defp validate_properties(data, nil, _ctx, errors, seen) do
    {data, errors, seen}
  end

  defp validate_properties(data, schema_map, ctx, errors, seen) do
    Enum.reduce(schema_map, {data, errors, seen}, fn
      {key, subvds}, {data, errors, seen} when is_map_key(data, key) ->
        seen = MapSet.put(seen, key)
        value = Map.fetch!(data, key)

        case Validator.validate_sub(value, subvds, ctx) do
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
    for {{pattern, regex}, subvds} <- schema_map,
        {key, value} <- data,
        Regex.match?(regex, key),
        reduce: {data, errors, seen} do
      {data, errors, seen} ->
        seen = MapSet.put(seen, key)

        case Validator.validate_sub(value, subvds, ctx) do
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

  defp validate_additional_properties(data, subvds, ctx, errors, seen) do
    for {key, value} <- data, not MapSet.member?(seen, key), reduce: {data, errors} do
      {data, errors} ->
        case Validator.validate_sub(value, subvds, ctx) do
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
