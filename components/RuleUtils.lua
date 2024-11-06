local _, ns = ...
local macroFrame, util = ns.macroFrame, ns.util
local C_Spell, C_Item, GetRealZoneText, GetSubZoneText, GetZoneText, GetMinimapZoneText, C_Transmog, C_TransmogSets, C_TransmogCollection, C_Transmog, TransmogUtil, TRANSMOG_SLOTS, tContains, GetSpecialization, GetSpecializationInfo, C_ClassTalents, C_Minimap = C_Spell, C_Item, GetRealZoneText, GetSubZoneText, GetZoneText, GetMinimapZoneText, C_Transmog, C_TransmogSets, C_TransmogCollection, C_Transmog, TransmogUtil, TRANSMOG_SLOTS, tContains, GetSpecialization, GetSpecializationInfo, C_ClassTalents, C_Minimap


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


function macroFrame:isTransmogSetActive(setID)
	local setInfo = C_TransmogSets.GetSetInfo(setID)
	if not (setInfo and setInfo.validForCharacter) then return end

	for k, transmogSlot in next, TRANSMOG_SLOTS do
		if not transmogSlot.location:IsSecondary()
		or TransmogUtil.IsSecondaryTransmoggedForItemLocation(TransmogUtil.GetItemLocationFromTransmogLocation(transmogSlot.location))
		then
			local sourceIDs = C_TransmogSets.GetSourceIDsForSlot(setID, transmogSlot.location:GetSlotID())
			if #sourceIDs > 0 then
				local baseSourceID, _, appliedSourceID = C_Transmog.GetSlotVisualInfo(transmogSlot.location)
				if tContains(sourceIDs, appliedSourceID > 0 and appliedSourceID or baseSourceID) then return end
			end
		end
	end
	return true
end


do
	local typeAappearance, typeIllusion, modMain, modSecondary, noTransmogID = Enum.TransmogType.Appearance, Enum.TransmogType.Illusion, Enum.TransmogModification.Main, Enum.TransmogModification.Secondary, Constants.Transmog.NoTransmogID
	local mainHandID, offHandID, shoulderID = INVSLOT_MAINHAND, INVSLOT_OFFHAND, INVSLOT_SHOULDER
	local modelScene = CreateFrame("ModelScene", nil, nil, "NonInteractableModelSceneMixinTemplate")
	modelScene:Hide()
	modelScene:SetSize(100, 100)
	modelScene:SetFromModelSceneID(290)

	local function getEffectiveTransmogID(transmogLocation)
		local itemLocation = TransmogUtil.GetItemLocationFromTransmogLocation(transmogLocation)
		if not C_Item.DoesItemExist(itemLocation) then return noTransmogID end

		local function GetTransmogIDFrom(fn)
			local itemTransmogInfo = fn(itemLocation)
			return TransmogUtil.GetRelevantTransmogID(itemTransmogInfo, transmogLocation)
		end

		local appliedTransmogID = GetTransmogIDFrom(C_Item.GetAppliedItemTransmogInfo)
		if appliedTransmogID == noTransmogID then
			return GetTransmogIDFrom(C_Item.GetBaseItemTransmogInfo)
		else
			return appliedTransmogID
		end
	end

	local function refreshItemModel(actor, slotID)
		local transmogLocation = TransmogUtil.GetTransmogLocation(slotID, typeAappearance, modMain)
		local appearanceID = getEffectiveTransmogID(transmogLocation)

		if appearanceID ~= noTransmogID then
			local secondaryAppearanceID = noTransmogID
			local illusionID = noTransmogID

			if transmogLocation:IsEitherHand() then
				local dependendLocation = TransmogUtil.GetTransmogLocation(slotID, typeIllusion, modMain)
				illusionID = getEffectiveTransmogID(dependendLocation)
			else
				local dependendLocation = TransmogUtil.GetTransmogLocation(slotID, typeAappearance, modSecondary)
				secondaryAppearanceID = getEffectiveTransmogID(dependendLocation)
			end

			local itemTransmogInfo = actor:GetItemTransmogInfo(slotID)
			itemTransmogInfo.appearanceID = appearanceID
			itemTransmogInfo.secondaryAppearanceID = secondaryAppearanceID
			itemTransmogInfo.illusionID = illusionID

			if transmogLocation:IsMainHand() then
				local mainHandCategoryID = C_Transmog.GetSlotEffectiveCategory(transmogLocation)
				local isLegionArtifact = TransmogUtil.IsCategoryLegionArtifact(mainHandCategoryID)
				itemTransmogInfo:ConfigureSecondaryForMainHand(isLegionArtifact)
				-- don't specify a slot for ranged weapons
				if mainHandCategoryID and TransmogUtil.IsCategoryRangedWeapon(mainHandCategoryID) then
					slotID = nil
				end
			end
			actor:SetItemTransmogInfo(itemTransmogInfo, slotID)
		end
	end

	function macroFrame:isTtransmogOutfitActive(name)
		local outfitID
		for _, id in ipairs(C_TransmogCollection.GetOutfits()) do
			if name == C_TransmogCollection.GetOutfitInfo(id) then
				outfitID = id
				break
			end
		end
		if not outfitID then return end

		local outfitItemTransmogInfoList = C_TransmogCollection.GetOutfitItemTransmogInfoList(outfitID)
		if not outfitItemTransmogInfoList then return end

		local actor = modelScene:GetPlayerActor()
		actor:SetModelByUnit("player", false, true, false, true)
		refreshItemModel(actor, shoulderID)
		refreshItemModel(actor, offHandID)
		refreshItemModel(actor, mainHandID)

		local currentItemTransmogInfoList = actor:GetItemTransmogInfoList()
		if not currentItemTransmogInfoList then return end

		for slotID = 1, #currentItemTransmogInfoList do
			local itemTransmogInfo = currentItemTransmogInfoList[slotID]
			if itemTransmogInfo.appearanceID ~= Constants.Transmog.NoTransmogID and not itemTransmogInfo:IsEqual(outfitItemTransmogInfoList[slotID]) then
				return
			end
		end
		return true
	end
end


function macroFrame:checkTalent(configID)
	local specIndex = GetSpecialization()
	if specIndex then
		local specID = GetSpecializationInfo(specIndex)
		return configID == C_ClassTalents.GetLastSelectedSavedConfigID(specID)
	end
end


function macroFrame:checkTracking(key, value)
	for i = 1, C_Minimap.GetNumTrackingTypes() do
		if C_Minimap.GetTrackingFilter(i)[key] == value then
			return C_Minimap.GetTrackingInfo(i).active
		end
	end
end