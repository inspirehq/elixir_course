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
    """
    # Real Ecto schema would look like:
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
    """
  end
end

IO.puts("Schema structure:")
IO.puts(DayTwo.User.show_schema_example())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Migration structure and common operations")

defmodule DayTwo.MigrationDemo do
  @moduledoc """
  Examples of common migration patterns.
  """

  def show_create_table_migration do
    """
    # mix ecto.gen.migration create_users
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
    """
  end

  def show_alter_table_migration do
    """
    # mix ecto.gen.migration add_phone_to_users
    defmodule MyApp.Repo.Migrations.AddPhoneToUsers do
      use Ecto.Migration

      def change do
        alter table(:users) do
          add :phone, :string
          modify :age, :integer, null: false
        end
      end
    end
    """
  end

  def show_rollback_safety do
    """
    # Some operations are automatically reversible:
    # - create table -> drop table
    # - add column -> remove column
    # - create index -> drop index

    # Some need explicit up/down:
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
    """
  end
end

IO.puts("Create table migration:")
IO.puts(DayTwo.MigrationDemo.show_create_table_migration())

IO.puts("\nAlter table migration:")
IO.puts(DayTwo.MigrationDemo.show_alter_table_migration())

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

defmodule DayTwo.Address do
  @moduledoc """
  Embedded schema - stored as JSON in parent table.
  """

  defstruct [:street, :city, :state, :zip]

  def show_embedded_schema do
    """
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
      embeds_one :address, Address
      embeds_many :phone_numbers, PhoneNumber
    end
    """
  end
end

defmodule DayTwo.UserWithVirtual do
  defstruct [:id, :first_name, :last_name, :full_name]

  def show_virtual_fields do
    """
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
    """
  end
end

IO.puts("\nEmbedded schema example:")
IO.puts(DayTwo.Address.show_embedded_schema())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: Blog schema with proper relationships")

defmodule DayTwo.BlogExample do
  @moduledoc """
  Real-world example showing a complete blog schema setup.
  """

  def show_blog_schemas do
    """
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
    """
  end

  def show_blog_migrations do
    """
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
    """
  end
end

IO.puts("Complete blog schema example:")
IO.puts(DayTwo.BlogExample.show_blog_schemas())

defmodule DayTwo.SchemaExercises do
  @moduledoc """
  Run the tests with: mix test day_two/02_schemas_and_migrations.exs
  or in IEx:
  iex -r day_two/02_schemas_and_migrations.exs
  DayTwo.SchemaExercisesTest.test_product_schema/0
  DayTwo.SchemaExercisesTest.test_order_system/0
  DayTwo.SchemaExercisesTest.test_social_media_schema/0
  """

  @spec design_product_schema() :: {module(), binary()}
  def design_product_schema do
    #   Design a `Product` schema for an e-commerce site with fields: name,
    #   description, price (as decimal), sku, in_stock (boolean), and category.
    #   Write the corresponding migration.
    #   Return {schema_module, migration_code}
    :not_implemented
  end

  @spec design_order_system() :: [module()]
  def design_order_system do
    #   Create an `Order` schema that belongs to a user and has many `OrderItem`s.
    #   Each OrderItem should reference a Product and have a quantity field.
    #   Show all three schemas and their relationships.
    #   Return [Order, OrderItem, User] modules
    :not_implemented
  end

  @spec design_social_media_schema() :: {module(), binary()}
  def design_social_media_schema do
    #   Design a schema for a social media app with `User`, `Post`,
    #   and `Like` entities. Users can like posts, and a like belongs to both
    #   a user and a post. Ensure you can't like the same post twice.
    #   Return {Like_schema, unique_constraint_migration}
    :not_implemented
  end
end

ExUnit.start()

defmodule DayTwo.SchemaExercisesTest do
  use ExUnit.Case, async: true

  alias DayTwo.SchemaExercises, as: EX

  test "design_product_schema/0 returns schema and migration" do
    {schema_module, migration_code} = EX.design_product_schema()
    assert is_atom(schema_module)
    assert is_binary(migration_code)
    assert String.contains?(migration_code, "create table(:products)")
  end

  test "design_order_system/0 returns related schemas" do
    schemas = EX.design_order_system()
    assert is_list(schemas)
    assert length(schemas) >= 2
    assert Enum.all?(schemas, &is_atom/1)
  end

  test "design_social_media_schema/0 includes unique constraint" do
    {schema_module, migration_code} = EX.design_social_media_schema()
    assert is_atom(schema_module)
    assert is_binary(migration_code)
    assert String.contains?(migration_code, "unique_index")
  end
end

"""
ANSWERS & EXPLANATIONS

# 1. design_product_schema/0
def design_product_schema do
  schema_module = :"Elixir.Store.Product"
  migration_code = \"\"\"
  def change do
    create table(:products) do
      add :name, :string, null: false
      add :description, :text
      add :price, :decimal, precision: 10, scale: 2, null: false
      add :sku, :string, null: false
      add :in_stock, :boolean, default: true
      add :category, :string

      timestamps()
    end

    create unique_index(:products, [:sku])
    create index(:products, [:category])
  end
  \"\"\"
  {schema_module, migration_code}
end
#  Shows proper decimal configuration for money and unique SKU constraint.

# 2. design_order_system/0
def design_order_system do
  [:"Elixir.Store.Order", :"Elixir.Store.OrderItem"]
end
#  Order has_many order_items, OrderItem belongs_to order and product.
#  Captures price at time of order for historical accuracy.

# 3. design_social_media_schema/0
def design_social_media_schema do
  schema_module = :"Elixir.Social.Like"
  migration_code = \"\"\"
  create table(:likes) do
    add :user_id, references(:users, on_delete: :delete_all), null: false
    add :post_id, references(:posts, on_delete: :delete_all), null: false
    timestamps()
  end
  create unique_index(:likes, [:user_id, :post_id])
  \"\"\"
  {schema_module, migration_code}
end
#  Unique constraint prevents duplicate likes from same user on same post.
"""
