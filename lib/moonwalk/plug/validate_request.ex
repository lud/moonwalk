defmodule Moonwalk.Plug.ValidateRequest do
  alias Plug.Conn
  alias Plug.Conn.Status
  require Logger

  @behaviour Plug

  def init(opts) do
    opts
  end

  def call(conn, _) do
    with {:ok, controller, action} <- fetch_phoenix(conn),
         {:ok, casters} <- fetch_casters(conn, controller, action) do
      apply_casters(casters, conn)
    else
      :error -> conn
    end
  catch
    :throw, {:reject, status} ->
      halt_with(conn, status, status_error(status))
  end

  defp fetch_phoenix(conn) do
    case conn do
      %{private: %{phoenix_controller: controller, phoenix_action: action}} ->
        {:ok, controller, action}

      _ ->
        IO.warn("conn given to #{inspect(__MODULE__)} was not routed by phoenix")
        :error
    end
  end

  defp fetch_casters(conn, controller, action) do
    case hook(controller, action, :handle_action?, conn.method) do
      true ->
        do_fetch_casters(conn, controller, action)

      false ->
        {:ok, []}

      :__undef__ ->
        log_undef_action(controller, action)
        {:ok, []}
    end
  end

  defp do_fetch_casters(conn, controller, action) do
    body =
      case hook(controller, action, :validate_body?, conn.method) do
        :__undef__ -> []
        false -> []
        true -> [fetch_body_caster(conn, controller, action)]
      end

    {:ok, Enum.concat([body])}
  end

  defp fetch_body_caster(conn, controller, action) do
    {primary, secondary} = fetch_content_type(conn)

    case hook(controller, action, :request_body_schema, {primary, secondary}) do
      {:ok, schema} -> {:body_schema, schema}
      :error -> throw({:reject, :unsupported_media_type})
    end
  end

  defp fetch_content_type(conn) do
    %{req_headers: req_headers} = conn

    with {"content-type", content_type} <- List.keyfind(req_headers, "content-type", 0, :error),
         {:ok, primary, secondary, _params} <- Conn.Utils.content_type(content_type) do
      {primary, secondary}
    else
      # This can still match on content type clauses that match on `_` for
      # content types like "*/*" or "text/*"
      :error -> {:notype, :notype}
    end
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

  defp apply_casters([{:body_schema, schema} | casters], conn) do
    case JSV.validate(conn.body_params, schema, cast: true, cast_formats: true) do
      {:ok, cast_body} ->
        conn = put_key(conn, :body_params, cast_body)
        apply_casters(casters, conn)

      {:error, validation_error} ->
        halt_with(conn, :unprocessable_entity, jsv_error(validation_error, :unprocessable_entity))
    end
  end

  defp apply_casters([], conn) do
    conn
  end

  defp put_key(conn, key, value) do
    old =
      case conn do
        %{private: %{moonwalk: map}} -> map
        _ -> %{}
      end

    new = Map.put(old, key, value)
    Conn.put_private(conn, :moonwalk, new)
  end

  defp status_error(status) do
    {:message, status_to_message(status)}
  end

  defp jsv_error(error, status) do
    {:jsv, status_to_message(status), error}
  end

  defp status_to_message(status) do
    status
    |> Status.code()
    |> Status.reason_phrase()
  end

  defp halt_with(conn, status, wrapped_error) do
    format =
      case fetch_accept(conn) do
        {"application", "json"} -> {:json, json_opts(conn)}
        _ -> :text
      end

    conn
    |> Conn.put_resp_content_type(resp_content_type(format))
    |> Conn.send_resp(status, format_error(wrapped_error, format))
    |> Conn.halt()
  end

  defp resp_content_type(format) do
    case format do
      {:json, _} -> "application/json"
      :text -> "text/plain"
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

  defp format_error({:message, message}, {:json, opts}) do
    json_encode(%{error: %{message: message}}, opts)
  end

  defp format_error({:message, message}, :text) do
    message
  end

  defp format_error({:jsv, message, validation_error}, {:json, opts}) do
    json_encode(
      %{error: %{message: message, detail: JSV.normalize_error(validation_error)}},
      opts
    )
  end

  defp format_error({:jsv, message, validation_error}, :text) do
    """
    #{message}

    #{Exception.message(validation_error)}
    """
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
