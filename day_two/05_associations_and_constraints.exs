# Day 2 – Associations and Constraints
#
# This script can be run with:
#     mix run day_two/05_associations_and_constraints.exs
# or inside IEx with:
#     iex -r day_two/05_associations_and_constraints.exs
#
# Associations define relationships between schemas, while constraints ensure
# data integrity at the database level. Together they create robust,
# well-structured data models.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Basic association types")

defmodule DayTwo.AssociationTypes do
  @moduledoc """
  Demonstrates the four main types of Ecto associations.
  """

  def show_belongs_to do
    quote do
      # belongs_to: One-to-one from child to parent
      defmodule Comment do
        use Ecto.Schema

        schema "comments" do
          field :content, :string
          belongs_to :post, Post
          belongs_to :user, User

          timestamps()
        end
      end
    end
  end

  def show_has_one do
    quote do
      # has_one: One-to-one from parent to child
      defmodule User do
        use Ecto.Schema

        schema "users" do
          field :email, :string
          has_one :profile, UserProfile

          timestamps()
        end
      end
    end
  end

  def show_has_many do
    quote do
      # has_many: One-to-many from parent to children
      defmodule User do
        use Ecto.Schema

        schema "users" do
          field :email, :string
          has_many :posts, Post
          has_many :comments, Comment

          timestamps()
        end
      end
    end
  end

  def show_many_to_many do
    quote do
      # many_to_many: Many-to-many through join table
      defmodule Post do
        use Ecto.Schema

        schema "posts" do
          field :title, :string
          many_to_many :tags, Tag, join_through: "posts_tags"

          timestamps()
        end
      end

      defmodule Tag do
        use Ecto.Schema

        schema "tags" do
          field :name, :string
          many_to_many :posts, Post, join_through: "posts_tags"

          timestamps()
        end
      end
    end
  end
end

IO.puts("belongs_to association:")
IO.puts(Macro.to_string(DayTwo.AssociationTypes.show_belongs_to()))
IO.puts("\nhas_one association:")
IO.puts(Macro.to_string(DayTwo.AssociationTypes.show_has_one()))
IO.puts("\nhas_many association:")
IO.puts(Macro.to_string(DayTwo.AssociationTypes.show_has_many()))
IO.puts("\nmany_to_many association:")
IO.puts(Macro.to_string(DayTwo.AssociationTypes.show_many_to_many()))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Working with associations in changesets")

defmodule DayTwo.AssociationChangesets do
  @moduledoc """
  How to handle associations in changesets for data creation and updates.
  """

  def show_cast_assoc do
    quote do
      # cast_assoc for nested data creation/updates
      defmodule User do
        def changeset(user, attrs) do
          user
          |> cast(attrs, [:name, :email])
          |> cast_assoc(:posts, with: &Post.changeset/2)
          |> cast_assoc(:profile, with: &Profile.changeset/2)
        end
      end

      # Usage - create user with posts:
      attrs = %{
        "name" => "John",
        "email" => "john@example.com",
        "posts" => [
          %{"title" => "First Post", "content" => "Hello world"},
          %{"title" => "Second Post", "content" => "More content"}
        ]
      }

      changeset = User.changeset(%User{}, attrs)
      Repo.insert(changeset) # Creates user and posts in transaction
    end
  end

  def show_put_assoc do
    quote do
      # put_assoc for replacing associations
      def update_user_tags(user, tag_names) do
        tags =
          Enum.map(tag_names, fn name ->
            Repo.get_by(Tag, name: name) || %Tag{name: name}
          end)

        user
        |> change()
        |> put_assoc(:tags, tags)
        |> Repo.update()
      end
    end
  end

  def show_build_assoc do
    quote do
      # build_assoc for creating related records
      user = Repo.get!(User, 1)

      # Build new post for user
      post_changeset =
        user
        |> build_assoc(:posts)
        |> Post.changeset(%{title: "New Post", content: "Content"})

      Repo.insert(post_changeset)

      # Equivalent to:
      Post.changeset(%Post{user_id: user.id}, attrs)
    end
  end
