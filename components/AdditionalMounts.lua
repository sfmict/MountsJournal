local _, ns = ...
local mounts, util = ns.mounts, ns.util
local C_UnitAuras, C_Spell, C_ZoneAbility, FindSpellOverrideByID, UnitAffectingCombat = C_UnitAuras, C_Spell, C_ZoneAbility, FindSpellOverrideByID, UnitAffectingCombat
local C_Item, C_Container = C_Item, C_Container
local ltl = LibStub("LibThingsLoad-1.0")
local _,_, raceID = UnitRace("player")
local _,_, classID = UnitClass("player")
local additionalMounts = {}
local additionalMountBuffs = {}
ns.additionalMounts = additionalMounts
ns.additionalMountBuffs = additionalMountBuffs


----------------------------------------------------------------------
-- TOOLTIP DATA
local tooltipLoad = {}
function mounts:TOOLTIP_DATA_UPDATE(dataInstanceID)
	local mount = tooltipLoad[dataInstanceID]
	if mount then
		local tooltipInfo = C_TooltipInfo.GetItemByID(mount.itemID)
		mount:updateFunc(tooltipInfo)
		tooltipLoad[dataInstanceID] = nil
		tooltipLoad[tooltipInfo.dataInstanceID] = mount
	end
end
mounts:RegisterEvent("TOOLTIP_DATA_UPDATE")


----------------------------------------------------------------------
-- METHODS
local isActive
if util.isMidnight then
	function isActive(self)
		return self.spellID == mounts.trackableID
	end
else
	function isActive(self)
		return C_UnitAuras.GetPlayerAuraBySpellID(self.buffID)
	end
end


local function setIsFavorite(self, enabled)
	mounts.additionalFavorites[self.spellID] = enabled or nil
	mounts:event("UPDATE_FAVORITES")
end


local function getIsFavorite(self)
	return mounts.additionalFavorites[self.spellID]
end


----------------------------------------------------------------------
-- SPELL AS A MOUNT
local createMountFromSpell do
	local function isUsable(self)
		return util.isSpellKnown(self.spellID)
		   and C_Spell.IsSpellUsable(self.spellID)
	end


	local function isCollected() return true end


	function createMountFromSpell(spellID, mountType, expansion, modelSceneID, selfMount, buffID)
		local t = {
			spellID = spellID,
			buffID = buffID or spellID,
			mountType = mountType,
			expansion = expansion,
			modelSceneID = modelSceneID,
			isActive = isActive,
			isUsable = isUsable,
			canUse = isUsable,
			isCollected = isCollected,
			setIsFavorite = setIsFavorite,
			getIsFavorite = getIsFavorite,
			isShown = true,
			selfMount = selfMount,
			familyID = 1,
		}
		additionalMounts[t.spellID] = t
		additionalMountBuffs[t.buffID] = t

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
end


----------------------------------------------------------------------
-- SOAR
local soar = createMountFromSpell(369536, 442, 10, 4, true, 430747)

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
	   and util.isSpellKnown(self.spellID)
	   and C_Spell.IsSpellUsable(self.spellID)
	   and C_Spell.GetSpellCooldown(self.spellID).startTime == 0
	   and C_Spell.GetSpellCooldown(61304).startTime == 0
end


----------------------------------------------------------------------
-- RUNNING WILD
local runningWild = createMountFromSpell(87840, 230, 4, 719, true)

if raceID == 22 then
	runningWild.creatureID = "player"
	runningWild.isShown = true
else
	-- MALE ID 45254 or FEMALE ID 39725
	runningWild.creatureID = UnitSex("player") == 2 and 34344 or 37389
	runningWild.isShown = false
end


----------------------------------------------------------------------
-- TRAVEL FORM
local travelForm = createMountFromSpell(783, 442, 2, 4, true)
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
	return util.isSpellKnown(self.spellID)
	   and C_Spell.IsSpellUsable(self.spellID)
	   and C_Spell.GetSpellCooldown(self.spellID).startTime == 0
	   and C_Spell.GetSpellCooldown(61304).startTime == 0
end


----------------------------------------------------------------------
-- G-99 Breakneck
local breakneck = createMountFromSpell(460013, 230, 11, 4, false)

breakneck.animID = 484
breakneck.creatureID = 124253
breakneck.allCreature = {
	124253,
	125048,
	125049,
	125050,
	125051,
	--125052,
}

function breakneck:isUsable()
	if mounts.instanceID ~= 2706 then return false end
	if self:isActive() then return true end
	local zoneAbilities = C_ZoneAbility.GetActiveAbilities()
	for i = 1, #zoneAbilities do
		local abilitySpellID = zoneAbilities[i].spellID
		if self.spellID == (FindSpellOverrideByID(abilitySpellID) or abilitySpellID) then return true end
	end
	return false
end
breakneck.canUse = breakneck.isUsable


----------------------------------------------------------------------
-- ITEM AS A MOUNT
local createMountFromItem do
	local function isUsable(self)
		return self:isCollected() and C_Spell.IsSpellUsable(self.spellID)
	end


	local function canUse(self)
		return self:isUsable() and C_Container.GetItemCooldown(self.itemID) == 0
	end


	local function isCollected(self)
		return C_Item.GetItemCount(self.itemID) > 0
	end


	function createMountFromItem(itemID, spellID, creatureID, mountType, expansion, modelSceneID, updateFunc)
		local t = {
			itemID = itemID,
			spellID = spellID,
			buffID = spellID,
			creatureID = creatureID,
			mountType = mountType,
			expansion = expansion,
			modelSceneID = modelSceneID,
			isActive = isActive,
			isUsable = isUsable,
			canUse = canUse,
			isCollected = isCollected,
			isShown = true,
			selfMount = false,
			familyID = 2,
			setIsFavorite = setIsFavorite,
			getIsFavorite = getIsFavorite,
		}
		additionalMounts[t.spellID] = t
		additionalMountBuffs[t.buffID] = t

		t.icon = ltl:GetItemIcon(itemID)
		t.name = ""
		t.sourceText = ""
		t.description = ""
		t.macro = "/use item:"..itemID
		t.updateFunc = updateFunc

		ltl:Items(itemID):Then(function()
			t.name = ltl:GetItemName(itemID)
		end)

		local tooltipInfo = C_TooltipInfo.GetItemByID(itemID)
		t:updateFunc(tooltipInfo)
		tooltipLoad[tooltipInfo.dataInstanceID] = t

		return t
	end
end


----------------------------------------------------------------------
-- MAGIC BROOM
mounts:on("ADDON_INIT", function()
	local magicBroom = createMountFromItem(37011, 47977, 21939, 442, 2, 4, function(self, tooltipInfo)
		if tooltipInfo.lines[5] then
			self.sourceText = tooltipInfo.lines[5].leftText
			self.description = tooltipInfo.lines[4].leftText
		end
	end)
	magicBroom.familyID = {2, 2904}
end)