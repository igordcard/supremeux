# Cheapino layout investigation

Frozen snapshot of a conversation tracing the origin of `vial-kb-layout.vil` and identifying which parts are factory, which came from an intermediate source, and which are Hammerspoon-driven overwrites. Paused here to resume with a deliberate remap of the layer 0 Hammerspoon bindings.

## Artefacts in play

| File | Location | Role |
|---|---|---|
| `vial-kb-layout.vil` | `hammerspoon/cheapino/` | Current working layout driving `init.lua` Hammerspoon bindings |
| `orig.vil` | `hammerspoon/cheapino/originals/` | Factory-default state (matches upstream `default` keymap.json) |
| `carl.vil` | `hammerspoon/cheapino/originals/` | Intermediate state — factory default + layer-0 customisations + home-row mods + gaming layer, with no Hammerspoon overwrites |
| Upstream `keymap.json` | [tompi/qmk_firmware @ cheapinov2](https://github.com/tompi/qmk_firmware/tree/cheapinov2/keyboards/cheapino/keymaps) | Reference for the factory-default keymap baked into `cheapino_vial.uf2` |

Both `orig.vil` and `carl.vil` share the same `uid` (`11439577402410331513`) as the current working `.vil`, confirming they are all snapshots of the same physical Cheapino's firmware.

## Cheapino matrix convention

The Cheapino is a split 3x5+3 (`LAYOUT_split_3x5_3`) — three rows of five alpha columns per side, three thumb keys per side, 36 keys total, one rotary encoder on the left half with a click. Vial exposes it in an 8x12 matrix with the following cell convention:

- **Right half**: rows 0-2, cols 0-5.
  - Alphas: cols 0-4 (col 0 = innermost → col 4 = pinky).
  - Thumbs: col 5 (row 0 = inner, row 1 = middle, row 2 = outer).
- **Left half**: rows 4-6, cols 6-11.
  - Alphas: cols 6-10 (col 6 = innermost → col 10 = pinky).
  - Thumbs: col 11 (row 4 = outer, row 5 = middle, row 6 = inner), mapping to the flat-array positions 30, 31, 32 in `keymap.json` respectively.
- **Encoder click**: row 3 col 0.

## Three-way diff summary

### `orig.vil` vs current `.vil`

Full-scale divergence — 98 cell differences across four populated layers, plus TDs/combo/encoder deltas.

- **Layer 0**: 20 cells.
- **Layer 1**: 28 cells — numbers/arrows design (upstream default) vs a numpad-on-left, shifted-symbols-on-right design (current).
- **Layer 2**: 25 cells — upstream symbols vs F-keys/nav/brackets design (current).
- **Layer 3**: identical (RGB).
- **Layer 4**: 25 cells — empty in `orig.vil`, populated gaming layer (QWER/ASDF/ZXCV + numbers 1-4 + `LALT(F4)` on encoder click) in current.
- **Tap dances**: 6 slots different — TDs 0-5 implement home-row mods (J/F/K/D/L/S with Shift/Ctrl/Alt at 230ms tapping term) in current, all `KC_NO` in `orig.vil`.
- **Encoder layer 4**: `VOLD/VOLU` in current vs `NO/NO` in `orig.vil`.
- **Combo[0]**: `LSHIFT+KC_F16 → KC_NO` (residual no-op) in current vs `KC_NO` everywhere in `orig.vil`.

### `carl.vil` vs current `.vil`

Small, well-bounded divergence concentrated entirely on layer 0.

- **Layer 0**: 16 cells. All the Hammerspoon F-key overwrites on alpha positions and thumbs. TDs on home-row positions are identical in both.
- **Layer 3**: 1 cell — `(4,11)` is `TO(0)` in `carl.vil`, `KC_TRNS` in current.
- **Combo[0]**: same `LSHIFT+F16` residual vs empty.
- **Layers 1, 2, 4, 5-7, 8-13, encoder, TDs, key overrides, settings, macros, UID**: all identical.

### `carl.vil` vs `orig.vil` (factory)

The interesting delta — this is what distinguishes "factory shipped from tompi" from "the state `carl.vil` captures".

Layer 0 deviations from factory:
| Cell | Factory (`orig.vil`) | `carl.vil` |
|---|---|---|
| `(1,3)` (L position) | `KC_L` | `TD(4)` (L tap / Alt hold) |
| `(0,5)` (right inner thumb) | `MO(2)` | `TO(1)` |
| `(2,5)` (right outer thumb) | `KC_RALT` | `KC_BSPACE` |
| `(4,11)` (left outer thumb) | `KC_LGUI` | `MO(1)` |
| `(6,11)` (left inner thumb) | `MO(1)` | `KC_DELETE` |

Also in `carl.vil` vs factory:
- **All six home-row mods** populated via tap dance (`TD(0)..TD(5)` on J/F/K/D/L/S).
- **Layer 1**: completely redesigned — numpad on left hand, shifted symbols on right hand, plus the encoder click.
- **Layer 2**: completely redesigned — F1-F12 spread across left hand, WASD-style nav cluster with brackets on right.
- **Layer 4**: populated gaming layer.
- **Encoder layer 4**: volume ±.

None of these deviations are in the upstream `default`, `via`, `lars`, or `tompi` keymaps in tompi's fork. The source of the `carl.vil` layer 1/2/4 design could not be identified on the web.

## Key findings

1. **`orig.vil` is the factory default**, cell-for-cell matching the `default` keymap from tompi's `cheapinov2` branch. Can be treated as the canonical "fresh Cheapino" reference.
2. **`carl.vil` is an intermediate, pre-Hammerspoon state.** It's the factory default with five thumb/home-row customisations on layer 0, a full home-row-mod set via tap dance, redesigned layers 1 and 2, a gaming layer 4, and a volume encoder on layer 4. Its layers 1-4 and TDs match the current working `.vil` exactly — so those are not Hammerspoon-era changes.
3. **Layer 0 of the current `.vil` is `carl.vil`'s layer 0 plus Hammerspoon F-key overwrites** (mic mute, app focus, Ghostty launchers, GitHub, LGTM, etc.). Every deviation of the current from `carl.vil` is isolated to layer 0 (plus 1 cell on layer 3 and the one residual combo).
4. **Layer-access loss on the current `.vil` is explained.** `carl.vil` relies on `MO(1)` on the left outer thumb and `TO(1)` on the right inner thumb to reach layers. Both got overwritten with `KC_F15` and `KC_F16` respectively in the current `.vil`, leaving no way to leave layer 0.

## Open questions

- The origin of `carl.vil`'s layers 1/2/4 design. Not matched by any upstream keymap; no web source identified. Might be from a personal dotfiles repo or a prior private configuration.
- Whether `carl.vil`'s specific thumb arrangement (`MO(1)` outer / `DELETE` inner on left; `TO(1)` inner / `BSPACE` outer on right) is intentional ergonomics or a mid-flight tweak.

## What's committed in this repo

- `hammerspoon/cheapino/vial-kb-layout.vil` — the current working Vial state.
- `hammerspoon/cheapino/README.md` — description of the file, deviations from upstream default, recovery guidance.
- `hammerspoon/cheapino/DEFAULT_LAYOUT.md` — full factory-default keymap from the tompi fork.
- `hammerspoon/cheapino/LAYOUT_INVESTIGATION.md` — this file.
- `hammerspoon/cheapino/originals/orig.vil` — factory-default snapshot, kept as an anchor reference.
- `hammerspoon/cheapino/originals/carl.vil` — pre-Hammerspoon intermediate snapshot, kept as an anchor reference.

## Next steps (to decide on resume)

1. **Decide the target layout for layer 0.** The current overwrites have accumulated opportunistically. Options:
   - Restore `carl.vil`'s layer 0 as the base and move every Hammerspoon F-key/modifier combo onto thumb/non-alpha positions so typing keys remain intact.
   - Keep the current overwrite-heavy layer 0 and only restore layer access (e.g. `LT(1, KC_F15)` on the left outer thumb, `LT(2, KC_F16)` on the right inner — tap preserves F-key, hold restores layer access).
   - Design a fresh layer 0 purely for Hammerspoon/Ghostty launching, treating the Cheapino as a dedicated macro pad and not a typing keyboard.
2. **Consider clearing the residual combo** (`LSHIFT+F16 → KC_NO` at `combo[0]`) during the next Vial session. It is a no-op, but cosmetically non-default.
3. **Revisit whether the `KC_MNXT` encoder click on layer 0** (vs the `KC_MPLY` carried through other layers) is intentional; both `carl.vil` and `orig.vil` have `KC_MPLY` there, so this is a deliberate current-state change.
4. **Continue the Hammerspoon roadmap** once the layer-0 layout decision is locked in.
