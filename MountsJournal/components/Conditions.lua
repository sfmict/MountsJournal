local _, ns = ...
local L, util = ns.L, ns.util
local strcmputf8i, concat, C_Secrets = strcmputf8i, table.concat, C_Secrets
local GetSpellAuraSecrecy, GetSpellCooldownSecrecy = C_Secrets.GetSpellAuraSecrecy, C_Secrets.GetSpellCooldownSecrecy
local playerGuid = UnitGUID("player")
local ltl = LibStub("LibThingsLoad-1.0")
local conds = {}
ns.conditions = conds
ns.RULE_ICON_SIZE = 14


---------------------------------------------------
-- mod MODIFIER
conds.mod = {}
conds.mod.text = L["Modifier"]

function conds.mod:getValueText(value)
	if value == "any" then
		return L["ANY_MODIFIER"]
	else
		return _G[value:upper().."_KEY_TEXT"]
	end
end

function conds.mod:getValueList(value, func)
	local mods = {
		"any",
		"alt",
		"ctrl",
		"shift",
		"lalt",
		"ralt",
		"lctrl",
		"rctrl",
		"lshift",
		"rshift",
	}
	local list = {}
	for i = 1, #mods do
		local v = mods[i]
		list[i] = {
			text = self:getValueText(v),
			value = v,
			func = func,
			checked = v == value,
		}
	end
	return list
end

function conds.mod:getFuncText(value)
	if value == "any" then
		return "IsModifierKeyDown()", "IsModifierKeyDown"
	elseif value == "alt" then
		return "IsAltKeyDown()", "IsAltKeyDown"
	elseif value == "ctrl" then
		return "IsControlKeyDown()", "IsControlKeyDown"
	elseif value == "shift" then
		return "IsShiftKeyDown()", "IsShiftKeyDown"
	elseif value == "lalt" then
		return "IsLeftAltKeyDown()", "IsLeftAltKeyDown"
	elseif value == "ralt" then
		return "IsRightAltKeyDown()", "IsRightAltKeyDown"
	elseif value == "lctrl" then
		return "IsLeftControlKeyDown()", "IsLeftControlKeyDown"
	elseif value == "rctrl" then
		return "IsRightoControlKeyDown()", "IsRightoControlKeyDown"
	elseif value == "lshift" then
		return "IsLeftShiftKeyDown()", "IsLeftShiftKeyDown"
	elseif value == "rshift" then
		return "IsRightShiftKeyDown()", "IsRightShiftKeyDown"
	else
		return "false"
	end
end


---------------------------------------------------
-- btn MOUSE BUTTON
conds.btn = {}
conds.btn.text = L["Mouse button"]

function conds.btn:getValueText(value)
	return _G["KEY_BUTTON"..value]
end

function conds.btn:getValueList(value, func)
	local list = {}
	local i = 1
	local text = self:getValueText(i)
	while text do
		list[i] = {
			text = text,
			value = i,
			func = func,
			checked = i == value,
		}
		i = i + 1
		text = self:getValueText(i)
	end
	return list
end

function conds.btn:getFuncText(value)
	if value == 1 then
		return "button == 'LeftButton'"
	elseif value == 2 then
		return "button == 'RightButton'"
	elseif value == 3 then
		return "button == 'MiddleButton'"
	else
		return ("button == 'Button%s'"):format(value)
	end
end


---------------------------------------------------
-- mcond MACRO CONDITIONS
conds.mcond = {}
conds.mcond.text = L["Macro condition"]

function conds.mcond:getValueDescription()
	return [[|cffffffffexists
help
dead
party, raid
unithasvehicleui
canexitvehicle
channeling, channeling:spellName
equipped:type, worn:type
flyable
flying
form:n, stance:n
group, group:party, group:raid
indoors, outdoors
known:name, known:spellID
mounted
pet:name, pet:family
petbattle
pvpcombat
resting
spec:n, spec:n1/n2
stealth
swimming
actionbar:n, bar:n, bar:n1/n2/...
bonusbar, bonusbar:n
button:n, btn:n1/n2/...
cursor
extrabar
modifier, mod, mod:key, mod:action
overridebar
possessbar
shapeshift
vehicleui|r

[mod:shift,swimming][btn:2]
]]
end

function conds.mcond:getValueText(value)
	return value
end

function conds.mcond:getFuncText(value)
	return ("SecureCmdOptionParse('%s')"):format(value:gsub("['\\]", "\\%1")), "SecureCmdOptionParse"
end


---------------------------------------------------
-- class
conds.class = {}
conds.class.text = CLASS

function conds.class:getValueText(value)
	local localized, className = GetClassInfo(value)
	if localized then
		local classColor = C_ClassColor.GetClassColor(className)
		local t = CLASS_ICON_TCOORDS[className]
		local size = 1024
		return CreateTextureMarkup("Interface/Glues/CharacterCreate/UI-CharacterCreate-Classes", size, size, ns.RULE_ICON_SIZE, ns.RULE_ICON_SIZE, t[1], t[2], t[3], t[4])..classColor:WrapTextInColorCode(localized)
	end
end

function conds.class:getValueList(value, func)
	local list = {}

	for i = 1, GetNumClasses() do
		local localized, className, id = GetClassInfo(i)
		local classColor = C_ClassColor.GetClassColor(className)
		local t = CLASS_ICON_TCOORDS[className]
		list[i] = {
			text = classColor:WrapTextInColorCode(localized),
			icon = "Interface/Glues/CharacterCreate/UI-CharacterCreate-Classes",
			iconInfo = {
				tCoordLeft = t[1],
				tCoordRight = t[2],
				tCoordTop = t[3],
				tCoordBottom = t[4],
			},
			value = id,
			func = func,
			checked = id == value,
		}
	end

	return list
end

function conds.class:getFuncText(value)
	local _,_, id = UnitClass("player")
	return id == value and "true" or "false"
end


---------------------------------------------------
-- spec
conds.spec = {}
conds.spec.text = SPECIALIZATION

function conds.spec:getValueText(value)
	local _, name, _, specIcon, _, className, class = GetSpecializationInfoByID(value)
	if name then
		local classColor = C_ClassColor.GetClassColor(className)
		local icon = CreateSimpleTextureMarkup(specIcon, ns.RULE_ICON_SIZE)
		return ("%s%s - %s"):format(icon, classColor:WrapTextInColorCode(class), name)
	end
end

function conds.spec:getValueList(value, func)
	local list = {}

	for i = 1, GetNumClasses() do
		for j = 1, C_SpecializationInfo.GetNumSpecializationsForClassID(i) do
			local id = GetSpecializationInfoForClassID(i, j)
			local _, name, _, specIcon, _, className, class = GetSpecializationInfoByID(id)
			local classColor = C_ClassColor.GetClassColor(className)
			list[#list + 1] = {
				text = ("%s - %s"):format(classColor:WrapTextInColorCode(class), name),
				icon = specIcon,
				value = id,
				func = func,
				checked = id == value,
			}
		end
	end

	return list
end

