local _, ns = ...
local macroFrame, util = ns.macroFrame, ns.util
local next, ipairs, C_Spell, C_Item, GetRealZoneText, GetSubZoneText, GetZoneText, GetMinimapZoneText, GetSpecialization, GetSpecializationInfo, C_ClassTalents, C_Minimap, C_EquipmentSet, GetPlayerInfoByGUID, C_ZoneAbility, FindSpellOverrideByID, GetNumGroupMembers, GetNumSubgroupMembers, UnitGUID, UnitIsConnected, IsInGroup, BNGetNumFriends, C_BattleNet = next, ipairs, C_Spell, C_Item, GetRealZoneText, GetSubZoneText, GetZoneText, GetMinimapZoneText, C_SpecializationInfo.GetSpecialization, C_SpecializationInfo.GetSpecializationInfo, C_ClassTalents, C_Minimap, C_EquipmentSet, GetPlayerInfoByGUID, C_ZoneAbility, FindSpellOverrideByID, GetNumGroupMembers, GetNumSubgroupMembers, UnitGUID, UnitIsConnected, IsInGroup, BNGetNumFriends, C_BattleNet


function macroFrame:isSpellReady(spellID)
	local cdInfo = C_Spell.GetSpellCooldown(spellID)
	return cdInfo and cdInfo.startTime == 0
end


function macroFrame:haveZoneSpell(spellID)
	local zoneAbilities = C_ZoneAbility.GetActiveAbilities()
	for i = 1, #zoneAbilities do
		local abilitySpellID = zoneAbilities[i].spellID
		if spellID == (FindSpellOverrideByID(abilitySpellID) or abilitySpellID) then return true end
	end
	return false
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
	return false
end


function macroFrame:checkTalent(configID)
	local specIndex = GetSpecialization()
	if specIndex then
		local specID = GetSpecializationInfo(specIndex)
		return configID == C_ClassTalents.GetLastSelectedSavedConfigID(specID)
	end
	return false
end


function macroFrame:checkTracking(key, value)
	for i = 1, C_Minimap.GetNumTrackingTypes() do
		if C_Minimap.GetTrackingFilter(i)[key] == value then
			return C_Minimap.GetTrackingInfo(i).active
		end
	end
	return false
end


function macroFrame:checkEquipmentSet(setID)
	local _,_,_, isEquipped = C_EquipmentSet.GetEquipmentSetInfo(setID)
	return isEquipped
end


do
	local updateFrame = CreateFrame("FRAME")

	local function update(self, elapsed)
		self.time = self.time - elapsed

		if self.time <= 0 then
			for guid in next, self.guids do
				if GetPlayerInfoByGUID(guid) then
					self.guids = nil
					self:SetScript("OnUpdate", nil)
					macroFrame:event("RULE_LIST_UPDATE")
					return
				end
			end

			self.attempts = self.attempts - 1
			if self.attempts == 0 then
				self.guids = nil
				self:SetScript("OnUpdate", nil)
				return
			end
			self.time = .5
		end
	end

	function macroFrame:getNameByGUID(guid)
		local _,_,_,_,_, name, realmName = GetPlayerInfoByGUID(guid)

		if name then
			if realmName == "" then realmName = GetRealmName() end
			return ("%s - %s"):format(name, realmName)
		end

		updateFrame.time = .5
		updateFrame.attempts = 5
		updateFrame.guids = updateFrame.guids or {}
		updateFrame.guids[guid] = true
		updateFrame:SetScript("OnUpdate", update)
		return "?? - ??"
	end
end


function macroFrame:isMapFlagActive(flag, profileName)
	local profile = profileName == "" and self.mounts.defProfile or self.mounts.profiles[profileName]
	if profile then
		local mapList = self.mounts.mapList
		for i = 1, #mapList do
			local list = profile.zoneMounts[mapList[i]]
			if list and list.flags.enableFlags then return list.flags[flag] end
		end
	end
	return false
end


function macroFrame:isItemEquipped(item)
	if C_Item.IsEquippedItem(item)
	or C_Item.IsEquippedItemType(item)
	then
		return true
	end
	return false
end


function macroFrame:isUnitInGroup(guid, isRaid)
	local unit, uGuid
	if isRaid then
		for i = 1, GetNumGroupMembers() do
			unit = "raid"..i
			uGuid = UnitGUID(unit)
			if not issecretvalue(uGuid) and guid == UnitGUID(unit) then
				return UnitIsConnected(unit)
			end
		end
	else
		for i = 1, GetNumSubgroupMembers() do
			unit = "party"..i
			uGuid = UnitGUID(unit)
			if not issecretvalue(uGuid) and guid == UnitGUID(unit) then
				return UnitIsConnected(unit)
			end
		end
	end
	return false
end


do
	local function checkApps(self, i, isRaid)
		for j = 1, C_BattleNet.GetFriendNumGameAccounts(i) do
			local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(i, j)
			if gameAccountInfo.clientProgram == "WoW" and self:isUnitInGroup(gameAccountInfo.playerGuid, isRaid) then
				return true
			end
		end
		return false
	end

	function macroFrame:isFriendInGroup(btag, isRaid)
		if not IsInGroup() then return end
		local _, numOline, fNum, fNumOnline = BNGetNumFriends()
		for i = 1, fNumOnline do
			local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
			if accountInfo.battleTag == btag then
				return checkApps(self, i, isRaid)
			end
		end
		for i = fNum + 1, fNum + numOline - fNumOnline do
			local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
			if accountInfo.battleTag == btag then
				return checkApps(self, i, isRaid)
			end
		end
		return false
	end
end