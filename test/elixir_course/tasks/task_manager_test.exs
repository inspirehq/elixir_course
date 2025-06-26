defmodule ElixirCourse.Tasks.TaskManagerTest do
  @moduledoc """
  Simplified tests for the TaskManager GenServer.

  This test suite demonstrates:
  - Basic GenServer testing patterns
  - State management testing
  - CRUD operations through GenServer
  - Simple filtering and sorting
  """

  use ElixirCourse.DataCase, async: false
  use ExUnit.Case, async: false

  alias ElixirCourse.Tasks.TaskManager
  alias ElixirCourse.Accounts

  # Test fixtures
  @valid_user_attrs %{
    email: "test@company.com",
    name: "Test User"
  }

  @valid_task_attrs %{
    title: "Test Task",
    description: "Test Description",
    priority: "medium",
    status: "todo"
  }

  setup do
    # Simple setup - ensure TaskManager is running and clear its state
    pid = Process.whereis(TaskManager)

    if pid do
      Ecto.Adapters.SQL.Sandbox.allow(ElixirCourse.Repo, self(), pid)
      :ok = GenServer.call(TaskManager, :clear_cache)
    end

    # Create test user
    {:ok, user} = Accounts.create_user(@valid_user_attrs)

    %{user: user}
  end

  describe "GenServer state management" do
    test "initializes with empty state", %{user: _user} do
      # Get initial cache stats
      stats = TaskManager.get_cache_stats()

      assert stats.cached_tasks == 0
      assert stats.cache_hits == 0
      assert stats.cache_misses == 0
    end

    test "maintains task cache correctly", %{user: user} do
      task_attrs = Map.put(@valid_task_attrs, :creator_id, user.id)

      # Create task through TaskManager
      {:ok, _task} = TaskManager.create_task(task_attrs)

      # Verify task is in cache
      {:ok, tasks} = TaskManager.get_tasks()
      assert match?([_], tasks)

      # Verify cache stats
      stats = TaskManager.get_cache_stats()
      assert stats.cached_tasks == 1
    end

    test "clears cache correctly", %{user: user} do
      # Create a task first
      task_attrs = Map.put(@valid_task_attrs, :creator_id, user.id)
      {:ok, _task} = TaskManager.create_task(task_attrs)

      # Verify task is in cache
      {:ok, tasks} = TaskManager.get_tasks()
      assert match?([_], tasks)

      # Clear cache
      :ok = GenServer.call(TaskManager, :clear_cache)

      # Verify cache is empty
      {:ok, tasks} = TaskManager.get_tasks()
      assert Enum.empty?(tasks)
    end
  end

  describe "task operations" do
    test "creates task successfully", %{user: user} do
      task_attrs = Map.put(@valid_task_attrs, :creator_id, user.id)

      assert {:ok, task} = TaskManager.create_task(task_attrs)
      assert task.title == @valid_task_attrs.title
      assert task.creator_id == user.id
      assert task.status == "todo"
    end

    test "returns error for invalid task", %{user: user} do
      invalid_attrs = %{title: "", creator_id: user.id}

      assert {:error, changeset} = TaskManager.create_task(invalid_attrs)
      assert %{title: ["can't be blank"]} = errors_on(changeset)
    end

    test "updates task successfully", %{user: user} do
      task_attrs = Map.put(@valid_task_attrs, :creator_id, user.id)
      {:ok, task} = TaskManager.create_task(task_attrs)

      update_attrs = %{title: "Updated Title", status: "in_progress"}

      assert {:ok, updated_task} = TaskManager.update_task(task.id, update_attrs)
      assert updated_task.title == "Updated Title"
      assert updated_task.status == "in_progress"
    end

    test "deletes task successfully", %{user: user} do
      task_attrs = Map.put(@valid_task_attrs, :creator_id, user.id)
      {:ok, task} = TaskManager.create_task(task_attrs)

      assert {:ok, _deleted_task} = TaskManager.delete_task(task.id)

      # Verify task is removed from cache
      {:ok, tasks} = TaskManager.get_tasks()
      assert Enum.empty?(tasks)
    end

    test "handles non-existent task gracefully", %{user: _user} do
      assert {:error, :not_found} = TaskManager.update_task(999, %{title: "New Title"})
      assert {:error, :not_found} = TaskManager.delete_task(999)
    end
  end

  describe "task filtering and sorting" do
    setup %{user: user} do
      # Create multiple tasks with different attributes
      tasks = [
        %{title: "Urgent Bug Fix", priority: "urgent", status: "todo", creator_id: user.id},
        %{
          title: "Feature Development",
          priority: "medium",
          status: "in_progress",
          creator_id: user.id
        },
        %{title: "Code Review", priority: "low", status: "review", creator_id: user.id}
      ]

      created_tasks =
        Enum.map(tasks, fn attrs ->
          {:ok, task} = TaskManager.create_task(attrs)
          task
        end)

      %{tasks: created_tasks}
    end

    test "filters by status", %{tasks: _tasks} do
      {:ok, todo_tasks} = TaskManager.get_tasks(%{status: "todo"})
      assert match?([_], todo_tasks)

      {:ok, in_progress_tasks} = TaskManager.get_tasks(%{status: "in_progress"})
      assert match?([_], in_progress_tasks)
    end

    test "filters by priority", %{tasks: _tasks} do
      {:ok, urgent_tasks} = TaskManager.get_tasks(%{priority: "urgent"})
      assert match?([_], urgent_tasks)

      {:ok, low_tasks} = TaskManager.get_tasks(%{priority: "low"})
      assert match?([_], low_tasks)
    end

    test "filters by search term", %{tasks: _tasks} do
      {:ok, search_tasks} = TaskManager.get_tasks(%{search: "Bug"})
      assert match?([_], search_tasks)

      {:ok, no_results} = TaskManager.get_tasks(%{search: "NonExistent"})
      assert Enum.empty?(no_results)
    end

    test "sorts by priority", %{tasks: _tasks} do
      {:ok, sorted_tasks} = TaskManager.get_tasks(%{sort_by: "priority"})
      priorities = Enum.map(sorted_tasks, & &1.priority)

      # Should be ordered: urgent, medium, low
      assert priorities == ["urgent", "medium", "low"]
    end

    test "combines filters and sorting", %{tasks: _tasks} do
      # Get all tasks sorted by status
      {:ok, sorted_tasks} = TaskManager.get_tasks(%{sort_by: "status"})

      assert length(sorted_tasks) == 3
      statuses = Enum.map(sorted_tasks, & &1.status)
      # Should be ordered: todo, in_progress, review
      assert statuses == ["todo", "in_progress", "review"]
    end
  end

  describe "error handling" do
    test "handles invalid task data gracefully", %{user: user} do
      # Test with invalid data
      invalid_attrs = %{title: String.duplicate("x", 300), creator_id: user.id}

      assert {:error, changeset} = TaskManager.create_task(invalid_attrs)
      assert changeset.errors != []
    end

    test "maintains state consistency during errors", %{user: user} do
      # Create valid task
      task_attrs = Map.put(@valid_task_attrs, :creator_id, user.id)
      {:ok, task} = TaskManager.create_task(task_attrs)

      # Try invalid update
      {:error, _changeset} = TaskManager.update_task(task.id, %{title: ""})

      # Verify original task is still in cache unchanged
      {:ok, tasks} = TaskManager.get_tasks()
      found_task = Enum.find(tasks, &(&1.id == task.id))
      assert found_task.title == @valid_task_attrs.title
    end
  end
end
