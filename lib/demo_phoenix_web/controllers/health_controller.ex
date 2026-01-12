defmodule DemoPhoenixWeb.HealthController do
  use DemoPhoenixWeb, :controller

  def check(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{
      status: "healthy",
      app: "demo_phoenix",
      type: "phoenix_liveview"
    }))
  end
end
