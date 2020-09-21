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

	-- for i = 1, 500000 do
	-- 	local name = GetSpellInfo(i)
	-- 	if IsSpellKnown(i) then
	-- 		fprint(name, i)
	-- 	end
	-- end

	for _, id in ipairs({90265, 34091, 34090, 33391, 33388}) do
		if IsSpellKnown(id) then
			fprint(("IsSpellKnown(%d)"):format(id), "DETECTED")
		else
			fprint(("IsSpellKnown(%d)"):format(id), "NOT DETECTED")
		end
	end

	-- for i = 1, 1000 do
	-- 	local info = GetProfessionInfo(i)
	-- 	if info then
	-- 		fprint(i, info)
	-- 	end
	-- end

	-- JOURNAL OPEN
	-- if not IsAddOnLoaded("Blizzard_Collections") then
	-- 	LoadAddOn("Blizzard_Collections")
	-- end
	-- ShowUIPanel(CollectionsJournal)
	-- MountJournal.MountDisplay.InfoButton.petSelectionBtn:Click()

	-- journal.navBarBtn:Click()
	-- journal.mapSettings.existingListsToggle:Click()
	-- journal.navBar:setMapID(1033)
	-- journal.navBar:setMapID(909)
	-- journal.navBar:setMapID(980)

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
	-- if true then return end

	-- MOUNT ANIMATION
	-- local modelScene = MountJournal.MountDisplay.ModelScene
	-- local timer
	-- local i = 530
	-- local i = 557
	-- modelScene:HookScript("OnMouseDown", function(self, btn)
	-- 	-- C_PetJournal.SummonPetByGUID("BattlePet-0-000001B3BB78")
	-- 	-- if true then return end
	-- 	-- if self.needsFanFare then return end
	-- 	local actor = self:GetActorByTag("unwrapped")
	-- 	-- local actor2 = self:GetActorByTag("player")
	-- 	actor2 = self:GetPlayerActor()
	-- 	-- actor2:SetModelByUnit("player")
	-- 	local creatureDisplayID, descriptionText, sourceText, isSelfMount, _, modelSceneID, animID, spellVisualKitID, disablePlayerMountPreview = C_MountJournal.GetMountInfoExtraByID(MountJournal.selectedMountID)

	-- 	local actorInfo = C_ModelInfo.GetModelSceneActorInfoByID(1)
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
		-- local mountDisplay = self:GetParent()
		-- if actor then
		-- 	if btn == "RightButton" then
		-- 		i = i + (IsShiftKeyDown() and -1 or 1)
		-- 	end
		-- 	fprint(i)
		-- 	actor:StopAnimationKit()
		-- 	-- actor:SetAnimationBlendOperation(LE_MODEL_BLEND_OPERATION_ANIM)
		-- 	actor:PlayAnimationKit(i, IsAltKeyDown() and 0 or nil)
		-- 	-- actor:SetAnimation(i)
		-- 	-- actor2:SetAnimation(i)
		-- 	-- if timer then timer:Cancel() end

		-- 	-- local lastDisplayed = mountDisplay.lastDisplayed
		-- 	-- timer = C_Timer.NewTimer(10, function()
		-- 	-- 	if mountDisplay.lastDisplayed == lastDisplayed then
		-- 	-- 		actor:SetAnimation(0)
		-- 	-- 	end
		-- 	-- end)
		-- end
	-- end)
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

-- UpdateAddOnMemoryUsage()
-- fprint(GetAddOnMemoryUsage(addon) / 1024, addon)

-- /dump MountJournal.ListScrollFrame.scrollBar:SetValue((46 * 2 - .00000000001) /46)

-- QUATERNION============================================
-- local Quaternion = {}

-- local function CreateQauternion(a, x, y, z)
-- 	local q = {}
-- 	for k, v in pairs(Quaternion) do
-- 		q[k] = v
-- 	end
-- 	if a then q:set(a, x, y, z) end
-- 	return q
-- end

-- function Quaternion:sete(x, y, z)
-- 	local c1 = math.cos( x / 2 );
-- 	local c2 = math.cos( y / 2 );
-- 	local c3 = math.cos( z / 2 );

-- 	local s1 = math.sin( x / 2 );
-- 	local s2 = math.sin( y / 2 );
-- 	local s3 = math.sin( z / 2 );

-- 	-- self.x = s1 * c2 * c3 + c1 * s2 * s3;
-- 	-- self.y = c1 * s2 * c3 - s1 * c2 * s3;
-- 	-- self.z = c1 * c2 * s3 + s1 * s2 * c3;
-- 	-- self.a = c1 * c2 * c3 - s1 * s2 * s3

-- 	self.a = c1 * c2 * c3 + s1 * s2 * s3;
-- 	self.x = s1 * c2 * c3 + c1 * s2 * s3;
-- 	self.y = c1 * s2 * c3 - s1 * c2 * s3;
-- 	self.z = c1 * c2 * s3 - s1 * s2 * c3;

-- 	-- self.x = s1 * c2 * c3 - c1 * s2 * s3;
-- 	-- self.y = c1 * s2 * c3 + s1 * c2 * s3;
-- 	-- self.z = c1 * c2 * s3 + s1 * s2 * c3;
-- 	-- self.a = c1 * c2 * c3 - s1 * s2 * s3;

