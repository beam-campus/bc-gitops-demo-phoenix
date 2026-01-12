defmodule DemoPhoenixWeb.Router do
  use DemoPhoenixWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DemoPhoenixWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DemoPhoenixWeb do
    pipe_through :browser

    live "/", GuestLive, :index
    get "/health", HealthController, :check
  end

  # Other scopes may use custom stacks.
  # scope "/api", DemoPhoenixWeb do
  #   pipe_through :api
  # end
end
