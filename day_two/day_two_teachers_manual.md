# Day Two Teacher's Manual
*A Comprehensive Guide for Teaching Advanced Elixir/Phoenix Development*

## 📚 Overview

Day Two builds upon Day One's GenServer foundations to cover database operations, real-time web features, and comprehensive testing strategies. The curriculum progresses from Ecto database operations through real-time Phoenix features, ending with advanced testing approaches.

### Learning Objectives
By the end of Day Two, students will:
- Master Ecto for database operations and data modeling
- Design and implement real-time web features using Phoenix PubSub, Channels, Presence, and Streams
- Understand advanced behaviour patterns and OTP design principles
- Apply comprehensive testing strategies including unit, property-based, and integration testing
- Mock external services effectively for reliable testing
- Debug and optimize database queries and real-time systems

---

## 📖 Lesson-by-Lesson Guide

### 01. Intro to Ecto (45 minutes)

#### 🎯 **Key Concepts**
- **Database Abstraction**: Ecto as a database wrapper and query generator
- **The Repo Pattern**: Understanding the central role of the repository
- **Type Safety**: Compile-time validation of queries and data types
- **Composability**: Building complex queries from simple components
- **Multi-Database Support**: Consistent API across different databases

#### 📝 **Student Summary**
*"Ecto is Elixir's database toolkit that provides a safe, explicit, and composable way to interact with databases. It's built around the Repo pattern and provides five key components: Repo, Schema, Changeset, Query, and Migration."*

#### 🎤 **Teacher Talking Points**

**Ecto's Place in the Ecosystem:**
"Ecto isn't just an ORM in the traditional sense; it's a complete database toolkit. Where other ORMs often try to hide the database behind a wall of 'magic,' Ecto embraces the database. It gives you explicit control and safety, preventing common pitfalls. It's designed by database experts who understand both the power of SQL and the principles of functional programming."

**The Five Pillars of Ecto (Refer to `01_intro_to_ecto.exs`):**
"Let's break down the five core components, which you'll see represented in the exercises."
1.  **Repo**: "The repository, or Repo, is your application's gateway to the database. It manages connections, pooling, and transactions. Think of it as the gatekeeper. You don't talk to the database directly; you go through the Repo. The `ExampleRepo` in the script shows a mock version of this."
2.  **Schema**: "This is the blueprint for your data. It maps database tables to Elixir structs, defining fields and their types. It's how you give your data structure and meaning within your Elixir code."
3.  **Changeset**: "This is arguably one of Ecto's most powerful features. It's a pipeline for filtering, casting, validating, and transforming data *before* it ever touches your database. It's your first line of defense against invalid data."
4.  **Query**: "Ecto gives you a beautiful Domain-Specific Language (DSL) written in pure Elixir for building database queries. These aren't just strings; they are composable data structures that get validated at compile time."
5.  **Migration**: "This is your database's version control. It allows you to evolve your database schema over time in a structured, reversible way."

**The Power of Compile-Time Safety:**
"This is a game-changer. In many languages, you write SQL as strings. You only find out you have a typo or referenced a non-existent column at runtime, often when a user performs an action in production. Ecto validates your queries when you compile your code. If you make a mistake, it won't even build. This eliminates an entire class of bugs."

**Database Agnostic by Design:**
"As the exercise `research_supported_databases` suggests, Ecto supports PostgreSQL, MySQL, SQLite, and even MS SQL Server with the same API. You can develop locally against a lightweight SQLite database and deploy to a robust PostgreSQL cluster without changing your application code. The `Ecto.Adapter` pattern handles the database-specific details for you."

**Performance Philosophy:**
"Ecto is designed to prevent common performance issues seen with other ORMs:"
- "It forces you to be explicit about loading related data, which helps avoid the infamous 'N+1 query' problem."
- "Connection pooling via `DBConnection` is built-in and highly configurable."
- "The composable nature of `Ecto.Query` lets you build efficient queries piece by piece, only fetching what you need."

#### 💬 **Discussion Questions**
1.  **"How does Ecto's explicit, Repo-centric approach differ from Active Record or other ORMs you've used?"**
    - *Explore benefits and trade-offs of explicit control vs. implicit "magic".*
2.  **"Looking at the `types_mapping` in the script, what are the benefits of mapping database types to specific Elixir structs like `Date` and `Decimal`?"**
    - *Discuss type safety, precision (for money), and leveraging Elixir's built-in libraries for handling complex data.*
3.  **"Why is separating the five pillars (Repo, Schema, etc.) a powerful design choice?"**
    - *Explore flexibility, testability, and how it allows each component to excel at its specific job.*

---

### 02. Schemas and Migrations (45 minutes)

#### 🎯 **Key Concepts**
- **Schema Definition**: Mapping database tables to Elixir structs (`schema "users" do ... end`).
- **Field Types & Options**: Understanding Ecto's type system (`:string`, `:integer`, `virtual: true`).
- **Migration Management**: Version-controlled database evolution (`create table`, `alter table`).
- **Index Strategy**: Optimizing database performance with `create index` and `unique_index`.
- **Embedded Schemas**: Storing structured data within a single field (like JSON).

#### 📝 **Student Summary**
*"Schemas define your data's structure and types in Elixir, while migrations manage the database schema's evolution over time. Together, they provide a type-safe, versioned, and explicit way to model your application's data."*

#### 🎤 **Teacher Talking Points**

**Schema as a Contract:**
"Think of a schema as a strict contract between your application and the database. The `DayTwo.User` module in the script shows this. It explicitly declares what fields exist, what their types are, and how they map to the Elixir struct. This isn't just documentation; it's an enforceable boundary."

**Virtual Fields (Refer to `DayTwo.UserWithVirtual`):**
"A key feature shown in the script is the `virtual` field. It's a field that exists on the Elixir struct but is *not* persisted in the database. This is perfect for temporary data, like form fields that aren't columns (e.g., `password_confirmation`) or for computed values (`full_name`)."

**Migration Philosophy: Database Version Control:**
"Migrations are to your database what Git is to your code. You can't just drop and recreate tables in production. Migrations allow you to evolve the schema safely."
- **Point to `show_alter_table_migration`:** "Notice how we can `add` a new column or `modify` an existing one. Ecto is smart enough to know that `add` is reversible."
- **Point to `show_rollback_safety`:** "For more complex changes, like data transformations, Ecto gives you explicit `up` and `down` functions for full control over both applying and reverting a migration."

**Embedded Schemas (Refer to `DayTwo.Address`):**
"Sometimes, you have structured data that doesn't need its own table. An address is a great example. Using `embeds_one` or `embeds_many`, you can define a schema for the address and store it directly in a JSON(B) field on the parent table (e.g., `users`). This keeps related data together without the overhead of a JOIN."

