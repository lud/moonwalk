defmodule Moonwalk.TestWeb.ParamController do
  alias JSV.Schema
  alias Moonwalk.TestWeb.Responder
  use Moonwalk.TestWeb, :controller

  plug Moonwalk.Plug.ValidateRequest

  @shape Schema.string_to_atom_enum([:square, :circle])
  @theme Schema.string_to_atom_enum([:dark, :light])
  @color Schema.string_to_atom_enum([:red, :blue])

  operation :single_path_param,
    parameters: [
      theme: [in: :path, schema: @theme]
    ]

  def single_path_param(conn, params) do
    Responder.reply(conn, params)
  end
end
