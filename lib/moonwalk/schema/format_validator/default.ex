defmodule Moonwalk.Schema.FormatValidator.Default.Optional do
  def optional_support(format, is?) when is_boolean(is?) do
    if is? do
      [format]
    else
      []
    end
  end

  def mod_exists?(module) do
    case Code.ensure_loaded(module) do
      {:module, ^module} -> true
      {:error, _} -> false
    end
  end
end

if Moonwalk.Schema.FormatValidator.Default.Optional.mod_exists?(AbnfParsec) do
  defmodule Moonwalk.Schema.FormatValidator.Default.Optional.IRI do
    use AbnfParsec,
      abnf: """
      iri            = scheme ":" ihier-part [ "?" iquery ]
      											[ "#" ifragment ]

      ihier-part     = "//" iauthority ipath-abempty
      							/ ipath-absolute
      							/ ipath-rootless
      							/ ipath-empty

      iri-reference  = iri / irelative-ref

      absolute-iri   = scheme ":" ihier-part [ "?" iquery ]

      irelative-ref  = irelative-part [ "?" iquery ] [ "#" ifragment ]

      irelative-part = "//" iauthority ipath-abempty
      										/ ipath-absolute

      							/ ipath-noscheme
      							/ ipath-empty

      iauthority     = [ iuserinfo "@" ] ihost [ ":" port ]
      iuserinfo      = *( iunreserved / pct-encoded / sub-delims / ":" )
      ihost          = IP-literal / IPv4address / ireg-name

      ireg-name      = *( iunreserved / pct-encoded / sub-delims )

      ipath          = ipath-abempty   ; begins with "/" or is empty
      							/ ipath-absolute  ; begins with "/" but not "//"
      							/ ipath-noscheme  ; begins with a non-colon segment
      							/ ipath-rootless  ; begins with a segment
      							/ ipath-empty     ; zero characters

      ipath-abempty  = *( "/" isegment )
      ipath-absolute = "/" [ isegment-nz *( "/" isegment ) ]
      ipath-noscheme = isegment-nz-nc *( "/" isegment )
      ipath-rootless = isegment-nz *( "/" isegment )
      ipath-empty    = 0<ipchar>

      isegment       = *ipchar
      isegment-nz    = 1*ipchar
      isegment-nz-nc = 1*( iunreserved / pct-encoded / sub-delims
      										/ "@" )
      							; non-zero-length segment without any colon ":"

      ipchar         = iunreserved / pct-encoded / sub-delims / ":"
      							/ "@"

      iquery         = *( ipchar / iprivate / "/" / "?" )

      ifragment      = *( ipchar / "/" / "?" )

      iunreserved    = ALPHA / DIGIT / "-" / "." / "_" / "~" / ucschar

      ucschar        = %xA0-D7FF / %xF900-FDCF / %xFDF0-FFEF
      							/ %x10000-1FFFD / %x20000-2FFFD / %x30000-3FFFD
      							/ %x40000-4FFFD / %x50000-5FFFD / %x60000-6FFFD
      							/ %x70000-7FFFD / %x80000-8FFFD / %x90000-9FFFD
      							/ %xA0000-AFFFD / %xB0000-BFFFD / %xC0000-CFFFD
      							/ %xD0000-DFFFD / %xE1000-EFFFD

      iprivate       = %xE000-F8FF / %xF0000-FFFFD / %x100000-10FFFD

      scheme         = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )

      port           = *DIGIT

      IP-literal     = "[" ( IPv6address / IPvFuture  ) "]"

      IPvFuture      = "v" 1*HEXDIG "." 1*( unreserved / sub-delims / ":" )

      IPv6address    =                            6( h16 ":" ) ls32
                      /                       "::" 5( h16 ":" ) ls32
                      / [               h16 ] "::" 4( h16 ":" ) ls32
                      / [ *1( h16 ":" ) h16 ] "::" 3( h16 ":" ) ls32
                      / [ *2( h16 ":" ) h16 ] "::" 2( h16 ":" ) ls32
                      / [ *3( h16 ":" ) h16 ] "::"    h16 ":"   ls32
                      / [ *4( h16 ":" ) h16 ] "::"              ls32
                      / [ *5( h16 ":" ) h16 ] "::"              h16
                      / [ *6( h16 ":" ) h16 ] "::"

      h16            = 1*4HEXDIG
      ls32           = ( h16 ":" h16 ) / IPv4address

      IPv4address    = dec-octet "." dec-octet "." dec-octet "." dec-octet

      dec-octet      = DIGIT                 ; 0-9
                      / %x31-39 DIGIT         ; 10-99
                      / "1" 2DIGIT            ; 100-199
                      / "2" %x30-34 DIGIT     ; 200-249
                      / "25" %x30-35          ; 250-255

      pct-encoded    = "%" HEXDIG HEXDIG

      unreserved     = ALPHA / DIGIT / "-" / "." / "_" / "~"
      reserved       = gen-delims / sub-delims
      gen-delims     = ":" / "/" / "?" / "#" / "[" / "]" / "@"
      sub-delims     = "!" / "$" / "&" / "'" / "(" / ")"
                      / "*" / "+" / "," / ";" / "="
      """,
      unbox: [],
      ignore: [],
      parse: :iri

    def parse_iri(data) do
      case iri(data) do
        ok when elem(ok, 0) == :ok -> {:ok, URI.parse(data)}
        error when elem(error, 0) == :error -> {:error, :invalid_iri}
      end
    end

    def parse_iri_reference(data) do
      case iri_reference(data) do
        ok when elem(ok, 0) == :ok -> {:ok, URI.parse(data)}
        error when elem(error, 0) == :error -> {:error, :invalid_iri_reference}
      end
    end
  end
