defmodule ElixirCourse.Repo do
  use Ecto.Repo,
    otp_app: :elixir_course,
    adapter: Ecto.Adapters.Postgres
end
