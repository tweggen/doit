defmodule Auth2024.Todo.Item do
  use Ecto.Schema
  import Ecto.Changeset
  alias Auth2024.Todo.{Person, Dep}
  alias Auth2024.Accounts.{User}

  schema "todo_items" do
    belongs_to :user, User

    field :status, :integer
    field :due, :date
    field :caption, :string
    field :content, :string
    belongs_to :author, Person, foreign_key: :author_id
    belongs_to :contact, Person, foreign_key: :contact_id

    has_many :demanding_from_deps, Dep, foreign_key: :demanding_id
    has_many :required_by_deps, Dep, foreign_key: :required_id

    timestamps(type: :utc_datetime)
  end
  

  def get_item_duestate(item) do
    {erl_date, _erl_time} = :calendar.local_time()
    {:ok, date} = Date.from_erl(erl_date)
    if item.status==0 && item.due != nil && date != nil do
      comp = Date.compare(item.due, date)
      if comp == :lt do
        if item.due.day != date.day do
          # This is late, is from yesterday or earlier
          2
        else
          # This is from today, is from yesterday or earlier
          1
        end
      else
        if item.due.day != date.day do
          # if the days do not match, this is older
          0
        else
          # the days are the same, so it is noticable
          1
        end      
      end
    else
      0
    end
  end

  @doc false
  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:status, :due, :caption, :content])
    |> validate_required([:user, :status, :caption])
  end


  @doc false
  def update_changeset(item, attrs) do
    item 
    |> cast(attrs, [:status, :due, :caption, :content])
    |> validate_caption()
    |> validate_content()
  end

  #def changeset_caption_content(item, attrs) do
  #  item
  #  |> cast(attrs, [:caption, :content])
  #  |> validate_caption()
  #  |> validate_content()
  #end    


  #def changeset_caption(item, attrs) do
  #  item
  #  |> cast(attrs, [:caption])
  #  |> validate_caption()
  #end

  def changeset_contact(item, attrs) do
    item
    |> Ecto.Changeset.change(contact_id: attrs.contact.id)
    |> validate_required([:contact_id])
  end

  #def update_due_changeset(item, attrs) do
  #  update_changeset(item, attrs)
  #  |> validate_required([:due])
  #end

  #def changeset_status(item, attrs) do
  #  item
  #  |> cast(attrs, [:status])
  #  |> validate_required([:status])
  #end

  defp validate_caption(changeset) do
    changeset
    |> validate_length(:caption, max: 160)
  end

  defp validate_content(changeset) do
    changeset
    |> validate_length(:content, max: 2030)
  end

end
