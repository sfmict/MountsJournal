local _, ns = ...
local type, concat, strconcat, C_Secrets = type, table.concat, string.concat, C_Secrets
local UnitClass, UnitRace, GetNumSpecializations, GetSpecializationInfo, GetDynamicFlightModeSpellID, Traits_GetConfigInfo = UnitClass, UnitRace, GetNumSpecializations, C_SpecializationInfo.GetSpecializationInfo, C_MountJournal.GetDynamicFlightModeSpellID, C_Traits.GetConfigInfo
local GetSpellAuraSecrecy, GetSpellCooldownSecrecy = C_Secrets.GetSpellAuraSecrecy, C_Secrets.GetSpellCooldownSecrecy
local playerGuid = UnitGUID("player")
local conds = {}
ns.conditions = conds


local function getTableString(values, isNumeric, curValue, addKey, ...)
	if type(values) == "table" then
		local var = ("_"):join("var", ...)
		if isNumeric then
			addKey(strconcat("local ", var, " = {[", concat(values, "]=true,["), "]=true}"))
		else
			addKey(strconcat("local ", var, " = {['", concat(values, "']=true,['"), "']=true}"))
		end
		return ("%s[%s]"):format(var, curValue)
	else
		if isNumeric then
			return ("(%s == %s)"):format(curValue, values)
		else
			return ("(%s == '%s')"):format(curValue, values)
		end
	end
end


local function getFuncString(values, funcStr, addKey, ...)
	local var = ("_"):join("var", ...)
	addKey(strconcat("local ", var, " = {", concat(values, ","), "}"))
	return funcStr:format(var)
end


---------------------------------------------------
-- mod MODIFIER
conds.mod = {}

function conds.mod:getFuncString(value, addKey)
	if value == "any" then
		addKey("local IsModifierKeyDown = IsModifierKeyDown")
		return "IsModifierKeyDown()"
	elseif value == "alt" then
		addKey("local IsAltKeyDown = IsAltKeyDown")
		return "IsAltKeyDown()"
	elseif value == "ctrl" then
		addKey("local IsControlKeyDown = IsControlKeyDown")
		return "IsControlKeyDown()"
	elseif value == "shift" then
		addKey("local IsShiftKeyDown = IsShiftKeyDown")
		return "IsShiftKeyDown()"
	elseif value == "lalt" then
		addKey("local IsLeftAltKeyDown = IsLeftAltKeyDown")
		return "IsLeftAltKeyDown()"
	elseif value == "ralt" then
		addKey("local IsRightAltKeyDown = IsRightAltKeyDown")
		return "IsRightAltKeyDown()"
	elseif value == "lctrl" then
		addKey("local IsLeftControlKeyDown = IsLeftControlKeyDown")
		return "IsLeftControlKeyDown()"
	elseif value == "rctrl" then
		addKey("local IsRightControlKeyDown = IsRightControlKeyDown")
		return "IsRightControlKeyDown()"
	elseif value == "lshift" then
		addKey("local IsLeftShiftKeyDown = IsLeftShiftKeyDown")
		return "IsLeftShiftKeyDown()"
	elseif value == "rshift" then
		addKey("local IsRightShiftKeyDown = IsRightShiftKeyDown")
		return "IsRightShiftKeyDown()"
	else
		return "false"
	end
end

function conds.mod:getFuncText(values, addKey)
	if type(values) == "table" then
		local funcs = {}
		for i = 1, #values do
			funcs[i] = self:getFuncString(values[i], addKey)
		end
		return strconcat("(", concat(funcs, " or "), ")")
	end
	return self:getFuncString(values, addKey)
end


---------------------------------------------------
-- btn MOUSE BUTTON
conds.btn = {}

function conds.btn:getButtonKey(value)
	if value == 1 then
		return "LeftButton"
	elseif value == 2 then
		return "RightButton"
	elseif value == 3 then
		return "MiddleButton"
	else
		return "Button"..value
	end
