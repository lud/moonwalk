defmodule Moonwalk.Schema.FormatValidator do
  @type format :: String.t()
  @callback supported_formats :: [format]
  @callback validate_cast(format, data :: String.t()) :: boolean
end