function conds.spec:getFuncText(value)
	local index
	for i = 1, GetNumSpecializations() do
		if value == C_SpecializationInfo.GetSpecializationInfo(i) then
			index = i
			break
		end
	end
	if index then
		return "C_SpecializationInfo.GetSpecialization() == "..index, "C_SpecializationInfo"
	end
	return "false"
end


---------------------------------------------------
-- zt ZONE TYPE
conds.zt = {}
conds.zt.text = L["Zone type"]

function conds.zt:getValueText(value)
	if value == "scenario" then
		return TRACKER_HEADER_SCENARIO
	elseif value == "party" then
		return TRACKER_HEADER_DUNGEON
	elseif value == "raid" then
		return RAID
	elseif value == "arena" then
		return ARENA
	elseif value == "pvp" then
		return BATTLEGROUND
	end
end

function conds.zt:getValueList(value, func)
	local zoneTypes = {
		"scenario",
		"party",
		"raid",
		"arena",
		"pvp"
	}
	local list = {}
	for i = 1, #zoneTypes do
		local v = zoneTypes[i]
		list[i] = {
			text = self:getValueText(v),
			value = v,
			func = func,
			checked = v == value,
		}
	end
	sort(list, function(a, b) return strcmputf8i(a.text, b.text) < 0 end)
	return list
end

function conds.zt:getFuncText(value)
	return ("self.mounts.instanceType == '%s'"):format(value)
end


---------------------------------------------------
-- holiday
conds.holiday = {}
conds.holiday.text = CALENDAR_FILTER_HOLIDAYS

function conds.holiday:getValueText(value)
	local holidayName = ns.calendar:getHolidayName(value)
	return ("%s |cff808080(ID:%s)|r"):format(holidayName or RED_FONT_COLOR:WrapTextInColorCode(L["Nameless holiday"]), value)
end

function conds.holiday:getValueList(value, cb, dd, notReset)
	local list = {custom = true}
	list[1] = {
		customFrame = ns.journal.bgFrame.calendarFrame,
		OnLoad = function(frame)
			local value = function() return self:getValueList(value, cb, dd, true) end
			frame:init(1, value, dd)
		end
	}
	local subList = {}
	list[2] = {list = subList}

	if not notReset then ns.calendar:setCurrentDate() end

	local func = function(btn, arg1)
		ns.calendar:saveHolidayName(btn.value, arg1)
		cb(btn)
	end

	local OnTooltipShow = function(btn, tooltip, _, description)
		tooltip:AddLine(description, nil, nil, nil, true)
		tooltip:AddDoubleLine("ID", btn.value, 1,1,1,1,1,1)
	end

	local eList = ns.calendar:getHolidayList()
	for i = 1, #eList do
		local e = eList[i]
		local startDate = FormatShortDate(e.st.monthDay, e.st.month)
		local endDate = FormatShortDate(e.et.monthDay, e.et.month)
		subList[i] = {
			icon = e.icon,
			iconInfo = e.iconInfo,
			text = e.isActive and ("%s (|cff00cc00%s|r)"):format(e.name, SPEC_ACTIVE) or e.name,
			rightText = ("|cff80b5fd%s - %s|r"):format(startDate, endDate),
			rightFont = util.codeFont,
			arg1 = e.name,
			arg2 = e.description,
			value = e.eventID,
			func = func,
			checked = e.eventID == value,
			OnTooltipShow = OnTooltipShow,
		}
	end

	return list
end

function conds.holiday:getFuncText(value)
	return ("self.calendar:isHolidayActive(%s)"):format(value)
end


---------------------------------------------------
-- falling
conds.falling = {}
conds.falling.text = L["The player is falling"]

function conds.falling:getFuncText()
	return "IsFalling()", "IsFalling"
end


---------------------------------------------------
-- moving
conds.moving = {}
conds.moving.text = L["The player is moving"]

function conds.moving:getFuncText()
	return "self:isMovingOrFalling()"
end


---------------------------------------------------
-- indoors
conds.indoors = {}
conds.indoors.text = L["The player is indoors"]

function conds.indoors:getFuncText()
	return "self.sFlags.isIndoors"
end


---------------------------------------------------
-- swimming
conds.swimming = {}
conds.swimming.text = L["The player is swimming"]

function conds.swimming:getFuncText()
	return "self.sFlags.swimming"
end


---------------------------------------------------
-- mounted
conds.mounted = {}
conds.mounted.text = L["The player is mounted"]

function conds.mounted:getFuncText()
	return "self.sFlags.isMounted"
end


---------------------------------------------------
-- vehicle
conds.vehicle = {}
conds.vehicle.text = L["The player is within an vehicle"]

function conds.vehicle:getFuncText()
	return "self.sFlags.inVehicle"
end


---------------------------------------------------
-- flyable
conds.flyable = {}
conds.flyable.text = L["Flyable area"]

function conds.flyable:getFuncText()
	return "self.sFlags.fly"
end


---------------------------------------------------
-- dead
conds.dead = {}
conds.dead.text = L["The player is dead"]

function conds.dead:getFuncText()
	return "UnitIsDead('Player')", "UnitIsDead"
end


---------------------------------------------------
-- rest
conds.rest = {}
conds.rest.text = L["The player is resting"]

function conds.rest:getFuncText()
	return "IsResting()", "IsResting"
end


---------------------------------------------------
-- combat
conds.combat = {}
conds.combat.text = L["The player is in combat"]

function conds.combat:getFuncText()
	return "InCombatLockdown()", "InCombatLockdown"
end


---------------------------------------------------
-- fs FLIGHT STYLE
conds.fs = {}
conds.fs.text = L["Flight style"]

function conds.fs:getValueText(value)
	return value == 1 and ACCESSIBILITY_ADV_FLY_LABEL or L["Steady Flight"]
end

function conds.fs:getValueList(value, func)
	local list = {}
	for i = 1, 2 do
		list[i] = {
			text = self:getValueText(i),
			value = i,
			func = func,
			checked = i == value,
		}
	end
	return list
end

function conds.fs:getFuncText(value)
	local spellID = C_MountJournal.GetDynamicFlightModeSpellID()
	if value == 1 then
		return ("C_Spell.GetSpellTexture(%s) ~= 5142726"):format(spellID), "C_Spell"
	else
		return ("C_Spell.GetSpellTexture(%s) == 5142726"):format(spellID), "C_Spell"
	end
end


---------------------------------------------------
-- hitem HAVE ITEM
conds.hitem = {}
conds.hitem.text = L["Have item"]
conds.hitem.isNumeric = true

function conds.hitem:getValueDescription()
	return "ItemID"
end

local function getItemID(value)
	local itemID = tonumber(value)
	if not itemID and value then
		itemID = tonumber(value:match("item:(%d*)"))
		if not itemID then
			local link = ltl:GetItemLink(value)
			if link then
				itemID = tonumber(link:match("item:(%d*)"))
			end
		end
	end
	return itemID
end

function conds.hitem:setValueLink(fontString, value)
	fontString:SetText()
	if not value then return end
	local itemID = value
	if type(value) == "string" then itemID = getItemID(value) end
	if not itemID then return end
	fontString.value = value
	ltl:Items(itemID):Then(function()
		if fontString.value == value then
			local _, itemLink, _,_,_,_,_,_,_, icon = ltl:GetItemInfo(value)
			fontString:SetText(util.getIconLink(itemLink, icon))
		end
	end)
