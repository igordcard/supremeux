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