end

function conds.btn:getFuncText(values, addKey, _, ...)
	local buttons
	if type(values) == "table" then
		buttons = {}
		for i = 1, #values do
			buttons[i] = self:getButtonKey(values[i])
		end
	else
		buttons = self:getButtonKey(values)
	end
	return getTableString(buttons, false, "button", addKey, ...)
end


---------------------------------------------------
-- mcond MACRO CONDITIONS
conds.mcond = {}

function conds.mcond:getFuncText(value, addKey)
	addKey("local SecureCmdOptionParse = SecureCmdOptionParse")
	return ("SecureCmdOptionParse('%s')"):format(value:gsub("['\\]", "\\%1"))
end


---------------------------------------------------
-- class
conds.class = {}

function conds.class:getFuncText(values)
	local _,_, id = UnitClass("player")
	if type(values) == "table" then
		for i = 1, #values do
			if id == values[i] then return "true" end
		end
	elseif id == values then
		return "true"
	end
	return "false"
end


---------------------------------------------------
-- spec
conds.spec = {}

function conds.spec:getFuncText(values, addKey, _, ...)
	local vals

	if type(values) == "table" then
		local num = 0
		vals = {}
		for i = 1, GetNumSpecializations() do
			local specID = GetSpecializationInfo(i)
			for j = 1, #values do
				if specID == values[j] then
					num = num + 1
					vals[num] = i
					break
				end
			end
		end
		if num == 0 then return "false"
		elseif num == 1 then vals = vals[1] end
	else
		for i = 1, GetNumSpecializations() do
			if values == GetSpecializationInfo(i) then
				vals = i
				break
			end
		end
		if vals == nil then return "false" end
	end

	addKey("local GetSpecialization = C_SpecializationInfo.GetSpecialization")
	return getTableString(vals, true, "GetSpecialization()", addKey, ...)
end


---------------------------------------------------
-- zt ZONE TYPE
conds.zt = {}

function conds.zt:getFuncText(values, addKey, _, ...)
	return getTableString(values, false, "self.mounts.instanceType", addKey, ...)
end


---------------------------------------------------
-- holiday
conds.holiday = {}

function conds.holiday:getFuncText(values, addKey, _, ...)
	if type(values) == "table" then
		return getFuncString(values, "self:anyHoldayActive(%s)", addKey, ...)
	end
	return ("self.calendar:isHolidayActive(%s)"):format(values)
end


---------------------------------------------------
-- falling
conds.falling = {}

function conds.falling:getFuncText(_, addKey)
	addKey("local IsFalling = IsFalling")
	return "IsFalling()"
end


---------------------------------------------------
-- moving
conds.moving = {}

function conds.moving:getFuncText()
	return "self:isMovingOrFalling()"
end


---------------------------------------------------
-- indoors
conds.indoors = {}

function conds.indoors:getFuncText()
	return "self.sFlags.isIndoors"
end


---------------------------------------------------
-- swimming
conds.swimming = {}

function conds.swimming:getFuncText()
	return "self.sFlags.swimming"
end


---------------------------------------------------
-- mounted
conds.mounted = {}

function conds.mounted:getFuncText()
	return "self.sFlags.isMounted"
end


---------------------------------------------------
-- vehicle
conds.vehicle = {}

function conds.vehicle:getFuncText()
	return "self.sFlags.inVehicle"
end


---------------------------------------------------
-- flyable
conds.flyable = {}

function conds.flyable:getFuncText()
	return "self.sFlags.fly"
end


---------------------------------------------------
-- dead
conds.dead = {}

function conds.dead:getFuncText(_, addKey)
	addKey("local UnitIsDead = UnitIsDead")
	return "UnitIsDead('Player')"
end


---------------------------------------------------
-- rest
conds.rest = {}

function conds.rest:getFuncText(_, addKey)
	addKey("local IsResting = IsResting")
	return "IsResting()"
end


