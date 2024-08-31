defmodule Moonwalk.Schema.Ref do
  alias __MODULE__
  alias Moonwalk.Schema.RNS
  defstruct ns: nil, kind: nil, fragment: nil, arg: nil, dynamic?: false

  def parse(url, current_ns) do
    do_parse(url, current_ns, false)
  end

  def parse_dynamic(url, current_ns) do
    do_parse(url, current_ns, true)
  end

  def do_parse(url, current_ns, dynamic?) do
    uri = URI.parse(url)
    {kind, normalized_fragment, arg} = parse_fragment(uri.fragment)

    dynamic? = dynamic? and kind == :anchor

    with {:ok, ns} <- RNS.derive(current_ns, url) |> dbg() do
      ns = RNS.without_fragment(ns)
      {:ok, %Ref{ns: ns, kind: kind, fragment: normalized_fragment, arg: arg, dynamic?: dynamic?}} |> dbg()
    end
  end

  defp parse_fragment(nil) do
    {:top, nil, []}
  end

  defp parse_fragment("") do
    {:top, nil, []}
  end

  defp parse_fragment("/") do
    {:top, nil, []}
  end

  defp parse_fragment("/" <> path = fragment) do
    {:docpath, fragment, parse_docpath(path)}
  end

  defp parse_fragment(anchor) do
    {:anchor, anchor, anchor}
  end

  defp parse_docpath(raw_docpath) do
    raw_docpath |> String.split("/") |> Enum.map(&parse_docpath_segment/1)
  end

  defp parse_docpath_segment(string) do
    case Integer.parse(string) do
      {int, ""} -> int
      _ -> unescape_json_pointer(string)
    end
  end

  defp unescape_json_pointer(str) do
    str
    |> String.replace("~1", "/")
    |> String.replace("~0", "~")
    |> URI.decode()
  end
end
