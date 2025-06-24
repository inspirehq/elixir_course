defmodule ElixirCourse.Accounts do
  @moduledoc """
  The Accounts context for managing users.
  """

  import Ecto.Query, warn: false
  alias ElixirCourse.Repo
  alias ElixirCourse.Accounts.User

  @doc """
  Returns the list of users.
  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.
  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) do
    Repo.get_by(User, email: String.downcase(email))
  end

  @doc """
  Creates a user.
  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates user status (online/offline/away).
  """
  def update_user_status(%User{} = user, status) do
    user
    |> User.status_changeset(%{status: status})
    |> Repo.update()
  end

  @doc """
  Deletes a user.
  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc """
  Lists online users for presence tracking.
  """
  def list_online_users do
    from(u in User, where: u.status in ["online", "away"])
    |> Repo.all()
  end
end
