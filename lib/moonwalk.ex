defmodule Moonwalk do
  alias Moonwalk.Internal.Normalizer
  alias Moonwalk.Internal.ValidationBuilder

  IO.warn("todo we need a demo app!")

  @moduledoc """
  The main API to work with OpenAPI specifications.

  This module can be used to define a specification module that will then be
  used in your Phoenix router and controllers.

  ### Example

  ```elixir
  defmodule MyAppWeb.OpenAPISpec do
    alias Moonwalk.Spec.Paths
    alias Moonwalk.Spec.Server
    use Moonwalk

    @impl true
    def spec do
      %{
        openapi: "3.1.1",
        info: %{title: "My App API", version: "1.0.0"},
        servers: [Server.from_config(:my_app, MyAppWeb.Endpoint)],
        paths: Paths.from_router(MyAppWeb.Router, filter: &String.starts_with?(&1.path, "/api/"))
      }
    end
  end
  ```
  """

  @type cache_key :: {:moonwalk_cache, module, responses? :: boolean, variant :: term}

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

  On custom implementations there is generally no need to wrap the key in a
  tagged tuple, as it is already a unique tagged tuple.
  """
  @callback cache({:get, key} | {:put, key, value}) :: :ok | {:ok, value} | :error
            when key: {:moonwalk_cache, module, term}, value: term

  @doc """
  Returns the options that will be passed to `JSV.build/2` when building the
  spec for the implementation module.

  The default implementation delegates to `Moonwalk.default_jsv_opts/0`.
  """
  @callback jsv_opts :: [JSV.build_opt()]

  @doc """
  This function is intended to change cache keys at runtime. The variant is any
  term used as the last element of a `t:cache_key/0`.

  This is useful if you need to rebuild the OpenAPI specification and its
  validators at runtime, when the used schemas or even routes depend on current
  application state. For instance, if a schema for a given entity is fetched
  regularly from a remote source and changes over time.

  The default implementation returns `nil`.

  > #### Stale cache entries are not purged automatically {: .warning}
  >
  > If you return a new variant from this callback, cache entries stored with
  > previous variants in the key are not automatically cleaned. You will need to
  > take care of that. See `c:cache/1` to implement a cache mechanism that you
  > can control.
  """
  @callback cache_variant :: term

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)

      @impl true
      def cache({:get, key}) do
        case(:persistent_term.get(key, :__undef__)) do
          :__undef__ -> :error
          cached -> {:ok, cached}
        end
      end

      def cache({:put, key, cacheable}) do
        :ok = :persistent_term.put(key, cacheable)
      end

      @impl true
      def jsv_opts do
        unquote(__MODULE__).default_jsv_opts()
      end

      @impl true
      def cache_variant do
        nil
      end

      defoverridable unquote(__MODULE__)
    end
  end

  # TODO(doc)
  def default_jsv_opts do
    [
      default_meta: JSV.default_meta(),
      formats: [Moonwalk.JsonSchema.Formats | JSV.default_format_validator_modules()]
    ]
  end

  # TODO(doc) returns a tuple with the JSV root
  # TODO(doc) opt :cache, defaults to true
  # TODO(doc) opt :responses, defaults to false
  def build_spec!(spec_module, opts \\ []) do
    cache? = Keyword.get(opts, :cache, true)

    if cache? do
      cache_key = cache_key(spec_module, opts)

      case spec_module.cache({:get, cache_key}) do
        {:ok, built_validations} ->
          built_validations

        :error ->
          built_validations = do_build_spec!(spec_module, opts)
          :ok = spec_module.cache({:put, cache_key, built_validations})
          built_validations
      end
    else
      do_build_spec!(spec_module, opts)
    end
  end

  @spec cache_key(module, keyword) :: cache_key
  defp cache_key(spec_module, opts) do
    {:moonwalk_cache, spec_module, !!opts[:responses], spec_module.cache_variant()}
  end

  defp do_build_spec!(spec_module, opts) do
    opts = build_opts(spec_module, opts)

    spec_module.spec()
    |> Normalizer.normalize!()
    |> ValidationBuilder.build_operations(opts)
  end

  defp build_opts(spec_module, opts) do
    opts
    |> Keyword.delete(:cache)
    |> Keyword.put_new_lazy(:jsv_opts, fn -> spec_module.jsv_opts() end)
    |> Keyword.put_new(:responses, false)
    |> Map.new()
  end

  @doc """
  Normalizes OpenAPI specification data.

  Takes specification data (raw maps or structs) and normalizes it to a
  JSON-compatible version (with binary keys).
  """
  def normalize_spec!(data) do
    Normalizer.normalize!(data)
  end
end
