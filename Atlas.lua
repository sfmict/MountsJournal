local addon, L = ...
local mounts = MountsJournal
local journal = MountsJournalFrame

mounts:RegisterEvent("PLAYER_ENTERING_WORLD")
function mounts:PLAYER_ENTERING_WORLD()
	fprint("PLAYER_ENTERING_WORLD")
	-- JOURNAL OPEN
	-- if not IsAddOnLoaded("Blizzard_Collections") then
	-- 	LoadAddOn("Blizzard_Collections")
	-- end
	-- CollectionsJournal:Show()
	-- journal.navBarBtn:Click()


	-- CONFIG OPEN
	local classConfig = MountsJournalConfigClasses
	if InterfaceOptionsFrameAddOns:IsVisible() and classConfig:IsVisible() then
		InterfaceOptionsFrame:Hide()
	else
		InterfaceOptionsFrame_OpenToCategory(L["Class settings"])
		if not InterfaceOptionsFrameAddOns:IsVisible() then
			InterfaceOptionsFrame_OpenToCategory(L["Class settings"])
		end
	end
end