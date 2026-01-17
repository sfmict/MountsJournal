local _, ns = ...
local L, util, macroFrame, mounts, conds = ns.L, ns.util, ns.macroFrame, ns.mounts, ns.conditions
local strcmputf8i = strcmputf8i
local ltl = LibStub("LibThingsLoad-1.0")
local actions = {}
ns.actions = actions


---------------------------------------------------
-- rmount RANDOM MOUNT
actions.rmount = {}
actions.rmount.text = L["Random Mount"]

function actions.rmount:getIcon()
	return 413588
end

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

actions.rmount.condText = "profileLoad ~= 2"

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
-- rmountt RANDOM MOUNT OF SELECTED TYPE
actions.rmountt = {}
actions.rmountt.text = L["Random Mount of Selected Type"]

function actions.rmountt:getIcon()
	return 413588, "T"
end

function actions.rmountt:getValueText(value)
	local mType, profile = (":"):split(value, 2)
	if profile == "0" then
		profile = L["Selected profile"]
	elseif profile == "1" then
		profile = DEFAULT
	elseif not mounts.profiles[profile] then
		profile = RED_FONT_COLOR:WrapTextInColorCode(profile)
	end
	return ("%s - %s"):format(profile, L["MOUNT_TYPE_"..mType])
end

function actions.rmountt:getValueList(value, func)
	local function getTList(profile)
		local tList = {}
		for i = 1, 3 do
			local v = i..":"..profile
			tList[i] = {
				text = L["MOUNT_TYPE_"..i],
				value = v,
				func = func,
				checked = v == value,
			}
		end
		return tList
	end

	local list = {}
	list[1] = {
		keepShownOnClick = true,
		notCheckable = true,
		hasArrow = true,
		text = L["Selected profile"],
		value = getTList(0)
	}
	list[2] = {
		keepShownOnClick = true,
		notCheckable = true,
		hasArrow = true,
		text = DEFAULT,
		value = getTList(1)
	}

	local profiles = {}
	for k in next, mounts.profiles do profiles[#profiles + 1] = k end
	sort(profiles, function(a, b) return strcmputf8i(a, b) < 0 end)

	for i = 1, #profiles do
		local profile = profiles[i]
		list[#list + 1] = {
			keepShownOnClick = true,
			notCheckable = true,
			hasArrow = true,
			text = profile,
			value = getTList(profile),
		}
	end

	return list
end

actions.rmountt.condText = "(not profileLoad or profileLoad == true)"

function actions.rmountt:getFuncText(value)
	local mType, profile = (":"):split(value, 2)

	if mType == "1" then
		mType = "fly"
	elseif mType == "2" then
		mType = "ground"
	else
		mType = "swimming"
	end

	local str = ("profileLoad = 2\nself.summonMType = '%s'\n"):format(mType)
	if profile == "0" then
		return str.."self.mounts:setMountsList(self.mounts.sp)"
	elseif profile == "1" then
		return str.."self.mounts:setMountsList(self.mounts.defProfile)"
	else
		return ("%sself.mounts:setMountsList(self.mounts.profiles['%s'])"):format(str, profile:gsub("[\\']", "\\%1"))
	end
end


---------------------------------------------------
-- rmountr RANDOM MOUNT BY RARITY
actions.rmountr = {}
actions.rmountr.text = L["Random Mount by Rarity"]
actions.rmountr.description = L["The lower the rarity, the higher the chance"]

function actions.rmountr:getIcon()
	return 413588, nil, 1, .5, 1
end

actions.rmountr.getValueText = actions.rmount.getValueText
actions.rmountr.getValueList = actions.rmount.getValueList
actions.rmountr.condText = actions.rmount.condText

function actions.rmountr:getFuncText(value)
	if value == 0 then
		return [[
			self.mounts:setMountsList(self.mounts.sp, self.mounts.rarityWeight)
			profileLoad = 1
		]]
	elseif value == 1 then
		return [[
			self.mounts:setMountsList(self.mounts.defProfile, self.mounts.rarityWeight)
			profileLoad = 1
		]]
	else
		return ([[
			local profile = self.mounts.profiles['%s']
			self.mounts:setMountsList(profile, self.mounts.rarityWeight)
			profileLoad = 1
		]]):format(value:gsub("[\\']", "\\%1"))
	end
end


---------------------------------------------------
-- rmounttr RANDOM MOUNT OF SELECTED TYPE BY RARITY
actions.rmounttr = {}
actions.rmounttr.text = L["Random Mount of Selected Type by Rarity"]
actions.rmounttr.description = L["The lower the rarity, the higher the chance"]

function actions.rmounttr:getIcon()
	return 413588, "T", 1, .5, 1
end

actions.rmounttr.getValueText = actions.rmountt.getValueText
actions.rmounttr.getValueList = actions.rmountt.getValueList
actions.rmounttr.condText = actions.rmountt.condText

function actions.rmounttr:getFuncText(value)
	local mType, profile = (":"):split(value, 2)

	if mType == "1" then
		mType = "fly"
	elseif mType == "2" then
		mType = "ground"
	else
		mType = "swimming"
	end

	local str = ("profileLoad = 2\nself.summonMType = '%s'\n"):format(mType)
	if profile == "0" then
		return str.."self.mounts:setMountsList(self.mounts.sp, self.mounts.rarityWeight)"
	elseif profile == "1" then
		return str.."self.mounts:setMountsList(self.mounts.defProfile, self.mounts.rarityWeight)"
	else
		return ("%sself.mounts:setMountsList(self.mounts.profiles['%s'], self.mounts.rarityWeight)"):format(str, profile:gsub("[\\']", "\\%1"))
	end
end


---------------------------------------------------
-- rmountc RANDOM MOUNT BY SUMMON COUNTER
actions.rmountc = {}
actions.rmountc.text = L["Random Mount by Summon Counter"]
actions.rmountc.description = L["The lower the counter, the higher the chance"]

function actions.rmountc:getIcon()
	return 413588, nil, .2, .5, 1
end

actions.rmountc.getValueText = actions.rmount.getValueText
actions.rmountc.getValueList = actions.rmount.getValueList
actions.rmountc.condText = actions.rmount.condText

function actions.rmountc:getFuncText(value)
	if value == 0 then
		return [[
			self.mounts:setMountsList(self.mounts.sp, self.mounts.counterWeight)
			profileLoad = 1
		]]
	elseif value == 1 then
		return [[
			self.mounts:setMountsList(self.mounts.defProfile, self.mounts.counterWeight)
			profileLoad = 1
		]]
	else
		return ([[
			local profile = self.mounts.profiles['%s']
			self.mounts:setMountsList(profile, self.mounts.counterWeight)
			profileLoad = 1
		]]):format(value:gsub("[\\']", "\\%1"))
	end
end


---------------------------------------------------
-- rmounttc RANDOM MOUNT OF SELECTED TYPE BY SUMMON COUNTER
actions.rmounttc = {}
actions.rmounttc.text = L["Random Mount of Selected Type by Summon Counter"]
actions.rmounttc.description = L["The lower the counter, the higher the chance"]

function actions.rmounttc:getIcon()
	return 413588, "T", .2, .5, 1
end

actions.rmounttc.getValueText = actions.rmountt.getValueText
actions.rmounttc.getValueList = actions.rmountt.getValueList
actions.rmounttc.condText = actions.rmountt.condText

function actions.rmounttc:getFuncText(value)
	local mType, profile = (":"):split(value, 2)

	if mType == "1" then
		mType = "fly"
	elseif mType == "2" then
		mType = "ground"
	else
		mType = "swimming"
	end

	local str = ("profileLoad = 2\nself.summonMType = '%s'\n"):format(mType)
	if profile == "0" then
		return str.."self.mounts:setMountsList(self.mounts.sp, self.mounts.counterWeight)"
	elseif profile == "1" then
		return str.."self.mounts:setMountsList(self.mounts.defProfile, self.mounts.counterWeight)"
	else
		return ("%sself.mounts:setMountsList(self.mounts.profiles['%s'], self.mounts.counterWeight)"):format(str, profile:gsub("[\\']", "\\%1"))
	end
end


---------------------------------------------------
-- mount
actions.mount = {}
actions.mount.text = L["Mount"]

function actions.mount:getIcon(value)
	local mount = ns.additionalMounts[value]
	if mount then
		return mount.icon
	else
		local mountID = C_MountJournal.GetMountFromSpell(value)
		if mountID then
			local _,_, icon = C_MountJournal.GetMountInfoByID(mountID)
			return icon
		end
	end
end

function actions.mount:getValueText(value, noIcon)
	local mount = ns.additionalMounts[value]
	if mount then
		return noIcon and mount.name or CreateSimpleTextureMarkup(mount.icon, ns.RULE_ICON_SIZE)..mount.name
	else
		local mountID = C_MountJournal.GetMountFromSpell(value)
		if mountID then
			local name, _, icon = C_MountJournal.GetMountInfoByID(mountID)
			return (noIcon or not icon) and name or CreateSimpleTextureMarkup(icon, ns.RULE_ICON_SIZE)..name
		end
	end
end

actions.mount.condText = "(not profileLoad or profileLoad == true) and not self.useMount"

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
			return ""
		-- MOUNT
		elseif not (noMacro and self.additionalMounts[%s]) then
			self.useMount = %s
		end
	]]):format(macroFrame.classDismount or "", value, value),
	{"GetTime"}
