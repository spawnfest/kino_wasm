defmodule WasmRunnerTest do
  use ExUnit.Case
  doctest WasmRunner

  test "greets the world" do
    assert WasmRunner.hello() == :world
  end
end
