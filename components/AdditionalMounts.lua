local _, ns = ...
local mounts = ns.mounts
local C_UnitAuras, C_Spell, IsSpellKnown = C_UnitAuras, C_Spell, IsSpellKnown
local ltl = LibStub("LibThingsLoad-1.0")
local _,_, raceID = UnitRace("player")
local _,_, classID = UnitClass("player")
local additionalMounts = {}
ns.additionalMounts = additionalMounts


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
	additionalMounts[t.spellID] = t

	local _, icon = ltl:GetSpellTexture(spellID)
	t.icon = icon
	t.name = ltl:GetSpellName(spellID)
	t.sourceText = ""
	t.description = ""
	t.macro = ""

	ltl:Spells(spellID):Then(function()
		t.sourceText = ltl:GetSpellSubtext(spellID) or ""
		t.macro = "/cast "..ltl:GetSpellFullName(spellID)
		t.description = ltl:GetSpellDescription(spellID)
	end)

	return t
end


-- SOAR
local soar = createMountFromSpell(369536, 442, 10, 4)

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
	   and C_Spell.GetSpellCooldown(self.spellID).startTime == 0
	   and C_Spell.GetSpellCooldown(61304).startTime == 0
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


-- TRAVEL FORM
local travelForm = createMountFromSpell(783, 442, 2, 4)

travelForm.isShown = classID == 11

if raceID == 6 then -- Tauren
	travelForm.creatureID = 21244
elseif raceID == 8 then -- Troll
	travelForm.creatureID = 37730
elseif raceID == 22 then -- Worgen
	travelForm.creatureID = 37729
elseif raceID == 28 then -- Highmountain Tauren
	travelForm.creatureID = 81439
elseif raceID == 31 then -- Zandalari Troll
	travelForm.creatureID = 91215
elseif raceID == 32 then -- Kul Tiran
	travelForm.creatureID = 88351
else -- Night Elf
	travelForm.creatureID = 21243
end

travelForm.allCreature = {
	21243, -- Night Elf
	21244, -- Tauren
	37729, -- Worgen
	37730, -- Troll
	81439, -- Highmountain Tauren
	88351, -- Kul Tiran
	91215, -- Zandalari Troll
	74305, -- Lunarwing Night Elf
	74304, -- Lunarwing Tauren, Highmountain Tauren
	74307, -- Lunarwing Worgen, Kul Tiran
	74306, -- Lunarwing Troll, Zandalari Troll
}

function travelForm:canUse()
	return IsSpellKnown(self.spellID)
	   and C_Spell.IsSpellUsable(self.spellID)
	   and C_Spell.GetSpellCooldown(self.spellID).startTime == 0
	   and C_Spell.GetSpellCooldown(61304).startTime == 0
end