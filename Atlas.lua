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
	-- journal.navBar:setMapID(1148)

	-- MOUNT ANIMATION
	-- local modelScene = MountJournal.MountDisplay.ModelScene
	-- local timer
	-- modelScene:HookScript("OnMouseDown", function(self)
	-- 	if self.needsFanFare then return end
	-- 	local actor = self:GetActorByTag("unwrapped")
	-- 	local mountDisplay = self:GetParent()
	-- 	if actor then
	-- 		actor:SetAnimation(94, 0)
	-- 		if timer then timer:Cancel() end

	-- 		local lastDisplayed = mountDisplay.lastDisplayed
	-- 		timer = C_Timer.NewTimer(10, function()
	-- 			if mountDisplay.lastDisplayed == lastDisplayed then
	-- 				actor:SetAnimation(0)
	-- 			end
	-- 		end)
	-- 	end
	-- end)

	-- CONFIG OPEN
	-- local classConfig = MountsJournalConfig
	-- local classConfig = MountsJournalConfigClasses
	-- if InterfaceOptionsFrameAddOns:IsVisible() and classConfig:IsVisible() then
	-- 	InterfaceOptionsFrame:Hide()
	-- else
	-- 	InterfaceOptionsFrame_OpenToCategory(classConfig.name)
	-- 	if not InterfaceOptionsFrameAddOns:IsVisible() then
	-- 		InterfaceOptionsFrame_OpenToCategory(classConfig.name)
	-- 	end
	-- end
	-- select(14,classConfig:GetChildren()):Click()
end

-- SetClampRectInsets