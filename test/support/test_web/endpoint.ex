defmodule Moonwalk.TestWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :moonwalk

  # This is only there so Firefox will be happy with a favicon and stop
  # generating errors in the logs when testing.
  plug Plug.Static, at: "/", from: "test/support/test_web/assets", only: ~w(favicon.ico)

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Moonwalk.TestWeb.Router
end
