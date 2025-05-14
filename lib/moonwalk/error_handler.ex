defmodule Moonwalk.ErrorHandler do
  alias Plug.Conn
  alias Moonwalk.Plug.ValidateRequest.InvalidBodyError
  alias Moonwalk.Plug.ValidateRequest.InvalidParameterError
  alias Moonwalk.Plug.ValidateRequest.UnsupportedMediaTypeError

  @moduledoc false

  def handle_errors(conn, status, errors, opts) do
    operation = Moonwalk.Plug.ValidateRequest.fetch_operation!(conn)

    # we will render HTML for any content
    format =
      case fetch_accept(conn) do
        {"application", "json"} -> {:json, json_opts(opts)}
        {"application", "vnd.api+json"} -> {:json, json_opts(opts)}
        {"application", "ld+json"} -> {:json, json_opts(opts)}
        _ -> :html
      end

    formatted_errors = format_errors(format, errors, status, operation)

    conn
    |> Conn.put_resp_content_type(resp_content_type(format))
    |> Conn.send_resp(status, formatted_errors)
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

  defp json_opts(opts) do
    case Keyword.fetch(opts, :pretty_errors) do
      {:ok, true} -> [pretty: true]
      _ -> []
    end
  end

  defp resp_content_type(format) do
    case format do
      {:json, _} -> "application/json"
      :html -> "text/html"
    end
  end

  defp format_errors({:json, opts}, errors, status, operation) do
    groups = render_errors(:json, errors, operation)

    json_encode(
      %{error: Map.put(groups, :message, status_to_message(status))},
      opts
    )
  end

  defp format_errors(:html, errors, status, operation) do
    groups = render_errors(:html, errors, operation)
    code = Conn.Status.code(status)
    message = status_to_message(status)

    """
    <!doctype html>
    <style>#{css()}</style>
    <title>#{message}</title>

    <h1><small>HTTP ERROR #{code}</small>#{message}</h1>

    #{groups}
    """
  end

  defp status_to_message(status) do
    status
    |> Conn.Status.code()
    |> Conn.Status.reason_phrase()
  end

  defp render_errors(:json, errors, operation) do
    accin = %{operation_id: operation.operationId}

    errors
    |> Enum.map(fn
      %InvalidParameterError{in: loc, name: name, validation_error: verr} ->
        {error_group_path([loc_to_group(loc), name]), JSV.normalize_error(verr)}

      %InvalidBodyError{validation_error: verr} ->
        {error_group_path([:body]), JSV.normalize_error(verr)}

      %UnsupportedMediaTypeError{media_type: media_type} ->
        {error_group_path([:media_type]), media_type}
    end)
    |> Enum.reduce(accin, fn {path, err}, acc -> put_in(acc, path, err) end)
  end

  defp render_errors(:html, errors, _operation) do
    errors
    |> Enum.sort_by(fn
      %InvalidParameterError{in: loc, name: name} -> {0, loc, name}
      _ -> {1, nil, nil}
    end)
    |> Enum.map_intersperse(?\n, &err_to_html/1)
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

  def err_to_html(%InvalidBodyError{validation_error: verr}) do
    """
    <section>
    <p>Body payload is not valid.</p>

    <pre>#{String.trim_trailing(Exception.message(verr))}</pre>
    </section>
    """
  end

  def err_to_html(%InvalidParameterError{in: loc, name: name, validation_error: verr}) do
    """
    <section>
    <p>Invalid parameter <code>#{name}</code> in <code>#{loc}</code>.</p>

    <pre>#{String.trim_trailing(Exception.message(verr))}</pre>
    </section>
    """
  end

  def err_to_html(%UnsupportedMediaTypeError{media_type: media_type}) do
    """
    <section>
    <p>Validation for body of type <code>#{media_type}</code> is not supported.</p>
    </section>
    """
  end

  @css_file :code.priv_dir(:moonwalk) |> Path.join("assets/error.min.css")
  @external_resource @css_file
  @css File.read!(@css_file)
  defp css do
    @css
  end
end
