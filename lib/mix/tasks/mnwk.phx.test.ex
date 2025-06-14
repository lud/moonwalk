defmodule Mix.Tasks.Mnwk.Phx.Test do
  use Mix.Task
  @requirements ["app.config"]

  @impl true
  def run(_) do
    Application.put_env(:phoenix, :serve_endpoints, true, persistent: true)
    {:ok, _} = Application.ensure_all_started(:moonwalk)

    spawn(fn ->
      {:ok, _} = Moonwalk.TestWeb.Endpoint.start_link()
      Process.sleep(:infinity)
    end)

    IO.puts("test with http://localhost:5001/generated/params/s/bad-shape/t/bad-theme/c/bad-color?color=not+an+int")
    Mix.Tasks.Run.run(["--no-halt"])
  end
end
