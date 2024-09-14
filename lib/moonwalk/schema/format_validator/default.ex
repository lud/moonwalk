defmodule Moonwalk.Schema.FormatValidator.Default do
  @behaviour Moonwalk.Schema.FormatValidator

  @impl true
  def supported_formats do
    ["ipv4", "ipv6", "unknown", "regex", "date", "date-time", "time"]
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

  # def validate_cast("time", data) do
  #   case Time.from_iso8601(data) do
  #     {:ok, _} -> true
  #     _ -> false
  #   end
  # end

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
