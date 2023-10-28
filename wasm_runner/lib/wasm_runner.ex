defmodule WasmRunner do
  use Application

  def start(_type, _args) do
    children = [{DynamicSupervisor, name: WasmRunner.Backend.Supervisor}]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
