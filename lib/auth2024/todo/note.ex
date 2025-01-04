defmodule Auth2024.Todo.Note do
  use Ecto.Schema
  import Ecto.Changeset
  alias Auth2024.Todo.Person
  alias Auth2024.Accounts.User


  schema "todo_notes" do
    # 0: It is visible
    # 1: it is archived
    # 2: it is deleted
    field :status, :integer

    # What user is owning this note
    belongs_to :user, User

    # Which person is this note about?
    belongs_to :person, Person

    # What is the tag we sort that into
    belongs_to :tag, Tag

    # What do I want to note here?
    field :content, :text

    timestamps(type: :utc_datetime)
  end

  @doc false
  def create_changeset(attrs, user_id) do
    %__MODULE__{}
    |> cast(attrs, [:status, :content])
    |> Ecto.Changeset.change(user_id: user_id)
    |> validate_required([:tag_id, :user_id])
  end

end
  