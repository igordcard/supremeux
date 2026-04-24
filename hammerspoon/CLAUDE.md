# Hammerspoon + Cheapino consistency

Any change in this directory must keep these four artifacts in lockstep, within the same commit:

1. `init.lua` — the `hs.hotkey.bind(...)` calls (source of truth for what Hammerspoon reacts to).
2. `cheapino/vial-kb-layout.vil` — which physical Cheapino key emits which combo.
3. `cheapino/LAYOUT.md` — ASCII diagram plus tables describing every mapped key, including the encoder section.
4. `cheapino/README.md` — the short summary that names the F-key ranges currently in use.

## Rules on every commit that touches any of the above

- A new binding in `init.lua` requires a matching cell in the `.vil` and new rows in `LAYOUT.md`. If the new combo extends the F-key range, update `README.md` accordingly.
- A remapped cell in the `.vil` requires the corresponding `hs.hotkey.bind` in `init.lua` and the corresponding table row in `LAYOUT.md` to change with it.
- A removed binding must be deleted from all four files — not left as a comment or placeholder.
- The ASCII physical diagram in `LAYOUT.md` must match the cell contents in `.vil` layer 0, using the same `S+` / `C+` shorthand.
- The encoder section in `LAYOUT.md` must match `encoder_layout[0]` in the `.vil` (rotate + click).

## When in doubt

- Diff `.vil` layer 0 against the `init.lua` bindings. Every non-`KC_NO` cell on layer 0 (excluding the encoder click) should correspond to exactly one `hs.hotkey.bind`, and vice versa.
- The `.vil` should only ever contain Hammerspoon-mapped keys plus the encoder. If a Cheapino-direct key gets added (something that does not go through Hammerspoon, like the encoder), call that out explicitly in `LAYOUT.md`.
