import * as monaco from "https://cdn.jsdelivr.net/npm/monaco-editor@0.44.0/+esm";
let editor;
export function init(ctx, payload) {
  ctx.root.innerHTML = baseComponent(payload);
  editor = startMonaco(payload);

  ctx.handleEvent("output", (payload) => {
    console.log("new output");
    console.log(payload);
    ctx.root.innerHTML = baseComponent(payload);
    editor = startMonaco(payload);
    setOnBlurEditorEvent(ctx, editor);
  });

  ctx.handleEvent("loading", () => {
    ctx.root.innerHTML = "Compiling and running...";
  });

  editor.onDidBlurEditorText(() => {
    ctx.pushEvent("blur", { source: editor.getValue() });
  });
}

const setOnBlurEditorEvent = (ctx, editor) => {
  editor.onDidBlurEditorText(() => {
    ctx.pushEvent("blur", { source: editor.getValue() });
  });
};

const baseComponent = (payload) => `
  <div style="height:200px; border-radius: 0.375rem;" id="${payload.id}"/>
  <div>${payload.output}</div>
  `;

const startMonaco = (payload) =>
  monaco.editor.create(document.getElementById(payload.id), {
    value: payload.source,
    language: "rust",
    automaticLayout: true,
    minimap: { enabled: false },
    theme: "vs-dark",
  });
