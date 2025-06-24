defmodule ElixirCourseWeb.UserController do
  use ElixirCourseWeb, :controller

  alias ElixirCourse.Accounts

  def index(conn, _params) do
    users = Accounts.list_users()

    conn
    |> put_status(:ok)
    |> json(%{users: users})
  end

  def show(conn, %{"id" => id}) do
    try do
      user = Accounts.get_user!(id)

      conn
      |> put_status(:ok)
      |> json(%{user: user})
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "User not found"})
    end
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> json(%{user: user})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    try do
      user = Accounts.get_user!(id)

      case Accounts.update_user(user, user_params) do
        {:ok, updated_user} ->
          conn
          |> put_status(:ok)
          |> json(%{user: updated_user})

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: format_errors(changeset)})
      end
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "User not found"})
    end
  end

  def delete(conn, %{"id" => id}) do
    try do
      user = Accounts.get_user!(id)

      case Accounts.delete_user(user) do
        {:ok, _user} ->
          conn
          |> put_status(:no_content)
          |> json(%{})

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: format_errors(changeset)})
      end
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "User not found"})
    end
  end

  # Helper function to format changeset errors
  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
