defmodule Auth2024Web.PageLive do
  use Auth2024Web, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end