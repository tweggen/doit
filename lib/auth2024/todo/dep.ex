defmodule Auth2024.Todo.Dep do
  use Ecto.Schema
  import Ecto.Changeset
  alias Auth2024.Todo.Item

  schema "todo_deps" do
    field :relation, :integer
    has_one :item_a, Item
    has_one :item_b, Item

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(dep, attrs) do
    dep
    |> cast(attrs, [:relation])
    |> validate_required([:relation])
  end
end
