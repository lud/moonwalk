defmodule Moonwalk do
  alias Moonwalk.Internal.Normalizer
  alias Moonwalk.Internal.ValidationBuilder
  alias Moonwalk.Plugs.ValidateRequest
  alias Moonwalk.Spec.OpenAPI

  IO.warn("maybe the behaviour should belong to a dedicated module.")
  IO.warn("provide a generic API for specs in this module: retrieve, build, normalize, etc ")

  @doc """
  This function should return the OpenAPI specification for your application.

  It can be returned as an `%#{OpenAPI}{}` struct, or a bare map with atoms or
  binary keys (for instance by reading from a JSON file at compile time).

  The returned value will be normalized, any extra data not defined in the
  `#{inspect(Moonwalk.Spec)}...` namespace will be lost.
  """
  @callback spec :: map

  @doc """
  This callback is used to cache the built version of the OpenAPI specification,
  with JSV schemas turned into validators.

  The callback will be called with `:get` to retrieve a cached build, in which
  case the callback should return `{:ok, cached}` or `:error`. It will be called
  with `{:put, value}` to set the cache, in which case it must return `:ok`.

  Caching is very important, otherwise the spec will be built for each request
  calling a controller that uses `#{inspect(ValidateRequest)}`. An efficient
  default implementation using `:persistent_term` is automatically generated.
  Override this callback if you need more control over the cache.
  """
  @callback cache(:get | {:put, term}) :: :ok | {:ok, term} | :error

  @optional_callbacks [cache: 1]

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)

      @__ptk :moonwalk_cache
      @impl true
      def cache(:get) do
        case(:persistent_term.get({@__ptk, __MODULE__}, :__undef__)) do
          :__undef__ -> :error
          cached -> {:ok, cached}
        end
      end

      def cache({:put, cacheable}) do
        :ok = :persistent_term.put({@__ptk, __MODULE__}, cacheable)
      end

      defoverridable unquote(__MODULE__)
    end
  end

  def build_spec!(spec_module) do
    case spec_module.cache(:get) do
      {:ok, built_validations} ->
        built_validations

      :error ->
        built_validations = do_build_spec!(spec_module)
        :ok = spec_module.cache({:put, built_validations})
        built_validations
    end
  end

  defp do_build_spec!(spec_module) do
    spec_module.spec()
    |> Normalizer.normalize!()
    |> ValidationBuilder.build_operations()
  end
end