end

function conds.hitem:receiveDrag(editBox)
	local infoType, itemID = GetCursorInfo()
	if infoType == "item" then
		editBox:SetText(itemID)
		editBox:SetCursorPosition(0)
		editBox:HighlightText()
		ClearCursor()
	end
end

function conds.hitem:getValueDisplay(value, noIcon)
	local name = ltl:GetItemName(value)
	if name then
		local icon = noIcon and "" or CreateSimpleTextureMarkup(ltl:GetItemIcon(value) or util.noIcon, ns.RULE_ICON_SIZE)
		return ("%s%s |cff808080<%s>|r"):format(icon, name, value)
	else
		ltl:Items(value):ThenForAll(function()
			ns.macroFrame:event("RULE_LIST_UPDATE")
		end)
	end
end

function conds.hitem:getValueText(value)
	return tostring(value or "")
end

function conds.hitem:getFuncText(value)
	return ("C_Item.GetItemCount(%s) > 0"):format(value), "C_Item"
end


---------------------------------------------------
-- ritem READY ITEM
conds.ritem = {}
conds.ritem.text = L["Item is ready"]
conds.ritem.isNumeric = true

conds.ritem.getValueDescription = conds.hitem.getValueDescription
conds.ritem.setValueLink = conds.hitem.setValueLink
conds.ritem.receiveDrag = conds.hitem.receiveDrag
conds.ritem.getValueDisplay = conds.hitem.getValueDisplay
conds.ritem.getValueText = conds.hitem.getValueText

function conds.ritem:getFuncText(value)
	return ("C_Container.GetItemCooldown(%s) == 0"):format(value), "C_Container"
end


---------------------------------------------------
-- kspell KNOWN SPELL
conds.kspell = {}
conds.kspell.text = L["Spell is known"]
conds.kspell.isNumeric = true

function conds.kspell:getValueDescription()
	return "SpellID"
end

function conds.kspell:setValueLink(fontString, value)
	if value then
		local link = ltl:GetSpellLink(value)
		local icon = link and ltl:GetSpellInfo(value).iconID
		fontString:SetText(util.getIconLink(link, icon))
	else
		fontString:SetText()
	end
end

function conds.kspell:receiveDrag(editBox)
	local infoType, itemID, _, spellID = GetCursorInfo()
	if infoType == "item" then
		spellID = select(2, C_Item.GetItemSpell(itemID))
	elseif infoType == "petaction" then
		spellID = itemID
	elseif infoType ~= "spell" then
		return
	end
	if spellID then
		editBox:SetText(spellID)
		editBox:SetCursorPosition(0)
		editBox:HighlightText()
		ClearCursor()
	end
end

function conds.kspell:getValueDisplay(value, noIcon)
	local info = ltl:GetSpellInfo(value)
	if info then
		local icon = noIcon and "" or CreateSimpleTextureMarkup(info.iconID or util.noIcon, ns.RULE_ICON_SIZE)
		return ("%s%s |cff808080<%s>|r"):format(icon, info.name, value)
	end
end

conds.kspell.getValueText = conds.hitem.getValueText

function conds.kspell:getFuncText(value)
	return ("self.isPlayerSpell(%s)"):format(value)
end


---------------------------------------------------
-- rspell READY SPELL
conds.rspell = {}
conds.rspell.text = L["Spell is ready"]
conds.rspell.combatLock = true
conds.rspell.isNumeric = true

function conds.rspell:getValueDescription()
	return "SpellID (61304 for GCD)"
end

conds.rspell.setValueLink = conds.kspell.setValueLink
conds.rspell.receiveDrag = conds.kspell.receiveDrag
conds.rspell.getValueDisplay = conds.kspell.getValueDisplay
conds.rspell.getValueText = conds.hitem.getValueText

function conds.rspell:getFuncText(value, isNot)
	local secrecy = GetSpellCooldownSecrecy(value)
	if secrecy == 2 then
		local notText = isNot and "not " or ""
		return ("notSCooldowns and %sself:isSpellReady(%s)"):format(notText, value), nil, true
	elseif secrecy == 0 then
		return ("self:isSpellReady(%s)"):format(value)
	end
	return "false", nil, true
end


---------------------------------------------------
-- uspell USABLE SPELL
conds.uspell = {}
conds.uspell.text = L["Spell is usable"]
conds.uspell.isNumeric = true

conds.uspell.getValueDescription = conds.kspell.getValueDescription
conds.uspell.setValueLink = conds.kspell.setValueLink
conds.uspell.receiveDrag = conds.kspell.receiveDrag
conds.uspell.getValueDisplay = conds.kspell.getValueDisplay
conds.uspell.getValueText = conds.hitem.getValueText

function conds.uspell:getFuncText(value)
	return ("C_Spell.IsSpellUsable(%s)"):format(value), "C_Spell"
end


---------------------------------------------------
-- hzspell HAVE ZONE SPELL
conds.hzspell = {}
conds.hzspell.text = L["Have zone spell"]
conds.hzspell.description = HUD_EDIT_MODE_EXTRA_ABILITIES_LABEL
conds.hzspell.isNumeric = true

conds.hzspell.getValueDescription = conds.kspell.getValueDescription
conds.hzspell.setValueLink = conds.kspell.setValueLink
conds.hzspell.receiveDrag = conds.kspell.receiveDrag
conds.hzspell.getValueDisplay = conds.kspell.getValueDisplay
conds.hzspell.getValueText = conds.hitem.getValueText

function conds.hzspell:getFuncText(value)
	return ("self:haveZoneSpell(%s)"):format(value)
end


---------------------------------------------------
-- hbuff HAS BUFF
conds.hbuff = {}
conds.hbuff.text = L["The player has a buff"]
conds.hbuff.combatLock = true
conds.hbuff.isNumeric = true

conds.hbuff.getValueDescription = conds.kspell.getValueDescription
conds.hbuff.setValueLink = conds.kspell.setValueLink
conds.hbuff.receiveDrag = conds.kspell.receiveDrag
conds.hbuff.getValueDisplay = conds.kspell.getValueDisplay
conds.hbuff.getValueText = conds.hitem.getValueText

function conds.hbuff:getFuncText(value, isNot)
	local secrecy = GetSpellAuraSecrecy(value)
	if secrecy == 2 then
		local notText = isNot and "not " or ""
		return ("notSAuras and %sself:hasPlayerBuff(%s)"):format(notText, value), nil, true
	elseif secrecy == 0 then
		return ("self:hasPlayerBuff(%s)"):format(value)
	end
	return "false", nil, true
end


---------------------------------------------------
-- hdebuff HAS DEBUFF
conds.hdebuff = {}
conds.hdebuff.text = L["The player has a debuff"]
conds.hdebuff.combatLock = true
conds.hdebuff.isNumeric = true

conds.hdebuff.getValueDescription = conds.kspell.getValueDescription
conds.hdebuff.setValueLink = conds.kspell.setValueLink
conds.hdebuff.receiveDrag = conds.kspell.receiveDrag
conds.hdebuff.getValueDisplay = conds.kspell.getValueDisplay
conds.hdebuff.getValueText = conds.hitem.getValueText

