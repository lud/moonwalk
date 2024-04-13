defmodule Moonwalk.Test.TestResolver do
  @mutex __MODULE__.Mutex
  @root_dir Path.join([File.cwd!(), "_build", "test", "resolved"])
  @suite_dir Path.join([File.cwd!(), "deps", "json_schema_test_suite", "remotes"])
  File.mkdir_p!(@root_dir)
  require Logger

  def resolve("http://localhost:1234/" <> _ = url) do
    uri = URI.parse(url)
    path = Path.join(@suite_dir, uri.path)

    with {:ok, json} <- File.read(path) do
      Jason.decode(json)
    end
  end

  def resolve("http://example.com" <> _ = url) do
    raise "should not resolve example.com for #{url}"
  end

  def resolve("http" <> _ = url) do
    %{host: host, path: path, query: nil, fragment: nil} = URI.parse(url)
    path = [@root_dir, host | String.split(path, "/")] |> Path.join()

    Mutex.under(@mutex, {:fetch, host}, fn ->
      case File.read(path) do
        {:ok, json} -> Jason.decode(json)
        {:error, :enoent} -> fetch_and_write(url, path)
      end
    end)
  end

  defp fetch_and_write(url, path) do
    with {:ok, %{status: 200, body: json}} <- http_get(url),
         :ok <- File.mkdir_p(Path.dirname(path)),
         {:ok, data} <- Jason.decode(json),
         :ok <- File.write(path, json) do
      {:ok, data}
    end
  end

  defp http_get(url) do
    headers = []
    http_options = [ssl: ExSslOptions.eef_options()]

    url = String.to_charlist(url)
    IO.puts([IO.ANSI.yellow(), "GET ", url, IO.ANSI.reset()])
    http_result = :httpc.request(:get, {url, headers}, http_options, body_format: :binary)

    case http_result do
      {:ok, {{_, status, _}, _, body}} -> {:ok, %{status: status, body: body}}
      {:error, reason} -> {:error, reason}
    end
  end

  def start_mutex do
    {:ok, _} = Mutex.start(name: @mutex)
  end
end
