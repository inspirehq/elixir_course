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
    """
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

    # This creates:
    # - post_id field in comments table
    # - user_id field in comments table
    # - comment.post and comment.user association accessors
    """
  end

  def show_has_one do
    """
    # has_one: One-to-one from parent to child
    defmodule User do
      use Ecto.Schema

      schema "users" do
        field :email, :string
        has_one :profile, UserProfile

        timestamps()
      end
    end

    # UserProfile table has user_id foreign key
    # Only one profile per user
    # user.profile accessor available
    """
  end

  def show_has_many do
    """
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

    # Post and Comment tables have user_id foreign keys
    # Multiple posts/comments per user
    # user.posts and user.comments accessors available
    """
  end

  def show_many_to_many do
    """
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

    # Requires posts_tags join table with post_id and tag_id
    """
  end
end

IO.puts("belongs_to association:")
IO.puts(DayTwo.AssociationTypes.show_belongs_to())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Working with associations in changesets")

defmodule DayTwo.AssociationChangesets do
  @moduledoc """
  How to handle associations in changesets for data creation and updates.
  """

  def show_cast_assoc do
    """
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
    Repo.insert(changeset)  # Creates user and posts in transaction
    """
  end

  def show_put_assoc do
    """
    # put_assoc for replacing associations
    def update_user_tags(user, tag_names) do
      tags = Enum.map(tag_names, fn name ->
        Repo.get_by(Tag, name: name) || %Tag{name: name}
      end)

      user
      |> change()
      |> put_assoc(:tags, tags)
      |> Repo.update()
    end

    # This replaces ALL user tags with the new set
    """
  end

  def show_build_assoc do
    """
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
    """
  end
end

IO.puts("cast_assoc for nested data:")
IO.puts(DayTwo.AssociationChangesets.show_cast_assoc())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Database constraints for data integrity")

defmodule DayTwo.ConstraintTypes do
  @moduledoc """
  Different types of database constraints and their purposes.
  """

  def show_foreign_key_constraints do
    """
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
    """
  end

  def show_unique_constraints do
    """
    # Unique constraints prevent duplicate values

    # In migration:
    create unique_index(:users, [:email])
    create unique_index(:posts, [:slug])
    create unique_index(:likes, [:user_id, :post_id])  # composite unique

    # In changeset:
    def changeset(user, attrs) do
      user
      |> cast(attrs, [:email, :username])
      |> unique_constraint(:email)
      |> unique_constraint(:username)
    end

    # Custom error messages:
    |> unique_constraint(:email, message: "This email is already registered")
    """
  end

  def show_check_constraints do
    """
    # Check constraints validate data at database level

    # In migration:
    create constraint(:products, :price_must_be_positive, check: "price > 0")
    create constraint(:users, :valid_email_format, check: "email LIKE '%@%'")

    # In changeset:
    def changeset(product, attrs) do
      product
      |> cast(attrs, [:name, :price])
      |> check_constraint(:price, name: :price_must_be_positive)
    end
    """
  end

  def show_exclusion_constraints do
    """
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
    """
  end
end

IO.puts("Foreign key constraints:")
IO.puts(DayTwo.ConstraintTypes.show_foreign_key_constraints())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Advanced association patterns")

defmodule DayTwo.AdvancedAssociations do
  @moduledoc """
  More complex association patterns for real-world scenarios.
  """

  def show_polymorphic_associations do
    """
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
    """
  end

  def show_self_referencing_associations do
    """
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
    """
  end

  def show_through_associations do
    """
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
    """
  end
end

IO.puts("Polymorphic associations:")
IO.puts(DayTwo.AdvancedAssociations.show_polymorphic_associations())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: E-commerce order system")

defmodule DayTwo.EcommerceExample do
  @moduledoc """
  Complete e-commerce example showing associations and constraints.
  """

  def show_ecommerce_schemas do
    """
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
        field :unit_price, :decimal  # Price at time of order

        belongs_to :order, Store.Order
        belongs_to :product, Store.Product

        timestamps()
      end
    end
    """
  end

  def show_ecommerce_constraints do
    """
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
    create unique_index(:order_items, [:order_id, :product_id])  # No duplicate products per order

    # Addresses table:
    create constraint(:addresses, :one_default_per_user,
      exclude: "gist (user_id WITH =) WHERE (is_default = true)"
    )
    """
  end

  def show_order_creation_example do
    """
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
    """
  end
