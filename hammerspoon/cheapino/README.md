# Cheapino keymap

`vial-kb-layout.vil` is a [Vial](https://github.com/vial-kb/vial-qmk) keyboard layout file for the [Cheapino](https://github.com/igordcard/cheapino) split keyboard, flashed so that a handful of its physical keys emit F-key and modifier combos (`F13`-`F20`, `Shift+F16..F19`, `Ctrl+F13..F15`) that [`../init.lua`](../init.lua) listens for.

See [`LAYOUT.md`](LAYOUT.md) for which physical key on the Cheapino emits which combo and what Hammerspoon does with it.

To load: open Vial, connect the Cheapino, and use **File -> Load current layout** to pick this `.vil`. Vial writes the layout directly to the keyboard, no QMK recompile needed.

Keep this file in sync with the bindings in `../init.lua`: if you add a new `hs.hotkey.bind(...)` there, remap a Cheapino key to the matching keycode in Vial, save a fresh export over `vial-kb-layout.vil`, and update `LAYOUT.md` to match.
