local _, ns = ...
local L, actions, util, mounts, conds = ns.L, ns.actions, ns.util, ns.mounts, ns.conditions
local createRadioInfo, createArrowInfo = util.createRadioInfo, util.createArrowInfo
local strcmputf8i = strcmputf8i
local ltl = LibStub("LibThingsLoad-1.0")


---------------------------------------------------
-- rmount RANDOM MOUNT
actions.rmount.text = L["Random Mount"]

function actions.rmount:getIcon()
	return 413588
end

function actions.rmount:getValue(profileName)
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
	list[1] = createRadioInfo(L["Selected profile"], 0, func, value == 0)
	list[2] = createRadioInfo(DEFAULT, 1, func, value == 1)

	local profiles = {}
	for k in next, mounts.profiles do profiles[#profiles + 1] = k end
	sort(profiles, function(a, b) return strcmputf8i(a, b) < 0 end)

	for i = 1, #profiles do
		local profile = profiles[i]
		list[#list + 1] = createRadioInfo(profile, profile, func, value == profile)
	end

	return list
end


---------------------------------------------------
-- rmountt RANDOM MOUNT OF SELECTED TYPE
actions.rmountt.text = L["Random Mount of Selected Type"]

function actions.rmountt:getIcon()
	return 413588, "T"
end

function actions.rmountt:getValue(value)
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
			tList[i] = createRadioInfo(L["MOUNT_TYPE_"..i], v, func, v == value)
		end
		return tList
	end

	local list = {}
	list[0] = createArrowInfo(L["Selected profile"], getTList(0))
	list[1] = createArrowInfo(DEFAULT, getTList(1))

	local profiles = {}
	for k in next, mounts.profiles do profiles[#profiles + 1] = k end
	sort(profiles, function(a, b) return strcmputf8i(a, b) < 0 end)

	for i = 1, #profiles do
		local profile = profiles[i]
		list[#list + 1] = createArrowInfo(profile, getTList(profile))
	end

	return list
end


---------------------------------------------------
-- rmountr RANDOM MOUNT BY RARITY
actions.rmountr.text = L["Random Mount by Rarity"]
actions.rmountr.description = L["The lower the rarity, the higher the chance"]

function actions.rmountr:getIcon()
	return 413588, nil, 1, .5, 1
end

actions.rmountr.getValue = actions.rmount.getValue
actions.rmountr.getValueList = actions.rmount.getValueList


---------------------------------------------------
-- rmounttr RANDOM MOUNT OF SELECTED TYPE BY RARITY
actions.rmounttr.text = L["Random Mount of Selected Type by Rarity"]
actions.rmounttr.description = L["The lower the rarity, the higher the chance"]

function actions.rmounttr:getIcon()
	return 413588, "T", 1, .5, 1
end

actions.rmounttr.getValue = actions.rmountt.getValue
actions.rmounttr.getValueList = actions.rmountt.getValueList


---------------------------------------------------
-- rmountc RANDOM MOUNT BY SUMMON COUNTER
actions.rmountc.text = L["Random Mount by Summon Counter"]
actions.rmountc.description = L["The lower the counter, the higher the chance"]

function actions.rmountc:getIcon()
	return 413588, nil, .2, .5, 1
end

actions.rmountc.getValue = actions.rmount.getValue
actions.rmountc.getValueList = actions.rmount.getValueList


---------------------------------------------------
-- rmounttc RANDOM MOUNT OF SELECTED TYPE BY SUMMON COUNTER
actions.rmounttc.text = L["Random Mount of Selected Type by Summon Counter"]
actions.rmounttc.description = L["The lower the counter, the higher the chance"]

function actions.rmounttc:getIcon()
	return 413588, "T", .2, .5, 1
end

actions.rmounttc.getValue = actions.rmountt.getValue
actions.rmounttc.getValueList = actions.rmountt.getValueList


---------------------------------------------------
-- mount
actions.mount.text = L["Mount"]

function actions.mount:getIcon(value)
	if not value then return 631718 end
	local mount = ns.additionalMounts[value]
	if mount then
		return mount.icon, nil,nil,nil,nil,nil, mount.spellID
	else
		local mountID = C_MountJournal.GetMountFromSpell(value)
		if mountID then
			local _, spellID, icon = C_MountJournal.GetMountInfoByID(mountID)
			return icon, nil,nil,nil,nil, mountID, spellID
		end
	end
end

function actions.mount:getValue(value, noIcon)
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


---------------------------------------------------
-- mount TARGET MOUNT
actions.tmount.text = L["CopyMountTarget"]
actions.tmount.description = L["TMOUNT_DESCRIPTION"]

function actions.tmount:getIcon()
	return 524052
end


---------------------------------------------------
-- dmount DISMOUNT
actions.dmount.text = BINDING_NAME_DISMOUNT

function actions.dmount:getIcon()
	return 237700
end


---------------------------------------------------
-- item
actions.item.text = L["Use Item"]
actions.item.isNumeric = true

function actions.item:getIcon(value)
	if not value then return 133633 end
	return ltl:GetItemIcon(value), nil,nil,nil,nil,nil,nil, ltl:GetItemLink(value)
end

actions.item.getValueDescription = conds.hitem.getValueDescription
actions.item.setValueLink = conds.hitem.setValueLink
actions.item.receiveDrag = conds.hitem.receiveDrag
actions.item.getValueDisplay = conds.hitem.getValueDisplay
actions.item.getValue = conds.hitem.getValue


---------------------------------------------------
-- iitem INVENTORY ITEM
actions.iitem.text = L["Use Inventory Item"]
actions.iitem.isNumeric = true

function actions.iitem:getIcon(value)
	if not value then return 133069 end
	return GetInventoryItemTexture("player", value), nil,nil,nil,nil,nil,nil, GetInventoryItemLink("player", value)
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
		description = ("%s%s = %s\n"):format(description, i, list[i])
	end
	return description
end

function actions.iitem:setValueLink(FontString, value)
	if value then
		local link = GetInventoryItemLink("player", value)
		local icon = GetInventoryItemTexture("player", value)
		FontString:SetText(util.getIconLink(link, icon))
	else
		FontString:SetText()
	end
end

function actions.iitem:getValueDisplay(value)
	return getInventoryList()[value]
end

actions.iitem.getValue = actions.item.getValue


---------------------------------------------------
-- spell
actions.spell.text = L["Cast Spell"]
actions.spell.isNumeric = true

function actions.spell:getIcon(value)
	if not value then return 135810 end
	local info = ltl:GetSpellInfo(value)
	if info then return info.iconID, nil,nil,nil,nil,nil, info.spellID end
end

actions.spell.getValueDescription = conds.kspell.getValueDescription
actions.spell.setValueLink = conds.kspell.setValueLink
actions.spell.receiveDrag = conds.kspell.receiveDrag
actions.spell.getValueDisplay = conds.kspell.getValueDisplay
actions.spell.getValue = conds.kspell.getValue


---------------------------------------------------
-- macro
actions.macro.text = MACRO
actions.macro.maxLetters = 255

function actions.macro:getIcon()
	return 136377
end

function actions.macro:getValue(value)
	return value
end


---------------------------------------------------
-- pmacro PRE MACRO
actions.pmacro.text = L["Use macro before mounting"]
actions.pmacro.description = L["PMACRO_DESCRIPTION"]
actions.pmacro.maxLetters = 200
actions.pmacro.doesntInterrupt = true

function actions.pmacro:getIcon()
	return 136377, "P"
end

actions.pmacro.getValue = actions.macro.getValue


---------------------------------------------------
-- sstate SET STATE
actions.sstate.text = L["Set State"]
actions.sstate.description = L["Set a state that can be read in conditions using \"Get State\""]
actions.sstate.doesntInterrupt = true

function actions.sstate:getIcon()
	return 2147148
end

actions.sstate.getValue = actions.macro.getValue


---------------------------------------------------
-- snip SNIPPET
actions.snip.text = L["Code Snippet"]

function actions.snip:getIcon()
	return 1660431
end

actions.snip.getValue = conds.snip.getValue
actions.snip.getValueList = conds.snip.getValueList


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
		local text = action.doesntInterrupt and action.text..dInterruptStar or action.text
		local icon, _, r,g,b = action:getIcon()

		local info = createRadioInfo(text, v, func, v == value, nil, icon, r and {r=r, g=g, b=b})
		info.arg1 = action
		if action.description or action.doesntInterrupt then
			info.OnTooltipShow = OnTooltipShow
		end
		list[i] = info
	end
	return list
end
