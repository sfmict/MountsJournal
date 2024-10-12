local _, ns = ...
local macroFrame, util = ns.macroFrame, ns.util
local C_Spell, C_Item, GetRealZoneText, GetSubZoneText, GetZoneText, GetMinimapZoneText, C_Transmog, C_TransmogSets, C_TransmogCollection, C_Transmog, TransmogUtil, TRANSMOG_SLOTS, tContains = C_Spell, C_Item, GetRealZoneText, GetSubZoneText, GetZoneText, GetMinimapZoneText, C_Transmog, C_TransmogSets, C_TransmogCollection, C_Transmog, TransmogUtil, TRANSMOG_SLOTS, tContains


function macroFrame:isSpellReady(spellID)
	local cdInfo = C_Spell.GetSpellCooldown(spellID)
	return cdInfo and cdInfo.startTime == 0
end


function macroFrame:hasPlayerBuff(spellID)
	return util.checkAura("player", spellID, "HELPFUL")
end


function macroFrame:hasPlayerDebuff(spellID)
	return util.checkAura("player", spellID, "HARMFUL")
end


function macroFrame:zoneMatch(zoneText)
	local cz = ("/%s/%s/%s/%s/"):format(GetRealZoneText(), GetSubZoneText(), GetZoneText(), GetMinimapZoneText()):gsub("//", "/")
	return cz:match(zoneText) and true
end


function macroFrame:checkMap(mapID)
	local mapList = self.mounts.mapList
	for i = 1, #mapList do
		if mapList[i] == mapID then return true end
	end
end