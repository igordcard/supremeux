# Cheapino keymap

`vial-kb-layout.vil` is a [Vial](https://github.com/vial-kb/vial-qmk) keyboard layout file for the [Cheapino](https://github.com/igordcard/cheapino) split keyboard, configured to emit the F-key and modifier combos that [`../init.lua`](../init.lua) listens for.

To use it: open Vial, connect the Cheapino, and load this file via **File -> Load current layout**. Vial writes the layout directly to the keyboard's firmware, no QMK recompile needed.

Keep this file in sync with the bindings in `../init.lua`: if you add a new `hs.hotkey.bind(...)` there, remap a Cheapino key to the matching keycode and save the updated `.vil` here.
