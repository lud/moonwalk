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
end
