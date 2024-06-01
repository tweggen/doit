defmodule Auth2024Web.PageLiveTest do
 use Auth2024Web.ConnCase
 import Phoenix.LiveViewTest

 test "disconnected and connected mount", %{conn: conn} do
   {:ok, page_live, disconnected_html} = live(conn, "/")
   assert disconnected_html =~ "Todo"
   assert render(page_live) =~ "What needs to be done"
 end
end