**Indexing is Key for Performance:**
"As applications grow, query performance becomes critical. An index is a database-level optimization that makes looking up records by a specific column incredibly fast. The `create unique_index(:users, [:email])` example is vital. It does two things:
1.  Enforces that no two users can have the same email.
2.  Makes looking up a user by their email almost instantaneous."

#### 💬 **Discussion Questions**
1.  **"When would you choose a `virtual` field over a regular persisted field?"**
    - *Discuss calculated values, temporary form data, and keeping the database schema clean.*
2.  **"What are the pros and cons of using an `embedded_schema` versus creating a separate table with a `belongs_to` association?"**
    - *Explore query simplicity (no join) vs. the inability to query inside the JSON efficiently across the whole table.*
3.  **"The `create_user_with_posts_migration` exercise requires multiple steps. Why is it important that migrations can handle more than just creating a single table?"**
    - *Discuss setting up relationships, backfilling data, and ensuring schema changes happen in the correct order.*

---

### 03. Changesets and Validations (60 minutes)

#### 🎯 **Key Concepts**
- **Data Pipeline**: Viewing changesets as a series of data transformation steps.
- **Casting vs. Changing**: Differentiating between casting external data and explicitly putting changes.
- **Validation & Business Logic**: Using `validate_*` functions to enforce rules.
- **Constraints vs. Validations**: Understanding the difference between application-level checks and database-level enforcement.
- **Contextual Changesets**: Creating different changeset functions for different scenarios (e.g., registration vs. profile update).

#### 📝 **Student Summary**
*"Changesets are the heart of Ecto's data integrity strategy. They provide a powerful pipeline to filter, cast, validate, and transform external data, ensuring that only clean, valid data makes it to your application and database."*

#### 🎤 **Teacher Talking Points**

**Changesets as Data Pipelines:**
"The most important concept to grasp is that a changeset is a data transformation pipeline. Look at the `show_real_blog_changeset` example. Raw data (`attrs`) goes in one end, and it flows through a series of functions piped together. Each function inspects or transforms the data. If at any point a validation fails, the changeset is marked as invalid, and a descriptive error is added. Clean data or a detailed error report comes out the other end."

**The `cast`, `validate`, `constraint` Flow:**
"There's a logical order to changeset functions:"
1.  **`cast`**: "This is the first step. You `cast` the raw, untrusted `attrs` map. You provide a list of allowed fields. This acts as a whitelist, preventing malicious users from trying to inject extra parameters."
2.  **`validate_*`**: "After casting, you apply your business logic validations (`validate_required`, `validate_length`, etc.). These checks happen in Elixir, before touching the database. They provide fast feedback."
3.  **`*_constraint`**: "This is the final check. `unique_constraint` or `foreign_key_constraint` doesn't perform the validation itself. Instead, it tells Ecto how to interpret a specific error if the *database* rejects the data. This is your safeguard against race conditions."

**Contextual Changesets are a Superpower (Refer to `DayTwo.UserContexts`):**
"A single `changeset/2` function is often not enough. The script shows a great example:
-   A `registration_changeset` needs to validate a password.
-   An `update_profile_changeset` probably shouldn't allow password changes.
-   An `admin_changeset` might allow changing a user's role, which is forbidden elsewhere.
This pattern of creating multiple, named changeset functions is a cornerstone of building robust and secure Ecto applications."

**Custom Validations and Transformations:**
"Ecto's built-in validators are great, but you'll always need custom logic. The `generate_slug` and `process_tags` examples in the `DayTwo.BlogPost` module are perfect illustrations. You can create your own private helper functions that receive the changeset, inspect it, and either return it unchanged or add changes and errors."

#### 💬 **Discussion Questions**
1.  **"Why is the distinction between a validation (`validate_format`) and a constraint (`unique_constraint`) so important for data integrity?"**
    - *Discuss race conditions: two users signing up with the same email at the exact same time. The validation might pass for both, but the database constraint will save you.*
2.  **"In the `DayTwo.BlogPost` example, why is it better to generate the `slug` inside the changeset rather than in the controller or context?"**
    - *Explore keeping data logic co-located, ensuring the slug is always generated consistently, and testability.*
3.  **"The `order_changeset_pipeline` exercise mentions `prepare_changes`. Why would a validation need to access the database, and how does this function help?"**
    - *Discuss checking inventory levels, validating a coupon code exists, etc. `prepare_changes` allows you to run functions that can perform these lookups as part of the changeset pipeline.*

---

### 04. Querying (60 minutes)

#### 🎯 **Key Concepts**
- **Query Syntaxes**: Understanding keyword, pipe, and macro forms of `from`.
- **Composable Queries**: Building complex queries from reusable, simple parts.
- **Pin Operator `^`**: Safely injecting Elixir variables into queries to prevent SQL injection.
- **Dynamic Queries**: Building queries programmatically based on conditions.
- **`select` and `fragment`**: Shaping the return data and using raw SQL functions safely.

#### 📝 **Student Summary**
*"Ecto's `Ecto.Query` provides a type-safe, composable DSL to build database queries in pure Elixir. Queries are data structures that can be built dynamically, and the pin operator `^` ensures they remain secure."*

#### 🎤 **Teacher Talking Points**

**Queries are Data Structures, Not Strings:**
"This is the fundamental shift from traditional SQL. An Ecto query is an `Ecto.Query` struct. You can build it, inspect it, pass it around, and add to it. The script's `show_basic_query_forms` shows the three main ways to do this:"
-   **Keyword Syntax:** "Great for simple, readable queries."
-   **Pipe Syntax:** "Embraces the Elixir ethos. Perfect for composing queries."
-   **Macro Syntax:** "The most explicit form, where you can see the query being built up step-by-step."

**The Pin Operator `^` is Your Security Blanket:**
"When you want to use an Elixir variable inside a query, you **must** use the pin operator `^`. This is not optional. Ecto uses this to distinguish between a column name and an external value. It's what allows Ecto to properly parameterize the final SQL query, which is the primary defense against SQL injection attacks. Emphasize this heavily."

**Composable and Dynamic Queries (Refer to `DynamicQueryExercises`):**
"Real-world applications rarely use static queries. You need to filter, sort, and paginate based on user input. Ecto shines here."
- **Show how you can start with a base query:** `query = from u in User`
- **Then conditionally pipe more clauses:** `if params["active"], do: where(query, [u], u.active == true)`
"This allows you to build clean, readable, and secure dynamic queries without messy string concatenation."

