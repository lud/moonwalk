defmodule Moonwalk.TestWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :moonwalk

  # This is only there so Firefox will be happy with a favicon and stop
  # generating errors in the logs when testing.
  plug Plug.Static, at: "/", from: "test/support/test_web/assets", only: ~w(favicon.ico)

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json, :test],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Moonwalk.TestWeb.Router
end

defmodule Plug.Parsers.TEST do
  def init(opts) do
    opts
  end

  def parse(conn, "test", "test", _headers, _opts) do
    # This allows to test an empty body. Because Plug.Parsers can only return
    # maps, Moonwalk considers empty maps as an empty body, _i.e_ it is not
    # validated if RequestBody spec :required option is `false`.
    case Plug.Conn.read_body(conn) do
      {:ok, "", conn} -> {:ok, %{}, conn}
      {:ok, body, conn} -> {:ok, %{raw_body: body}, conn}
    end
  end

  def parse(conn, _type, _subtype, _headers, _opts) do
    {:next, conn}
  end
end
