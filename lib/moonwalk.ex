defmodule Moonwalk do
  alias Moonwalk.Spec.Api

  def normalize_spec(%Api{} = api) do
    Api.normalize_spec(api)
  end

  def json_serializable?(term) when is_binary(term) when is_atom(term) when is_number(term),
    do: true

  def json_serializable?(_), do: false

  def json_serializable!(term) do
    case json_serializable?(term) do
      true -> term
      false -> raise ArgumentError, "The term #{inspect(term)} is not JSON serializable"
    end
  end

  def json_key?(term) when is_binary(term) when is_atom(term), do: true
  def json_key?(_), do: false

  def json_key!(binary) when is_binary(binary), do: binary
  def json_key!(atom) when is_atom(atom), do: Atom.to_string(atom)

  def json_key!(term),
    do: raise(ArgumentError, "The term #{inspect(term)} is not a valid JSON key")
end
