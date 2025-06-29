# Day 2 – Changesets and Validations
#
# This script can be run with:
#     mix run day_two/03_changesets_and_validations.exs
# or inside IEx with:
#     iex -r day_two/03_changesets_and_validations.exs
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

  def show_real_changeset_example do
    quote do
      # Real Ecto changeset function:
      def changeset(user, attrs) do
        user
        |> cast(attrs, [:name, :email, :age, :active])
        |> validate_required([:name, :email])
        |> validate_format(:email, ~r/@/)
        |> validate_number(:age, greater_than: 0, less_than: 120)
        |> unique_constraint(:email)
      end
    end
  end

  def run_user_example do
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

    errors =
      if required_present?(attrs), do: errors, else: [{:name, "can't be blank"} | errors]

    errors =
      if email_format_valid?(attrs), do: errors, else: [{:email, "invalid format"} | errors]

    errors =
      if age_in_range?(attrs),
        do: errors,
        else: [{:age, "must be between 1 and 120"} | errors]

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
      nil ->
        true # age is optional
      age when is_integer(age) ->
        age >= 1 and age <= 120
      age when is_binary(age) ->
        case Integer.parse(age) do
          {parsed, ""} -> parsed >= 1 and parsed <= 120
          _ -> false
        end
      _ ->
        false
    end
  end
end

DayTwo.User.run_user_example()
IO.puts(Macro.to_string(DayTwo.User.show_real_changeset_example()))

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
    quote do
      # Custom validation function:
      defp validate_username_availability(changeset) do
        case get_change(changeset, :username) do
          nil ->
            changeset
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
    end
  end
end

DayTwo.ValidationExamples.show_validation_functions()
IO.puts("\nCustom validation pattern:")
IO.puts(Macro.to_string(DayTwo.ValidationExamples.show_custom_validation_example()))

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
    quote do
      # In migration:
      create unique_index(:users, [:email])

      # In changeset:
      def changeset(user, attrs) do
        user
        |> cast(attrs, [:email])
        |> validate_format(:email, ~r/@/) # validation
        |> unique_constraint(:email) # constraint
      end

      # If unique constraint fails:
      case Repo.insert(changeset) do
        {:ok, user} ->
          # success
          :ok
        {:error, changeset} ->
          # changeset.errors will include constraint violation
          # [email: {"has already been taken", [constraint: :unique]}]
          :error
      end
    end
  end
end

IO.puts("Validations vs Constraints:")
IO.puts(DayTwo.ConstraintsVsValidations.explain_difference())
IO.puts("\nConstraint handling example:")
IO.puts(Macro.to_string(DayTwo.ConstraintsVsValidations.show_constraint_example()))

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
    quote do
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
    end
  end

  def run_example do
    user = %__MODULE__{}
    DayTwo.UserContexts.registration_changeset(user, %{})
    DayTwo.UserContexts.update_profile_changeset(user, %{})
    DayTwo.UserContexts.admin_changeset(user, %{})
  end
end

DayTwo.UserContexts.run_example()
IO.puts(Macro.to_string(DayTwo.UserContexts.show_real_multiple_changesets()))

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
    quote do
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
          nil ->
            changeset
          title ->
            slug =
              title
              |> String.downcase()
              |> String.replace(~r/[^a-z0-9]/, "-")
              |> String.replace(~r/-+/, "-")
              |> String.trim("-")

            put_change(changeset, :slug, slug)
        end
      end

      defp process_tags(changeset) do
        case get_change(changeset, :tags) do
          nil ->
            changeset
          tags when is_binary(tags) ->
            processed =
              tags
              |> String.split(",")
              |> Enum.map(&String.trim/1)
              |> Enum.map(&String.downcase/1)
              |> Enum.reject(&(&1 == ""))
              |> Enum.uniq()

            put_change(changeset, :tags, processed)
          _ ->
            changeset
        end
      end
    end
  end

  def run_example do
    post = %__MODULE__{}
    DayTwo.BlogPost.changeset(post, %{"title" => "My Blog Post"})
  end
end

DayTwo.BlogPost.run_example()
IO.puts(Macro.to_string(DayTwo.BlogPost.show_real_blog_changeset()))

