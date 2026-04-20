local function pickSlackWindow(slack)
	-- Try standard visible window first
	for _, w in ipairs(slack:allWindows()) do
		if w:isStandard() then return w end
	end
	-- Then any window at all
	local all = slack:allWindows()
	if #all > 0 then return all[1] end
	return slack:mainWindow() or slack:focusedWindow()
end

local function debugSlack(slack)
	local rows = {}
	for _, w in ipairs(slack:allWindows()) do
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
	hs.alert.show("Slack -> " .. target:name())
end

hs.hotkey.bind({}, "F13", function()
	local target = hs.screen.find("Retina Display")
	if not target then
		local names = hs.fnutils.map(hs.screen.allScreens(), function(s) return s:name() end)
		hs.alert.show("No target. Screens: " .. hs.inspect(names))
		return
	end

	-- `open -a` both focuses Slack and triggers the "reopen" event,
	-- which restores a window if Slack was closed to the menu bar.
	hs.execute("/usr/bin/open -a Slack")

	local function tryPlace(attempt)
		local slack = hs.application.get("Slack")
		if slack then
			local w = pickSlackWindow(slack)
			if w then
				placeOnScreen(w, target)
				return
			end
		end
		if attempt < 20 then
			hs.timer.doAfter(0.15, function() tryPlace(attempt + 1) end)
		else
			hs.alert.show("No Slack window. " .. (slack and debugSlack(slack) or "app not found"), 5)
		end
	end

	tryPlace(1)
end)