end

IO.puts("cast_assoc for nested data:")
IO.puts(Macro.to_string(DayTwo.AssociationChangesets.show_cast_assoc()))
IO.puts("\nput_assoc for replacing associations:")
IO.puts(Macro.to_string(DayTwo.AssociationChangesets.show_put_assoc()))
IO.puts("\nbuild_assoc for creating related records:")
IO.puts(Macro.to_string(DayTwo.AssociationChangesets.show_build_assoc()))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Database constraints for data integrity")

defmodule DayTwo.ConstraintTypes do
  @moduledoc """
  Different types of database constraints and their purposes.
  """

  def show_foreign_key_constraints do
    quote do
      # Foreign key constraints ensure referential integrity

      # In migration:
      create table(:posts) do
        add :title, :string
        add :user_id, references(:users, on_delete: :delete_all)
        timestamps()
      end

      # on_delete options:
      # :nothing - default, prevent deletion if referenced
      # :delete_all - delete all associated records
      # :nilify_all - set foreign key to NULL
      # :restrict - same as :nothing but more explicit

      # In changeset:
      def changeset(post, attrs) do
        post
        |> cast(attrs, [:title, :user_id])
        |> foreign_key_constraint(:user_id)
      end
    end
  end

  def show_unique_constraints do
    quote do
      # Unique constraints prevent duplicate values

      # In migration:
      create unique_index(:users, [:email])
      create unique_index(:posts, [:slug])
      create unique_index(:likes, [:user_id, :post_id]) # composite unique

      # In changeset:
      def changeset(user, attrs) do
        user
        |> cast(attrs, [:email, :username])
        |> unique_constraint(:email)
        |> unique_constraint(:username)
      end

      # Custom error messages:
      |> unique_constraint(:email, message: "This email is already registered")
    end
  end

  def show_check_constraints do
    quote do
      # Check constraints validate data at database level

      # In migration:
      create table(:products) do
        add :price, :decimal
        add :quantity, :integer
        timestamps()
      end

      create constraint("products", "price_must_be_positive", check: "price > 0")
      create constraint("products", "quantity_must_be_non_negative", check: "quantity >= 0")

      # In changeset (optional but good practice):
      def changeset(product, attrs) do
        product
        |> cast(attrs, [:price, :quantity])
        |> check_constraint(:price, name: :price_must_be_positive)
        |> check_constraint(:quantity, name: :quantity_must_be_non_negative)
      end
    end
  end

  def show_exclusion_constraints do
    quote do
      # Exclusion constraints prevent overlapping values (PostgreSQL)

      # Example: Prevent overlapping time slots
      create constraint(:bookings, :no_overlapping_bookings,
        exclude: ~s|gist (room_id WITH =, tsrange(start_time, end_time) WITH &&)|
      )

      # In changeset:
      def changeset(booking, attrs) do
        booking
        |> cast(attrs, [:room_id, :start_time, :end_time])
        |> exclusion_constraint(:room_id, name: :no_overlapping_bookings)
      end
    end
  end
end

IO.puts("Foreign key constraints:")
IO.puts(Macro.to_string(DayTwo.ConstraintTypes.show_foreign_key_constraints()))
IO.puts("\nUnique constraints:")
IO.puts(Macro.to_string(DayTwo.ConstraintTypes.show_unique_constraints()))
IO.puts("\nCheck constraints:")
IO.puts(Macro.to_string(DayTwo.ConstraintTypes.show_check_constraints()))
IO.puts("\nExclusion constraints:")
IO.puts(Macro.to_string(DayTwo.ConstraintTypes.show_exclusion_constraints()))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Advanced association patterns")

