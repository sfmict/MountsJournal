local _, ns = ...
local conditions = {}
ns.conditions = conditions


conditions.mod = function(v)
	if v == "any" then
		return "IsModifierKeyDown()"
	elseif v == "alt" then
		return "IsAltKeyDown()"
	elseif v == "ctrl" then
		return "IsControlKeyDown()"
	elseif v == "shift" then
		return "IsShiftKeyDown()"
	elseif v == "lalt" then
		return "IsLeftAltKeyDown()"
	elseif v == "ralt" then
		return "IsRightAltKeyDown()"
	elseif v == "lctrl" then
		return "IsLeftControlKeyDown()"
	elseif v == "rctrl" then
		return "IsRightoControlKeyDown()"
	elseif v == "lshift" then
		return "IsLeftShiftKeyDown()"
	elseif v == "rshift" then
		return "IsRightShiftKeyDown()"
	else
		return "false"
	end
end


conditions.btn = function(v)
	if v == 1 then
		return "button == 'LeftButton'"
	elseif v == 2 then
		return "button == 'RightButton'"
	elseif v == 3 then
		return "button == 'MiddleButton'"
	else
		return ("button == 'Button%d'"):format(v)
	end
end


function conditions:getText(conds)
	local text = ""
	for i = 1, #conds do
		local cond = conds[i]
		if i ~= 1 then text = text.."and " end
		if cond[1] then text = text.."not " end
		text = text..self[cond[2]](cond[3]).."\n"
	end
	return text
end