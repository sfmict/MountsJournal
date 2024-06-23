local C_UnitAuras, C_Spell, IsSpellKnown, GetSpellCooldown = C_UnitAuras, C_Spell, IsSpellKnown, GetSpellCooldown
local mounts = MountsJournal
local ltl = LibStub("LibThingsLoad-1.0")
local _,_, raceID = UnitRace("player")
mounts.additionalMounts = {}


local function isActive(self)
	return C_UnitAuras.GetPlayerAuraBySpellID(self.spellID)
end


local function isUsable(self)
	return IsSpellKnown(self.spellID)
	   and C_Spell.IsSpellUsable(self.spellID)
end


local function setIsFavorite(self, enabled)
	mounts.additionalFavorites[self.spellID] = enabled or nil
	mounts:event("UPDATE_FAVORITES")
end


local function getIsFavorite(self)
	return mounts.additionalFavorites[self.spellID]
end


local function createMountFromSpell(spellID, mountType, expansion, modelSceneID)
	local t = {
		spellID = spellID,
		mountType = mountType,
		expansion = expansion,
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
local soar = createMountFromSpell(369536, 402, 10, 4)

if raceID == 52 or raceID == 70 then
	soar.creatureID = "player"
	soar.isShown = true
else
	-- MALE ID 198587 or FEMALE ID 200550
	soar.creatureID = UnitSex("player") == 2 and 110241 or 111204
	soar.isShown = false
end

function soar:canUse()
	return not mounts.sFlags.isSubmerged
	   and IsSpellKnown(self.spellID)
	   and C_Spell.IsSpellUsable(self.spellID)
	   and GetSpellCooldown(self.spellID) == 0
	   and GetSpellCooldown(61304) == 0
end


-- RUNNING WILD
local runningWild = createMountFromSpell(87840, 230, 4, 719)

if raceID == 22 then
	runningWild.creatureID = "player"
	runningWild.isShown = true
else
	-- MALE ID 45254 or FEMALE ID 39725
	runningWild.creatureID = UnitSex("player") == 2 and 34344 or 37389
	runningWild.isShown = false
end