**Shaping Your Results with `select`:**
"You don't always want the entire schema struct back. The `show_select_variations` example is fantastic for this."
- "You can select specific fields into a tuple: `select: {u.id, u.name}`."
- "Or into a map: `select: %{id: u.id, name: u.name}`. This is incredibly useful for APIs."
- "You can even run calculations and aggregations like `count(u.id)`."

**When to Use `fragment`:**
"`fragment` is your escape hatch to use database-specific functions that Ecto doesn't have a helper for. The example `fragment("DATE(?)", p.inserted_at)` is perfect. It lets you call the `DATE` function in PostgreSQL. `fragment` is still safe because the values (represented by `?`) are still properly parameterized."

#### 💬 **Discussion Questions**
1.  **"In the `DynamicQueryExercises`, how does the composable nature of `Ecto.Query` make it safer and cleaner to build a search query than using string concatenation?"**
2.  **"Why is it a performance best practice to use `select` to only fetch the fields you need, especially for API endpoints or list views?"**
    - *Discuss reducing data transfer from DB to app, less memory usage, and faster serialization.*
3.  **"Let's look at `Repo.one` vs. `Repo.one!`. When would you choose one over the other in your application code?"**
    - *Explore `Repo.one!` for when data is expected to exist (e.g., getting the current logged-in user) vs. `Repo.one` for when it might not (e.g., finding a user by a potentially invalid ID).*

---

### 05. Associations and Constraints (60 minutes)

#### 🎯 **Key Concepts**
- **Association Types**: `belongs_to`, `has_one`, `has_many`, `many_to_many`.
- **Working with Associations**: Using `cast_assoc`, `put_assoc`, and `build_assoc` in changesets.
- **Preloading vs. Joining**: Strategies for efficiently loading related data (`Repo.preload` vs. `join`).
- **Database Constraints**: `foreign_key_constraint`, `unique_constraint`, and `check_constraint` for ultimate data integrity.
- **`on_delete` Actions**: Defining what happens to related data when a parent record is deleted.

#### 📝 **Student Summary**
*"Associations define the relationships between your schemas, while database constraints enforce data integrity at the lowest level. Ecto provides powerful tools to work with these relationships in changesets and to load related data efficiently."*

#### 🎤 **Teacher Talking Points**

**The Four Core Relationships (Refer to `DayTwo.AssociationTypes`):**
"These four association types cover almost every data relationship you'll need to model."
-   **`belongs_to`**: "The 'child' points to the 'parent'. A `Comment` `belongs_to` a `Post`. This adds a `post_id` foreign key to the `comments` table."
-   **`has_many`**: "The 'parent' points to its many 'children'. A `Post` `has_many` `Comment`s."
-   **`has_one`**: "Like `has_many`, but for a single record. A `User` `has_one` `Profile`."
-   **`many_to_many`**: "Requires a third 'join table'. A `Post` `many_to_many` `Tag`s, via a `posts_tags` table."

**Managing Associations in Changesets:**
"The `DayTwo.AssociationChangesets` module shows the three key functions for this:"
-   **`cast_assoc`**: "Use this when you want to create, update, or delete nested records along with the parent. For example, creating a `User` and their `Post`s from a single form submission. It's powerful but requires trust in the nested data."
-   **`put_assoc`**: "Use this to replace an entire set of associations with a new set. The `update_user_tags` example is canonical: you're not adding or removing individual tags, you're setting the user's tags to a specific new list."
-   **`build_assoc`**: "This is a convenient way to build a new child record that is already associated with the parent. `build_assoc(user, :posts)` creates a new `%Post{}` with the `user_id` already correctly set."

**Preloading is Ecto's Answer to N+1 Queries:**
"This is a critical performance concept. If you load 10 posts and then loop through them to load each post's author, you'll make 11 database queries (1 for posts, 10 for authors). This is an N+1 query."
-   **The Solution is `Repo.preload`**: `posts = Repo.all(Post) |> Repo.preload(:user)`.
-   "Ecto will run just **two** queries: one to get all the posts, and a second to get all the unique users for those posts (`WHERE id IN (...)`). It then stitches the data together in Elixir. This is vastly more efficient."

**Constraints are Your Final Safety Net:**
"We discussed `unique_constraint` before, but `foreign_key_constraint` is just as important. It prevents you from creating 'orphaned' records. For example, you can't insert a comment with a `post_id` that doesn't actually exist in the `posts` table. The database will reject it, and the constraint in your changeset will turn that database error into a friendly validation message."

#### 💬 **Discussion Questions**
1.  **"When creating a new user and their profile at the same time, would you use `cast_assoc` or `put_assoc`? Why?"**
    - *Lead them to `cast_assoc`, as you're creating new records based on nested attributes.*
2.  **"Let's say you're displaying a list of 50 blog posts on a page, and you need to show the author's name for each. What is the most efficient way to fetch this data?"**
    - *Guide them to `Repo.preload(:user)` as the answer to avoiding the N+1 query problem.*
3.  **"The `on_delete: :delete_all` option is powerful. What are the potential dangers of using it, and when might `on_delete: :nilify_all` be a better choice?"**
    - *Discuss cascading deletes that might wipe out more data than intended. `nilify_all` is great for optional relationships, like if a user is deleted, their posts could become "authored by Anonymous" instead of being deleted too.*

---

### 06. Transactions and Ecto.Multi (60 minutes)

#### 🎯 **Key Concepts**
- **ACID Properties**: Understanding Atomicity, Consistency, Isolation, and Durability.
- **`Repo.transaction`**: The fundamental tool for wrapping operations in a database transaction.
- **`Ecto.Multi`**: A declarative and composable way to build complex, multi-step transactions.
- **Error Handling & Rollbacks**: How Multis automatically roll back on failure and provide detailed error information.
- **Composable & Conditional Logic**: Building dynamic Multis that can adapt to different conditions.

#### 📝 **Student Summary**
*"Transactions guarantee that a series of operations either all succeed or all fail, keeping data consistent. Ecto.Multi provides a beautiful, composable pipeline for building these complex, transactional workflows in a readable and robust way."*

#### 🎤 **Teacher Talking Points**

**Why Do We Need Transactions? (Refer to `TransactionBasics`):**
"Think about transferring money. You need to debit one account and credit another. What happens if the server crashes after the debit but before the credit? You've just lost money! This is the problem transactions solve. By wrapping both operations in a transaction, you guarantee that either both complete successfully, or if anything goes wrong, the whole operation is rolled back, and the database is left untouched. This is **Atomicity**."

