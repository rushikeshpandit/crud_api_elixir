defmodule CrudApiElixir.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: CrudApiElixir.Worker.start_link(arg)
      # {CrudApiElixir.Worker, arg}
      {
        Plug.Cowboy,
        scheme: :http,
        plug: CrudApiElixir.Router,
        options: [port: Application.get_env(:crud_api_elixir, :port)]
      },
      {
        Mongo,
        [
          name: :mongo,
          database: Application.get_env(:crud_api_elixir, :database),
          pool_size: Application.get_env(:crud_api_elixir, :pool_size)
        ]
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CrudApiElixir.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
