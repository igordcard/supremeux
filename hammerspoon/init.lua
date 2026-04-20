local function pickAppWindow(app)
	-- Prefer a standard window (skips popovers, huddle mini-windows, etc.)
	for _, w in ipairs(app:allWindows()) do
		if w:isStandard() then return w end
	end
	-- Fall back to any window, then mainWindow/focusedWindow
	local all = app:allWindows()
	if #all > 0 then return all[1] end
	return app:mainWindow() or app:focusedWindow()
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

	-- `open -a` both focuses the app and triggers the AppKit "reopen" event,
	-- which restores a window if the app was closed to the menu bar.
	hs.execute("/usr/bin/open -a '" .. appName .. "'")

	local function tryPlace(attempt)
		local app = hs.application.get(appName)
		if app then
			local w = pickAppWindow(app)
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
