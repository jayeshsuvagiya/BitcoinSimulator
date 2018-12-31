defmodule Btcsim.Repo do
  use Ecto.Repo,
    otp_app: :btcsim,
    adapter: Ecto.Adapters.Postgres
end
