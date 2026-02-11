# supremeux

A collection of tools and configurations to improve and optimize the user experience across operating systems.

## Karabiner-Elements

### macOS Tiling Shortcuts for Non-Apple External Keyboards

macOS Sequoia introduced native window tiling with `Fn + Ctrl + Arrow` shortcuts (and `Fn + Ctrl + F` for fullscreen, `Fn + Ctrl + C` for center). On Apple keyboards, `Fn` sits in the bottom-left corner, making these shortcuts natural. On most external keyboards, however, `Fn` either doesn't exist or is in an awkward position — breaking the ergonomics entirely.

This Karabiner-Elements complex modification remaps `Ctrl + Option + Arrow/F/C` to the native tiling shortcuts, letting you tile windows comfortably on any keyboard while maintaining muscle memory across devices.

**Mappings:**

| Input | Output | Action |
|---|---|---|
| `Ctrl + Opt + ←` | `Fn + Ctrl + ←` | Tile left |
| `Ctrl + Opt + →` | `Fn + Ctrl + →` | Tile right |
| `Ctrl + Opt + ↑` | `Fn + Ctrl + ↑` | Tile top / maximize |
| `Ctrl + Opt + ↓` | `Fn + Ctrl + ↓` | Tile bottom |
| `Ctrl + Opt + F` | `Fn + Ctrl + F` | Fill (fullscreen) |
| `Ctrl + Opt + C` | `Fn + Ctrl + C` | Center |

All mappings also pass through `Shift` to support the "Arrange" window actions from the macOS tiling system.

**Installation:**

1. Install [Karabiner-Elements](https://karabiner-elements.pqrs.org/)
2. Copy `macos-tiling-shortcuts-on-non-apple-external-keyboard.json` into `~/.config/karabiner/assets/complex_modifications/`
3. Open Karabiner-Elements → Complex Modifications → Add rule → Enable the rule
