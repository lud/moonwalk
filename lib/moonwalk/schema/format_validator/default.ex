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

  # TODO document hostname accepts numerical TLDs and single letter TLDs

  @re_hostname ~r/^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/

  @formats [
             optional_support("duration", @supports_duration),
             optional_support("email", @supports_email),
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
