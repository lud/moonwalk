defmodule Moonwalk.Test do
  alias Moonwalk.Plugs.ValidateRequest
  alias Moonwalk.JsonSchema.Formats.HttpStructuredField
  import ExUnit.Assertions

  def valid_response(spec_module, %Plug.Conn{} = conn, status) when is_integer(status) do
    operation_id =
      case get_in(conn.private, [:moonwalk, :operation_id]) do
        nil ->
          raise """
          the connection was not validated by Moonwalk.Plugs.ValidateRequest

          This may happen if no pipeline with the Moonwalk plugs is defined for
          the route, if the operation is not declared above the controller function
          or is explictitly disabled with `operation :my_function, false`.
          """

        opid ->
          opid
      end

    body = Phoenix.ConnTest.response(conn, status)

    {validations, jsv_root} = Moonwalk.build_spec!(spec_module, responses: true) |> dbg()

    content_validation =
      with {:ok, path_validations} <- Map.fetch(validations, operation_id) |> dbg(),
           {:ok, responses} <- Keyword.fetch(path_validations, :responses),
           {:ok, status_validations} <- Map.fetch(responses, status) do
        status_validations
      else
        _ ->
          raise "could not find response definition for operation #{inspect(operation_id)} " <>
                  "with status #{inspect(status)}"
      end

    case content_validation do
      [] ->
        body

      [_ | _] ->
        content_type = content_type(conn)

        parse_validate_response(%{
          body: body,
          conn: conn,
          content_type: content_type,
          type_subtype: parse_content_type(content_type),
          content_validation: content_validation,
          jsv_root: jsv_root,
          operation_id: operation_id,
          status: status
        })
    end
  end

  defp parse_validate_response(ctx) do
    jsv_key = match_media_type(ctx)
    body = maybe_parse_body(ctx) |> dbg()

    case JSV.validate(body, ctx.jsv_root, key: jsv_key) do
      {:ok, _} ->
        body

      {:error, jsv_error} ->
        raise "invalid response returned by operation #{inspect(ctx.operation_id)} " <>
                "with status #{inspect(ctx.status)} and content-type #{inspect(ctx.content_type)}" <>
                """
                Schema validation errors:

                #{inspect(JSV.normalize_error(jsv_error), pretty: true, limit: 1000)}
                """
    end
  end

  defp match_media_type(ctx) do
    type_subtype = parse_content_type(ctx.content_type)

    case ValidateRequest.match_media_type(ctx.content_validation, type_subtype) do
      {:ok, {_ct, jsv_key}} ->
        jsv_key

      {:error, :media_type_match} ->
        raise "operation #{inspect(ctx.operation_id)} " <>
                "with status #{inspect(ctx.status)} has no definition for content-type #{inspect(ctx.content_type)}"
    end
  end

  defp maybe_parse_body(ctx) do
    %{body: body, type_subtype: {_, subtype}} = ctx
    # For now we only know how to parse JSON
    cond do
      subtype == "json" -> json_decode!(body)
      String.ends_with?(subtype, "+json") -> json_decode!(body)
      :otherwise -> body
    end
    |> dbg()
  end

  defp json_decode!(data) do
    JSV.Codec.decode!(data)
  end

  defp content_type(conn) do
    case Plug.Conn.get_resp_header(conn, "content-type") do
      [] ->
        raise "missing response content-type header"

      [raw] ->
        case HttpStructuredField.parse_sf_item(raw, unwrap: true, maps: true) do
          {:ok, {token, _}} -> token
          _ -> raise "invalid content-type header: #{inspect(raw)}"
        end

      [_ | _] ->
        raise "multiple content-type header values"
    end
  end

  defp parse_content_type(content_type) do
    case Plug.Conn.Utils.content_type(content_type) do
      :error -> {content_type, ""}
      {:ok, primary, secondary, _params} -> {primary, secondary}
    end
  end
end