end


---------------------------------------------------
-- mount TARGET MOUNT
actions.tmount = {}
actions.tmount.text = L["CopyMountTarget"]
actions.tmount.description = L["TMOUNT_DESCRIPTION"]

function actions.tmount:getIcon()
	return 524052
end

actions.tmount.condText = actions.mount.condText

function actions.tmount:getFuncText()
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
			return ""
		-- MOUNT
		elseif self.sFlags.targetMount and not (noMacro and self.sFlags.targetMountAdditional) then
			self.useMount = self.sFlags.targetMount
		end
	]]):format(macroFrame.classDismount or ""),
	{"GetTime"}
end


---------------------------------------------------
-- dmount DISMOUNT
actions.dmount = {}
actions.dmount.text = BINDING_NAME_DISMOUNT

function actions.dmount:getIcon()
	return 237700
end

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
			return ""
		end
	]]):format(macroFrame.classDismount or ""),
	{"GetTime"}
end


---------------------------------------------------
-- item
actions.item = {}
actions.item.text = L["Use Item"]
actions.item.isNumeric = true

function actions.item:getIcon(value)
	return ltl:GetItemIcon(value)
end

actions.item.getValueDescription = conds.hitem.getValueDescription
actions.item.setValueLink = conds.hitem.setValueLink
actions.item.receiveDrag = conds.hitem.receiveDrag
actions.item.getValueDisplay = conds.hitem.getValueDisplay
actions.item.getValueText = conds.hitem.getValueText

