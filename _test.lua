local addon, ns = ...
local L, mounts, config, journal = ns.L, ns.mounts, ns.config, ns.journal
mounts.mountsDB = ns.mountsDB
local test = CreateFrame("Frame")
test:RegisterEvent("PLAYER_ENTERING_WORLD")


local ignoreEvents = {
	["SPELL_ACTIVATION_OVERLAY_HIDE"] = true,
	["ARENA_SEASON_WORLD_STATE"] = true,
	["PVP_RATED_STATS_UPDATE"] = true,
	["UNIT_AURA"] = true,
	["BAG_UPDATE_COOLDOWN"] = true,
	["GLOBAL_MOUSE_DOWN"] = true,
	["GLOBAL_MOUSE_UP"] = true,
	["PLAYER_STOPPED_MOVING"] = true,
	["PLAYER_STARTED_MOVING"] = true,
	["ACTIONBAR_SLOT_CHANGED"] = true,
	["ACTIONBAR_UPDATE_COOLDOWN"] = true,
	["SPELL_UPDATE_USABLE"] = true,
	["MODIFIER_STATE_CHANGED"] = true,
	["SPELL_UPDATE_COOLDOWN"] = true,
	["UPDATE_FACTION"] = true,
	["UNIT_POWER_FREQUENT"] = true,
	["UNIT_POWER_UPDATE"] = true,
	-- [""] = true,
	-- [""] = true,
	["CURSOR_CHANGED"] = true,
	["WORLD_CURSOR_TOOLTIP_UPDATE"] = true,
	["UPDATE_UI_WIDGET"] = true,
	["UPDATE_MOUSEOVER_UNIT"] = true,
	["QUICK_TICKET_THROTTLE_CHANGED"] = true,
	["STORE_STATUS_CHANGED"] = true,
	["TOKEN_STATUS_CHANGED"] = true,
	["SOCIAL_QUEUE_CONFIG_UPDATED"] = true,
	["WAR_MODE_STATUS_UPDATE"] = true,
	["INITIAL_CLUBS_LOADED"] = true,
	["QUEST_SESSION_ENABLED_STATE_CHANGED"] = true,
	["CONTENT_TRACKING_IS_ENABLED_UPDATE"] = true,
	["BAG_UPDATE_DELAYED"] = true,
	["FIRST_FRAME_RENDERED"] = true, -- HMMMM
	["GARRISON_LANDINGPAGE_SHIPMENTS"] = true,
	["HEIRLOOMS_UPDATED"] = true,
	["MINIMAP_UPDATE_ZOOM"] = true,
	["PET_JOURNAL_LIST_UPDATE"] = true,
	["PORTRAITS_UPDATED"] = true,
	["QUEST_LOG_UPDATE"] = true,
	["QUEST_WATCH_LIST_CHANGED"] = true,
	["PLAYER_STARTED_LOOKING"] = true,
	["PLAYER_STOPPED_LOOKING"] = true,
	["PLAYER_STARTED_TURNING"] = true,
	["PLAYER_STOPPED_TURNING"] = true,
	-- [""] = true,
	-- [""] = true,
	-- [""] = true,
}


test:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		fprint(event, ...)
		self[event](self, ...)
	else
		if not ignoreEvents[event] then
			fprint("None:", event, ...)
		end
	end
end)
test:RegisterEvent("ADDON_LOADED")
-- test:RegisterAllEvents()

test:RegisterEvent("UI_MODEL_SCENE_INFO_UPDATED")
-- test:RegisterEvent("PET_BATTLE_OPENING_START")
-- test:RegisterEvent("PET_BATTLE_OPENING_DONE")
-- test:RegisterEvent("PET_BATTLE_CLOSE")
-- test:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
-- test:RegisterEvent("CHAT_MSG_CURRENCY")

-- test:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
-- function test:COMBAT_LOG_EVENT_UNFILTERED()
-- 	fprint(CombatLogGetCurrentEventInfo())
-- end

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
-- test:RegisterEvent("SKILL_LINES_CHANGED")
-- test:RegisterEvent("COMPANION_UNLEARNED")

-- test:RegisterEvent("CALENDAR_ACTION_PENDING")
-- test:RegisterEvent("CALENDAR_UPDATE_EVENT")

-- local btn = CreateFrame("BUTTON", nil, Minimap)
-- btn:SetSize(31, 31)
-- btn:SetNormalTexture("Interface\\Artifacts\\ArtifactPower-QuestBorder")
-- btn:SetScript("OnClick", function() fprint("asd2") end)

-- local needsFanfare = C_MountJournal.NeedsFanfare
-- local mFanfare = {
-- 	[1049] = true,
-- 	[896] = true,
-- }

-- C_MountJournal.NeedsFanfare = function(mountID)
-- 	return mFanfare[mountID] or needsFanfare(mountID)
-- end

-- local clearFanfare = C_MountJournal.ClearFanfare
-- C_MountJournal.ClearFanfare = function(mountID)
-- 	if mFanfare[mountID] then
-- 		mFanfare[mountID] = nil
-- 	else
-- 		clearFanfare(mountID)
-- 	end
-- end

-- local getNumMountsNeedingFanfare = C_MountJournal.GetNumMountsNeedingFanfare
-- C_MountJournal.GetNumMountsNeedingFanfare = function()
-- 	local num = getNumMountsNeedingFanfare()
-- 	for mountID in pairs(mFanfare) do
-- 		num = num + 1
-- 	end
-- 	return num
-- end

