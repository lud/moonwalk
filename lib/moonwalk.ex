raise "todo cleanup"

defmodule Moonwalk do
  alias Moonwalk.Spec.Request
  alias Moonwalk.Spec.Api

  def normalize_spec(%Api{} = api) do
    Api.normalize_spec(api)
  end

  def normalize_spec(%Request{} = api) do
    Request.normalize_spec(api)
  end

  defp json_serializable?(term) when is_binary(term) when is_atom(term) when is_number(term) do
    true
  end

  # defp json_serializable?(_) do
  #   false
  # end

  def json_serializable!(term) do
    case json_serializable?(term) do
      # false -> raise ArgumentError, "The term #{inspect(term)} is not JSON serializable"
      true -> term
    end
  end

  # def json_key?(term) when is_binary(term) when is_atom(term) do
  #   true
  # end

  # def json_key?(_) do
  #   false
  # end

  def json_key!(binary) when is_binary(binary) do
    binary
  end

  def json_key!(atom) when is_atom(atom) do
    Atom.to_string(atom)
  end

  # def json_key!(term) do
  #   raise(ArgumentError, "The term #{inspect(term)} is not a valid JSON key")
  # end
end
