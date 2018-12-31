defmodule Btcsim.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
    Bitcoin.BitcoinSimulator,
    Bitcoin.NetworkSupervisor,
      # Start the Ecto repository
      Btcsim.Repo,
      # Start the endpoint when the application starts
      BtcsimWeb.Endpoint
      # Starts a worker by calling: Btcsim.Worker.start_link(arg)
      # {Btcsim.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Btcsim.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BtcsimWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
