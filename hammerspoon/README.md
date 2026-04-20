# Hammerspoon

[Hammerspoon](https://www.hammerspoon.org/) is a Lua-scriptable macOS automation tool. The config here lives at `~/.hammerspoon/init.lua` on the target machine.

## Bring Slack to the MacBook display

When you press **F13**, Slack is focused on the built-in Retina display, filling the screen. It works whether Slack is already frontmost, hidden, minimized, in native fullscreen on another monitor, or closed to the menu bar with no windows open.

### How it works

1. **F13 is the trigger.** F13 is chosen because it has no default macOS binding and is easy to emit from a secondary keyboard without colliding with the main keyboard. The Cheapino split keyboard is configured (via [Vial](https://vial.rocks/)) to remap its `S` key to F13; the main keyboard still types a normal `S`.
2. **Hammerspoon catches the F13 keypress** and runs the handler in `init.lua`.
3. **Target screen lookup.** `hs.screen.find("Retina Display")` matches the built-in display by substring. Note: the argument is a Lua pattern, so the literal name "Built-in Retina Display" would need the hyphen escaped (`"Built%-in Retina Display"`); using "Retina Display" sidesteps that.
4. **Reopen Slack if needed.** `open -a Slack` is invoked unconditionally. This is the equivalent of clicking the Dock icon: it focuses the app AND triggers the AppKit "reopen" event, which asks Slack to restore a window when none exist (the menu-bar-only state). A plain `app:activate()` does not trigger reopen.
5. **Poll for a window.** The handler retries up to 20 times at 150ms intervals waiting for `slack:allWindows()` to return something, since the reopened window is not instant.
6. **Pick the right window.** Prefer a window where `isStandard()` is true (skips popovers, huddle mini-windows, notification surfaces). Fall back to any window, then `mainWindow()`/`focusedWindow()`.
7. **Place the window.**
   - If minimized, unminimize.
   - If in native macOS fullscreen (its own Space), exit fullscreen, wait 1.2s for the Space animation to complete, then retry. Without that wait, the move silently no-ops because the window has not yet left its Space.
   - `win:setFrame(target:frame())` sizes the window to fill the target screen. This is deliberately NOT native macOS fullscreen, to avoid spawning a new Space every invocation.

### Why `setFrame` instead of `setFullScreen(true)`

Native fullscreen (the green-button behavior) creates a separate Space for the window. That means every F13 press would either create a new Space or leave the window stranded in an old one, fighting the user's Mission Control state. Filling the screen with `setFrame` keeps Slack on the current Space and is the behavior most people actually want from "put Slack fullscreen on this monitor".

## Installation

1. Install Hammerspoon: `brew install --cask hammerspoon`
2. Copy `init.lua` to `~/.hammerspoon/init.lua`
3. Launch Hammerspoon.
4. Grant permissions (see below).
5. From the Hammerspoon menu bar icon, choose **Reload Config** after any edit.

## Required macOS permissions

Hammerspoon needs TWO separate permissions for this config to work. Granting only one gives misleading partial behavior.

### Accessibility (required)

**System Settings -> Privacy & Security -> Accessibility -> Hammerspoon -> on**

Without this, `hs.window.allWindows()` and `app:allWindows()` return an empty list for every application, even ones with clearly visible windows. Activation (focusing apps) still works because it uses LaunchServices, not the Accessibility API, which makes the symptom confusing: the app comes to the front, but Hammerspoon reports "no windows" and cannot move or resize anything.

If Hammerspoon is not already in the Accessibility list, click `+`, navigate to `/Applications/Hammerspoon.app`, add it, toggle on.

After granting, **fully quit and relaunch Hammerspoon** (not just Reload Config). The permission is only read at process start.

Sanity check in the Hammerspoon Console:

```lua
#hs.window.allWindows()
```

If this returns `0` despite many windows being open, Accessibility is not actually effective.

### Input Monitoring (required for F-keys and modifier hotkeys)

**System Settings -> Privacy & Security -> Input Monitoring -> Hammerspoon -> on**

Without this, `hs.hotkey.bind` silently fails to receive the key event. The `hs.hotkey.bind` call itself does not error, so missing this permission looks like "my hotkey just does nothing".
