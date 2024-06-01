defmodule Auth2024.Repo.Migrations.CreateTodoItems do
  use Ecto.Migration

  def change do
    create table(:todo_items) do
      add :caption, :string
      add :content, :string
      add :status, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
