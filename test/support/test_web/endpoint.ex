defmodule Moonwalk.TestWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :moonwalk

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Moonwalk.TestWeb.Router
end
