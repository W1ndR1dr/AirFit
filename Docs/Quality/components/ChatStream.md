# Chat Stream — Quality Checklist

- Streaming lifecycle
  - Starts within 250 ms of submit on high‑end devices (TTFT measured)
  - No dropped characters; line wrapping correct at all sizes
  - Stop action responsive (< 150 ms)
- Typography
  - Size/weight contrast: message vs status vs hints
  - Comfortable line length (~60–80 chars)
- Animation
  - Delta append: subtle opacity/translate; no bounce on long content
  - Cursor/caret or dot pulse consistent and low‑key
- Accessibility
  - VoiceOver announces streaming updates politely
  - Dynamic type layout remains readable
- Observability
  - AppLogger entries for start/finish with token usage (estimated flagged)

