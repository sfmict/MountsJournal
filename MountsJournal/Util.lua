local addon, ns = ...
local L = ns.L
local type, tremove, next, tostring, math = type, tremove, next, tostring, math
local C_MountJournal, C_UnitAuras, UnitExists, IsInRaid, IsInGroup, IsSpellKnown, IsSpellInSpellBook, IsMounted = C_MountJournal, C_UnitAuras, UnitExists, IsInRaid, IsInGroup, C_SpellBook.IsSpellKnown, C_SpellBook.IsSpellInSpellBook, IsMounted
local events, eventsMixin, dot = {}, {}, "."


function eventsMixin:on(event, func)
	if type(event) ~= "string" or type(func) ~= "function" then return self end
	local event, name = dot:split(event, 2)

	local handlerList = events[event]
	if not handlerList then
		handlerList = {}
		events[event] = handlerList
	end

	local k = tostring(self)..(name or tostring(func))
	if handlerList[k] then
		for i = #handlerList, 1, -1 do
			if handlerList[i] == handlerList[k] then
				tremove(handlerList, i)
				break
			end
		end
	end

	local handler = function(...) func(self, ...) end
	handlerList[#handlerList + 1] = handler
	handlerList[k] = handler
	return self
end


function eventsMixin:off(event, func)
	if type(event) ~= "string" then return self end
	local event, name = dot:split(event, 2)

	local handlerList = events[event]
	if handlerList then
		if name or func then
			local k = tostring(self)..(name or tostring(func))
			local handler = handlerList[k]
			if handler then
				for i = #handlerList, 1, -1 do
					if handlerList[i] == handler then
						tremove(handlerList, i)
						break
					end
				end
				handlerList[k] = nil
				if #handlerList == 0 then
					events[event] = nil
				end
			end
		else
			events[event] = nil
		end
	end
	return self
end


function eventsMixin:event(event, ...)
	local handlerList = events[event]
	if handlerList then
		for i = 1, #handlerList do
			handlerList[i](...)
		end
	end
	return self
end


local util = {}
MountsJournalUtil = util
ns.util = util
util.addonName = ("%s_ADDON_"):format(addon:upper())
util.expansion = tonumber(GetBuildInfo():match("(.-)%."))
util.secureButtonNameMount = addon.."_Mount"
util.secureButtonNameSecondMount = addon.."_SecondMount"


-- 1 FLY, 2 GROUND, 3 SWIMMING
util.mountTypes = setmetatable({
	[242] = 1,
	[247] = 1,
	[402] = 1,
	[407] = {1, 3},
	[411] = 1,
	[424] = 1,
	[426] = 1,
	[430] = 1,
	[436] = {1, 3},
	[437] = 1,
	[442] = 1,
	[444] = 1,
	[445] = 1,
	[446] = 1,
	[447] = 1,
	[230] = 2,
	[241] = 2,
	[284] = 2,
	[408] = 2,
	[412] = {2, 3},
	[231] = 3,
	[232] = 3,
	[254] = 3,
}, {
	__index = function(self, key)
		if type(key) == "number" then
			self[key] = 1
			return self[key]
		end
	end
})


function util.setMixin(obj, mixin)
	for k, v in next, mixin do
		obj[k] = v
	end
	return obj
end


function util.createFromEventsMixin()
	return util.setMixin({}, eventsMixin)
end


function util.setEventsMixin(frame)
	return util.setMixin(frame, eventsMixin)
end


function util.getMapFullNameInfo(mapID)
	local mapInfo = C_Map.GetMapInfo(mapID)

	local mapGroupID = C_Map.GetMapGroupID(mapID)
	if mapGroupID then
		local mapGroupInfo = C_Map.GetMapGroupMembersInfo(mapGroupID)
		if mapGroupInfo then
			for _, mapGroupMemberInfo in ipairs(mapGroupInfo) do
				if mapGroupMemberInfo.mapID == mapID then
					mapInfo.name = ("%s (%s)"):format(mapInfo.name, mapGroupMemberInfo.name)
					break
				end
			end
		end
	end

	return mapInfo
end


function util:copyTable(t)
	local n = {}
	for k, v in next, t do
		n[k] = type(v) == "table" and self:copyTable(v) or v
	end
	return n
end


function util.getGroupType()
	return IsInRaid() and "raid" or IsInGroup() and "group"
end


function util.getMountInfo(mount)
	-- name, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, _, isForDragonriding
	if type(mount) == "number" then
		return C_MountJournal.GetMountInfoByID(mount)
	else
		return mount.name, mount.spellID, mount.icon, mount:isActive(), mount:isUsable(), 0, mount:getIsFavorite(), false, nil, not mount.isShown, mount:isCollected()
	end
end


function util.checkAura(unit, spellID, filter)
	if not UnitExists(unit) then return end
	local GetAuraSlots, GetAuraDataBySlot, ctok, a,b,c,d,e = C_UnitAuras.GetAuraSlots, C_UnitAuras.GetAuraDataBySlot
	repeat
		ctok, a,b,c,d,e = GetAuraSlots(unit, filter, 5, ctok)
		while a do
			local auraID = GetAuraDataBySlot(unit, a).spellId
			if not issecretvalue(auraID) and auraID == spellID then return true end
			a,b,c,d,e = b,c,d,e
		end
	until not ctok
	return false
end


function util.getUnitMount(unit)
	if not UnitExists(unit) or C_Secrets.ShouldAurasBeSecret() then return end
	local GetAuraSlots, GetAuraDataBySlot, ctok, a,b,c,d,e = C_UnitAuras.GetAuraSlots, C_UnitAuras.GetAuraDataBySlot
	local filter = unit == "player" and "HELPFUL PLAYER" or "HELPFUL"
	repeat
		ctok, a,b,c,d,e = GetAuraSlots(unit, filter, 5, ctok)
		while a do
			local data = GetAuraDataBySlot(unit, a)
			if ns.additionalMountBuffs[data.spellId] then
				return ns.additionalMountBuffs[data.spellId].spellID, nil, data.auraInstanceID
			else
				local mountID = C_MountJournal.GetMountFromSpell(data.spellId)
				if mountID then return data.spellId, mountID, data.auraInstanceID end
			end
			a,b,c,d,e = b,c,d,e
		end
	until not ctok
end


function util.isMounted()
	return ns.mounts.trackableID ~= nil or IsMounted()
end


function util.getRarityColor(mountID)
	local rarity = ns.mountsDB[mountID][3]
	if rarity > 50 then
		return ITEM_QUALITY_COLORS[1].color
	elseif rarity > 20 then
		return ITEM_QUALITY_COLORS[2].color
	elseif rarity > 10 then
		return ITEM_QUALITY_COLORS[3].color
	elseif rarity > 1 then
		return ITEM_QUALITY_COLORS[4].color
	else
		return ITEM_QUALITY_COLORS[5].color
	end
end


do
	local libSerialize = LibStub("LibSerialize")
	local libDeflate = LibStub("LibDeflate")
	local compressedCache

	function util.getStringFromData(data, forPrint, config)
		local serialized = libSerialize:Serialize(data)
		local serverTime, compressed = GetServerTime()
		compressedCache = compressedCache or {}

		-- get from / add to cache
		if compressedCache[serialized] then
			compressed = compressedCache[serialized].compressed
			compressedCache[serialized].lastAccess = serverTime
		else
			compressed = libDeflate:CompressDeflate(serialized, config)
			compressedCache[serialized] = {
				compressed = compressed,
				lastAccess = serverTime,
			}
		end

		-- remove cache after 5 min
		local expiredTime = serverTime - 300
		for k, v in next, compressedCache do
			if v.lastAccess < expiredTime then compressedCache[k] = nil end
		end

		if forPrint then
			return libDeflate:EncodeForPrint(compressed)
		else
			return libDeflate:EncodeForWoWAddonChannel(compressed)
		end
	end

	function util.getDataFromString(str, fromPrint)
		local decoded
		if fromPrint then
			decoded = libDeflate:DecodeForPrint(str)
		else
			decoded = libDeflate:DecodeForWoWAddonChannel(str)
		end
		if not decoded then return end
		local decompressed = libDeflate:DecompressDeflate(decoded)
		if not decompressed then return end
		local success, data = libSerialize:Deserialize(decompressed)
		if success then return data end
	end
end


-- WORKAROUND
-- Blizzard in its infinite wisdom did:
-- * Force enable the profanity filter for the chinese region
-- * Add a realm name's part to the profanity filter
function util.obfuscateName(name)
	if GetCurrentRegion() == 5 then
		local result = string.char(name:byte(1))
		for i = 2, #name do
			local b = name:byte(i)
			if b >= 196 then
				-- UTF8 Start byte
				result = result..string.char(46, b)
			else
				result = result..string.char(b)
			end
		end
		return result
	else
		return name
	end
end


function util.deobfuscateName(name)
	if GetCurrentRegion() == 5 then
		local result = ""
		local i = #name
		while i > 1 do
			local b = name:byte(i)
			if b >= 196 and name:byte(i - 1) == 46 then
				i = i - 1
			end
			result = string.char(b)..result
			i = i - 1
		end
		return string.char(name:byte(1))..result
	else
		return name
	end
end


do
	local fullName
	local function getFullName()
		local name, realm = UnitFullName("player")
		fullName = realm and name.."-"..util.obfuscateName(realm) or name
		return fullName
	end

	local linked
	function util.getLink(dataType, id, characterName)
		local playerName = fullName or getFullName()
		if not characterName or playerName == characterName then
			linked = linked or {}
			linked[dataType..":"..id] = GetServerTime()
		end
		return ("[MountsJournal:%s:%s:%s:MJ]"):format(characterName or playerName, dataType, util.obfuscateName(id))
	end

	function util.isLinkValid(dataType, id)
		if not linked then return false end
		local expiredLinkTime = GetServerTime() - 300
		for linkID, time in next, linked do
			if time < expiredLinkTime then linked[linkID] = nil end
		end
		return not not linked[dataType..":"..id]
	end
end


function util.insertChatLink(...)
	local editBox = ChatEdit_GetActiveWindow() or GetCurrentKeyBoardFocus()
	if editBox then
		editBox:Insert(util.getLink(...))
		editBox:SetFocus()
	end
end


function util.openJournalTab(tab1, tab2)
	if InCombatLockdown() then return end
	if not C_AddOns.IsAddOnLoaded("Blizzard_Collections") then
		C_AddOns.LoadAddOn("Blizzard_Collections")
	end
	ShowUIPanel(CollectionsJournal)
	CollectionsJournal_SetTab(CollectionsJournal, COLLECTIONS_JOURNAL_TAB_INDEX_MOUNTS)
	if ns.mounts.config.useDefaultJournal then
		if ns.journal.useMountsJournalButton:IsProtected() then
			ns.journal._s:SetAttribute("useDefaultJournal", false)
			ns.journal._s:Execute(ns.journal._s:GetAttribute("update"))
		end
		ns.journal.useMountsJournalButton:Click()
	end
	ns.journal.bgFrame.setTab(tab1)
	ns.journal._s:SetAttribute("tab", tab1)
	ns.journal._s:Execute(ns.journal._s:GetAttribute("tabUpdate"))
	if tab1 == 1 and tab2 then
		ns.journal.bgFrame.settingsBackground.Tabs[tab2]:Click()
	end
end


do
	local bankPlayer = Enum.SpellBookSpellBank.Player
	local bankPet = Enum.SpellBookSpellBank.Pet

	function util.isPlayerSpell(spellID)
		return IsSpellKnown(spellID, bankPlayer)
	end

	function util.isSpellKnown(spellID, isPet)
		return IsSpellInSpellBook(spellID, isPet and bankPet or bankPlayer, false)
	end
end


do
	local ABBR_YARD = " "..L["ABBR_YARD"]
	local ABBR_MILE = " "..L["ABBR_MILE"]
	function util.getImperialFormat(distance)
		if distance < 1760 then
			return math.floor(distance)..ABBR_YARD
		elseif distance < 176e4 then
			return (math.floor(distance / 176) / 10)..ABBR_MILE
		end
		return math.floor(distance / 1760)..ABBR_MILE
	end
end


do
	local ABBR_METER = " "..L["ABBR_METER"]
	local ABBR_KILOMETER = " "..L["ABBR_KILOMETER"]
	function util.getMetricFormat(distance)
		distance = distance * .9144
		if distance < 1e3 then
			return math.floor(distance)..ABBR_METER
		elseif distance < 1e6 then
			return (math.floor(distance / 100) / 10)..ABBR_KILOMETER
		end
		return math.floor(distance / 1e3)..ABBR_KILOMETER
	end
end


do
	local text = "%s/"..L["ABBR_HOUR"]
	local redText = "|cffee2222"..text
	local speedFormat = GetLocale() ~= "enUS" and util.getMetricFormat or util.getImperialFormat
	function util.getFormattedSpeed(speed, noThrill)
		return (noThrill and redText or text):format(speedFormat(speed * 3600))
	end
end


function util.doEmote(...)
	if ns.mounts.stState == 0 and not GetCVarBool("addonChatRestrictionsForced") then
		C_ChatInfo.PerformEmote(...)
	end
end
