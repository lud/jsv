defmodule JSV.Application do
  alias JSV.Resolver.Cache
  use Application

  def start(_type, _args) do
    children = [
      {Cache, name: Cache}
    ]

    opts = [strategy: :one_for_one, name: YourApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
