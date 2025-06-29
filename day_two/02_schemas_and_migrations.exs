# Day 2 – Schemas and Migrations
#
# This script can be run with:
#     mix run day_two/02_schemas_and_migrations.exs
# or inside IEx with:
#     iex -r day_two/02_schemas_and_migrations.exs
#
# Schemas define the structure of your data, mapping database tables to Elixir
# structs. Migrations create and modify database tables over time.
# Together they provide a complete data modeling solution.
#
# This file has been refactored to contain "live" code examples using quoted
# expressions. The code inside the `quote` blocks is parsed and validated by
# the Elixir compiler, but is not executed directly.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Basic schema definition")

# In a real app, you'd use `use Ecto.Schema`, but we'll show the structure:
defmodule DayTwo.User do
  @moduledoc """
  Example schema showing common patterns.
  In a real Phoenix app, this would `use Ecto.Schema` and connect to a table.
  """

  # This simulates what `use Ecto.Schema` provides:
  defstruct [:id, :name, :email, :age, :active, :inserted_at, :updated_at]

  @type t :: %__MODULE__{
    id: integer() | nil,
    name: String.t() | nil,
    email: String.t() | nil,
    age: integer() | nil,
    active: boolean(),
    inserted_at: DateTime.t() | nil,
    updated_at: DateTime.t() | nil
  }

  def show_schema_example do
    quote do
      defmodule MyApp.User do
        use Ecto.Schema

        schema "users" do
          field :name, :string
          field :email, :string
          field :age, :integer
          field :active, :boolean, default: true

          timestamps()  # adds inserted_at and updated_at
        end
      end
    end
  end
end

IO.puts("Schema structure:")
IO.puts(Macro.to_string(DayTwo.User.show_schema_example()))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Migration structure and common operations")

defmodule DayTwo.MigrationDemo do
  @moduledoc "Examples of common migration patterns."

  def show_create_table_migration do
    quote do
      defmodule MyApp.Repo.Migrations.CreateUsers do
        use Ecto.Migration

        def change do
          create table(:users) do
            add :name, :string, null: false
            add :email, :string, null: false
            add :age, :integer
            add :active, :boolean, default: true

            timestamps()
          end

          create unique_index(:users, [:email])
        end
      end
    end
  end

  def show_alter_table_migration do
    quote do
      defmodule MyApp.Repo.Migrations.AddPhoneToUsers do
        use Ecto.Migration

        def change do
          alter table(:users) do
            add :phone, :string
            modify :age, :integer, null: false
          end
        end
      end
    end
  end

  def show_rollback_safety do
    quote do
      # Some operations need explicit up/down:
      def up do
        execute "UPDATE users SET active = true WHERE active IS NULL"

        alter table(:users) do
          modify :active, :boolean, null: false
        end
      end

      def down do
        alter table(:users) do
          modify :active, :boolean, null: true
        end
      end
    end
  end
end

IO.puts("Create table migration:")
IO.puts(Macro.to_string(DayTwo.MigrationDemo.show_create_table_migration()))

IO.puts("\nAlter table migration:")
IO.puts(Macro.to_string(DayTwo.MigrationDemo.show_alter_table_migration()))

IO.puts("\nReversible migration with up/down:")
IO.puts(Macro.to_string(DayTwo.MigrationDemo.show_rollback_safety()))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Schema field types and options")

defmodule DayTwo.SchemaTypes do
  def show_common_field_types do
    types = [
      {":string", "VARCHAR in most databases"},
      {":text", "TEXT for longer content"},
      {":integer", "32-bit signed integer"},
      {":float", "Floating point number"},
      {":decimal", "Precise decimal (use for money)"},
      {":boolean", "true/false"},
      {":date", "Date without time"},
      {":time", "Time without date"},
      {":datetime", "Naive datetime (no timezone)"},
      {":utc_datetime", "UTC datetime with timezone"},
      {":binary", "Binary data"},
      {":map", "JSON/JSONB in PostgreSQL"},
      {"{:array, :string}", "Array of strings (PostgreSQL)"}
    ]

    IO.puts("Common Ecto field types:")
    Enum.each(types, fn {type, description} ->
      IO.puts("  #{type} - #{description}")
    end)
  end

  def show_field_options do
    options = [
      {"null: false", "Field cannot be NULL"},
      {"default: value", "Default value if none provided"},
      {"primary_key: true", "Mark as primary key"},
      {"virtual: true", "Not stored in database"},
      {"source: :db_column", "Map to different column name"}
    ]

    IO.puts("\nCommon field options:")
    Enum.each(options, fn {option, description} ->
      IO.puts("  #{option} - #{description}")
    end)
  end
end

DayTwo.SchemaTypes.show_common_field_types()
DayTwo.SchemaTypes.show_field_options()

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Embedded schemas and virtual fields")

