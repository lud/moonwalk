import Config

config :moonwalk, Moonwalk.TestWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 5001],
  url: [host: "localhost", port: 5001, scheme: "http"],
  debug_errors: true,
  code_reloader: false,
  secret_key_base: "zANuLKxVwY9Tu3MD+g2XBbCWHbkf1G2GSVgiF4NAq9t03UZU/Wbib2/8lpNPLiCh",
  adapter: Bandit.PhoenixAdapter

config :logger, level: :warning

# config :phoenix, :plug_init_mode, :compile
config :phoenix, :plug_init_mode, :runtime

config :jsv,
  resolver_inspect_derive: [only: [:chain, :default_meta]],
  builder_inspect_derive: [only: [:ns, :current_rev_path, :resolver]]
