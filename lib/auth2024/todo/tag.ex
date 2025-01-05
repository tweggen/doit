defmodule Auth2024.Todo.Tag do
  use Ecto.Schema
  import Ecto.Changeset
  alias Auth2024.Todo.Person
  alias Auth2024.Accounts.User


  schema "todo_tags" do
    # 0: It is visible
    # 1: it is archived
    # 2: it is deleted
    field :status, :integer

    # What user is owning this tag
    belongs_to :user, User

    field :tag, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def create_changeset(attrs, user_id) do
    %__MODULE__{}
    |> cast(attrs, [:tag])
    |> Ecto.Changeset.change(user_id: user_id)
    |> validate_required([:tag, :user_id])
  end

end
  