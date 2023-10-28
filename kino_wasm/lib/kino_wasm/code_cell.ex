defmodule KinoWasm.CodeCell do
  use Kino.JS, assets_path: "assets"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Rust Code Cell"

  require Logger

  alias Kino.AttributeStore

  @impl true
  def init(attrs, ctx) do
    placeholder = """
    #[no_mangle]
    pub extern fn sum(x: i32, y: i32) -> i32 {
        x + y
    }
    """

    ctx =
      ctx
      |> assign(id: :crypto.strong_rand_bytes(10) |> Base.encode64())
      |> assign(source: attrs["source"] || placeholder)
      |> assign(output: attrs["output"] || "")

    {:ok, ctx, reevaluate_on_change: true}
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
    attrs["source"]
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
  def handle_event("blur", %{"source" => source}, ctx) do
    output = WasmRunner.Backend.run(:rust, source)

    ctx =
      ctx
      |> assign(source: source)
      |> assign(output: output)

    AttributeStore.put_attribute(:output, output)
    {:noreply, ctx}
  end

  asset "main.js" do
    """
    import * as monaco from "https://cdn.jsdelivr.net/npm/monaco-editor@0.44.0/+esm"

    export function init(ctx, payload) {
      ctx.root.innerHTML = `
      <div style="height:200px; border-radius: 0.375rem;" id="${payload.id}"/>
      `
      let editor = monaco.editor.create(document.getElementById(payload.id), {
        value: payload.source,
        language: "rust",
       	automaticLayout: true,
        minimap: { enabled: false },
        theme: "vs-dark"
      })

      editor.onDidBlurEditorText(()=>{
         ctx.pushEvent("blur", {source: editor.getValue()})
      });
    }
    """
  end
end
