defmodule KinoWasm.CodeCell do
  use Kino.JS, assets_path: "assets"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Plain code editor"

  @impl true
  def init(attrs, ctx) do
    languages = [
      %{key: "Rust", value: "rust"},
      %{key: "Golang", value: "go"},
      %{key: "JavaScript", value: "javascript"},
      %{key: "TypeScript", value: "typescript"},
      %{key: "Python", value: "python"},
      %{key: "Ruby", value: "ruby"}
    ]

    ctx =
      ctx
      |> assign(id: :crypto.strong_rand_bytes(10) |> Base.encode64())
      |> assign(source: attrs["source"] || "code here")
      |> assign(language: attrs["source"] || hd(languages))
      |> assign(languages: attrs["source"] || languages)

    {:ok, ctx, reevaluate_on_change: true}
  end

  @impl true
  def handle_event("blur", %{"source" => source}, ctx) do
    {:noreply, assign(ctx, source: source)}
  end

  def handle_event("language_change", language, ctx) do
    selected = Enum.find(ctx.assigns.languages, fn %{value: value} -> value == language end)
    {:noreply, assign(ctx, language: selected)}
  end

  @impl true
  def handle_connect(ctx) do
    {:ok,
     %{
       source: ctx.assigns.source,
       id: ctx.assigns.id,
       language: ctx.assigns.language,
       languages: ctx.assigns.languages
     }, ctx}
  end

  @impl true
  def to_attrs(ctx) do
    %{
      "id" => ctx.assigns.id,
      "source" => ctx.assigns.source,
      "language" => ctx.assigns.language,
      "languages" => ctx.assigns.languages
    }
  end

  @impl true
  def to_source(attrs) do
    attrs["source"]
  end

  asset "main.js" do
    """
    import * as monaco from "https://cdn.jsdelivr.net/npm/monaco-editor@0.44.0/+esm"

    export function init(ctx, payload) {
      console.log(payload)
      let options = payload.languages.map((lang) => {
        return `<option value="${lang.value}">${lang.key}</option>`
      }).join("")
      ctx.root.innerHTML = `
      <select id="language" name="language" id="${payload.language.value}">
        ${options}
      </select>

      <div style="height:200px; border-radius: 0.375rem;" id="${payload.id}"/>
      `
      console.log(payload.language.value)
      let editor = monaco.editor.create(document.getElementById(payload.id), {
        value: payload.source,
        language: payload.language.value,
       	automaticLayout: true,
        minimap: {  enabled: false },
        theme: "vs-dark"
      })

      editor.onDidBlurEditorText(()=>{
         ctx.pushEvent("blur", {source: editor.getValue()})
      });
      document.getElementById("language").addEventListener("change", (e) => {
        editor.updateOptions({language: e.target.value})
        ctx.pushEvent("language_change", e.target.value)
      })
    }
    """
  end

  asset "main.css" do
    """
    """
  end
end
