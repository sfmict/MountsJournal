local _, ns = ...
local L = ns.L
local actions = {}
ns.actions = actions


---------------------------------------------------
-- mount
actions.rmount = {}
actions.rmount.text = L["Random Mount"]

function actions.rmount:getFuncText()
	return "return self:getMacro()\n"
end

---------------------------------------------------
-- mount
actions.mount = {}
actions.mount.text = L["Mount"]

function actions.mount:getValueText(spellID)
	if ns.additionalMounts[spellID] then
		return ns.additionalMounts[spellID].name
	else
		local mountID = C_MountJournal.GetMountFromSpell(spellID)
		if mountID then
			local name = C_MountJournal.GetMountInfoByID(mountID)
			return name
		end
	end
end

function actions.mount:getFuncText(spellID)
	return ([[
		if self.additionalMounts[%d] then
			return self.additionalMounts[%d].macro
		else
			return '/run MountsJournal:summon(%d)'
		end
	]]):format(spellID, spellID, spellID)
end


---------------------------------------------------
-- item
actions.item = {}
actions.item.text = L["Use Item"]

function actions.item:getValueText(spellID)
	return tostring(spellID or "")
end

function actions.item:getFuncText(itemID)
	return ("return '/use item:%d'\n"):format(itemID)
end


---------------------------------------------------
-- iitem
actions.iitem = {}
actions.iitem.text =L["Use Inventory Item"]

function actions.iitem:getValueText(spellID)
	return tostring(spellID or "")
end

function actions.iitem:getFuncText(slot)
	return ("return '/use %d'\n"):format(slot)
end


---------------------------------------------------
-- spell
actions.spell = {}
actions.spell.text = L["Cast Spell"]

function actions.spell:getValueText(spellID)
	return tostring(spellID or "")
end

function actions.spell:getFuncText(spellID)
	return ([[
		local spellName = self:getSpellName(%d)
		if spellName then
			return '/cast '..spellName
		end
	]]):format(spellID)
end


---------------------------------------------------
-- macro
actions.macro = {}
actions.macro.text = L["Macro"]

function actions.macro:getValueText(macroText)
	return macroText
end

function actions.macro:getFuncText(macroText)
	return ("return '%s'\n"):format(macroText:gsub("['\n\\]", "\\%1"))
end


---------------------------------------------------
-- METHODS
function actions:getMenuList(value, func)
	local list = {}
	local types = {
		"rmount",
		"mount",
		"spell",
		"item",
		"iitem",
		"macro",
	}
	for i = 1, #types do
		local v = types[i]
		list[i] = {
			text = self[v].text,
			value = v,
			func = func,
			checked = v == value,
		}
	end
	return list
end


function actions:getFuncText(action)
	return self[action[1]]:getFuncText(action[2])
end