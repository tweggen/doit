defmodule Auth2024.Repo.Migrations.CreateTodoItems do
  use Ecto.Migration

  def change do
    create table(:todo_items) do
      add :status, :integer
      add :due, :date
      add :caption, :string
      add :content, :string

      add :author_id, references(:todo_persons), null: false
      add :contact_id, references(:todo_persons), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:todo_items, [:due])

  end
end
