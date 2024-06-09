defmodule Auth2024.Todo.Dep do
  use Ecto.Schema
  import Ecto.Changeset
  alias Auth2024.Todo.Item

  schema "todo_deps" do
    field :relation, :integer

    belongs_to :demanding_item, Item, foreign_key: :demanding_id
    belongs_to :required_item, Item, foreign_key: :required_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(dep, attrs) do
    dep
    |> cast(attrs, [:relation])
    |> validate_required([:relation])
  end
end
