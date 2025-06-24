ExUnit.start()

# Ensure application is started
{:ok, _} = Application.ensure_all_started(:elixir_course)

Ecto.Adapters.SQL.Sandbox.mode(ElixirCourse.Repo, :manual)
