defmodule Moonwalk.Schema.Vocabulary.V202012.Validation do
  alias Moonwalk.Schema.Validator.Context
  use Moonwalk.Schema.Vocabulary

  def init_validators do
    []
  end

  todo_take_keywords ~w(
    dependentRequired
    maxContains
    maxProperties
    minContains
    minProperties
  )

  def take_keyword({"type", t}, vds, ctx) do
    {:ok, [{:type, valid_type!(t)} | vds], ctx}
  end

  def take_keyword({"maximum", maximum}, acc, ctx) do
    take_number(:maximum, maximum, acc, ctx)
  end

  def take_keyword({"exclusiveMaximum", exclusive_maximum}, acc, ctx) do
    take_number(:exclusive_maximum, exclusive_maximum, acc, ctx)
  end

  def take_keyword({"minimum", minimum}, acc, ctx) do
    take_number(:minimum, minimum, acc, ctx)
  end

  def take_keyword({"exclusiveMinimum", exclusive_minimum}, acc, ctx) do
    take_number(:exclusive_minimum, exclusive_minimum, acc, ctx)
  end

  def take_keyword({"minItems", min_items}, acc, ctx) do
    take_integer(:min_items, min_items, acc, ctx)
  end

  def take_keyword({"maxItems", max_items}, acc, ctx) do
    take_integer(:max_items, max_items, acc, ctx)
  end

  def take_keyword({"required", required}, acc, ctx) when is_list(required) do
    {:ok, [{:required, required} | acc], ctx}
  end

  def take_keyword({"multipleOf", zero}, _acc, _ctx) when zero in [0, 0.0] do
    {:error, "mutipleOf zero is not allowed"}
  end

  def take_keyword({"multipleOf", multiple_of}, acc, ctx) do
    take_number(:multiple_of, multiple_of, acc, ctx)
  end

  def take_keyword({"const", const}, acc, ctx) do
    {:ok, [{:const, const} | acc], ctx}
  end

  def take_keyword({"maxLength", max_length}, acc, ctx) do
    take_integer(:max_length, max_length, acc, ctx)
  end

  def take_keyword({"minLength", min_length}, acc, ctx) do
    take_integer(:min_length, min_length, acc, ctx)
  end

  def take_keyword({"enum", enum}, acc, ctx) do
    {:ok, [{:enum, enum} | acc], ctx}
  end

  def take_keyword({"pattern", pattern}, acc, ctx) do
    case Regex.compile(pattern) do
      {:ok, re} -> {:ok, [{:pattern, re} | acc], ctx}
      {:error, _} -> {:error, {:invalid_pattern, pattern}}
    end
  end

  def take_keyword({"uniqueItems", unique?}, acc, ctx) do
    if unique? do
      {:ok, [{:unique_items, true} | acc], ctx}
    else
      {:ok, acc, ctx}
    end
  end

  ignore_any_keyword()

  # ---------------------------------------------------------------------------

  def finalize_validators([]) do
    :ignore
  end

  def finalize_validators(list) do
    list
  end

  # -----------------------------------------------------------------------------

  defp valid_type!(list) when is_list(list) do
    Enum.map(list, &valid_type!/1)
  end

  defp valid_type!("array") do
    :array
  end

  defp valid_type!("object") do
    :object
  end

  defp valid_type!("null") do
    :null
  end

  defp valid_type!("boolean") do
    :boolean
  end

  defp valid_type!("string") do
    :string
  end

  defp valid_type!("integer") do
    :integer
  end

  defp valid_type!("number") do
    :number
  end

  def validate(data, vds, ctx) do
    run_validators(data, vds, ctx, :validate_keyword)
  end

  defp validate_keyword(data, {:type, ts}, ctx) when is_list(ts) do
    Enum.find_value(ts, fn t ->
      case validate_type(data, t) do
        true -> {:ok, data}
        false -> nil
        {:swap, new_data} -> {:ok, new_data}
      end
    end)
    |> case do
      {:ok, data} -> {:ok, data}
      nil -> {:error, Context.make_error(ctx, :type, data, type: ts)}
    end
  end

  defp validate_keyword(data, {:type, t}, ctx) do
    case validate_type(data, t) do
      true -> {:ok, data}
      false -> {:error, Context.make_error(ctx, :type, data, type: t)}
      {:swap, new_data} -> {:ok, new_data}
    end
  end

  defp validate_keyword(data, {:maximum, n}, ctx) when is_number(data) do
    case data <= n do
      true -> {:ok, data}
      false -> {:error, Context.make_error(ctx, :maximum, data, n: n)}
    end
  end

  pass validate_keyword(data, {:maximum, _}, _)

  defp validate_keyword(data, {:exclusive_maximum, n}, ctx) when is_number(data) do
    case data < n do
      true -> {:ok, data}
      false -> {:error, Context.make_error(ctx, :exclusive_maximum, data, n: n)}
    end
  end

  pass validate_keyword(data, {:exclusive_maximum, _}, _)

  defp validate_keyword(data, {:minimum, n}, ctx) when is_number(data) do
    case data >= n do
      true -> {:ok, data}
      false -> {:error, Context.make_error(ctx, :minimum, data, n: n)}
    end
  end

  pass validate_keyword(data, {:minimum, _}, _)

  defp validate_keyword(data, {:exclusive_minimum, n}, ctx) when is_number(data) do
    case data > n do
      true -> {:ok, data}
      false -> {:error, Context.make_error(ctx, :exclusive_minimum, data, n: n)}
    end
  end

  pass validate_keyword(data, {:exclusive_minimum, _}, _)

  defp validate_keyword(data, {:max_items, max}, ctx) when is_list(data) do
    len = length(data)

    if len <= max do
      {:ok, data}
    else
      {:error, Context.make_error(ctx, :max_items, data, max_items: max, len: len)}
    end
  end

  pass validate_keyword(data, {:max_items, _}, _)

  defp validate_keyword(data, {:min_items, min}, ctx) when is_list(data) do
    len = length(data)

    if len >= min do
      {:ok, data}
    else
      {:error, Context.make_error(ctx, :min_items, data, min_items: min, len: len)}
    end
  end

  pass validate_keyword(data, {:min_items, _}, _)

  defp validate_keyword(data, {:multiple_of, n}, ctx) when is_number(data) do
    case fractional_is_zero?(data / n) do
      true -> {:ok, data}
      false -> {:error, Context.make_error(ctx, :multiple_of, data, multiple_of: n)}
    end
  rescue
    # Rescue infinite division (huge numbers divided by float)
    _ in ArithmeticError -> {:error, Context.make_error(ctx, :multiple_of, data, multiple_of: n)}
  end

  pass validate_keyword(data, {:multiple_of, _}, _)

  defp validate_keyword(data, {:required, keys}, ctx) when is_map(data) do
    case keys -- Map.keys(data) do
      [] -> {:ok, data}
      missing -> {:error, Context.make_error(ctx, :requred, data, required: missing)}
    end
  end

  pass validate_keyword(data, {:required, _}, _)

  defp validate_keyword(data, {:max_length, max}, ctx) when is_binary(data) do
    len = String.length(data)

    if len <= max do
      {:ok, data}
    else
      {:error, Context.make_error(ctx, :max_length, data, max_items: max, len: len)}
    end
  end

  pass validate_keyword(data, {:max_length, _}, _)

  defp validate_keyword(data, {:min_length, min}, ctx) when is_binary(data) do
    len = String.length(data)

    if len >= min do
      {:ok, data}
    else
      {:error, Context.make_error(ctx, :min_length, data, min_items: min, len: len)}
    end
  end

  pass validate_keyword(data, {:min_length, _}, _)

  defp validate_keyword(data, {:const, const}, ctx) do
    # 1 == 1.0 should be true according to JSON Schema specs
    if data == const do
      {:ok, data}
    else
      {:error, Context.make_error(ctx, :const, data, const: const)}
    end
  end

  defp validate_keyword(data, {:enum, enum}, ctx) do
    # validate 1 == 1.0 or 1.0 == 1
    if Enum.any?(enum, &(&1 == data)) do
      {:ok, data}
    else
      {:error, Context.make_error(ctx, :enum, data, enum: enum)}
    end
  end

  defp validate_keyword(data, {:pattern, re}, ctx) when is_binary(data) do
    if Regex.match?(re, data) do
      {:ok, data}
    else
      {:error, Context.make_error(ctx, :pattern, data, pattern: re.source)}
    end
  end

  pass validate_keyword(data, {:pattern, _}, _)

  defp validate_keyword(data, {:unique_items, true}, ctx) when is_list(data) do
    data
    |> Enum.with_index()
    |> Enum.reduce({[], %{}}, fn {item, index}, {errors, seen} ->
      if Map.has_key?(seen, item) do
        {[Context.make_error(ctx, :unique_items_item, item, index: index) | errors], seen}
      else
        {errors, Map.put(seen, item, true)}
      end
    end)
    |> case do
      {[], _} -> {:ok, data}
      {errors, _} -> {:error, Context.make_error(ctx, :unique_items, data, errors: errors)}
    end
  end

  # ---------------------------------------------------------------------------

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
  defp fractional_is_zero?(n) when is_float(n) do
    n - trunc(n) === 0.0
  end
end
