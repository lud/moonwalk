defmodule Moonwalk.ErrorHandler do
  alias Moonwalk.Errors.InvalidBodyError
  alias Moonwalk.Errors.InvalidParameterError
  alias Moonwalk.Errors.MissingParameterError
  alias Moonwalk.Errors.UnsupportedMediaTypeError
  alias Plug.Conn

  @moduledoc false

  def handle_errors(conn, status, errors, opts) do
    operation = Moonwalk.Plugs.ValidateRequest.fetch_operation!(conn)

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

  defp format_errors(
         {:json, opts},
         [%UnsupportedMediaTypeError{media_type: media_type}],
         status,
         operation
       ) do
    payload = %{
      error: %{
        message: status_to_message(status),
        operation_id: operation.operationId,
        media_type: media_type
      }
    }

    json_encode(payload, opts)
  end

  defp format_errors({:json, opts}, errors, status, operation) do
    errors_list = render_errors(:json, errors)

    payload = %{
      error: %{
        message: status_to_message(status),
        operation_id: operation.operationId,
        errors: errors_list
      }
    }

    json_encode(payload, opts)
  end

  defp format_errors(:html, errors, status, _operation) do
    groups = render_errors(:html, errors)
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

  defp render_errors(:json, errors) do
    errors
    |> sort_errors()
    |> Enum.map(&err_to_json/1)
  end

  defp render_errors(:html, errors) do
    errors
    |> sort_errors()
    |> Enum.map_intersperse(?\n, &err_to_html/1)
  end

  defp sort_errors(errors) do
    Enum.sort_by(errors, fn
      %MissingParameterError{in: loc, name: name} -> {0, loc, name}
      %InvalidParameterError{in: loc, name: name} -> {1, loc, name}
      _ -> {255, nil, nil}
    end)
  end

  defp err_to_json(%InvalidParameterError{in: loc, name: name, validation_error: verr}) do
    %{
      "kind" => "invalid_parameter",
      "parameter" => name,
      "in" => loc,
      "validation_error" => JSV.normalize_error(verr, sort: :asc),
      # we do not want the JSV error in the message here, but we want it on the
      # exception message if it is risen.
      "message" => "invalid parameter #{name} in #{loc}"
    }
  end

  defp err_to_json(%MissingParameterError{in: loc, name: name} = e) do
    %{
      "kind" => "missing_parameter",
      "parameter" => name,
      "in" => loc,
      "message" => Exception.message(e)
    }
  end

  defp err_to_json(%InvalidBodyError{validation_error: verr}) do
    %{
      "kind" => "invalid_body",
      "in" => "body",
      "validation_error" => JSV.normalize_error(verr, sort: :asc),
      "message" => "invalid body"
    }
  end

  defp err_to_json(%UnsupportedMediaTypeError{media_type: media_type}) do
    %{
      "kind" => "unsupported_media_type",
      "in" => "body",
      "media type" => media_type,
      "message" => "unsupported media type"
    }
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

  defp json_encode(payload, opts) do
    case opts[:pretty] do
      true -> JSV.Codec.format!(payload)
      _ -> JSV.Codec.encode!(payload)
    end
  end

  @css_file :code.priv_dir(:moonwalk) |> Path.join("assets/error.min.css")
  @external_resource @css_file
  @css File.read!(@css_file)
  defp css do
    @css
  end
end
