--
-- Kraken Calendar Notes - override merged into the core "calendar_main" window.
--
-- Replaces the ruleset's addLogEntry(), whose creation branch is gated on
-- Session.IsHost (so players can't make notes). Our version lets a player
-- request creation via the host (OOB), and stamps the author + identity color.
-- We cannot read the core window's private aEvents upvalue from this separate
-- script chunk, so we scan the shared calendar.log list directly to find an
-- existing entry for the date. Single note per day (matches the built-in);
-- the multi-note day panel is Phase 2.
--

function addLogEntry(nMonth, nDay)
	local nYear = CalendarManager.getCurrentYear();

	-- Find an existing entry for this date in the shared log list.
	local nodeExisting = nil;
	for _, v in ipairs(DB.getChildList("calendar.log")) do
		if DB.getValue(v, "year", 0) == nYear
				and DB.getValue(v, "month", 0) == nMonth
				and DB.getValue(v, "day", 0) == nDay then
			nodeExisting = v;
			break;
		end
	end

	if nodeExisting then
		Interface.openWindow("advlogentry", nodeExisting);
		return;
	end

	-- No entry yet: gather author identity + color for stamping.
	local sEpoch = DB.getValue("calendar.current.epoch", "");
	local sAuthor = "";
	local sColor = "";
	local sIdentity = (User.getCurrentIdentity and User.getCurrentIdentity()) or "";
	if sIdentity ~= "" then
		sAuthor = (User.getIdentityLabel and User.getIdentityLabel(sIdentity)) or sIdentity;
		sColor = (User.getIdentityColor and User.getIdentityColor(sIdentity)) or "";
	end
	if sAuthor == "" then
		sAuthor = Session.UserName or "";
	end

	if Session.IsHost then
		local nodeEvent = KrakenCalNotes.createNote(nYear, nMonth, nDay, sEpoch, sAuthor, sColor);
		if nodeEvent then
			Interface.openWindow("advlogentry", nodeEvent);
		end
	else
		-- Player: ask the host to create it. The day marker appears when it
		-- syncs back; double-click again to open and type the note (the player owns it).
		KrakenCalNotes.requestCreate(nYear, nMonth, nDay, sEpoch, sAuthor, sColor);
	end
end
