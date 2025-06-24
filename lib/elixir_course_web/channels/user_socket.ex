defmodule ElixirCourseWeb.UserSocket do
  use Phoenix.Socket

  # A Socket handler
  #
  # It's possible to control the websocket connection and
  # assign values that can be accessed by your channel topics.

  ## Channels
  channel "task_board", ElixirCourseWeb.TaskBoardChannel

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error` or `{:error, term}`. To control the
  # response the client receives in that case, see `websocket_error/2`
  @impl true
  def connect(%{"user_id" => user_id}, socket, _connect_info) do
    # In a real app, you'd verify the user_id with a token
    # For demo purposes, we'll just accept any user_id
    {:ok, assign(socket, :user_id, String.to_integer(user_id))}
  end

  def connect(_params, _socket, _connect_info) do
    # Reject connection if no user_id provided
    :error
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     Elixir.ElixirCourseWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.user_id}"
end
