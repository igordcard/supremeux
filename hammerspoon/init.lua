-- Per-app state: remembers which window was last picked so repeated presses cycle.
local lastWindowIdByApp = {}

local function standardWindowsSorted(app)
	local windows = {}
	for _, w in ipairs(app:allWindows()) do
		if w:isStandard() then table.insert(windows, w) end
	end
	-- Sort by window id for a stable cycle order. app:allWindows() reorders
	-- by recency as we focus windows, which would break cycling.
	table.sort(windows, function(a, b) return a:id() < b:id() end)
	return windows
end

local function pickAppWindow(app, appName)
	local windows = standardWindowsSorted(app)

	if #windows == 0 then
		-- Fall back to any window, then the app's own primary handles.
		local all = app:allWindows()
		if #all > 0 then return all[1] end
		return app:mainWindow() or app:focusedWindow()
	end

	if #windows == 1 then
		lastWindowIdByApp[appName] = windows[1]:id()
		return windows[1]
	end

	-- Cycle: pick the window after the last-picked one (wrapping around).
	-- If the last id is unknown or gone, start at the first.
	local lastId = lastWindowIdByApp[appName]
	local nextIdx = 1
	for i, w in ipairs(windows) do
		if w:id() == lastId then
			nextIdx = (i % #windows) + 1
			break
		end
	end
	lastWindowIdByApp[appName] = windows[nextIdx]:id()
	return windows[nextIdx]
end

local function debugApp(app)
	local rows = {}
	for _, w in ipairs(app:allWindows()) do
		table.insert(rows, string.format("[%s] std=%s vis=%s min=%s",
			w:title(), tostring(w:isStandard()), tostring(w:isVisible()), tostring(w:isMinimized())))
	end
	return #rows == 0 and "(no windows)" or table.concat(rows, " | ")
end

local function placeOnScreen(win, target)
	if win:isMinimized() then win:unminimize() end

	-- If in native fullscreen, exit first, wait for Space animation, then retry.
	if win:isFullScreen() then
		win:setFullScreen(false)
		hs.timer.doAfter(1.2, function() placeOnScreen(win, target) end)
		return
	end

	-- Focus the picked window specifically (important for cycling: setFrame
	-- alone doesn't bring a background window of the same app to the front).
	win:focus()

	-- Fill the target screen's frame (reliable; no Space switching).
	win:setFrame(target:frame())
end

local function focusAppOnScreen(appName, screenPattern)
	local target = hs.screen.find(screenPattern)
	if not target then
		local names = hs.fnutils.map(hs.screen.allScreens(), function(s) return s:name() end)
		hs.alert.show("No target. Screens: " .. hs.inspect(names))
		return
	end

	-- Fast path: app is already running and has a window we can pick.
	-- Skip `open -a` so the MRU window doesn't flash forward before we
	-- switch to our (possibly different, e.g. cycled) target.
	local app = hs.application.get(appName)
	if app then
		local w = pickAppWindow(app, appName)
		if w then
			placeOnScreen(w, target)
			return
		end
	end

	-- Slow path: app isn't running, or is running without a pickable window
	-- (menu-bar mode). `open -a` both launches and triggers the AppKit
	-- "reopen" event, which restores a window in the menu-bar case.
	hs.execute("/usr/bin/open -a '" .. appName .. "'")

	local function tryPlace(attempt)
		app = hs.application.get(appName)
		if app then
			local w = pickAppWindow(app, appName)
			if w then
				placeOnScreen(w, target)
				return
			end
		end
		if attempt < 20 then
			hs.timer.doAfter(0.15, function() tryPlace(attempt + 1) end)
		else
			hs.alert.show("No " .. appName .. " window. " .. (app and debugApp(app) or "app not found"), 5)
		end
	end

	tryPlace(1)
end

hs.hotkey.bind({}, "F13", function() focusAppOnScreen("Slack", "Retina Display") end)
hs.hotkey.bind({}, "F14", function() focusAppOnScreen("Gitodo", "Retina Display") end)
hs.hotkey.bind({}, "F15", function() focusAppOnScreen("Google Chrome", "Retina Display") end)
hs.hotkey.bind({}, "F19", function() focusAppOnScreen("zoom.us", "Retina Display") end)

-- Shell quote a string for inclusion in a shell command.
local function shq(s) return "'" .. s:gsub("'", "'\\''") .. "'" end

-- F16: mic mute toggle.
--
-- In a Zoom meeting: invoke Zoom's mute via the accessibility API. The
-- menu item Zoom exposes ("Mute audio" / "Unmute audio") is actually a
-- toggle action, not a set-state action: its title reflects the current
-- state, but invoking it just flips mute regardless of which label is
-- shown. This matters for rapid presses, where Zoom has not yet
-- refreshed the menu title between presses - findMenuItem returns a
-- stale label, but selectMenuItem still toggles.
--
-- Strategy: track the presumed mute state locally and flip on each
-- press. Re-sync from the menu only when enough time has passed that
-- the label is guaranteed fresh (handles the user muting via Zoom's UI
-- button between F16 presses). Clear the local state when Zoom leaves
-- the meeting, so the next meeting starts fresh.
--
-- Outside a meeting: toggle the default input device via hs.audiodevice.
local zoomMutedPresumed = nil
local zoomLastToggle = 0

hs.hotkey.bind({}, "F16", function()
	local zoom = hs.application.get("zoom.us")
	if zoom then
		local muteAvail = zoom:findMenuItem({ "Meeting", "Mute audio" }) ~= nil
		local unmuteAvail = zoom:findMenuItem({ "Meeting", "Unmute audio" }) ~= nil

		if muteAvail or unmuteAvail then
			local now = hs.timer.secondsSinceEpoch()
			local stableForResync = (now - zoomLastToggle) > 1.5

			-- Re-sync local state from the menu when we know it is fresh.
			if zoomMutedPresumed == nil or stableForResync then
				zoomMutedPresumed = unmuteAvail
			end

			-- Click whichever menu label is currently showing. Zoom treats
			-- the invocation as a toggle either way, so exactly one of
			-- these will succeed (the one whose label is currently in the
			-- menu) and both cause a flip in Zoom's actual state.
			if not zoom:selectMenuItem({ "Meeting", "Mute audio" }) then
				zoom:selectMenuItem({ "Meeting", "Unmute audio" })
			end

			zoomMutedPresumed = not zoomMutedPresumed
			zoomLastToggle = now
			hs.alert.show(zoomMutedPresumed and "Mic muted" or "Mic on")
			return
		else
			-- Zoom is running but not in a meeting; drop stale state.
			zoomMutedPresumed = nil
		end
	end

	local mic = hs.audiodevice.defaultInputDevice()
	if not mic then
		hs.alert.show("No default input device")
		return
	end
	local muted = not mic:muted()
	mic:setMuted(muted)
	hs.alert.show(muted and "Mic muted" or "Mic on")
end)

-- F17: create a new timestamped note and open it in vim inside Ghostty
--
-- ~/mygit/ej/notes/YYYYMMDDTHHMMSS.md (second-granularity uniqueness).
local function nextNotePath()
	local home = os.getenv("HOME")
	local dir = home .. "/mygit/ej/notes"
	hs.execute("/bin/mkdir -p " .. shq(dir))
	local stamp = os.date("%Y%m%dT%H%M%S")
	local p = string.format("%s/%s.md", dir, stamp)
	hs.execute("/usr/bin/touch " .. shq(p))
	return p
end

-- Paste `command` into the frontmost app via the clipboard, then send
-- Return. Paste is far more reliable than hs.eventtap.keyStrokes, which
-- drops/transposes characters under load and handles embedded newlines
-- inconsistently. We save and restore the clipboard around the paste.
local function pasteAndEnter(command)
	local saved = hs.pasteboard.getContents()
	hs.pasteboard.setContents(command)
	hs.eventtap.keyStroke({ "cmd" }, "v")
	hs.timer.doAfter(0.15, function()
		hs.eventtap.keyStroke({}, "return")
		hs.timer.doAfter(0.1, function()
			if saved ~= nil then hs.pasteboard.setContents(saved) end
		end)
	end)
end

-- Bring Ghostty forward with a fresh shell, then optionally paste
-- `command` + Enter into it. `newShellKey` is the single letter to
-- press with Cmd: "n" for a new window (fresh $HOME shell), "t" for a
-- new tab (inherits cwd from the current tab). If Ghostty was not
-- running or had no windows, it is launched; the keystroke is skipped
-- in that case because the freshly-opened window is already a new
-- shell.
local function runInFreshGhosttyShell(newShellKey, command)
	local ghostty = hs.application.get("Ghostty")
	local hasWindow = ghostty and #ghostty:allWindows() > 0

	local function typeCommandIfAny()
		if command then
			hs.timer.doAfter(0.6, function() pasteAndEnter(command) end)
		end
	end

	if hasWindow then
		ghostty:activate()
		hs.timer.doAfter(0.15, function()
			hs.eventtap.keyStroke({ "cmd" }, newShellKey)
			typeCommandIfAny()
		end)
		return
	end

	-- Launch (or reopen) Ghostty; it will open exactly one window. "New
	-- tab / new window" distinction is moot here since there is no
	-- existing tab to inherit cwd from.
	hs.execute("/usr/bin/open -a Ghostty")
	if not command then return end
	local tries = 0
	local function waitThenPaste()
		tries = tries + 1
		local g = hs.application.get("Ghostty")
		if g and #g:allWindows() > 0 then
			g:activate()
			hs.timer.doAfter(0.5, function() pasteAndEnter(command) end)
			return
		end
		if tries < 40 then
			hs.timer.doAfter(0.1, waitThenPaste)
		else
			hs.alert.show("Ghostty did not open a window")
		end
	end
	waitThenPaste()
end

hs.hotkey.bind({}, "F17", function()
	local p = nextNotePath()
	local dir = os.getenv("HOME") .. "/mygit/ej/notes"
	-- cd into the notes dir first so `ls`/tab-completion is easy after vim
	-- exits, but vim the absolute path so shell history stays useful from
	-- any cwd.
	runInFreshGhosttyShell("n", "cd " .. shq(dir) .. " && vim " .. shq(p))
end)

-- F18: open the current repo/PR on GitHub, using the cwd captured by the
-- shell hooks (see README: "Shell sidechannel for F18"). Each shell writes
-- to ~/.cache/shell-cwd/<pid>, and we read the most recently modified file,
-- which is the shell the user most recently interacted with (a decent
-- proxy for "the frontmost Ghostty tab").
local function mostRecentShellCwd()
	local dir = os.getenv("HOME") .. "/.cache/shell-cwd"
	local newest = hs.execute("/bin/ls -t " .. shq(dir) .. " 2>/dev/null | head -1")
	if not newest or newest == "" then return nil end
	newest = newest:gsub("%s+$", "")
	if newest == "" then return nil end
	local f = io.open(dir .. "/" .. newest, "r")
	if not f then return nil end
	local cwd = f:read("*l")
	f:close()
	if cwd and cwd ~= "" then return cwd end
	return nil
end

hs.hotkey.bind({}, "F18", function()
	local cwd = mostRecentShellCwd()
	if not cwd then
		hs.alert.show("No cached shell cwd. Install the shell hooks (see README).", 4)
		return
	end
	-- `gh pr view --web` opens the PR for the current branch if one exists;
	-- otherwise it exits non-zero and we fall through to `gh browse`, which
	-- opens the repo root. Prepend Homebrew paths because hs.execute runs
	-- with a minimal PATH that excludes /opt/homebrew/bin.
	local cmd = string.format(
		"export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH && cd %s && { gh pr view --web 2>&1 || gh browse 2>&1 ; }",
		shq(cwd)
	)
	local out, ok = hs.execute(cmd)
	if not ok then
		hs.alert.show("gh failed in " .. cwd .. ": " .. (out or ""), 5)
	end
end)

-- F20: open a fresh Ghostty window in $HOME and launch Claude.
--
-- Cmd+N inherits cwd from the current Ghostty tab. Directly launching
-- Ghostty's own binary (or `open -n -a Ghostty`) turned out to be
-- unsafe: the child can block Hammerspoon's run loop, and repeated
-- F20 presses while blocked produced a storm of windows and a frozen
-- Hammerspoon. `open -n` is also refused by Ghostty's single-instance
-- policy on some setups.
--
-- Instead, send Cmd+N and paste `cd && claude` (bare `cd` goes to
-- $HOME in zsh, then we launch Claude there). The window appears
-- briefly in the inherited cwd, then snaps to $HOME and drops into
-- Claude. Reliable, no blocking, no freeze.
hs.hotkey.bind({}, "F20", function()
	runInFreshGhosttyShell("n", "cd && claude")
end)

-- "F21" (actually Shift+F16): open a new Ghostty tab (which inherits
-- the current tab's cwd under Ghostty's defaults) and launch Claude
-- CLI in it. Pair this with an existing Ghostty tab sitting in the
-- repo you want Claude to start in; a new tab keeps the same working
-- directory, and `claude` picks that up as its project context.
--
-- Bound to Shift+F16 rather than F21 because macOS does not route F21+
-- through its keycode map. The Cheapino is remapped in Vial to emit
-- Shift+F16 for this key; the main keyboard can't produce F16 at all,
-- so the combo is guaranteed Cheapino-only.
hs.hotkey.bind({ "shift" }, "F16", function()
	runInFreshGhosttyShell("t", "claude")
end)

-- "F22" (actually Shift+F17): open a new Ghostty window and place it
-- on the DELL (second) monitor. Uses Cmd+N when Ghostty has windows,
-- or launches Ghostty if it does not.
--
-- The newly-opened window becomes focused, so focusedWindow() after a
-- small settle delay is the one we want to move.
local function moveGhosttyFocusedToDell()
	local ghostty = hs.application.get("Ghostty")
	if not ghostty then return end
	local target = hs.screen.find("DELL")
	if not target then return end
	local win = ghostty:focusedWindow() or ghostty:mainWindow()
	if win then win:moveToScreen(target) end
end

-- "F23" (actually Shift+F18): cycle focus through every Ghostty
-- window on any screen, without moving or resizing them. Reuses the
-- same per-app cycle state that F13-F15/F19 use, so it picks a
-- different window on each press and wraps around.
hs.hotkey.bind({ "shift" }, "F18", function()
	local ghostty = hs.application.get("Ghostty")
	if not ghostty or #ghostty:allWindows() == 0 then
		hs.execute("/usr/bin/open -a Ghostty")
		return
	end
	local win = pickAppWindow(ghostty, "Ghostty")
	if not win then return end
	if win:isMinimized() then win:unminimize() end
	win:focus()
end)

-- "F24" (actually Shift+F19): paste "LGTM" into the frontmost field and
-- press Cmd+Return to submit. Designed for one-tap approval on GitHub PR
-- review comment boxes (Cmd+Enter = "Submit"), but works anywhere the
-- same shortcut submits a comment (Slack, Linear, etc.). Uses paste
-- rather than keyStrokes so the four letters never get dropped or
-- transposed under load.
hs.hotkey.bind({ "shift" }, "F19", function()
	local saved = hs.pasteboard.getContents()
	hs.pasteboard.setContents("LGTM")
	hs.eventtap.keyStroke({ "cmd" }, "v")
	hs.timer.doAfter(0.15, function()
		hs.eventtap.keyStroke({ "cmd" }, "return")
		hs.timer.doAfter(0.15, function()
			hs.eventtap.keyStroke({}, "return")
			hs.timer.doAfter(0.1, function()
				if saved ~= nil then hs.pasteboard.setContents(saved) end
			end)
		end)
	end)
end)

hs.hotkey.bind({ "shift" }, "F17", function()
	local ghostty = hs.application.get("Ghostty")
	local hasWindow = ghostty and #ghostty:allWindows() > 0

	if hasWindow then
		ghostty:activate()
		hs.timer.doAfter(0.15, function()
			hs.eventtap.keyStroke({ "cmd" }, "n")
			hs.timer.doAfter(0.5, moveGhosttyFocusedToDell)
		end)
		return
	end

	hs.execute("/usr/bin/open -a Ghostty")
	local tries = 0
	local function waitAndMove()
		tries = tries + 1
		local g = hs.application.get("Ghostty")
		if g and #g:allWindows() > 0 then
			hs.timer.doAfter(0.3, moveGhosttyFocusedToDell)
			return
		end
		if tries < 40 then
			hs.timer.doAfter(0.1, waitAndMove)
		end
	end
	waitAndMove()
end)
