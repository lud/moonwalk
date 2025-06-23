defmodule Moonwalk.TestWeb.LabController do
  alias Moonwalk.TestWeb.Responder
  use Moonwalk.TestWeb, :controller

  # TODO(doc) We can just declare an existing operation id if the spec is built
  # from a document rather from paths.
  use_operation :create_potion, "createPotion"

  def create_potion(conn, params) do
    Responder.reply(conn, params)
  end

  use_operation :list_alchemists, "listAlchemists"

  def list_alchemists(conn, params) do
    Responder.reply(conn, params)
  end

  use_operation :search_alchemists, "searchAlchemists"

  def search_alchemists(conn, params) do
    Responder.reply(conn, params)
  end
end
