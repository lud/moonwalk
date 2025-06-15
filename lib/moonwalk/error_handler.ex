defmodule Moonwalk.ErrorHandler do
  alias Moonwalk.Errors.InvalidBodyError
  alias Moonwalk.Errors.InvalidParameterError
  alias Moonwalk.Errors.MissingParameterError
  alias Moonwalk.Errors.UnsupportedMediaTypeError
  alias Plug.Conn

  @moduledoc false

  # TODO(doc) define a behaviour with the right specs to know what error tuples
  # are passed. Parameters errors can be invalid or missing.

  # TODO(doc) the default error handler will serve text/html only if the request
  # specifically allows it. Otherwise it's JSON. This help when debugging with
  # cURL by not having to put the Accept header all the time.

  def handle_error(conn, reason, opts) do
    operation = Moonwalk.Plugs.ValidateRequest.fetch_operation!(conn)

    # we will render HTML for any content
    format = response_formatter(conn, opts)
    status = response_status(reason)

    body = format_reason(format, reason, status, operation)

    conn
    |> Conn.put_resp_content_type(resp_content_type(format))
    |> Conn.send_resp(status, body)
    |> Conn.halt()
  end

  defp response_formatter(conn, opts) do
    with [accept | _] <- Plug.Conn.get_req_header(conn, "accept"),
         true <- accept =~ "html" do
      :html
    else
      _ -> {:json, json_opts(opts)}
    end
  end

  defp response_status(reason) do
    case reason do
      %InvalidBodyError{} -> :unprocessable_entity
      %UnsupportedMediaTypeError{} -> :unsupported_media_type
      {:invalid_parameters, [_ | _]} -> :bad_request
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

  defp format_reason({:json, json_opts}, reason, status, operation) do
    payload = %{error: reason_to_json(reason, status, operation)}
    json_encode(payload, json_opts)
  end

  defp format_reason(:html, reason, status, operation) do
    errors = format_html_errors(reason)
    code = Conn.Status.code(status)
    message = status_to_message(status)

    """
    <!doctype html>
    <style>#{css()}</style>
    <title>#{message}</title>

    <h1>
    <span class="status">HTTP ERROR #{code}</span>
    #{message}
    </h1>

    <p>Invalid request for operation <code>#{operation.operationId}</code>.</p>

    <ol>
      #{errors}
    </ol>
    """
  end

  defp base_json_error(status, operation, overrides) do
    Map.merge(
      %{
        message: status_to_message(status),
        kind: status,
        operation_id: operation.operationId
      },
      overrides
    )
  end

  defp reason_to_json(%InvalidBodyError{} = e, status, operation) do
    base_json_error(status, operation, %{
      "in" => "body",
      "validation_error" => JSV.normalize_error(e.validation_error)
    })
  end

  defp reason_to_json(%UnsupportedMediaTypeError{} = e, status, operation) do
    base_json_error(status, operation, %{
      "in" => "body",
      "media_type" => e.media_type
    })
  end

  defp reason_to_json({:invalid_parameters, list}, status, operation) do
    base_json_error(status, operation, %{
      "in" => "parameters",
      "parameters_errors" => list |> sort_errors() |> Enum.map(&parameter_error_to_json/1)
    })
  end

  defp parameter_error_to_json(%InvalidParameterError{} = e) do
    %{in: loc, name: name, validation_error: verr} = e

    %{
      "kind" => "invalid_parameter",
      "parameter" => name,
      "in" => loc,
      "validation_error" => JSV.normalize_error(verr),
      "message" => "invalid parameter #{name} in #{loc}"
    }
  end

  defp parameter_error_to_json(%MissingParameterError{} = e) do
    %{in: loc, name: name} = e

    %{
      "kind" => "missing_parameter",
      "parameter" => name,
      "in" => loc,
      "message" => Exception.message(e)
    }
  end

  defp status_to_message(status) when is_atom(status) do
    status
    |> Conn.Status.code()
    |> Conn.Status.reason_phrase()
  end

  defp format_html_errors(reason) do
    reason
    |> sort_errors()
    |> Enum.map_intersperse(?\n, &reason_to_html/1)
  end

  # sort_errors also converts the reason to a list if not already a list, this
  # is useful to render html blocks. For json rendering it is only called for
  # parameters.

  defp sort_errors(%InvalidBodyError{} = e) do
    [e]
  end

  defp sort_errors(%UnsupportedMediaTypeError{} = e) do
    [e]
  end

  defp sort_errors({:invalid_parameters, list}) do
    sort_errors(list)
  end

  defp sort_errors(errors) when is_list(errors) do
    Enum.sort_by(errors, fn
      %MissingParameterError{in: loc, name: name} -> {0, loc, name}
      %InvalidParameterError{in: loc, name: name} -> {1, loc, name}
      _ -> {255, nil, nil}
    end)
  end

  defp reason_to_html(%InvalidBodyError{validation_error: verr}) do
    """
    <li>
    <h2>Invalid request body.</h2>

    <pre>#{String.trim_trailing(Exception.message(verr))}</pre>
    </li>
    """
  end

  defp reason_to_html(%InvalidParameterError{in: loc, name: name, validation_error: verr}) do
    """
    <li>
    <h2>Invalid parameter <code>#{name}</code> in <code>#{loc}</code>.</h2>

    <pre>#{String.trim_trailing(Exception.message(verr))}</pre>
    </li>
    """
  end

  defp reason_to_html(%MissingParameterError{in: loc, name: name}) do
    """
    <li>
    <h2>Missing required parameter <code>#{name}</code> in <code>#{loc}</code>.</h2>
    </li>
    """
  end

  defp reason_to_html(%UnsupportedMediaTypeError{media_type: media_type}) do
    """
    <li>
    <h2>Validation for body of type <code>#{media_type}</code> is not supported.</h2>
    </li>
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
