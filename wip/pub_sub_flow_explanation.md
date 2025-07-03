# TaskManager PubSub Flow (ElixirCourse)

This document explains the exact flow of PubSub events and task data in the ElixirCourse app.

---

## 1. What Triggers a PubSub Event?

- When a task is **created, updated, or deleted** (via the `ElixirCourse.Tasks` context), the code does:
  ```elixir
  Phoenix.PubSub.broadcast(ElixirCourse.PubSub, "tasks", {:task_created, task})
  # or {:task_updated, task}, {:task_deleted, task}
  ```

---

## 2. Who Listens to PubSub?

- **TaskManager GenServer** subscribes to the "tasks" topic on startup.
- **LiveView** processes (e.g., `TaskBoardLive`) subscribe to "tasks" when a user connects.
- **Channel** processes (e.g., `TaskBoardChannel`) may also subscribe to "tasks".

---

## 3. What Happens When a PubSub Event is Received?

- **TaskManager GenServer**:
  - Receives the event (e.g., `{:task_created, task}`).
  - Updates its in-memory cache of tasks.
  - Notifies any direct process subscribers (e.g., channels) via `send(pid, message)`.

- **LiveView**:
  - Receives the event.
  - Fetches the latest tasks from TaskManager (using its cache, not the DB).
  - Updates the UI for the user.

- **Channel**:
  - Receives the event.
  - Pushes the update to all connected WebSocket clients.

---

## 4. Visual Flow (ASCII Diagram)

```
[DB Write]
    |
    v
[Phoenix.PubSub.broadcast("tasks", {...})]
    |
    v
+-------------------+-------------------+-------------------+
|                   |                   |
|                   |                   |
|             [TaskManager]         [LiveView]         [Channel]
|                   |                   |
|                   |                   |
|   (updates cache) |              (fetches tasks)    (pushes to WS)
|   (notifies subs) |               (updates UI)     (updates clients)
|                   |                   |
+-------------------+-------------------+-------------------+
```

---

## 5. Why This Flow?

- **Performance**: TaskManager cache means LiveView/Channel don't hit the DB on every update.
- **Consistency**: All clients see the same data, always fetched from TaskManager.
- **Real-time**: PubSub ensures all parts of the app react instantly to changes.
- **Extensibility**: Direct process subscriptions allow for testing, monitoring, or other advanced features.

---

## 6. Summary

- **TaskManager** is the single source of truth for in-memory task state.
- **PubSub** is the event bus for broadcasting changes.
- **LiveView/Channels** update their UI state in response to PubSub events, always fetching from TaskManager for consistency.
- **Direct process subscriptions** allow for advanced scenarios (testing, monitoring, etc.).

This design ensures performance, decoupling, and real-time responsiveness across all interfaces.
