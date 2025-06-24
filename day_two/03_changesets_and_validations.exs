# Day 2 – Changesets and Validations
#
# Run with `mix run elixir_course/day_two/03_changesets_and_validations.exs`
# or inside IEx with:
#     iex -S mix
#     c "elixir_course/day_two/03_changesets_and_validations.exs"
#
# Changesets are Ecto's way of filtering, casting, and validating data before
# it reaches the database. They provide a clear boundary between raw input
# and clean, validated data.
# ────────────────────────────────────────────────────────────────

IO.puts("\n📌 Example 1 – Basic changeset with cast and validation")

defmodule DayTwo.User do
  @moduledoc """
  Demonstrates basic changeset patterns.
  In a real app, this would use Ecto.Schema and Ecto.Changeset.
  """

  defstruct [:id, :name, :email, :age, :active]

  def changeset(user \\ %__MODULE__{}, attrs) do
    # This simulates what a real changeset would do:
    %{
      data: user,
      params: attrs,
      changes: filter_changes(user, attrs),
      valid?: validate_all(attrs),
      errors: get_errors(attrs)
    }
  end

  defp filter_changes(user, attrs) do
    # Only include allowed fields that have changed
    allowed = [:name, :email, :age, :active]

    Enum.reduce(allowed, %{}, fn field, acc ->
      key = Atom.to_string(field)
      if Map.has_key?(attrs, key) do
        new_value = Map.get(attrs, key)
        current_value = Map.get(user, field)

        if new_value != current_value do
          Map.put(acc, field, new_value)
        else
          acc
        end
      else
        acc
      end
    end)
  end

  defp validate_all(attrs) do
    # All validations must pass
    required_present?(attrs) and
    email_format_valid?(attrs) and
    age_in_range?(attrs)
  end

  defp get_errors(attrs) do
    errors = []

    errors = if required_present?(attrs), do: errors, else: [{:name, "can't be blank"} | errors]
    errors = if email_format_valid?(attrs), do: errors, else: [{:email, "invalid format"} | errors]
    errors = if age_in_range?(attrs), do: errors, else: [{:age, "must be between 1 and 120"} | errors]

    errors
  end

  defp required_present?(attrs) do
    name = Map.get(attrs, "name", "")
    String.length(String.trim(name)) > 0
  end

  defp email_format_valid?(attrs) do
    email = Map.get(attrs, "email", "")
    String.contains?(email, "@") and String.contains?(email, ".")
  end

  defp age_in_range?(attrs) do
    case Map.get(attrs, "age") do
      nil -> true  # age is optional
      age when is_integer(age) -> age >= 1 and age <= 120
      age when is_binary(age) ->
        case Integer.parse(age) do
          {parsed, ""} -> parsed >= 1 and parsed <= 120
          _ -> false
        end
      _ -> false
    end
  end

  def show_real_changeset_example do
    """
    # Real Ecto changeset function:
    def changeset(user, attrs) do
      user
      |> cast(attrs, [:name, :email, :age, :active])
      |> validate_required([:name, :email])
      |> validate_format(:email, ~r/@/)
      |> validate_number(:age, greater_than: 0, less_than: 120)
      |> unique_constraint(:email)
    end
    """
  end
end

# Test the changeset with valid data
valid_attrs = %{"name" => "Alice", "email" => "alice@example.com", "age" => 25}
valid_changeset = DayTwo.User.changeset(%DayTwo.User{}, valid_attrs)

IO.inspect(valid_changeset.valid?, label: "Valid changeset")
IO.inspect(valid_changeset.changes, label: "Changes")
IO.inspect(valid_changeset.errors, label: "Errors")

# Test with invalid data
invalid_attrs = %{"name" => "", "email" => "not-an-email", "age" => 150}
invalid_changeset = DayTwo.User.changeset(%DayTwo.User{}, invalid_attrs)

IO.inspect(invalid_changeset.valid?, label: "Invalid changeset")
IO.inspect(invalid_changeset.errors, label: "Validation errors")

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 2 – Common validation functions")

defmodule DayTwo.ValidationExamples do
  @moduledoc """
  Examples of common Ecto validation patterns.
  """

  def show_validation_functions do
    validations = [
      "validate_required([:name, :email]) - ensures fields are present",
      "validate_format(:email, ~r/@/) - regex pattern matching",
      "validate_length(:title, min: 3, max: 100) - string length constraints",
      "validate_number(:age, greater_than: 0) - numeric range validation",
      "validate_inclusion(:status, [\"active\", \"inactive\"]) - whitelist values",
      "validate_exclusion(:username, [\"admin\", \"root\"]) - blacklist values",
      "validate_acceptance(:terms) - checkbox acceptance (true)",
      "validate_confirmation(:password) - password confirmation matching"
    ]

    IO.puts("Common Ecto validations:")
    Enum.each(validations, fn validation ->
      IO.puts("  • #{validation}")
    end)
  end

  def show_custom_validation_example do
    """
    # Custom validation function:
    defp validate_username_availability(changeset) do
      case get_change(changeset, :username) do
        nil -> changeset
        username ->
          if username_taken?(username) do
            add_error(changeset, :username, "is already taken")
          else
            changeset
          end
      end
    end

    # Usage in changeset:
    def changeset(user, attrs) do
      user
      |> cast(attrs, [:username, :email])
      |> validate_required([:username])
      |> validate_username_availability()
    end
    """
  end
