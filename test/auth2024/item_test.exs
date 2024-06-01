defmodule Auth2024.ItemTest do
  use Auth2024.DataCase
  alias Auth2024.Todo.Item

  describe "items" do
    @valid_attrs %{status: 0, caption: "Todo Test Case", content: "Something is imprtant to do"}
    @update_attrs %{caption: "Updated Test Case", status: 1}
    @invalid_attrs %{caption: nil}

    def item_fixture(attrs \\ %{}) do
      {:ok, item} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Item.create_item()

      item
    end

    test "get_item!/1 returns the item with given id" do
      item = item_fixture(@valid_attrs)
      assert Item.get_item!(item.id) == item
    end

    test "create_item/1 with valid data creates a item" do
      assert {:ok, %Item{} = item} = Item.add_item(@valid_attrs)
      assert item.text == "Todo Test Case"

      inserted_item = List.first(Item.list_items())
      assert inserted_item.text == @valid_attrs.text
    end

    test "create_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Item.add_item(@invalid_attrs)
    end

    test "list_items/0 returns a list of todo items stored in the DB" do
      item1 = item_fixture()
      item2 = item_fixture()
      items = Item.list_items()
      assert Enum.member?(items, item1)
      assert Enum.member?(items, item2)
    end

    test "update_item/2 with valid data updates the item" do
      item = item_fixture()
      assert {:ok, %Item{} = item} = Item.update_item(item, @update_attrs)
      assert item.text == "Updated Test Case"
    end
  end
end