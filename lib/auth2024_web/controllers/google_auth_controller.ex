defmodule Auth2024Web.GoogleAuthController do
  use Auth2024Web, :controller
  alias Auth2024Web.GoogleAuth

  def request(conn, _params) do
    GoogleAuth.request(conn)
  end

  def callback(conn, _params) do
    GoogleAuth.callback(conn)
  end
end
