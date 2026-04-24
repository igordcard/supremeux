# Hammerspoon

[Hammerspoon](https://www.hammerspoon.org/) is a Lua-scriptable macOS automation tool. The config here lives at `~/.hammerspoon/init.lua` on the target machine.

## Bring an app to the MacBook display

An F-key press focuses a chosen app on the built-in Retina display, filling the screen. It works whether the app is already frontmost, hidden, minimized, in native fullscreen on another monitor, or closed to the menu bar with no windows open.

### Current bindings

| Key | Action |
|---|---|
| F13 | Focus/cycle Slack on the MacBook display |
| F14 | Focus/cycle Gitodo on the MacBook display |
| F15 | Focus/cycle Google Chrome on the MacBook display |
| F16 | Toggle default-input mic mute |
| F17 | New timestamped note (`YYYYMMDDTHHMMSS.md`) in `~/mygit/ej/notes/`, opened in vim inside Ghostty |
| F18 | Open the current repo/PR on GitHub (requires shell hook, see below) |
| F19 | Focus/cycle Zoom on the MacBook display |
| F20 | Open a fresh Ghostty window in `$HOME` and run `claude` |
| Shift+F16 | Open a new Ghostty tab (inherits current tab's cwd) and run `claude` |
| Shift+F17 | Open a new Ghostty window on the DELL (second) monitor; works even if Ghostty is closed |
| Shift+F18 | Cycle focus through every Ghostty window, wherever they are; no window movement |
| Shift+F19 | Type `LGTM` into the focused field, submit with Cmd+Return, then press Return (PR approvals, comment boxes) |
| Ctrl+F13 | Focus/cycle Slack on the secondary monitor |
| Ctrl+F14 | Focus/cycle Gitodo on the secondary monitor |
| Ctrl+F15 | Focus/cycle Google Chrome on the secondary monitor |

> Note: the Cheapino key physically labeled F21 is remapped in Vial to emit `Shift+F16`. macOS only routes F-keys up to F20 through its virtual-keycode map, so anything past F20 has to be expressed as a modifier + standard F-key combo. `Shift+F16` is safe because the main keyboard cannot produce F16 at all, so the combo never collides.

Each F-key is emitted by the Cheapino split keyboard, configured (via [Vial](https://vial.rocks/)) to remap one of its letter keys to the corresponding F-key. The main keyboard still types the original letter normally; only the secondary keyboard triggers the jump. F13-F19 are chosen because they have no default macOS bindings and never collide with anything a normal keyboard emits.

### Cycling across windows

When the target app has multiple standard windows (e.g. several Chrome windows), repeated presses of the hotkey cycle through them: first press brings one window to the MacBook display, second press swaps to the next, and so on, wrapping around. State is tracked per app, so F13 and F15 maintain independent cursors.

Cycling order is by window ID (stable across focus changes) rather than MRU order. Using MRU would make cycling collapse to a single window: focusing a window bumps it to the front of `app:allWindows()`, so the "next" window after it would just be itself.

### Configuring your monitors

The top of `init.lua` defines two variables so you can point this config at your own displays without hunting through the file:

```lua
local PRIMARY_SCREEN = "Retina Display" -- MacBook built-in display
local SECONDARY_SCREEN = "DELL"         -- External monitor
```

Each value is a Lua pattern matched against screen names via `hs.screen.find`, so a unique substring is enough. Beware that `-` is a Lua pattern metacharacter: use `"Retina Display"` rather than `"Built-in Retina Display"`, or escape as `"Built%-in Retina Display"`.

To list the screen names macOS currently reports, open the Hammerspoon Console (menu-bar icon -> Console) and run:

```lua
hs.inspect(hs.fnutils.map(hs.screen.allScreens(), function(s) return s:name() end))
```

`hs.inspect` is needed because the console prints a bare `table: 0x...` address otherwise. You will get something like `{ "DELL U2718Q", "Built-in Retina Display" }`. Pick a unique substring from each and drop it into the two variables above.

### Adding another app

Add one line to `init.lua`:

```lua
hs.hotkey.bind({}, "F15", function() focusAppOnScreen("Linear", PRIMARY_SCREEN) end)
```

The second argument to `focusAppOnScreen` is any screen pattern string — you can reuse `PRIMARY_SCREEN`/`SECONDARY_SCREEN` or pass a literal pattern for a third monitor.

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

## F16: mic mute toggle (Zoom-aware)

When Zoom is in a meeting, F16 invokes Zoom's "Mute audio" / "Unmute audio" menu item via the accessibility API (`app:selectMenuItem(...)`). No keystroke is sent, so it works regardless of which app is frontmost, and Zoom's "Enable Global Shortcut" setting is not required. When not in a meeting, F16 falls back to toggling `hs.audiodevice.defaultInputDevice():setMuted(...)` and flashes "Mic muted" / "Mic on".

### Why not toggle the system mic directly during calls

Zoom tracks its own mute state separately from macOS's input-device mute. Muting via `setMuted(true)` at the device level cuts the audio Zoom receives, but Zoom's UI continues to show the user as unmuted — other participants see the wrong state, and the speaker does not get the usual visual cue. Driving Zoom's own mute avoids this desync entirely.

### Handling rapid presses

Zoom's menu item is actually a toggle action, not a set-state action: its title ("Mute audio" vs "Unmute audio") reflects the current state, but invoking it just flips mute regardless of which label is showing. On rapid presses, Zoom has not yet refreshed the menu title between invocations, so `findMenuItem` returns the stale label even though `selectMenuItem` still successfully toggles. Reading the label to decide the alert text therefore drifts from reality.

The handler tracks the presumed mute state locally and flips it on every press. It re-syncs from the menu label only when at least 1.5s have elapsed since the last F16 press, which covers the case where the user muted via Zoom's UI button between F16 presses. The local state is cleared when Zoom leaves the meeting (both menu items absent) so the next meeting starts fresh.

## F17: new timestamped note, opened in vim inside Ghostty

Press F17 and a fresh Ghostty window opens with `vim ~/mygit/ej/notes/YYYYMMDDTHHMMSS.md` already running, ready to type. The file itself is only created if/when you save from vim, so dismissing without writing leaves no empty notes behind. The directory is created if missing.

Second-level granularity is enough for uniqueness in practice: you would have to press F17 twice in the same second to collide, in which case both presses touch and open the same file (benign). This avoids a per-day counter entirely.

### Why paste + Return instead of typing

The command is injected into the new Ghostty window via the clipboard (`Cmd+V` followed by a separate `Return` event), with the original clipboard contents saved and restored. Initially this used `hs.eventtap.keyStrokes(command .. "\n")`, but under load that function drops or transposes characters and handles embedded newlines inconsistently; paste is deterministic and the Return is a dedicated event that always fires.

### Why Cmd+N when Ghostty already has windows

The "bring Ghostty forward + new window + run vim" flow needs to work in three states: Ghostty already running with windows, running menu-bar-only, or not running at all. When Ghostty already has windows, `Cmd+N` is issued so the paste never lands in a window that has a partial command typed, a vim session, or a running `claude` prompt. When Ghostty is cold-launched it comes up with exactly one fresh window, so no `Cmd+N` is needed.

## F18: open the current repo or PR on GitHub

Press F18 and the browser opens either the pull request for your current branch, or the repo root if no PR exists. Detection uses `gh`:

```sh
gh pr view --web 2>&1 || gh browse 2>&1
```

So `gh` needs to be installed and authenticated (`gh auth status`).

### Shell sidechannel for F18

Hammerspoon cannot directly ask Ghostty "what is the cwd of the frontmost terminal session". Ghostty does not expose a rich AppleScript API, the window title is truncated with an ellipsis for long paths so it cannot be parsed back to an absolute path, and mapping a focused window back to its specific child shell process is not reliable from outside. The approach here is a set of zsh hooks that maintain one file per shell PID under `~/.cache/shell-cwd/`. On F18, Hammerspoon picks the most recently modified file (via `ls -t`) and reads the cwd from it. That file corresponds to the shell the user has most recently interacted with, which in practice tracks the frontmost tab.

Add to `~/.zshrc`:

```zsh
mkdir -p ~/.cache/shell-cwd
__save_shell_cwd() { print -r -- "$PWD" > ~/.cache/shell-cwd/$$ }
precmd_functions+=(__save_shell_cwd)
preexec_functions+=(__save_shell_cwd)
chpwd_functions+=(__save_shell_cwd)
trap '/bin/rm -f ~/.cache/shell-cwd/$$' EXIT
```

Then open a new terminal (or `source ~/.zshrc`) so the hooks start running.

The three hooks cover complementary events:

- `precmd` fires before each prompt is displayed. Catches the steady state "shell is waiting for input in this directory".
- `preexec` fires just before a command runs. Catches activity even when the user is launching a long-running program (`vim`, `claude`, `ssh`) that would otherwise suppress further prompts.
- `chpwd` fires after every directory change. Catches `cd` that happens inside a single compound command (e.g. `cd ~/repo && claude`), where `preexec` already captured the previous cwd.

The `trap` on EXIT removes the file when the shell terminates, so stale per-PID files do not accumulate. Even without the trap, stale files are harmless: they have older mtimes than the user's current activity, so `ls -t` never picks them.

### Why this works even inside Claude Code / vim / ssh

The `preexec` hook fires just before the long-running command starts, so the file captures the cwd at the moment you ran `claude`, `vim`, or `ssh`. When you press F18 while deep inside a Claude Code conversation, the file still reflects the directory where you launched `claude`, which is almost always the repo directory you care about.

### Caveat: multiple terminals without recent activity in the frontmost one

The "most recently touched file wins" heuristic fails in one specific case: if shell A in repo X has recently had activity, and you then switch focus to shell B in repo Y without typing anything or pressing Enter, F18 opens repo X. Typing one character plus Enter in B (or any `cd`) refreshes B's timestamp and fixes it. In day-to-day use this rarely bites.

## Why `setFrame` instead of `setFullScreen(true)`

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
