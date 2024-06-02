defmodule Auth2024.Todo.Person do
  use Ecto.Schema
  import Ecto.Changeset
  alias Auth2024.Todo.Item


  schema "todo_persons" do
    field :status, :integer
    field :family_name, :string
    field :given_name, :string
    has_many :authored_items, Item, foreign_key: :author_id
    has_many :contact_items, Item, foreign_key: :contact_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(person, attrs) do
    person
    |> cast(attrs, [:family_name, :given_name, :status])
    |> validate_required([:family_name, :given_name, :status])
  end
end
