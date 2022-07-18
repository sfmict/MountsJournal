hooksecurefunc("HandleModifiedItemClick", function(link)
	local config = MountsJournal.config

	if config.openHyperlinks and not config.useDefaultJournal and not InCombatLockdown() and IsModifiedClick("DRESSUP") and not IsModifiedClick("CHATLINK") then
		local _,_,_, linkType, linkID = (":|H"):split(link)

		local mountID
		if linkType == "item" then
			mountID = C_MountJournal.GetMountFromItem(tonumber(linkID))
		elseif linkType == "spell" then
			mountID = C_MountJournal.GetMountFromSpell(tonumber(linkID))
		end

		if mountID then
			HideUIPanel(DressUpFrame)
			if not IsAddOnLoaded("Blizzard_Collections") then
				LoadAddOn("Blizzard_Collections")
			end
			ShowUIPanel(CollectionsJournal)
			MountsJournalFrame:setSelectedMount(mountID)
		end
	end
end)