defmodule ElixirCourse.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :title, :string, null: false
      add :description, :text
      add :status, :string, default: "todo"
      add :priority, :string, default: "medium"
      add :due_date, :date
      add :completed_at, :naive_datetime
      add :estimated_hours, :decimal, precision: 8, scale: 2
      add :actual_hours, :decimal, precision: 8, scale: 2
      add :tags, {:array, :string}, default: []

      add :creator_id, references(:users, on_delete: :restrict), null: false
      add :assignee_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    # Indexes for performance
    create index(:tasks, [:creator_id])
    create index(:tasks, [:assignee_id])
    create index(:tasks, [:status])
    create index(:tasks, [:priority])
    create index(:tasks, [:due_date])
    create index(:tasks, [:completed_at])
    create index(:tasks, [:inserted_at])

    # Composite indexes for common queries
    create index(:tasks, [:status, :priority])
    create index(:tasks, [:assignee_id, :status])
    create index(:tasks, [:creator_id, :status])

    # GIN index for tags array searching (PostgreSQL specific)
    create index(:tasks, [:tags], using: :gin)
  end
end
