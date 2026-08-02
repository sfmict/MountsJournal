local addon, ns = ...
local L, mounts, config, journal = ns.L, ns.mounts, ns.config, ns.journal
mounts.ns = ns
mounts.additionalMounts = ns.additionalMounts
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
	--elseif event == "ADDON_LOADED" then
	--	local name, containsBindings = ...
	--	local _,_,_,_,_, security = C_AddOns.GetAddOnInfo(name)
	--	fprint(event, name, containsBindings, security)
	-- elseif not ignoreEvents[event] then
		-- fprint("None:", event, ...)
	end
end)
--test:RegisterEvent("ADDON_LOADED")
-- test:RegisterAllEvents()
--test:RegisterEvent("VIEWED_TRANSMOG_OUTFIT_CHANGED")
--test:RegisterEvent("VIEWED_TRANSMOG_OUTFIT_SLOT_WEAPON_OPTION_CHANGED")

test:RegisterEvent("UI_MODEL_SCENE_INFO_UPDATED")

-- test:RegisterEvent("ADDON_RESTRICTION_STATE_CHANGED")
-- test:RegisterEvent("PLAYER_REGEN_ENABLED")
-- test:RegisterEvent("PLAYER_REGEN_DISABLED")

--ShouldSpellCooldownBeSecret, ShouldSpellAuraBeSecret
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

-- hooksecurefunc(WorldMapFrame, "AcquirePin", fprint)

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
	-- ns.util.openJournalTab(3, 3)
	--ns.ruleConfig.snippetToggle:Click() -- snippets
	--ns.snippets.addSnipBtn:Click() -- codeEdit
	--journal.mountDisplay.info.petSelectionBtn:Click()

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

-- DEBUG IN MILLISECONDS
-- debugprofilestart()
-- for i = 1, 10000 do
-- end
-- fprint(debugprofilestop())

-- UpdateAddOnMemoryUsage()
-- fprint(GetAddOnMemoryUsage(addon) / 1024, addon)
