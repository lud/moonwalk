defmodule Moonwalk.Plugs.ValidateRequest do
  alias Moonwalk.Errors.InvalidBodyError
  alias Moonwalk.Errors.InvalidParameterError
  alias Moonwalk.Errors.MissingParameterError
  alias Moonwalk.Errors.UnsupportedMediaTypeError
  alias Moonwalk.Spec.Operation
  alias Plug.Conn
  require Logger

  @behaviour Plug

  def init(opts) do
    if opts[:spec] do
      IO.warn("obsolete spec option")
    end

    opts =
      Keyword.put_new_lazy(opts, :pretty_errors, fn ->
        # Default to true only when mix is available:
        # * in dev/test environment.
        # * when compiling releases with phoenix set to compile-time. In that
        #   case we do not want pretty errors by default in production.
        function_exported?(Mix, :env, 0) && Mix.env() != :prod
      end)

    {handler, opts_no_handler} = Keyword.pop(opts, :error_handler, Moonwalk.ErrorHandler)

    error_handler =
      case handler do
        mod when is_atom(mod) -> {handler, opts_no_handler}
        {mod, arg} when is_atom(mod) -> {mod, arg}
      end

    [error_handler: error_handler]
  end

  def call(conn, opts) do
    {controller, action} = fetch_phoenix!(conn)

    with {:ok, validations_with_root} <- fetch_validations(conn, controller, action),
         {:ok, private, conn} <- run_validations(conn, validations_with_root) do
      Conn.put_private(conn, :moonwalk, private)
    else
      {:error, {:params_errors, errors}, conn} when is_list(errors) ->
        handle_errors(conn, :unprocessable_entity, errors, opts)

      {:error, %InvalidBodyError{} = e, conn} ->
        handle_errors(conn, :unprocessable_entity, [e], opts)

      {:error, %UnsupportedMediaTypeError{} = e, conn} ->
        handle_errors(conn, :unsupported_media_type, [e], opts)

      {:error, {:not_built, operation_id}, _conn} ->
        raise "operation with id #{inspect(operation_id)} was not built"

      {:skip, _} ->
        conn
    end
  end

  defp fetch_phoenix!(conn) do
    case conn do
      %{private: %{phoenix_controller: controller, phoenix_action: action}} ->
        {controller, action}

      _ ->
        raise """
        conn given to #{inspect(__MODULE__)} was not routed by phoenix

        Make sure to call this plug from a phoenix controller.
        """
    end
  end

  defp fetch_validations(conn, controller, action) do
    case fetch_operation_id(conn, controller, action) do
      {:ok, operation_id} ->
        spec_module = fetch_spec_module!(conn)
        {validations, jsv_root} = Moonwalk.build_spec!(spec_module)

        case validations do
          %{^operation_id => op_validations} -> {:ok, {op_validations, jsv_root}}
          _ -> {:error, {:not_built, operation_id}, conn}
        end

      {:skip, _} = err ->
        err
    end
  end

  defp fetch_operation_id(conn, controller, action) do
    case hook(controller, :operation_id, action, conn.method) do
      {:ok, operation_id} ->
        {:ok, operation_id}

      :ignore ->
        {:skip, :unhandled_action}

      :__undef__ ->
        warn_undef_action(controller, action)
        {:skip, :unhandled_action}
    end
  end

  defp fetch_spec_module!(conn) do
    case conn do
      %{private: %{moonwalk: %{spec: module}}} ->
        module

      _ ->
        raise """
        #{inspect(__MODULE__)} was called but #{inspect(Moonwalk.Plugs.SpecProvider)} was not called upstream

        Make sure to provide a spec module before calling #{inspect(__MODULE__)}:

        pipeline :api do
          plug Moonwalk.Plugs.SpecProvider, spec: Moonwalk.TestWeb.ApiSpec
        end

        scope "/api", MyAppWeb.Api do
          pipe_through :api

          get "/hello", HelloController, :hello
        end
        """
    end
  end

  defp run_validations(conn, {validations, jsv_root}) do
    Enum.reduce_while(validations, {:ok, _private = %{}, conn}, fn
      validation, {:ok, private, conn} ->
        # we are not collecting all errors but rather stop on the first error. If
        # parameters are wrong, as they handle path parameters we act as if the
        # route is wrong, and do not want to validate the body.
        case validate(conn, validation, jsv_root) do
          {:ok, new_private, conn} -> {:cont, {:ok, Map.merge(private, new_private), conn}}
          {:error, reason, conn} -> {:halt, {:error, reason, conn}}
        end
    end)
  end

  defp validate(conn, {:parameters, by_location}, jsv_root) do
    validate_parameters(conn, by_location, jsv_root)
  end

  defp validate(conn, {:body, required?, media_matchers}, jsv_root) do
    case ensure_fetched_body(conn) do
      {:ok, body, conn} -> validate_body(conn, body, required?, media_matchers, jsv_root)
    end
  end

  defp ensure_fetched_body(%{body_params: %Plug.Conn.Unfetched{}} = conn) do
    # If we read the body from there we will not try to turn it into json or
    # something, this is the responisibility of the users.
    #
    # TODO(doc) The plug will populate conn.body_params with the raw body
    case Plug.Conn.read_body(conn) do
      {:ok, body, conn} -> {:ok, body, %{conn | body_params: body}}
      {:more, _, conn} -> {:error, :too_large, conn}
    end
  end

  defp ensure_fetched_body(conn) do
    {:ok, conn.body_params, conn}
  end

  IO.warn("todo make sure parameters are fetched")

  defp validate_parameters(conn, by_location, jsv_root) do
    %{path_params: raw_path_params, query_params: raw_query_params} = conn
    %{path: path_specs, query: query_specs} = by_location

    # parameters in path

    {cast_path_params, path_errors} =
      validate_parameters_group(path_specs, raw_path_params, jsv_root)

    {cast_query_params, query_errors} =
      validate_parameters_group(query_specs, raw_query_params, jsv_root)

    case {path_errors, query_errors} do
      {[], []} ->
        private = %{path_params: cast_path_params, query_params: cast_query_params}
        {:ok, private, conn}

      _ ->
        {:error, {:params_errors, path_errors ++ query_errors}, conn}
    end
  end

  defp validate_parameters_group(param_specs, raw_params, jsv_root) do
    Enum.reduce(param_specs, {%{}, []}, fn parameter, {acc, errors} ->
      validate_parameter(parameter, raw_params, jsv_root, acc, errors)
    end)
  end

  defp validate_parameter(parameter, raw_params, jsv_root, acc, errors) do
    %{bin_key: bin_key, key: key, schema_key: jsv_key, required: required?} = parameter

    case Map.fetch(raw_params, bin_key) do
      {:ok, value} ->
        case validate_with_schema(value, jsv_key, jsv_root) do
          {:ok, cast_value} ->
            acc = Map.put(acc, key, cast_value)
            {acc, errors}

          {:error, validation_error} ->
            err = %InvalidParameterError{
              in: parameter.in,
              name: bin_key,
              value: value,
              validation_error: validation_error
            }

            {acc, [err | errors]}
        end

      :error when required? ->
        err = %MissingParameterError{in: parameter.in, name: bin_key}
        {acc, [err | errors]}

      :error ->
        {acc, errors}
    end
  end

  # TODO(doc) a body is considered empty if "" or nil, and in this case we do
  # not run the validations.
  #
  # The JSON parser plug will only set an empty map as the body_params when the
  # content type of the request is JSON but the body is empty. We do not handle
  # that case, as an application/json request should have a JSON body.
  defp validate_body(conn, body, false = _required?, _, _) when body in [nil, ""] do
    {:ok, %{}, conn}
  end

  defp validate_body(conn, body, _required?, media_matchers, jsv_root) do
    {primary, secondary} = fetch_content_type(conn)

    with {:ok, {_, jsv_key}} <- match_media_type(media_matchers, {primary, secondary}),
         {:ok, cast_body} <- validate_with_schema(body, jsv_key, jsv_root) do
      {:ok, %{body_params: cast_body}, conn}
    else
      {:error, %JSV.ValidationError{} = validation_error} ->
        {:error, %InvalidBodyError{validation_error: validation_error, value: body}, conn}

      {:error, :unsupported} ->
        {:error, %UnsupportedMediaTypeError{media_type: "#{primary}/#{secondary}", value: body}, conn}

      {:error, :unfetched} ->
        raise "cannot validate request with content type '#{primary}/#{secondary}' as body was not fetched"
    end
  end

  defp fetch_content_type(conn) do
    %{req_headers: req_headers} = conn

    case List.keyfind(req_headers, "content-type", 0, :error) do
      :error ->
        {"unknown", "unknown"}

      {"content-type", content_type} ->
        case Conn.Utils.content_type(content_type) do
          :error -> {content_type, ""}
          {:ok, primary, secondary, _params} -> {primary, secondary}
        end
    end
  end

  defp match_media_type([{{primary, secondary}, _jsv_key} = matched | _], {primary, secondary}) do
    {:ok, matched}
  end

  defp match_media_type([{{"*", _secondary}, _jsv_key} = matched | _], _) do
    {:ok, matched}
  end

  defp match_media_type([{{primary, "*"}, _jsv_key} = matched | _], {primary, _}) do
    {:ok, matched}
  end

  defp match_media_type([_ | matchspecs], content_type_tuple) do
    match_media_type(matchspecs, content_type_tuple)
  end

  defp match_media_type([], _) do
    {:error, :unsupported}
  end

  defp validate_with_schema(value, jsv_key, jsv_root)

  IO.warn("todo no validation")

  defp validate_with_schema(value, :no_validation, _) do
    raise "noval!"
    {:ok, value}
  end

  defp validate_with_schema(value, {:precast, caster, jsv_key}, jsv_root) do
    case precast_parameter(value, caster) do
      {:ok, precast_value} ->
        validate_with_schema(precast_value, jsv_key, jsv_root)

      {:error, _} ->
        # On error we still call the real schema. For instance if "hello" is
        # given for the integer type, we will have a correct type error (though
        # the value will be quoted if shown in the error message)
        validate_with_schema(value, jsv_key, jsv_root)
    end
  end

  defp validate_with_schema(value, jsv_key, jsv_root) do
    JSV.validate(value, jsv_root, cast: true, cast_formats: true, key: jsv_key)
  end

  defp precast_parameter(value, fun) when is_function(fun, 1) do
    fun.(value)
  end

  defp precast_parameter(values, {:list, fun}) when is_list(values) and is_function(fun, 1) do
    precast_list(values, fun, [])
  end

  defp precast_parameter(_values, {:list, fun}) when is_function(fun, 1) do
    {:error, :non_array_parameter}
  end

  defp precast_list([h | t], fun, acc) do
    case fun.(h) do
      {:ok, v} -> precast_list(t, fun, [v | acc])
      {:error, _} = err -> err
    end
  end

  defp precast_list([], _, acc) do
    {:ok, :lists.reverse(acc)}
  end

  defp handle_errors(conn, status, errors, opts) do
    {handler_mod, handler_arg} = Keyword.fetch!(opts, :error_handler)
    handler_mod.handle_errors(conn, status, errors, handler_arg)
  end

  @doc """
  Helper for error handlers.

  The conn given to this function must have been through the
  #{inspect(__MODULE__)} plug with an error result.
  """
  def fetch_operation!(conn) do
    {controller, action} = fetch_phoenix!(conn)

    case hook(controller, :operation, action, conn.method) do
      {:ok, %Operation{} = operation} -> operation
      _ -> raise ArgumentError, "could not fetch operation from Plug.Conn struct"
    end
  end

  defp warn_undef_action(controller, action) do
    IO.warn("""
    Controller #{inspect(controller)} has no operation defined for action #{inspect(action)}

    Pass `false` to the `operation` macro to suppress this warning

        operation :my_action, false

        def my_action(conn, params) do
          # ...
        end
    """)
  end

  defp hook(controller, kind, action, arg) do
    _result = controller.__moonwalk__(kind, action, arg)
  end

  # defp hook(controller, kind) do
  #   _result = controller.__moonwalk__(kind)
  # end
end
