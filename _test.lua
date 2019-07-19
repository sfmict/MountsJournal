local addon, L = ...
local mounts = MountsJournal
local config = MountsJournalConfig
local journal = MountsJournalFrame
local test = CreateFrame("Frame")
test:RegisterEvent("PLAYER_ENTERING_WORLD")


test:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		fprint(event, ...)
		self[event](self, ...)
	else
		fprint("None:", event, ...)
	end
end)
test:RegisterEvent("UI_MODEL_SCENE_INFO_UPDATED")


function test:PLAYER_ENTERING_WORLD()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	if true then return end
	-- fprint("PLAYER_ENTERING_WORLD")
	-- JOURNAL OPEN
	if not IsAddOnLoaded("Blizzard_Collections") then
		LoadAddOn("Blizzard_Collections")
	end
	ShowUIPanel(CollectionsJournal)
	-- journal.navBarBtn:Click()
	-- journal.mapSettings.existingsListsToggle:Click()
	-- journal.navBar:setMapID(1033)

	-- MOUNT ANIMATION
	local modelScene = MountJournal.MountDisplay.ModelScene
	-- local timer
	local i = 0
	modelScene:HookScript("OnMouseDown", function(self, btn)
		-- if self.needsFanFare then return end
		local actor = self:GetActorByTag("unwrapped")
		local actor2 = self:GetActorByTag("player")
		-- actor2:SetModelByUnit("player")
		self.UnwrapAnim.UnwrappedAnim:SetTarget(actor)

		local modelSceneType, cameraIDs, actorIDs = C_ModelInfo.GetModelSceneInfoByID(self.modelSceneID)
		local actorInfo = C_ModelInfo.GetModelSceneActorInfoByID(actorIDs[3])
		-- fprint(dump, C_ModelInfo.GetModelSceneActorDisplayInfoByID(actorInfo.modelActorDisplayID))
		-- fprint(dump, C_ModelInfo.GetModelSceneInfoByID(self.modelSceneID))
		-- C_ModelInfo.GetModelSceneActorDisplayInfoByID()
		-- UIModelSceneActorDisplayInfo

		-- WALK            4 119
		-- WALK BACK       13
		-- RUN             5 143
		-- IN WATTER       41
		-- SWIMM           42
		-- SWIMM BACK      45
		-- FLIGHT          548
		-- FLIGHT FORWARD  135 556 558
		-- FLIGHT BACK     550 562
		-- SPECIAL         94

		-- PLAYER 91
		local mountDisplay = self:GetParent()
		if actor then
			if btn == "RightButton" then
				i = i + 1
			end
			fprint(i)
			actor:SetAnimation(i)
			-- actor2:SetAnimation(i)
			-- if timer then timer:Cancel() end

			-- local lastDisplayed = mountDisplay.lastDisplayed
			-- timer = C_Timer.NewTimer(10, function()
			-- 	if mountDisplay.lastDisplayed == lastDisplayed then
			-- 		actor:SetAnimation(0)
			-- 	end
			-- end)
		end
	end)

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
-- GetBuildInfo