-- GROUP_ROSTER_UPDATE

-- fprint(dumpe, getmetatable(CreateFrame("EventFrame", nil, UIParent)))

-- hooksecurefunc(C_Macro, "RunMacroText", fprint)

function test:PLAYER_ENTERING_WORLD()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")

	-- for i = 1, 500000 do
	-- 	local name = GetSpellInfo(i)
	-- 	if IsSpellKnown(i) then
	-- 		fprint(name, i)
	-- 	end
	-- end

	-- self.a = function(...) return ... end
	-- local err, r = xpcall(self.a, geterrorhandler(), "dsa")
	-- fprint("asd", err, r)

	-- local str = [[
	-- 	return function() fprint(exec) end
	-- ]]
	-- local loadedFunction, err = loadstring(str)
	-- if err then
	-- 	fprint(err)
	-- else
	-- 	setfenv(loadedFunction, {exec = "WoW", fprint = fprint, _G = _G})
	-- 	local success, func = pcall(loadedFunction)
	-- 	if success then
	-- 		func()
	-- 	end
	-- end

	-- for i = 1, 1000 do
	-- 	local info = GetProfessionInfo(i)
	-- 	if info then
	-- 		fprint(i, info)
	-- 	end
	-- end

	-- JOURNAL OPEN
	-- if not C_AddOns.IsAddOnLoaded("Blizzard_Collections") then
	-- 	C_AddOns.LoadAddOn("Blizzard_Collections")
	-- end
	-- ShowUIPanel(CollectionsJournal)
	-- journal.bgFrame.profilesMenu:Click()
	-- CollectionsJournal_SetTab(CollectionsJournal, COLLECTIONS_JOURNAL_TAB_INDEX_MOUNTS) -- DISABLE
	-- journal.mountDisplay.info.petSelectionBtn:Click()

	-- local sbg = journal.bgFrame.settingsBackground
	-- sbg:Show()

	-- local bgWidth = journal.bgFrame:GetWidth()
	-- for i = 1, sbg:GetNumPoints() do
	-- 	local point, rframe, rpoint, x, y = sbg:GetPoint(i)
	-- 	sbg:SetPoint(point, rframe, rpoint, x + bgWidth, y)
	-- end

	-- sbg:SetSize(sbg:GetSize())
	-- sbg:ClearAllPoints()
	-- sbg:SetPoint("TOPLEFT", journal.bgFrame, "TOPRIGHT", 5, -60)
	-- sbg.Tabs[3]:Click()
	-- ns.ruleConfig.addRule:Click()

	-- journal.navBarBtn:Click()
	-- journal.mapSettings.existingListsToggle:Click()
	-- journal.navBar:setMapID(1033)
	-- journal.navBar:setMapID(909)
	-- journal.navBar:setMapID(980)

	-- CONFIG OPEN
	-- local configName = "HidingBar"
	-- local configName = addon
	-- local configName = L["Class settings"]
	-- local configName = L["About"]
	-- Settings.OpenToCategory(configName)
	-- select(14,config:GetChildren()):Click()
	-- if true then return end

	-- LOAD CHARACTER FORM
	-- local modelScene = journal.mountDisplay.modelScene

	-- local function loadPlayer()
	-- 	local mountActor = modelScene:GetActorByTag("unwrapped")
	-- 	local playerActor = modelScene:GetActorByTag("player-rider")
	-- 	playerActor:ClearModel()

	-- 	local forceSceneChange = false
	-- 	modelScene:TransitionToModelSceneID(4, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_MAINTAIN, forceSceneChange)
	-- 	modelScene:PrepareForFanfare(false)

	-- 	local sheathWeapons = true
	-- 	local autoDress = true
	-- 	local hideWeapons = false
	-- 	local usePlayerNativeForm = true
	-- 	if not mountActor:SetModelByUnit("player", sheathWeapons, autoDress, hideWeapons, usePlayerNativeForm) then
	-- 		mountActor:ClearModel()
	-- 	end
	-- end

	-- IDLE INIT 1265k
	-- IDLE 618
	-- WALK 620
	-- RUN 622 2024k 2932k
	-- Walk backwards 634
	-- SPECIAL 636 1852k

	-- 3000k

	-- C_Timer.After(0, function() loadPlayer() end)


	-- MOUNT ANIMATION
	-- local modelScene = MountJournal.MountDisplay.ModelScene
	-- local timer
	-- local i = 530
	-- local i = 557
	-- modelScene:HookScript("OnMouseDown", function(self, btn)
		-- loadPlayer()
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




-- function MountsJournalNextAnimKit(cur)
-- 	for i = 1, #animKit do
-- 		if cur < animKit[i] then return animKit[i] end
-- 	end
-- 	return animKit[1]
-- end
-- function MountsJournalPrevAnimKit(cur)
-- 	for i = #animKit, 1, -1 do
-- 		if cur > animKit[i] then return animKit[i] end
-- 	end
-- 	return animKit[#animKit]
-- end

-- local prev = animKit[1]
-- local v = {prev}
-- local asd = {}
-- for i = 2, #animKit do
-- 	local id = animKit[i]

-- 	if id - prev ~= 1 then
-- 		if prev ~= v[1] then v[2] = prev end
-- 		asd[#asd + 1] = v
-- 		v = {id}
-- 	end
-- 	prev = id
-- end
-- fprint(dumpe, asd)