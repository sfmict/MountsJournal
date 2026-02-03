if not (OPie and OPie.ActionBook and OPie.ActionBook.compatible) then return end
local AB = OPie.ActionBook:compatible(2, 47)
local R = OPie.CustomRings
if not (AB and R and R.AddDefaultRing) then return end
local addon, ns = ...
local L, mounts = ns.L, ns.mounts


R:AddDefaultRing(addon, {
	{"MJClick", 1, 1, _u = "1"},
	{"MJClick", 2, 1, _u = "2"},
	name = addon, _u = "OPCMJC", v = 1
})


ns.macroFrame:on("ADDON_INIT", function(macroFrame)
	local actionMap = {}

	local function tooltip(tooltip, info)
		local id = info[1]
		GameTooltip_SetTitle(tooltip, ("%s %d %s"):format(SUMMONS, id, _G["KEY_BUTTON"..info[2]]))
		if macroFrame.currentRuleSet[id].altMode then
			GameTooltip_AddNormalLine(tooltip, L["SecondMountTooltipDescription"]:gsub("\n\n", "\n"))
		else
			GameTooltip_AddNormalLine(tooltip, L["Normal mount summon"], nil, nil, nil, true)
		end
	end

	local function btnHint(info)
		local id = info[1]
		local name = "summon"..id.."Icon"
		local icon = mounts.config[name]
		macroFrame.sFlags.summonID = id
		return true, IsMounted() and 1 or 0, icon, name, 0, 0, 0, tooltip, info
	end

	local function createMJClick(id, btnID)
		macroFrame.sFlags.forceModifier = macroFrame.currentRuleSet[id].altMode
		macroFrame.sFlags.summonID = id

		local macro
		if UnitAffectingCombat("player") then
			macro = macroFrame:getCombatMacro()
		else
			local button
			if btnID == 1 then
				button = "LeftButton"
			elseif btnID == 2 then
				button = "RightButton"
			elseif btnID == 3 then
				button = "MiddleButton"
			else
				button = "Button"..btnID
			end
			macro = macroFrame.checkRules[id](macroFrame, button) or ""
			if macroFrame.useMount then
				local spellID = macroFrame.useMount
				if spellID == true then spellID = mounts.summonedSpellID end
				if spellID then macro = ("%s\n/run MountsJournal:summon(%s)"):format(macro, spellID) end
			end
		end

		local hk = (65521 + id) * btnID
		local k = hk..macro
		local a = actionMap[k]
		if not a then
			local info = actionMap[hk]
			if not info then
				info = {id, btnID}
				actionMap[hk] = info
			end
			a = AB:CreateActionSlot(btnHint, info, "macrotext", macro)
			actionMap[k] = a
		end
		return a
	end

	local function describeMJClick(id, btnID)
		return "MJClick", ("%s %d %s"):format(SUMMONS, id, _G["KEY_BUTTON"..btnID]), mounts.config["summon"..id.."Icon"]
	end

	AB:RegisterActionType("MJClick", createMJClick, describeMJClick, 2)
	AB:AugmentCategory(addon, function(_, add)
		local i = 1
		while _G["KEY_BUTTON"..i] do
			add("MJClick", 1, i)
			add("MJClick", 2, i)
			i = i + 1
		end
	end)
end)