**Introducing `Ecto.Multi` - A Better Way:**
"`Repo.transaction(fn -> ... end)` is good, but it can become a messy pyramid of `case` statements. `Ecto.Multi` is a much cleaner, more powerful alternative."
- **It's Declarative**: "Look at the `show_basic_multi_example`. You're not *running* the operations; you're *describing* the sequence of operations you want to happen. You build up a `Multi` struct."
- **It's Composable**: "You can pass the `multi` struct around and have different functions add steps to it before it's finally executed."
- **Dependencies are Explicit**: `Multi.insert(:profile, fn %{user: user} -> ... end)` shows this perfectly. The second step declares that it depends on the result of the `:user` step. `Ecto.Multi` ensures everything runs in the correct order and passes the results along."

**Handling Success and Failure:**
"The `case Repo.transaction(multi) do` statement is the standard pattern."
-   `{:ok, results}`: "On success, you get a map where the keys are the names you provided (`:user`, `:profile`) and the values are the results of those steps."
-   `{:error, operation, changeset, changes_so_far}`: "On failure, the pattern matching is incredibly descriptive. You get back:"
    -   `:operation`: The name of the step that failed.
    -   `:changeset`: The reason for the failure (often an invalid changeset).
    -   `:changes_so_far`: A map of all the steps that succeeded before the failure, which is useful for debugging or compensation logic.

**Beyond Insert/Update/Delete with `Multi.run`:**
"`Multi.run` is the escape hatch for any step that isn't a simple database operation. Common uses include:"
-   Sending an email.
-   Making an API call to a third-party service.
-   Running complex business logic that doesn't fit into a standard Repo function.
"This is how the example `create_user_with_optional_promotion` can conditionally run logic or send different types of emails all within one transactional workflow."

#### 💬 **Discussion Questions**
1.  **"Imagine a user registration process: create a user, create a team for them, and send a welcome email. Why is `Ecto.Multi` a perfect tool for this job?"**
    - *Guide them to discuss atomicity (what if the email fails?), readable steps (`Multi.insert(:user, ...)`), and using `Multi.run` for the email sending part.*
2.  **"Looking at the error tuple `{:error, operation, value, changes_so_far}`, how could you use this detailed information to provide better feedback to a user or a developer?"**
    - *Discuss pattern matching on `:operation` to give a specific error message, logging the `value` (e.g., the invalid changeset) for debugging.*
3.  **"The `process_bulk_order` exercise hints at building a Multi dynamically inside an `Enum.reduce`. Why is this such a powerful pattern?"**
    - *Explore how it allows you to build a single transaction from a list of inputs of any size, like processing items in a shopping cart.*

---

### 07. Behaviour Refresher (45 minutes)

#### 🎯 **Key Concepts**
- **Behaviour Pattern**: Defining contracts for modules to implement
- **GenServer Revisited**: Understanding GenServer as a behaviour implementation
- **Custom Behaviours**: Creating your own behaviour specifications
- **Polymorphism**: Achieving polymorphism through behaviours

#### 📝 **Student Summary**
*"Behaviours define contracts that modules must implement, enabling polymorphism and standardized interfaces. GenServer is just one example of Elixir's powerful behaviour system."*

#### 🎤 **Teacher Talking Points**

**Behaviours as Contracts:**
"Behaviours are like interfaces in other languages, but more powerful. They define what functions a module must implement and can provide default implementations. This creates consistent APIs across different implementations."

**GenServer Behaviour Analysis:**
"Let's revisit GenServer with new understanding. When you write `use GenServer`, you're implementing the GenServer behaviour, which requires specific callbacks like `init/1`, `handle_call/3`, etc. This standardization is what makes supervision trees work."

**Custom Behaviour Benefits:**
"Creating your own behaviours allows you to:"
- "Define plugin architectures"
- "Ensure consistent APIs across modules"
- "Provide compile-time verification of implementations"
- "Enable hot code swapping with confidence"

**Real-World Behaviour Examples:**
```elixir
# Payment processor behaviour
defmodule PaymentProcessor do
  @callback charge(amount :: integer, token :: String.t()) :: 
    {:ok, transaction_id :: String.t()} | {:error, reason :: String.t()}
  
  @callback refund(transaction_id :: String.t()) :: 
    :ok | {:error, reason :: String.t()}
end

# Implementations
defmodule StripeProcessor do
  @behaviour PaymentProcessor
  # Must implement charge/2 and refund/1
end

defmodule PayPalProcessor do
  @behaviour PaymentProcessor  
  # Must implement charge/2 and refund/1
end
```

**Behaviour vs. Protocols:**
- "Behaviours: Compile-time contracts for modules"
- "Protocols: Runtime polymorphism for data types"
- "Use behaviours for service contracts"
- "Use protocols for data transformations"

**Testing Behaviours:**
"Behaviours make testing easier by allowing mock implementations that follow the same contract as production implementations."

#### 💬 **Discussion Questions**
1. **"How do behaviours enable better software architecture?"**
   - *Decoupling, testability, modularity, standardization*
2. **"When would you create a custom behaviour vs. using existing ones?"**
   - *Plugin systems, service abstractions, API standardization*
3. **"How might behaviours help with testing external service integrations?"**
   - *Mock implementations, contract testing, isolation*

---

### 08. Phoenix PubSub (60 minutes)

#### 🎯 **Key Concepts**
- **Publish-Subscribe Pattern**: Decoupled messaging between components
- **Distributed Messaging**: Communication across multiple nodes
- **Topic-Based Routing**: Organizing messages by subject matter
- **Real-Time Architecture**: Building responsive, event-driven applications

#### 📝 **Student Summary**
*"Phoenix PubSub enables real-time communication between processes and nodes through a publish-subscribe messaging system. It's the foundation for building reactive, distributed applications."*

#### 🎤 **Teacher Talking Points**

**PubSub vs. Direct Messaging:**
"Traditional programming often uses direct function calls or method invocations. PubSub inverts this - instead of knowing who to call, you publish events to topics. This decouples publishers from subscribers and enables one-to-many communication."

**Real-Time Web Evolution:**
"The web started as request-response, but modern applications need real-time updates. PubSub enables this by letting your application react to events and push updates to users immediately."

**Phoenix PubSub Architecture:**
"Phoenix PubSub is built on Erlang's distributed capabilities. It can route messages locally within a node or across a cluster of nodes, making it perfect for scalable real-time applications."

**Event-Driven Design Benefits:**
- "Loose coupling between application components"
- "Easy to add new features without modifying existing code"
- "Natural fit for real-time requirements"
- "Scales horizontally across multiple servers"