function conds.hdebuff:getFuncText(value, isNot)
	local secrecy = GetSpellAuraSecrecy(value)
	if secrecy == 2 then
		local notText = isNot and "not " or ""
		return ("notSAuras and %sself:hasPlayerDebuff(%s)"):format(notText, value), nil, true
	elseif secrecy == 0 then
		return ("self:hasPlayerDebuff(%s)"):format(value)
	end
	return "false", nil, true
end


---------------------------------------------------
-- qc QUEST COMPLETED
conds.qc = {}
conds.qc.text = QUEST_COMPLETE
conds.qc.isNumeric = true

function conds.qc:getValueDescription()
	return "questID"
end

conds.qc.getValueText = conds.hitem.getValueText

function conds.qc:getFuncText(value)
	return ("C_QuestLog.IsQuestFlaggedCompleted(%s)"):format(value), "C_QuestLog"
end


---------------------------------------------------
-- qca QUEST COMPLETED ON ACCOUNT
conds.qca = {}
conds.qca.text = L["Quest completed on account"]
conds.qca.isNumeric = true

conds.qca.getValueDescription = conds.qc.getValueDescription
conds.qca.getValueText = conds.hitem.getValueText

function conds.qca:getFuncText(value)
	return ("C_QuestLog.IsQuestFlaggedCompletedOnAccount(%s)"):format(value), "C_QuestLog"
end


---------------------------------------------------
-- faction
conds.faction = {}
conds.faction.text = FACTION

function conds.faction:getValueText(value)
	return FACTION_LABELS[value]
end

function conds.faction:getValueList(value, func)
	local list = {}
	for i = 0, #PLAYER_FACTION_GROUP do
		list[#list + 1] = {
			text = self:getValueText(i),
			value = i,
			func = func,
			checked = i == value,
		}
	end
	return list
end

function conds.faction:getFuncText(value)
	local faction = PLAYER_FACTION_GROUP[value]
	return ("UnitFactionGroup('player') == '%s'"):format(faction:gsub("['\\]", "\\%1")), "UnitFactionGroup"
end


---------------------------------------------------
-- race
conds.race = {}
conds.race.text = RACE

local RACE_KEYS = {
	1, -- Human
	2, -- Orc
	3, -- Dwarf
	4, -- NightElf
	5, -- Scourge
	6, -- Tauren
	7, -- Gnome
	8, -- Troll
	9, -- Goblin
	10, -- BloodElf
	11, -- Draenei
	22, -- Worgen
	24, -- Pandaren
	27, -- Nightborne
	28, -- HighmountainTauren
	29, -- VoidElf
	30, -- LightforgedDraenei
	31, -- ZandalariTroll
	32, -- KulTiran
	34, -- DarkIronDwarf
	35, -- Vulpera
	36, -- MagharOrc
	37, -- Mechagnome
	52, -- Dracthyr
	84, -- EarthenDwarf
	86, -- Harronir
}
local RACE_LABELS = {}
for i = 1, #RACE_KEYS do
	local id = RACE_KEYS[i]
	local info = C_CreatureInfo.GetRaceInfo(id)
	RACE_KEYS[i] = info.clientFileString
	RACE_LABELS[info.clientFileString] = info.raceName
end

function conds.race:getValueText(value)
	local atlasName = util.getRaceAtlas(value, UnitSex("Player"))
	return CreateAtlasMarkup(atlasName, ns.RULE_ICON_SIZE, ns.RULE_ICON_SIZE)..RACE_LABELS[value]
end

function conds.race:getValueList(value, func)
	local sex = UnitSex("Player")
	local list = {}
	sort(RACE_KEYS, function(a,b) return strcmputf8i(RACE_LABELS[a], RACE_LABELS[b]) < 0 end)
	for i = 1, #RACE_KEYS do
		local v = RACE_KEYS[i]
		list[#list + 1] = {
			text = RACE_LABELS[v],
			icon = util.getRaceAtlas(v, sex),
			value = v,
			func = func,
			checked = v == value,
		}
	end
	return list
end

function conds.race:getFuncText(value)
	local _, key = UnitRace("player")
	return key == value and "true" or "false"
end


---------------------------------------------------
-- zone
conds.zone = {}
conds.zone.text = ZONE

function conds.zone:getValueDescription()
	return L["Zone Name/Subzone Name"]
end

conds.zone.getValueText = conds.mcond.getValueText

function conds.zone:getFuncText(value)
	return ("self:zoneMatch('/%s/')"):format(value:gsub("['\\]", "\\%1"))
end


---------------------------------------------------
-- map
conds.map = {}
conds.map.text = L["Map"]

function conds.map:getValueText(value)
	if value == ns.mounts.defMountsListID then
		return WORLD
	else
		local mapInfo = util.getMapFullNameInfo(value)
		if mapInfo then return mapInfo.name end
	end
end

function conds.map:getFuncText(value)
	return ("self:checkMap(%s)"):format(value)
end


---------------------------------------------------
-- mapf MAP FLAGS
conds.mapf = {}
conds.mapf.text = L["Map flags"]

function conds.mapf:getValueText(value)
	local flag, profile = (":"):split(value, 2)

	local flags = {
		groundOnly = L["Ground Mounts Only"],
		waterWalkOnly = L["Water Walking"],
		herbGathering = L["Herb Gathering"],
	}

	if profile == "" then
		profile = DEFAULT
	elseif not ns.mounts.profiles[profile] then
		profile = RED_FONT_COLOR:WrapTextInColorCode(profile)
	end

	return ("%s - %s"):format(profile, flags[flag])
end

