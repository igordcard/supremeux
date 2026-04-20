# Hammerspoon

[Hammerspoon](https://www.hammerspoon.org/) is a Lua-scriptable macOS automation tool. The config here lives at `~/.hammerspoon/init.lua` on the target machine.

## Bring an app to the MacBook display

An F-key press focuses a chosen app on the built-in Retina display, filling the screen. It works whether the app is already frontmost, hidden, minimized, in native fullscreen on another monitor, or closed to the menu bar with no windows open.

### Current bindings

| Key | App |
|---|---|
| F13 | Slack |
| F14 | Gitodo |

Each F-key is emitted by the Cheapino split keyboard, configured (via [Vial](https://vial.rocks/)) to remap one of its letter keys to the corresponding F-key. The main keyboard still types the original letter normally; only the secondary keyboard triggers the jump. F13-F19 are chosen because they have no default macOS bindings and never collide with anything a normal keyboard emits.

### Adding another app

Add one line to `init.lua`:

```lua
hs.hotkey.bind({}, "F15", function() focusAppOnScreen("Linear", "Retina Display") end)
```

The second argument is a Lua pattern matched against screen names via `hs.screen.find`, so a unique substring is enough. Beware that hyphens are pattern metacharacters: use `"Retina Display"` rather than `"Built-in Retina Display"`, or escape as `"Built%-in Retina Display"`.

### How it works

1. **An F-key is the trigger.** F13-F19 have no default macOS binding, so they never collide with anything a regular keyboard sends.
2. **Hammerspoon catches the keypress** and runs `focusAppOnScreen(appName, screenPattern)`.
3. **Target screen lookup.** `hs.screen.find(screenPattern)` matches by substring. The argument is a Lua pattern, so special characters (notably `-`) must be escaped if you want them literal.
4. **Reopen the app if needed.** `open -a <AppName>` is invoked unconditionally. This is the equivalent of clicking the Dock icon: it focuses the app AND triggers the AppKit "reopen" event, which asks the app to restore a window when none exist (the menu-bar-only state). A plain `app:activate()` does not trigger reopen.
5. **Poll for a window.** The handler retries up to 20 times at 150ms intervals waiting for `app:allWindows()` to return something, since a reopened window is not instant.
6. **Pick the right window.** Prefer a window where `isStandard()` is true (skips popovers, mini-windows, notification surfaces). Fall back to any window, then `mainWindow()`/`focusedWindow()`.
7. **Place the window.**
   - If minimized, unminimize.
   - If in native macOS fullscreen (its own Space), exit fullscreen, wait 1.2s for the Space animation to complete, then retry. Without that wait, the move silently no-ops because the window has not yet left its Space.
   - `win:setFrame(target:frame())` sizes the window to fill the target screen. This is deliberately NOT native macOS fullscreen, to avoid spawning a new Space every invocation.

### Why `setFrame` instead of `setFullScreen(true)`

Native fullscreen (the green-button behavior) creates a separate Space for the window. That means every hotkey press would either create a new Space or leave the window stranded in an old one, fighting the user's Mission Control state. Filling the screen with `setFrame` keeps the app on the current Space and is the behavior most people actually want from "put X fullscreen on this monitor".

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
