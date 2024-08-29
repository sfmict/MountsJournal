local _, ns = ...
local L, macroFrame, mounts = ns.L, ns.macroFrame, ns.mounts
local actions = {}
ns.actions = actions


---------------------------------------------------
-- rmount
actions.rmount = {}
actions.rmount.text = L["Random Mount"]

function actions.rmount:getValueText(profileName)
	if profileName == 0 then
		return L["Selected profile"]
	elseif profileName == 1 then
		return DEFAULT
	else
		return mounts.profiles[profileName] and profileName or RED_FONT_COLOR:WrapTextInColorCode(profileName)
	end
end

function actions.rmount:getValueList(value, func)
	local list = {}
	list[1] = {
		text = L["Selected profile"],
		func = func,
		value = 0,
		checked = value == 0,
	}
	list[2] = {
		text = DEFAULT,
		value = 1,
		func = func,
		checked = value == 1,
	}

	local profiles = {}
	for k in next, mounts.profiles do profiles[#profiles + 1] = k end
	sort(profiles)

	for i = 1, #profiles do
		local profile = profiles[i]
		list[#list + 1] = {
			text = profile,
			value = profile,
			func = func,
			checked = value == profile,
		}
	end

	return list
end

function actions.rmount:getFuncText(value)
	if value == 0 then
		return [[
			self.mounts:setMountsList(self.mounts.sp)
			profileLoad = true
		]]
	elseif value == 1 then
		return [[
			self.mounts:setMountsList(self.mounts.defProfile)
			profileLoad = true
		]]
	else
		return ([[
			local profile = self.mounts.profiles['%s']
			self.mounts:setMountsList(profile)
			profileLoad = true
		]]):format(value:gsub("[\\']", "\\%1"))
	end
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
	local macro
	if macroFrame.additionalMounts[spellID] then
		macro = macroFrame.additionalMounts[spellID].macro
	else
		macro = ('/run MountsJournal:summon(%d)'):format(spellID)
	end

	return ([[
		%s
		-- EXIT VEHICLE
		if self.sFlags.inVehicle then
			return "/leavevehicle"
		-- DISMOUNT
		elseif self.sFlags.isMounted then
			if not self.lastUseTime or GetTime() - self.lastUseTime > .5 then
				return "/dismount"
			end
		-- MOUNT
		else
			return self:addLine(self:getDefMacro(), '%s')
		end
	]]):format(macroFrame.classDismount or "", macro:gsub("[\\']", "\\%1")),
	{"GetTime"}
end


---------------------------------------------------
-- item
actions.item = {}
actions.item.text = L["Use Item"]

function actions.item:getDescription()
	return "ItemID"
end

function actions.item:getValueText(spellID)
	return tostring(spellID or "")
end

function actions.item:getFuncText(itemID)
	return ("return '/use item:%d'\n"):format(itemID)
end


---------------------------------------------------
-- iitem
actions.iitem = {}
actions.iitem.text = L["Use Inventory Item"]

function actions.iitem:getDescription()
	local list = {
		INVTYPE_HEAD,
		INVTYPE_NECK,
		INVTYPE_SHOULDER,
		INVTYPE_BODY,
		INVTYPE_CHEST,
		INVTYPE_WAIST,
		INVTYPE_LEGS,
		INVTYPE_FEET,
		INVTYPE_WRIST,
		INVTYPE_HAND,
		INVTYPE_FINGER.." 1",
		INVTYPE_FINGER.." 2",
		INVTYPE_TRINKET.." 1",
		INVTYPE_TRINKET.." 2",
		INVTYPE_CLOAK,
		INVTYPE_WEAPONMAINHAND,
		INVTYPE_WEAPONOFFHAND,
		INVTYPE_RANGED,
		INVTYPE_TABARD,
	}
	local description = ""
	for i = 1, #list do
		local slot = list[i]
		description = description..("%s = %s\n"):format(list[i], i)
	end
	return description
end

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

function actions.spell:getDescription()
	return "SpellID"
end

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
actions.macro.text = MACRO

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
		local action = self[v]
		list[i] = {
			text = action.text,
			value = v,
			func = func,
			checked = v == value,
			arg1 = action.getDescription and action:getDescription(),
		}
	end
	return list
end


function actions:getFuncText(action)
	return self[action[1]]:getFuncText(action[2])
end