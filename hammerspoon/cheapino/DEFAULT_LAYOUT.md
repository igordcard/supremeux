# Cheapino factory default layout

This is the complete factory-default keymap shipped on the Cheapino v2 Vial firmware, sourced from the `default` keymap in [tompi/qmk_firmware](https://github.com/tompi/qmk_firmware/blob/cheapinov2/keyboards/cheapino/keymaps/default/keymap.json) on branch `cheapinov2`.

Use it as a reference if you want to restore any of the defaults that have been overwritten in `vial-kb-layout.vil`, or to understand how the physical layout maps to the Vial matrix.

## Physical layout

Cheapino is a split 3x5+3 (`LAYOUT_split_3x5_3`): three rows of five alpha columns per side, plus three thumb keys per side. 36 keys total, one rotary encoder on the left half with a click.

```
+-----+-----+-----+-----+-----+       +-----+-----+-----+-----+-----+
|  Q  |  W  |  E  |  R  |  T  |       |  Y  |  U  |  I  |  O  |  P  |
+-----+-----+-----+-----+-----+       +-----+-----+-----+-----+-----+
|  A  |  S  |  D  |  F  |  G  |       |  H  |  J  |  K  |  L  |  ;  |
+-----+-----+-----+-----+-----+       +-----+-----+-----+-----+-----+
|  Z  |  X  |  C  |  V  |  B  |       |  N  |  M  |  ,  |  .  |  /  |
+-----+-----+-----+-----+-----+       +-----+-----+-----+-----+-----+
                  +------+------+------+      +-------+-------+-------+
                  | LGUI | SPC  |MO(1) |      | MO(2) | ENTER | RALT  |
                  +------+------+------+      +-------+-------+-------+
                    outer  mid   inner           inner   mid    outer
```

Thumb ordering in the Vial matrix (so you know which cell is which physical key):

- **Left thumbs** live on `rows 4-6, col 11` of the 8x12 Vial matrix: row 6 = inner, row 5 = middle, row 4 = outer.
- **Right thumbs** live on `rows 0-2, col 5`: row 0 = inner, row 1 = middle, row 2 = outer.
- **Alpha grid**: left half on rows 4-6 cols 6-10 (col 6 = innermost, col 10 = pinky); right half on rows 0-2 cols 0-4 (col 0 = innermost, col 4 = pinky).
- **Encoder click**: row 3 col 0.

## Layer 0 - Base (alpha + thumbs)

```
Q W E R T     Y U I O P
A S D F G     H J K L ;
Z X C V B     N M , . /
    LGUI SPC MO(1)   MO(2) ENT RALT
```

No home-row mods in the factory default. The two layer-switch keys are the **inner thumbs**:

- **Left inner thumb = `MO(1)`**: hold to access the numbers/arrows layer.
- **Right inner thumb = `MO(2)`**: hold to access the symbols layer.

## Layer 1 - Numbers + arrows (hold left-inner thumb)

```
1 2 3 4 5     6 7 8 9 0
_ _ _ _ _     ← ↓ ↑ →  _
_ _ _ _ _     _ _ _ _ _
    LGUI SPC (held)   MO(3) ENT RALT
```

The left five alphas disappear (no bindings); the right hand has number row on top and arrow keys on home row. Holding the right-inner thumb while on layer 1 jumps to `MO(3)` (RGB controls).

## Layer 2 - Symbols (hold right-inner thumb)

```
! @ # $ %     ^ & * ( )
_ _ _ _ _     - = [ ] \
_ _ _ _ _     _ + { } |

Note: bottom row has _ _ _ _ _  on left, and: _ _ _ _ _ on right.
Actual layer 2 values for bottom row right half: _ _ { } |
```

(Exact layer-2 assignments: `KC_UNDS KC_PLUS KC_LCBR KC_RCBR KC_PIPE` on the right-hand bottom row, with all other non-symbol keys being `KC_NO`.)

```
    LGUI SPC MO(3)   (held) ENT RALT
```

Holding the left-inner thumb (`MO(3)`) jumps to RGB controls.

## Layer 3 - RGB controls (hold both inner thumbs, or layer 1/2 + inner thumb)

```
_ _ _ _ _     _ _ _ _ _
HUE+ SAT+ VAL+ _ _     _ _ _ _ _
HUE- SAT- VAL- _ _     _ _ _ _ _
    LGUI SPC (held)    (held) ENT RALT
```

Only the RGB hue/saturation/value increment + decrement keys are bound; everything else is `KC_NO`.

## Thumbs summary

| Physical position | Matrix cell | Layer 0 | Layer 1 | Layer 2 | Layer 3 |
|---|---|---|---|---|---|
| Left outer | row 4 col 11 | `KC_LGUI` | `KC_LGUI` | `KC_LGUI` | `KC_LGUI` |
| Left middle | row 5 col 11 | `KC_SPC` | `KC_SPC` | `KC_SPC` | `KC_SPC` |
| Left inner | row 6 col 11 | `MO(1)` | — | `MO(3)` | — |
| Right inner | row 0 col 5 | `MO(2)` | `KC_TRNS` | — | `KC_TRNS` |
| Right middle | row 1 col 5 | `KC_ENT` | `KC_ENT` | `KC_ENT` | `KC_ENT` |
| Right outer | row 2 col 5 | `KC_RALT` | `KC_RALT` | `KC_RALT` | `KC_RALT` |

## What is NOT captured in this file

The factory default layers above are the only thing baked into the firmware's `keymap.json`. Everything else that shows up in a `.vil` file is Vial-runtime state that the user configures:

- **Tap dance slots** - all `KC_NO` by default (no home-row mods in the factory keymap).
- **Combos** - all disabled by default.
- **Key overrides** - all disabled.
- **Encoder actions** - configured via Vial UI, not in keymap.json.
- **Settings** (tapping term, RGB parameters, etc.) - configured via Vial UI.
- **Layers 4-15** - firmware provides the slots but they are blank (`KC_TRNS`).

If you want the exact factory state in a `.vil` file, the easiest path is to flash `cheapino_vial.uf2` and then use Vial's **Security -> Reset** to wipe any stored runtime state; saving the layout at that point gives you the canonical default `.vil`.
