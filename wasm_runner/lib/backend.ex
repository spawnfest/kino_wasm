defmodule WasmRunner.Backend do
  use GenServer

  @callback compile(binary(), binary()) :: {:ok, URI.t()} | {:error, :failed_to_compile, binary()}
  @placeholder """
  #[no_mangle]
  pub extern fn sum(x: i32, y: i32) -> i32 {
      x + y
  }
  """
  def start_child(opts),
    do: DynamicSupervisor.start_child(__MODULE__.Supervisor, {__MODULE__, opts})

  def run(:rust, code \\ @placeholder, fun \\ "sum", args \\ [1, 2]) do
    id = :crypto.hash(:md5, code) |> Base.encode32()
    {:ok, pid} = start_child(%{backend: WasmRunner.Backend.Rust, id: id})

    GenServer.call(pid, {:run, code, fun, args}, :infinity)
  end

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

  # Callbacks

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def handle_call({:run, code, fun, args}, _, %{backend: backend, id: id} = state) do
    {:ok, %URI{path: path}} = backend.compile(code, id)
    {:ok, bytes} = File.read(path)
    {:ok, pid} = Wasmex.start_link(%{bytes: bytes})
    {:ok, res} = Wasmex.call_function(pid, fun, args)
    {:reply, res, state}
  end
end