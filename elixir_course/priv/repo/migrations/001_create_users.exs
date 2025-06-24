defmodule ElixirCourse.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :name, :string, null: false
      add :avatar_url, :string
      add :status, :string, default: "offline"
      add :last_seen_at, :naive_datetime

      timestamps()
    end

    create unique_index(:users, [:email])
    create index(:users, [:status])
    create index(:users, [:last_seen_at])
  end
end
