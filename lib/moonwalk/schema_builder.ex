defmodule Moonwalk.SchemaBuilder do
  @moduledoc false

  def build(schema, opts \\ []) do
    # when using schemas for query params we do not want to have to specify the
    # cast functions, so we do it here automatically

    schema
    |> deref_module()
    |> do_build(opts)
  end

  defp do_build(schema, opts) do
    schema_chain =
      case opts[:cast_strings] do
        true -> with_parameter_precast(schema)
        _ -> schema
      end

    case schema_chain do
      {:precast, caster, schema} ->
        {:precast, caster, JSV.build!(schema)}

      schema ->
        JSV.build!(schema)
    end
  end

  def deref_module(atom) when atom in [true, false, nil] do
    # This is going to be invalid for JSV but it's not our problem here
    atom
  end

  def deref_module(module) when is_atom(module) do
    JSV.Schema.normalize(module.schema())
  end

  def deref_module(bool) when is_boolean(bool) do
    bool
  end

  def deref_module(map) when is_map(map) do
    JSV.Schema.normalize(map)
  end

  defp with_parameter_precast(schema) do
    case schema do
      %{"type" => "integer"} ->
        {:precast, &JSV.Cast.string_to_integer/1, schema}

      %{"type" => "boolean"} ->
        {:precast, &JSV.Cast.string_to_boolean/1, schema}

      %{"type" => "number"} ->
        {:precast, &JSV.Cast.string_to_number/1, schema}

      %{"type" => "array", "items" => %{"type" => "integer"}} ->
        {:precast, {:list, &JSV.Cast.string_to_integer/1}, schema}

      %{"type" => "array", "items" => %{"type" => "boolean"}} ->
        {:precast, {:list, &JSV.Cast.string_to_boolean/1}, schema}

      %{"type" => "array", "items" => %{"type" => "number"}} ->
        {:precast, {:list, &JSV.Cast.string_to_number/1}, schema}

      _ ->
        schema
    end
  end
end
