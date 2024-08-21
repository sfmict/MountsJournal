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
	return ("SecureCmdOptionParse('%s')\n"):format(value:gsub("['\\]", "\\%1")), "SecureCmdOptionParse"
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
	local text = ""
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