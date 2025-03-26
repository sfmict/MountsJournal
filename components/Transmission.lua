local addon, ns = ...
local L, util, mounts = ns.L, ns.util, ns.mounts
local type, select, Ambiguate, UnitInRaid, UnitInParty, IsGuildMember, BNGetNumFriends, C_BattleNet = type, select, Ambiguate, UnitInRaid, UnitInParty, IsGuildMember, BNGetNumFriends, C_BattleNet


local function filterFunc(_, event, msg, player, l, cs, t, flag, channelId, ...)
	if flag == "GM" or flag == "DEV"
	or event == "CHAT_MSG_CHANNEL" and type(channelId) == "number" and channelId > 0
	then return end

	local newMsg, finish, start, newStart, type, id, anyLinkFound = "", 0
	while true do
		newStart = finish + 1
		start, finish, characterName, dataType, id = msg:find("%[MountsJournal:(.-):(.-):(.-):MJ%]", newStart)
		if characterName and dataType and id then
			newMsg = newMsg..msg:sub(newStart, start - 1)
			newMsg = newMsg..("|HaddonMountsJournal%s|h|cFFCC33FF[MJ:%s - %s:%s]|r|h"):format(dataType, characterName, L[dataType], id)
			anyLinkFound = true
		else
			break
		end
	end

	if anyLinkFound then
		newMsg = newMsg..msg:sub(newStart)
		local trimmedPlayer = Ambiguate(player, "none")
		if event == "CHAT_MSG_WHISPER" and not (UnitInRaid(trimmedPlayer) or UnitInParty(trimmedPlayer) or IsGuildMember(select(5, ...))) then
			local _, num = BNGetNumFriends()
			for i = 1, num do
				for j = 1, C_BattleNet.GetFriendNumGameAccounts(i) do
					local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(i, j)
					if gameAccountInfo.characterName == trimmedPlayer and gameAccountInfo.clientProgram == "WoW" then
						return false, newMsg, player, l, cs, t, flag, channelId, ...
					end
				end
			end
			return true
		else
			return false, newMsg, player, l, cs, t, flag, channelId, ...
		end
	end
end


ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", filterFunc)


-- TEST
--C_Timer.After(0, function()
--	SendChatMessage(util.getLink("Profile", "").." "..util.getLink("Profile", next(mounts.profiles), nil), "WHISPER", select(2, GetDefaultLanguage()), UnitName("player"))
--	SendChatMessage(util.getLink("Snippet", next(mounts.globalDB.snippets), nil), "WHISPER", select(2, GetDefaultLanguage()), UnitName("player"))
--	SendChatMessage(util.getLink("Rule Set", mounts.globalDB.ruleSets[1].name), "WHISPER", select(2, GetDefaultLanguage()), UnitName("player"))
--	SendChatMessage(util.getLink("Rule", "1:1:"..mounts.globalDB.ruleSets[1].name), "WHISPER", select(2, GetDefaultLanguage()), UnitName("player"))
--end)


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


-- RECEIVING DATA
local comm = LibStub("AceComm-3.0")
local delayedImport = CreateFrame("FRAME")
local deflateConfig = {level = 9}
local tooltipLoading, receivedData


local function requestData(characterName, dataType, id)
	local transmitString = util.getStringFromData({m = "dr", t = dataType, id = id}, nil, deflateConfig)
	comm:SendCommMessage(addon, transmitString, "WHISPER", characterName)
end


