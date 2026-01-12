defmodule DemoPhoenixWeb.PageController do
  use DemoPhoenixWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
