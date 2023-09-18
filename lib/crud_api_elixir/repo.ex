defmodule CrudApiElixir.Repo do
  use Ecto.Repo,
    otp_app: :crud_api_elixir,
    adapter: Ecto.Adapters.Postgres
end
