defmodule Auth2024.Repo.Migrations.ModifyItemContentToText do
  use Ecto.Migration

  def change do
    alter table(:todo_items) do
      modify :content, :text
    end
  end

end

