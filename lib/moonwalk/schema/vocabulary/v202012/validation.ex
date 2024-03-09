defmodule Moonwalk.Schema.Vocabulary.V202012.Validation do
  alias Moonwalk.Schema.Validator.Context
  use Moonwalk.Schema.Vocabulary

  def init_validators do
    []
  end

  todo_take_keywords ~w(
    const
    dependentRequired
    enum
    maxContains
    maxLength
    maxProperties
    minContains
    minLength
    minProperties
    multipleOf
    pattern
    required
    uniqueItems
  )

  def take_keyword({"type", t}, vds, ctx) do
    {:ok, [{:type, valid_type!(t)} | vds], ctx}
  end

  def take_keyword({"maximum", maximum}, acc, ctx) do
    with :ok <- check_number(maximum) do
      {:ok, [{:maximum, maximum} | acc], ctx}
    end
  end

  def take_keyword({"exclusiveMaximum", exclusive_maximum}, acc, ctx) do
    with :ok <- check_number(exclusive_maximum) do
      {:ok, [{:exclusive_maximum, exclusive_maximum} | acc], ctx}
    end
  end

  def take_keyword({"minimum", minimum}, acc, ctx) do
    with :ok <- check_number(minimum) do
      {:ok, [{:minimum, minimum} | acc], ctx}
    end
  end

  def take_keyword({"exclusiveMinimum", exclusive_minimum}, acc, ctx) do
    with :ok <- check_number(exclusive_minimum) do
      {:ok, [{:exclusive_minimum, exclusive_minimum} | acc], ctx}
    end
  end

  def take_keyword({"minItems", min_items}, acc, ctx) do
    with :ok <- check_number(min_items) do
      {:ok, [{:min_items, min_items} | acc], ctx}
    end
  end

  def take_keyword({"maxItems", max_items}, acc, ctx) do
    with :ok <- check_number(max_items) do
      {:ok, [{:max_items, max_items} | acc], ctx}
    end
  end

  ignore_any_keyword()

  defp check_number(n) when is_number(n) do
    :ok
  end

  defp check_number(other) do
    {:error, "not a number: #{inspect(other)}"}
  end

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

  pass validate_keyword(data, {:exclusive_maximum, _}, _) when not is_number(data)
  pass validate_keyword(data, {:exclusive_minimum, _}, _) when not is_number(data)
  pass validate_keyword(data, {:maximum, _}, _) when not is_number(data)
  pass validate_keyword(data, {:minimum, _}, _) when not is_number(data)
  pass validate_keyword(data, {:max_items, _}, _) when not is_list(data)
  pass validate_keyword(data, {:min_items, _}, _) when not is_list(data)

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
      nil -> {:error, Context.type_error(ctx, data, ts)}
    end
  end

  defp validate_keyword(data, {:type, t}, ctx) do
    case validate_type(data, t) do
      true -> {:ok, data}
      false -> {:error, Context.type_error(ctx, data, t)}
      {:swap, new_data} -> {:ok, new_data}
    end
  end

  defp validate_keyword(data, {:maximum, n}, ctx) when is_number(data) do
    case data <= n do
      true -> {:ok, data}
      false -> {:error, Context.make_error(ctx, :maximum, data, n: n)}
    end
  end

  defp validate_keyword(data, {:maximum, _}, _ctx) do
    {:ok, data}
  end

  defp validate_keyword(data, {:exclusive_maximum, n}, ctx) when is_number(data) do
    case data < n do
      true -> {:ok, data}
      false -> {:error, Context.make_error(ctx, :exclusive_maximum, data, n: n)}
    end
  end

  defp validate_keyword(data, {:minimum, n}, ctx) when is_number(data) do
    case data >= n do
      true -> {:ok, data}
      false -> {:error, Context.make_error(ctx, :minimum, data, n: n)}
    end
  end

  defp validate_keyword(data, {:exclusive_minimum, n}, ctx) when is_number(data) do
    case data > n do
      true -> {:ok, data}
      false -> {:error, Context.make_error(ctx, :exclusive_minimum, data, n: n)}
    end
  end

  defp validate_keyword(data, {:max_items, max}, ctx) when is_list(data) do
    len = length(data)

    if len <= max do
      {:ok, data}
    else
      {:error, Context.make_error(ctx, :max_items, data, max_items: max, len: len)}
    end
  end

  defp validate_keyword(data, {:min_items, min}, ctx) when is_list(data) do
    len = length(data)

    if len >= min do
      {:ok, data}
    else
      {:error, Context.make_error(ctx, :min_items, data, min_items: min, len: len)}
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
  defp fractional_is_zero?(n) do
    n - trunc(n) === 0.0
  end

  defp validate_properties(data, nil, _ctx, errors, seen) do
    {data, errors, seen}
  end
end
