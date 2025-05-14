defmodule Moonwalk.Plug.ValidateRequest do
  alias Plug.Conn
  alias Plug.Conn.Status
  require Logger

  @behaviour Plug

  defmodule InvalidBodyError do
    @enforce_keys [:value, :validation_error]
    defexception value: nil, validation_error: nil

    def message(%{validation_error: verr}) do
      """
      invalid body

      #{Exception.message(verr)}
      """
    end

    def to_html(%{validation_error: verr}) do
      """
      <p>Body payload is not valid:</p>

      #{Exception.message(verr)}
      """
    end
  end

  defmodule InvalidParameterError do
    @enforce_keys [:name, :in, :value, :validation_error]
    defexception name: nil, in: nil, value: nil, validation_error: nil

    def message(%{in: loc, name: name, validation_error: verr}) do
      """
      invalid parameter #{name} in #{loc}

      #{Exception.message(verr)}
      """
    end

    def to_html(%{in: loc, name: name, validation_error: verr}) do
      """
      <p>Invalid parameter <code>#{name}</code> in <code>#{loc}</code>:</p>

      <pre>
      #{Exception.message(verr)}
      <pre>
      """
    end
  end

  defmodule UnsupportedMediaTypeError do
    @enforce_keys [:media_type]
    defexception media_type: nil, value: nil

    def message(%{media_type: media_type}) do
      "cannot validate media type #{media_type}"
    end

    def to_html(%{media_type: media_type}) do
      "<p>Validation for body of type <code>#{media_type}</code> is not supported.</p>"
    end
  end

  def init(opts) do
    # We call mix from there because it will be compiled according to the user
    # enviroment (:plug_init_mode config value), and not always in :prod
    # environment as dependencies are compiled.
    opts
    |> Keyword.put_new_lazy(:pretty_errors, fn ->
      if function_exported?(Mix, :env, 0) do
        Mix.env() != :prod
      else
        false
      end
    end)
    |> Keyword.update(:error_formatter, {Moonwalk.ErrorFormatter, opts}, fn
      module when is_atom(module) -> {module, opts}
      {module, custom_opts} when is_atom(module) -> {module, custom_opts}
    end)
  end

  def call(conn, _) do
    with {:ok, controller, action} <- fetch_phoenix(conn),
         {:ok, validations} <- fetch_validations(conn, controller, action),
         {:ok, private} <- run_validations(conn, validations, controller, action) do
      Conn.put_private(conn, :moonwalk, private)
    else
      {:error, errors} when is_list(errors) -> halt_with(conn, :unprocessable_entity, errors)
      {:error, %InvalidBodyError{} = e} -> halt_with(conn, :unprocessable_entity, [e])
      {:error, %UnsupportedMediaTypeError{} = e} -> halt_with(conn, :unsupported_media_type, [e])
      {:skip, :no_phoenix} -> conn
      {:skip, :unhandled_action} -> conn
    end
  end

  defp fetch_phoenix(conn) do
    case conn do
      %{private: %{phoenix_controller: controller, phoenix_action: action}} ->
        {:ok, controller, action}

      _ ->
        IO.warn("conn given to #{inspect(__MODULE__)} was not routed by phoenix")
        {:skip, :no_phoenix}
    end
  end

  defp fetch_validations(conn, controller, action) do
    case hook(controller, action, :validations, conn.method) do
      {:ok, validations} ->
        {:ok, validations}

      :ignore ->
        {:skip, :unhandled_action}

      :__undef__ ->
        log_undef_action(controller, action)
        {:skip, :unhandled_action}
    end
  end

  defp run_validations(conn, validations, controller, action) do
    Enum.reduce_while(validations, {:ok, _privates = %{}}, fn validation, {:ok, private} ->
      # we are not collecting all errors but rather stop on the first error. If
      # parameters are wrong, as they handle path parameters we act as if the
      # route is wrong, and do not want to validate the body.
      case validate(conn, validation, controller, action) do
        {:ok, new_private} -> {:cont, {:ok, Map.merge(private, new_private)}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp validate(conn, {:parameters, by_location}, _, _) do
    validate_parameters(conn, by_location)
  end

  defp validate(conn, {:body, media_matchers}, _, _) do
    validate_body(conn, media_matchers)
  end

  defp validate_parameters(conn, by_location) do
    %{path_params: raw_path_params, query_params: _raw_query_params} = conn
    %{path: path_specs, query: _} = by_location

    # parameters in path

    {cast_path_params, path_errors} = validate_parameters_group(path_specs, raw_path_params)
    {cast_query_params, query_errors} = {%{}, []}

    case {path_errors, query_errors} do
      {[], []} ->
        private = %{path_params: cast_path_params, query_params: cast_query_params}
        {:ok, private}

      _ ->
        {:error, path_errors ++ query_errors}
    end
  end

  defp validate_parameters_group(param_specs, raw_params) do
    Enum.reduce(param_specs, {%{}, []}, fn parameter, {acc, errors} ->
      validate_parameter(parameter, raw_params, acc, errors)
    end)
  end

  defp validate_parameter(parameter, raw_params, acc, errors) do
    %{bin_key: bin_key, key: key, required: _required?, schema: schema} = parameter

    case Map.fetch(raw_params, bin_key) do
      {:ok, value} ->
        case validate_with_schema(value, schema) do
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
    end
  end

  defp validate_body(conn, media_matchers) do
    content_type_tuple = fetch_content_type(conn)
    %{body_params: raw_parsed_body} = conn

    case match_body_and_validate(media_matchers, content_type_tuple, raw_parsed_body) do
      {:ok, cast_body} -> {:ok, %{body_params: cast_body}}
      {:error, _} = err -> err
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

  defp match_body_and_validate([{{primary, secondary}, schema} | _], {primary, secondary}, body) do
    do_validate_body(body, schema)
  end

  defp match_body_and_validate([{{"*", _secondary}, schema} | _], _, body) do
    do_validate_body(body, schema)
  end

  defp match_body_and_validate([{{primary, "*"}, schema} | _], {primary, _}, body) do
    do_validate_body(body, schema)
  end

  defp match_body_and_validate([_ | matchspecs], content_type_tuple, body) do
    match_body_and_validate(matchspecs, content_type_tuple, body)
  end

  defp match_body_and_validate([], {primary, secondary}, body) do
    {:error, %UnsupportedMediaTypeError{media_type: "#{primary}/#{secondary}", value: body}}
  end

  defp do_validate_body(body, schema) do
    case validate_with_schema(body, schema) do
      {:ok, cast_body} ->
        {:ok, cast_body}

      {:error, validation_error} ->
        {:error, %InvalidBodyError{validation_error: validation_error, value: body}}
    end
  end

  defp validate_with_schema(value, schema)

  defp validate_with_schema(value, :no_validation) do
    {:ok, value}
  end

  defp validate_with_schema(value, schema) do
    JSV.validate(value, schema, cast: true, cast_formats: true)
  end

  defp halt_with(conn, status, errors) do
    format =
      case fetch_accept(conn) do
        {"application", "json"} -> {:json, json_opts(conn)}
        _ -> :html
      end

    conn
    |> Conn.put_resp_content_type(resp_content_type(format))
    |> Conn.send_resp(status, format_errors(status, errors, format))
    |> Conn.halt()
  end

  defp fetch_accept(conn) do
    %{req_headers: req_headers} = conn

    with {"accept", content_type} <- List.keyfind(req_headers, "accept", 0, :error),
         {:ok, primary, secondary, _params} <- Conn.Utils.content_type(content_type) do
      {primary, secondary}
    else
      :error -> :error
    end
  end

  defp resp_content_type(format) do
    case format do
      {:json, _} -> "application/json"
      :html -> "text/html"
    end
  end

  defp json_opts(conn) do
    pretty? =
      with %{private: %{phoenix_controller: controller}} <- conn,
           true <- function_exported?(controller, :__moonwalk__, 1),
           {:ok, v} when is_boolean(v) <-
             Keyword.fetch(hook(controller, :opts), :pretty_errors) do
        v
      else
        _ -> false
      end

    [pretty: pretty?]
  end

  defp format_errors(status, errors, {:json, opts}) do
    groups = render_errors(errors, :json)

    json_encode(
      %{error: Map.put(groups, :message, status_to_message(status))},
      opts
    )
  end

  defp format_errors(status, errors, :html) do
    groups = render_errors(errors, :html)

    """
    <h1>#{status_to_message(status)}</h1>

    #{groups}
    """
  end

  defp status_to_message(status) do
    status
    |> Status.code()
    |> Status.reason_phrase()
  end

  defp render_errors(errors, :json) do
    info = %{}

    errors
    |> Enum.map(fn
      %InvalidParameterError{in: loc, name: name, validation_error: verr} ->
        {error_group_path([loc_to_group(loc), name]), JSV.normalize_error(verr)}

      %InvalidBodyError{validation_error: verr} ->
        {error_group_path([:body]), JSV.normalize_error(verr)}

      %UnsupportedMediaTypeError{media_type: media_type} ->
        {error_group_path([:media_type]), media_type}
    end)
    |> Enum.reduce(info, fn {path, err}, acc -> put_in(acc, path, err) end)
  end

  IO.warn(
    "create an error handler module that must return a response given the accept content type"
  )

  defp render_errors(errors, :html) do
    errors
    |> Enum.sort_by(fn
      %InvalidParameterError{in: loc, name: name} -> {0, loc, name}
      _ -> {1, nil, nil}
    end)
    |> Enum.map_intersperse(?\n, fn %mod{} = e -> mod.to_html(e) end)
  end

  defp loc_to_group(loc) do
    case loc do
      :path -> :path_parameters
      :query -> :query_parameters
    end
  end

  defp error_group_path(path_items) do
    Enum.map(path_items, &Access.key(&1, %{}))
  end

  defp json_encode(payload, opts) do
    case opts[:pretty] do
      true -> JSV.Codec.format!(payload)
      _ -> JSV.Codec.encode!(payload)
    end
  end

  defp log_undef_action(controller, action) do
    Logger.warning(
      "Controller #{inspect(controller)} has no operation defined for action #{inspect(action)}"
    )
  end

  defp hook(controller, action, kind, arg) do
    _result = controller.__moonwalk__(action, kind, arg)
  end

  defp hook(controller, kind) do
    _result = controller.__moonwalk__(kind)
  end
end
