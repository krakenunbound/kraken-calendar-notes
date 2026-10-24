--
-- Kraken Calendar Notes - global manager.
--
-- Bridges player-created calendar notes to the host. Players cannot create
-- nodes under the GM-owned calendar.log list directly, so a player's request
-- is sent to the host via an OOB message; the host creates the shared log
-- entry and stamps it with the requesting player's name and color. The entry
-- then syncs back to everyone (the day marker appears on all clients).
--

local OOB_CREATE = "kcn_create";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_CREATE, handleCreate);
end

function onTabletopInit()
	local bridge = AgentBridge or ClaudeBridge;
	if Session.IsHost and bridge and bridge.registerPackage then
		bridge.registerPackage("KrakenCalNotes", KrakenCalNotes);
	end
end

-- Called on a player client: ask the host to create a note for this date.
function requestCreate(nYear, nMonth, nDay, sEpoch, sAuthor, sColor)
	local msg = {
		type = OOB_CREATE,
		syear = tostring(nYear or 0),
		smonth = tostring(nMonth or 0),
		sday = tostring(nDay or 0),
		sepoch = sEpoch or "",
		sUser = sAuthor or "",
		scolor = sColor or "",
		sowner = Session.UserName or "",
	};
	Comm.deliverOOBMessage(msg, "");
end

-- Host-side OOB handler.
function handleCreate(msgOOB)
	if not Session.IsHost then
		return;
	end
	local nYear = tonumber(msgOOB.syear) or 0;
	local nMonth = tonumber(msgOOB.smonth) or 0;
	local nDay = tonumber(msgOOB.sday) or 0;
	if nMonth <= 0 or nDay <= 0 then
		return;
	end
	local nodeEvent = createNote(nYear, nMonth, nDay, msgOOB.sepoch, msgOOB.sUser, msgOOB.scolor);
	-- 0.2: the player owns the note, so they can write in it
	if nodeEvent and (msgOOB.sowner or "") ~= "" then
		DB.setOwner(nodeEvent, msgOOB.sowner);
	end
end

-- Create a calendar.log entry (host context only). Returns the new node or nil.
function createNote(nYear, nMonth, nDay, sEpoch, sAuthor, sColor)
	local nodeLog = DB.createNode("calendar.log");
	if not nodeLog then
		return nil;
	end
	local nodeEvent = DB.createChild(nodeLog);
	if not nodeEvent then
		return nil;
	end

	DB.setValue(nodeEvent, "epoch", "string", sEpoch or "");
	DB.setValue(nodeEvent, "year", "number", nYear or 0);
	DB.setValue(nodeEvent, "month", "number", nMonth or 0);
	DB.setValue(nodeEvent, "day", "number", nDay or 0);
	if (sAuthor or "") ~= "" then
		DB.setValue(nodeEvent, "author", "string", sAuthor);
	end
	if (sColor or "") ~= "" then
		DB.setValue(nodeEvent, "authorcolor", "string", sColor);
	end

	return nodeEvent;
end
