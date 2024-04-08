defmodule Moonwalk.Schema.Vocabulary.V202012.Validation do
  alias Moonwalk.Schema.Validator
  alias Moonwalk.Helpers
  use Moonwalk.Schema.Vocabulary, priority: 300

  @impl true
  def init_validators do
    []
  end

  @impl true

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

  def take_keyword({"minProperties", min_properties}, acc, ctx) do
    take_integer(:min_properties, min_properties, acc, ctx)
  end

  def take_keyword({"maxProperties", max_properties}, acc, ctx) do
    take_integer(:max_properties, max_properties, acc, ctx)
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

  def take_keyword({keyword, _}, _acc, _ctx) when keyword in ["minContains", "maxContains"] do
    # This is handled by the Applicator module IF the validation vocabulary is
    # enabled
    :ignore
  end

  def take_keyword({"dependentRequired", dependent_required}, acc, ctx) do
    {:ok, [{:dependent_required, dependent_required} | acc], ctx}
  end

  ignore_any_keyword()

  # ---------------------------------------------------------------------------

  @impl true
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

  @impl true
  def validate(data, vds, vdr) do
    run_validators(data, vds, vdr, &validate_keyword/3)
  end

  defp validate_keyword(data, {:type, ts}, vdr) when is_list(ts) do
    Enum.find_value(ts, fn t ->
      case validate_type(data, t) do
        true -> {:ok, data}
        false -> nil
        {:swap, new_data} -> {:ok, new_data}
      end
    end)
    |> case do
      {:ok, data} -> {:ok, data, vdr}
      nil -> {:error, Validator.with_error(vdr, :type, data, type: ts)}
    end
  end

  defp validate_keyword(data, {:type, t}, vdr) do
    case validate_type(data, t) do
      true -> {:ok, data, vdr}
      false -> {:error, Validator.with_error(vdr, :type, data, type: t)}
      {:swap, new_data} -> {:ok, new_data, vdr}
    end
  end

  defp validate_keyword(data, {:maximum, n}, vdr) when is_number(data) do
    case data <= n do
      true -> {:ok, data, vdr}
      false -> {:error, Validator.with_error(vdr, :maximum, data, n: n)}
    end
  end

  pass validate_keyword({:maximum, _})

  defp validate_keyword(data, {:exclusive_maximum, n}, vdr) when is_number(data) do
    case data < n do
      true -> {:ok, data, vdr}
      false -> {:error, Validator.with_error(vdr, :exclusive_maximum, data, n: n)}
    end
  end

  pass validate_keyword({:exclusive_maximum, _})

  defp validate_keyword(data, {:minimum, n}, vdr) when is_number(data) do
    case data >= n do
      true -> {:ok, data, vdr}
      false -> {:error, Validator.with_error(vdr, :minimum, data, n: n)}
    end
  end

  pass validate_keyword({:minimum, _})

  defp validate_keyword(data, {:exclusive_minimum, n}, vdr) when is_number(data) do
    case data > n do
      true -> {:ok, data, vdr}
      false -> {:error, Validator.with_error(vdr, :exclusive_minimum, data, n: n)}
    end
  end

  pass validate_keyword({:exclusive_minimum, _})

  defp validate_keyword(data, {:max_items, max}, vdr) when is_list(data) do
    len = length(data)

    if len <= max do
      {:ok, data, vdr}
    else
      {:error, Validator.with_error(vdr, :max_items, data, max_items: max, len: len)}
    end
  end

  pass validate_keyword({:max_items, _})

  defp validate_keyword(data, {:min_items, min}, vdr) when is_list(data) do
    len = length(data)

    if len >= min do
      {:ok, data, vdr}
    else
      {:error, Validator.with_error(vdr, :min_items, data, min_items: min, len: len)}
    end
  end

  pass validate_keyword({:min_items, _})

  defp validate_keyword(data, {:multiple_of, n}, vdr) when is_number(data) do
    case Helpers.fractional_is_zero?(data / n) do
      true -> {:ok, data, vdr}
      false -> {:error, Validator.with_error(vdr, :multiple_of, data, multiple_of: n)}
    end
  rescue
    # Rescue infinite division (huge numbers divided by float)
    _ in ArithmeticError -> {:error, Validator.with_error(vdr, :multiple_of, data, multiple_of: n)}
  end

  pass validate_keyword({:multiple_of, _})

  defp validate_keyword(data, {:required, required_keys}, vdr) when is_map(data) do
    case required_keys -- Map.keys(data) do
      [] -> {:ok, data, vdr}
      missing -> {:error, Validator.with_error(vdr, :required, data, required: missing)}
    end
  end

  pass validate_keyword({:required, _})

  defp validate_keyword(data, {:dependent_required, map}, vdr) when is_map(data) do
    Validator.apply_all_fun(data, map, vdr, fn
      data, {parent_key, required_keys}, vdr when is_map_key(data, parent_key) ->
        case required_keys -- Map.keys(data) do
          [] ->
            {:ok, data, vdr}

          missing ->
            {:error, Validator.with_error(vdr, :dependent_required, data, parent: parent_key, required: missing)}
        end

      data, {_, _}, vdr ->
        {:ok, data, vdr}
    end)
  end

  pass validate_keyword({:dependent_required, _})

  defp validate_keyword(data, {:max_length, max}, vdr) when is_binary(data) do
    len = String.length(data)

    if len <= max do
      {:ok, data, vdr}
    else
      {:error, Validator.with_error(vdr, :max_length, data, max_items: max, len: len)}
    end
  end

  pass validate_keyword({:max_length, _})

  defp validate_keyword(data, {:min_length, min}, vdr) when is_binary(data) do
    len = String.length(data)

    if len >= min do
      {:ok, data, vdr}
    else
      {:error, Validator.with_error(vdr, :min_length, data, min_items: min, len: len)}
    end
  end

  pass validate_keyword({:min_length, _})

  defp validate_keyword(data, {:const, const}, vdr) do
    # 1 == 1.0 should be true according to JSON Schema specs
    if data == const do
      {:ok, data, vdr}
    else
      {:error, Validator.with_error(vdr, :const, data, const: const)}
    end
  end

  defp validate_keyword(data, {:enum, enum}, vdr) do
    # validate 1 == 1.0 or 1.0 == 1
    if Enum.any?(enum, &(&1 == data)) do
      {:ok, data, vdr}
    else
      {:error, Validator.with_error(vdr, :enum, data, enum: enum)}
    end
  end

  defp validate_keyword(data, {:pattern, re}, vdr) when is_binary(data) do
    if Regex.match?(re, data) do
      {:ok, data, vdr}
    else
      {:error, Validator.with_error(vdr, :pattern, data, pattern: re.source)}
    end
  end

  pass validate_keyword({:pattern, _})

  defp validate_keyword(data, {:unique_items, true}, vdr) when is_list(data) do
    data
    |> Enum.with_index()
    |> Enum.reduce({[], %{}}, fn {item, index}, {duplicate_indices, seen} ->
      case Map.fetch(seen, item) do
        {:ok, seen_index} -> {[{index, seen_index} | duplicate_indices], seen}
        :error -> {duplicate_indices, Map.put(seen, item, index)}
      end
    end)
    |> case do
      {[], _} -> {:ok, data, vdr}
      {duplicates, _} -> {:error, Validator.with_error(vdr, :unique_items, data, duplicates: Map.new(duplicates))}
    end
  end

  pass validate_keyword({:unique_items, true})

  defp validate_keyword(data, {:min_properties, n}, vdr) when is_map(data) do
    case map_size(data) do
      size when size < n -> {:error, Validator.with_error(vdr, :min_properties, data, min_properties: n, size: size)}
      _ -> {:ok, data, vdr}
    end
  end

  pass validate_keyword({:min_properties, _})

  defp validate_keyword(data, {:max_properties, n}, vdr) when is_map(data) do
    case map_size(data) do
      size when size > n -> {:error, Validator.with_error(vdr, :max_properties, data, max_properties: n, size: size)}
      _ -> {:ok, data, vdr}
    end
  end

  pass validate_keyword({:max_properties, _})

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
    Helpers.fractional_is_zero?(data) && {:swap, trunc(data)}
  end

  defp validate_type(data, :integer) do
    is_integer(data)
  end

  defp validate_type(data, :number) do
    is_number(data)
  end
end
