local addon, ns = ...
local L, util, mounts = ns.L, ns.util, ns.mounts
local type, select, next, tconcat, GetServerTime, Ambiguate, UnitInRaid, UnitInParty, IsGuildMember, BNGetNumFriends = type, select, next, table.concat, GetServerTime, Ambiguate, UnitInRaid, UnitInParty, IsGuildMember, BNGetNumFriends
local C_BattleNet, AddMessageEventFilter = C_BattleNet, ChatFrameUtil.AddMessageEventFilter


local function checkApps(i, guid)
	for j = 1, C_BattleNet.GetFriendNumGameAccounts(i) do
		local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(i, j)
		if gameAccountInfo.clientProgram == "WoW" and gameAccountInfo.playerGuid == guid then
			return true
		end
	end
	return false
end


local function filterFunc(_, event, msg, player, l, cs, t, flag, channelId, ...)
	if flag == "GM" or flag == "DEV"
	or event == "CHAT_MSG_CHANNEL" and type(channelId) == "number" and channelId > 0
	then return end

	local newMsg, finish, start, newStart, id, target, dataType, anyLinkFound = "", 0
	while true do
		newStart = finish + 1
		start, finish, target, dataType, id = msg:find("%[MountsJournal:(.-):(.-):(.-):MJ%]", newStart)
		if target and dataType and id then
			newMsg = newMsg..msg:sub(newStart, start - 1)
			newMsg = newMsg..("|HMountsJournalH:%s:%s|h|cFFCC33FF[MJ:%s - %s:%s]|r|h"):format(dataType, id, target, L[dataType], id == "" and DEFAULT or id)
			anyLinkFound = true
		else
			break
		end
	end

	if anyLinkFound then
		newMsg = newMsg..msg:sub(newStart)
		local trimmedPlayer = Ambiguate(player, "none")
		local guid = select(5, ...)
		if event == "CHAT_MSG_WHISPER" and not (UnitInRaid(trimmedPlayer) or UnitInParty(trimmedPlayer) or IsGuildMember(guid)) then
			local _, numOline, fNum, fNumOline = BNGetNumFriends()
			for i = 1, fNumOline do
				if checkApps(i, guid) then
					return false, newMsg, player, l, cs, t, flag, channelId, ...
				end
			end
			for i = fNum + 1, fNum + numOline - fNumOline do
				if checkApps(i, guid) then
					return false, newMsg, player, l, cs, t, flag, channelId, ...
				end
			end
			return true
		else
			return false, newMsg, player, l, cs, t, flag, channelId, ...
		end
	end
end


AddMessageEventFilter("CHAT_MSG_CHANNEL", filterFunc)
AddMessageEventFilter("CHAT_MSG_YELL", filterFunc)
AddMessageEventFilter("CHAT_MSG_GUILD", filterFunc)
AddMessageEventFilter("CHAT_MSG_OFFICER", filterFunc)
AddMessageEventFilter("CHAT_MSG_PARTY", filterFunc)
AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", filterFunc)
AddMessageEventFilter("CHAT_MSG_RAID", filterFunc)
AddMessageEventFilter("CHAT_MSG_RAID_LEADER", filterFunc)
AddMessageEventFilter("CHAT_MSG_SAY", filterFunc)
AddMessageEventFilter("CHAT_MSG_WHISPER", filterFunc)
AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", filterFunc)
AddMessageEventFilter("CHAT_MSG_BN_WHISPER", filterFunc)
AddMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", filterFunc)
AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", filterFunc)
AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", filterFunc)


-- TEST
-- C_Timer.After(0, function()
-- 	C_ChatInfo.SendChatMessage(util.getLink("Profile", "").." "..util.getLink("Profile", next(mounts.profiles), nil), "WHISPER", select(2, GetDefaultLanguage()), UnitName("player"))
-- 	C_ChatInfo.SendChatMessage(util.getLink("Snippet", next(mounts.globalDB.snippets), nil), "WHISPER", select(2, GetDefaultLanguage()), UnitName("player"))
-- 	C_ChatInfo.SendChatMessage(util.getLink("Rule Set", mounts.globalDB.ruleSets[1].name), "WHISPER", select(2, GetDefaultLanguage()), UnitName("player"))
-- 	C_ChatInfo.SendChatMessage(util.getLink("Rule", "1:1:"..mounts.globalDB.ruleSets[1].name), "WHISPER", select(2, GetDefaultLanguage()), UnitName("player"))
-- end)


-- COMM
local CTL = assert(ChatThrottleLib, "Requires ChatThrottleLib")
local comm = CreateFrame("FRAME")
comm:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
comm:RegisterEvent("CHAT_MSG_ADDON")
comm.pool = {}


