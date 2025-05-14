import Config

config :moonwalk, Moonwalk.TestWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 5001],
  debug_errors: true,
  code_reloader: false,
  secret_key_base: "zANuLKxVwY9Tu3MD+g2XBbCWHbkf1G2GSVgiF4NAq9t03UZU/Wbib2/8lpNPLiCh",
  adapter: Bandit.PhoenixAdapter

config :logger, level: :warning

config :phoenix, :plug_init_mode, :compile