---------------------------------------------------
-- combat
conds.combat = {}

function conds.combat:getFuncText(_, addKey)
	addKey("local InCombatLockdown = InCombatLockdown")
	return "InCombatLockdown()"
end


---------------------------------------------------
-- fs FLIGHT STYLE
conds.fs = {}

function conds.fs:getFuncText(value, addKey)
	local spellID = GetDynamicFlightModeSpellID()
	addKey("local GetSpellTexture = C_Spell.GetSpellTexture")
	if value == 1 then
		return ("(GetSpellTexture(%s) ~= 5142726)"):format(spellID)
	else
		return ("(GetSpellTexture(%s) == 5142726)"):format(spellID)
	end
end


---------------------------------------------------
-- hitem HAVE ITEM
conds.hitem = {}

function conds.hitem:getFuncText(value, addKey)
	addKey("local GetItemCount = C_Item.GetItemCount")
	return ("(GetItemCount(%s) > 0)"):format(value)
end


---------------------------------------------------
-- ritem READY ITEM
conds.ritem = {}

function conds.ritem:getFuncText(value, addKey)
	addKey("local GetItemCooldown = C_Container.GetItemCooldown")
	return ("(GetItemCooldown(%s) == 0)"):format(value)
end


---------------------------------------------------
-- kspell KNOWN SPELL
conds.kspell = {}

function conds.kspell:getFuncText(value)
	return ("self.isPlayerSpell(%s)"):format(value)
end


---------------------------------------------------
-- rspell READY SPELL
conds.rspell = {}

function conds.rspell:getFuncText(value, _, isNot)
	local secrecy = GetSpellCooldownSecrecy(value)
	if secrecy == 2 then
		local notText = isNot and "not " or ""
		return ("notSCooldowns and %sself:isSpellReady(%s)"):format(notText, value), true
	elseif secrecy == 0 then
		return ("self:isSpellReady(%s)"):format(value)
	end
	return "false", true
end


---------------------------------------------------
-- uspell USABLE SPELL
conds.uspell = {}

function conds.uspell:getFuncText(value, addKey)
	addKey("local IsSpellUsable = C_Spell.IsSpellUsable")
	return ("IsSpellUsable(%s)"):format(value)
end


---------------------------------------------------
-- hzspell HAVE ZONE SPELL
conds.hzspell = {}

function conds.hzspell:getFuncText(value)
	return ("self:hasZoneSpell(%s)"):format(value)
end


---------------------------------------------------
-- hbuff HAS BUFF
conds.hbuff = {}

function conds.hbuff:getFuncText(value, _, isNot)
	local secrecy = GetSpellAuraSecrecy(value)
	if secrecy == 2 then
		local notText = isNot and "not " or ""
		return ("notSAuras and %sself:hasPlayerBuff(%s)"):format(notText, value), true
	elseif secrecy == 0 then
		return ("self:hasPlayerBuff(%s)"):format(value)
	end
	return "false", true
end


---------------------------------------------------
-- hdebuff HAS DEBUFF
conds.hdebuff = {}

function conds.hdebuff:getFuncText(value, _, isNot)
	local secrecy = GetSpellAuraSecrecy(value)
	if secrecy == 2 then
		local notText = isNot and "not " or ""
		return ("notSAuras and %sself:hasPlayerDebuff(%s)"):format(notText, value), true
	elseif secrecy == 0 then
		return ("self:hasPlayerDebuff(%s)"):format(value)
	end
	return "false", true
end


---------------------------------------------------
-- qc QUEST COMPLETED
conds.qc = {}

function conds.qc:getFuncText(value, addKey)
	addKey("local IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted")
	return ("IsQuestFlaggedCompleted(%s)"):format(value)
end


---------------------------------------------------
-- qca QUEST COMPLETED ON ACCOUNT
conds.qca = {}

