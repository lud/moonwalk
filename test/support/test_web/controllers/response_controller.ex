defmodule Moonwalk.TestWeb.ResponseController do
  use Moonwalk.TestWeb, :controller

  defmodule FortuneCookie do
    require(JSV).defschema(%{
      type: :object,
      properties: %{
        category: %{enum: ~w(wisdom humor warning advice)},
        message: %{type: :string}
      },
      required: [:category, :message]
    })
  end

  defmodule GenericError do
    require(JSV).defschema(%{
      type: :object,
      properties: %{
        errcode: %{type: :integer},
        message: %{type: :string}
      },
      required: [:errcode, :message]
    })
  end

  @fortunes [
    %{category: "wisdom", message: "Patience is the greatest potion ingredient."},
    %{category: "humor", message: "Never trust a wizard with purple socks."},
    %{category: "warning", message: "Do not mix Phoenix Feather and Dragon Scale!"},
    %{category: "advice", message: "Don't trust Merlin's labels."}
  ]

  operation :no_operation, false

  def no_operation(conn, _) do
    text(conn, "not json")
  end

  operation :valid, operation_id: "fortune_valid", responses: [ok: FortuneCookie]

  def valid(conn, _) do
    json(conn, Enum.random(@fortunes))
  end

  # Returns a response that does not match the schema (missing required field)
  operation :invalid, operation_id: "fortune_invalid", responses: [ok: FortuneCookie]

  def invalid(conn, _) do
    json(conn, %{message: 123})
  end

  # Returns a response with no content defined in the spec
  operation :no_content_def,
    operation_id: "fortune_no_content_def",
    responses: [ok: [description: "Hello"]]

  def no_content_def(conn, _) do
    text(conn, "anything")
  end

  # Returns a response with the wrong content-type (text/plain instead of application/json)
  operation :bad_content_type, operation_id: "fortune_bad_content_type", responses: [ok: FortuneCookie]

  def bad_content_type(conn, _) do
    text(conn, "not json")
  end

  operation :default_resp,
    operation_id: "fortune_default_resp",
    responses: %{200 => FortuneCookie, :default => GenericError}

  def default_resp(conn, _) do
    conn
    |> put_status(500)
    |> json(%{message: "too bad!", errcode: 123_456})
  end

  operation :invalid_default_resp,
    operation_id: "fortune_invalid_default_resp",
    responses: [ok: FortuneCookie, default: GenericError]

  def invalid_default_resp(conn, _) do
    conn
    |> put_status(500)
    |> json(%{message: "too bad!", errcode: "not an int"})
  end
end
