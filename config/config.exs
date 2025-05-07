import Config

if config_env() in [:test] do
  import_config "#{config_env()}.exs"
end
