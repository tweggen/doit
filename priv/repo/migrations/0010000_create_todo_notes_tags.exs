defmodule Auth2024.Repo.Migrations.CreateTodoNotesTags do
  use Ecto.Migration

  def change do
    create table(:todo_tags) do
      add :status, :integer

      add :user_id, references(:users), null: false

      add :tag, :string

      timestamps(type: :utc_datetime)
    end

    create index(:todo_tags, [:tag])

    create table(:todo_notes) do
      add :status, :integer

      add :user_id, references(:users), null: false
      add :person_id, references(:todo_persons), null: false

      add :tag_id, references(:todo_tags), null: false

      add :content, :string

      timestamps(type: :utc_datetime)
    end

    alter table(:todo_notes) do
      modify :content, :text
    end

    create index(:todo_notes, [:user_id, :person_id])

  end
end
