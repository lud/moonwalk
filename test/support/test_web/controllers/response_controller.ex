defmodule Moonwalk.TestWeb.ResponseController do
  use Moonwalk.TestWeb, :controller

  defmodule FortuneCookie do
    require(JSV).defschema(%{
      type: :object,
      properties: %{
        category: %{enum: ~w(wisdom humor warning advice)},
        message: %{type: :string}
      }
    })
  end

  @fortunes [
    %{category: "wisdom", message: "Patience is the greatest potion ingredient."},
    %{category: "humor", message: "Never trust a wizard with purple socks."},
    %{category: "warning", message: "Do not mix Phoenix Feather and Dragon Scale!"},
    %{category: "advice", message: "Don't trust Merlin's labels."}
  ]

  operation :fortune_200_valid, operation_id: "fortune_200_valid", responses: [ok: FortuneCookie]

  def fortune_200_valid(conn, _) do
    json(conn, Enum.random(@fortunes))
  end

  # Returns a response that does not match the schema (missing required field)
  operation :fortune_200_invalid, operation_id: "fortune_200_invalid", responses: [ok: FortuneCookie]

  def fortune_200_invalid(conn, _) do
    json(conn, %{message: 123})
  end

  # Returns a response with no content defined in the spec
  operation :fortune_200_no_content_def,
    operation_id: "fortune_200_no_content_def",
    responses: [ok: [description: "Hello"]]

  def fortune_200_no_content_def(conn, _) do
    text(conn, "anything")
  end

  # Returns a response with the wrong content-type (text/plain instead of application/json)
  operation :fortune_200_bad_content_type, operation_id: "fortune_200_bad_content_type", responses: [ok: FortuneCookie]

  def fortune_200_bad_content_type(conn, _) do
    text(conn, "not json")
  end

  operation :fortune_200_no_operation, false

  def fortune_200_no_operation(conn, _) do
    text(conn, "not json")
  end
end
