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

-- F16: toggle default input mic mute
hs.hotkey.bind({}, "F16", function()
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

-- Bring Ghostty forward with a fresh window, then paste `command` + Enter
-- into it. Works whether Ghostty was already running, running with no
-- windows (menu-bar-only), or not running at all.
local function runInNewGhosttyWindow(command)
	local ghostty = hs.application.get("Ghostty")
	local hasWindow = ghostty and #ghostty:allWindows() > 0

	if hasWindow then
		ghostty:activate()
		hs.timer.doAfter(0.15, function()
			-- Cmd+N for a fresh shell, since an existing window may have a
			-- partial command typed, be running vim/claude, etc.
			hs.eventtap.keyStroke({ "cmd" }, "n")
			-- Wait for the new window's shell to reach a prompt.
			hs.timer.doAfter(0.6, function() pasteAndEnter(command) end)
		end)
		return
	end

	-- Launch (or reopen) Ghostty; it will open exactly one window.
	hs.execute("/usr/bin/open -a Ghostty")
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
	runInNewGhosttyWindow("cd " .. shq(dir) .. " && vim " .. shq(p))
end)

-- F18: open the current repo/PR on GitHub, using the cwd captured by the
-- shell precmd hook (see README: "Shell sidechannel for F18").
local function lastShellCwd()
	local path = os.getenv("HOME") .. "/.cache/last-shell-cwd"
	local f = io.open(path, "r")
	if not f then return nil end
	local cwd = f:read("*l")
	f:close()
	if cwd and cwd ~= "" then return cwd end
	return nil
end

hs.hotkey.bind({}, "F18", function()
	local cwd = lastShellCwd()
	if not cwd then
		hs.alert.show("No cached shell cwd. Install the precmd hook (see README).", 4)
		return
	end
	-- `gh pr view --web` opens the PR for the current branch if one exists;
	-- otherwise it exits non-zero and we fall through to `gh browse`, which
	-- opens the repo root.
	local cmd = string.format(
		"cd %s && { gh pr view --web 2>&1 || gh browse 2>&1 ; }",
		shq(cwd)
	)
	local out, ok = hs.execute(cmd)
	if not ok then
		hs.alert.show("gh failed in " .. cwd .. ": " .. (out or ""), 5)
	end
end)
