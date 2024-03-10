defmodule Moonwalk.Schema.Ref do
  alias __MODULE__
  defstruct [:ns, :kind, :fragment, :docpath]

  defguardp is_not_blank(str) when is_binary(str) and str != ""

  def parse(url, current_ns) do
    uri = URI.parse(url)
    {kind, normalized_fragment, docpath} = parse_fragment(uri.fragment)

    ns =
      case uri do
        # ref with a "namespace" (an absolute url with scheme, host and path)
        # we keep that namespace
        %URI{scheme: scheme, host: host, path: path} = uri
        when is_not_blank(scheme) and is_not_blank(host) and is_not_blank(path) ->
          URI.to_string(%URI{uri | fragment: nil})

        # No host but another path, we need to merge the path on top of the
        # current namespace
        %URI{host: nil, path: path} = uri when is_not_blank(path) ->
          merged = URI.merge(URI.parse(current_ns), %URI{uri | fragment: nil})
          URI.to_string(merged)

        # Fragment only,
        %URI{host: nil, path: nil} ->
          current_ns
      end

    {:ok, %Ref{ns: ns, kind: kind, fragment: normalized_fragment, docpath: docpath}}
  rescue
    _ -> {:error, {:invalid_ref, url, current_ns}}
  end

  defp parse_fragment(nil) do
    {:top, "#", []}
  end

  defp parse_fragment("#") do
    {:top, "#", []}
  end

  defp parse_fragment("#/") do
    {:top, "#", []}
  end

  defp parse_fragment("#/" <> path = fragment) do
    {:docpath, fragment, parse_docpath(path)}
  end

  defp parse_docpath(raw_docpath) do
    String.split(raw_docpath, "/")
  end

  @doc """
  Returns a key that identifies the associated validators in a context
  """
  def to_key(%Ref{ns: ns, fragment: fragment}) do
    {ns, fragment}
  end

  defimpl Inspect do
    def inspect(%Ref{ns: :root, fragment: frag}, _opts) do
      "Ref<#{frag}>"
    end

    def inspect(%Ref{ns: ns, fragment: frag}, _opts) do
      "Ref<#{ns}#{frag}>"
    end
  end
end