end

defmodule Moonwalk.Schema.FormatValidator.Default do
  import Moonwalk.Schema.FormatValidator.Default.Optional
  @behaviour Moonwalk.Schema.FormatValidator

  # TODO document that missing implementations can be added by users.

  # TODO document the fact that support for durations is since elixir 1.17.

  # TODO document support for email using mail_address optional dependency and
  # limited by that implementation.

  # TODO document idn-email not supported, and email with limited support.

  # TODO document uri will only check for scheme and host presence

  # TODO document uri-reference is very permissive and will turn most strings
  # into a single path

  @supports_duration mod_exists?(Duration)
  @supports_email mod_exists?(MailAddress.Parser)
  @supports_iri mod_exists?(AbnfParsec)

  # TODO document hostname accepts numerical TLDs and single letter TLDs

  @re_hostname ~r/^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/

  @formats [
             optional_support("duration", @supports_duration),
             optional_support("email", @supports_email),
             optional_support("iri", @supports_iri),
             optional_support("iri-reference", @supports_iri),
             [
               "ipv4",
               "ipv6",
               "unknown",
               "regex",
               "date",
               "date-time",
               "time",
               "email",
               "hostname",
               "uri",
               "uri-reference"
             ]
           ]
           |> :lists.flatten()

  @impl true

  def supported_formats do
    @formats
  end

  @impl true
  def validate_cast("date-time", data) do
    case DateTime.from_iso8601(data) do
      {:ok, dt, _} -> {:ok, dt}
      {:error, _} = err -> err
    end
  end

  def validate_cast("date", data) do
    Date.from_iso8601(data)
  end

  def validate_cast("duration", data) do
    # JSON schema adheres closely to the spec, the duration cannot mix Week and
    # other P-level elements. But we are allowing it because Elixir allows it,
    # we do not want to put arbitrary limit to capabilities.
    Duration.from_iso8601(data)
  end

  def validate_cast("time", data) do
    Time.from_iso8601(String.replace(data, "z", "Z"))
  end

  def validate_cast("ipv4", data) do
    :inet.parse_strict_address(String.to_charlist(data))
  end

  def validate_cast("ipv6", data) do
    # JSON schema spec does not support zone info suffix in ipv6
    with {:ok, {_, _, _, _, _, _, _, _} = ipv6} <- :inet.parse_strict_address(String.to_charlist(data)),
         false <- String.contains?(data, "%") do
      {:ok, ipv6}
    else
      _ -> {:error, :invalid_ipv6}
    end
  end

  def validate_cast("regex", data) do
    Regex.compile(data)
  end

  def validate_cast("unknown", data) do
    {:ok, data}
  end

  if @supports_email do
    def validate_cast("email", data) do
      if MailAddress.Parser.valid?(data) do
        {:ok, data}
      else
        {:error, :invalid_email}
      end
    end
  end

  def validate_cast("hostname", data) do
    if Regex.match?(@re_hostname, data) do
      {:ok, data}
    else
      {:error, :invalid_hostname}
    end
  end

  def validate_cast("iri", data) do
    Moonwalk.Schema.FormatValidator.Default.Optional.IRI.parse_iri(data)
  end

  def validate_cast("iri-reference", data) do
    Moonwalk.Schema.FormatValidator.Default.Optional.IRI.parse_iri_reference(data)
  end

  def validate_cast("uri", data) do
    case URI.parse(data) do
      %{scheme: nil} -> {:error, :no_uri_scheme}
      %{host: nil} -> {:error, :no_uri_host}
      uri -> {:ok, uri}
    end
  end

  def validate_cast("uri-reference", data) do
    case URI.parse(data) do
      %{host: nil, path: path, fragment: frag, query: q} = uri
      when is_binary(path)
      when is_binary(frag)
      when is_binary(q) ->
        {:ok, uri}

      %{host: "", path: path, fragment: frag, query: q} = uri
      when is_binary(path)
      when is_binary(frag)
      when is_binary(q) ->
        {:ok, uri}

      %{host: nil} ->
        {:error, :no_uri_host}

      %{host: ""} ->
        {:error, :no_uri_host}

      uri ->
        {:ok, uri}
    end
  end
end