**Common PubSub Patterns:**
1. **User Notifications**: "Broadcast updates to specific users"
2. **Live Updates**: "Real-time data changes across the application"
3. **Cache Invalidation**: "Notify all nodes when cache should be cleared"
4. **Background Jobs**: "Coordinate work across worker processes"

**Topic Naming Strategies:**
```elixir
# User-specific topics
"user:#{user_id}"                    # Individual user updates
"user:#{user_id}:notifications"      # User's notifications

# Entity-specific topics  
"post:#{post_id}:comments"          # Comments on a specific post
"room:#{room_id}:messages"          # Messages in a chat room

# Global topics
"system:maintenance"                 # System-wide announcements
"analytics:page_views"               # Analytics events
```

**Performance and Reliability:**
"PubSub systems need careful design for performance:"
- "Consider message volume and subscriber count"
- "Plan for network partitions in distributed systems"
- "Design idempotent message handlers"
- "Monitor topic subscription counts"

#### 💬 **Discussion Questions**
1. **"How does PubSub change how you architect real-time applications?"**
   - *Event-driven vs. request-response, decoupling benefits*
2. **"What are the trade-offs between local and distributed PubSub?"**
   - *Performance vs. scalability, consistency vs. availability*
3. **"How might you use PubSub to improve user experience in a web application?"**
   - *Real-time updates, notifications, collaborative features*

---

### 09. Channels (75 minutes)

#### 🎯 **Key Concepts**
- **WebSocket Communication**: Bidirectional real-time communication
- **Channel Architecture**: Managing stateful connections at scale
- **Presence Tracking**: Knowing who's online and where
- **Real-Time Features**: Chat, live updates, collaborative editing

#### 📝 **Student Summary**
*"Phoenix Channels provide WebSocket-based real-time communication between browsers and servers. They handle connection management, presence tracking, and message routing automatically."*

#### 🎤 **Teacher Talking Points**

**WebSocket Revolution:**
"HTTP is request-response - the client asks, the server answers, then the connection closes. WebSockets maintain persistent connections, allowing the server to push data to the client anytime. This enables truly interactive applications."

**Channel vs. Raw WebSockets:**
"You could use raw WebSockets, but Channels provide crucial abstractions:"
- "Connection management and recovery"
- "Message routing and filtering"
- "Presence tracking"
- "Integration with Phoenix authentication"
- "Built-in scaling across multiple servers"

**Channel Lifecycle:**
```elixir
# 1. Client connects to socket
socket = new Socket("/socket")

# 2. Client joins a channel/topic  
channel = socket.channel("room:lobby")
channel.join()

# 3. Bidirectional messaging
channel.push("new_message", {message: "Hello!"})
channel.on("new_message", msg => console.log(msg))

# 4. Server can push anytime
# Phoenix.Endpoint.broadcast("room:lobby", "new_message", payload)
```

**Scaling Challenges and Solutions:**
"Real-time applications face unique scaling challenges:"
- "Connection state management across servers"
- "Message routing in distributed systems"
- "Presence synchronization between nodes"
- "Phoenix solves these with PubSub and distributed Erlang"

**Real-World Channel Applications:**
1. **Live Chat**: "Instant messaging with presence indicators"
2. **Collaborative Editing**: "Multiple users editing documents simultaneously"
3. **Live Dashboards**: "Real-time metrics and monitoring"
4. **Gaming**: "Multiplayer game state synchronization"
5. **Live Comments**: "Real-time discussion on articles or videos"

**Performance Considerations:**
- "Each channel connection consumes server memory"
- "Message frequency affects CPU usage"
- "Consider message batching for high-frequency updates"
- "Use Channel assigns for connection-specific state"

**Security and Authentication:**
"Channels integrate with Phoenix authentication:"
- "Authenticate users at socket connection"
- "Authorize channel joins per topic"
- "Filter messages based on user permissions"
- "Prevent message spoofing and unauthorized access"

#### 💬 **Discussion Questions**
1. **"How do Channels change the user experience compared to traditional web apps?"**
   - *Immediate feedback, real-time collaboration, reduced latency*
2. **"What are the challenges of maintaining WebSocket connections at scale?"**
   - *Memory usage, connection drops, state synchronization*
3. **"How might you design a real-time feature for [specific domain problem]?"**
   - *Apply Channel concepts to real business requirements*

---

### 10. Presence (45 minutes)

#### 🎯 **Key Concepts**
- **Distributed Presence**: Tracking user presence across multiple servers
- **CRDT Technology**: Conflict-free replicated data types for consistency
- **Phoenix.Presence**: Built-in presence tracking with metadata
- **Real-Time Indicators**: Online status, typing indicators, active users

#### 📝 **Student Summary**
*"Phoenix.Presence tracks who's online and where across distributed systems using conflict-free replicated data types. It provides real-time presence indicators without complex coordination."*

#### 🎤 **Teacher Talking Points**

**The Presence Problem:**
"In single-server applications, tracking who's online is simple - keep a list in memory. In distributed systems, this becomes complex: which server knows the truth? What happens when servers disconnect? Phoenix.Presence solves this elegantly."

**CRDT Magic:**
"Conflict-free Replicated Data Types (CRDTs) are mathematical structures that can be updated independently on different servers and still converge to the same state. Phoenix.Presence uses CRDTs to ensure all servers agree on who's present."

**Presence vs. Simple State Tracking:**
"You could track presence manually with PubSub messages, but Presence provides:"
- "Automatic conflict resolution"
- "Network partition tolerance"
- "Metadata attachment (user details, status)"
- "Efficient state synchronization"
- "Built-in integration with Channels"

**Real-World Presence Applications:**
```elixir
# User online status
%{
  "user:123" => %{
    metas: [%{online_at: ~U[2023-12-25 10:30:00Z], 
              status: "active"}]
  }
}

# Typing indicators
%{
  "user:456" => %{
    metas: [%{typing_in: "room:lobby",
              started_typing_at: ~U[2023-12-25 10:31:00Z]}]
  }
}

# Geographic presence
%{
  "user:789" => %{
    metas: [%{location: "San Francisco",
              timezone: "America/Los_Angeles"}]
  }
}
```

**Performance Characteristics:**
"Presence is designed for efficiency:"
- "State is synchronized only when changes occur"
- "Metadata is compressed and batched"
- "Clients receive minimal updates"
- "Scales to thousands of concurrent users"

**Integration Patterns:**
1. **Channel Integration**: "Automatic presence tracking when users join/leave"
2. **Custom Metadata**: "Rich presence information beyond online/offline"
3. **Presence Diffs**: "Efficient updates showing only changes"
4. **Cross-Channel Presence**: "Track users across multiple topics"

