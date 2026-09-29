// Registry of docs series and standalone notes shown on the docs landing page.
// Add a series: create docs/<slug>/series.typ, import it here, and list it in
// series-registry. Add a note: append an entry to note-registry.
// Thumbnails live in assets/content-thumbnails/.

#import "./arch-notes/series.typ": arch-notes-series

#let series-registry = (
  arch-notes-series,
  // my-series,
)

#let note-registry = (
  (
    id: "ai-inference",
    title: "AI Inference",
    summary: "FlashAttention, KV cache, Flash-Decoding, GQA, PagedAttention, and MLA — the attention-side toolbox of modern LLM serving.",
    route: "docs/ai-inference/",
    thumbnail: "ai-inference.svg",
    label: "Note",
  ),
)