end

DayTwo.ValidationExamples.show_validation_functions()
IO.puts("\nCustom validation pattern:")
IO.puts(DayTwo.ValidationExamples.show_custom_validation_example())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 3 – Constraints vs validations")

defmodule DayTwo.ConstraintsVsValidations do
  @moduledoc """
  Understanding the difference between validations and constraints.
  """

  def explain_difference do
    """
    VALIDATIONS (business logic):
    - Run in Elixir before database interaction
    - Fast feedback for users
    - Can be bypassed if needed
    - Examples: format, length, presence

    CONSTRAINTS (data integrity):
    - Enforced by the database
    - Protect against race conditions
    - Cannot be bypassed
    - Examples: unique_constraint, foreign_key_constraint

    Best practice: Use both together!
    validate_format(:email, ~r/@/) + unique_constraint(:email)
    """
  end

  def show_constraint_example do
    """
    # In migration:
    create unique_index(:users, [:email])

    # In changeset:
    def changeset(user, attrs) do
      user
      |> cast(attrs, [:email])
      |> validate_format(:email, ~r/@/)  # validation
      |> unique_constraint(:email)       # constraint
    end

    # If unique constraint fails:
    case Repo.insert(changeset) do
      {:ok, user} ->
        # success
      {:error, changeset} ->
        # changeset.errors will include constraint violation
        # [email: {"has already been taken", [constraint: :unique]}]
    end
    """
  end
end

IO.puts("Validations vs Constraints:")
IO.puts(DayTwo.ConstraintsVsValidations.explain_difference())
IO.puts("\nConstraint handling example:")
IO.puts(DayTwo.ConstraintsVsValidations.show_constraint_example())

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 4 – Multiple changeset functions for different contexts")

defmodule DayTwo.UserContexts do
  @moduledoc """
  Different changeset functions for different use cases.
  """

  defstruct [:id, :name, :email, :password_hash, :role, :active]

  def registration_changeset(user, attrs) do
    # For user registration - requires password, sets role
    simulated_changeset = %{
      operation: :registration,
      required_fields: [:name, :email, :password],
      validations: ["password minimum 8 chars", "email format", "email unique"],
      transformations: ["hash password", "set role to 'user'", "set active to true"]
    }

    IO.inspect(simulated_changeset, label: "Registration changeset would")
    simulated_changeset
  end

  def update_profile_changeset(user, attrs) do
    # For profile updates - no password required
    simulated_changeset = %{
      operation: :profile_update,
      allowed_fields: [:name, :email],
      validations: ["email format if changed", "email unique if changed"],
      transformations: ["only update changed fields"]
    }

    IO.inspect(simulated_changeset, label: "Profile update changeset would")
    simulated_changeset
  end

  def admin_changeset(user, attrs) do
    # For admin operations - can change role and active status
    simulated_changeset = %{
      operation: :admin_update,
      allowed_fields: [:name, :email, :role, :active],
      validations: ["role in allowed list", "admin cannot deactivate self"],
      transformations: ["audit log all changes"]
    }

    IO.inspect(simulated_changeset, label: "Admin changeset would")
    simulated_changeset
  end

  def show_real_multiple_changesets do
    """
    # Registration changeset
    def registration_changeset(user, attrs) do
      user
      |> cast(attrs, [:name, :email, :password])
      |> validate_required([:name, :email, :password])
      |> validate_length(:password, min: 8)
      |> put_password_hash()
      |> put_change(:role, "user")
      |> put_change(:active, true)
    end

    # Profile update changeset
    def update_changeset(user, attrs) do
      user
      |> cast(attrs, [:name, :email])
      |> validate_required([:name, :email])
      |> unique_constraint(:email)
    end

    # Admin changeset
    def admin_changeset(user, attrs) do
      user
      |> cast(attrs, [:name, :email, :role, :active])
      |> validate_inclusion(:role, ["user", "admin", "moderator"])
      |> validate_admin_not_deactivating_self()
    end
    """
  end
end

user = %DayTwo.UserContexts{}
DayTwo.UserContexts.registration_changeset(user, %{})
DayTwo.UserContexts.update_profile_changeset(user, %{})
DayTwo.UserContexts.admin_changeset(user, %{})

# ────────────────────────────────────────────────────────────────
IO.puts("\n📌 Example 5 – Real-world: Blog post changeset with complex validation")

