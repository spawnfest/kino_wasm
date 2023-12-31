defmodule WasmRunner.Backend do
  use GenServer

  @callback compile(binary(), binary()) :: {:ok, URI.t()} | {:error, :failed_to_compile, binary()}

  def start_child(opts),
    do: DynamicSupervisor.start_child(__MODULE__.Supervisor, {__MODULE__, opts})

  def run(lang, code, args \\ [1, 2], fun \\ "run")

  def run(:rust, code, args, fun) do
    {:ok, pid} = start_child(%{backend: WasmRunner.Backend.Rust, id: id(code)})
    GenServer.call(pid, {:run, code, args, fun}, :infinity)
  end

  def run(:zig, code, args, fun) do
    {:ok, pid} = start_child(%{backend: WasmRunner.Backend.Zig, id: id(code)})
    GenServer.call(pid, {:run, code, args, fun}, :infinity)
  end

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

  # Callbacks

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def handle_call({:run, code, args, fun}, _, %{backend: backend, id: id} = state) do
    {:ok, %URI{path: path}} = backend.compile(code, id)
    {:ok, bytes} = File.read(path)
    {:ok, pid} = Wasmex.start_link(%{bytes: bytes})
    {_, res} = Wasmex.call_function(pid, fun, args)
    {:reply, res, state}
  end

  defp id(code), do: :crypto.hash(:md5, code) |> Base.encode32()
end