-- 	-- self.x = s1 * c2 * c3 - c1 * s2 * s3;
-- 	-- self.y = c1 * s2 * c3 + s1 * c2 * s3;
-- 	-- self.z = c1 * c2 * s3 - s1 * s2 * c3;
-- 	-- self.a = c1 * c2 * c3 + s1 * s2 * s3;

-- 	fprint(self.a, self.x, self.y, self.z)
-- 	return self
-- end

-- function Quaternion:set(a, x, y ,z)
-- 	local halfA = a / 2
-- 	local s = math.sin(halfA)
-- 	self.a = math.cos(halfA)
-- 	self.x = x * s
-- 	self.y = y * s
-- 	self.z = z * s
-- 	-- local c1 = math.cos( x / 2 );
-- 	-- local c2 = math.cos( y / 2 );
-- 	-- local c3 = math.cos( z / 2 );

-- 	-- local s1 = math.sin( x / 2 );
-- 	-- local s2 = math.sin( y / 2 );
-- 	-- local s3 = math.sin( z / 2 );

-- 	-- self.a = c1 * c2 * c3 - s1 * s2 * s3;
-- 	-- self.x = s1 * c2 * c3 + c1 * s2 * s3;
-- 	-- self.y = c1 * s2 * c3 - s1 * c2 * s3;
-- 	-- self.z = c1 * c2 * s3 + s1 * s2 * c3;

-- 	return self
-- end

-- function Quaternion:getYawPitchRoll()
-- 	-- local yaw, pitch, roll

-- 	-- EXAMPLE 1
-- 	local yaw = math.atan2(2*(self.y*self.z + self.a*self.x), self.a*self.a - self.x*self.x - self.y*self.y + self.z*self.z);
-- 	local pitch = math.asin(math.min(1, math.max(-2*(self.x*self.z - self.a*self.y), -1)));
-- 	local roll = math.atan2(2*(self.x*self.y + self.a*self.z), self.a*self.a + self.x*self.x - self.y*self.y - self.z*self.z);

-- 	-- EXAMPLE 2
-- 	-- local sinr_cosp = 2 * (self.a * self.x + self.y * self.z);
-- 	-- local cosr_cosp = 1 - 2 * (self.x * self.x + self.y * self.y);
-- 	-- roll = math.atan2(sinr_cosp, cosr_cosp);

-- 	--  -- pitch (y-axis rotation)
-- 	-- local sinp = 2 * (self.a * self.y - self.z * self.x);
-- 	-- -- if math.abs(sinp) >= 1 then
-- 	-- 	-- pitch = math.pi / 2 -- use 90 degrees if out of range
-- 	-- 	-- if sinp < 0 then pitch = -pitch end
-- 	-- -- else
-- 	-- 	pitch = math.asin(sinp)
-- 	-- -- end

-- 	--  -- yaw (z-axis rotation)
-- 	-- local siny_cosp = 2 * (self.a * self.z + self.x * self.y);
-- 	-- local cosy_cosp = 1 - 2 * (self.y * self.y + self.z * self.z);
-- 	-- yaw = math.atan2(siny_cosp, cosy_cosp);

-- 	-- local sqw = self.a*self.a;
--  --   local sqx = self.x*self.x;
--  --   local sqy = self.y*self.y;
--  --   local sqz = self.z*self.z;
-- 	-- local unit = sqx + sqy + sqz + sqw; -- if normalised is one, otherwise is correction factor
-- 	-- local test = self.x*self.y + self.z*self.a;
-- 	-- if (test > 0.499*unit) then -- singularity at north pole
-- 	-- 	pitch = 2 * math.atan2(self.x,self.a);
-- 	-- 	roll = math.pi/2;
-- 	-- 	yaw = 0;
-- 	-- elseif (test < -0.499*unit) then -- singularity at south pole
-- 	-- 	pitch = -2 * math.atan2(self.x,self.a);
-- 	-- 	roll = -math.pi/2;
-- 	-- 	yaw = 0;
-- 	-- else
-- 	-- 	pitch = math.atan2(2*self.y*self.a-2*self.x*self.z , sqx - sqy - sqz + sqw);
-- 	-- 	roll = math.asin(2*test/unit);
-- 	-- 	yaw = math.atan2(2*self.x*self.a-2*self.y*self.z , -sqx + sqy - sqz + sqw)
-- 	-- end

-- 	return yaw, pitch, roll
-- end

-- function Quaternion:mul(q1, q2)
-- 	if not q2 then
-- 		q2 = q1
-- 		q1 = self
-- 	end

-- 	local q1a, q1x, q1y, q1z = q1.a, q1.x, q1.y, q1.z
-- 	local q2a, q2x, q2y, q2z = q2.a, q2.x, q2.y, q2.z

-- 	self.a = q1a * q2a - q1x * q2x - q1y * q2y - q1z * q2z
-- 	self.x = q1x * q2a + q1a * q2x + q1y * q2z - q1z * q2y
-- 	self.y = q1y * q2a + q1a * q2y + q1z * q2x - q1x * q2z
-- 	self.z = q1z * q2a + q1a * q2z + q1x * q2y - q1y * q2x
-- 	return self
-- end