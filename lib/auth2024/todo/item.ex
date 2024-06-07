defmodule Auth2024.Todo.Item do
  use Ecto.Schema
  import Ecto.Changeset
  alias Auth2024.Todo.{Person, Dep}
  alias Auth2024.Accounts.{User}

  schema "todo_items" do
    belongs_to :user, User

    field :status, :integer
    field :due, :date
    field :caption, :string
    field :content, :string
    belongs_to :author, Person, foreign_key: :author_id
    belongs_to :contact, Person, foreign_key: :contact_id

    has_many :demanding_from_deps, Dep, foreign_key: :demanding_id
    has_many :required_by_deps, Dep, foreign_key: :required_id

    timestamps(type: :utc_datetime)
  end
  
  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:status, :due, :caption, :content])
    |> validate_required([:user, :status, :caption])
    |> cast_assoc(:author)
    |> cast_assoc(:contact)
  end

  def changeset_caption(item, attrs) do
    item
    |> cast(attrs, [:caption])
    |> validate_required([:caption])
  end

  def changeset_due(item, attrs) do
    item
    |> cast(attrs, [:due])
    |> validate_required([:due])
  end

  def changeset_status(item, attrs) do
    item
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end

  defp validate_caption(changeset) do
    changeset
    |> validate_required([:caption])
    |> validate_length(:caption, max: 160)
  end

  defp validate_content(changeset) do
    changeset
    |> validate_required([:content])
    |> validate_length(:content, max: 2030)
  end

  @doc """
  An item changeset for changing the caption.

  It requires the caption to change otherwise an error is added.
  """
  def caption_changeset(item, attrs) do
    item
    |> cast(attrs, [:caption])
    |> validate_caption()
    |> case do
      %{changes: %{caption: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :caption, "did not change")
    end
  end

  @doc """
  An item changeset for changing the content.

  It requires the content to change otherwise an error is added.
  """
  def content_changeset(item, attrs) do
    item
    |> cast(attrs, [:content])
    |> validate_content()
    |> case do
      %{changes: %{content: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :content, "did not change")
    end
  end
end
