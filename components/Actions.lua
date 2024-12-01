local _, ns = ...
local L, macroFrame, mounts = ns.L, ns.macroFrame, ns.mounts
local strcmputf8i = strcmputf8i
local actions = {}
ns.actions = actions


---------------------------------------------------
-- rmount RANDOM MOUNT
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
		value = 0,
		func = func,
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
	sort(profiles, function(a, b) return strcmputf8i(a, b) < 0 end)

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
			profileLoad = 1
		]]
	elseif value == 1 then
		return [[
			self.mounts:setMountsList(self.mounts.defProfile)
			profileLoad = 1
		]]
	else
		return ([[
			local profile = self.mounts.profiles['%s']
			self.mounts:setMountsList(profile)
			profileLoad = 1
		]]):format(value:gsub("[\\']", "\\%1"))
	end
end


---------------------------------------------------
-- rmountr RANDOM MOUNT BY RARITY
actions.rmountr = {}
actions.rmountr.text = L["Random Mount by Rarity"]
actions.rmountr.description = L["The lower the rarity, the higher the chance"]

actions.rmountr.getValueText = actions.rmount.getValueText

actions.rmountr.getValueList = actions.rmount.getValueList

function actions.rmountr:getFuncText(value)
	local text = [[
		profileLoad = 1
		self.sFlags.rarityWeight = true
	]]
	if value == 0 then
		return [[
			self.mounts:setMountsList(self.mounts.sp)
		]]..text
	elseif value == 1 then
		return [[
			self.mounts:setMountsList(self.mounts.defProfile)
		]]..text
	else
		return ([[
			local profile = self.mounts.profiles['%s']
			self.mounts:setMountsList(profile)
			%s
		]]):format(value:gsub("[\\']", "\\%1"), text)
	end
end


---------------------------------------------------
-- mount
actions.mount = {}
actions.mount.text = L["Mount"]

function actions.mount:getValueText(value)
	if ns.additionalMounts[value] then
		return ns.additionalMounts[value].name
	else
		local mountID = C_MountJournal.GetMountFromSpell(value)
		if mountID then
			local name = C_MountJournal.GetMountInfoByID(mountID)
			return name
		end
	end
end

function actions.mount:getFuncText(value)
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
		elseif not (noMacro and self.additionalMounts[%s]) then
			self.useMount = %s
		end
	]]):format(macroFrame.classDismount or "", value, value),
	{"GetTime"}
end


---------------------------------------------------
-- dmount DISMOUNT
actions.dmount = {}
actions.dmount.text = BINDING_NAME_DISMOUNT

function actions.dmount:getFuncText()
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
		end
	]]):format(macroFrame.classDismount or ""),
	{"GetTime"}
end


---------------------------------------------------
-- item
actions.item = {}
actions.item.text = L["Use Item"]

function actions.item:getValueDescription()
	return "ItemID"
end

function actions.item:getValueText(value)
	return tostring(value or "")
end

function actions.item:getFuncText(value)
	return ("return '/use item:%d'"):format(value)
end


---------------------------------------------------
-- iitem INVENTORY ITEM
actions.iitem = {}
actions.iitem.text = L["Use Inventory Item"]

function actions.iitem:getValueDescription()
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
		description = ("%s%s = %s\n"):format(description, i, list[i])
	end
	return description
end

actions.iitem.getValueText = actions.item.getValueText

function actions.iitem:getFuncText(slot)
	return ("return '/use %d'"):format(slot)
end


---------------------------------------------------
-- spell
actions.spell = {}
actions.spell.text = L["Cast Spell"]

function actions.spell:getValueDescription()
	return "SpellID"
end

actions.spell.getValueText = actions.item.getValueText

function actions.spell:getFuncText(value)
	return ([[
		local spellName = self:getSpellName(%d)
		if spellName then
			return '/cast '..spellName
		end
	]]):format(value)
end


---------------------------------------------------
-- macro
actions.macro = {}
actions.macro.text = MACRO
actions.macro.maxLetters = 255

function actions.macro:getValueText(value)
	return value
end

function actions.macro:getFuncText(value)
	return ("return '%s'"):format(value:gsub("['\n\\]", "\\%1"))
end


---------------------------------------------------
-- pmacro PRE MACRO
actions.pmacro = {}
actions.pmacro.text = L["Use macro before mounting"]
actions.pmacro.description = L["PMACRO_DESCRIPTION"]
actions.pmacro.maxLetters = 200

actions.pmacro.getValueText = actions.macro.getValueText

function actions.pmacro:getFuncText(value)
	return ("self.preUseMacro = '%s'"):format(value:gsub("['\n\\]", "\\%1"))
end


---------------------------------------------------
-- METHODS
function actions:getMenuList(value, func)
	local list = {}
	local types = {
		"rmount",
		"rmountr",
		"mount",
		"dmount",
		"spell",
		"item",
		"iitem",
		"macro",
		"pmacro",
	}
	for i = 1, #types do
		local v = types[i]
		local action = self[v]
		list[i] = {
			text = action.text,
			value = v,
			func = func,
			checked = v == value,
		}
		if action.description then
			list[i].OnTooltipShow = function(btn, tooltip)
				GameTooltip_SetTitle(tooltip, action.text)
				tooltip:AddLine(action.description, nil, nil, nil, true)
			end
		end
	end
	return list
end


function actions:getFuncText(action)
	return self[action[1]]:getFuncText(action[2])
end