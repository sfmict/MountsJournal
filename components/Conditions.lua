local _, ns = ...
local L = ns.L
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
	sort(list, function(a, b) return a.text < b.text end)
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
conds.falling.text = STRING_ENVIRONMENTAL_DAMAGE_FALLING

function conds.falling:getFuncText()
	return "IsFalling()", "IsFalling"
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
	sort(list, function(a, b) return a.text < b.text end)
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