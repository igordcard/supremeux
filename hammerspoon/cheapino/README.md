# Cheapino keymap

`vial-kb-layout.vil` is a [Vial](https://github.com/vial-kb/vial-qmk) keyboard layout file for the [Cheapino](https://github.com/igordcard/cheapino) split keyboard, configured to emit the F-key and modifier combos that [`../init.lua`](../init.lua) listens for.

To use it: open Vial, connect the Cheapino, and load this file via **File -> Load current layout**. Vial writes the layout directly to the keyboard's firmware, no QMK recompile needed.

Keep this file in sync with the bindings in `../init.lua`: if you add a new `hs.hotkey.bind(...)` there, remap a Cheapino key to the matching keycode and save the updated `.vil` here.

## Deviations from the factory default

See [`DEFAULT_LAYOUT.md`](DEFAULT_LAYOUT.md) for a full dump of the factory-default Cheapino v2 Vial keymap (taken from the `default` keymap in [tompi/qmk_firmware](https://github.com/tompi/qmk_firmware/tree/cheapinov2/keyboards/cheapino/keymaps/default)).

Notable ways `vial-kb-layout.vil` differs from that default:

- **Home-row mods added on `S`/`D`/`F` and `J`/`K`/`L`** via tap dances: tap = letter, hold = Alt/Ctrl/Shift (230ms tapping term). The factory default has no home-row mods.
- **All six thumb keys have been remapped** to emit the F-key and modifier combos that `../init.lua` listens for. This overwrote the two layer-switch keys that lived on the inner thumbs:
  - Left inner thumb (row 6 col 11) - was `MO(1)`, now emits `F13`.
  - Right inner thumb (row 0 col 5) - was `MO(2)`, now emits `F16`.
- **Layers 1-3 are largely custom** - still organised around numbers (L1), navigation (L2), and RGB (L3), but with thumb keys and a handful of right-hand keys reassigned.
- **A gaming layer (L4)** has been added for games that expect WASD.

### Recovering layer access without losing the F-key bindings

Because the two `MO()` keys were overwritten with plain F-keys, the base layer can no longer reach layers 1, 2, or 3. The cleanest fix is to wrap those two thumb keys in `LT(layer, keycode)` in Vial's "Any" field:

- Left inner thumb: `LT(1, KC_F13)` - tap still sends `F13` for Hammerspoon, hold activates layer 1.
- Right inner thumb: `LT(2, KC_F16)` - tap still sends `F16` for Hammerspoon, hold activates layer 2.

Both behaviours preserved, no Hammerspoon binding lost.

### Restoring the factory default `.vil`

There is no direct keymap.json -> .vil converter - the two formats serve different layers of the stack. The practical options:

1. **Flash `cheapino_vial.uf2` + factory reset in Vial** (Security -> Reset). This wipes all runtime Vial state and leaves you on the firmware's compiled-in default. Saving the layout at that point gives you a canonical default `.vil`. You lose every customisation, so only do this on a spare/test setup.
2. **Rebuild the defaults manually in Vial** using `DEFAULT_LAYOUT.md` as a reference. Slower but non-destructive - you can do it on a second "layer set" file without touching your main `.vil`.

If you just want layer access back, prefer the `LT()` fix above over a full reset.
