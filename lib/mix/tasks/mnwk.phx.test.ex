defmodule Mix.Tasks.Mnwk.Phx.Test do
  @requirements ["app.config"]
  def run(_) do
    Application.put_env(:phoenix, :serve_endpoints, true, persistent: true)
    {:ok, _} = Application.ensure_all_started(:moonwalk)

    spawn(fn ->
      {:ok, _} = Moonwalk.TestWeb.Endpoint.start_link()
      Process.sleep(:infinity)
    end)

    IO.puts("test with http://localhost:5001/params/t/some-invalid")
  end
end