defmodule DayTwo.AdvancedAssociations do
  @moduledoc """
  More complex association patterns for real-world scenarios.
  """

  def show_polymorphic_associations do
    quote do
      # Polymorphic associations (commentable posts and photos)
      defmodule Comment do
        use Ecto.Schema

        schema "comments" do
          field :content, :string
          field :commentable_id, :integer
          field :commentable_type, :string

          timestamps()
        end
      end

      # Usage with custom functions:
      defmodule Post do
        def comments(post) do
          from c in Comment,
            where: c.commentable_id == ^post.id,
            where: c.commentable_type == "post"
        end
      end
    end
  end

  def show_self_referencing_associations do
    quote do
      # Self-referencing associations (user follows user)
      defmodule User do
        use Ecto.Schema

        schema "users" do
          field :name, :string

          many_to_many :following, User,
            join_through: "user_follows",
            join_keys: [follower_id: :id, following_id: :id]

          many_to_many :followers, User,
            join_through: "user_follows",
            join_keys: [following_id: :id, follower_id: :id]

          timestamps()
        end
      end

      # Migration for join table:
      create table(:user_follows, primary_key: false) do
        add :follower_id, references(:users, on_delete: :delete_all)
        add :following_id, references(:users, on_delete: :delete_all)

        timestamps()
      end

      create unique_index(:user_follows, [:follower_id, :following_id])
    end
  end

  def show_through_associations do
    quote do
      # has_many :through for indirect associations
      defmodule User do
        use Ecto.Schema

        schema "users" do
          has_many :posts, Post
          has_many :comments, Comment

          # Get all comments on user's posts
          has_many :post_comments, through: [:posts, :comments]

          timestamps()
        end
      end

      # Usage:
      user = Repo.get!(User, 1) |> Repo.preload(:post_comments)
      # Returns all comments on any of user's posts
    end
  end
end

IO.puts("Polymorphic associations:")
IO.puts(Macro.to_string(DayTwo.AdvancedAssociations.show_polymorphic_associations()))
IO.puts("\nSelf-referencing associations:")
IO.puts(Macro.to_string(DayTwo.AdvancedAssociations.show_self_referencing_associations()))
IO.puts("\n`has_many :through` associations:")
IO.puts(Macro.to_string(DayTwo.AdvancedAssociations.show_through_associations()))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: E-commerce order system")

defmodule DayTwo.EcommerceExample do
  @moduledoc """
  Complete e-commerce example showing associations and constraints.
  """

  def show_ecommerce_schemas do
    quote do
      # User schema
      defmodule Store.User do
        use Ecto.Schema

        schema "users" do
          field :email, :string
          field :first_name, :string
          field :last_name, :string

          has_many :orders, Store.Order
          has_many :addresses, Store.Address
          has_one :default_address, Store.Address, where: [is_default: true]

          timestamps()
        end
      end

      # Product schema
      defmodule Store.Product do
        use Ecto.Schema

        schema "products" do
          field :name, :string
          field :description, :text
          field :price, :decimal
          field :sku, :string
          field :inventory_count, :integer

          has_many :order_items, Store.OrderItem
          has_many :orders, through: [:order_items, :order]
          belongs_to :category, Store.Category

          timestamps()
        end
      end

      # Order schema
      defmodule Store.Order do
        use Ecto.Schema

        schema "orders" do
          field :total, :decimal
          field :status, :string
          field :shipped_at, :utc_datetime

          belongs_to :user, Store.User
          belongs_to :shipping_address, Store.Address
          has_many :order_items, Store.OrderItem
          has_many :products, through: [:order_items, :product]

          timestamps()
        end
      end

      # OrderItem schema (join table with additional data)
      defmodule Store.OrderItem do
        use Ecto.Schema

        schema "order_items" do
          field :quantity, :integer
          field :unit_price, :decimal # Price at time of order

          belongs_to :order, Store.Order
          belongs_to :product, Store.Product

          timestamps()
        end
      end
    end
  end

  def show_ecommerce_constraints do
    quote do
      # Key constraints for data integrity:

      # Users table:
      create unique_index(:users, [:email])

      # Products table:
      create unique_index(:products, [:sku])
      create constraint(:products, :positive_price, check: "price > 0")
      create constraint(:products, :non_negative_inventory, check: "inventory_count >= 0")

      # Orders table:
      create constraint(:orders, :positive_total, check: "total >= 0")

      # Order items table:
      create constraint(:order_items, :positive_quantity, check: "quantity > 0")
      create constraint(:order_items, :positive_unit_price, check: "unit_price > 0")
      create unique_index(:order_items, [:order_id, :product_id]) # No duplicate products per order

      # Addresses table:
      create constraint(:addresses, :one_default_per_user,
        exclude: "gist (user_id WITH =) WHERE (is_default = true)"
      )
    end
  end

  def show_order_creation_example do
    quote do
      # Creating an order with items using cast_assoc:
      def create_order(user, order_attrs) do
        %Order{user_id: user.id}
        |> Order.changeset(order_attrs)
        |> cast_assoc(:order_items, with: &OrderItem.changeset/2)
        |> validate_inventory_available()
        |> calculate_total()
        |> Repo.insert()
      end

      # Order creation would look like:
      order_attrs = %{
        "shipping_address_id" => 1,
        "order_items" => [
          %{"product_id" => 1, "quantity" => 2},
          %{"product_id" => 3, "quantity" => 1}
        ]
      }
    end
  end
