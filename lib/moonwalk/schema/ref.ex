defmodule Moonwalk.Schema.RNS do
  # A "namespace" for a schema ID or reference
  # Universal Resource Reference. That is
  # basically a URI but with a hack to support URNs (urn:isbn:1234 is
  # represented as urn://isbn/1234)
  defstruct [:uri, urn?: false]

  def parse("urn:" <> _ = urn) do
    %{host: nil, path: path} = uri = URI.parse(urn)
    [host, path] = String.split(path, ":", parts: 2)
    uri = %URI{uri | host: host, path: "/" <> path}
    %__MODULE__{uri: uri, urn?: true}
  end

  def parse(string) when is_binary(string) do
    %__MODULE__{uri: URI.parse(string)}
  end

  def parse(:root) do
    %__MODULE__{uri: :root}
  end

  def derive(parent, child) do
    parent_rns = parse(parent)
    child_rns = parse(child)

    with {:ok, merged} <- merge(parent_rns, child_rns) do
      {:ok, to_ns(merged)}
    end
  end

  defp merge(%{uri: :root} = parent, %{uri: %{host: nil, path: nil}}) do
    {:ok, parent}
  end

  defp merge(%{uri: :root} = parent, %{uri: %{host: host}} = child) when is_binary(host) do
    {:ok, child}
  end

  defp merge(%{uri: :root} = parent, %{uri: child}) do
    {:error, {:invalid_child_ns, URI.to_string(child)}}
  end

  defp merge(%{uri: parent_uri, urn?: urn?}, %{uri: child_uri}) do
    {:ok, %__MODULE__{uri: URI.merge(parent_uri, child_uri), urn?: urn?}}
  end

  def to_ns(%{uri: :root}) do
    :root
  end

  def to_ns(%{uri: uri, urn?: true}) do
    %{host: host, path: "/" <> path} = uri
    uri = %URI{uri | host: nil, path: host <> ":" <> path}
    to_string_no_fragment(uri)
  end

  def to_ns(%{uri: uri}) do
    to_string_no_fragment(uri)
  end

  defp to_string_no_fragment(%URI{} = uri) do
    String.Chars.URI.to_string(Map.put(uri, :fragment, nil))
  end
end

defmodule Moonwalk.Schema.Ref do
  alias __MODULE__
  alias Moonwalk.Schema.RNS
  defstruct ns: nil, kind: nil, fragment: nil, arg: nil, dynamic?: false

  defguardp is_not_blank(str) when is_binary(str) and str != ""

  def parse(url, current_ns) do
    do_parse(url, current_ns, false)
  end

  def parse_dynamic(url, current_ns) do
    do_parse(url, current_ns, true)
  end

  def do_parse(url, current_ns, dynamic?) do
    uri = URI.parse(url)
    {kind, normalized_fragment, arg} = parse_fragment(uri.fragment)
    dynamic? = dynamic? and normalized_fragment != nil

    with {:ok, ns} <- RNS.derive(current_ns, url) do
      {:ok, %Ref{ns: ns, kind: kind, fragment: normalized_fragment, arg: arg, dynamic?: dynamic?}}
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
    {:anchor, "#" <> anchor, anchor}
  end

  defp parse_docpath(raw_docpath) do
    raw_docpath |> String.split("/") |> Enum.map(&unescape_json_pointer/1)
  end

  defp unescape_json_pointer(str) do
    str
    |> String.replace("~1", "/")
    |> String.replace("~0", "~")
    |> URI.decode()
  end

  @doc """
  Returns a key that identifies the associated validators in a context
  """
  def to_key(ref) do
    %Ref{kind: kind, ns: ns, fragment: fragment} = ref

    case kind do
      :top -> {ns, :top}
      :docpath -> {ns, :pointer, fragment}
      :anchor -> {ns, :anchor, fragment}
    end
  end

  # defimpl Inspect do
  #   def inspect(%Ref{kind: kind, ns: :root, fragment: frag}, _opts) do
  #     "Ref<#{inspect(kind)}, :root|#{frag}>"
  #   end

  #   def inspect(%Ref{kind: kind, ns: ns, fragment: frag}, _opts) do
  #     "Ref<#{inspect(kind)}, #{ns}#{frag}>"
  #   end
  # end
end
