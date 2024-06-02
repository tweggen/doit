defmodule Auth2024.Todo.Person do
  use Ecto.Schema
  import Ecto.Changeset
  alias Auth2024.Todo.Item
  alias Auth2024.Accounts.User


  schema "todo_persons" do
    field :status, :integer
    field :family_name, :string
    field :given_name, :string

    belongs_to :user, User
    has_many :authored_items, Item, foreign_key: :author_id
    has_many :contacted_items, Item, foreign_key: :contact_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(person, attrs) do
    person
    |> cast(attrs, [:family_name, :given_name, :status])
    |> validate_required([:family_name, :status])
    |> cast_assoc(:user)
  end
end
  