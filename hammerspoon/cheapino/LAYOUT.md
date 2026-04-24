# Cheapino layout for Hammerspoon

Physical map of the Cheapino keys that emit combos `../init.lua` reacts to. Every other key on the board is unrelated to Hammerspoon and is deliberately omitted here. The rotary encoder is included at the end for completeness even though it doesn't feed into Hammerspoon.

## Physical layout

Cheapino is a split 3x5+3: three rows of five alpha columns per side, plus three thumb keys per side. Keys shown below are the ones wired to Hammerspoon; blanks are untouched by this config.

```
LEFT HALF                                        RIGHT HALF
+------+------+------+------+------+             +------+------+------+------+------+
|      |      |      |      |      |             | S+F17|      | F20  | S+F16| C+F13|
+------+------+------+------+------+             +------+------+------+------+------+
|      |      |      |      |      |             |      |      |      | F18  | C+F14|
+------+------+------+------+------+             +------+------+------+------+------+
| F19  |      |      |      | S+F18|             |      |      |      |      | C+F15|
+------+------+------+------+------+             +------+------+------+------+------+
               +------+------+------+       +------+------+------+
               | F15  | F14  | F13  |       | F16  | F17  | S+F19|
               +------+------+------+       +------+------+------+
                 outer mid  inner             inner  mid   outer
```

`S+` = `Shift+`, `C+` = `Ctrl+`. On the left half the leftmost column is the pinky; on the right half the rightmost column is the pinky.

## What each key does

### Left thumbs

| Key | Emits | Hammerspoon action |
|---|---|---|
| Left outer thumb | `F15` | Focus/cycle Google Chrome on the primary monitor |
| Left middle thumb | `F14` | Focus/cycle Gitodo on the primary monitor |
| Left inner thumb | `F13` | Focus/cycle Slack on the primary monitor |

### Right thumbs

| Key | Emits | Hammerspoon action |
|---|---|---|
| Right inner thumb | `F16` | Toggle mic mute (Zoom-aware when in a meeting) |
| Right middle thumb | `F17` | New timestamped note in `~/mygit/ej/notes/`, opened in vim inside Ghostty |
| Right outer thumb | `Shift+F19` | Type `LGTM`, press `Cmd+Return`, then press `Return` (PR approvals, comment boxes) |

### Right-hand alphas

| Key position | Emits | Hammerspoon action |
|---|---|---|
| Top row, index (Y pos) | `Shift+F17` | Open a new Ghostty window on the secondary monitor |
| Top row, middle (I pos) | `F20` | Open a fresh Ghostty window in `$HOME` and run `claude` |
| Top row, ring (O pos) | `Shift+F16` | Open a new Ghostty tab inheriting cwd and run `claude` |
| Top row, pinky (P pos) | `Ctrl+F13` | Focus/cycle Slack on the secondary monitor |
| Home row, ring (L pos) | `F18` | Open the current repo/PR on GitHub |
| Home row, pinky (`;` pos) | `Ctrl+F14` | Focus/cycle Gitodo on the secondary monitor |
| Bottom row, pinky (`/` pos) | `Ctrl+F15` | Focus/cycle Google Chrome on the secondary monitor |

### Left-hand alphas

| Key position | Emits | Hammerspoon action |
|---|---|---|
| Bottom row, pinky (Z pos) | `F19` | Focus/cycle Zoom on the primary monitor |
| Bottom row, index (B pos) | `Shift+F18` | Cycle focus through every Ghostty window, on any screen, no movement |

### Encoder (left half)

Not wired to Hammerspoon; handled entirely by the keyboard firmware.

| Action | Emits | Effect |
|---|---|---|
| Rotate clockwise | `KC_WH_D` | Scroll wheel down |
| Rotate counter-clockwise | `KC_WH_U` | Scroll wheel up |
| Click | `KC_MNXT` | Media next track |
