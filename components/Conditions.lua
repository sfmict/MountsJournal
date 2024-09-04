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

function conds.mcond:getDescription()
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
	return ("%s (%d)"):format(holidayName or RED_FONT_COLOR:WrapTextInColorCode(L["Nameless holiday"]), value)
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
			text = ("%s (%d)"):format(e.isActive and ("%s (|cff00cc00%s|r)"):format(e.name, SPEC_ACTIVE) or e.name, e.eventID),
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

function conds.hitem:getDescription()
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

function conds.ritem:getDescription()
	return "ItemID"
end

function conds.ritem:getValueText(value)
	return tostring(value or "")
end

function conds.ritem:getFuncText(value)
	return ("C_Container.GetItemCooldown(%d) == 0"):format(value), "C_Container"
end


---------------------------------------------------
-- rspell READY SPELL
conds.rspell = {}
conds.rspell.text = L["Spell is ready"]
conds.rspell.isNumeric = true

function conds.rspell:getDescription()
	return "SpellID (61304 for GCD)"
end

function conds.rspell:getValueText(value)
	return tostring(value or "")
end

function conds.rspell:getFuncText(value)
	return ("self:isSpellReady(%d)"):format(value)
end


---------------------------------------------------
-- hbuff HAS BUFF
conds.hbuff = {}
conds.hbuff.text = L["The player has a buff"]
conds.hbuff.isNumeric = true

function conds.hbuff:getDescription()
	return "SpellID"
end

function conds.hbuff:getValueText(value)
	return tostring(value or "")
end

function conds.hbuff:getFuncText(value)
	return ("self:hasPlayerBuff(%d)"):format(value)
end


---------------------------------------------------
-- hdebuff HAS DEBUFF
conds.hdebuff = {}
conds.hdebuff.text = L["The player has a debuff"]
conds.hdebuff.isNumeric = true

function conds.hdebuff:getDescription()
	return "SpellID"
end

function conds.hdebuff:getValueText(value)
	return tostring(value or "")
end

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
		end
	end
	sort(list, function(a, b) return strcmputf8i(a.text, b.text) < 0 end)
	return list
end


function conds:getFuncText(conds)
	local text = conds.action[1] ~= "rmount" and "not profileLoad\nand " or ""
	local vars = {}
	for i = 1, #conds do
		local cond, var = conds[i]
		local condText, var = self[cond[2]]:getFuncText(cond[3])
		if var then vars[#vars + 1] = var end
		if i ~= 1 then text = text.."and " end
		if cond[1] then text = text.."not " end
		text = text..condText.."\n"
	end
	return text, #vars > 0 and vars
end