function conds.qca:getFuncText(value, addKey)
	addKey("local IsQuestFlaggedCompletedOnAccount = C_QuestLog.IsQuestFlaggedCompletedOnAccount")
	return ("IsQuestFlaggedCompletedOnAccount(%s)"):format(value)
end


---------------------------------------------------
-- faction
conds.faction = {}

function conds.faction:getFuncText(value, addKey)
	local faction = PLAYER_FACTION_GROUP[value]
	addKey("local UnitFactionGroup = UnitFactionGroup")
	return ("(UnitFactionGroup('player') == '%s')"):format(faction:gsub("['\\]", "\\%1"))
end


---------------------------------------------------
-- race
conds.race = {}

function conds.race:getFuncText(values)
	local _, key = UnitRace("player")
	if type(values) == "table" then
		for i = 1, #values do
			if key == values[i] then return "true" end
		end
	elseif key == values then
		return "true"
	end
	return "false"
end


---------------------------------------------------
-- zone
conds.zone = {}

function conds.zone:getFuncText(value)
	return ("self:zoneMatch('/%s/')"):format(value:gsub("['\\]", "\\%1"))
end


---------------------------------------------------
-- map
conds.map = {}

function conds.map:getFuncText(value)
	return ("self:checkMap(%s)"):format(value)
end


---------------------------------------------------
-- mapf MAP FLAGS
conds.mapf = {}

function conds.mapf:getFuncText(value)
	local flag, profile = (":"):split(value, 2)
	return ("self:isMapFlagActive('%s', '%s')"):format(flag, profile:gsub("['\\]", "\\%1"))
end


---------------------------------------------------
-- instance
conds.instance = {}

function conds.instance:getFuncText(values, addKey, _, ...)
	return getTableString(values, true, "self.mounts.instanceID", addKey, ...)
end


---------------------------------------------------
-- difficulty
conds.difficulty = {}

function conds.difficulty:getFuncText(values, addKey, _, ...)
	return getTableString(values, true, "self.mounts.difficultyID", addKey, ...)
end


---------------------------------------------------
-- tmog TRANSMOG
conds.tmog = {}

function conds.tmog:getFuncText(values, addKey, _, ...)
	local vals

	if type(values) == "table" then
		local num = 0
		vals = {}
		for i = 1, #values do
			local outfitID, guid = (":"):split(values[i], 2)
			if guid == playerGuid then
				num = num + 1
				vals[num] = outfitID
			end
		end
		if num == 0 then return "false"
		elseif num == 1 then vals = vals[1] end
	else
		local outfitID, guid = (":"):split(values, 2)
		if guid ~= playerGuid then return "false" end
		vals = outfitID
	end

	addKey("local GetActiveOutfitID = C_TransmogOutfitInfo.GetActiveOutfitID")
	return getTableString(vals, true, "GetActiveOutfitID()", addKey, ...)
end


---------------------------------------------------
-- sex
conds.sex = {}

function conds.sex:getFuncText(value, addKey)
	local unit, sex = (":"):split(value, 2)
	addKey("local UnitSex = UnitSex")
	return ("(UnitSex('%s') == %s)"):format(unit, sex)
end


---------------------------------------------------
-- tl TALENT LOADOUT
conds.tl = {}

function conds.tl:getFuncText(values, addKey, _, ...)
	local vals

	if type(values) == "table" then
		local num = 0
		vals = {}
		for i = 1, #values do
			local configID = (":"):split(values[i], 2)
			if Traits_GetConfigInfo(tonumber(configID)) then
				num = num + 1
				vals[num] = configID
			end
		end
		if num == 0 then return "false"
		elseif num == 1 then vals = vals[1] end
	else
		local configID = (":"):split(values, 2)
		if Traits_GetConfigInfo(tonumber(configID)) == nil then return "false" end
		vals = configID
	end

	return getTableString(vals, true, "self:getTalentConfig()", addKey, ...)
end


---------------------------------------------------
-- mtrack MINIMAP TRACKING
conds.mtrack = {}

