defmodule ElixirCourse.Tasks.Task do
  @moduledoc """
  Task schema representing a work item in the task management system.

  This schema demonstrates:
  - Comprehensive field validation
  - Custom business logic validation
  - Proper association setup
  - Status management with lifecycle callbacks
  """

  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, except: [:__meta__, :creator, :assignee]}

  @statuses ["todo", "in_progress", "review", "done"]
  @priorities ["low", "medium", "high", "urgent"]

  schema "tasks" do
    field :title, :string
    field :description, :string
    field :status, :string, default: "todo"
    field :priority, :string, default: "medium"
    field :due_date, :date
    field :completed_at, :naive_datetime
    field :estimated_hours, :decimal
    field :actual_hours, :decimal
    field :tags, {:array, :string}, default: []

    # Associations
    belongs_to :creator, ElixirCourse.Accounts.User
    belongs_to :assignee, ElixirCourse.Accounts.User

    timestamps()
  end

  @doc """
  Standard changeset for task creation and updates.

  Validates required fields, field formats, and business rules.
  """
  def changeset(task, attrs) do
    task
    |> cast(attrs, [
      :title, :description, :status, :priority, :due_date,
      :estimated_hours, :actual_hours, :tags, :creator_id, :assignee_id
    ])
    |> validate_required([:title, :creator_id])
    |> validate_length(:title, min: 3, max: 200)
    |> validate_length(:description, max: 2000)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:priority, @priorities)
    |> validate_number(:estimated_hours, greater_than: 0)
    |> validate_number(:actual_hours, greater_than_or_equal_to: 0)
    |> validate_due_date()
    |> validate_tags()
    |> foreign_key_constraint(:creator_id)
    |> foreign_key_constraint(:assignee_id)
    |> maybe_set_completed_at()
  end

  @doc """
  Status update changeset with specific validation for status transitions.
  """
  def status_changeset(task, attrs) do
    task
    |> cast(attrs, [:status])
    |> validate_required([:status])
    |> validate_inclusion(:status, @statuses)
    |> validate_status_transition(task.status)
    |> maybe_set_completed_at()
  end

  @doc """
  Quick update changeset for minor field updates.
  """
  def update_changeset(task, attrs) do
    task
    |> cast(attrs, [:title, :description, :priority, :due_date, :assignee_id])
    |> validate_length(:title, min: 3, max: 200)
    |> validate_length(:description, max: 2000)
    |> validate_inclusion(:priority, @priorities)
    |> validate_due_date()
    |> foreign_key_constraint(:assignee_id)
  end

  # Private validation functions

  defp validate_due_date(changeset) do
    validate_change(changeset, :due_date, fn :due_date, due_date ->
      case Date.compare(due_date, Date.utc_today()) do
        :lt -> [due_date: "cannot be in the past"]
        _ -> []
      end
    end)
  end

  defp validate_tags(changeset) do
    validate_change(changeset, :tags, fn :tags, tags ->
      cond do
        length(tags) > 10 ->
          [tags: "cannot have more than 10 tags"]

        Enum.any?(tags, &(String.length(&1) > 50)) ->
          [tags: "individual tags cannot be longer than 50 characters"]

        Enum.any?(tags, &(String.length(&1) < 2)) ->
          [tags: "individual tags must be at least 2 characters"]

        true ->
          []
      end
    end)
  end

  defp validate_status_transition(changeset, current_status) do
    new_status = get_change(changeset, :status)

    case {current_status, new_status} do
      # Allow any transition from todo
      {"todo", _} -> changeset

      # From in_progress, can go to todo, review, or done
      {"in_progress", status} when status in ["todo", "review", "done"] -> changeset

      # From review, can go back to in_progress or to done
      {"review", status} when status in ["in_progress", "done"] -> changeset

      # From done, can only go back to review (for reopening)
      {"done", "review"} -> changeset

      # Invalid transition
      {current, new} when current != new ->
        add_error(changeset, :status, "invalid status transition from #{current} to #{new}")

      # Same status (no change)
      _ -> changeset
    end
  end

  defp maybe_set_completed_at(changeset) do
    case get_change(changeset, :status) do
      "done" ->
        completed_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        put_change(changeset, :completed_at, completed_at)

      status when status in ["todo", "in_progress", "review"] ->
        put_change(changeset, :completed_at, nil)

      _ ->
        changeset
    end
  end

  # Helper functions for queries and display

  @doc """
  Returns available statuses for the task.
  """
  def statuses, do: @statuses

  @doc """
  Returns available priorities for the task.
  """
  def priorities, do: @priorities

  @doc """
  Returns a human-readable status label.
  """
  def status_label("todo"), do: "To Do"
  def status_label("in_progress"), do: "In Progress"
  def status_label("review"), do: "In Review"
  def status_label("done"), do: "Done"
  def status_label(status), do: status

  @doc """
  Returns a CSS class for priority styling.
  """
  def priority_class("urgent"), do: "text-red-600 bg-red-100"
  def priority_class("high"), do: "text-orange-600 bg-orange-100"
  def priority_class("medium"), do: "text-yellow-600 bg-yellow-100"
  def priority_class("low"), do: "text-green-600 bg-green-100"
  def priority_class(_), do: "text-gray-600 bg-gray-100"

  @doc """
  Returns a CSS class for status styling.
  """
  def status_class("todo"), do: "text-gray-600 bg-gray-100"
  def status_class("in_progress"), do: "text-blue-600 bg-blue-100"
  def status_class("review"), do: "text-purple-600 bg-purple-100"
  def status_class("done"), do: "text-green-600 bg-green-100"
  def status_class(_), do: "text-gray-600 bg-gray-100"

  @doc """
  Checks if a task is overdue.
  """
  def overdue?(%__MODULE__{due_date: nil}), do: false
  def overdue?(%__MODULE__{due_date: _due_date, status: "done"}), do: false
  def overdue?(%__MODULE__{due_date: due_date}) do
    Date.compare(due_date, Date.utc_today()) == :lt
  end

  @doc """
  Checks if a task is due soon (within 3 days).
  """
  def due_soon?(%__MODULE__{due_date: nil}), do: false
  def due_soon?(%__MODULE__{due_date: _due_date, status: "done"}), do: false
  def due_soon?(%__MODULE__{due_date: due_date}) do
    days_until_due = Date.diff(due_date, Date.utc_today())
    days_until_due >= 0 and days_until_due <= 3
  end

  @doc """
  Returns the estimated completion percentage based on status.
  """
  def completion_percentage(%__MODULE__{status: "todo"}), do: 0
  def completion_percentage(%__MODULE__{status: "in_progress"}), do: 50
  def completion_percentage(%__MODULE__{status: "review"}), do: 80
  def completion_percentage(%__MODULE__{status: "done"}), do: 100
end
