defmodule Auth2024.Todo.Item do
  use Ecto.Schema
  import Ecto.Changeset
  alias Auth2024.Todo.{Person, Dep}

  schema "todo_items" do
    field :status, :integer
    field :due, :date
    field :caption, :string
    field :content, :string
    has_one :author, :Person
    has_many :contact, :Person
    has_many :deps, :Dep

    timestamps(type: :utc_datetime)
  end
  
  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:status, :due, :caption, :content])
    |> validate_required([:status, :due, :caption, :content])
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
