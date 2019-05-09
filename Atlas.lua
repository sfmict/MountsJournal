local mounts = MountsJournal
local journal = MountsJournalFrame

mounts:RegisterEvent("PLAYER_ENTERING_WORLD")
function mounts:PLAYER_ENTERING_WORLD()
	fprint("PLAYER_ENTERING_WORLD")
	-- if not IsAddOnLoaded("Blizzard_Collections") then
	-- 	LoadAddOn("Blizzard_Collections")
	-- end
	-- CollectionsJournal:Show()
	-- journal.navBarBtn:Click()
end