defmodule ElixirCourse.Accounts.User do
  @moduledoc """
  User schema representing users in the task management system.

  This schema demonstrates:
  - User validation patterns
  - Association management
  - Status tracking for presence features
  """

  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, except: [:__meta__, :created_tasks, :assigned_tasks]}

  @statuses ["online", "offline", "away"]

  schema "users" do
    field :email, :string
    field :name, :string
    field :avatar_url, :string
    field :status, :string, default: "offline"
    field :last_seen_at, :naive_datetime

    # Associations
    has_many :created_tasks, ElixirCourse.Tasks.Task, foreign_key: :creator_id
    has_many :assigned_tasks, ElixirCourse.Tasks.Task, foreign_key: :assignee_id

    timestamps()
  end

  @doc """
  Changeset for creating and updating users.
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :avatar_url, :status, :last_seen_at])
    |> validate_required([:email, :name])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email")
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:email, max: 255)
    |> validate_inclusion(:status, @statuses)
    |> validate_professional_email()
    |> unique_constraint(:email)
    |> normalize_email()
  end

  @doc """
  Changeset for status updates (online/offline/away).
  """
  def status_changeset(user, attrs) do
    user
    |> cast(attrs, [:status, :last_seen_at])
    |> validate_inclusion(:status, @statuses)
    |> maybe_update_last_seen()
  end

  # Private validation functions

  defp validate_professional_email(changeset) do
    validate_change(changeset, :email, fn :email, email ->
      free_providers = ["gmail.com", "yahoo.com", "hotmail.com", "outlook.com"]
      domain = email |> String.split("@") |> List.last() |> String.downcase()

      if domain in free_providers do
        [email: "must be a professional email address"]
      else
        []
      end
    end)
  end

  defp normalize_email(changeset) do
    case get_change(changeset, :email) do
      nil -> changeset
      email -> put_change(changeset, :email, String.downcase(email))
    end
  end

  defp maybe_update_last_seen(changeset) do
    case get_change(changeset, :status) do
      "offline" ->
        put_change(changeset, :last_seen_at, NaiveDateTime.utc_now())

      _ ->
        changeset
    end
  end

  # Helper functions

  @doc """
  Returns available user statuses.
  """
  def statuses, do: @statuses

  @doc """
  Returns the display name for the user.
  """
  def display_name(%__MODULE__{name: name}), do: name

  @doc """
  Returns the user's initials for avatar display.
  """
  def initials(%__MODULE__{name: name}) do
    name
    |> String.split(" ")
    |> Enum.take(2)
    |> Enum.map_join("", &String.first/1)
    |> String.upcase()
  end

  @doc """
  Checks if the user is currently online.
  """
  def online?(%__MODULE__{status: "online"}), do: true
  def online?(_), do: false

  @doc """
  Returns a CSS class for status styling.
  """
  def status_class("online"), do: "text-green-600 bg-green-100"
  def status_class("away"), do: "text-yellow-600 bg-yellow-100"
  def status_class("offline"), do: "text-gray-600 bg-gray-100"
  def status_class(_), do: "text-gray-600 bg-gray-100"

  @doc """
  Returns a status indicator dot color.
  """
  def status_dot_class("online"), do: "bg-green-400"
  def status_dot_class("away"), do: "bg-yellow-400"
  def status_dot_class("offline"), do: "bg-gray-400"
  def status_dot_class(_), do: "bg-gray-400"
end