#### 💬 **Discussion Questions**
1. **"How does distributed presence tracking improve user experience?"**
   - *Social proof, real-time awareness, collaboration cues*
2. **"What kind of metadata might be useful for presence in different applications?"**
   - *Status messages, locations, activities, device types*
3. **"How might you handle privacy concerns with presence tracking?"**
   - *Opt-in/opt-out, granular visibility, data minimization*

---

### 11. Streams Backend (60 minutes)

#### 🎯 **Key Concepts**
- **Server-Sent Events**: Efficient one-way real-time data streaming
- **LiveView Integration**: Streaming data to Phoenix LiveView
- **Backpressure Handling**: Managing data flow rates
- **Efficient Updates**: Minimal data transfer for real-time applications

#### 📝 **Student Summary**
*"Phoenix Streams enable efficient real-time data streaming from server to client. They're perfect for live feeds, real-time dashboards, and any scenario where data flows primarily one direction."*

#### 🎤 **Teacher Talking Points**

**Streams vs. Channels:**
"While Channels provide bidirectional communication, Streams are optimized for server-to-client data flow. Think of Streams as real-time RSS feeds - the server pushes updates when they happen."

**Server-Sent Events Foundation:**
"Streams are built on Server-Sent Events (SSE), a web standard for real-time server-to-client communication. Unlike WebSockets, SSE connections are simpler and automatically reconnect on failure."

**LiveView Streaming Benefits:**
"Phoenix LiveView uses Streams to efficiently update the UI:"
- "Only changed data is sent, not entire page re-renders"
- "Automatic DOM diffing and patching"
- "Maintains scroll position and form state"
- "Handles network interruptions gracefully"

**Common Streaming Patterns:**
```elixir
# Live activity feed
stream :posts, Post.recent_posts(), at: 0

# Real-time notifications  
stream :notifications, user_notifications, limit: 50

# Live metrics dashboard
stream :metrics, system_metrics(), reset: true

# Chat message history
stream :messages, room_messages, at: -1
```

**Performance Optimization:**
"Streams are designed for efficiency:"
- "Incremental updates instead of full re-renders"
- "Configurable buffer limits to prevent memory leaks"
- "Automatic cleanup of old stream items"
- "Batched updates to reduce network chatter"

**Real-World Applications:**
1. **Social Media Feeds**: "New posts appear automatically"
2. **Live Dashboards**: "Metrics update in real-time"
3. **Chat Applications**: "Messages stream as they arrive"
4. **Live Sports**: "Score updates and play-by-play"
5. **Stock Tickers**: "Real-time price updates"

**Error Handling and Resilience:**
"Streams handle network issues gracefully:"
- "Automatic reconnection on connection loss"
- "Buffering during temporary disconnections"
- "Client-side error recovery"
- "Graceful degradation when streaming fails"

#### 💬 **Discussion Questions**
1. **"When would you choose Streams over Channels for real-time features?"**
   - *Data flow patterns, complexity, performance requirements*
2. **"How do Streams improve the user experience of data-heavy applications?"**
   - *Perceived performance, immediate updates, reduced loading*
3. **"What challenges might arise when streaming large volumes of real-time data?"**
   - *Backpressure, memory usage, client processing capability*

---

### 12. Intro to ExUnit (75 minutes)

#### 🎯 **Key Concepts**
- **Testing Philosophy**: Building confidence through comprehensive testing
- **Test Organization**: Structuring tests for maintainability
- **Assertion Patterns**: Effective use of ExUnit's assertion library
- **Test Lifecycle**: Setup, execution, and teardown patterns

#### 📝 **Student Summary**
*"ExUnit is Elixir's built-in testing framework that emphasizes clear, maintainable tests. It provides excellent tooling for organizing tests, making assertions, and running tests efficiently."*

#### 🎤 **Teacher Talking Points**

**Testing as Documentation:**
"Good tests serve as living documentation of how your code should behave. They describe not just what the code does, but what it's supposed to do under various conditions."

**ExUnit's Design Philosophy:**
"ExUnit prioritizes clarity over brevity. Test names should be descriptive, assertions should be explicit, and test structure should be obvious. This makes tests easier to understand and maintain."

**Test Structure Best Practices:**
```elixir
defmodule UserServiceTest do
  use ExUnit.Case, async: true
  
  describe "create_user/1" do
    test "creates user with valid attributes" do
      # Arrange
      attrs = %{name: "Alice", email: "alice@example.com"}
      
      # Act  
      result = UserService.create_user(attrs)
      
      # Assert
      assert {:ok, user} = result
      assert user.name == "Alice"
      assert user.email == "alice@example.com"
    end
    
    test "returns error with invalid email" do
      attrs = %{name: "Alice", email: "invalid"}
      
      assert {:error, changeset} = UserService.create_user(attrs)
      assert %{email: ["has invalid format"]} = errors_on(changeset)
    end
  end
end
```

**Assertion Strategy:**
"ExUnit provides specific assertions for different scenarios:"
- "`assert` for general truth testing"
- "`assert_raise` for exception testing"
- "`assert_in_delta` for floating-point comparisons"
- "Pattern matching for complex data structure testing"

**Async Testing Benefits:**
"ExUnit can run tests in parallel when marked with `async: true`. This dramatically speeds up test suites, but requires tests to be isolated and not share global state."

**Test Organization Patterns:**
1. **Describe Blocks**: "Group related tests by function or feature"
2. **Context Setup**: "Use setup callbacks for test data preparation"
3. **Test Tags**: "Organize tests by type, speed, or environment"
4. **Shared Examples**: "Reuse test patterns across modules"

**Testing Anti-Patterns:**
- "Testing implementation details instead of behavior"
- "Creating overly complex test setup"
- "Using random data that makes tests non-deterministic"
- "Writing tests that are harder to understand than the code"

#### 💬 **Discussion Questions**
1. **"How do good tests contribute to code quality and maintainability?"**
   - *Regression detection, refactoring confidence, design feedback*
2. **"What makes a test easy to understand and maintain?"**
   - *Clear naming, focused scope, minimal setup, explicit assertions*
3. **"How might you organize tests in a large Phoenix application?"**
   - *Module organization, test types, shared utilities*

---

### 13. Property Testing (60 minutes)

#### 🎯 **Key Concepts**
- **Property-Based Testing**: Testing properties rather than specific examples
- **Generative Testing**: Automatically generating test cases
- **Shrinking**: Finding minimal failing cases
- **Invariant Discovery**: Finding universal truths about your code

#### 📝 **Student Summary**
*"Property-based testing generates hundreds of test cases automatically to find edge cases you wouldn't think of manually. It's especially powerful for testing data transformations and algorithms."*

