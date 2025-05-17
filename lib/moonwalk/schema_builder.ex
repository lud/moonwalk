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
        true -> enforce_string_casting(schema)
        _ -> schema
      end

    case schema_chain do
      {:cast_parameter, caster, schema} ->
        {:cast_parameter, caster, JSV.build!(schema)}

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

  defp enforce_string_casting(schema) do
    case {uses_cast?(schema), get_type(schema)} do
      {true, _} -> schema
      {false, "integer"} -> {:cast_parameter, &JSV.Cast.string_to_integer/1, schema}
    end
  end

  defp get_type(schema) do
    case schema do
      %{"type" => t} -> t
      _ -> nil
    end
  end

  defp uses_cast?(schema) do
    case schema do
      %{"jsv-cast" => nil} -> false
      %{"jsv-cast" => _} -> true
      _ -> false
    end
  end
end
