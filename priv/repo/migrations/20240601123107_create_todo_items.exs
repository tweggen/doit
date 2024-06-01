defmodule Auth2024.Repo.Migrations.CreateTodoItems do
  use Ecto.Migration

  def change do
    create table(:todo_items) do
      add :status, :integer
      add :due, :date
      add :caption, :string
      add :content, :string

      timestamps(type: :utc_datetime)
    end
  end
end