#### 🎤 **Teacher Talking Points**

**Beyond Example-Based Testing:**
"Traditional testing uses specific examples: 'when input is X, output should be Y.' Property testing asks: 'what should always be true about this function, regardless of input?' This finds bugs that example-based testing misses."

**The Property Testing Workflow:**
1. **Define Properties**: "What should always be true?"
2. **Generate Data**: "Create random inputs within constraints"
3. **Test Properties**: "Verify properties hold for all generated inputs"
4. **Shrink Failures**: "Find the smallest input that reproduces the failure"

**Common Property Patterns:**
```elixir
# Roundtrip properties
property "encoding and decoding are inverse operations" do
  forall data <- term() do
    data |> encode() |> decode() == data
  end
end

# Invariant properties  
property "sorting maintains list length" do
  forall list <- list(integer()) do
    length(Enum.sort(list)) == length(list)
  end
end

# Metamorphic properties
property "reversing twice returns original" do
  forall list <- list(term()) do
    list |> Enum.reverse() |> Enum.reverse() == list
  end
end
```

**When Property Testing Shines:**
- "Data transformation functions"
- "Parsing and serialization code"
- "Mathematical algorithms"
- "Data structure operations"
- "API contract validation"

**Property Testing vs. Unit Testing:**
"Use both approaches complementarily:"
- "Unit tests for specific business logic and edge cases"
- "Property tests for general behavior and invariants"
- "Unit tests are faster and more focused"
- "Property tests find unexpected edge cases"

**Shrinking Magic:**
"When a property test fails, the testing framework automatically tries smaller inputs to find the minimal case that reproduces the failure. This makes debugging much easier."

#### 💬 **Discussion Questions**
1. **"What kinds of properties might you test for a sorting algorithm?"**
   - *Length preservation, ordering, idempotence, permutation*
2. **"How might property testing help with API testing?"**
   - *Input validation, response consistency, error handling*
3. **"What are the limitations of property-based testing?"**
   - *Performance overhead, property design difficulty, random test nature*

---

### 14. Testing Third-Party Services (60 minutes)

#### 🎯 **Key Concepts**
- **Service Isolation**: Testing without external dependencies
- **Mock Strategies**: Different approaches to mocking external services
- **Contract Testing**: Ensuring mock behavior matches reality
- **Test Reliability**: Building stable tests for unstable external services

#### 📝 **Student Summary**
*"Testing code that depends on external services requires isolation strategies. Mocks, stubs, and contract testing help you build reliable tests that don't depend on external service availability."*

#### 🎤 **Teacher Talking Points**

**The External Service Problem:**
"External services create testing challenges: they're slow, unreliable, expensive to call, and might not exist in test environments. We need strategies to test our integration code without actually calling external services."

**Mock vs. Stub vs. Fake:**
- "**Mock**: Verifies that interactions happen correctly"
- "**Stub**: Returns canned responses for testing"
- "**Fake**: Lightweight implementation for testing (in-memory database)"
- "Choose based on what you're testing: behavior vs. state"

**Mox Library Benefits:**
"Mox is designed specifically for Elixir's concurrent nature:"
- "Type-safe mocking through behaviours"
- "Process-isolated mocks for async testing"
- "Explicit setup prevents accidental mock sharing"
- "Integration with ExUnit's lifecycle"

**Testing Strategy Layers:**
```elixir
# 1. Unit tests with mocks
test "payment processing handles success" do
  expect(PaymentMock, :charge, fn _amount, _token ->
    {:ok, "transaction_123"}
  end)
  
  assert {:ok, _order} = OrderService.complete_purchase(order, card)
end

# 2. Integration tests with real service in sandbox
test "payment integration works end-to-end" do
  # Use test API keys, test environment
  assert {:ok, _transaction} = PaymentService.charge(100, test_token())
end

# 3. Contract tests to verify mock accuracy
test "mock behavior matches real service" do
  # Verify mock responses match real API responses
end
```

**HTTP Service Testing Patterns:**
1. **Bypass**: "Create local HTTP servers for testing"
2. **WebMock**: "Intercept HTTP requests and return test responses"
3. **VCR**: "Record real HTTP interactions and replay them"
4. **Service Virtualization**: "Simulate external services completely"

**Error Scenario Testing:**
"External services fail in many ways:"
- "Network timeouts and connection errors"
- "Invalid responses and malformed data"
- "Rate limiting and authentication failures"
- "Partial failures and inconsistent state"

#### 💬 **Discussion Questions**
1. **"How do you balance test isolation with integration confidence?"**
   - *Test pyramid, different test types, feedback loops*
2. **"What strategies help ensure mocks accurately represent real services?"**
   - *Contract testing, shared fixtures, API documentation*
3. **"How might you test error handling for external service failures?"**
   - *Chaos engineering, error injection, timeout simulation*

---

### 15. Introduction to Phoenix Plugs (60 minutes)

#### 🎯 **Key Concepts**
- **Plug Specification**: Understanding the conn-in, conn-out pattern
- **Function vs Module Plugs**: Two approaches to building plugs
- **Pipeline Composition**: Chaining plugs together for request processing
- **Real-World Patterns**: Authentication, logging, CORS, rate limiting

#### 📝 **Student Summary**
*"Plugs are the fundamental building blocks of Phoenix applications. They transform HTTP connections through composable functions, enabling everything from authentication to logging in a standardized way."*

#### 🎤 **Teacher Talking Points**

**Plugs as Web Middleware:**
"Think of plugs as middleware layers in web applications. Every request flows through a series of plugs, each one potentially transforming the connection. This pattern is simple but incredibly powerful - it's how Phoenix handles everything from parsing request bodies to enforcing authentication."

**The Plug Contract:**
"The beauty of plugs is their simplicity. Every plug follows the same contract:"
```elixir
# Function plug
def my_plug(conn, opts) do
  # Transform the connection
  conn
end

# Module plug  
defmodule MyPlug do
  def init(opts), do: opts  # Compile-time setup
  def call(conn, opts) do   # Runtime execution
    # Transform the connection
    conn
  end
end
```

**Why Two Types of Plugs?**
- "**Function Plugs**: Simple, stateless transformations - perfect for logging, headers"
- "**Module Plugs**: Complex logic with compile-time optimization - authentication, rate limiting"
- "**Performance**: Module plugs can pre-process configuration at compile time"
- "**Testing**: Both types are pure functions, making them easy to test"

**Connection Lifecycle:**
"The %Plug.Conn{} struct carries everything about an HTTP request/response:"
- "Request data: method, path, headers, parameters"
- "Response data: status, headers, body"
- "Assigns: Key-value storage for request-scoped data"
- "Halted flag: Stops pipeline processing when needed"

