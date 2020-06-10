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
		if event ~= "ARENA_SEASON_WORLD_STATE"
		and event ~= "PVP_RATED_STATS_UPDATE" then
			fprint("None:", event, ...)
		end
	end
end)
-- test:RegisterAllEvents()
-- test:RegisterEvent("UI_MODEL_SCENE_INFO_UPDATED")

-- test:RegisterEvent("PET_JOURNAL_PET_DELETED")
-- test:RegisterEvent("PET_JOURNAL_PETS_HEALED")
-- test:RegisterEvent("PET_JOURNAL_CAGE_FAILED")
-- test:RegisterEvent("BATTLE_PET_CURSOR_CLEAR")
-- test:RegisterEvent("COMPANION_UPDATE")
-- test:RegisterEvent("PET_BATTLE_LEVEL_CHANGED")
-- test:RegisterEvent("PET_BATTLE_QUEUE_STATUS")
-- test:RegisterEvent("UI_MODEL_SCENE_INFO_UPDATED")
-- test:RegisterEvent("COMPANION_LEARNED")
-- test:RegisterEvent("COMPANION_UNLEARNED")


function test:PLAYER_ENTERING_WORLD()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	fprint(GetBuildInfo())

	-- JOURNAL OPEN
	-- if not IsAddOnLoaded("Blizzard_Collections") then
	-- 	LoadAddOn("Blizzard_Collections")
	-- end
	-- ShowUIPanel(CollectionsJournal)
	-- MountJournal.MountDisplay.InfoButton.petSelectionBtn:Click()

	-- journal.navBarBtn:Click()
	-- journal.mapSettings.existingListsToggle:Click()
	-- journal.navBar:setMapID(1033)

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
	if true then return end

	-- hooksecurefunc("MountJournal_UpdateMountDisplay", function()
	-- 	fprint("a")
	-- end)
	-- hooksecurefunc("DressUpMount", function()
	-- 	fprint("b")
	-- end)

	-- activeCamera.UpdateCameraOrientationAndPosition = function(self)
	-- 	local yaw, pitch, roll = self:GetInterpolatedOrientation();
	-- 	-- fprint(yaw, pitch, roll)
	-- 	-- yaw = 3
	-- 	-- pitch = 0
	-- 	-- roll = 0
	-- 	local axisAngleX, axisAngleY, axisAngleZ = Vector3D_CalculateNormalFromYawPitch(yaw, pitch);

	-- 	local targetX, targetY, targetZ = self:GetInterpolatedTarget();
	-- 	-- targetX = 0
	-- 	-- targetY = 0
	-- 	-- targetZ = 0

	-- 	local X, Y
	-- 	if self:IsLeftMouseButtonDown() then
	-- 		X = targetX * math.cos(yaw) + targetY * math.sin(yaw)
	-- 		Y = targetX * math.sin(yaw) - targetY * math.cos(yaw)
	-- 		Z = targetZ
	-- 	else
	-- 		X = targetX
	-- 		Y = targetY
	-- 		Z = targetZ
	-- 	end
	-- 	-- local X2 = X * math.cos(pitch) - targetZ * math.sin(pitch)
	-- 	-- local Z = X * math.sin(pitch) + targetZ * math.cos(pitch)
	-- 	-- fprint(targetX, targetY)
	-- 	local zoomDistance = self:GetInterpolatedZoomDistance();
	-- 	-- fprint(self:CalculatePositionByDistanceFromTarget(targetX, targetY, targetZ, zoomDistance, axisAngleX, axisAngleY, axisAngleZ))

	-- 	self:SetPosition(self:CalculatePositionByDistanceFromTarget(X, Y, Z, zoomDistance, axisAngleX, axisAngleY, axisAngleZ));
	-- 	self:GetOwningScene():SetCameraOrientationByYawPitchRoll(yaw, pitch, roll);
	-- end

	-- MOUNT ANIMATION
	local modelScene = MountJournal.MountDisplay.ModelScene
	-- local timer
	-- local i = 530
	local i = 557
	modelScene:HookScript("OnMouseDown", function(self, btn)
		-- C_PetJournal.SummonPetByGUID("BattlePet-0-000001B3BB78")
		-- if true then return end
		-- if self.needsFanFare then return end
		local actor = self:GetActorByTag("unwrapped")
		-- local actor2 = self:GetActorByTag("player")
		actor2 = self:GetPlayerActor()
		-- actor2:SetModelByUnit("player")
		local creatureDisplayID, descriptionText, sourceText, isSelfMount, _, modelSceneID, animID, spellVisualKitID, disablePlayerMountPreview = C_MountJournal.GetMountInfoExtraByID(MountJournal.selectedMountID)

		local actorInfo = C_ModelInfo.GetModelSceneActorInfoByID(1)
		-- fprint(dump, actorInfo)

		-- actor2:SetModelByUnit("player", false)
		-- actor2:ClearModel()
		-- actor:Hide()
		-- actor:SetAlpha(0)
		-- actor:AttachToMount(actor2, animID, spellVisualKitID)
		-- for k,v in pairs(actor) do
		-- 	fprint(k)
		-- end
		-- fprint(C_MountJournal.GetMountInfoExtraByID(MountJournal.selectedMountID))
		-- self.UnwrapAnim.UnwrappedAnim:SetTarget(actor)

		-- local modelSceneType, cameraIDs, actorIDs = C_ModelInfo.GetModelSceneInfoByID(self.modelSceneID)
		-- local actorInfo = C_ModelInfo.GetModelSceneActorInfoByID(actorIDs[3])
		-- fprint(dump, C_ModelInfo.GetModelSceneActorDisplayInfoByID(actorInfo.modelActorDisplayID))
		-- fprint(dump, C_ModelInfo.GetModelSceneInfoByID(self.modelSceneID))
		-- C_ModelInfo.GetModelSceneActorDisplayInfoByID()
		-- UIModelSceneActorDisplayInfo

		-- WALK            4 119
		-- WALK BACK       13
		-- RUN             5 143
		-- IN WATTER       41 532
		-- SWIMM           42 540
		-- SWIMM BACK      45 534
		-- FLIGHT          548
		-- FLIGHT FORWARD  135 556 558
		-- FLIGHT BACK     550 562
		-- SPECIAL         94 636

		-- ANIMATION KIT
		-- WALK            565
		-- WALK BACK       
		-- RUN             603
		-- IN WATTER       557
		-- SWIMM           
		-- SWIMM BACK      
		-- FLIGHT          
		-- FLIGHT FORWARD  
		-- FLIGHT BACK     
		-- SPECIAL         
		-- DEMONIC         651
		-- LEFT RIGHT      349

		-- PLAYER 91
		local mountDisplay = self:GetParent()
		if actor then
			if btn == "RightButton" then
				i = i + (IsShiftKeyDown() and -1 or 1)
			end
			fprint(i)
			actor:StopAnimationKit()
			-- actor:SetAnimationBlendOperation(LE_MODEL_BLEND_OPERATION_ANIM)
			actor:PlayAnimationKit(i, IsAltKeyDown() and 0 or nil)
			-- actor:SetAnimation(i)
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
end

-- SetClampRectInsets
-- GetBuildInfo
-- C_PetJournal.SummonRandomPet(true)
-- C_PetJournal.SummonPetByGUID(PetJournalPetCard.petID)
-- C_PetJournal.GetSummonedPetGUID()

-- DEBUG IN MILLISECONDS
-- debugprofilestart()
-- for i = 1, 10000 do
-- end
-- fprint(debugprofilestop())