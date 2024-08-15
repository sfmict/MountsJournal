local _, ns = ...
local L = ns.L
local conds = {}
ns.conditions = conds


---------------------------------------------------
-- mod
conds.mod = {}
conds.mod.text = L["Modifier"]

function conds.mod:getValueText(value)
	if value == "any" then
		return L["Any"]
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
		return "IsModifierKeyDown()"
	elseif value == "alt" then
		return "IsAltKeyDown()"
	elseif value == "ctrl" then
		return "IsControlKeyDown()"
	elseif value == "shift" then
		return "IsShiftKeyDown()"
	elseif value == "lalt" then
		return "IsLeftAltKeyDown()"
	elseif value == "ralt" then
		return "IsRightAltKeyDown()"
	elseif value == "lctrl" then
		return "IsLeftControlKeyDown()"
	elseif value == "rctrl" then
		return "IsRightoControlKeyDown()"
	elseif value == "lshift" then
		return "IsLeftShiftKeyDown()"
	elseif value == "rshift" then
		return "IsRightShiftKeyDown()"
	else
		return "false"
	end
end


---------------------------------------------------
-- btn
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
	for i = 1, #conds do
		local cond = conds[i]
		if i ~= 1 then text = text.."and " end
		if cond[1] then text = text.."not " end
		text = text..self[cond[2]]:getFuncText(cond[3]).."\n"
	end
	return text
end