function conds.mtrack:getFuncText(value)
	local k, v = (":"):split(value, 2)
	return ("self:checkTracking('%s', %s)"):format(k, v)
end


---------------------------------------------------
-- prof PROFESSION
conds.prof = {}

function conds.prof:getFuncText(values, addKey, _, ...)
	if type(values) == "table" then
		return getFuncString(values, "self:hasProfession(%s)", addKey, ...)
	end
	return ("self.mounts.profs[%s]"):format(values)
end


---------------------------------------------------
-- equips EQUIPMENT SET
conds.equips = {}

function conds.equips:getFuncText(values, addKey, _, ...)
	local vals

	if type(values) == "table" then
		local num = 0
		vals = {}
		for i = 1, #values do
			local setID, guid = (":"):split(values[i], 2)
			if guid == playerGuid then
				num = num + 1
				vals[num] = setID
			end
		end
		if num == 0 then return "false"
		elseif num == 1 then vals = vals[1]
		else return getFuncString(vals, "self:checkEquipmentSets(%s)", addKey, ...) end
	else
		local setID, guid = (":"):split(values, 2)
		if guid ~= playerGuid then return "false" end
		vals = setID
	end

	return ("self:checkEquipmentSet(%s)"):format(vals)
end


---------------------------------------------------
-- equipi EQUIPPED ITEM
conds.equipi = {}

function conds.equipi:getFuncText(value)
	return ("self:isItemEquipped('%s')"):format(value:gsub("['\\]", "\\%1"))
end


---------------------------------------------------
-- gstate GET STATE
conds.gstate = {}

function conds.gstate:getFuncText(value)
	return ("self.state['%s']"):format(value:gsub("['\\]", "\\%1"))
end


---------------------------------------------------
-- snip SNIPPET
conds.snip = {}

function conds.snip:getFuncText(value)
	return ("self:callSnippet('%s')"):format(value:gsub("['\\]", "\\%1"))
end


---------------------------------------------------
-- group GROUP TYPE
conds.group = {}

function conds.group:getFuncText(value)
	if value == "group" or value == "raid" then
		return ("(self.getGroupType() == '%s')"):format(value)
	else
		return "self.getGroupType()"
	end
end


---------------------------------------------------
-- fgroup FRIEND IN PARTY
conds.fgroup = {}

function conds.fgroup:getFuncText(value)
	local t, v = (":"):split(value, 2)
	if t == "btag" then
		return ("self:isFriendInGroup('%s')"):format(v)
	else
		return ("self:isUnitInGroup('%s')"):format(v)
	end
end


---------------------------------------------------
-- fraid FRIEND IN RAID
conds.fraid = {}

function conds.fraid:getFuncText(value)
	local t, v = (":"):split(value, 2)
	if t == "btag" then
		return ("self:isFriendInGroup('%s', true)"):format(v)
	else
		return ("self:isUnitInGroup('%s', true)"):format(v)
	end
end


---------------------------------------------------
-- title
conds.title = {}

function conds.title:getFuncText(values, addKey, _, ...)
	addKey("local GetCurrentTitle = GetCurrentTitle")
	return getTableString(values, true, "GetCurrentTitle()", addKey, ...)
end


---------------------------------------------------
-- METHODS
function conds:getFuncText(rule, addKey, isGroup, ...)
	local text = {}

	if isGroup == nil then
		local condText = rule.action and ns.actions[rule.action[1]].condText
		text[1] = condText and condText or "not (profileLoad or self.useMount)"
	end

	local i = 1
	local cond = rule[i]
	while cond ~= nil do
		local condt = self[cond[2]]
		if condt ~= nil then
			local condText, strict = condt:getFuncText(cond[3], addKey, cond[1], i, ...)
			if cond[1] and not strict then
				condText = "not "..condText
			end
			i = i + 1
			text[#text + 1] = condText
		else
			tremove(rule, i)
		end
		cond = rule[i]
	end
	return concat(text, "\nand ")
end
