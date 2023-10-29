defmodule WasmRunner.Backend.Zig do
  @behaviour WasmRunner.Backend

  require Logger

  @impl true
  def compile(source, id) do
    with {:ok, res} <- build_wasm(source, id) do
      {:ok, res}
    end
  end

  defp build_wasm(source, id) do
    path = "/tmp/zig/#{id}"

    File.write!("#{path}/main.zig", source)

    case System.cmd(zig(), ["build-lib", "main.zig", "-target", "wasm32-freestanding", "-dynamic", "-rdynamic"],
           cd: path,
           env: env(),
           stderr_to_stdout: true
         ) do
      {_, 0} ->
        {:ok, URI.parse("#{path}/main.wasm")}

      {error, _} ->
        Logger.error(error)
        {:error, :failed_to_compile, error}
    end
  end

  defp env(), do: [{"PATH", path()}]
  defp zig(), do: "/opt/homebrew/Cellar/zig/0.11.0/bin/zig"

  defp path(),
    do:
      "#{File.cwd!()}/.asdf/shims:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/Apple/usr/bin:/opt/homebrew/bin:/opt/homebrew/sbin:#{File.cwd!()}/.cargo/bin"
end