function comm:registerPrefix(prefix, func)
	self[prefix] = func
	C_ChatInfo.RegisterAddonMessagePrefix(prefix)
end


function comm:sendMessage(prefix, message, chattype, target, prio, cb, arg)
	local queueName = prefix
	local maxLen = 255
	local len = #message
	local func = cb and function(sent, sendResult) cb(arg, sent, len, sendResult) end

	local force
	if message:match("^[\001-\004]") then
		if len + 1 <= maxLen then
			message = "\004"..message
		else
			force = true
		end
	end

	if len <= maxLen and not force then
		CTL:SendAddonMessage(prio, prefix, message, chattype, target, queueName, func, len)
	else
		maxLen = maxLen - 1
		local chunk = "\001"..message:sub(1, maxLen)
		CTL:SendAddonMessage(prio, prefix, chunk, chattype, target, queueName, func, maxLen)

		local pos = 1 + maxLen
		while pos + maxLen <= len do
			chunk = "\002"..message:sub(pos, pos + maxLen - 1)
			CTL:SendAddonMessage(prio, prefix, chunk, chattype, target, queueName, func, pos + maxLen - 1)
			pos = pos + maxLen
		end

		chunk = "\003"..message:sub(pos)
		CTL:SendAddonMessage(prio, prefix, chunk, chattype, target, queueName, func, len)
	end
end


