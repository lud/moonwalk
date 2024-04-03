defmodule Moonwalk.Schema.Vocabulary.V202012.Applicator do
  alias Moonwalk.Schema.Builder
  alias Moonwalk.Helpers
  alias Moonwalk.Schema.Validator
  alias Moonwalk.Schema.Validator.Context
  use Moonwalk.Schema.Vocabulary

  def init_validators do
    []
  end

  todo_take_keywords(~w(
    additionalItems


    not
  ))

  def take_keyword({"properties", properties}, acc, ctx) do
    properties
    |> Helpers.reduce_ok({%{}, ctx}, fn {k, pschema}, {acc, ctx} ->
      case Builder.build_sub(pschema, ctx) do
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
    take_sub(:additional_properties, additional_properties, acc, ctx)
  end

  def take_keyword({"patternProperties", pattern_properties}, acc, ctx) do
    pattern_properties
    |> Helpers.reduce_ok({%{}, ctx}, fn {k, pschema}, {acc, ctx} ->
      with {:ok, re} <- Regex.compile(k),
           {:ok, subvalidators, ctx} <- Builder.build_sub(pschema, ctx) do
        {:ok, {Map.put(acc, {k, re}, subvalidators), ctx}}
      end
    end)
    |> case do
      {:ok, {subvalidators, ctx}} -> {:ok, [{:pattern_properties, subvalidators} | acc], ctx}
      {:error, _} = err -> err
    end
  end

  def take_keyword({"items", items}, acc, ctx) do
    take_sub(:items, items, acc, ctx)
  end

  def take_keyword({"prefixItems", prefix_items}, acc, ctx) do
    prefix_items
    |> Helpers.reduce_ok({[], ctx}, fn item, {subacc, ctx} ->
      case Builder.build_sub(item, ctx) do
        {:ok, subvalidators, ctx} -> {:ok, {[subvalidators | subacc], ctx}}
        {:error, _} = err -> err
      end
    end)
    |> case do
      {:ok, {subvalidators, ctx}} -> {:ok, [{:prefix_items, :lists.reverse(subvalidators)} | acc], ctx}
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

  def take_keyword({"if", if_schema}, acc, ctx) do
    take_sub(:if, if_schema, acc, ctx)
  end

  def take_keyword({"then", then}, acc, ctx) do
    take_sub(:then, then, acc, ctx)
  end

  def take_keyword({"else", else_schema}, acc, ctx) do
    take_sub(:else, else_schema, acc, ctx)
  end

  def take_keyword({"propertyNames", property_names}, acc, ctx) do
    take_sub(:property_names, property_names, acc, ctx)
  end

  def take_keyword({"contains", contains}, acc, ctx) do
    case Builder.build_sub(contains, ctx) do
      {:ok, subvalidators, ctx} -> {:ok, [{:contains, subvalidators} | acc], ctx}
      {:error, _} = err -> err
    end
  end

  def take_keyword({"dependentSchemas", dependent_schemas}, acc, ctx) do
    dependent_schemas
    |> Helpers.reduce_ok({%{}, ctx}, fn {k, depschema}, {acc, ctx} ->
      case Builder.build_sub(depschema, ctx) do
        {:ok, subvalidators, ctx} -> {:ok, {Map.put(acc, k, subvalidators), ctx}}
        {:error, _} = err -> err
      end
    end)
    |> case do
      {:ok, {subvalidators, ctx}} -> {:ok, [{:dependent_schemas, subvalidators} | acc], ctx}
      {:error, _} = err -> err
    end
  end

  ignore_any_keyword()

  # ---------------------------------------------------------------------------

  defp build_sub_list(subschemas, ctx) do
    Helpers.reduce_ok(subschemas, {[], ctx}, fn subschema, {acc, ctx} ->
      case Builder.build_sub(subschema, ctx) do
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
    validators = finalize_properties(validators)
    validators = finalize_if_then_else(validators)
    validators = finalize_items(validators)
    validators
  end

  defp finalize_properties(validators) do
    {properties, validators} = Keyword.pop(validators, :properties, nil)
    {pattern_properties, validators} = Keyword.pop(validators, :pattern_properties, nil)
    {additional_properties, validators} = Keyword.pop(validators, :additional_properties, nil)

    case {properties, pattern_properties, additional_properties} do
      {nil, nil, nil} ->
        validators

      _ ->
        Keyword.put(validators, :all_properties, {properties, pattern_properties, additional_properties})
    end
  end

  defp finalize_items(validators) do
    {items, validators} = Keyword.pop(validators, :items, nil)
    {prefix_items, validators} = Keyword.pop(validators, :prefix_items, nil)

    case {items, prefix_items} do
      {nil, nil} -> validators
      some -> Keyword.put(validators, :all_items, some)
    end
  end

  defp finalize_if_then_else(validators) do
    {if_vds, validators} = Keyword.pop(validators, :if, nil)
    {then_vds, validators} = Keyword.pop(validators, :then, nil)
    {else_vds, validators} = Keyword.pop(validators, :else, nil)

    case {if_vds, then_vds, else_vds} do
      {nil, _, _} -> validators
      {_, nil, nil} -> validators
      some -> Keyword.put(validators, :if_then_else, some)
    end
  end

  # ---------------------------------------------------------------------------

  def validate(data, vds, vdr) do
    run_validators(data, vds, vdr, &validate_keyword/3)
  end

  IO.warn("remove validate_keyword_debug")

  defp validate_keyword_debug(data, tuple, vdr) do
    IO.puts("tuple: #{inspect(tuple)}")

    case validate_keyword(data, tuple, vdr) do
      {:ok, _, _} = ok -> ok
      {:error, %Validator{}} = err -> err
    end
  end

  IO.warn("remove errors carrying. Maybe seen too?")

  defp list_property_validations(data, property_schema)

  defp list_property_validations(_data, nil) do
    []
  end

  defp list_property_validations(data, properties) do
    Enum.flat_map(properties, fn
      {key, subschema} when is_map_key(data, key) -> [{:property, key, subschema, nil}]
      _ -> []
    end)
  end

  defp list_pattern_validations(data, pattern_properties)

  defp list_pattern_validations(data, nil) do
    []
  end

  defp list_pattern_validations(data, pattern_properties) do
    for {{pattern, re}, subschema} <- pattern_properties,
        {key, _} <- data,
        Regex.match?(re, key) do
      {:pattern, key, subschema, pattern}
    end
  end

  defp validate_keyword(data, {:all_properties, {properties, pattern_properties, additional_properties}}, vdr)
       when is_map(data) do
    key_to_propschema = list_property_validations(data, properties)
    key_to_patternschema = list_pattern_validations(data, pattern_properties)

    key_to_additional =
      case additional_properties do
        nil ->
          []

        _ ->
          seen_keys =
            Enum.map(key_to_propschema, fn {:property, key, _, _} -> key end) ++
              Enum.map(key_to_patternschema, fn {:pattern, key, _, _} -> key end)

          data
          |> Enum.filter(fn {key, _} -> key not in seen_keys end)
          |> Enum.map(fn {key, _} -> {:additional, key, additional_properties, nil} end)
      end

    all_validation = Enum.concat([key_to_propschema, key_to_patternschema, key_to_additional])

    # Note: casted data from previous schema is evaluted by later schema. The
    # other way would be to discard previously casted on later schema.

    Validator.apply_all_fun(data, all_validation, vdr, fn
      data, {kind, key, subschema, pattern} = propcase, vdr ->
        case Validator.validate_nested(Map.fetch!(data, key), key, subschema, vdr) do
          {:ok, casted, vdr} -> {:ok, Map.put(data, key, casted), vdr}
          {:error, vdr} -> {:error, with_property_error(vdr, data, propcase)}
        end
    end)
  end

  pass validate_keyword({:all_properties, _})

  defp validate_keyword(data, {:all_items, {items, prefix_items}}, vdr) when is_list(data) do
    all_schemas = Stream.concat(List.wrap(prefix_items), Stream.cycle([items]))

    index_items = Stream.with_index(data)

    zipped = Enum.zip(index_items, all_schemas)

    {rev_items, vdr} =
      Enum.reduce(zipped, {[], vdr}, fn
        {{item, index}, nil}, {casted, vdr} ->
          # TODO add evaluated path to validator
          {[item | casted], vdr}

        {{item, index}, subschema}, {casted, vdr} ->
          case Validator.validate_nested(item, index, subschema, vdr) do
            {:ok, casted_item, vdr} -> {[casted_item | casted], vdr}
            {:error, vdr} = err -> {[item | casted], Validator.with_error(vdr, :item, item, index: index)}
          end
      end)

    Validator.return(:lists.reverse(rev_items), vdr)
  end

  pass validate_keyword({:all_items, _})

  defp validate_keyword(data, {:one_of, subvalidators}, vdr) do
    case validate_split(subvalidators, data, vdr) do
      {[{_, data}], _, vdr} ->
        {:ok, data, vdr}

      {[], _, _} ->
        # TODO compute branch error of all invalid
        {:error, Validator.with_error(vdr, :one_of, data, validated_schemas: [])}

      {[_ | _] = too_much, _, _} ->
        validated_schemas = Enum.map(too_much, &elem(&1, 0))
        {:error, Validator.with_error(vdr, :one_of, data, validated_schemas: validated_schemas)}
    end
  end

  defp validate_keyword(data, {:any_of, subvalidators}, vdr) do
    case validate_split(subvalidators, data, vdr) do
      # If multiple schemas validate the data, we take the casted value of the
      # first one, arbitrarily.
      # TODO compute branch error of all invalid validations
      {[{_, data} | _], _, vdr} -> {:ok, data, vdr}
      {[], _, vdr} -> {:error, Validator.with_error(vdr, :any_of, data, validated_schemas: [])}
    end
  end

  defp validate_keyword(data, {:all_of, subvalidators}, vdr) do
    case validate_split(subvalidators, data, vdr) do
      # If multiple schemas validate the data, we take the casted value of the
      # first one, arbitrarily.
      {[{_, data} | _], [], vdr} -> {:ok, data, vdr}
      # TODO merge all error VDRs
      {_, [{_, err_vdr} | _] = invalid, _vdr} -> {:error, err_vdr}
    end
  end

  defp validate_keyword(data, {:if_then_else, {if_vds, then_vds, else_vds}}, vdr) do
    case Validator.validate(data, if_vds, vdr) do
      {:ok, _, _} ->
        case then_vds do
          nil -> {:ok, data, vdr}
          sub -> Validator.validate(data, sub, vdr)
        end

      {:error, _} ->
        case else_vds do
          nil -> {:ok, data, vdr}
          sub -> Validator.validate(data, sub, vdr)
        end
    end
  end

  defp validate_keyword(data, {:contains, subschema}, vdr) when is_list(data) do
    count =
      Enum.count(data, fn item ->
        case Validator.validate(item, subschema, vdr) do
          {:ok, _, _} -> true
          {:error, _} -> false
        end
      end)

    if count > 0 do
      {:ok, data, vdr}
    else
      {:error, Validator.with_error(vdr, :contains, data, count: count)}
    end
  end

  pass validate_keyword({:contains, _})

  defp validate_keyword(data, {:dependent_schemas, schemas_map}, vdr) when is_map(data) do
    Validator.apply_all_fun(data, schemas_map, vdr, fn
      data, {parent_key, subschema}, vdr when is_map_key(data, parent_key) ->
        Validator.validate(data, subschema, vdr)

      data, {_, _}, vdr ->
        {:ok, data, vdr}
    end)
  end

  pass validate_keyword({:dependent_schemas, _})

  # ---------------------------------------------------------------------------

  # Split the validators between those that validate the data and those who
  # don't.
  IO.warn("@todo return each vdr")

  defp validate_split(validators, data, vdr) do
    # TODO return VDR for each matched or unmatched schema, do not return a
    # global VDR
    {valids, invalids, vdr} =
      Enum.reduce(validators, {[], [], vdr}, fn subvalidator, {valids, invalids, vdr} ->
        case Validator.validate(data, subvalidator, vdr) do
          {:ok, data, vdr} -> {[{subvalidator, data} | valids], invalids, vdr}
          # We continue with the good validator in the acc
          {:error, err_vdr} -> {valids, [{subvalidator, err_vdr} | invalids], vdr}
        end
      end)

    {:lists.reverse(valids), :lists.reverse(invalids), vdr}
  end

  defp flat_map_or_empty(nil, _) do
    []
  end

  defp flat_map_or_empty(enum, f) do
    Enum.flat_map(enum, f)
  end

  defp with_property_error(vdr, data, {kind, key, _, pattern}) do
    case kind do
      :property -> Validator.with_error(vdr, :property, data, key: key)
      :pattern -> Validator.with_error(vdr, :pattern_property, data, pattern: pattern, key: key)
      :additional -> Validator.with_error(vdr, :additional_property, data, key: key)
    end
  end
end
