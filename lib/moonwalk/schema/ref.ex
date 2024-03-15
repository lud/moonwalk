defmodule Moonwalk.Schema.Ref do
  alias __MODULE__
  defstruct [:ns, :kind, :fragment, :arg]

  defguardp is_not_blank(str) when is_binary(str) and str != ""

  def parse(url, current_ns) do
    uri = URI.parse(url)
    binding() |> IO.inspect(label: "-- PARSE REF ----------------\n")
    {kind, normalized_fragment, arg} = parse_fragment(uri.fragment)

    ns =
      case uri do
        # ref with a "namespace" (an absolute url with scheme, host and path)
        # we keep that namespace
        %URI{scheme: scheme, host: host, path: path} = uri
        when is_not_blank(scheme) and is_not_blank(host) and is_not_blank(path) ->
          URI.to_string(%URI{uri | fragment: nil})

        %URI{scheme: "urn", path: path} = uri when is_not_blank(path) ->
          URI.to_string(Map.put(uri, :fragment, nil))

        # No host but another path, we need to merge the path on top of the
        # current namespace
        %URI{host: nil, path: path} = uri when is_not_blank(path) ->
          case current_ns do
            :root ->
              raise "todo cannot change path without URI $id"

            x ->
              x |> dbg()
              merged = URI.merge(URI.parse(current_ns), %URI{uri | fragment: nil})
              URI.to_string(merged)
          end

        # Fragment only,
        %URI{host: nil, path: nil} ->
          case URI.parse(current_ns) do
            %{host: host} when is_not_blank(host) -> current_ns
            _ -> raise "cannot make full ref from #{inspect(current_ns)} and #{inspect(url)}"
          end
      end
      |> IO.inspect(label: "ns")

    {:ok, %Ref{ns: ns, kind: kind, fragment: normalized_fragment, arg: arg}}
    |> IO.inspect(label: "okref")

    # rescue
    #   e ->
    #     IO.warn(Exception.format(:error, e, __STACKTRACE__))
    #     {:error, {:invalid_ref, url, current_ns}}
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
