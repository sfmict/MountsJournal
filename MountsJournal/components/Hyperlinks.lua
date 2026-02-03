local _, ns = ...


hooksecurefunc("HandleModifiedItemClick", function(link)
	local config = ns.mounts.config

	if config.openHyperlinks and not InCombatLockdown() and IsModifiedClick("DRESSUP") and not IsModifiedClick("CHATLINK") and link then
		local _,_,_, linkType, linkID = (":|H"):split(link)

		local mountID
		if linkType == "item" then
			mountID = C_MountJournal.GetMountFromItem(tonumber(linkID))
		elseif linkType == "spell" then
			linkID = tonumber(linkID)
			mountID = ns.additionalMounts[linkID] or C_MountJournal.GetMountFromSpell(linkID)
		end

		if mountID then
			HideUIPanel(DressUpFrame)
			ns.util.openJournalTab(3)
			ns.journal:setSelectedMount(mountID)
		end
	end
end)