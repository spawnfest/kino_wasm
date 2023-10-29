defmodule KinoWasm do
  use Application

  def start(_type, _args) do
    Kino.SmartCell.register(KinoWasm.RustCodeCell)
    Kino.SmartCell.register(KinoWasm.ZigCodeCell)
    Supervisor.start_link([], strategy: :one_for_one)
  end
end