defmodule DayTwo.EmbeddedAndVirtual do
  @moduledoc "Examples of embedded schemas and virtual fields."

  def show_embedded_schema do
    quote do
      defmodule MyApp.Address do
        use Ecto.Schema

        embedded_schema do
          field :street, :string
          field :city, :string
          field :state, :string
          field :zip, :string
        end
      end

      # In parent schema:
      schema "users" do
        field :name, :string
        embeds_one :address, MyApp.Address
        embeds_many :phone_numbers, MyApp.PhoneNumber
      end
    end
  end

  def show_virtual_fields do
    quote do
      schema "users" do
        field :first_name, :string
        field :last_name, :string
        field :full_name, :string, virtual: true
      end

      # Virtual fields can be computed:
      def changeset(user, attrs) do
        user
        |> cast(attrs, [:first_name, :last_name])
        |> put_change(:full_name, get_full_name(user, attrs))
      end

      defp get_full_name(user, attrs) do
        first = attrs["first_name"] || user.first_name
        last = attrs["last_name"] || user.last_name
        "#{first} #{last}"
      end
    end
  end
end

IO.puts("\nEmbedded schema example:")
IO.puts(Macro.to_string(DayTwo.EmbeddedAndVirtual.show_embedded_schema()))

IO.puts("\nVirtual fields example:")
IO.puts(Macro.to_string(DayTwo.EmbeddedAndVirtual.show_virtual_fields()))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: Blog schema with proper relationships")

defmodule DayTwo.BlogExample do
  @moduledoc "Real-world example showing a complete blog schema setup."

  def show_blog_schemas do
    quote do
      # User schema
      defmodule Blog.User do
        use Ecto.Schema

        schema "users" do
          field :email, :string
          field :username, :string
          field :password_hash, :string
          field :active, :boolean, default: true

          has_many :posts, Blog.Post
          has_many :comments, Blog.Comment

          timestamps()
        end
      end

      # Post schema
      defmodule Blog.Post do
        use Ecto.Schema

        schema "posts" do
          field :title, :string
          field :content, :text
          field :published_at, :utc_datetime
          field :slug, :string
          field :tags, {:array, :string}, default: []

          belongs_to :user, Blog.User
          has_many :comments, Blog.Comment

          timestamps()
        end
      end

      # Comment schema
      defmodule Blog.Comment do
        use Ecto.Schema

        schema "comments" do
          field :content, :text
          field :approved, :boolean, default: false

          belongs_to :user, Blog.User
          belongs_to :post, Blog.Post

          timestamps()
        end
      end
    end
  end

  def show_blog_migrations do
    quote do
      # Create users migration
      def change do
        create table(:users) do
          add :email, :string, null: false
          add :username, :string, null: false
          add :password_hash, :string, null: false
          add :active, :boolean, default: true

          timestamps()
        end

        create unique_index(:users, [:email])
        create unique_index(:users, [:username])
      end

      # Create posts migration
      def change do
        create table(:posts) do
          add :title, :string, null: false
          add :content, :text, null: false
          add :published_at, :utc_datetime
          add :slug, :string, null: false
          add :tags, {:array, :string}, default: []
          add :user_id, references(:users, on_delete: :delete_all), null: false

          timestamps()
        end

        create unique_index(:posts, [:slug])
        create index(:posts, [:user_id])
        create index(:posts, [:published_at])
      end
    end
  end
end

IO.puts("Complete blog schema example:")
IO.puts(Macro.to_string(DayTwo.BlogExample.show_blog_schemas()))

IO.puts("\nComplete blog migration example:")
IO.puts(Macro.to_string(DayTwo.BlogExample.show_blog_migrations()))

defmodule DayTwo.SchemaExercises do
  @moduledoc """
  Run the tests with: mix test day_two/02_schemas_and_migrations.exs
  or in IEx:
  iex -r day_two/02_schemas_and_migrations.exs
  DayTwo.SchemaExercisesTest.test_product_schema/0
  DayTwo.SchemaExercisesTest.test_alter_product_schema/0
  DayTwo.SchemaExercisesTest.test_social_media_schema/0
  """

  @doc """
  Define an Ecto schema for a `Product`.
  The schema should be in a module named `MyApp.Product`.

  Schema requirements:
  - The table name should be `products`.
  - Use a binary_id for the primary key.
  - `name`: a string
  - `description`: a text field
  - `price`: a decimal with precision 10 and scale 2
  - `sku`: a string
  - `is_available`: a boolean with a default of `true`
  - Include timestamps.

  Also, define a `changeset/2` function for this schema that:
  - Casts the attributes: `name`, `description`, `price`, `sku`, `is_available`.
  - Validates that `name`, `price`, and `sku` are required.
  - Enforces a unique constraint on `sku`.

  This function should define the `MyApp.Product` module and return the module name.
  """
  @spec build_product_schema() :: module()
  def build_product_schema do
    # The function returns the module name, which is a common way to
    # confirm the module was defined in the exercise's scope.
    # Hint: `quote` a `defmodule` block and then return the module atom.
    nil
  end

  @doc """
  Create a migration to create the `products` table.
  The migration should be in a module named `MyApp.Repo.Migrations.CreateProducts`.

  Migration requirements:
  - The table should not have an autogenerated integer primary key.
  - The primary key should be a `:binary_id` named `id`.
  - `name`: string, not null
  - `description`: text
  - `price`: decimal, precision 10, scale 2, not null
  - `sku`: string, not null
  - `is_available`: boolean, default: true
  - Include timestamps.
  - Create a unique index on `sku`.

  This function should define the migration module and return `{:create_table, :products}`.
  """
  @spec create_product_migration() :: {:create_table, atom()}
  def create_product_migration do
    # This function returns a representation of the migration's core action.
    nil
  end

  @doc """
  Design a `User` schema that has an embedded `UserProfile` schema.

  1.  Define an embedded schema in `MyApp.UserProfile` with no primary key.
      It should contain the following fields:
      - `bio`: a string
      - `website`: a string
      - `social_links`: an array of strings

  2.  Define a schema in `MyApp.UserWithProfile` for the `users` table.
      It should contain:
      - `email`: a string
      - `timestamps`
      - An embedded schema for `:profile` using `MyApp.UserProfile`.
        - When replacing the profile, the old one should be deleted.

  This function should define these modules and return `MyApp.UserWithProfile`.
  """
  @spec build_user_with_embedded_profile() :: module()
  def build_user_with_embedded_profile do
    # This function returns the module containing the embedded schema.
    nil
  end