defmodule DayTwo.BlogPost do
  @moduledoc """
  Complex changeset example with conditional validations and transformations.
  """

  defstruct [:id, :title, :content, :slug, :published_at, :user_id, :tags]

  def changeset(post, attrs) do
    # Simulate a complex changeset pipeline
    steps = [
      "1. Cast allowed fields",
      "2. Validate required fields",
      "3. Generate slug from title",
      "4. Validate slug uniqueness",
      "5. Process tags (split, trim, downcase)",
      "6. Validate content length",
      "7. Set published_at if publishing"
    ]

    IO.puts("Blog post changeset pipeline:")
    Enum.each(steps, &IO.puts("  #{&1}"))

    # Simulated result
    %{
      valid?: true,
      changes: %{
        title: "My Blog Post",
        slug: "my-blog-post",
        content: "This is the content...",
        tags: ["elixir", "programming"]
      }
    }
  end

  def show_real_blog_changeset do
    """
    def changeset(post, attrs) do
      post
      |> cast(attrs, [:title, :content, :tags, :published_at])
      |> validate_required([:title, :content])
      |> validate_length(:title, min: 3, max: 100)
      |> validate_length(:content, min: 10)
      |> generate_slug()
      |> unique_constraint(:slug)
      |> process_tags()
      |> validate_published_at()
    end

    defp generate_slug(changeset) do
      case get_change(changeset, :title) do
        nil -> changeset
        title ->
          slug = title
                 |> String.downcase()
                 |> String.replace(~r/[^a-z0-9]/, "-")
                 |> String.replace(~r/-+/, "-")
                 |> String.trim("-")

          put_change(changeset, :slug, slug)
      end
    end

    defp process_tags(changeset) do
      case get_change(changeset, :tags) do
        nil -> changeset
        tags when is_binary(tags) ->
          processed = tags
                     |> String.split(",")
                     |> Enum.map(&String.trim/1)
                     |> Enum.map(&String.downcase/1)
                     |> Enum.reject(&(&1 == ""))
                     |> Enum.uniq()

          put_change(changeset, :tags, processed)
        _ -> changeset
      end
    end
    """
  end
end

post = %DayTwo.BlogPost{}
DayTwo.BlogPost.changeset(post, %{"title" => "My Blog Post"})

# ────────────────────────────────────────────────────────────────
# 🚀  EXERCISES
#
# 1. Create a `Product` changeset that validates price is positive, name is
#    at least 3 characters, and SKU follows format "ABC-123" (3 letters,
#    dash, 3 numbers). Include a custom validation function.
# 2. Build a `PasswordReset` changeset that validates the token is present,
#    the new password meets complexity requirements (8+ chars, has number
#    and special character), and confirmation matches.
# 3. (Challenge) Design an `Order` changeset that calculates total from
#    line items, validates inventory is available, and applies discount
#    codes. Show how you'd handle the case where validation requires
#    database queries.

"""
🔑 ANSWERS & EXPLANATIONS

# 1. Product changeset with custom SKU validation
def changeset(product, attrs) do
  product
  |> cast(attrs, [:name, :price, :sku])
  |> validate_required([:name, :price, :sku])
  |> validate_length(:name, min: 3)
  |> validate_number(:price, greater_than: 0)
  |> validate_sku_format()
end

defp validate_sku_format(changeset) do
  case get_change(changeset, :sku) do
    nil -> changeset
    sku ->
      if Regex.match?(~r/^[A-Z]{3}-[0-9]{3}$/, sku) do
        changeset
      else
        add_error(changeset, :sku, "must be format ABC-123")
      end
  end
end

# 2. Password reset changeset
def changeset(reset, attrs) do
  reset
  |> cast(attrs, [:token, :password, :password_confirmation])
  |> validate_required([:token, :password, :password_confirmation])
  |> validate_length(:password, min: 8)
  |> validate_password_complexity()
  |> validate_confirmation(:password)
end

defp validate_password_complexity(changeset) do
  case get_change(changeset, :password) do
    nil -> changeset
    password ->
      has_number = Regex.match?(~r/[0-9]/, password)
      has_special = Regex.match?(~r/[!@#$%^&*]/, password)

      if has_number and has_special do
        changeset
      else
        add_error(changeset, :password, "must contain number and special character")
      end
  end
end

# 3. Order changeset with database validation
def changeset(order, attrs) do
  order
  |> cast(attrs, [:user_id, :discount_code])
  |> validate_required([:user_id])
  |> cast_assoc(:line_items, with: &LineItem.changeset/2)
  |> calculate_total()
  |> validate_inventory_available()
  |> apply_discount_code()
end

defp validate_inventory_available(changeset) do
  # This requires a database query, so we use a constraint approach:
  changeset
  |> prepare_changes(fn changeset ->
    line_items = get_field(changeset, :line_items)

    case check_inventory(line_items) do
      :ok -> changeset
      {:error, out_of_stock_items} ->
        Enum.reduce(out_of_stock_items, changeset, fn item, acc ->
          add_error(acc, :line_items, "#{item} is out of stock")
        end)
    end
  end)
end

# Using prepare_changes/2 allows database access during changeset validation
"""
