defmodule ElixirCourse.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ElixirCourseWeb.Telemetry,
      ElixirCourse.Repo,
      {DNSCluster, query: Application.get_env(:elixir_course, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ElixirCourse.PubSub},
      # Start Phoenix Presence for tracking online users
      ElixirCourseWeb.Presence,
      # Start the Finch HTTP client for sending emails
      {Finch, name: ElixirCourse.Finch},
      # Start the TaskManager GenServer for the capstone project
      ElixirCourse.Tasks.TaskManager,
      # Start a worker by calling: ElixirCourse.Worker.start_link(arg)
      # {ElixirCourse.Worker, arg},
      # Start to serve requests, typically the last entry
      ElixirCourseWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirCourse.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ElixirCourseWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
