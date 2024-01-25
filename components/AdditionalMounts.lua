local _, L = ...
local C_UnitAuras, IsUsableSpell, IsSpellKnown, GetSpellCooldown = C_UnitAuras, IsUsableSpell, IsSpellKnown, GetSpellCooldown
local mounts = MountsJournal
local ltl = LibStub("LibThingsLoad-1.0")
local _,_, raceID = UnitRace("player")
mounts.additionalMounts = {}


local animationList = {
	{
		name = L["Default"],
		animation = 618,
	},
	{
		name = L["Mount special"],
		animation = 636,
	},
	{
		name = L["Walk"],
		animation = 620,
		type = 2,
	},
	{
		name = L["Walk backwards"],
		animation = 634,
		type = 2,
	},
	{
		name = L["Run"],
		animation = 622,
		type = 2,
	},
	{
		name = L["Swim idle"],
		animation = 532,
		type = 3,
	},
	{
		name = L["Swim"],
		animation = 540,
		type = 3,
	},
	{
		name = L["Swim backwards"],
		animation = 534,
		type = 3,
	},
	{
		name = L["Fly stand"],
		animation = 548,
		type = 1,
	},
	{
		name = L["Fly"],
		animation = 558,
		type = 1,
	},
	{
		name = L["Fly backwards"],
		animation = 562,
		type = 1,
	},
}


local function isActive(self)
	return C_UnitAuras.GetPlayerAuraBySpellID(self.spellID)
end


local function isUsable(self)
	return IsSpellKnown(self.spellID)
	   and IsUsableSpell(self.spellID)
end


local function setIsFavorite(self, enabled)
	mounts.additionalFavorites[self.spellID] = enabled or nil
	mounts:event("UPDATE_FAVORITES")
end


local function getIsFavorite(self)
	return mounts.additionalFavorites[self.spellID]
end


local function createMountFromSpell(spellID, mountType, dragonriding, expansion, creatureID, modelSceneID)
	local t = {
		spellID = spellID,
		mountType = mountType,
		dragonriding = dragonriding,
		expansion = expansion,
		creatureID = creatureID,
		modelSceneID = modelSceneID,
		animationList = animationList,
		isActive = isActive,
		isUsable = isUsable,
		setIsFavorite = setIsFavorite,
		getIsFavorite = getIsFavorite,
	}
	mounts.additionalMounts[t.spellID] = t

	local _, icon = ltl:GetSpellTexture(spellID)
	t.icon = icon
	t.name = ltl:GetSpellName(spellID)
	t.sourceText = ""
	t.description = ""
	t.macro = ""

	ltl:Spells(spellID):Then(function()
		t.sourceText = ltl:GetSpellSubtext(spellID)
		t.macro = "/cast "..ltl:GetSpellFullName(spellID)
		t.description = ltl:GetSpellDescription(spellID)
	end)

	return t
end


-- SOAR
local soar = createMountFromSpell(369536, 402, true, 10, "player", 4)
mounts._soar = soar

function soar:isShown()
	return raceID == 52
end

function soar:canUse()
	return not mounts.sFlags.isSubmerged
	   and not mounts.sFlags.modifier
	   and IsSpellKnown(430935)
	   and IsUsableSpell(self.spellID)
	   and GetSpellCooldown(self.spellID) == 0
	   and GetSpellCooldown(61304) == 0
end

function soar:setMount()
	mounts.summonedSpellID = self.spellID
	return true
end


-- RUNNING WILD
local runningWild = createMountFromSpell(87840, 230, false, 4, "player", 719)

function runningWild:isShown()
	return raceID == 22
end

function runningWild:canUse()
	return IsSpellKnown(self.spellID)
	   and IsUsableSpell(self.spellID)
end