defmodule DayTwo.ChangesetExercises do
  @moduledoc """
  Run the tests with: mix test day_two/03_changesets_and_validations.exs
  or in IEx:
  iex -r day_two/03_changesets_and_validations.exs
  DayTwo.ChangesetExercisesTest.test_product_changeset/0
  DayTwo.ChangesetExercisesTest.test_password_reset_changeset/0
  """

  @spec build_product_changeset(map(), map()) :: map()
  def build_product_changeset(_product, _attrs) do
    # Create a changeset-like map for a `Product`.
    #
    # Validations:
    # - `name`: must be at least 3 characters long.
    # - `price`: must be a positive number.
    # - `sku`: must follow the format "ABC-123" (3 uppercase letters, a dash, 3 numbers).
    #
    # Implement the `sku` validation using a private helper function.
    #
    # Return a map with keys: `:valid?`, `:errors`, and `:changes`.
    %{valid?: false, errors: [], changes: %{}}
  end

  @spec build_password_reset_changeset(map(), map()) :: map()
  def build_password_reset_changeset(_reset, _attrs) do
    # Build a changeset-like map for a `PasswordReset`.
    #
    # Validations:
    # - `password`: must be at least 8 characters long.
    # - `password_confirmation`: must match the `password`.
    #
    # Return a map with keys: `:valid?` and `:errors`.
    %{valid?: false, errors: []}
  end

  defp validate_name(errors, attrs) do
    name = Map.get(attrs, "name", "")
    if String.length(name) < 3, do: [{:name, "must be at least 3 characters"} | errors], else: errors
  end

  defp validate_price(errors, attrs) do
    price = Map.get(attrs, "price", 0)
    if price <= 0, do: [{:price, "must be positive"} | errors], else: errors
  end

  defp validate_sku_format(errors, attrs) do
    sku = Map.get(attrs, "sku", "")
    unless Regex.match?(~r/^[A-Z]{3}-\d{3}$/, sku),
      do: [{:sku, "must be format ABC-123"} | errors],
      else: errors
  end
end

ExUnit.start()

defmodule DayTwo.ChangesetExercisesTest do
  use ExUnit.Case, async: true

  alias DayTwo.ChangesetExercises, as: EX

  test "build_product_changeset/2 validates all product fields" do
    product = %{}
    valid_attrs = %{"name" => "Great Product", "price" => 29.99, "sku" => "ABC-123"}
    invalid_attrs = %{"name" => "ab", "price" => -10, "sku" => "invalid"}

    valid_changeset = EX.build_product_changeset(product, valid_attrs)
    assert valid_changeset.valid? == true

    invalid_changeset = EX.build_product_changeset(product, invalid_attrs)
    assert invalid_changeset.valid? == false
    assert length(invalid_changeset.errors) == 3
  end

  test "build_password_reset_changeset/2 validates password length and confirmation" do
    reset = %{}

    valid_attrs = %{
      "password" => "secure_password",
      "password_confirmation" => "secure_password"
    }

    invalid_attrs = %{"password" => "short", "password_confirmation" => "does_not_match"}

    valid_changeset = EX.build_password_reset_changeset(reset, valid_attrs)
    assert valid_changeset.valid? == true
    assert valid_changeset.errors == []

    invalid_changeset = EX.build_password_reset_changeset(reset, invalid_attrs)
    assert invalid_changeset.valid? == false
    assert length(invalid_changeset.errors) == 2
  end
end

defmodule DayTwo.Answers do
  def answer_one do
    quote do
      def build_product_changeset(product, attrs) do
        name = Map.get(attrs, "name", "")
        price = Map.get(attrs, "price", 0)
        sku = Map.get(attrs, "sku", "")

        errors =
          []
          |> validate_name(attrs)
          |> validate_price(attrs)
          |> validate_sku_format(attrs)

        %{
          valid?: Enum.empty?(errors),
          errors: Enum.reverse(errors),
          changes: Map.take(attrs, ["name", "price", "sku"])
        }
      end
    end
  end

  def answer_two do
    quote do
      def build_password_reset_changeset(_reset, attrs) do
        password = Map.get(attrs, "password", "")
        confirmation = Map.get(attrs, "password_confirmation", "")

        errors = []

        errors =
          if String.length(password) < 8,
            do: [{:password, "must be at least 8 characters"} | errors],
            else: errors

        errors =
          if password != confirmation,
            do: [{:password_confirmation, "does not match"} | errors],
            else: errors

        %{valid?: Enum.empty?(errors), errors: Enum.reverse(errors)}
      end
    end
  end
end

IO.puts("""
ANSWERS & EXPLANATIONS

# 1. build_product_changeset/2
#{Macro.to_string(DayTwo.Answers.answer_one())}
#  This implementation shows the validation logic inline. The exercise asks you to
#  refactor the SKU validation into a private helper function (`defp`) inside the
#  `DayTwo.ChangesetExercises` module, which is a common practice for cleaner code.

# 2. build_password_reset_changeset/2
#{Macro.to_string(DayTwo.Answers.answer_two())}
#  This exercise demonstrates two common validation patterns: checking a field's
#  properties (length) and ensuring two fields match (confirmation). This is
#  a core part of handling user input for things like password changes.

""")
