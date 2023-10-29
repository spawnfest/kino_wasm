defmodule KinoWasm.CodeCell do
  use Kino.JS, assets_path: "lib/assets/code_cell"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Rust Code Cell"

  require Logger

  @impl true
  def init(attrs, ctx) do
    placeholder = """
    #[no_mangle]
    pub extern fn sum(x: i32, y: i32) -> i32 {
        x + y
    }
    """

    IO.inspect(ctx)

    ctx =
      ctx
      |> assign(id: :crypto.strong_rand_bytes(10) |> Base.encode64())
      |> assign(source: attrs["source"] || placeholder)
      |> assign(output: attrs["output"] || "")

    {:ok, ctx, editor: [attribute: "code", language: "elixir"]}
  end

  @impl true
  def to_attrs(ctx) do
    %{
      "id" => ctx.assigns.id,
      "source" => ctx.assigns.source,
      "output" => ctx.assigns.output
    }
  end

  @impl true
  def to_source(attrs) do
    {args, _} = Code.eval_string(attrs["code"])

    quote do
      output = WasmRunner.Backend.run(:rust, unquote(attrs["source"]), unquote(args))
    end
    |> Macro.to_string()
  end

  @impl true
  def scan_eval_result(_, result) do
    result
  end

  @impl true
  def handle_connect(ctx) do
    {:ok,
     %{
       source: ctx.assigns.source,
       id: ctx.assigns.id,
       output: ctx.assigns.output
     }, ctx}
  end

  @impl true
  def handle_event("blur", %{"source" => source}, %{origin: id} = ctx) do
    ctx =
      ctx
      |> assign(loading: true)
      |> assign(source: source)

    send_event(ctx, id, "loading", nil)
    send(self(), {:run, id})

    {:noreply, ctx}
  end

  @impl true
  def handle_info({:run, id}, %{assigns: %{source: source}} = ctx) do
    output = WasmRunner.Backend.run(:rust, source)

    ctx =
      ctx
      |> assign(source: source)
      |> assign(output: output)
      |> assign(loading: false)

    send_event(ctx, id, "output", ctx.assigns)

    {:noreply, ctx}
  end
end