**Pipeline Architecture:**
"Phoenix applications are essentially plug pipelines:"
```
Request → Endpoint Plugs → Router Plugs → Controller Plugs → Action → Response
```
"Each layer can transform the connection, add data, or halt processing. This creates a clean separation of concerns."

**Real-World Plug Categories:**
1. **Infrastructure Plugs**: Request ID, logging, static files, parsing
2. **Security Plugs**: CORS, CSRF, authentication, authorization  
3. **Business Logic Plugs**: Tenant resolution, feature flags, API versioning
4. **Monitoring Plugs**: Metrics collection, performance timing, error tracking

**Common Patterns:**
- "**Early Termination**: Use `halt(conn)` to stop processing (authentication failures)"
- "**Data Loading**: Use `assign(conn, :key, value)` to store request-scoped data"
- "**Header Management**: Security headers, CORS, API versioning"
- "**Request Transformation**: Authentication token → user struct"

**Performance Considerations:**
"Plugs execute for every request, so performance matters:"
- "Keep plug logic lightweight and focused"
- "Use module plugs for expensive setup (compile-time optimization)"
- "Consider caching for expensive operations"
- "Profile plug performance in production scenarios"

**Testing Philosophy:**
"Plugs are pure functions, making them exceptionally testable:"
- "Mock %Plug.Conn{} structs for unit testing"
- "Test both success and failure scenarios"
- "Verify conn transformation and assigns"
- "Integration test entire plug pipelines"

#### 💬 **Discussion Questions**
1. **"How do plugs compare to middleware in other web frameworks you've used?"**
   - *Explore functional vs. object-oriented approaches, composability*
2. **"When would you choose a function plug vs. a module plug?"**
   - *Complexity, reusability, configuration needs, performance*
3. **"How might you structure plugs for a multi-tenant application?"**
   - *Tenant resolution, authorization, data scoping*
4. **"What security concerns should you consider when building authentication plugs?"**
   - *Token handling, session management, timing attacks, error information leakage*
5. **"How could you use plugs to implement feature flags or A/B testing?"**
   - *Request routing, user segmentation, gradual rollouts*

#### 🛠 **Common Implementation Patterns**

**Authentication Pipeline:**
```elixir
# In router.ex
pipeline :authenticated do
  plug MyApp.AuthPlug
  plug MyApp.LoadUserPlug
  plug MyApp.RequireActivePlug
end
```

**API Versioning:**
```elixir
defmodule MyApp.APIVersionPlug do
  def call(conn, _opts) do
    version = 
      get_req_header(conn, "x-api-version") 
      |> List.first() 
      |> Kernel.||("v1")
    
    assign(conn, :api_version, version)
  end
end
```

**Request Timing:**
```elixir
# Start timer plug
def start_timer(conn, _opts) do
  assign(conn, :start_time, System.monotonic_time())
end

# End timer plug  
def end_timer(conn, _opts) do
  duration = System.monotonic_time() - conn.assigns.start_time
  put_resp_header(conn, "x-response-time", "#{duration}ms")
end
```

#### 🎯 **Teaching Tips**
- **Start Simple**: Begin with basic function plugs before introducing module plugs
- **Visual Pipeline**: Draw the request flow through different plug layers
- **Live Coding**: Build plugs incrementally, showing conn transformation at each step
- **Real Examples**: Use authentication, logging, and CORS as concrete use cases
- **Error Handling**: Emphasize the importance of proper error responses and halting

#### ⚠️ **Common Pitfalls**
1. **Forgetting to Return Conn**: Students often forget that plugs must return the connection
2. **Halting Without Response**: Using `halt()` without setting a response leads to confusing errors
3. **Heavy Processing**: Putting expensive operations in plugs that run on every request
4. **State Mutation**: Trying to mutate the connection instead of returning a new one
5. **Error Handling**: Not handling edge cases in authentication or data parsing

---

## 🎯 Teaching Strategies

### Day Two Progression
- **Morning (Ecto Focus)**: Database operations and data modeling
- **Afternoon (Real-Time Focus)**: Phoenix features for real-time web applications
- **Testing Block**: Comprehensive testing strategies and techniques

### Advanced Concepts Integration
- **Connect to Day One**: Show how GenServers power Phoenix features
- **System Thinking**: Emphasize how components work together
- **Production Readiness**: Discuss scalability, monitoring, and deployment

### Hands-On Projects
1. **Blog Application**: Combine Ecto concepts in a practical project
2. **Chat Application**: Build real-time features with Channels and Presence
3. **Testing Workshop**: Apply all testing strategies to existing code

---

## 📊 Assessment Rubric

### Database Proficiency
- [ ] Designs appropriate schemas and migrations
- [ ] Writes efficient queries with proper associations
- [ ] Implements comprehensive validation logic
- [ ] Uses transactions appropriately for data consistency

### Real-Time Features
- [ ] Implements PubSub messaging patterns
- [ ] Builds functional Channel-based features
- [ ] Integrates Presence tracking effectively
- [ ] Uses Streams for efficient data updates

### Testing Excellence  
- [ ] Writes comprehensive unit and integration tests
- [ ] Applies property-based testing appropriately
- [ ] Mocks external services effectively
- [ ] Designs maintainable test suites

### System Design
- [ ] Understands how components integrate
- [ ] Makes appropriate architectural decisions
- [ ] Considers performance and scalability
- [ ] Applies OTP principles effectively

---

## 🚨 Common Challenges

### Database-Related Issues
1. **N+1 Query Problems**: Students forget to preload associations
2. **Migration Conflicts**: Teams working on same schema changes
3. **Complex Query Building**: Dynamic queries become unreadable

### Real-Time Development
1. **WebSocket State Management**: Losing track of connection state
2. **Message Ordering**: Race conditions in message handling
3. **Scaling Concerns**: Not considering multi-node scenarios

### Testing Difficulties
1. **Test Data Management**: Complex setup and teardown
2. **Async Test Issues**: Race conditions in concurrent tests
3. **Mock Complexity**: Over-mocking leading to fragile tests

---

## 📚 Additional Resources

### Advanced Topics
- Phoenix LiveView documentation
- Distributed Elixir patterns
- Performance monitoring with Telemetry
- Production deployment strategies

### Real-World Examples
- Open source Phoenix applications
- Elixir case studies and success stories
- Conference talks on Phoenix architecture
- Community best practices and patterns

Day Two prepares students for building production-ready Elixir applications with robust data layers, real-time features, and comprehensive testing. The progression from database fundamentals through real-time web features to testing excellence creates well-rounded Phoenix developers.