defmodule DemoPhoenix.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DemoPhoenixWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:demo_phoenix, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: DemoPhoenix.PubSub},
      # Start a worker by calling: DemoPhoenix.Worker.start_link(arg)
      # {DemoPhoenix.Worker, arg},
      # Start to serve requests, typically the last entry
      DemoPhoenixWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DemoPhoenix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DemoPhoenixWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
