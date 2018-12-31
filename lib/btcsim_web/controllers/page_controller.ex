defmodule BtcsimWeb.PageController do
  use BtcsimWeb, :controller

  def index(conn, _params) do
    render(conn, "index_main.html")
  end
end
