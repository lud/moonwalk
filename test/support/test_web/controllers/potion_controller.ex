defmodule Moonwalk.TestWeb.PotionController do
  alias Moonwalk.TestWeb.Responder
  use Moonwalk.TestWeb, :controller

  operation :create_potion, operation_id: "createPotion"

  def create_potion(conn, params) do
    Responder.reply(conn, params)
  end
end
