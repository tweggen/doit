defmodule Auth2024.Todo.Person do
  use Ecto.Schema
  import Ecto.Changeset
  alias Auth2024.Todo.Item
  alias Auth2024.Accounts.User


  schema "todo_persons" do
    field :status, :integer
    field :email, :string
    field :family_name, :string
    field :given_name, :string

    belongs_to :owning_user, User
    belongs_to :user, User

    has_many :authored_items, Item, foreign_key: :author_id
    has_many :contacted_items, Item, foreign_key: :contact_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def create_changeset(attrs, owning_user_id) do
    %__MODULE__{}
    |> cast(attrs, [:status, :email, :family_name, :given_name])
    |> Ecto.Changeset.change(owning_user_id: owning_user_id)
    |> validate_required([:family_name, :status, :owning_user_id])
  end


  @doc false
  def update_changeset(item, attrs) do
    res = item |> cast(attrs, [:status, :family_name, :given_name])
    IO.inspect(res)
    res2 = res
    |> validate_family_name()
    |> validate_given_name()
    IO.inspect(res2)
    res2
  end


  @doc false
  def edit_changeset(attrs,  %__MODULE__{} = struct) do
    struct
    |> cast(attrs, [:family_name, :given_name, :status])
    |> validate_required([:family_name, :status])
  end
  

  defp validate_family_name(changeset) do
    changeset
    |> validate_length(:family_name, max: 160)
  end


  defp validate_given_name(changeset) do
    changeset
    |> validate_length(:given_name, max: 160)
  end


end
  