function conds.mapf:getValueList(value, func)
	local list = {}

	local flags = {
		groundOnly = L["Ground Mounts Only"],
		waterWalkOnly = L["Water Walking"],
		herbGathering = L["Herb Gathering"],
	}

	local profiles = {}
	for k in next, ns.mounts.profiles do profiles[#profiles + 1] = k end
	sort(profiles, function(a, b) return strcmputf8i(a, b) < 0 end)
	tinsert(profiles, 1, DEFAULT)

	list[1] = {
		notCheckable = true,
		isTitle = true,
		text = L["Profiles"],
	}

	for i = 1, #profiles do
		local profileName = profiles[i]
		local flagList = {}

		for k, name in next, flags do
			local v = ("%s:%s"):format(k, profileName == DEFAULT and "" or profileName)
			flagList[#flagList + 1] = {
				text = name,
				value = v,
				func = func,
				checked = v == value,
			}
		end

		list[i + 1] = {
			keepShownOnClick = true,
			notCheckable = true,
			hasArrow = true,
			text = profileName,
			value = flagList,
		}
	end

	return list
end

function conds.mapf:getFuncText(value)
	local flag, profile = (":"):split(value, 2)
	return ("self:isMapFlagActive('%s', '%s')"):format(flag, profile:gsub("['\\]", "\\%1"))
end


---------------------------------------------------
-- instance
conds.instance = {}
conds.instance.text = INSTANCE

function conds.instance:getValueDescription()
	return {
		INSTANCE.." or InstanceID",
		{INSTANCE , ns.mounts.instanceName},
		{"InstanceID", ns.mounts.instanceID},
	}
end

conds.instance.getValueText = conds.mcond.getValueText

function conds.instance:getFuncText(value)
	if value:trim():match("%D") then
		return ("self.mounts.instanceName == '%s'"):format(value:gsub("['\\]", "\\%1"))
	elseif tonumber(value) then
		return ("self.mounts.instanceID == %s"):format(tonumber(value))
	end
	return "false"
end


---------------------------------------------------
-- difficulty
conds.difficulty = {}
conds.difficulty.text = LFG_LIST_DIFFICULTY

function conds.difficulty:getValueText(value)
	if value == 0 then return WORLD end
	local name, instanceType, _,_,_,_,_, isLFR, minPlayers, maxPlayers = GetDifficultyInfo(value)

	if name then
		if instanceType == "raid" then
			name = name.." | "..LEGENDARY_ORANGE_COLOR:WrapTextInColorCode(RAID)
		elseif instanceType == "party" then
			name = name.." | "..EPIC_PURPLE_COLOR:WrapTextInColorCode(LFG_TYPE_DUNGEON)
		end

		if isLFR then name = name.." | "..HEIRLOOM_BLUE_COLOR:WrapTextInColorCode(minPlayers.." - "..maxPlayers) end
		if IsLegacyDifficulty(value) then name = name.." | "..ARTIFACT_GOLD_COLOR:WrapTextInColorCode(LFG_LIST_LEGACY) end

		return name
	end
end

function conds.difficulty:getValueList(value, func)
	local ids = {0}
	for k, id in next, DifficultyUtil.ID do ids[#ids + 1] = id end
	sort(ids)

	local list = {}
	for i = 1, #ids do
		local id = ids[i]
		list[i] = {
			text = self:getValueText(id),
			value = id,
			func = func,
			checked = id == value,
		}
	end
	return list
end

function conds.difficulty:getFuncText(value)
	return ("self.mounts.difficultyID == %s"):format(value)
end


---------------------------------------------------
-- tmog TRANSMOG
conds.tmog = {}
conds.tmog.text = PERKS_VENDOR_CATEGORY_TRANSMOG

function conds.tmog:getValueText(value)
	local outfitID, guid = (":"):split(value, 2)
	if guid == playerGuid then
		local outfitInfo = C_TransmogOutfitInfo.GetOutfitInfo(tonumber(outfitID))
		if outfitInfo then return outfitInfo.name end
	elseif guid then
		return ("ID:%s - %s"):format(outfitID, ns.macroFrame:getNameByGUID(guid))
	end
end

function conds.tmog:getValueList(value, func)
	local list = {}
	local outfitsInfo = C_TransmogOutfitInfo.GetOutfitsInfo()

	local function getSlotTransmogID(location, weaponOption, appearanceID)
		if not location then return Constants.Transmog.NoTransmogID end
		if location:IsIllusion() then
			if appearanceID == Constants.Transmog.NoTransmogID or not TransmogUtil.CanEnchantSource(appearanceID) then
				return Constants.Transmog.NoTransmogID
			end
		end
		local slotInfo = C_TransmogOutfitInfo.GetViewedOutfitSlotInfo(location:GetSlot(), location:GetType(), weaponOption)
		return slotInfo and slotInfo.transmogID or Constants.Transmog.NoTransmogID
	end

	local function onEnter(btn, outfitID)
		if MJTooltipModel.previousActor then
			MJTooltipModel.previousActor:ClearModel()
			MJTooltipModel.previousActor = nil
		end

		MJTooltipModel.model:SetFromModelSceneID(290)
		local actor = MJTooltipModel.model:GetPlayerActor()
		if not actor then return end
		MJTooltipModel.previousActor = actor
		actor:SetModelByUnit("player", false, false, false, PlayerUtil.ShouldUseNativeFormInModelScene())

		local hideIgnored = GetCVar("transmogHideIgnoredSlots")
		SetCVar("transmogHideIgnoredSlots", "1")
		local curOutfitID = C_TransmogOutfitInfo.GetCurrentlyViewedOutfitID()
		C_TransmogOutfitInfo.ChangeViewedOutfit(outfitID)

		local tLocations = {}
		local iLocations = {}
		for i, groupData in ipairs(C_TransmogOutfitInfo.GetSlotGroupInfo()) do
			for j, appearanceInfo in ipairs(groupData.appearanceSlotInfo) do
				tLocations[#tLocations + 1] = TransmogUtil.GetTransmogLocation(appearanceInfo.slotName, appearanceInfo.type, appearanceInfo.isSecondary)
			end
			for j, illusionInfo in ipairs(groupData.illusionSlotInfo) do
				iLocations[illusionInfo.slot] = TransmogUtil.GetTransmogLocation(illusionInfo.slotName, illusionInfo.type, illusionInfo.isSecondary)
			end
		end
		for i, location in ipairs(tLocations) do
			local slot = location:GetSlot()
			local linkedSlotInfo = C_TransmogOutfitInfo.GetLinkedSlotInfo(slot)

			if not linkedSlotInfo or linkedSlotInfo.primarySlotInfo.slot == slot then
				local weaponOption = C_TransmogOutfitInfo.GetEquippedSlotOptionFromTransmogSlot(slot) or Enum.TransmogOutfitSlotOption.None
				local appearanceID = getSlotTransmogID(location, weaponOption)
				local secondaryAppearanceID = Constants.Transmog.NoTransmogID
				if linkedSlotInfo then
					local outfitSlotInfo = C_TransmogOutfitInfo.GetViewedOutfitSlotInfo(linkedSlotInfo.secondarySlotInfo.slot, linkedSlotInfo.secondarySlotInfo.type, weaponOption)
					if outfitSlotInfo then
						secondaryAppearanceID = outfitSlotInfo.transmogID
					end
				end

				if appearanceID ~= Constants.Transmog.NoTransmogID or secondaryAppearanceID ~= Constants.Transmog.NoTransmogID then
					local illusionID = getSlotTransmogID(iLocations[slot], weaponOption, appearanceID)
					local itemTransmogInfo = ItemUtil.CreateItemTransmogInfo(appearanceID, secondaryAppearanceID, illusionID)
					local slotID = location:GetSlotID()

					if location:IsMainHand() then
						local mainHandCategoryID = C_TransmogOutfitInfo.GetItemModifiedAppearanceEffectiveCategory(appearanceID)
						itemTransmogInfo:ConfigureSecondaryForMainHand(TransmogUtil.IsCategoryLegionArtifact(mainHandCategoryID))
						-- Don't specify a slot for ranged weapons.
						if TransmogUtil.IsCategoryRangedWeapon(mainHandCategoryID) then
							slotID = nil
						end
					end
					actor:SetItemTransmogInfo(itemTransmogInfo, slotID)
				end
			end
		end

		SetCVar("transmogHideIgnoredSlots", hideIgnored)
		C_TransmogOutfitInfo.ChangeViewedOutfit(curOutfitID)

		MJTooltipModel:ClearAllPoints()
		MJTooltipModel:SetPoint("LEFT", btn, "RIGHT", 5, 0)
		MJTooltipModel:Show()
	end

	local function onLeave()
		MJTooltipModel:Hide()
	end

	if outfitsInfo and #outfitsInfo > 0 then
		for i, outfitInfo in ipairs(outfitsInfo) do
			local v = ("%s:%s"):format(outfitInfo.outfitID, playerGuid)
			list[i] = {
				text = outfitInfo.name,
				rightText = ("|cff808080ID:%s|r"):format(outfitInfo.outfitID),
				rightFont = util.codeFont,
				value = v,
				arg1 = outfitInfo.outfitID,
				icon = outfitInfo.icon,
				func = func,
				checked = v == value,
				OnEnter = onEnter,
				OnLeave = onLeave,
			}
		end
	else
		list[1] = {
			notCheckable = true,
			disabled = true,
			text = EMPTY,
		}
	end

	return list
end

function conds.tmog:getFuncText(value)
	local outfitID, guid = (":"):split(value, 2)
	if guid == playerGuid then
		return "C_TransmogOutfitInfo.GetActiveOutfitID() == "..outfitID, "C_TransmogOutfitInfo"
	end
	return "false"
end


---------------------------------------------------
-- sex
conds.sex = {}
conds.sex.text = L["Sex"]

function conds.sex:getValueText(value)
	local unit, sex = (":"):split(value, 2)
	if sex == "2" then
		sex = MALE
	elseif sex == "3" then
		sex = FEMALE
	else
		sex = UNKNOWN
	end
	return ("%s - %s"):format(unit:upper(), sex)
end

function conds.sex:getValueList(value, func)
	local list = {}
	for i, unit in ipairs({"player", "target", "focus"}) do
		for j = 3, 1, -1 do
			local v = ("%s:%s"):format(unit, j)
			list[#list + 1] = {
				text = self:getValueText(v),
				value = v,
				func = func,
				checked = v == value,
			}
		end
	end
	return list
end

function conds.sex:getFuncText(value)
	local unit, sex = (":"):split(value, 2)
	return ("UnitSex('%s') == %s"):format(unit, sex), "UnitSex"
end


---------------------------------------------------
-- tl TALENT LOADOUT
conds.tl = {}
conds.tl.text = L["Talent loadout"]

function conds.tl:getValueText(value)
	local configID, guid = (":"):split(value, 2)
	local configInfo = C_Traits.GetConfigInfo(tonumber(configID))
	if configInfo then
		return configInfo.name
	else
		return ("ID:%s - %s"):format(configID, ns.macroFrame:getNameByGUID(guid))
	end
end

function conds.tl:getValueList(value, func)
	local list = {}

	for i = 1, GetNumSpecializations() do
		local specID, specName = C_SpecializationInfo.GetSpecializationInfo(i)
		local configIDs = C_ClassTalents.GetConfigIDsBySpecID(specID)
		for j = 1, #configIDs do
			local configID = configIDs[j]
			local configInfo = C_Traits.GetConfigInfo(configID)
			local v = ("%s:%s"):format(configID, playerGuid)
			list[#list + 1] = {
				text = ("%s - %s"):format(configInfo.name, specName),
				rightText = ("|cff808080ID:%s|r"):format(configID),
				rightFont = util.codeFont,
				value = v,
				func = func,
				checked = v == value,
			}
		end
	end

	if #list == 0 then
		list[1] = {
			notCheckable = true,
			disabled = true,
			text = EMPTY,
		}
	end

	return list
end

function conds.tl:getFuncText(value)
	local configID = (":"):split(value, 2)
	if C_Traits.GetConfigInfo(tonumber(configID)) then
		return ("self:checkTalent(%s)"):format(configID)
	end
	return "false"
end


---------------------------------------------------
-- mtrack MINIMAP TRACKING
conds.mtrack = {}
conds.mtrack.text = TRACKING

function conds.mtrack:getValueText(value)
	local k, v, name = (":"):split(value, 2)
	v = tonumber(v)
	for i = 1, C_Minimap.GetNumTrackingTypes() do
		if C_Minimap.GetTrackingFilter(i)[k] == v then
			name = C_Minimap.GetTrackingInfo(i).name
			break
		end
	end
	if not name and k == "spellID" then
		name = C_Spell.GetSpellName(v)
	end
	if name then
		return ("%s |cff808080(%s)|r"):format(name, value)
	end
	return value
end

function conds.mtrack:getValueList(value, func)
	local list = {}
	local showAll = GetCVarBool("minimapTrackingShowAll")
	local isHunterClass = select(2, UnitClass("player")) == "HUNTER"

	local OPTIONAL_FILTERS = {
		[Enum.MinimapTrackingFilter.Banker] = true,
		[Enum.MinimapTrackingFilter.Auctioneer] = true,
		[Enum.MinimapTrackingFilter.Barber] = true,
		[Enum.MinimapTrackingFilter.TrainerProfession] = true,
		[Enum.MinimapTrackingFilter.AccountCompletedQuests] = true,
		[Enum.MinimapTrackingFilter.TrivialQuests] = true,
		[Enum.MinimapTrackingFilter.Transmogrifier] = true,
		[Enum.MinimapTrackingFilter.Mailbox] = true,
	}

	local TRACKING_SPELL_OVERRIDE_ATLAS = {
		[43308] = "professions_tracking_fish", -- Find Fish
		[2580] = "professions_tracking_ore", -- Find Minerals 1
		[8388] = "professions_tracking_ore", -- Find Minerals 2
		[2383] = "professions_tracking_herb", -- Find Herbs 1
		[8387] = "professions_tracking_herb", -- Find Herbs 2
		[122026] = "WildBattlePetCapturable", -- Track Pets
	}

	local hunterList = {}
	local townfolkList = {}
	local regularList = {}

	for i = 1, C_Minimap.GetNumTrackingTypes() do
		local filter = C_Minimap.GetTrackingFilter(i)
		if showAll or OPTIONAL_FILTERS[filter.filterID] or filter.spellID then
			local trackingInfo = C_Minimap.GetTrackingInfo(i)
			local v = filter.filterID and "filterID:"..filter.filterID or "spellID:"..filter.spellID

			local info = {
				text = trackingInfo.name,
				icon = TRACKING_SPELL_OVERRIDE_ATLAS[trackingInfo.spellID] or trackingInfo.texture,
				rightText = ("|cff808080%s|r"):format(v),
				rightFont = util.codeFont,
				value = v,
				func = func,
				checked = v == value,
			}

			if isHunterClass and trackingInfo.subType == HUNTER_TRACKING then
				hunterList[#hunterList + 1] = info
			elseif showAll and trackingInfo.subType == TOWNSFOLK_TRACKING then
				townfolkList[#townfolkList + 1] = info
			else
				regularList[#regularList + 1] = info
			end
		end
	end

	if #hunterList == 1 then
		list[#list + 1] = hunterList[1]
	elseif #hunterList > 1 then
		list[#list + 1] = {
			keepShownOnClick = true,
			notCheckable = true,
			text = HUNTER_TRACKING_TEXT,
			hasArrow = true,
			value = hunterList,
		}
	end

	if #townfolkList > 0 then
		list[#list + 1] = {
			keepShownOnClick = true,
			notCheckable = true,
			text = TOWNSFOLK_TRACKING_TEXT,
			hasArrow = true,
			value = townfolkList,
		}
	end

	for i = 1, #regularList do
		list[#list + 1] = regularList[i]
	end

	return list
end

function conds.mtrack:getFuncText(value)
	local k, v = (":"):split(value, 2)
	return ("self:checkTracking('%s', %s)"):format(k, v)
end


---------------------------------------------------
-- prof PROFESSION
conds.prof = {}
conds.prof.text = PROFESSIONS_BUTTON

function conds.prof:getValueText(value)
	return C_TradeSkillUI.GetTradeSkillDisplayName(value)
end

function conds.prof:getValueList(value, func)
	local list = {}
	for id in next, WORLD_QUEST_ICONS_BY_PROFESSION do
		local icon = C_TradeSkillUI.GetTradeSkillTexture(id)
		if icon then
			list[#list + 1] = {
				text = self:getValueText(id),
				icon = icon,
				value = id,
				func = func,
				checked = id == value,
			}
		end
	end
	sort(list, function(a, b) return strcmputf8i(a.text, b.text) < 0 end)
	return list
end

function conds.prof:getFuncText(value)
	return ("self.mounts.profs[%s]"):format(value)
end


---------------------------------------------------
-- equips EQUIPMENT SET
conds.equips = {}
conds.equips.text = PAPERDOLL_EQUIPMENTMANAGER

function conds.equips:getValueText(value)
	local setID, guid = (":"):split(value, 2)
	if guid == playerGuid then
		local name = C_EquipmentSet.GetEquipmentSetInfo(tonumber(setID))
		if name then
			return name
		else
			return RED_FONT_COLOR:WrapTextInColorCode(("ID:%s"):format(setID))
		end
	end
	return ("ID:%s - %s"):format(setID, ns.macroFrame:getNameByGUID(guid))
end

function conds.equips:getValueList(value, func)
	local list = {}

	for i, setID in ipairs(C_EquipmentSet.GetEquipmentSetIDs()) do
		local name, iconFileID = C_EquipmentSet.GetEquipmentSetInfo(setID)
		local v = ("%s:%s"):format(setID, playerGuid)
		list[i] = {
			text = name,
			rightText = ("|cff808080ID:%s|r"):format(setID),
			rightFont = util.codeFont,
			icon = iconFileID,
			value = v,
			func = func,
			checked = v == value,
		}
	end

	if #list == 0 then
		list[1] = {
			notCheckable = true,
			disabled = true,
			text = EMPTY,
		}
	end

	return list
end

function conds.equips:getFuncText(value)
	local setID, guid = (":"):split(value, 2)
	if guid == playerGuid then
		return ("self:checkEquipmentSet(%s)"):format(setID)
	end
	return "false"
end


---------------------------------------------------
-- equipi EQUIPPED ITEM
conds.equipi = {}
conds.equipi.text = L["Item is equipped"]

conds.equipi.setValueLink = conds.hitem.setValueLink

function conds.equipi:receiveDrag(editBox)
	local infoType, _, link = GetCursorInfo()
	if infoType == "item" then
		editBox:SetText(link)
		editBox:SetCursorPosition(0)
		editBox:HighlightText()
		ClearCursor()
	end
end

function conds.equipi:getValueDisplay(value)
	local itemID = getItemID(value)
	return itemID and conds.hitem.getValueDisplay(self, itemID)
end

conds.equipi.getValueText = conds.mcond.getValueText

function conds.equipi:getFuncText(value)
	return ("self:isItemEquipped('%s')"):format(value:gsub("['\\]", "\\%1"))
end


---------------------------------------------------
-- gstate GET STATE
conds.gstate = {}
conds.gstate.text = L["Get State"]
conds.gstate.description = L["Get a state that can be set in actions using \"Set State\""]

function conds.gstate:getValueText(value)
	return value
end

function conds.gstate:getFuncText(value)
	return ("self.state['%s']"):format(value:gsub("['\\]", "\\%1"))
end


---------------------------------------------------
-- snip SNIPPET
conds.snip = {}
conds.snip.text = L["Code Snippet"]

function conds.snip:getValueText(value)
	if ns.macroFrame.snippets[value] then
		return value
	end
	return RED_FONT_COLOR:WrapTextInColorCode(value)
end

function conds.snip:getValueList(value, func)
	local list = {}

	for name in next, ns.macroFrame.snippets do
		list[#list + 1] = {
			text = name,
			value = name,
			func = func,
			checked = name == value,
		}
	end

	if #list > 1 then
		sort(list, function(a, b) return strcmputf8i(a.text, b.text) < 0 end)
	elseif #list == 0 then
		list[1] = {
			notCheckable = true,
			disabled = true,
			text = EMPTY,
		}
	end

	return list
end

function conds.snip:getFuncText(value)
	return ("self:callSnippet('%s')"):format(value:gsub("['\\]", "\\%1"))
end


---------------------------------------------------
-- group GROUP TYPE
conds.group = {}
conds.group.text = L["Group Type"]

function conds.group:getValueText(value)
	if value == "group" then
		return PARTY
	elseif value == "raid" then
		return RAID
	end
	return L["ANY_GROUP"]
end

function conds.group:getValueList(value, func)
	local list = {}
	for i, v in ipairs({"any", "group", "raid"}) do
		list[i] = {
			text = self:getValueText(v),
			value = v,
			func = func,
			checked = v == value,
		}
	end
	return list
end

function conds.group:getFuncText(value)
	if value == "group" or value == "raid" then
		return ("self.getGroupType() == '%s'"):format(value:gsub("['\\]", "\\%1"))
	else
		return "self.getGroupType()"
	end
end


---------------------------------------------------
-- fgroup FRIEND IN PARTY
conds.fgroup = {}
conds.fgroup.text = L["Friend in Party"]
conds.fgroup.combatLock = true

local function getFriendList(value, func)
	local friends = {}
	local favIcon = CreateAtlasMarkup("PetJournal-FavoritesIcon", 20, 20)
	local noteIcon = CreateSimpleTextureMarkup("Interface/FriendsFrame/UI-FriendsFrame-Note", 12, 12)
	local numBNetTotal, numBNetOnline, numBNetFavorite = BNGetNumFriends()
	local numWoWTotal, numWoWOnline = 0, 0

	if C_GameRules.GetActiveGameMode() == Enum.GameMode.Standard then
		numWoWTotal = C_FriendList.GetNumFriends()
		numWoWOnline = C_FriendList.GetNumOnlineFriends()
	end

	local function onEnter(btn, note)
		if note and note ~= "" then
			GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
			GameTooltip:SetText(noteIcon..note)
			GameTooltip:Show()
		end
	end

	local function addBNet(i)
		local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
		local v = "btag:"..accountInfo.battleTag
		local nameText, nameColor, statusTexture = FriendsFrame_GetBNetAccountNameAndStatus(accountInfo)

		friends[#friends + 1] = {
			text = accountInfo.isFavorite and nameText..favIcon or nameText,
			icon = statusTexture,
			value = v,
			arg1 = accountInfo.note,
			OnEnter = onEnter,
			OnLeave = GameTooltip_Hide,
			func = func,
			checked = v == value,
		}
	end

	local function addWoW(i)
		local info = C_FriendList.GetFriendInfoByIndex(i)
		local v, icon = "guid:"..info.guid

		if not info.connected then
			icon = FRIENDS_TEXTURE_OFFLINE
		elseif info.afk then
			icon = FRIENDS_TEXTURE_AFK
		elseif info.dnd then
			icon = FRIENDS_TEXTURE_DND
		else
			icon = FRIENDS_TEXTURE_ONLINE
		end

		friends[#friends + 1] = {
			text = info.connected and info.name..", "..FRIENDS_LEVEL_TEMPLATE:format(info.level, info.className) or info.name,
			icon = icon,
			value = v,
			arg1 = info.notes,
			OnEnter = onEnter,
			OnLeave = GameTooltip_Hide,
			func = func,
			checked = v == value,
		}
	end

	for i = 1, numBNetFavorite + numBNetOnline do addBNet(i) end
	for i = 1, numWoWOnline do addWoW(i) end
	for i = numBNetFavorite + numBNetOnline + 1, numBNetTotal do addBNet(i) end
	for i = numWoWOnline + 1, numWoWTotal do addWoW(i) end

	if #friends == 0 then
		friends[1] = {
			notCheckable = true,
			disabled = true,
			text = EMPTY,
		}
	end

	return friends
end

function conds.fgroup:getValueText(value)
	local t, v = (":"):split(value, 2)

	if t == "btag" then
		for i = 1, BNGetNumFriends() do
			local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
			if accountInfo.battleTag == v then
				return accountInfo.accountName
			end
		end
	elseif t == "guid" then
		return ns.macroFrame:getNameByGUID(v)
	end

	return RED_FONT_COLOR:WrapTextInColorCode(L["Not Found"])
end

function conds.fgroup:getValueList(value, func)
	local group, isSecret = {}

	for i = 1, GetNumSubgroupMembers() do
		local unit = "party"..i
		-- if UnitIsPlayer(unit) then
			local guid = UnitGUID(unit)
			if issecretvalue(guid) then
				isSecret = true
				break
			end
			local v = "guid:"..guid
			group[#group + 1] = {
				text = GetUnitName(unit, true),
				value = v,
				func = func,
				checked = v == value,
			}
		-- end
	end

	if #group == 0 then
		group[1] = {
			notCheckable = true,
			disabled = true,
			text = isSecret and "<secret>" or EMPTY,
		}
	end

	return {
		{
			keepShownOnClick = true,
			notCheckable = true,
			text = FRIENDS,
			hasArrow = true,
			value = getFriendList(value, func),
		},
		{
			keepShownOnClick = true,
			notCheckable = true,
			text = PARTY,
			hasArrow = true,
			value = group,
		}
	}
end

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
conds.fraid.text = L["Friend in Raid"]
conds.fraid.combatLock = true

conds.fraid.getValueText = conds.fgroup.getValueText

function conds.fraid:getValueList(value, func)
	local group, isSecret = {}

	if IsInRaid() then
		for i = 1, GetNumGroupMembers() do
			local unit = "raid"..i
			if UnitIsPlayer(unit) then
				local isPlayer = UnitIsUnit(unit, "player")
				if issecretvalue(isPlayer) then
					isSecret = true
					break
				end
				if not isPlayer then
					local v = "guid:"..UnitGUID(unit)
					group[#group + 1] = {
						text = GetUnitName(unit, true),
						value = v,
						func = func,
						checked = v == value,
					}
				end
			end
		end
	end

	if #group == 0 then
		group[1] = {
			notCheckable = true,
			disabled = true,
			text = isSecret and "<secret>" or EMPTY,
		}
	end

	return {
		{
			keepShownOnClick = true,
			notCheckable = true,
			text = FRIENDS,
			hasArrow = true,
			value = getFriendList(value, func),
		},
		{
			keepShownOnClick = true,
			notCheckable = true,
			text = RAID,
			hasArrow = true,
			value = group,
		}
	}
end

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
conds.title.text = PAPERDOLL_SIDEBAR_TITLES

function conds.title:getValueText(value)
	local name = GetTitleName(value)
	return name
end

function conds.title:getValueList(value, func)
	local list = {}
	for i = 1, GetNumTitles() do
		local name, show = GetTitleName(i)
		if show then
			list[#list + 1] = {
				text = IsTitleKnown(i) and ("%s (|cff00cc00%s|r)"):format(name, GARRISON_MISSION_ADDED_TOAST2) or name,
				rightText = ("|cff808080%s|r"):format(i),
				rightFont = util.codeFont,
				value = i,
				func = func,
				checked = i == value,
			}
		end
	end
	sort(list, function(a, b)
		local val = strcmputf8i(a.text, b.text)
		if val < 0 then return true
		elseif val > 0 then return false end
		return a.value < b.value
	end)
	return list
end

function conds.title:getFuncText(value)
	return "GetCurrentTitle() == "..value, "GetCurrentTitle"
end


---------------------------------------------------
-- METHODS
function conds:getMenuList(value, func)
	local combatStar = " (|cffff4444*|r)"
	local combatText = NIGHT_FAE_BLUE_COLOR:WrapTextInColorCode(combatStar:sub(2).." "..L["CONDITION_DATA_SECRET_INFO"])
	local list = {}

	local OnTooltipShow = function(btn, tooltip, v)
		GameTooltip_SetTitle(tooltip, v.text)
		if v.description then tooltip:AddLine(v.description, nil, nil, nil, true) end
		if v.combatLock then
			if v.description then tooltip:AddLine(" ") end
			tooltip:AddLine(combatText, nil, nil, nil, true)
		end
	end

	for k, v in next, self do
		if type(v) == "table" then
			list[#list + 1] = {
				text = v.combatLock and v.text..combatStar or v.text,
				value = k,
				arg1 = v,
				func = func,
				checked = k == value,
			}
			if v.description or v.combatLock then
				list[#list].OnTooltipShow = OnTooltipShow
			end
		end
	end
	sort(list, function(a, b) return strcmputf8i(a.text, b.text) < 0 end)
	return list
end


function conds:getFuncText(conds, keys, isGroup)
	local text = {}

	if isGroup == nil then
		local condText = conds.action and ns.actions[conds.action[1]].condText
		text[1] = condText and condText or "not (profileLoad or self.useMount)"
	end

	local i = 1
	local cond = conds[i]
	while cond ~= nil do
		local condt = self[cond[2]]
		if condt ~= nil then
			local condText, var, strict = condt:getFuncText(cond[3], cond[1])
			if var ~= nil and keys[var] ~= 1 then
				keys[var] = 1
				keys[#keys + 1] = var
			end
			if cond[1] and not strict then
				condText = "not "..condText
			end
			i = i + 1
			text[#text + 1] = condText
		else
			tremove(conds, i)
		end
		cond = conds[i]
	end
	return concat(text, "\nand ")
end
