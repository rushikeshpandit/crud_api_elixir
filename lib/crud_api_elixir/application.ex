defmodule CrudApiElixir.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      CrudApiElixirWeb.Telemetry,
      # Start the Ecto repository
      CrudApiElixir.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: CrudApiElixir.PubSub},
      # Start Finch
      {Finch, name: CrudApiElixir.Finch},
      # Start the Endpoint (http/https)
      CrudApiElixirWeb.Endpoint
      # Start a worker by calling: CrudApiElixir.Worker.start_link(arg)
      # {CrudApiElixir.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CrudApiElixir.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CrudApiElixirWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
