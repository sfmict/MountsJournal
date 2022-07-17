hooksecurefunc("HandleModifiedItemClick", function(link)
	local config = MountsJournal.config

	if config.openHyperlinks and not config.useDefaultJournal and IsModifiedClick("DRESSUP") and not IsModifiedClick("CHATLINK") then
		local _,_,_, linkType, linkID = (":|H"):split(link)

		local mountID
		if linkType == "item" then
			mountID = C_MountJournal.GetMountFromItem(tonumber(linkID))
		elseif linkType == "spell" then
			mountID = C_MountJournal.GetMountFromSpell(tonumber(linkID))
		end

		if mountID then
			local isCollectionsLoaded = IsAddOnLoaded("Blizzard_Collections")
			if isCollectionsLoaded or not InCombatLockdown() then
				HideUIPanel(DressUpFrame)
				if not isCollectionsLoaded then
					LoadAddOn("Blizzard_Collections")
				end
				ShowUIPanel(CollectionsJournal)
				MountsJournalFrame:setSelectedMount(mountID)
			end
		end
	end
end)