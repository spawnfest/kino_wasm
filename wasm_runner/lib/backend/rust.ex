defmodule WasmRunner.Backend.Rust do
  @behaviour WasmRunner.Backend

  require Logger

  @impl true
  def compile(source, id) do
    with :ok <- check_syntax(source, id),
         {:ok, res} <- build_wasm(source, id) do
      {:ok, res}
    end
  end

  def check_syntax(source, id) do
    path = "/tmp/rust/#{id}"

    File.mkdir_p!("#{path}/src")
    File.write!("#{path}/Cargo.toml", cargo())
    File.write!("#{path}/src/lib.rs", source)

    case System.cmd(cargo_bin(), ["build", "-q"], cd: path, env: env(), stderr_to_stdout: true) do
      {_, 0} ->
        :ok

      {error, _} ->
        Logger.error(error)
        {:error, :failed_to_compile, error}
    end
  end

  defp build_wasm(source, id) do
    path = "/tmp/rust/#{id}"

    File.mkdir_p!("#{path}/src")
    File.write!("#{path}/Cargo.toml", cargo())
    File.write!("#{path}/src/lib.rs", source)

    case System.cmd(wasm_pack_bin(), ["build", "--target", "web"],
           cd: path,
           env: env(),
           stderr_to_stdout: true
         ) do
      {_, 0} ->
        {:ok, URI.parse("#{path}/target/wasm32-unknown-unknown/release/wasm.wasm")}

      {error, _} ->
        Logger.error(error)
        {:error, :failed_to_compile, error}
    end
  end

  defp cargo() do
    """
    [package]
    name = "wasm"
    version = "0.1.0"
    authors = ["Your Name <you@example.com>"]
    description = "A sample project with wasm-pack"
    license = "MIT/Apache-2.0"
    repository = "https://github.com/yourgithubusername/hello-wasm"
    edition = "2018"

    [lib]
    crate-type = ["cdylib"]

    [dependencies]
    wasm-bindgen = "0.2"
    """
  end

  defp env(), do: [{"PATH", path()}]
  defp cargo_bin, do: "#{File.cwd!()}/.cargo/bin/cargo"
  defp wasm_pack_bin, do: "#{File.cwd!()}/.cargo/bin/wasm-pack"

  defp path(),
    do:
      "#{File.cwd!()}/.asdf/shims:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/Apple/usr/bin:/opt/homebrew/bin:/opt/homebrew/sbin:#{File.cwd!()}/.cargo/bin"
end
