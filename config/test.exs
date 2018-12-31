use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :btcsim, BtcsimWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :btcsim, Btcsim.Repo,
  username: "postgres",
  password: "postgres",
  database: "btcsim_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
