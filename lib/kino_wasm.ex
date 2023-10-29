defmodule KinoWasm do
  use Application

  def start(_type, _args) do
    Kino.SmartCell.register(KinoWasm.CodeCell)
    Supervisor.start_link([], strategy: :one_for_one)
  end
end