do
	local timer
	EventRegistry:RegisterCallback("SetItemRef", function(_, link, text)
		if link:sub(1, 18) == "addonMountsJournal" then
			local _,_, dataType, characterName, typeLang, id = text:gsub("|[Cc]%x%x%x%x%x%x%x%x", ""):gsub("|[Rr]", ""):find("|HaddonMountsJournal(.-)|h%[MJ:(.-) %- (.-):(.-)%]|h")
			if dataType and characterName and typeLang and id then
				id = util.deobfuscateName(id)
				if IsShiftKeyDown() then
					util.insertChatLink(dataType, id, characterName)
				else
					characterName = util.deobfuscateName(characterName)
					local r,g,b = NIGHT_FAE_BLUE_COLOR:GetRGB()
					local displayID = id == "" and DEFAULT or id
					showTooltip({
						{2, typeLang, displayID, 1,1,1,r,g,b},
						{1, L["Requesting data from %s ..."]:format(characterName), 1,.8,0},
					})
					tooltipLoading = true
					receivedData = false
					requestData(characterName, dataType, id)

					if timer and not timer:IsCancelled() then timer:Cancel() end
					timer = C_Timer.NewTicker(5, function()
						if tooltipLoading and not receivedData and ItemRefTooltip:IsShown() then
							showTooltip({
								{2, typeLang, displayID, 1,1,1,r,g,b},
								{1, L["Error not receiving data from %s ..."]:format(characterName), 1,0,0},
							})
						end
					end, 1)
				end
			else
				showTooltip({{1, L["Malformed link"], 1,0,0}})
			end
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
		local summonN, index, rsName = (":"):split(data.id, 3)
		summonN = tonumber(summonN)
		index = tonumber(index)
		if not (summonN and index and rsName) then return end
		for i, ruleSet in ipairs(mounts.globalDB.ruleSets) do
			if ruleSet.name == rsName then
				local rules = ruleSet[summonN]
				if rules then
					toTransmit = rules[index]
				end
				break
			end
		end
	elseif data.t == "Snippet" then
		toTransmit = mounts.globalDB.snippets[data.id]
	end
	return toTransmit and util.getStringFromData({m = "d", t = data.t, id = data.id, d = toTransmit}, nil, deflateConfig)
end


local function dataImport(dataType, id, data, characterName)
	if InCombatLockdown() then
		local r,g,b = NIGHT_FAE_BLUE_COLOR:GetRGB()
		showTooltip({
			{2, L[dataType], id == "" and DEFAULT or id, 1,1,1,r,g,b},
			{1, ERR_NOT_IN_COMBAT, 1,0,0}
		})
		delayedImport:SetScript("OnEvent", function()
			delayedImport:UnregisterEvent("PLAYER_REGEN_ENABLED")
			dataImport(dataType, id, data, characterName)
		end)
		delayedImport:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	ItemRefTooltip:Hide()

	if dataType == "Profile" then
		if type(data) ~= "table" then return end
		util.openJournalTab(3)
		ns.journal.bgFrame.profilesMenu:dataImport(data, id, characterName)
	elseif dataType == "Rule Set" then
		if type(data) ~= "table" then return end
		util.openJournalTab(1, 3)
		ns.ruleConfig:dataImportRuleSet(data, id, characterName)
	elseif dataType == "Rule" then
		if type(data) ~= "table" then return end
		util.openJournalTab(1, 3)
		ns.ruleConfig:dataImportRule(data, id, characterName)
	elseif dataType == "Snippet" then
		if type(data) ~= "string" then return end
		util.openJournalTab(1, 3)
		if not ns.ruleConfig.snippetToggle:GetChecked() then ns.ruleConfig.snippetToggle:Click() end
		ns.snippets:dataImport(data, id, characterName)
	end
end


local function transmitData(data, characterName)
	local encoded = getTransmitData(data)
	if encoded then
		comm:SendCommMessage(addon, encoded, "WHISPER", characterName, "BULK", function(id, done, total)
			comm:SendCommMessage(addon.."P", done.." "..total.." "..id, "WHISPER", characterName, "ALERT")
		end, data.t..":"..data.id)
	end
end


local function handleComm(prefix, message, distribution, sender)
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


local function handleProgressComm(prefix, message, distribution, sender)
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


comm:RegisterComm(addon, handleComm)
comm:RegisterComm(addon.."P", handleProgressComm)