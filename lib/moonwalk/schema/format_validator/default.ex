supports_duration? =
  case Version.parse!(System.version()) do
    %{major: major, minor: minor} when minor >= 17 or major > 1 -> true
    _ -> false
  end

defmodule Moonwalk.Schema.FormatValidator.Default do
  @behaviour Moonwalk.Schema.FormatValidator

  # TODO document the fact that support for durations must be added by users to
  # support durations in elixir < 1.17

  @formats ["ipv4", "ipv6", "unknown", "regex", "date", "date-time", "time"]
  @impl true
  if supports_duration? do
    def supported_formats do
      ["duration" | @formats]
    end
  else
    def supported_formats do
      @formats
    end
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
end