end

IO.puts("E-commerce schema relationships:")
IO.puts(Macro.to_string(DayTwo.EcommerceExample.show_ecommerce_schemas()))
IO.puts("\nE-commerce constraints:")
IO.puts(Macro.to_string(DayTwo.EcommerceExample.show_ecommerce_constraints()))
IO.puts("\nE-commerce order creation:")
IO.puts(Macro.to_string(DayTwo.EcommerceExample.show_order_creation_example()))

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Exercises")

defmodule DayTwo.AssociationExercises do
  @moduledoc """
  Run the test with: mix test day_two/05_associations_and_constraints.exs
  """

  @doc """
  Define the schemas for a basic blog application.

  Inside a `quote` block, define the following modules and their associations:
  1.  `Blog.User`: `schema "users"` with `has_many :posts` and `has_many :comments`.
  2.  `Blog.Post`: `schema "posts"` with `belongs_to :user`, `has_many :comments`,
      and `many_to_many :tags` (join_through: "posts_tags").
  3.  `Blog.Comment`: `schema "comments"` with `belongs_to :user` and `belongs_to :post`.
  4.  `Blog.Tag`: `schema "tags"` with `many_to_many :posts` (join_through: "posts_tags").

  The function should return the `quote` block.
  """
  @spec define_schemas_for_blog() :: Macro.t()
  def define_schemas_for_blog do
    # TODO: Return a quote block with the schema definitions.
    quote do
    end
  end

  @doc """
  Define a changeset function that uses `cast_assoc` for nested data.

  Inside a `quote` block, define a function `create_user_with_posts_changeset(user, attrs)` that:
  - Casts the `user` attributes (`:username`).
  - Validates that `:username` is required.
  - Uses `cast_assoc(:posts)` to handle nested post data.

  The function should return the `quote` block.
  """
  @spec create_user_with_posts_changeset() :: Macro.t()
  def create_user_with_posts_changeset do
    # TODO: Return a quote block with the changeset function definition.
    quote do
    end
  end

  @doc """
  Define common database constraints within a migration.

  Inside a `quote` block, show examples of adding the following constraints:
  1.  A `unique_index` on the `users` table for the `email` column.
  2.  A `references` constraint in the `posts` table for `user_id`, which
      cascades on delete (`on_delete: :delete_all`).
  3.  A composite `unique_index` on a `likes` table for `user_id` and `post_id`.

  The function should return the `quote` block containing these migration snippets.
  """
  @spec add_constraints_to_migration() :: Macro.t()
  def add_constraints_to_migration do
    # TODO: Return a quote block with migration constraint examples.
    quote do
    end
  end
end

ExUnit.start()