end

IO.puts("E-commerce schema relationships:")
IO.puts(DayTwo.EcommerceExample.show_ecommerce_schemas())

defmodule DayTwo.AssociationExercises do
  @moduledoc """
  Run the tests with: mix test day_two/05_associations_and_constraints.exs
  or in IEx:
  iex -r day_two/05_associations_and_constraints.exs
  DayTwo.AssociationExercisesTest.test_library_system/0
  DayTwo.AssociationExercisesTest.test_social_media_constraints/0
  DayTwo.AssociationExercisesTest.test_course_enrollment/0
  """

  @spec design_library_system() :: [atom()]
  def design_library_system do
    #   Design a library system with `Book`, `Author`, `User`, and `Checkout`
    #   entities. Books can have multiple authors, users can check out multiple
    #   books, but each book can only be checked out by one user at a time.
    #   Return a list of module names for the main entities
    nil  # TODO: Implement this exercise
  end

  @spec design_social_media_constraints() :: [binary()]
  def design_social_media_constraints do
    #   Create a social media schema where users can follow each other and
    #   like posts. Add constraints to prevent users from liking their own
    #   posts and following themselves.
    #   Return a list of constraint definitions as strings
    nil  # TODO: Implement this exercise
  end

  @spec design_course_enrollment_system() :: map()
  def design_course_enrollment_system do
    #   Design a course enrollment system with `Course`, `Student`,
    #   `Instructor`, and `Enrollment` entities. Include prerequisites (courses
    #   that must be completed before enrolling) and capacity limits.
    #   Return a map with keys for the main entities and their constraints
    nil  # TODO: Implement this exercise
  end
end

ExUnit.start()

defmodule DayTwo.AssociationExercisesTest do
  use ExUnit.Case, async: true

  alias DayTwo.AssociationExercises, as: EX

  test "design_library_system/0 returns core entities" do
    entities = EX.design_library_system()
    assert is_list(entities)
    assert length(entities) == 4
    assert :Book in entities
    assert :Author in entities
    assert :User in entities
    assert :Checkout in entities
  end

  test "design_social_media_constraints/0 prevents self-interaction" do
    constraints = EX.design_social_media_constraints()
    assert is_list(constraints)
    assert Enum.any?(constraints, fn c -> String.contains?(c, "cannot_like_own_post") end)
    assert Enum.any?(constraints, fn c -> String.contains?(c, "cannot_follow_self") end)
  end

  test "design_course_enrollment_system/0 includes capacity constraints" do
    system = EX.design_course_enrollment_system()
    assert is_map(system)
    assert Map.has_key?(system, :entities)
    assert Map.has_key?(system, :constraints)
    assert is_list(system.constraints)
  end
end

"""
ANSWERS & EXPLANATIONS

# 1. design_library_system/0
def design_library_system do
  [:Book, :Author, :User, :Checkout]
end
#  Key constraint: unique_index(:checkouts, [:book_id], where: "returned_at IS NULL")
#  ensures only one active checkout per book

# 2. design_social_media_constraints/0
def design_social_media_constraints do
  [
    "create unique_index(:likes, [:user_id, :post_id])",
    "create constraint(:likes, :cannot_like_own_post, exclude: \"gist (user_id WITH =, post_id WITH =) WHERE (user_id = (SELECT user_id FROM posts WHERE id = post_id))\")",
    "create constraint(:follows, :cannot_follow_self, check: \"follower_id != following_id\")"
  ]
end
#  Constraints prevent self-interaction and duplicate likes/follows

# 3. design_course_enrollment_system/0
def design_course_enrollment_system do
  %{
    entities: [:Course, :Student, :Instructor, :Enrollment],
    constraints: [
      "create constraint(:courses, :positive_capacity, check: \"capacity > 0\")",
      "create unique_index(:enrollments, [:student_id, :course_id])",
      "create constraint(:course_prerequisites, :no_self_prerequisite, check: \"course_id != prerequisite_id\")"
    ]
  }
end
#  Includes capacity limits and prevents circular prerequisites
"""