function comm:CHAT_MSG_ADDON(prefix, message, chattype, sender)
	if not self[prefix] then return end
	sender = Ambiguate(sender, "none")
	local control, text = message:match("^([\001-\004])(.*)")

	if control then
		if control == "\004" then
			self[prefix](text, chattype, sender)
			return
		end

		local st = GetServerTime()
		for k, v in next, self.pool do
			if st - v.st > 300 then
				self.pool[k] = nil
			end
		end

		local k = prefix.."\000"..chattype.."\000"..sender

		if control == "\001" then
			self.pool[k] = {text, st = st}
		elseif control == "\002" then
			local t = self.pool[k]
			if t then t[#t+1] = text end
		elseif control == "\003" then
			local t = self.pool[k]
			if t then
				self.pool[k] = nil
				t[#t+1] = text
				self[prefix](tconcat(t, ""), chattype, sender)
			end
		end
	else
		self[prefix](message, chattype, sender)
	end
end


-- TOOLTIP
local function showTooltip(lines)
	if not ItemRefTooltip:IsShown() then
		ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
	end
	ItemRefTooltip:ClearLines()
	ItemRefTooltip:AddLine(addon, .8,.2,1)
	for i, line in ipairs(lines) do
		local sides, a1, a2, a3, a4, a5, a6, a7, a8 = unpack(line)
		if sides == 1 then
			ItemRefTooltip:AddLine(a1, a2, a3, a4, a5)
		elseif sides == 2 then
			ItemRefTooltip:AddDoubleLine(a1, a2, a3, a4, a5, a6, a7, a8)
		end
	end
	ItemRefTooltip:SetPadding(0, 0)
	ItemRefTooltip:Show()
end


-- DATA TRANSFER
local tooltipLoading, receivedData


local function requestData(target, dataType, id)
	local transmitString = util.getStringFromData({m = "dr", t = dataType, id = id})
	comm:sendMessage(addon, transmitString, "WHISPER", target, "NORMAL")
end


do
	local timer
	LinkUtil.RegisterLinkHandler("MountsJournalH", function(link, text, linkData, contextData)
		local _,_, dataType, id, target = text:gsub("|[Cc]%x%x%x%x%x%x%x%x", ""):gsub("|[Rr]", ""):find("|HMountsJournalH:(.-):(.-)|h%[MJ:(.-) %- .-%]|h")
		if dataType and id and target then
			id = util.deobfuscateName(id)
			if IsShiftKeyDown() then
				util.insertChatLink(dataType, id, target)
			else
				target = util.deobfuscateName(target)
				local r,g,b = NIGHT_FAE_BLUE_COLOR:GetRGB()
				local displayID = id == "" and DEFAULT or id
				showTooltip({
					{2, L[dataType], displayID, 1,1,1,r,g,b},
					{1, L["Requesting data from %s ..."]:format(target), 1,.8,0},
				})
				tooltipLoading = true
				receivedData = false
				requestData(target, dataType, id)

				if timer and not timer:IsCancelled() then timer:Cancel() end
				timer = C_Timer.NewTicker(5, function()
					if tooltipLoading and not receivedData and ItemRefTooltip:IsShown() then
						showTooltip({
							{2, L[dataType], displayID, 1,1,1,r,g,b},
							{1, L["Error not receiving data from %s ..."]:format(target), 1,0,0},
						})
					end
				end, 1)
			end
		else
			showTooltip({{1, L["Malformed link"], 1,0,0}})
		end
	end)
end


local function getTransmitData(data)
	local toTransmit
	if data.t == "Profile" then
		toTransmit = data.id == "" and mounts.defProfile or mounts.profiles[data.id]
	elseif data.t == "Rule Set" then
		for i, ruleSet in ipairs(mounts.globalDB.ruleSets) do
			if ruleSet.name == data.id then
				toTransmit = util:copyTable(ruleSet)
				toTransmit.name = nil
				toTransmit.isDefault = nil
				break
			end
		end
	elseif data.t == "Rule" then
		local summonN, path, rsName = (":"):split(data.id, 3)
		summonN = tonumber(summonN)
		if not (summonN and path and rsName) then return end
		for i, ruleSet in ipairs(mounts.globalDB.ruleSets) do
			if ruleSet.name == rsName then
				local rules, rule = ruleSet[summonN]
				for i, order in ipairs({(">"):split(path)}) do
					if rules then
						rule = rules[tonumber(order)]
						rules = rule and rule.rules
					else
						rule = nil
						break
					end
				end
				toTransmit = rule
				break
			end
		end
	elseif data.t == "Snippet" then
		toTransmit = mounts.globalDB.snippets[data.id]
	end
	return toTransmit and util.getStringFromData({m = "d", t = data.t, id = data.id, d = toTransmit})
end


local function dataImport(dataType, id, data, sender)
	if InCombatLockdown() then
		local r,g,b = NIGHT_FAE_BLUE_COLOR:GetRGB()
		showTooltip({
			{2, L[dataType], id == "" and DEFAULT or id, 1,1,1,r,g,b},
			{1, ERR_NOT_IN_COMBAT, 1,0,0}
		})
		comm.PLAYER_REGEN_ENABLED = function(self)
			self:UnregisterEvent("PLAYER_REGEN_ENABLED")
			self.PLAYER_REGEN_ENABLED = nil
			dataImport(dataType, id, data, sender)
		end
		comm:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	ItemRefTooltip:Hide()

	if dataType == "Profile" then
		if type(data) ~= "table" then return end
		util.openJournalTab(3)
		ns.journal.bgFrame.profilesMenu:dataImport(data, id, sender)
	elseif dataType == "Rule Set" then
		if type(data) ~= "table" then return end
		util.openJournalTab(1, 3)
		ns.ruleConfig:dataImportRuleSet(data, id, sender)
	elseif dataType == "Rule" then
		if type(data) ~= "table" then return end
		util.openJournalTab(1, 3)
		ns.ruleConfig:dataImportRule(data, id, sender)
	elseif dataType == "Snippet" then
		if type(data) ~= "string" then return end
		util.openJournalTab(1, 3)
		if not ns.ruleConfig.snippetToggle:GetChecked() then ns.ruleConfig.snippetToggle:Click() end
		ns.snippets:dataImport(data, id, sender)
	end
end


local function transmitData(data, target)
	local encoded = getTransmitData(data)
	if encoded then
		comm:sendMessage(addon, encoded, "WHISPER", target, "BULK", function(id, done, total)
			comm:sendMessage(addon.."P", done.." "..total.." "..id, "WHISPER", target, "ALERT")
		end, data.t..":"..data.id)
	end
end


local function handleComm(message, chattype, sender)
	local data = util.getDataFromString(message)
	if type(data) == "table" and data.m and data.t and data.id then
		if data.m == "d" then
			tooltipLoading = nil
			if data.d then
				dataImport(data.t, data.id, data.d, sender)
			else
				showTooltip({{1, L["Transmission error"], 1,0,0}})
			end
		elseif data.m == "dr" then
			if util.isLinkValid(data.t, data.id) then transmitData(data, sender) end
		end
	end
end


local function handleProgressComm(message, chattype, sender)
	if tooltipLoading and ItemRefTooltip:IsShown() then
		receivedData = true
		local done, total, id = (" "):split(message, 3)
		local dataType, dataID = (":"):split(id, 2)
		done = tonumber(done)
		total = tonumber(total)
		if done and total and dataType and dataID and total >= done then
			local red = min(255, (1 - done / total) * 510)
			local green = min(255, (done / total) * 510)
			local r,g,b = NIGHT_FAE_BLUE_COLOR:GetRGB()
			showTooltip({
				{2, L[dataType], dataID == "" and DEFAULT or dataID, 1,1,1,r,g,b},
				{1, L["Receiving data from %s"]:format(sender), 1,.8,0},
				{2, " ", ("|cFF%2x%2x00%d|cFF00FF00/%d"):format(red, green, done, total)}
			})
		end
	end
end


comm:registerPrefix(addon, handleComm)
comm:registerPrefix(addon.."P", handleProgressComm)