end

ExUnit.start()

defmodule DayTwo.SchemaExercisesTest do
  use ExUnit.Case, async: true

  alias DayTwo.SchemaExercises, as: EX

  defmacrop with_mock_module(module_name, body) do
    quote do
      defmodule unquote(module_name) do
        defmacro __using__(_), do: nil
      end

      unquote(body)
    end
  end

  test "build_product_schema/0 defines and returns the product schema module" do
    module = EX.build_product_schema()
    assert is_atom(module)

    with_mock_module Ecto.Schema do
      assert module.module_info()
      assert function_exported?(module, :__schema__, 1)
      assert function_exported?(module, :changeset, 2)
    end
  end

  test "create_product_migration/0 defines a migration and returns the action" do
    with_mock_module Ecto.Migration do
      assert EX.create_product_migration() == {:create_table, :products}
    end
  end

  test "build_user_with_embedded_profile/0 defines and returns the user schema module" do
    module = EX.build_user_with_embedded_profile()
    assert is_atom(module)

    with_mock_module Ecto.Schema do
      assert module.module_info()
      assert function_exported?(module, :__schema__, 1)
    end
  end
end

defmodule DayTwo.Answers do
  def answer_one do
    quote do
      defmodule MyApp.Product do
        use Ecto.Schema
        import Ecto.Changeset

        @primary_key {:id, :binary_id, autogenerate: true}
        schema "products" do
          field :name, :string
          field :description, :text
          field :price, :decimal, precision: 10, scale: 2
          field :sku, :string
          field :is_available, :boolean, default: true

          timestamps()
        end

        def changeset(product, attrs) do
          product
          |> cast(attrs, [:name, :description, :price, :sku, :is_available])
          |> validate_required([:name, :price, :sku])
          |> unique_constraint(:sku)
        end
      end

      # The function returns the module name, which is a common way to
      # confirm the module was defined in the exercise's scope.
      def build_product_schema, do: MyApp.Product
    end
  end

  def answer_two do
    quote do
      defmodule MyApp.Repo.Migrations.CreateProducts do
        use Ecto.Migration

        def change do
          create table(:products, primary_key: false) do
            add :id, :binary_id, primary_key: true
            add :name, :string, null: false
            add :description, :text
            add :price, :decimal, precision: 10, scale: 2, null: false
            add :sku, :string, null: false
            add :is_available, :boolean, default: true

            timestamps()
          end

          create unique_index(:products, [:sku])
        end
      end

      # This function returns a representation of the migration's core action.
      def create_product_migration, do: {:create_table, :products}
    end
  end

  def answer_three do
    quote do
      defmodule MyApp.UserProfile do
        use Ecto.Schema

        @primary_key false
        embedded_schema do
          field :bio, :string
          field :website, :string
          field :social_links, {:array, :string}
        end
      end

      defmodule MyApp.UserWithProfile do
        use Ecto.Schema

        schema "users" do
          field :email, :string
          embeds_one :profile, MyApp.UserProfile, on_replace: :delete

          timestamps()
        end
      end

      # This function returns the module containing the embedded schema.
      def build_user_with_embedded_profile, do: MyApp.UserWithProfile
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. build_product_schema/0
#{Macro.to_string(DayTwo.Answers.answer_one())}
#  This defines a typical Ecto schema. Note the use of `:decimal` for price to
#  avoid floating-point inaccuracies. A basic changeset is also included,
#  which is a standard best practice for any schema.

# 2. create_product_migration/0
#{Macro.to_string(DayTwo.Answers.answer_two())}
#  The migration creates the `products` table. It includes `null: false` constraints
#  for important fields and a `unique_index` on the SKU to enforce uniqueness at
#  the database level, which is a crucial data integrity measure.

# 3. build_user_with_embedded_profile/0
#{Macro.to_string(DayTwo.Answers.answer_three())}
#  `embedded_schema` is perfect for data that is tightly coupled to its parent
#  and doesn't need to be queried on its own. It's stored in the same database
#  record (often as JSON), which simplifies data retrieval.
""")
