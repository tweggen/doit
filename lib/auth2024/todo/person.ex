defmodule Auth2024.Todo.Person do
  use Ecto.Schema
  import Ecto.Changeset

  schema "todo_persons" do
    field :status, :integer
    field :family_name, :string
    field :given_name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(person, attrs) do
    person
    |> cast(attrs, [:family_name, :given_name, :status])
    |> validate_required([:family_name, :given_name, :status])
  end
end