function actions.item:getFuncText(value)
	return ("return '/use item:%s'"):format(value)
end


---------------------------------------------------
-- iitem INVENTORY ITEM
actions.iitem = {}
actions.iitem.text = L["Use Inventory Item"]
actions.iitem.isNumeric = true

function actions.iitem:getIcon(value)
	return GetInventoryItemTexture("player", value)
end

local function getInventoryList()
	return {
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
end

function actions.iitem:getValueDescription()
	local list = getInventoryList()
	local description = ""
	for i = 1, #list do
		local slot = list[i]
		description = ("%s%s = %s\n"):format(description, i, list[i])
	end
	return description
end

function actions.iitem:setValueLink(FontString, value)
	if value then
		local link = GetInventoryItemLink("player", value)
		FontString:SetText(util.getIconLink(link, GetInventoryItemTexture("player", value)))
	else
		FontString:SetText()
	end
end

function actions.iitem:getValueDisplay(value)
	return getInventoryList()[value]
end

actions.iitem.getValueText = actions.item.getValueText

function actions.iitem:getFuncText(value)
	return ("return '/use %s'"):format(value)
end


---------------------------------------------------
-- spell
actions.spell = {}
actions.spell.text = L["Cast Spell"]
actions.spell.isNumeric = true

function actions.spell:getIcon(value)
	local info = ltl:GetSpellInfo(value)
	if info then return info.iconID end
end

actions.spell.getValueDescription = conds.kspell.getValueDescription
actions.spell.setValueLink = conds.kspell.setValueLink
actions.spell.receiveDrag = conds.kspell.receiveDrag
actions.spell.getValueDisplay = conds.kspell.getValueDisplay
actions.spell.getValueText = conds.kspell.getValueText

function actions.spell:getFuncText(value)
	return ([[
		local spellName = self:getSpellName(%s)
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

function actions.macro:getIcon()
	return 136377
end

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
actions.pmacro.doesntInterrupt = true

function actions.pmacro:getIcon()
	return 136377, "P"
end

actions.pmacro.getValueText = actions.macro.getValueText

actions.pmacro.condText = "not (profileLoad or self.useMount or self.preUseMacro)"

function actions.pmacro:getFuncText(value)
	return ("self.preUseMacro = '%s'"):format(value:gsub("['\n\\]", "\\%1"))
end


---------------------------------------------------
-- sstate SET STATE
actions.sstate = {}
actions.sstate.text = L["Set State"]
actions.sstate.description = L["Set a state that can be read in conditions using \"Get State\""]
actions.sstate.doesntInterrupt = true

function actions.sstate:getIcon()
	return 2147148
end

actions.sstate.getValueText = actions.macro.getValueText

function actions.sstate:getFuncText(value)
	return ("self.state['%s'] = true"):format(value:gsub("['\\]", "\\%1"))
end


---------------------------------------------------
-- snip SNIPPET
actions.snip = {}
actions.snip.text = L["Code Snippet"]

function actions.snip:getIcon()
	return 1660431
end

actions.snip.getValueText = conds.snip.getValueText
actions.snip.getValueList = conds.snip.getValueList

function actions.snip:getFuncText(value)
	return ([[
		local text = self:callSnippet('%s')
		return type(text) == "string" and text or nil
	]]):format(value:gsub("['\\]", "\\%1")),
	{"type"}
end


---------------------------------------------------
-- METHODS
function actions:getMenuList(value, func)
	local dInterruptStar = " (|cff44ff44*|r)"
	local dInterruptText = NIGHT_FAE_BLUE_COLOR:WrapTextInColorCode(dInterruptStar:sub(2).." "..L["Doesn't interrupt the rule queue"])
	local list = {}
	local types = {
		"rmount",
		"rmountt",
		"rmountr",
		"rmounttr",
		"rmountc",
		"rmounttc",
		"mount",
		"tmount",
		"dmount",
		"spell",
		"item",
		"iitem",
		"macro",
		"pmacro",
		"sstate",
		"snip",
	}

	local OnTooltipShow = function(btn, tooltip, v)
		GameTooltip_SetTitle(tooltip, v.text)
		if v.description then tooltip:AddLine(v.description, nil, nil, nil, true) end
		if v.doesntInterrupt then
			if v.description then tooltip:AddLine(" ") end
			tooltip:AddLine(dInterruptText, nil, nil, nil, true)
		end
	end

	for i = 1, #types do
		local v = types[i]
		local action = self[v]
		list[i] = {
			text = action.doesntInterrupt and action.text..dInterruptStar or action.text,
			value = v,
			arg1 = action,
			func = func,
			checked = v == value,
		}
		if action.description or action.doesntInterrupt then
			list[i].OnTooltipShow = OnTooltipShow
		end
	end
	return list
end


function actions:getFuncText(action, keys)
	local text, vars = self[action[1]]:getFuncText(action[2])
	if vars then
		for i = 1, #vars do
			local var = vars[i]
			if keys[var] ~= 1 then
				keys[var] = 1
				keys[#keys + 1] = var
			end
		end
	end
	return text
end
