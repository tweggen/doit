defmodule Auth2024.Todo.Config do
  use Ecto.Schema
  import Ecto.Changeset
  alias Auth2024.Todo.Item
  alias Auth2024.Accounts.User


  schema "todo_configs" do
    field :properties, :map

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:properties])
  end

  def changeset(config, attrs) do
    config
    |> cast(attrs, [:properties])
  end

  @doc false
  def update_changeset(config, attrs) do
    config 
    |> cast(attrs, [:properties])
  end

end
  