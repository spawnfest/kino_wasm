defmodule KinoWasmTest do
  use ExUnit.Case
  doctest KinoWasm

  test "greets the world" do
    assert KinoWasm.hello() == :world
  end
end
