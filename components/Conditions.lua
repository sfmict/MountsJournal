local _, ns = ...
local L = ns.L
local strcmputf8i = strcmputf8i
local conds = {}
ns.conditions = conds


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
	local list =  {}
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
		return ("button == 'Button%d'"):format(value)
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
		return classColor:WrapTextInColorCode(localized)
	end
end

function conds.class:getValueList(value, func)
	local list = {}

	for i = 1, GetNumClasses() do
		local _,_, id = GetClassInfo(i)
		list[i] = {
			text = self:getValueText(id),
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
	local _, name, _,_,_, className, class = GetSpecializationInfoByID(value)
	if name then
		local classColor = C_ClassColor.GetClassColor(className)
		return ("%s - %s"):format(classColor:WrapTextInColorCode(class), name)
	end
end

function conds.spec:getValueList(value, func)
	local list = {}

	for i = 1, GetNumClasses() do
		for j = 1, GetNumSpecializationsForClassID(i) do
			local id = GetSpecializationInfoForClassID(i, j)
			list[#list + 1] = {
				text = self:getValueText(id),
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
	for i = 1,  GetNumSpecializations() do
		if value == GetSpecializationInfo(i) then
			index = i
			break
		end
	end
	if index then
		return "GetSpecialization() == "..index, "GetSpecialization"
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
	return ("%s |cff808080(ID:%d)|r"):format(holidayName or RED_FONT_COLOR:WrapTextInColorCode(L["Nameless holiday"]), value)
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

	local eList = ns.calendar:getHolidayList()
	for i = 1, #eList do
		local e = eList[i]
		subList[i] = {
			text = ("%s |cff808080(ID:%d)|r"):format(e.isActive and ("%s (|cff00cc00%s|r)"):format(e.name, SPEC_ACTIVE) or e.name, e.eventID),
			arg1 = e.name,
			value = e.eventID,
			func = func,
			checked = e.eventID == value,
		}
	end

	return list
end

function conds.holiday:getFuncText(value)
	return ("self.calendar:isHolidayActive(%d)"):format(value)
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
-- fs FLIGHT STYLE
conds.fs = {}
conds.fs.text = L["Flight style"]

function conds.fs:getValueText(value)
	return value == 1 and DYNAMIC_FLIGHT or L["Steady Flight"]
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
		return ("C_Spell.GetSpellTexture(%d) ~= 5142726"):format(spellID), "C_Spell"
	else
		return ("C_Spell.GetSpellTexture(%d) == 5142726"):format(spellID), "C_Spell"
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

function conds.hitem:getValueText(value)
	return tostring(value or "")
end

function conds.hitem:getFuncText(value)
	return ("C_Item.GetItemCount(%d) > 0"):format(value), "C_Item"
end


---------------------------------------------------
-- ritem READY ITEM
conds.ritem = {}
conds.ritem.text = L["Item is ready"]
conds.ritem.isNumeric = true

conds.ritem.getValueDescription = conds.hitem.getValueDescription

conds.ritem.getValueText = conds.hitem.getValueText

function conds.ritem:getFuncText(value)
	return ("C_Container.GetItemCooldown(%d) == 0"):format(value), "C_Container"
end


---------------------------------------------------
-- kspell KNOWN SPELL
conds.kspell = {}
conds.kspell.text = L["Spell is known"]
conds.kspell.isNumeric = true

function conds.kspell:getValueDescription()
	return "SpellID"
end

conds.kspell.getValueText = conds.hitem.getValueText

function conds.kspell:getFuncText(value)
	return ("IsPlayerSpell(%d)"):format(value), "IsPlayerSpell"
end


---------------------------------------------------
-- rspell READY SPELL
conds.rspell = {}
conds.rspell.text = L["Spell is ready"]
conds.rspell.isNumeric = true

function conds.rspell:getValueDescription()
	return "SpellID (61304 for GCD)"
end

conds.rspell.getValueText = conds.hitem.getValueText

function conds.rspell:getFuncText(value)
	return ("self:isSpellReady(%d)"):format(value)
end


---------------------------------------------------
-- hbuff HAS BUFF
conds.hbuff = {}
conds.hbuff.text = L["The player has a buff"]
conds.hbuff.isNumeric = true

conds.hbuff.getValueDescription = conds.kspell.getValueDescription

conds.hbuff.getValueText = conds.hitem.getValueText

function conds.hbuff:getFuncText(value)
	return ("self:hasPlayerBuff(%d)"):format(value)
end


---------------------------------------------------
-- hdebuff HAS DEBUFF
conds.hdebuff = {}
conds.hdebuff.text = L["The player has a debuff"]
conds.hdebuff.isNumeric = true

conds.hdebuff.getValueDescription = conds.kspell.getValueDescription

conds.hdebuff.getValueText = conds.hitem.getValueText

function conds.hdebuff:getFuncText(value)
	return ("self:hasPlayerDebuff(%d)"):format(value)
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
}
local RACE_LABELS = {}

for i = 1, #RACE_KEYS do
	local info = C_CreatureInfo.GetRaceInfo(RACE_KEYS[i])
	RACE_KEYS[i] = info.clientFileString
	RACE_LABELS[info.clientFileString] = info.raceName
end
sort(RACE_KEYS, function(a,b) return strcmputf8i(RACE_LABELS[a], RACE_LABELS[b]) < 0 end)

function conds.race:getValueText(value)
	return RACE_LABELS[value]
end

function conds.race:getValueList(value, func)
	local list = {}
	for i = 1, #RACE_KEYS do
		local v = RACE_KEYS[i]
		list[#list + 1] = {
			text = self:getValueText(v),
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
		local mapInfo = ns.util.getMapFullNameInfo(value)
		if mapInfo then return mapInfo.name end
	end
end

function conds.map:getFuncText(value)
	return ("self:checkMap(%d)"):format(value)
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
			hasArrow =  true,
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
		return ("self.mounts.instanceID == %d"):format(tonumber(value))
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
		local n = {name}

		if instanceType == "raid" then
			n[#n + 1] = LEGENDARY_ORANGE_COLOR:WrapTextInColorCode(RAID)
		elseif instanceType == "party" then
			n[#n + 1] = EPIC_PURPLE_COLOR:WrapTextInColorCode(LFG_TYPE_DUNGEON)
		end

		if isLFR then n[#n + 1] = HEIRLOOM_BLUE_COLOR:WrapTextInColorCode(("%d - %d"):format(minPlayers, maxPlayers)) end
		if IsLegacyDifficulty(value) then n[#n + 1] = ARTIFACT_GOLD_COLOR:WrapTextInColorCode(LFG_LIST_LEGACY) end

		return table.concat(n, " | ")
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
	return ("self.mounts.difficultyID == %d"):format(value)
end


---------------------------------------------------
-- tmog TRANSMOG
conds.tmog = {}
conds.tmog.text = PERKS_VENDOR_CATEGORY_TRANSMOG

function conds.tmog:getValueText(value)
	if type(value) == "number" then
		local setInfo = C_TransmogSets.GetSetInfo(value)
		if setInfo then
			if setInfo.description then
				return ("%s - %s (%s)"):format(WARDROBE_SETS, setInfo.name, setInfo.description)
			else
				return ("%s - %s"):format(WARDROBE_SETS, setInfo.name)
			end
		end
	else
		return ("%s - %s"):format(TRANSMOG_OUTFIT_HYPERLINK_TEXT:match("|t(.*)"), value)
	end
end

function conds.tmog:getValueList(value, func)
	local outfitList = {}
	for i, id in ipairs(C_TransmogCollection.GetOutfits()) do
		local name, icon = C_TransmogCollection.GetOutfitInfo(id)
		outfitList[i] = {
			text = name,
			value = name,
			icon = icon,
			func = func,
			checked = name == value,
		}
	end

	if #outfitList == 0 then
		outfitList[1] = {
			notCheckable = true,
			disabled = true,
			text = EMPTY,
		}
	end

	local function set_OnEnter(btn)
		MJTooltipModel.model:SetFromModelSceneID(290)
		local actor = MJTooltipModel.model:GetPlayerActor()
		actor:SetModelByUnit("player", false, false, false, true)

		local primaryAppearances = C_TransmogSets.GetSetPrimaryAppearances(btn.value)
		for i = 1, #primaryAppearances do
			actor:TryOn(primaryAppearances[i].appearanceID)
		end

		MJTooltipModel:ClearAllPoints()
		MJTooltipModel:SetPoint("LEFT", btn, "RIGHT", 5, 0)
		MJTooltipModel:Show()
	end

	local function set_OnLeave(btn)
		MJTooltipModel:Hide()
	end

	local setList = {}
	for i, set in ipairs(C_TransmogSets.GetUsableSets()) do
		local setInfo = C_TransmogSets.GetSetInfo(set.setID)
		setList[i] = {
			text = setInfo.description and ("%s (%s)"):format(setInfo.name, setInfo.description) or setInfo.name,
			value = set.setID,
			func = func,
			checked = set.setID == value,
			OnEnter = set_OnEnter,
			OnLeave = set_OnLeave,
		}
	end
	sort(setList, function(a, b) return strcmputf8i(a.text, b.text) < 0 end)

	if #setList == 0 then
		setList[1] = {
			notCheckable = true,
			disabled = true,
			text = EMPTY,
		}
	end

	return {
		{
			keepShownOnClick = true,
			notCheckable = true,
			hasArrow = true,
			text = TRANSMOG_OUTFIT_HYPERLINK_TEXT:match("|t(.*)"),
			value = outfitList,
		},
		{
			keepShownOnClick = true,
			notCheckable = true,
			hasArrow = true,
			text = WARDROBE_SETS,
			value = setList,
		},
	}
end

function conds.tmog:getFuncText(value)
	if type(value) == "number" then
		return ("self:isTransmogSetActive(%d)"):format(value)
	else
		return ("self:isTtransmogOutfitActive('%s')"):format(value:gsub("['\\]", "\\%1"))
	end
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
			local v = ("%s:%d"):format(unit, j)
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
	local guid = UnitGUID("player")

	for i = 1, GetNumSpecializations() do
		local specID, specName = GetSpecializationInfo(i)
		local configIDs = C_ClassTalents.GetConfigIDsBySpecID(specID)
		for j = 1, #configIDs do
			local configID = configIDs[j]
			local configInfo = C_Traits.GetConfigInfo(configID)
			local v = ("%d:%s"):format(configID, guid)
			list[#list + 1] = {
				text = ("%s - %s |cff808080(ID:%d)|r"):format(configInfo.name, specName, configID),
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
				text = ("%s |cff808080(%s)|r"):format(trackingInfo.name, v),
				value = v,
				func = func,
				checked = v == value,
			}

			if TRACKING_SPELL_OVERRIDE_ATLAS[trackingInfo.spellID] then
				local atlasInfo = C_Texture.GetAtlasInfo(TRACKING_SPELL_OVERRIDE_ATLAS[trackingInfo.spellID])
				info.icon = atlasInfo.file
				info.iconInfo = {
					tCoordLeft = atlasInfo.leftTexCoord,
					tCoordRight = atlasInfo.rightTexCoord,
					tCoordTop = atlasInfo.topTexCoord,
					tCoordBottom = atlasInfo.bottomTexCoord,
				}
			else
				info.icon = trackingInfo.texture
			end

			if trackingInfo.subType == HUNTER_TRACKING then
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
	return ("self.mounts.profs[%d]"):format(value)
end


---------------------------------------------------
-- equips EQUIPMENT SET
conds.equips = {}
conds.equips.text = PAPERDOLL_EQUIPMENTMANAGER

function conds.equips:getValueText(value)
	local setID, guid = (":"):split(value, 2)
	if guid == UnitGUID("player") then
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
	local guid = UnitGUID("player")

	for i, setID in ipairs(C_EquipmentSet.GetEquipmentSetIDs()) do
		local name, iconFileID = C_EquipmentSet.GetEquipmentSetInfo(setID)
		local v = ("%d:%s"):format(setID, guid)
		list[i] = {
			text = ("%s |cff808080(ID:%d)|r"):format(name, setID),
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
	if guid == UnitGUID("player") then
		return ("self:checkEquipmentSet(%s)"):format(setID)
	end
	return "false"
end


---------------------------------------------------
-- equipi EQUIPPED ITEM
conds.equipi = {}
conds.equipi.text = L["Item is equipped"]

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
	local rules = ns.ruleConfig.rules
	for i = 1, #rules do
		local action = rules[i].action
		if action[1] == "sstate" and action[2] == value then
			return value
		end
	end
	return RED_FONT_COLOR:WrapTextInColorCode(value)
end

function conds.gstate:getValueList(value, func)
	local list = {}
	local rules = ns.ruleConfig.rules

	for i = 1, #rules do
		local action = rules[i].action
		if action[1] == "sstate" then
			list[#list + 1] = {
				text = action[2],
				value = action[2],
				func = func,
				checked = action[2] == value,
			}
		end
	end

	if #list == 0 then
		list[1] = {
			notCheckable = true,
			disabled = true,
			text = EMPTY,
		}
	elseif #list > 1 then
		sort(list, function(a, b) return strcmputf8i(a.text, b.text) < 0 end)
	end

	return list
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
-- METHODS
function conds:getMenuList(value, func)
	local list = {}
	for k, v in next, self do
		if type(v) == "table" then
			list[#list + 1] = {
				text = v.text,
				value = k,
				func = func,
				checked = k == value,
			}
			if v.description then
				list[#list].OnTooltipShow = function(btn, tooltip)
					GameTooltip_SetTitle(tooltip, v.text)
					tooltip:AddLine(v.description, nil, nil, nil, true)
				end
			end
		end
	end
	sort(list, function(a, b) return strcmputf8i(a.text, b.text) < 0 end)
	return list
end


function conds:getFuncText(conds)
	local actionType, text = conds.action[1]
	if actionType == "rmount" or actionType == "rmountr" then
		text = "profileLoad ~= 2\nand "
	elseif actionType == "rmountt" or actionType == "rmounttr" then
		text = "(not profileLoad or profileLoad == true)\nand "
	elseif actionType == "mount" then
		text = "(not profileLoad or profileLoad == true) and not self.useMount\nand "
	else
		text = "not (profileLoad or self.useMount)\nand "
		if actionType == "pmacro" then
			text = text.."not self.preUseMacro\nand "
		end
	end

	local vars = {}
	for i = 1, #conds do
		local cond = conds[i]
		local condText, var = self[cond[2]]:getFuncText(cond[3])
		if var then vars[#vars + 1] = var end
		if i ~= 1 then text = text.."and " end
		if cond[1] then text = text.."not " end
		text = text..condText.."\n"
	end
	return text, #vars > 0 and vars
end