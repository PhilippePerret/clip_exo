defmodule ClipExo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ClipExoWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:clip_exo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ClipExo.PubSub},
      # Start a worker by calling: ClipExo.Worker.start_link(arg)
      # {ClipExo.Worker, arg},
      # Start to serve requests, typically the last entry
      ClipExoWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ClipExo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ClipExoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
