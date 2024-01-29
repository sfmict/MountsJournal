local _, L = ...
local C_UnitAuras, IsUsableSpell, IsSpellKnown, GetSpellCooldown = C_UnitAuras, IsUsableSpell, IsSpellKnown, GetSpellCooldown
local mounts = MountsJournal
local ltl = LibStub("LibThingsLoad-1.0")
local _,_, raceID = UnitRace("player")
mounts.additionalMounts = {}


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
		isActive = isActive,
		isUsable = isUsable,
		canUse = isUsable,
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

function soar:isShown()
	return raceID == 52
end

function soar:canUse()
	return not mounts.sFlags.isSubmerged
	   and IsSpellKnown(430935)
	   and IsUsableSpell(self.spellID)
	   and GetSpellCooldown(self.spellID) == 0
	   and GetSpellCooldown(61304) == 0
end


-- RUNNING WILD
local runningWild = createMountFromSpell(87840, 230, false, 4, "player", 719)

function runningWild:isShown()
	return raceID == 22
end