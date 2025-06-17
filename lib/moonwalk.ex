defmodule Moonwalk do
  alias Moonwalk.Internal.Normalizer
  alias Moonwalk.Internal.ValidationBuilder

  # TODO(doc) returns a tuple with the JSV root
  # TODO(doc) opt :cache
  # TODO(doc) opt :responses
  def build_spec!(spec_module, opts \\ []) do
    case Keyword.pop(opts, :cache) do
      {false, opts} ->
        do_build_spec!(spec_module, opts)

      {_, opts} ->
        case spec_module.cache(:get) do
          {:ok, built_validations} ->
            built_validations

          :error ->
            built_validations = do_build_spec!(spec_module, opts)
            :ok = spec_module.cache({:put, built_validations})
            built_validations
        end
    end
  end

  defp do_build_spec!(spec_module, opts) do
    spec_module.spec()
    |> Normalizer.normalize!()
    |> ValidationBuilder.build_operations(opts)
  end

  @doc """
  Normalizes OpenAPI specification data.

  Takes raw specification data (maps, structs, etc.) and normalizes it according
  to the OpenAPI specification structure defined in the `Moonwalk.Spec.*`
  modules.
  """
  def normalize_spec!(data) do
    Normalizer.normalize!(data)
  end
end