defmodule DayTwo.AssociationExercisesTest do
  use ExUnit.Case, async: true

  alias DayTwo.AssociationExercises, as: EX

  defp to_string_unformatted(quote) do
    quote
    |> Macro.to_string()
    |> String.replace(~r/\s+/, " ")
  end

  test "define_schemas_for_blog/0 returns quote block defining blog schemas" do
    result = EX.define_schemas_for_blog()
    str = to_string_unformatted(result)

    assert str =~ "defmodule Blog.User"
    assert str =~ "has_many :posts, Blog.Post"
    assert str =~ "defmodule Blog.Post"
    assert str =~ "belongs_to :user, Blog.User"
    assert str =~ "many_to_many :tags, Blog.Tag"
  end

  test "create_user_with_posts_changeset/0 returns quote block with cast_assoc" do
    result = EX.create_user_with_posts_changeset()
    str = to_string_unformatted(result)

    assert str =~ "def create_user_with_posts_changeset(user, attrs)"
    assert str =~ "cast_assoc(:posts)"
  end

  test "add_constraints_to_migration/0 returns quote block with constraints" do
    result = EX.add_constraints_to_migration()
    str = to_string_unformatted(result)

    assert str =~ "create unique_index(:users, [:email])"
    assert str =~ "references(:users, on_delete: :delete_all)"
    assert str =~ "create unique_index(:likes, [:user_id, :post_id])"
  end
end

defmodule DayTwo.Answers do
  def answer_one do
    quote do
      defmodule Blog.User do
        use Ecto.Schema
        schema "users" do
          field :username, :string
          has_many :posts, Blog.Post
          has_many :comments, Blog.Comment
        end
      end

      defmodule Blog.Post do
        use Ecto.Schema
        schema "posts" do
          field :title, :string
          belongs_to :user, Blog.User
          has_many :comments, Blog.Comment
          many_to_many :tags, Blog.Tag, join_through: "posts_tags"
        end
      end

      defmodule Blog.Comment do
        use Ecto.Schema
        schema "comments" do
          field :body, :string
          belongs_to :user, Blog.User
          belongs_to :post, Blog.Post
        end
      end

      defmodule Blog.Tag do
        use Ecto.Schema
        schema "tags" do
          field :name, :string
          many_to_many :posts, Blog.Post, join_through: "posts_tags"
        end
      end

      def define_schemas_for_blog, do: [Blog.User, Blog.Post, Blog.Comment, Blog.Tag]
    end
  end

  def answer_two do
    quote do
      def create_user_with_posts_changeset(user, attrs) do
        user
        |> Ecto.Changeset.cast(attrs, [:username])
        |> Ecto.Changeset.validate_required([:username])
        |> Ecto.Changeset.cast_assoc(:posts, with: &Blog.Post.changeset/2)
      end
    end
  end

  def answer_three do
    quote do
      def add_constraints_to_migration do
        # This is a fragment of a migration file.
        quote do
          # In create table(:users)
          create unique_index(:users, [:email])

          # In create table(:posts)
          add :user_id, references(:users, on_delete: :delete_all)

          # In create table(:likes)
          add :user_id, references(:users, on_delete: :delete_all), null: false
          add :post_id, references(:posts, on_delete: :delete_all), null: false
          create unique_index(:likes, [:user_id, :post_id])
        end
      end
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. define_schemas_for_blog/0
#{Macro.to_string(DayTwo.Answers.answer_one())}
#  This demonstrates a standard blog schema setup. `belongs_to` adds the foreign
#  key (e.g., `user_id` in `posts`), `has_many` provides the reverse, and
#  `many_to_many` sets up the join table relationship.

# 2. create_user_with_posts_changeset/0
#{Macro.to_string(DayTwo.Answers.answer_two())}
#  `cast_assoc` is the go-to function for managing nested data. It will run the
#  provided changeset function (e.g., `Blog.Post.changeset/2`) for each item in
#  the associated data, allowing you to create, update, and delete associated
#  records all within a single transaction.

# 3. add_constraints_to_migration/0
#{Macro.to_string(DayTwo.Answers.answer_three())}
#  Constraints are vital for data integrity. `unique_index` prevents duplicates
#  at the database level, protecting against race conditions. `references` creates
#  a foreign key, and `on_delete: :delete_all` creates a cascading delete, ensuring
#  that when a user is deleted, all of their posts are also deleted.
""")
