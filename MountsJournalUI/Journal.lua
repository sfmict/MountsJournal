local addon, ns = ...
local L, util, mounts = ns.L, ns.util, ns.mounts
local C_MountJournal, C_PetJournal, C_Timer, InCombatLockdown = C_MountJournal, C_PetJournal, C_Timer, InCombatLockdown
local next, pairs, ipairs, type, math = next, pairs, ipairs, type, math
local wipe, tinsert, sort, concat, select = wipe, table.insert, table.sort, table.concat, select
local journal = CreateFrame("FRAME", "MountsJournalFrame")
ns.journal = util.setEventsMixin(journal)


local MOUNT_ACHIEVEMENT_CATEGORY = 15248


journal.colors = {
	gold = CreateColor(.8, .6, 0),
	gray = CreateColor(.5, .5, .5),
	dark = CreateColor(.3, .3, .3),
	mount1 = CreateColor(.824, .78, .235),
	mount2 = CreateColor(.62, .502, .424),
	mount3 = CreateColor(.231, .533, .588),
	mount4 = CreateColor(.03, .48, .03),
}
-- local metaMounts = {__index = {[0] = 0}}
journal.indexByMountID = {}


function journal:init()
	self.init = nil

	local lsfdd = LibStub("LibSFDropDown-1.5")
	local texPath = "Interface/AddOns/MountsJournal/textures/"
	self.tFly = texPath.."fly"
	self.tGround = texPath.."ground"
	self.tSwimming = texPath.."swimming"
	self.mountIDs = C_MountJournal.GetMountIDs()

	-- FILTERS INIT
	local filtersMeta = {__index = function(self, key)
		self[key] = true
		return self[key]
	end}

	local function checkFilters(filters)
		if filters.collected == nil then filters.collected = true end
		if filters.notCollected == nil then filters.notCollected = true end
		if filters.unusable == nil then filters.unusable = true end
		filters.types = setmetatable(filters.types or {}, filtersMeta)
		filters.selected = setmetatable(filters.selected or {}, filtersMeta)
		filters.sources = setmetatable(filters.sources or {}, filtersMeta)
		filters.specific = setmetatable(filters.specific or {}, filtersMeta)
		filters.family = setmetatable(filters.family or {}, filtersMeta)
		filters.factions = setmetatable(filters.factions or {}, filtersMeta)
		filters.pet = setmetatable(filters.pet or {}, filtersMeta)
		filters.expansions = setmetatable(filters.expansions or {}, filtersMeta)
		filters.mountsRarity = filters.mountsRarity or {
			-- sign = nil,
			value = 100,
		}
		filters.mountsWeight = filters.mountsWeight or {
			-- sign = nil,
			weight = 100,
		}
		filters.tags = filters.tags or {
			noTag = true,
			withAllTags = false,
			tags = {},
		}
		filters.color = filters.color or {threshold = 20}
	end

	checkFilters(mounts.filters)
	mounts.filters.sorting = mounts.filters.sorting or {
		by = "name",
		favoritesFirst = true,
	}
	if mounts.filters.sorting.collectedFirst == nil then
		mounts.filters.sorting.collectedFirst = true
	end
	if mounts.filters.sorting.additionalFirst == nil then
		mounts.filters.sorting.additionalFirst = true
	end
	mounts.filters.sorting.by2 = mounts.filters.sorting.by2 or "name"
	mounts.filters.sorting.by3 = mounts.filters.sorting.by3 or "name"
	checkFilters(mounts.defFilters)
	setmetatable(mounts.defFilters.tags.tags, filtersMeta)

	self.mountsWithMultipleModels = {}
	for i = 1, #self.mountIDs do
		local mountID = self.mountIDs[i]
		local creatureIDs = self:getMountAllCreatureDisplayInfo(mountID)
		if creatureIDs and #creatureIDs > 1 then
			self.mountsWithMultipleModels[mountID] = true
		end
	end

	-- ADDITIONAL MOUNTS
	for spellID, mount in next, ns.additionalMounts do
		if mount.allCreature then self.mountsWithMultipleModels[mount] = true end
		self.mountIDs[#self.mountIDs + 1] = mount
	end

	-- BACKGROUND FRAME
	self.bgFrame = CreateFrame("FRAME", "MountsJournalBackground", self.useMountsJournalButton, "MJMountJournalFrameTemplate")
	self.bgFrame:SetPoint("TOPLEFT", self.CollectionsJournal, "TOPLEFT", 0, 0)
	self.bgFrame:SetTitle(MOUNTS)
	self.bgFrame:SetPortraitToAsset("Interface/Icons/MountJournalPortrait")

	self.bgFrame:SetScript("OnShow", function()
		self.CollectionsJournal.NineSlice:Hide()
		self:RegisterEvent("COMPANION_UPDATE")
		self:RegisterEvent("UI_MODEL_SCENE_INFO_UPDATED")
		self:RegisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		self:RegisterEvent("SPELLS_CHANGED")
		self:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "player")
		self:on("MOUNT_SPEED_UPDATE", self.updateSpeed)
		self:on("MOUNTED_UPDATE", self.updateMounted)
		self:updateCollectionTabs()
		local notCombat = not InCombatLockdown()
		self.leftInset:EnableKeyboard(notCombat)
		self.bgFrame.resize:SetEnabled(notCombat)
		local by = mounts.filters.sorting.by
		if by == "summons" or by == "time" or by == "distance" then
			self:sortMounts()
		else
			self:updateMountsList()
		end
		self:updateMountDisplay(true)
		local isMounted = util.isMounted()
		self.mountSpecial:SetEnabled(isMounted)
		self.mountSpeed:SetShown(mounts.config.statCollection and isMounted)
	end)

	self.bgFrame:SetScript("OnHide", function()
		self.CollectionsJournal.NineSlice:Show()
		self:UnregisterEvent("COMPANION_UPDATE")
		self:UnregisterEvent("UI_MODEL_SCENE_INFO_UPDATED")
		self:UnregisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")
		self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		self:UnregisterEvent("SPELLS_CHANGED")
		self:UnregisterEvent("UNIT_PORTRAIT_UPDATE")
		self:off("MOUNT_SPEED_UPDATE", self.updateSpeed)
		self:off("MOUNTED_UPDATE", self.updateMounted)
		self:updateCollectionTabs()
	end)

	self.bgFrame:RegisterForDrag("LeftButton")
	for _, e in ipairs({"OnMouseDown", "OnMouseUp", "OnDragStart", "OnDragStop"}) do
		self.bgFrame:SetScript(e, function(_, ...)
			local func = self.CollectionsJournal:GetScript(e)
			if func then
				func(self.CollectionsJournal, ...)
			end
		end)
	end

	self.mountCount = self.bgFrame.mountCount
	self.achiev = self.bgFrame.achiev
	self.navBar = self.bgFrame.navBar
	self.worldMap = self.bgFrame.worldMap
	self.mapSettings = self.bgFrame.mapSettings
	self.existingLists = self.mapSettings.existingLists
	self.filtersPanel = self.bgFrame.filtersPanel
	self.filtersToggle = self.filtersPanel.btnToggle
	self.gridToggleButton = self.filtersPanel.gridToggleButton
	self.searchBox = self.filtersPanel.searchBox
	self.filtersBar = self.filtersPanel.filtersBar
	self.shownPanel = self.filtersPanel.shownPanel
	self.gridModelSettings = self.bgFrame.gridModelSettings
	self.leftInset = self.bgFrame.leftInset
	self.rightInset = self.bgFrame.rightInset
	self.mountDisplay = self.bgFrame.mountDisplay
	self.modelScene = self.mountDisplay.modelScene
	self.multipleMountBtn = self.modelScene.multipleMountBtn
	self.mountListUpdateAnim = self.leftInset.updateAnimFrame.anim
	self.scrollBox = self.leftInset.scrollBox
	self.summonButton = self.bgFrame.summonButton
	self.percentSlider = self.bgFrame.percentSlider
	self.mountSpecial = self.bgFrame.mountSpecial
	self.mountSpeed = self.leftInset.mountSpeed

	-- USE MountsJournal BUTTON
	self.useMountsJournalButton:SetParent(self.CollectionsJournal)
	self.useMountsJournalButton:SetScript("OnShow", nil)
	self.useMountsJournalButton:SetScript("OnHide", nil)
	self.useMountsJournalButton:SetPoint("BOTTOMLEFT", self.bgFrame, "BOTTOMLEFT", 281, 2)
	self.useMountsJournalButton:EnableMouse(false)
	self.useMountsJournalButton:SetFlattensRenderLayers(true)
	self.useMountsJournalButton:SetFrameLevel(self.CollectionsJournal:GetFrameLevel() + 1000)
	self.bgFrame:SetFrameLevel(self.useMountsJournalButton:GetFrameLevel() - 1)

	-- SECURE FRAMES
	local sMountJournal = CreateFrame("FRAME", nil, self.MountJournal, "SecureHandlerShowHideTemplate")
	self._s = sMountJournal
	local randomButton = self.MountJournal.SummonRandomFavoriteSpellFrame
	randomButton:Hide()
	sMountJournal:SetFrameRef("randomButton", randomButton)
	sMountJournal:SetFrameRef("useMountsJournalButton", self.useMountsJournalButton)
	sMountJournal:SetFrameRef("bgFrame", self.bgFrame)
	sMountJournal:SetFrameRef("CollectionsJournalTab1", CollectionsJournalTab1)
	sMountJournal:SetAttribute("useDefaultJournal", mounts.config.useDefaultJournal)
	sMountJournal:SetAttribute("isShow", true)
	sMountJournal:SetAttribute("_onshow", [[
		self:SetAttribute("isShow", true)
		self:RunAttribute("update")
	]])
	sMountJournal:SetAttribute("_onhide", [[
		self:SetAttribute("isShow", false)
		self:RunAttribute("update")
	]])
	sMountJournal:SetAttribute("update", [[
		local randomButton = self:GetFrameRef("randomButton")
		local useMountsJournalButton = self:GetFrameRef("useMountsJournalButton")
		local bgFrame = self:GetFrameRef("bgFrame")
		local tab, rFrame = self:GetFrameRef("CollectionsJournalTab1")

		if self:GetAttribute("isShow") then
			useMountsJournalButton:Show()
			if self:GetAttribute("useDefaultJournal") then
				randomButton:Show()
				bgFrame:Hide()
				useMountsJournalButton:SetPoint("BOTTOMLEFT", "$parent", "BOTTOMLEFT", 281, 2)
				rFrame = "$parent"
			else
				randomButton:Hide()
				bgFrame:Show()
				useMountsJournalButton:SetPoint("BOTTOMLEFT", bgFrame, "BOTTOMLEFT", 281, 2)
				rFrame = bgFrame
			end
		else
			randomButton:Show()
			useMountsJournalButton:Hide()
			bgFrame:Hide()
			rFrame = "$parent"
		end

		if tab:IsProtected() then
			local point, _, rPoint, x, y = tab:GetPoint()
			tab:SetPoint(point, rFrame, rPoint, x, y)
		end
	]])
	sMountJournal:SetFrameRef("DynamicFlightModeButton", self.bgFrame.DynamicFlightModeButton)
	sMountJournal:SetFrameRef("frame1", self.mountCount)
	sMountJournal:SetFrameRef("frame2", self.bgFrame.slotButton)
	sMountJournal:SetFrameRef("frame3", self.bgFrame.summon1)
	sMountJournal:SetFrameRef("frame4", self.bgFrame.summon2)
	sMountJournal:SetFrameRef("frame5", self.summonButton)
	sMountJournal:SetAttribute("tabUpdate", [[
		local tab = self:GetAttribute("tab")
		local i = 1
		while true do
			local frame = self:GetFrameRef("frame"..i)
			if frame then
				if tab == 1 then
					frame:Hide()
				else
					frame:Show()
				end
			else
				break
			end
			i = i + 1
		end
		local DynamicFlightModeButton = self:GetFrameRef("DynamicFlightModeButton")
		if tab ~= 1 and self:GetAttribute("isDragonRidingUnlocked") then
			DynamicFlightModeButton:Show()
		else
			DynamicFlightModeButton:Hide()
		end
		for i = 1, self:GetAttribute("numTabs") do
			if i == tab then
				self:GetFrameRef("tab"..i):Disable()
			else
				self:GetFrameRef("tab"..i):Enable()
			end
		end
	]])

	local sMountsJournalButton = CreateFrame("BUTTON", nil, self.useMountsJournalButton, "SecureHandlerClickTemplate")
	sMountsJournalButton:SetAllPoints()
	sMountsJournalButton:SetHitRectInsets(self.useMountsJournalButton:GetHitRectInsets())
	sMountsJournalButton:SetScript("OnEnter", function()
		self.useMountsJournalButton.highlight:Show()
	end)
	sMountsJournalButton:SetScript("OnLeave", function()
		self.useMountsJournalButton.highlight:Hide()
	end)
	sMountsJournalButton:SetScript("OnMouseDown", function()
		self.useMountsJournalButton:GetPushedTexture():Show()
	end)
	sMountsJournalButton:SetScript("OnMouseUp", function()
		self.useMountsJournalButton:GetPushedTexture():Hide()
	end)
	sMountsJournalButton:SetFrameRef("s", sMountJournal)
	sMountsJournalButton:SetAttribute("_onclick", [[
		self:GetParent():CallMethod("Click")
		local frame = self:GetFrameRef("s")
		frame:SetAttribute("useDefaultJournal", not frame:GetAttribute("useDefaultJournal"))
		frame:RunAttribute("update")
	]])

	-- TABS
	self.bgFrame.setTab = function(tab)
		PlaySound(SOUNDKIT.UI_TOYBOX_TABS)
		PanelTemplates_SetTab(self.bgFrame, tab)

		self.bgFrame.settingsBackground:SetShown(tab == 1)
		self.achiev:SetShown(tab ~= 1)
		self.bgFrame.targetMount:SetShown(tab ~= 1)
		self.bgFrame.OpenDynamicFlightSkillTreeButton:SetShown(tab ~= 1 and DragonridingUtil.IsDragonridingUnlocked())
		self.navBar:SetShown(tab == 2)
		self.filtersPanel:SetShown(tab ~= 1)
		self.leftInset:SetShown(tab ~= 1)
		self.altGrid = tab ~= 3
		self:setScrollGridMounts()
		self.gridToggleButton:setCoordIcon()
		if tab == 1 then self.rightInset:Hide() end
		if tab ~= 3 then self.mountDisplay:Hide() end
		self.worldMap:SetShown(tab == 2)
		self.mapSettings:SetShown(tab == 2)
		self.bgFrame.profilesMenu:SetShown(tab ~= 1)
		self.mountSpecial:SetShown(tab ~= 1)
		self.bgFrame.summonPanelSettings:SetShown(tab ~= 1 and mounts.summonPanel:IsShown())
		self:event("TAB_CHANGED")
	end

	self.bgFrame.settingsTab:SetText(L["Settings"])
	self.bgFrame.settingsTab.Enable = nop
	self.bgFrame.settingsTab.Disable = nop
	self.bgFrame.mapTab:SetText(L["Map"])
	self.bgFrame.mapTab.Enable = nop
	self.bgFrame.mapTab.Disable = nop
	self.bgFrame.modelTab:SetText(L["Model"])
	self.bgFrame.modelTab:Disable()
	self.bgFrame.modelTab.Enable = nop
	self.bgFrame.modelTab.Disable = nop

	for i = 1, #self.bgFrame.Tabs do
		local tab = self.bgFrame.Tabs[i]
		PanelTabButtonMixin.OnLoad(tab)
		sMountJournal:SetFrameRef("tab"..i, tab)
		tab:OnEvent()
		tab:SetFrameRef("s", sMountJournal)
		tab:SetAttribute("_onclick", [[
			local frame = self:GetFrameRef("s")
			frame:SetAttribute("tab", ]]..i..[[)
			frame:RunAttribute("tabUpdate")
		]])
		tab:HookScript("OnClick", function() self.bgFrame.setTab(i) end)
	end

	self.bgFrame.numTabs = 3
	PanelTemplates_SetTab(self.bgFrame, self.bgFrame.numTabs)
	sMountJournal:SetAttribute("numTabs", self.bgFrame.numTabs)

	-- SET SIZE
	local minWidth, minHeight, maxWidth, maxHeight = self:getMinMaxSize()
	local width = Clamp(mounts.config.journalWidth or minWidth, minWidth, maxWidth)
	local height = Clamp(mounts.config.journalHeight or minHeight, minHeight, maxHeight)
	self.bgFrame:SetSize(width, height)

	-- DYNAMIC FLIGHT
	hooksecurefunc(self.MountJournal.ToggleDynamicFlightFlyoutButton, "UpdateVisibility", function()
		if InCombatLockdown() then return end
		local isDragonRidingUnlocked = DragonridingUtil.IsDragonridingUnlocked()
		local show = isDragonRidingUnlocked and PanelTemplates_GetSelectedTab(self.bgFrame) ~= 1
		self.bgFrame.OpenDynamicFlightSkillTreeButton:SetShown(show)
		self.bgFrame.DynamicFlightModeButton:SetShown(show)
		sMountJournal:SetAttribute("isDragonRidingUnlocked", isDragonRidingUnlocked)
	end)

	-- CLOSE BUTTON
	self.bgFrame.closeButton:SetAttribute("type", "click")
	self.bgFrame.closeButton:SetAttribute("clickbutton", self.CollectionsJournal.CloseButton)

	-- MOUNT COUNT
	self.mountCount.collectedLabel:SetText(L["Collected:"])
	self.mountCount:SetScript("OnLeave", GameTooltip_Hide)
	self.mountCount:SetScript("OnEnter", function(frame)
		local summons, mountTime, mountDistance = 0, 0, 0
		for k, v in next, mounts.stat do
			summons = summons + v[1]
			mountTime = mountTime + v[2]
			mountDistance = mountDistance + v[3]
		end
		if summons == 0 and mountTime == 0 and mountDistance == 0 then return end

		GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT")
		GameTooltip:SetText(TOTAL)

		if summons > 0 then util.addTooltipDLine(SUMMONS, summons) end
		if mountTime > 0 then util.addTooltipDLine(L["Travel time"], util.getTimeBreakDown(mountTime)) end
		if mountDistance > 0 then
			util.addTooltipDLine(L["Travel distance"], util:getFormattedDistance(mountDistance))
			util.addTooltipDLine(L["Avg. speed"], util:getFormattedAvgSpeed(mountDistance, mountTime))
		end

		GameTooltip:Show()
	end)
	self:updateCountMounts()
	self:RegisterEvent("COMPANION_LEARNED")
	self:RegisterEvent("COMPANION_UNLEARNED")

	-- ACHIEVEMENT
	self:ACHIEVEMENT_EARNED()
	self.achiev:SetScript("OnClick", function()
		ToggleAchievementFrame()
		AchievementFrame_UpdateAndSelectCategory(MOUNT_ACHIEVEMENT_CATEGORY)
	end)
	self:RegisterEvent("ACHIEVEMENT_EARNED")

	-- MACRO BUTTONS
	local summon1Handler = _G[util.secureButtonNameMount]
	local summon1 = self.bgFrame.summon1
	summon1.id = 1
	summon1.icon:SetTexture(mounts.config.summon1Icon)
	summon1:SetAttribute("clickbutton", summon1Handler)
	SecureHandlerWrapScript(summon1, "OnClick", summon1Handler, [[owner:SetAttribute("useOnKeyDown", false);return nil, "post"]], [[owner:SetAttribute("useOnKeyDown", nil)]])
	summon1:SetScript("OnDragStart", function()
		mounts.summonPanel:startDrag()
	end)
	summon1:SetScript("OnDragStop", function()
		mounts.summonPanel:stopDrag()
	end)
	summon1:SetScript("OnEnter", function(btn)
		GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
		GameTooltip_SetTitle(GameTooltip, ("%s \"%s %d\""):format(ns.addon, SUMMONS, btn.id))
		if ns.macroFrame.currentRuleSet[btn.id].altMode then
			GameTooltip_AddNormalLine(GameTooltip, L["SecondMountTooltipDescription"]:gsub("\n\n", "\n"))
		else
			GameTooltip:AddLine(L["Normal mount summon"])
		end
		GameTooltip_AddColoredLine(GameTooltip, "\n"..L["Drag to create a summon panel"], NIGHT_FAE_BLUE_COLOR, false)
		GameTooltip_AddColoredLine(GameTooltip, L["UseBindingTooltip"], NIGHT_FAE_BLUE_COLOR, false)
		if InCombatLockdown() then
			GameTooltip_AddErrorLine(GameTooltip, SPELL_FAILED_AFFECTING_COMBAT)
		end
		GameTooltip:Show()
	end)

	local summon2Handler = _G[util.secureButtonNameSecondMount]
	local summon2 = self.bgFrame.summon2
	summon2.id = 2
	summon2.icon:SetTexture(mounts.config.summon2Icon)
	summon2:SetAttribute("clickbutton", summon2Handler)
	SecureHandlerWrapScript(summon2, "OnClick", summon2Handler, [[owner:SetAttribute("useOnKeyDown", false);return nil, "post"]], [[owner:SetAttribute("useOnKeyDown", nil)]])
	summon2:SetScript("OnDragStart", summon1:GetScript("OnDragStart"))
	summon2:SetScript("OnDragStop", summon1:GetScript("OnDragStop"))
	summon2:SetScript("OnEnter", summon1:GetScript("OnEnter"))

	-- update btn icon
	self:on("UPDATE_SUMMON_ICON", function(self, id, icon)
		self.bgFrame["summon"..id].icon:SetTexture(icon)
	end)

	-- NAVBAR
	self:on("MAP_CHANGE", function(self)
		self:setEditMountsList()
		self:updateMountsList()
		self:updateMapSettings()

		self.mountListUpdateAnim:Stop()
		self.mountListUpdateAnim:Play()
	end)

	-- MAP SETTINGS
	self.mapSettings:SetScript("OnShow", function() self:updateMapSettings() end)
	self.mapSettings.CurrentMap:SetText(L["Current Location"])
	self.mapSettings.CurrentMap:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self.navBar:setCurrentMap()
	end)
	self.mapSettings.hint.tooltip = L["ZoneSettingsTooltip"]
	self.mapSettings.hint.tooltipDescription = "\n"..L["ZoneSettingsTooltipDescription"]
	self.mapSettings.Flags.Text:SetText(L["Enable Flags"])
	self.mapSettings.Flags:HookScript("OnClick", function(check) self:setFlag("enableFlags", check:GetChecked()) end)
	self.mapSettings.Ground = util.createCheckboxChild(L["Ground Mounts Only"], self.mapSettings.Flags)
	self.mapSettings.Ground:HookScript("OnClick", function(check) self:setFlag("groundOnly", check:GetChecked()) end)
	self.mapSettings.WaterWalk = util.createCheckboxChild(L["Water Walking"], self.mapSettings.Flags)
	self.mapSettings.WaterWalk.tooltipText = L["Water Walking"]
	self.mapSettings.WaterWalk.tooltipRequirement = L["WaterWalkFlagDescription"]
	self.mapSettings.WaterWalk:HookScript("OnClick", function(check) self:setFlag("waterWalkOnly", check:GetChecked()) end)
	self.mapSettings.HerbGathering = util.createCheckboxChild(L["Herb Gathering"], self.mapSettings.Flags)
	self.mapSettings.HerbGathering.tooltipText = L["Herb Gathering"]
	self.mapSettings.HerbGathering.tooltipRequirement = L["HerbGatheringFlagDescription"]
	self.mapSettings.HerbGathering:HookScript("OnClick", function(check) self:setFlag("herbGathering", check:GetChecked()) end)
	self.mapSettings.listFromMap = lsfdd:CreateStretchButtonOriginal(self.mapSettings, 134, 30, true)
	self.mapSettings.listFromMap:SetPoint("BOTTOMLEFT", 33, 5)
	self.mapSettings.listFromMap:SetText(L["ListMountsFromZone"])
	self.mapSettings.listFromMap.maps = {}
	self.mapSettings.listFromMap:SetScript("OnClick", function(btn) self:listFromMapClick(btn) end)
	self.mapSettings.listFromMap:ddSetDisplayMode(addon)
	self.mapSettings.listFromMap:ddSetInitFunc(function(...) self:listFromMapInit(...) end)
	self.mapSettings.relationMap:SetPoint("LEFT", self.mapSettings.listFromMap, "RIGHT", 5, 0)
	self.mapSettings.relationClear:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self.currentList.listFromID = nil
		self:getRemoveMountList(self.navBar.mapID)
		self:setEditMountsList()
		self:updateMountsList()
		self:updateMapSettings()
		-- mounts:setMountsList()
		self.existingLists:refresh()

		self.mountListUpdateAnim:Stop()
		self.mountListUpdateAnim:Play()
	end)

	-- EXISTING LISTS TOGGLE
	self.mapSettings.existingListsToggle:HookScript("OnClick", function(btn)
		self.existingLists:SetShown(btn:GetChecked())
	end)

	-- FILTERS BAR
	self.filtersBar.clear:SetScript("OnClick", function() self:clearBtnFilters() end)

	local function tabClick(self)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		local id = self.id

		for _, tab in ipairs(self:GetParent().tabs) do
			if tab.id == id then
				tab.selected:Show()
				tab.content:Show()
			else
				tab.selected:Hide()
				tab.content:Hide()
			end
		end
	end

	local function setTabs(frame, ...)
		frame.tabs = {}

		for i = 1, select("#", ...) do
			local tab = CreateFrame("BUTTON", nil, frame, "MJTabTemplate")
			tab.id = select(i, ...)

			if i == 1 then
				tab:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 4, -4)
			else
				tab:SetPoint("LEFT", frame.tabs[i - 1], "RIGHT", -5, 0)
			end

			tab.text:SetText(L[tab.id])
			tab.content:SetPoint("TOPLEFT", frame, "TOPLEFT")
			tab.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
			tab:SetScript("OnClick", tabClick)

			frame[tab.id] = tab.content
			frame.tabs[i] = tab
		end

		if #frame.tabs ~= 0 then
			tabClick(frame.tabs[1])
		end
	end
	setTabs(self.filtersBar, "types", "selected", "sources")

	-- FILTERS BTN TOGGLE
	self.filtersToggle.vertical = true
	self.filtersToggle:SetChecked(mounts.config.filterToggle)

	self.filtersToggle.setFiltersToggleCheck = function(isShown)
		if isShown then
			self.filtersPanel:SetHeight(82)
			self.filtersBar:Show()
		else
			self.filtersPanel:SetHeight(29)
			self.filtersBar:Hide()
		end
	end

	self.filtersToggle:HookScript("OnClick", function(btn)
		mounts.config.filterToggle = btn:GetChecked()
		btn.setFiltersToggleCheck(mounts.config.filterToggle)
	end)

	-- GRID TOGGLE BUTTON
	self.gridToggleButton.setCoordIcon = function(btn)
		local grid = self:getGridToggle()
		if grid == 1 then
			btn.icon:SetTexCoord(0, .625, 0, .25)
		elseif grid == 2 then
			btn.icon:SetTexCoord(0, .625, .25, .5)
		else
			btn.icon:SetTexCoord(0, .625, .5, .75)
		end
	end
	self.gridToggleButton:setCoordIcon()

	self.gridToggleButton:SetScript("OnClick", function(btn)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self:setGridToggle(self:getGridToggle() + 1)
		btn:setCoordIcon()
		self:setScrollGridMounts()
	end)

	-- GRID MODEL STRIDE SLIDER
	local strideSlider = self.gridModelSettings.strideSlider
	strideSlider:setOnChanged(function(frame, value)
		if mounts.config.gridModelStride ~= value then
			mounts.config.gridModelStride = value
			self:setScrollGridMounts(true)
		end
	end)
	strideSlider:setStep(1)
	strideSlider:setMinMax(2, 6)
	strideSlider:setMaxLetters(1)
	strideSlider:setValue(mounts.config.gridModelStride)

	-- SCROLL FRAME
	self.view = CreateScrollBoxListGridView()
	ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.leftInset.scrollBar, self.view)

	-- MODELSCENE
	self.modelScene:HookScript("OnEnter", function(modelScene)
		modelScene:GetParent():SetScript("OnUpdate", nil)
		modelScene.multipleMountBtn:SetAlpha(.5)
		modelScene.modelControl:SetAlpha(.5)
		modelScene.animationsCombobox:SetAlpha(.5)
		if modelScene.playerToggle:GetParent() == modelScene then
			modelScene.playerToggle:SetAlpha(.5)
		end
	end)

	local function modelSceneControlsHide(mountDisplay, elapsed)
		mountDisplay.time = mountDisplay.time - elapsed
		local alpha = .5 / .2 * mountDisplay.time
		local modelScene = mountDisplay.modelScene
		if alpha <= 0 then
			mountDisplay:SetScript("OnUpdate", nil)
			modelScene.multipleMountBtn:SetAlpha(0)
			modelScene.modelControl:SetAlpha(0)
			modelScene.animationsCombobox:SetAlpha(0)
			if modelScene.playerToggle:GetParent() == modelScene then
				modelScene.playerToggle:SetAlpha(0)
			end
		else
			modelScene.multipleMountBtn:SetAlpha(alpha)
			modelScene.modelControl:SetAlpha(alpha)
			modelScene.animationsCombobox:SetAlpha(alpha)
			if modelScene.playerToggle:GetParent() == modelScene then
				modelScene.playerToggle:SetAlpha(alpha)
			end
		end
	end

	self.modelScene:HookScript("OnLeave", function(modelScene)
		local mountDisplay = modelScene:GetParent()
		mountDisplay.time = .2
		mountDisplay:SetScript("OnUpdate", modelSceneControlsHide)
	end)

	-- WOWHEAD LINK
	self.mountDisplay.info.link:HookScript("OnEnter", function()
		self.modelScene:GetScript("OnEnter")(self.modelScene)
	end)
	self.mountDisplay.info.link:HookScript("OnLeave", function()
		self.modelScene:GetScript("OnLeave")(self.modelScene)
	end)
	util.setCopyBox(self.mountDisplay.info.link)

	local langButton = self.mountDisplay.info.linkLang
	langButton:SetPropagateMouseMotion(true)
	langButton:SetText(mounts.config.wowheadLinkLang)

	lsfdd:SetMixin(langButton)
	langButton:ddSetDisplayMode(addon)
	langButton:ddHideWhenButtonHidden()
	langButton:ddSetNoGlobalMouseEvent(true)

	langButton:ddSetInitFunc(function(langButton)
		local info = {}

		local langs = {
			de = "Deutsch",
			en = "English",
			es = "Español",
			mx = "Español (México)",
			fr = "Français",
			it = "Italiano",
			pt = "Português (Brasil)",
			ru = "Русский",
			ko = "한국어",
			cn = "简体中文",
			tw = "繁體中文",
		}

		info.func = function(btn)
			mounts.config.wowheadLinkLang = btn.value
			langButton:SetText(btn.value)
			self:updateMountDisplay(true)
		end

		for i, lang in ipairs({"de", "en", "es", "mx", "fr", "it", "pt", "ru", "ko", "cn", "tw"}) do
			info.value = lang
			info.text = langs[lang]
			info.checked = lang == mounts.config.wowheadLinkLang
			langButton:ddAddButton(info)
		end
	end)

	langButton:SetScript("OnClick", function(btn)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		btn:ddToggle(1, nil, btn, 30, 20)
	end)

	-- RARITY TOOLTIP
	local rarityValue = self.mountDisplay.info.rarityValue
	rarityValue:SetScript("OnEnter", function(self)
		if self:IsShown() then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText(L["Collected by %s of players"]:format(self:GetText()))
			GameTooltip:Show()
		end
	end)
	rarityValue:SetScript("OnLeave", function()
		if self:IsShown() then GameTooltip:Hide() end
	end)
	rarityValue:SetMouseClickEnabled(false)

	-- MOUNT DESCRIPTION TOGGLE
	local mountDescriptionToggle = self.mountDisplay.info.mountDescriptionToggle
	mountDescriptionToggle.vertical = true
	mountDescriptionToggle:SetPropagateMouseMotion(true)
	mountDescriptionToggle:SetChecked(mounts.config.mountDescriptionToggle)

	local function setShownDescription(btn)
		local checked = btn:GetChecked()
		self.mountDisplay.info.lore:SetShown(checked)
		self.mountDisplay.info.source:SetShown(checked)
		mounts.config.mountDescriptionToggle = checked

		local activeCamera = self.modelScene.activeCamera
		if activeCamera then activeCamera:updateYOffset() end
	end
	setShownDescription(mountDescriptionToggle)
	mountDescriptionToggle:HookScript("OnClick", setShownDescription)

	-- SEARCH BOX
	self.searchBox:HookScript("OnTextChanged", function(editBox, userInput)
		if userInput then
			self:updateMountsList()
		end
	end)
	self.searchBox:SetScript("OnHide", function(editBox)
		local text = editBox:GetText()
		if #text > 0 then
			editBox:SetText("")
			self:updateMountsList()
		end
	end)
	self.searchBox.clearButton:HookScript("OnClick", function()
		self:updateMountsList()
	end)

	-- FILTERS BUTTON
	self.filtersButton = lsfdd:CreateStretchButtonOriginal(self.filtersPanel, nil, 22)
	self.filtersButton:SetPoint("LEFT", self.searchBox, "RIGHT", -1, 0)
	self.filtersButton:SetPoint("TOPRIGHT", -3, -4)
	self.filtersButton:SetText(FILTER)
	self.filtersButton:ddSetDisplayMode(addon)
	self.filtersButton:ddSetInitFunc(function(...) self:filterDropDown_Initialize(...) end)

	-- PERCENT SLIDER
	local weightControl_OnEnter = function(self)
		local parent = self:GetParent()
		parent:GetScript("OnEnter")(parent)
	end
	self.percentSlider:setOnChanged(function(frame, value)
		frame.setFunc(value)
	end)
	self.percentSlider:SetScript("OnEnter", function(frame)
		self.filtersButton:ddCloseMenus(frame.level)
	end)
	self.percentSlider.slider:HookScript("OnEnter", weightControl_OnEnter)
	self.percentSlider.edit:HookScript("OnEnter", weightControl_OnEnter)

	-- FILTER BUTTONS
	local function filterClick(btn)
		self:setBtnFilters(btn:GetParent():GetParent().id)
	end

	local function filterEnter(btn)
		GameTooltip:SetOwner(btn, "ANCHOR_BOTTOM")
		GameTooltip:SetText(btn.tooltip)
		GameTooltip:Show()
	end

	local function filterLeave()
		GameTooltip:Hide()
	end

	local function CreateButtonFilter(id, parent, width, height, texture, tWidth, tHeight, tooltip, l,r,t,b)
		local btn = CreateFrame("CheckButton", nil, parent, width == height and "MJFilterButtonSquareTemplate" or "MJFilterButtonRectangleTemplate")
		btn.id = id
		btn.tooltip = tooltip
		btn:SetSize(width, height)

		if not parent.childs then
			btn:SetPoint("LEFT", 5, 0)
			parent.childs = {}
		else
			btn:SetPoint("LEFT", parent.childs[#parent.childs], "RIGHT")
		end
		parent.childs[#parent.childs + 1] = btn

		btn.icon:SetTexture(texture)
		btn.icon:SetSize(tWidth, tHeight)
		if l then btn.icon:SetTexCoord(l,r,t,b) end

		btn:SetScript("OnClick", filterClick)
		btn:SetScript("OnEnter", filterEnter)
		btn:SetScript("OnLeave", filterLeave)
	end

	-- FILTER TYPES BUTTONS
	CreateButtonFilter(1, self.filtersBar.types, 88, 24, self.tFly, 32, 16, L["MOUNT_TYPE_1"])
	CreateButtonFilter(2, self.filtersBar.types, 88, 24, self.tGround, 32, 16, L["MOUNT_TYPE_2"])
	CreateButtonFilter(3, self.filtersBar.types, 88, 24, self.tSwimming, 32, 16, L["MOUNT_TYPE_3"])

	-- FILTER SELECTED BUTTONS
	CreateButtonFilter(1, self.filtersBar.selected, 66, 24, self.tFly, 32, 16, L["MOUNT_TYPE_1"])
	CreateButtonFilter(2, self.filtersBar.selected, 66, 24, self.tGround, 32, 16, L["MOUNT_TYPE_2"])
	CreateButtonFilter(3, self.filtersBar.selected, 66, 24, self.tSwimming, 32, 16, L["MOUNT_TYPE_3"])
	CreateButtonFilter(4, self.filtersBar.selected, 66, 24, "Interface/BUTTONS/UI-GROUPLOOT-PASS-DOWN", 16, 16, L["MOUNT_TYPE_4"])

	-- FILTER SOURCES BUTTONS
	local sourcesTex = texPath.."sources"
	for i = 1, C_PetJournal.GetNumPetSources() do
		if C_MountJournal.IsValidSourceFilter(i) then
			local col = (i - 1) % 4 * .25
			local row = math.floor((i - 1) / 4) * .25
			CreateButtonFilter(i, self.filtersBar.sources, 24, 24, sourcesTex, 20, 20, _G["BATTLE_PET_SOURCE_"..i], col, col + .25, row, row + .25)
		end
	end

	-- SHOWN PANEL
	self.shownPanel.text:SetText(L["Shown:"])
	self.shownPanel.clear:SetScript("OnClick", function() self:resetToDefaultFilters() end)
	self.shownPanel.framePool = CreateFramePool("BUTTON", self.shownPanel.resetBar, "MJFilterResetButtonTempalte")
	self.shownPanel.list = {}

	local resetFilter = self.shownPanel.resetFilter
	resetFilter.icon:SetRotation(-math.pi/2)
	lsfdd:SetMixin(self.shownPanel.resetFilter)
	resetFilter:ddSetDisplayMode(addon)
	resetFilter:ddHideWhenButtonHidden()
	resetFilter:ddSetNoGlobalMouseEvent(true)
	resetFilter:SetScript("OnClick", function(btn)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		btn:ddToggle(1, nil, btn, "TOPRIGHT", "BOTTOMRIGHT", 22, 0)
	end)
	resetFilter:ddSetInitFunc(function(dd)
		local list = dd:GetParent().list
		local info = {}
		info.keepShownOnClick = true
		info.notCheckable = true

		info.widgets = {{
			icon = "common-search-clearbutton",
			OnClick = function(btn)
				PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
				self:resetFilterByInfo(btn.value)
				dd:ddCloseMenus()
				if self.shownPanel.startIndex ~= 0 then dd:Click() end
			end,
			iconInfo = {
				tSizeX = 12,
				tSizeY = 12,
			}
		}}

		for i = self.shownPanel.startIndex, #list do
			info.text = list[i]
			info.value = list[info.text]
			dd:ddAddButton(info)
		end
	end)

	-- MODEL SCENE ACTOR
	hooksecurefunc(self.modelScene, "AcquireAndInitializeActor", function(self, actorInfo)
		if actorInfo.scriptTag == "unwrapped" then
			self:GetActorByTag("unwrapped"):SetOnSizeChangedCallback(function()
				journal.mountDisplay.loading:Hide()
				journal:event("MOUNT_MODEL_LOADED")
			end)
		end
	end)

	-- MODEL SCENE CAMERA
	hooksecurefunc(self.modelScene, "SetActiveCamera", function(self)
		journal:event("SET_ACTIVE_CAMERA", self.activeCamera)
	end)
	self.modelScene:HookScript("OnShow", function(self)
		self.activeCamera:setMaxOffsets()
	end)

	-- CAMERA X INITIAL ACCELERATION
	self.xInitialAcceleration = CreateFrame("FRAME", nil, nil, "MJSliderFrameTemplate")
	self.xInitialAcceleration:setOnChanged(function(frame, value)
		mounts.cameraConfig.xInitialAcceleration = value
	end)
	self.xInitialAcceleration:setStep(.1)
	self.xInitialAcceleration:setMinMax(.1, 1)
	self.xInitialAcceleration:setText(L["Initial x-axis accseleration"])

	-- CAMERA X ACCELERATION
	self.xAcceleration = CreateFrame("FRAME", nil, nil, "MJSliderFrameTemplate")
	self.xAcceleration:setOnChanged(function(frame, value)
		mounts.cameraConfig.xAcceleration = value
	end)
	self.xAcceleration:setStep(.1)
	self.xAcceleration:setMinMax(-2, -.1)
	self.xAcceleration:setText(L["X-axis accseleration"])
	self.xAcceleration:setMaxLetters(4)

	-- CAMERA X MIN ACCELERATION
	self.xMinSpeed = CreateFrame("FRAME", nil, nil, "MJSliderFrameTemplate")
	self.xMinSpeed:setOnChanged(function(frame, value)
		mounts.cameraConfig.xMinSpeed = value
	end)
	self.xMinSpeed:setMinMax(0, 10)
	self.xMinSpeed:setText(L["Minimum x-axis speed"])

	-- CAMERA Y INITIAL ACCELERATION
	self.yInitialAcceleration = CreateFrame("FRAME", nil, nil, "MJSliderFrameTemplate")
	self.yInitialAcceleration:setOnChanged(function(frame, value)
		mounts.cameraConfig.yInitialAcceleration = value
	end)
	self.yInitialAcceleration:setStep(.1)
	self.yInitialAcceleration:setMinMax(.1, 1)
	self.yInitialAcceleration:setText(L["Initial y-axis accseleration"])

	-- CAMERA Y ACCELERATION
	self.yAcceleration = CreateFrame("FRAME", nil, nil, "MJSliderFrameTemplate")
	self.yAcceleration:setOnChanged(function(frame, value)
		mounts.cameraConfig.yAcceleration = value
	end)
	self.yAcceleration:setStep(.1)
	self.yAcceleration:setMinMax(-2, -.1)
	self.yAcceleration:setText(L["Y-axis accseleration"])
	self.yAcceleration:setMaxLetters(4)

	-- CAMERA Y MIN ACCELERATION
	self.yMinSpeed = CreateFrame("FRAME", nil, nil, "MJSliderFrameTemplate")
	self.yMinSpeed:setOnChanged(function(frame, value)
		mounts.cameraConfig.yMinSpeed = value
	end)
	self.yMinSpeed:setMinMax(0, 10)
	self.yMinSpeed:setText(L["Minimum y-axis speed"])

	-- MODEL SCENE SETTINGS
	local mssBtn = self.mountDisplay.info.modelSceneSettingsButton
	mssBtn:SetPropagateMouseMotion(true)

	lsfdd:SetMixin(mssBtn)
	mssBtn:ddSetDisplayMode(addon)
	mssBtn:ddHideWhenButtonHidden()
	mssBtn:ddSetNoGlobalMouseEvent(true)

	mssBtn:ddSetInitFunc(function(btn, level)
		local info = {}

		info.keepShownOnClick = true
		info.isNotRadio = true
		info.text = L["Enable Acceleration around the X-axis"]
		info.checked = mounts.cameraConfig.xAccelerationEnabled
		info.func = function(_,_,_, checked)
			mounts.cameraConfig.xAccelerationEnabled = checked
		end
		btn:ddAddButton(info)

		info.customFrame = self.xInitialAcceleration
		info.OnLoad = function(frame)
			frame:setValue(mounts.cameraConfig.xInitialAcceleration)
		end
		btn:ddAddButton(info)

		info.customFrame = self.xAcceleration
		info.OnLoad = function(frame)
			frame:setValue(mounts.cameraConfig.xAcceleration)
		end
		btn:ddAddButton(info)

		info.customFrame = self.xMinSpeed
		info.OnLoad = function(frame)
			frame:setValue(mounts.cameraConfig.xMinSpeed)
		end
		btn:ddAddButton(info)

		btn:ddAddSpace()

		info.customFrame = nil
		info.text = L["Enable Acceleration around the Y-axis"]
		info.checked = mounts.cameraConfig.yAccelerationEnabled
		info.func = function(_,_,_, checked)
			mounts.cameraConfig.yAccelerationEnabled = checked
		end
		btn:ddAddButton(info)

		info.customFrame = self.yInitialAcceleration
		info.OnLoad = function(frame)
			frame:setValue(mounts.cameraConfig.yInitialAcceleration)
		end
		btn:ddAddButton(info)

		info.customFrame = self.yAcceleration
		info.OnLoad = function(frame)
			frame:setValue(mounts.cameraConfig.yAcceleration)
		end
		btn:ddAddButton(info)

		info.customFrame = self.yMinSpeed
		info.OnLoad = function(frame)
			frame:setValue(mounts.cameraConfig.yMinSpeed)
		end
		btn:ddAddButton(info)
	end)

	mssBtn:SetScript("OnClick", function(btn)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		btn:ddToggle(1, nil, btn, 0, 0)
	end)

	-- MODEL SCENE MOUNT HINT
	local msMountHint = self.mountDisplay.info.mountHint
	msMountHint:SetPropagateMouseMotion(true)
	msMountHint:SetScript("OnEnter", function(btn)
		btn.isHover = true
		btn.highlight:Show()
		btn:SetAlpha(1)
		GameTooltip:SetOwner(btn, "ANCHOR_NONE")
		GameTooltip:SetPoint("RIGHT", btn, "LEFT", 14, 0)
		self:setMountTooltip(self.selectedMountID, self.selectedSpellID)
		GameTooltip:Show()
	end)

	msMountHint:SetScript("OnLeave", function(btn)
		btn.isHover = nil
		btn.highlight:Hide()
		btn:SetAlpha(.5)
		GameTooltip:Hide()
	end)

	local function updateMountHint()
		if msMountHint.isHover then
			msMountHint:GetScript("OnEnter")(msMountHint)
		end
	end

	self:on("MOUNT_SELECT", updateMountHint)
	    :on("MOUNT_SUMMONED", updateMountHint)

	-- MODEL SCENE MULTIPLE BUTTON
	lsfdd:SetMixin(self.multipleMountBtn)
	self.multipleMountBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	self.multipleMountBtn:ddSetDisplayMode(addon)
	self.multipleMountBtn:ddHideWhenButtonHidden()
	self.multipleMountBtn:ddSetNoGlobalMouseEvent(true)

	self.multipleMountBtn:ddSetInitFunc(function(btn, level)
		local info = {keepShownOnClick = true}
		local creatureIDs = self:getMountAllCreatureDisplayInfo(self.selectedMountID)
		local func = function(_, creatureID)
			self:updateMountDisplay(true, creatureID)
			btn:ddRefresh(level)
		end
		local checked = function(_, creatureID)
			return self.mountDisplay.lastCreatureID == creatureID
		end

		for i = 1, #creatureIDs do
			local creatureID = creatureIDs[i]
			info.text = MODEL.." "..i
			info.arg1 = creatureID
			info.func = func
			info.checked = checked
			btn:ddAddButton(info, level)
		end
	end)

	self.multipleMountBtn:SetScript("OnClick", function(btn, mouseBtn)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		if mouseBtn == "LeftButton" then
			btn:ddCloseMenus()
			local creatureIDs = self:getMountAllCreatureDisplayInfo(self.selectedMountID)
			for i = 1, #creatureIDs do
				if self.mountDisplay.lastCreatureID == creatureIDs[i] then
					local index = Wrap(i + 1, #creatureIDs)
					self:updateMountDisplay(true, creatureIDs[index])
					break
				end
			end
		else
			btn:ddToggle(1, nil, btn, 30, 30)
		end
	end)

	-- MODEL SCENE CONTROL
	local modelControl = self.modelScene.modelControl
	modelControl.zoomIn.icon:SetTexCoord(.57812500, .82812500, .14843750, .27343750)
	modelControl.zoomOut.icon:SetTexCoord(.29687500, .54687500, .00781250, .13281250)
	modelControl.panButton.icon:SetTexCoord(.29687500, .54687500, .28906250, .41406250)
	modelControl.rotateLeftButton.icon:SetTexCoord(.01562500, .26562500, .28906250, .41406250)
	modelControl.rotateRightButton.icon:SetTexCoord(.57812500, .82812500, .28906250, .41406250)
	modelControl.rotateUpButton.icon:SetTexCoord(.01562500, .26562500, .28906250, .41406250)
	modelControl.rotateUpButton.icon:SetRotation(-math.pi / 1.6, CreateVector2D(.5, .43))
	modelControl.rotateDownButton.icon:SetTexCoord(.57812500, .82812500, .41406250, .28906250)
	modelControl.rotateDownButton.icon:SetRotation(-math.pi / 1.6)

	modelControl.panButton:HookScript("OnMouseDown", function(self)
		self:GetParent():GetParent().isRightButtonDown = true
		MJModelPanningFrame:Show()
	end)
	modelControl.panButton:HookScript("OnMouseUp", function(self)
		self:GetParent():GetParent().isRightButtonDown = false
		MJModelPanningFrame:Hide()
	end)

	local function modelSceneControlOnUpdate(self, elapsed)
		self:GetParent():GetParent().activeCamera:HandleMouseMovement(self.cmd, elapsed * self.delta, self.snapToValue)
	end
	local function modelSceneControlOnMouseDown(self)
		self:SetScript("OnUpdate", modelSceneControlOnUpdate)
	end
	local function modelSceneControlOnMouseUp(self)
		self:SetScript("OnUpdate", nil)
	end

	modelControl.zoomIn:HookScript("OnMouseDown", modelSceneControlOnMouseDown)
	modelControl.zoomIn:HookScript("OnMouseUp", modelSceneControlOnMouseUp)
	modelControl.zoomOut:HookScript("OnMouseDown", modelSceneControlOnMouseDown)
	modelControl.zoomOut:HookScript("OnMouseUp", modelSceneControlOnMouseUp)
	modelControl.rotateLeftButton:HookScript("OnMouseDown", modelSceneControlOnMouseDown)
	modelControl.rotateLeftButton:HookScript("OnMouseUp", modelSceneControlOnMouseUp)
	modelControl.rotateRightButton:HookScript("OnMouseDown", modelSceneControlOnMouseDown)
	modelControl.rotateRightButton:HookScript("OnMouseUp", modelSceneControlOnMouseUp)
	modelControl.rotateUpButton:HookScript("OnMouseDown", modelSceneControlOnMouseDown)
	modelControl.rotateUpButton:HookScript("OnMouseUp", modelSceneControlOnMouseUp)
	modelControl.rotateDownButton:HookScript("OnMouseDown", modelSceneControlOnMouseDown)
	modelControl.rotateDownButton:HookScript("OnMouseUp", modelSceneControlOnMouseUp)

	modelControl.reset:SetScript("OnClick", function(self)
		self:GetParent():GetParent().activeCamera:resetPosition()
	end)

	-- PLAYER SHOW BUTTON
	local playerToggle = self.modelScene.playerToggle

	function playerToggle.updateModels()
		self:updateMountDisplay(true)
		if mounts.config.gridToggle == 3 then
			for i, f in ipairs(self.view:GetFrames()) do
				self:initMountButton(f, f:GetElementData(), true)
			end
		end
	end

	playerToggle:SetChecked(GetCVarBool("mountJournalShowPlayer"))
	SetPortraitTexture(playerToggle.portrait, "player")
	playerToggle:RegisterEvent("PORTRAITS_UPDATED")
	playerToggle:SetScript("OnEvent", function(btn)
		SetPortraitTexture(btn.portrait, "player")
		if btn.portrait:GetTexture() then
			btn:UnregisterEvent("PORTRAITS_UPDATED")
			btn:SetScript("OnEvent", nil)
			btn.updateModels()
		end
	end)
	playerToggle:SetScript("OnClick", function(btn)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		SetCVar("mountJournalShowPlayer", btn:GetChecked() and 1 or 0)
		btn.updateModels()
	end)

	-- SUMMON BUTTON
	self.summonButton:SetScript("OnEvent", function(btn)
		btn:Disable()
	end)
	self.summonButton:RegisterEvent("PLAYER_REGEN_DISABLED")

	self.summonButton:SetScript("OnEnter", function(btn)
		GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
		GameTooltip:SetText(btn:GetText(), HIGHLIGHT_FONT_COLOR:GetRGB())

		local isMount = type(self.selectedMountID) == "number"

		local needsFanFare = isMount and C_MountJournal.NeedsFanfare(self.selectedMountID)
		if needsFanFare then
			GameTooltip_AddNormalLine(GameTooltip, MOUNT_UNWRAP_TOOLTIP, true)
		else
			GameTooltip_AddNormalLine(GameTooltip, MOUNT_SUMMON_TOOLTIP, true)
		end

		if isMount then
			local checkIndoors = true
			local isUsable, errorText = C_MountJournal.GetMountUsabilityByID(self.selectedMountID, checkIndoors)
			if errorText ~= nil then
				GameTooltip_AddErrorLine(GameTooltip, errorText, true)
			end
		end

		GameTooltip:Show()
	end)

	self.summonButton:HookScript("PreClick", function(btn)
		if InCombatLockdown() then return end
		if type(self.selectedMountID) == "number" then
			local spellID = ns.macroFrame.getFormSpellID and ns.macroFrame.getFormSpellID()
			if spellID == 5487 or spellID == 768 or spellID == 114282 or spellID == 210053 then
				btn:SetAttribute("macrotext", "/cancelform")
			else
				btn:SetAttribute("macrotext", nil)
			end
		elseif self.selectedMountID then
			btn:SetAttribute("macrotext", self.selectedMountID.macro)
		end
	end)

	self.summonButton:HookScript("PostClick", function(btn)
		if type(self.selectedMountID) == "number" then
			self:useMount(self.selectedMountID)
		end
	end)

	-- CALENDAR FRAME
	local calendarFrame = journal.bgFrame.calendarFrame
	calendarFrame.calendar = ns.calendar

	function calendarFrame:init(level, value, dd)
		self.level = level
		self.value = value
		self.dd = dd
		local year, monthName = self.calendar:getSelectedDate()
		self.yearText:SetText(year)
		self.monthText:SetText(monthName)
	end

	function calendarFrame:reloadMenu()
		self.dd:ddCloseMenus(self.level)
		local menu = lsfdd:GetMenu(self.level)
		local value = type(self.value) == "function" and self.value() or self.value
		self.dd:ddToggle(self.level, value, menu.anchorFrame)
	end

	calendarFrame.prevMonthButton:SetScript("OnClick", function(btn)
		PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN)
		local parent = btn:GetParent()
		parent.calendar:setPreviousMonth()
		parent:reloadMenu()
	end)
	calendarFrame.nextMonthButton:SetScript("OnClick", function(btn)
		PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN)
		local parent = btn:GetParent()
		parent.calendar:setNextMonth()
		parent:reloadMenu()
	end)

	-- PROFILES
	self:on("UPDATE_PROFILE", function(self, changeProfile)
		self:setEditMountsList()
		self:updateMountsList()
		self:updateMapSettings()
		self.existingLists:refresh()

		if changeProfile then
			self.mountListUpdateAnim:Stop()
			self.mountListUpdateAnim:Play()
		end
	end)

	-- RESIZE BUTTON
	local resize = self.bgFrame.resize
	resize:SetScript("OnDragStart", function(btn)
		if InCombatLockdown() then return end
		local parent = btn:GetParent()
		parent:SetResizeBounds(self:getMinMaxSize())
		parent.isSizing = true
		parent:StartSizing("BOTTOMRIGHT", true)
		btn:SetScript("OnUpdate", function()
			self:setScrollGridMounts(true)
			self:event("JOURNAL_RESIZED")
		end)
	end)
	resize:SetScript("OnDragStop", function(btn)
		if InCombatLockdown() then return end
		btn:SetScript("OnUpdate", nil)
		local parent = btn:GetParent()
		parent:StopMovingOrSizing()
		parent.isSizing = nil
		mounts.config.journalWidth, mounts.config.journalHeight = parent:GetSize()
		self.bgFrame:ClearAllPoints()
		self.bgFrame:SetPoint("TOPLEFT", self.CollectionsJournal, "TOPLEFT", 0, 0)
		self:setScrollGridMounts(true)
		self:event("JOURNAL_RESIZED")
	end)

	-- MOUNT SPECIAL
	local isMounted = util.isMounted()
	self.mountSpecial:SetText("!")
	self.mountSpecial.normal = self.mountSpecial:GetFontString()
	self.mountSpecial.normal:ClearAllPoints()
	self.mountSpecial.normal:SetPoint("CENTER")
	self.mountSpecial:SetEnabled(isMounted)
	self.mountSpecial:SetScript("OnEnter", function(btn)
		GameTooltip:SetOwner(btn, "ANCHOR_TOP")
		GameTooltip_SetTitle(GameTooltip, "/MountSpecial")
		GameTooltip:Show()
	end)
	self.mountSpecial:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	self.mountSpecial:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		util.doEmote("MountSpecial")
	end)

	-- MOUNT SPEED
	self.mountSpeed:SetShown(mounts.config.statCollection and isMounted)

	-- FANFARE
	hooksecurefunc(C_MountJournal, "ClearFanfare", function(mountID)
		self:sortMounts()
		if self.selectedMountID == mountID then
			self:updateMountDisplay()
			if self.modelScene:GetActorByTag("wrapped"):GetAlpha() == 1 then
				self.modelScene:StartUnwrapAnimation()
			end
		end
	end)

	-- SET/UNSET FAVORITE
	self:on("UPDATE_FAVORITES", self.sortMounts)
	hooksecurefunc(C_MountJournal, "SetIsFavorite", function()
		self:sortMounts()
	end)

	-- ON ALERT CLICK
	hooksecurefunc("MountJournal_SelectByMountID", function(mountID)
		if mounts.config.useDefaultJournal then return end
		util.openJournalTab(3)
		self:setSelectedMount(mountID)
	end)

	-- MODULES INIT
	self:event("MODULES_INIT"):off("MODULES_INIT")

	-- INIT
	self.CollectionsJournal.NineSlice:Hide()
	self:RegisterEvent("COMPANION_UPDATE")
	self:RegisterEvent("UI_MODEL_SCENE_INFO_UPDATED")
	self:RegisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")
	self:RegisterEvent("SPELLS_CHANGED")
	self:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "player")
	self:on("MOUNT_SPEED_UPDATE", self.updateSpeed)
	self:on("MOUNTED_UPDATE", self.updateMounted)
	self:on("PET_STATUS_UPDATE", self.updateMountsList)

	self.lastMountListUpdate = 0
	self:updateCollectionTabs(true)
	self:setScrollGridMounts()
	self:setArrowSelectMount(mounts.config.arrowButtonsBrowse)
	self:setMJFiltersBackup()
	self:hideFrames()
	self:setEditMountsList()
	self:updateBtnFilters()
	self:sortMounts()
	self:selectMountByIndex(1)
	if not self.selectedMountID then
		self:updateMountDisplay()
	end
end


journal:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
journal.mjFiltersBackup = {sources = {}, types = {}}
journal.frameState = {}
journal.CollectionsJournal = CollectionsJournal
journal.MountJournal = MountJournal

journal.useMountsJournalButton = CreateFrame("CheckButton", nil, journal.MountJournal, "MJUseMountsJournalButtonTemplate")
journal.useMountsJournalButton:SetPoint("BOTTOMLEFT", journal.CollectionsJournal, "BOTTOMLEFT", 281, 2)
journal.useMountsJournalButton.Text:SetFontObject("GameFontNormal")
journal.useMountsJournalButton.Text:SetText(ns.addon)
journal.useMountsJournalButton:SetChecked(not mounts.config.useDefaultJournal)

journal.useMountsJournalButton:SetScript("OnEnter", function(btn)
	if not btn:IsEnabled() then
		GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
		GameTooltip_SetTitle(GameTooltip, ns.addon)
		GameTooltip_AddErrorLine(GameTooltip, SPELL_FAILED_AFFECTING_COMBAT)
		GameTooltip:Show()
	end
end)

journal.useMountsJournalButton:SetScript("OnEnable", function(btn)
	btn.Text:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
end)

journal.useMountsJournalButton:HookScript("OnClick", function(btn)
	local checked = btn:GetChecked()
	mounts.config.useDefaultJournal = not checked
	if checked then
		if journal.init then
			btn:Disable()
			journal:init()
			C_Timer.After(0, function() btn:Enable() end)
		else
			journal:setMJFiltersBackup()
			journal:hideFrames()
		end
	else
		journal:restoreMJFilters()
		journal:restoreFrames()
	end
end)

journal.useMountsJournalButton:SetScript("OnShow", function(btn)
	if InCombatLockdown() then
		btn:Disable()
	else
		if mounts.config.useDefaultJournal then
			btn:Enable()
		else
			btn:Disable()
			journal:init()
			C_Timer.After(0, function() btn:Enable() end)
		end
	end
	journal:RegisterEvent("PLAYER_REGEN_DISABLED")
	journal:RegisterEvent("PLAYER_REGEN_ENABLED")
end)

journal.useMountsJournalButton:SetScript("OnHide", function()
	journal:UnregisterEvent("PLAYER_REGEN_DISABLED")
	journal:UnregisterEvent("PLAYER_REGEN_ENABLED")
end)


function journal:getMinMaxSize()
	local minWidth, minHeight = self.CollectionsJournal:GetSize()
	local minTabWidth = (self.CollectionsJournal.Tabs[self.CollectionsJournal.numTabs]:GetRight() or 0) - self.CollectionsJournal:GetLeft() + self.bgFrame:GetRight() - self.bgFrame.Tabs[#self.bgFrame.Tabs]:GetLeft() + 20
	local maxWidth = UIParent:GetWidth() - self.bgFrame:GetLeft() - 10
	local maxHeight = self.bgFrame:GetTop() - CollectionsJournalTab1:GetHeight()
	return max(minWidth, minTabWidth), minHeight, maxWidth, maxHeight
end


function journal:setMJFiltersBackup()
	local backup = self.mjFiltersBackup
	if backup.isBackuped then return end
	backup.collected = C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED)
	backup.notCollected = C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED)
	backup.unusable = C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE)
	for i = 1, C_PetJournal.GetNumPetSources() do
		if C_MountJournal.IsValidSourceFilter(i) then
			backup.sources[i] = C_MountJournal.IsSourceChecked(i)
		end
	end
	for i = 1, Enum.MountTypeMeta.NumValues do
		if C_MountJournal.IsValidTypeFilter(i) then
			backup.types[i] = C_MountJournal.IsTypeChecked(i)
		end
	end
	backup.isBackuped = true
	self:RegisterEvent("MOUNT_JOURNAL_SEARCH_UPDATED")
	self:RegisterEvent("PLAYER_LOGOUT")
	self:updateIndexByMountID(true)
end


function journal:restoreMJFilters()
	local backup = self.mjFiltersBackup
	if not backup.isBackuped then return end
	self:UnregisterEvent("MOUNT_JOURNAL_SEARCH_UPDATED")
	self:UnregisterEvent("PLAYER_LOGOUT")
	C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED, backup.collected)
	C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED, backup.notCollected)
	C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE, backup.unusable)
	for i = 1, C_PetJournal.GetNumPetSources() do
		if C_MountJournal.IsValidSourceFilter(i) then
			C_MountJournal.SetSourceFilter(i, backup.sources[i])
		end
	end
	for i = 1, Enum.MountTypeMeta.NumValues do
		if C_MountJournal.IsValidTypeFilter(i) then
			C_MountJournal.SetTypeFilter(i, backup.types[i])
		end
	end
	backup.isBackuped = false
end
journal.PLAYER_LOGOUT = journal.restoreMJFilters


do
	local function SetShown(self, shown)
		journal.frameState[self] = shown
		journal.Hide(self)
	end

	local function Show(self)
		journal.frameState[self] = true
		journal.Hide(self)
	end

	local function Hide(self)
		journal.frameState[self] = false
	end

	function journal:hideFrames()
		for _, frame in ipairs({self.MountJournal:GetChildren()}) do
			if not frame:IsProtected() then
				self.frameState[frame] = frame:IsShown()
				frame:Hide()
				hooksecurefunc(frame, "SetShown", SetShown)
				hooksecurefunc(frame, "Show", Show)
				hooksecurefunc(frame, "Hide", Hide)
			end
		end
	end
end


function journal:restoreFrames()
	for frame, shown in pairs(self.frameState) do
		self.frameState[frame] = nil
		frame.SetShown = nil
		frame.Show = nil
		frame.Hide = nil
		frame:SetShown(shown)
	end
end


function journal:PLAYER_REGEN_DISABLED()
	if self.init then
		self.useMountsJournalButton:Disable()
	else
		self.leftInset:EnableKeyboard(false)
		self.bgFrame.resize:Disable()
		if self.bgFrame.isSizing then
			self.bgFrame.resize:GetScript("OnDragStop")(self.bgFrame.resize)
		end
		self:updateMountsList()
	end
end


function journal:PLAYER_REGEN_ENABLED()
	if self.init then
		if mounts.config.useDefaultJournal then
			self.useMountsJournalButton:Enable()
		else
			self:init()
			C_Timer.After(0, function() self.useMountsJournalButton:Enable() end)
		end
	else
		self.leftInset:EnableKeyboard(true)
		self.bgFrame.resize:Enable()
		self:updateMountsList()
		self:updateMountDisplay()
	end
end


function journal:updateCollectionTabs(force)
	local tab = CollectionsJournalTab1
	if tab:IsProtected() and not force then return end
	local relativeFrame = self.bgFrame:IsShown() and self.bgFrame or CollectionsJournal
	local point, _, rPoint, x, y = tab:GetPoint()
	tab:SetPoint(point, relativeFrame, rPoint, x, y)
end


function journal:updateListAndDisplay()
	self.tags.doNotHideMenu = true
	self:updateScrollMountList()
	self.tags.doNotHideMenu = nil
	self:updateMountDisplay()
end
journal.SPELLS_CHANGED = journal.updateListAndDisplay


function journal:updateMounted(isMounted)
	self:updateListAndDisplay()
	self.mountSpecial:SetEnabled(isMounted)
	self.mountSpeed:SetShown(mounts.config.statCollection and isMounted)
end


function journal:COMPANION_UPDATE(companionType)
	if companionType == "MOUNT"
	and (InCombatLockdown() or C_Secrets.ShouldAurasBeSecret())
	then
		C_Timer.After(0, function() self:updateMounted(util.isMounted()) end)
	end
end


function journal:updateSpeed(...)
	self.mountSpeed:SetText(util.getFormattedSpeed(...))
end


function journal:setMountTooltip(mountID, spellID, showDescription)
	local name, _,_,_,_,_,_,_, faction = util.getMountInfo(mountID)
	local expansion, familyID, _,_, descriptionText, sourceText, _, mountType = util.getMountInfoExtra(mountID)
	GameTooltip:SetText(name, nil, nil, nil, nil, true)

	-- type
	local mType, typeStr = util.mountTypes[mountType]
	if type(mType) == "table" then
		typeStr = L["MOUNT_TYPE_"..mType[1]]
		for i = 2, #mType do
			typeStr = ("%s, %s"):format(typeStr, L["MOUNT_TYPE_"..mType[i]])
		end
	else
		typeStr = L["MOUNT_TYPE_"..mType]
	end
	util.addTooltipDLine(L["types"], typeStr)
	--@do-not-package@
	util.addTooltipDLine("Type", mountType)
	--@end-do-not-package@

	-- family
	local function getPath(FID)
		for name, k in next, ns.familyDB do
			if type(k) == "number" then
				if FID == k then return L[name] end
			else
				for subName, id in next, k do
					if FID == id then return ("%s / %s"):format(L[name], L[subName]) end
				end
			end
		end
	end

	if type(familyID) == "table" then
		for i = 1, #familyID do
			util.addTooltipDLine(i == 1 and L["Family"] or " ", getPath(familyID[i]))
		end
	else
		util.addTooltipDLine(L["Family"], getPath(familyID))
	end

	-- tags
	local mTags = self.tags.mountTags[spellID]
	if mTags then
		util.addTooltipDLine(L["tags"], concat(GetKeysArray(mTags), ", "))
	end

	-- faction
	util.addTooltipDLine(L["factions"], L["MOUNT_FACTION_"..((faction or 2) + 1)])

	-- expanstion
	util.addTooltipDLine(EXPANSION_FILTER_TEXT, _G["EXPANSION_NAME"..(expansion - 1)])

	-- receipt date
	local mountDate = mounts:getMountDate(spellID)
	if mountDate then
		local tDate = date("*t", mountDate)
		util.addTooltipDLine(L["Receipt date"], FormatShortDate(tDate.day, tDate.month, tDate.year))
	end

	-- statistic
	local summons = mounts:getMountSummons(spellID)
	if summons > 0 then util.addTooltipDLine(SUMMONS, summons) end

	local mountTime = mounts:getMountTime(spellID)
	if mountTime > 0 then util.addTooltipDLine(L["Travel time"], util.getTimeBreakDown(mountTime)) end

	local mountDistance = mounts:getMountDistance(spellID)
	if mountDistance > 0 then
		util.addTooltipDLine(L["Travel distance"], util:getFormattedDistance(mountDistance))
		util.addTooltipDLine(L["Avg. speed"], util:getFormattedAvgSpeed(mountDistance, mountTime))
	end

	if showDescription or not mounts.config.mountDescriptionToggle then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(sourceText, 1,1,1, true)
		GameTooltip:AddLine(descriptionText, 1,1,1, true)
	end
end


function journal:getMountFirstCreatureDisplayID(mountID)
	local creatureIDs = C_MountJournal.GetMountAllCreatureDisplayInfoByID(mountID)
	return creatureIDs and creatureIDs[1] and creatureIDs[1].creatureDisplayID or 0
end


function journal:getMountAllCreatureDisplayInfo(mount)
	if type(mount) == "number" then
		local creatureIDs = C_MountJournal.GetMountAllCreatureDisplayInfoByID(mount)
		if creatureIDs and #creatureIDs > 0 then
			local list = {}
			for i = 1, #creatureIDs do
				local creatureID = creatureIDs[i].creatureDisplayID
				if list[creatureID] == nil then
					list[creatureID] = 1
					list[#list + 1] = creatureID
				end
			end
			return list
		end
	else
		return mount.allCreature
	end
end


function journal:setGridToggle(grid)
	if self.altGrid then
		if mounts.config.gridToggle < 3 then
			mounts.config.gridToggle = Wrap(grid, 2)
		else
			mounts.config.altGridToggle = Wrap(grid, 2)
		end
	else
		mounts.config.gridToggle = Wrap(grid, 3)
	end
end


function journal:getGridToggle()
	if self.altGrid and mounts.config.gridToggle == 3 then
		return mounts.config.altGridToggle
	end
	return mounts.config.gridToggle
end


function journal:setScrollGridMounts(force)
	local index = self.view:CalculateDataIndices(self.scrollBox)
	local playerToggle = self.modelScene.playerToggle
	local grid = self:getGridToggle()

	self.filtersPanel:ClearAllPoints()
	if self.navBar:IsShown() then
		self.filtersPanel:SetPoint("TOPLEFT", self.navBar, "BOTTOMLEFT", -1, -1)
	else
		self.filtersPanel:SetPoint("TOPLEFT", 4, -60)
	end
	self.searchBox:ClearAllPoints()
	self.searchBox:SetPoint("TOPRIGHT", -95, -5)
	playerToggle:ClearAllPoints()

	if grid ~= 3 then
		self.inspectFrame:Hide()
		self.filtersToggle:Show()
		self.filtersToggle.setFiltersToggleCheck(mounts.config.filterToggle)
		self.gridModelSettings:Hide()
		playerToggle:SetParent(self.modelScene)
		playerToggle:SetScale(.5)
		playerToggle:SetPoint("LEFT", self.modelScene.modelControl, "RIGHT", 301, 1)
		playerToggle:SetAlpha(0)
		if not self.altGrid then
			self.mountDisplay:Show()
			self.rightInset:Show()
		end
	else
		self.filtersPanel:SetPoint("RIGHT", -4, 0)
		self.searchBox:SetPoint("LEFT", self.gridModelSettings, "RIGHT", 6, 0)
		self.filtersToggle:Hide()
		self.filtersToggle.setFiltersToggleCheck(false)
		self.gridModelSettings:Show()
		playerToggle:SetParent(self.gridModelSettings)
		playerToggle:SetScale(.36)
		playerToggle:SetPoint("RIGHT", -5, -1)
		playerToggle:SetAlpha(1)
		if not self.inspectFrame:IsShown() then
			self.mountDisplay:Hide()
			self.rightInset:Hide()
		end
	end

	if self.curGrid == grid and not force then return end
	self.curGrid = grid
	local template, top, bottom, left, right, hSpacing, vSpacing, extent, panScalar, sizeCalculator

	if grid == 1 then
		top = 1
		left = 41
		if mounts.config.showTypeSelBtn then
			template = "MJMountDefaultListButtonWithTypeBtns"
			right = 25
			extent = 44
		else
			template = "MJMountDefaultListButton"
			extent = 40
		end
		self.gridN = 1
		self.initMountButton = self.defaultInitMountButton
	elseif grid == 2 then
		top = 2
		bottom = 2
		vSpacing = 2
		extent = 40
		if mounts.config.showTypeSelBtn then
			template = "MjGridMountButtonWithTypeBtnsTemplate"
			left = 16
			hSpacing = 39
			self.gridN = 3
		else
			template = "MjGridMountButtonDefTemplate"
			left = 7
			hSpacing = 22
			self.gridN = 4
		end
		self.initMountButton = self.gridInitMountButton
	else
		template = mounts.config.showTypeSelBtn and "MJGridModelSceneWithTypeBtnsTemplate" or "MJGridModelSceneDefTemplate"
		left = 0
		right = 0
		hSpacing = 0
		panScalar = 1
		local scrollWidth = self.scrollBox:GetWidth() - left - right
		self.gridN = mounts.config.gridModelStride
		extent = math.floor((scrollWidth - (self.gridN - 1) * hSpacing) / self.gridN)
		sizeCalculator = function(dataIndex, elementData) return extent, extent end
		self.initMountButton = self.gridModelSceneInit
	end

	self.scrollBox.wheelPanScalar = panScalar or 2
	self.view:SetPadding(top,bottom,left,right,hSpacing,vSpacing)
	self.view:SetElementExtent(extent)
	self.view:SetElementSizeCalculator(sizeCalculator)
	self.view:SetPanExtent(extent)
	self.view:SetStride(self.gridN)
	self.view:SetElementInitializer(template, function(...)
		self:initMountButton(...)
	end)

	if self.dataProvider then
		self:updateFilterNavBar()
		self:updateScrollMountList()
		self.view:Layout()
		self.scrollBox:ScrollToElementDataIndex(index, ScrollBoxConstants.AlignBegin)
	end
end


do
	local function showNext(toggles, index, texture, color)
		local toggle = toggles[index]
		toggle:SetTexture(texture)
		toggle:SetVertexColor(color:GetRGB())
		toggle:Show()
		return index + 1
	end

	local function setColor(self, btn, checked)
		local color = checked and self.colors.gold or self.colors.gray
		btn.icon:SetVertexColor(color:GetRGB())
		btn:SetChecked(checked)
	end

	function journal:updateMountToggleButton(btn, reverse)
		if btn.toggle then
			for i = 1, #btn.toggle do btn.toggle[i]:Hide() end
			if self.list then
				local index = 1
				if reverse then
					if self.list.swimming[btn.spellID] then
						index = showNext(btn.toggle, index, self.tSwimming, self.colors.mount3)
					end
					if self.list.ground[btn.spellID] then
						index = showNext(btn.toggle, index, self.tGround, self.colors.mount2)
					end
					if self.list.fly[btn.spellID] then
						showNext(btn.toggle, index, self.tFly, self.colors.mount1)
					end
				else
					if self.list.fly[btn.spellID] then
						index = showNext(btn.toggle, index, self.tFly, self.colors.mount1)
					end
					if self.list.ground[btn.spellID] then
						index = showNext(btn.toggle, index, self.tGround, self.colors.mount2)
					end
					if self.list.swimming[btn.spellID] then
						index = showNext(btn.toggle, index, self.tSwimming, self.colors.mount3)
					end
					if btn.toggleBG then
						local last = btn.toggle[index - 1]
						if last then
							btn.toggleBG:SetPoint("BOTTOMRIGHT", last, -1, -1)
							btn.toggleBG:Show()
						else
							btn.toggleBG:Hide()
						end
					end
				end
			elseif btn.toggleBG then
				btn.toggleBG:Hide()
			end
		else
			setColor(self, btn.fly, self.list and self.list.fly[btn.spellID])
			setColor(self, btn.ground, self.list and self.list.ground[btn.spellID])
			setColor(self, btn.swimming, self.list and self.list.swimming[btn.spellID])
		end
	end
end


local function getColorWeight(weight)
	if weight > 50 then
		return ("|cff%02xff00%d%%|r"):format((100 - weight) * 5.1, weight)
	else
		return ("|cffff%02x00%d%%|r"):format(weight * 5.1, weight)
	end
end


function journal:defaultInitMountButton(btn, data)
	local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, isFiltered, isCollected = util.getMountInfo(data.mountID)

	local needsFanfare, qualityColor
	if type(data.mountID) == "number" then
		needsFanfare = C_MountJournal.NeedsFanfare(data.mountID)
		qualityColor = util.getRarityColor(data.mountID)
	else
		qualityColor = HIGHLIGHT_FONT_COLOR
	end

	btn.spellID = spellID
	btn.mountID = data.mountID

	btn.dragButton.icon:SetTexture(needsFanfare and COLLECTIONS_FANFARE_ICON or icon)
	btn.dragButton.icon:SetVertexColor(1, 1, 1)
	btn.dragButton.qualityBorder:SetVertexColor(qualityColor:GetRGB())
	btn.dragButton.hidden:SetShown(self:isMountHidden(spellID))
	btn.dragButton.favorite:SetShown(isFavorite)
	btn.dragButton.activeTexture:SetShown(active)

	local mountWeight = self.mountsWeight[spellID]
	if mountWeight then
		btn.dragButton.mountWeight:SetText(getColorWeight(mountWeight))
		btn.dragButton.mountWeight:Show()
		btn.dragButton.mountWeightBG:Show()
	else
		btn.dragButton.mountWeight:Hide()
		btn.dragButton.mountWeightBG:Hide()
	end

	btn.name:SetText(creatureName)
	btn.name:SetTextColor((mounts.config.coloredMountNames and qualityColor or NORMAL_FONT_COLOR):GetRGB())
	btn.new:SetShown(needsFanfare)
	btn.newGlow:SetShown(needsFanfare)
	btn.background:SetVertexColor(1, 1, 1)
	btn.selectedTexture:SetShown(data.mountID == self.selectedMountID)

	if isFactionSpecific then
		btn.factionIcon:SetAtlas(faction == 0 and "MountJournalIcons-Horde" or "MountJournalIcons-Alliance")
		btn.factionIcon:Show()
	else
		btn.factionIcon:Hide()
	end

	if isUsable or needsFanfare then
		btn.dragButton:Enable()
		btn.dragButton.icon:SetDesaturated()
		btn.dragButton.icon:SetAlpha(1)
		btn.name:SetFontObject("GameFontNormal")
	elseif isCollected then
		btn.dragButton:Enable()
		btn.dragButton.icon:SetDesaturated(true)
		-- 150/255, 50/255, 50/255
		btn.dragButton.icon:SetVertexColor(.58823529411765, .19607843137255, .19607843137255)
		btn.dragButton.icon:SetAlpha(.75)
		btn.dragButton.qualityBorder:SetAlpha(.75)
		btn.name:SetFontObject("GameFontNormal")
		btn.background:SetVertexColor(1, 0, 0)
	else
		btn.dragButton:Disable()
		btn.dragButton.icon:SetDesaturated(true)
		btn.dragButton.icon:SetAlpha(.25)
		btn.dragButton.qualityBorder:SetAlpha(.25)
		btn.name:SetFontObject("GameFontDisable")
	end

	self:updateMountToggleButton(btn, true)
end


function journal:gridInitMountButton(btn, data)
	local mountID = data.mountID
	local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, isFiltered, isCollected = util.getMountInfo(mountID)

	local needsFanfare, qualityColor
	if type(mountID) == "number" then
		needsFanfare = C_MountJournal.NeedsFanfare(mountID)
		qualityColor = util.getRarityColor(mountID)
	else
		qualityColor = HIGHLIGHT_FONT_COLOR
	end

	btn.spellID = spellID
	btn.mountID = mountID
	btn.icon:SetTexture(needsFanfare and COLLECTIONS_FANFARE_ICON or icon)
	btn.icon:SetVertexColor(1, 1, 1)
	btn.qualityBorder:SetVertexColor(qualityColor:GetRGB())
	btn.selectedTexture:SetShown(mountID == self.selectedMountID)
	btn.hidden:SetShown(self:isMountHidden(spellID))
	btn.favorite:SetShown(isFavorite)

	local mountWeight = self.mountsWeight[spellID]
	if mountWeight then
		btn.mountWeight:SetText(getColorWeight(mountWeight))
		btn.mountWeight:Show()
		btn.mountWeightBG:Show()
	else
		btn.mountWeight:Hide()
		btn.mountWeightBG:Hide()
	end

	if isUsable or needsFanfare then
		btn.icon:SetDesaturated()
		btn.icon:SetAlpha(1)
	elseif isCollected then
		btn.icon:SetDesaturated(true)
		-- 150/255, 50/255, 50/255
		btn.icon:SetVertexColor(.58823529411765, .19607843137255, .19607843137255)
		btn.icon:SetAlpha(.75)
		btn.qualityBorder:SetAlpha(.75)
	else
		btn.icon:SetDesaturated(true)
		btn.icon:SetAlpha(.35)
		btn.qualityBorder:SetAlpha(.25)
	end

	self:updateMountToggleButton(btn)
end


function journal:gridModelSceneInit(btn, data, force)
	local mountID = data.mountID
	local oldMountID = btn.mountID
	local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, isFiltered, isCollected = util.getMountInfo(mountID)
	btn.spellID = spellID
	btn.mountID = mountID

	local needsFanfare, qualityColor
	if type(mountID) == "number" then
		needsFanfare = C_MountJournal.NeedsFanfare(mountID)
		qualityColor = util.getRarityColor(mountID)
	else
		qualityColor = HIGHLIGHT_FONT_COLOR
	end

	local drag = btn.dragButton
	drag.icon:SetTexture(needsFanfare and COLLECTIONS_FANFARE_ICON or icon)
	drag.icon:SetVertexColor(1, 1, 1)
	drag.qualityBorder:SetVertexColor(qualityColor:GetRGB())
	drag.selectedTexture:SetShown(active)
	drag.hidden:SetShown(self:isMountHidden(spellID))
	drag.favorite:SetShown(isFavorite)

	local mountWeight = self.mountsWeight[spellID]
	if mountWeight then
		drag.mountWeight:SetText(getColorWeight(mountWeight))
		drag.mountWeight:Show()
		drag.mountWeightBG:Show()
	else
		drag.mountWeight:Hide()
		drag.mountWeightBG:Hide()
	end

	if isFactionSpecific then
		btn.factionIcon:SetAtlas(faction == 0 and "MountJournalIcons-Horde" or "MountJournalIcons-Alliance")
		btn.factionIcon:Show()
	else
		btn.factionIcon:Hide()
	end

	if isUsable or needsFanfare then
		drag.icon:SetDesaturated()
		drag.icon:SetAlpha(1)
	elseif isCollected then
		drag.icon:SetDesaturated(true)
		-- 150/255, 50/255, 50/255
		drag.icon:SetVertexColor(.58823529411765, .19607843137255, .19607843137255)
		drag.icon:SetAlpha(.75)
		drag.qualityBorder:SetAlpha(.75)
	else
		drag.icon:SetDesaturated(true)
		drag.icon:SetAlpha(.35)
		drag.qualityBorder:SetAlpha(.25)
	end

	btn.name:SetText(creatureName)
	btn.name:SetTextColor((mounts.config.coloredMountNames and qualityColor or NORMAL_FONT_COLOR):GetRGB())

	btn.selected = mountID == self.selectedMountID
	if btn.selected then
		btn:SetBackdropBorderColor(.8, .6, 0)
	else
		btn:SetBackdropBorderColor(.3, .3, .3)
	end

	btn.petSelectionBtn:mountSelect()
	self:updateMountToggleButton(btn)

	if oldMountID == mountID and not force then return end

	local _,_, rarity, creatureID, descriptionText, sourceText, isSelfMount, mountType, modelSceneID, animID, spellVisualKitID, disablePlayerMountPreview = util.getMountInfoExtra(mountID)

	if rarity then
		btn.rarity:SetText(rarity.."%")
		btn.rarity:Show()
	else
		btn.rarity:Hide()
	end

	if not creatureID then
		creatureID = self:getMountFirstCreatureDisplayID(mountID)
	end

	btn.mountType = mountType
	btn.isSelfMount = isSelfMount

	btn.loading:Show()
	btn.modelScene:TransitionToModelSceneID(modelSceneID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_DISCARD, true)
	btn.modelScene:PrepareForFanfare(needsFanfare)
	self:setMountToModelScene(btn.modelScene, creatureID, isSelfMount, animID, disablePlayerMountPreview, spellVisualKitID)
end


function journal:setArrowSelectMount(enabled)
	if not self.leftInset then return end
	if enabled then
		local function updateIndex(index, delta)
			index = index + delta
			if index < 1 then
				index = self.shownNumMouns + index - math.fmod(self.shownNumMouns, delta)
				if self.shownNumMouns - index > -delta - 1 then index = index - delta end
			elseif index > self.shownNumMouns then
				index = index - self.shownNumMouns + math.fmod(self.shownNumMouns, delta)
				if index > delta then index = index - delta end
			end
			return index
		end

		local time, pressed, delta, index
		local onUpdate = function(f, elapsed)
			time = time - elapsed
			if time <= 0 then
				time = .1
				index = updateIndex(index, delta)
				self:selectMountByIndex(index)
			end
		end

		self.leftInset:SetScript("OnKeyDown", function(f, key)
			if key == "UP" or key == "DOWN" or key == "LEFT" or key == "RIGHT" then
				f:SetPropagateKeyboardInput(false)

				delta = (key == "UP" or key == "LEFT") and -1 or 1
				if key == "UP" or key == "DOWN" then
					delta = delta * self.gridN
				end

				index = nil
				if self.selectedMountID then
					index = self:getMountDataByMountID(self.selectedMountID)
					if index then index = updateIndex(index, delta) end
				end

				if not index then
					index = delta > 0 and 1 or self.shownNumMouns
				end
				self:selectMountByIndex(index)

				pressed = key
				time = .5
				f:SetScript("OnUpdate", onUpdate)
			else
				f:SetPropagateKeyboardInput(true)
			end
		end)

		self.leftInset:SetScript("OnKeyUp", function(f, key)
			if pressed == key then
				f:SetScript("OnUpdate", nil)
			end
		end)

		self.leftInset:SetScript("OnHide", function(f)
			f:SetScript("OnUpdate", nil)
		end)
	else
		self.leftInset:SetScript("OnKeyDown", nil)
		self.leftInset:SetScript("OnKeyUp", nil)
		self.leftInset:SetScript("OnHide", nil)
		self.leftInset:SetScript("OnUpdate", nil)
	end
end


function journal:ACHIEVEMENT_EARNED()
	self.achiev.text:SetText(GetCategoryAchievementPoints(MOUNT_ACHIEVEMENT_CATEGORY, true))
end


function journal:setCountMounts()
	if mounts.filters.hideOnChar then
		self.mountCount.count:SetText(self.mountCount.count.numWithHidden)
		self.mountCount.collected:SetText(self.mountCount.collected.numWithHidden)
	else
		self.mountCount.count:SetText(self.mountCount.count.num)
		self.mountCount.collected:SetText(self.mountCount.collected.num)
	end
end


function journal:updateCountMounts()
	local count, countWithHidden, collected, collectedWithHidden = 0, 0, 0, 0
	for i = 1, #self.mountIDs do
		local mountID = self.mountIDs[i]
		if type(mountID) == "number" then
			local _,_,_,_,_,_,_,_,_, hideOnChar, isCollected = C_MountJournal.GetMountInfoByID(mountID)
			if not hideOnChar then
				count = count + 1
				if isCollected then
					collected = collected + 1
				end
			end
			if isCollected then
				collectedWithHidden = collectedWithHidden + 1
			end
			countWithHidden = countWithHidden + 1
		end
	end
	self.mountCount.count.num = count
	self.mountCount.count.numWithHidden = countWithHidden
	self.mountCount.collected.num = collected
	self.mountCount.collected.numWithHidden = collectedWithHidden
	self:setCountMounts()
end


function journal:getMountIndexByMountID(mountID)
	local index = self.indexByMountID[mountID]
	if not index or mountID ~= C_MountJournal.GetDisplayedMountID(index) then
		self:updateIndexByMountID(true)
		index = self.indexByMountID[mountID]
	end
	return index
end


function journal:isCanFavorite(mountID)
	if type(mountID) == "table" then return true end
	local index = self:getMountIndexByMountID(mountID)
	if index then
		local isFavorite, canFavorite = C_MountJournal.GetIsFavorite(index)
		return canFavorite
	end
	return false
end


function journal:setIsFavorite(mountID, enabled)
	if type(mountID) == "table" then
		mountID:setIsFavorite(enabled)
	else
		local index = self:getMountIndexByMountID(mountID)
		if index then C_MountJournal.SetIsFavorite(index, enabled) end
	end
end


function journal:updateIndexByMountID(force)
	if not self.mjFiltersBackup.isBackuped then return end
	if C_MountJournal.GetNumDisplayedMounts() ~= self.mountCount.count.num or force then
		self:UnregisterEvent("MOUNT_JOURNAL_SEARCH_UPDATED")
		C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED, true)
		C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED, true)
		C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE, true)
		C_MountJournal.SetAllTypeFilters(true)
		C_MountJournal.SetAllSourceFilters(true)
		C_MountJournal.SetSearch("")
		self:RegisterEvent("MOUNT_JOURNAL_SEARCH_UPDATED")
	end

	wipe(self.indexByMountID)
	for i = 1, C_MountJournal.GetNumDisplayedMounts() do
		local mountID = C_MountJournal.GetDisplayedMountID(i)
		self.indexByMountID[mountID] = i
	end
end
journal.MOUNT_JOURNAL_SEARCH_UPDATED = journal.updateIndexByMountID


function journal:COMPANION_LEARNED()
	self:updateCountMounts()
	self:updateIndexByMountID(true)
	self:sortMounts()
end
journal.COMPANION_UNLEARNED = journal.COMPANION_LEARNED


-- isUsable FLAG CHANGED
function journal:MOUNT_JOURNAL_USABILITY_CHANGED()
	self:updateMountsList()
	self:updateMountDisplay()
end


-- to shapeshift worgen and dracthyr or change clothes
function journal:UNIT_PORTRAIT_UPDATE()
	self:updateMountDisplay(true)
end


function journal:mountToggle(mountType, spellID, mountID, list, zoneMounts)
	if not list then
		list = self:createMountList(self.listMapID, zoneMounts)
	end

	local tList = list[mountType]
	tList[spellID] = not tList[spellID] or nil
	self:getRemoveMountList(self.listMapID, zoneMounts)

	local btn = self:getMountButtonByMountID(mountID)
	if btn then
		self:initMountButton(btn, btn:GetElementData())
		btn:Hide()
		btn:Show() -- motion trigger
	end

	-- mounts:setMountsList()
	self.existingLists:refresh()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end


do
	local mapLangTypes = {
		[1] = WORLD,
		[2] = CONTINENT,
		[3] = ZONE,
		[4] = INSTANCE,
	}
	function journal:listFromMapClick(btn)
		wipe(btn.maps)
		local assocMaps = {}
		for mapID, mapConfig in pairs(self.zoneMounts) do
			if not mapConfig.listFromID
			and mapID ~= self.navBar.mapID
			and (next(mapConfig.fly) or next(mapConfig.ground) or next(mapConfig.swimming)) then
				local mapInfo = util.getMapFullNameInfo(mapID)
				local mapLangType = mapLangTypes[mapInfo.mapType]
				if not mapLangType then
					mapInfo.mapType = 5
					mapLangType = OTHER
				end

				if not assocMaps[mapInfo.mapType] then
					assocMaps[mapInfo.mapType] = {
						name = mapLangType,
						list = {},
					}
					tinsert(btn.maps, assocMaps[mapInfo.mapType])
				end

				tinsert(assocMaps[mapInfo.mapType].list, {name = mapInfo.name, mapID = mapID})
			end
		end

		local function sortFunc(a, b) return a.name < b.name end
		sort(btn.maps, sortFunc)
		for _, mapInfo in ipairs(btn.maps) do
			sort(mapInfo.list, sortFunc)
		end

		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		btn:ddToggle(1, btn.maps, btn, 121, 17)
	end
end


do
	local function setListFrom(_, mapID)
		if journal.navBar.mapID == mapID then return end
		if not journal.currentList then
			journal:createMountList(journal.navBar.mapID)
		end
		journal.currentList.listFromID = mapID
		journal:setEditMountsList()
		journal:updateMountsList()
		journal:updateMapSettings()
		-- mounts:setMountsList()
		journal.existingLists:refresh()

		journal.mountListUpdateAnim:Stop()
		journal.mountListUpdateAnim:Play()
	end


	function journal:listFromMapInit(btn, level, value)
		local info = {}
		info.notCheckable = true

		if next(value) == nil then
			info.disabled = true
			info.text = EMPTY
			btn:ddAddButton(info, level)
		elseif level == 2 then
			info.list = {}
			for i, mapInfo in ipairs(value) do
				info.list[i] = {
					notCheckable = true,
					text = mapInfo.name,
					arg1 = mapInfo.mapID,
					func = setListFrom,
				}
			end
			btn:ddAddButton(info, level)
		else
			info.keepShownOnClick = true
			info.hasArrow = true
			for _, mapInfo in ipairs(value) do
				info.text = mapInfo.name
				info.value = mapInfo.list
				btn:ddAddButton(info, level)
			end

			info.keepShownOnClick = nil
			info.hasArrow = nil
			info.text = WORLD
			info.arg1 = self.navBar.defMapID
			info.func = setListFrom
			btn:ddAddButton(info, level)
		end
	end
end


function journal:updateMapSettings()
	local mapSettings = self.mapSettings
	if not mapSettings:IsShown() then return end
	local flags = self.currentList and self.currentList.flags

	mapSettings.Flags:SetChecked(flags and flags.enableFlags)
	mapSettings.Ground:SetChecked(flags and flags.groundOnly)
	mapSettings.WaterWalk:SetChecked(flags and flags.waterWalkOnly)
	mapSettings.HerbGathering:SetChecked(flags and flags.herbGathering)

	local optionsEnable = self.navBar.mapID ~= self.navBar.defMapID
	mapSettings.Flags:SetEnabled(optionsEnable)
	mapSettings.listFromMap:SetEnabled(optionsEnable)

	local relationText = mapSettings.relationMap.text
	local relationClear = mapSettings.relationClear
	if self.currentList and self.currentList.listFromID then
		relationText:SetText(self.currentList.listFromID == self.navBar.defMapID and WORLD or util.getMapFullNameInfo(self.currentList.listFromID).name)
		relationText:SetTextColor(self.colors.gold:GetRGB())
		relationClear:Show()
	else
		relationText:SetText(L["No relation"])
		relationText:SetTextColor(self.colors.gray:GetRGB())
		relationClear:Hide()
	end
end


function journal:setMountToModelScene(modelScene, creatureID, isSelfMount, animID, disablePlayerMountPreview, spellVisualKitID)
	local mountActor = modelScene:GetActorByTag("unwrapped")
	if mountActor then
		if creatureID == "player" then
			modelScene:GetActorByTag("player-rider"):ClearModel()
			mountActor:SetAnimationBlendOperation(Enum.ModelBlendOperation.None)
			mountActor:SetAnimation(618)
			local sheathWeapons = true
			local autoDress = true
			local hideWeapons = false
			local usePlayerNativeForm = true
			if not mountActor:SetModelByUnit("player", sheathWeapons, autoDress, hideWeapons, usePlayerNativeForm) then
				mountActor:ClearModel()
			end
		else
			-- mount self idle animation
			if isSelfMount then
				mountActor:SetAnimationBlendOperation(Enum.ModelBlendOperation.None)
				mountActor:SetAnimation(618)
			else
				mountActor:SetAnimationBlendOperation(Enum.ModelBlendOperation.Anim)
				mountActor:SetAnimation(0)
			end
			mountActor:SetModelByCreatureDisplayID(creatureID, true)
			modelScene:AttachPlayerToMount(mountActor, animID, isSelfMount, disablePlayerMountPreview or not GetCVarBool("mountJournalShowPlayer"), spellVisualKitID, PlayerUtil.ShouldUseNativeFormInModelScene())
		end
	end
end


function journal:updateMountDisplay(forceSceneChange, creatureID)
	local info = self.mountDisplay.info
	if self.selectedMountID then
		local creatureName, spellID, icon, active, isUsable = util.getMountInfo(self.selectedMountID)
		local isMount = type(self.selectedMountID) == "number"
		local needsFanfare = isMount and C_MountJournal.NeedsFanfare(self.selectedMountID)

		if self.mountDisplay.lastMountID ~= self.selectedMountID or forceSceneChange or MountJournal_GetPendingMountChanges() then
			local _,_, rarity, creatureDisplayID, descriptionText, sourceText, isSelfMount, mountType, modelSceneID, animID, spellVisualKitID, disablePlayerMountPreview = util.getMountInfoExtra(self.selectedMountID)
			if not creatureID then
				if self.mountDisplay.lastMountID == self.selectedMountID then
					creatureID = self.mountDisplay.lastCreatureID
				else
					if not creatureDisplayID then
						creatureDisplayID = self:getMountFirstCreatureDisplayID(self.selectedMountID)
					end
					creatureID = creatureDisplayID
				end
			end
			self.mountDisplay.lastMountID = self.selectedMountID
			self.mountDisplay.lastCreatureID = creatureID

			if rarity then
				info.rarityValue:SetText(rarity.."%")
				info.rarityValue:Show()
			else
				info.rarityValue:Hide()
			end

			local lang = mounts.config.wowheadLinkLang
			local link = "wowhead.com"..(lang == "en" and "" or "/"..lang)
			if isMount then
				link = link.."/mount/"..self.selectedMountID
			elseif self.selectedMountID.itemID then
				link = link.."/item="..self.selectedMountID.itemID
			else
				link = link.."/spell="..self.selectedSpellID
			end

			info.link:SetShown(mounts.config.showWowheadLink)
			info.linkLang:SetShown(mounts.config.showWowheadLink)
			info.link:SetText(link)
			info.name:SetText(creatureName)
			info.source:SetText(sourceText)
			info.lore:SetText(descriptionText)
			self.multipleMountBtn:SetShown(self.mountsWithMultipleModels[self.selectedMountID])

			self:event("MOUNT_MODEL_UPDATE", mountType, isSelfMount)

			self.mountDisplay.loading:Show()
			self.modelScene:TransitionToModelSceneID(modelSceneID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_MAINTAIN, forceSceneChange)
			self.modelScene:PrepareForFanfare(needsFanfare)
			self:setMountToModelScene(self.modelScene, creatureID, isSelfMount, animID, disablePlayerMountPreview, spellVisualKitID)
		end

		if needsFanfare then
			info.icon:SetTexture(COLLECTIONS_FANFARE_ICON)
			info.new:Show()
			info.newGlow:Show()
		else
			info.icon:SetTexture(icon)
			info.new:Hide()
			info.newGlow:Hide()
		end

		info:Show()
		self.modelScene:Show()
		self.mountDisplay.yesMountsTex:Show()
		self.mountDisplay.noMountsTex:Hide()
		self.mountDisplay.noMounts:Hide()

		if needsFanfare then
			self.summonButton:SetText(UNWRAP)
			if not InCombatLockdown() then self.summonButton:Enable() end
		elseif active then
			self.summonButton:SetText(BINDING_NAME_DISMOUNT)
			if not InCombatLockdown() then self.summonButton:SetEnabled(isUsable) end
		else
			self.summonButton:SetText(MOUNT)
			if not InCombatLockdown() then self.summonButton:SetEnabled(isUsable) end
		end
	else
		info:Hide()
		self.modelScene:Hide()
		self.mountDisplay.yesMountsTex:Hide()
		self.mountDisplay.noMountsTex:Show()
		self.mountDisplay.noMounts:Show()
		if not InCombatLockdown() then self.summonButton:Disable() end
	end
end


function journal:UI_MODEL_SCENE_INFO_UPDATED()
	if self.bgFrame:IsShown() then self:updateMountDisplay(true) end
end


function journal:useMount(mountID)
	local _,_,_, active = C_MountJournal.GetMountInfoByID(mountID)
	if active then
		C_MountJournal.Dismiss()
	elseif C_MountJournal.NeedsFanfare(mountID) then
		if self:getGridToggle() == 3 then
			local btn = self:getMountButtonByMountID(mountID)
			if btn then btn.modelScene:StartUnwrapAnimation() end
		end
		self.modelScene:StartUnwrapAnimation(function()
			C_MountJournal.ClearFanfare(mountID)
			local index = self:getMountDataByMountID(mountID)
			if index then self.scrollBox:ScrollToElementDataIndex(index, ScrollBoxConstants.AlignBegin) end
		end)
	else
		C_MountJournal.SummonByID(mountID)
	end
end


function journal:getMountDataByMountID(mountID)
	return self.dataProvider:FindByPredicate(function(data)
		return data.mountID == mountID
	end)
end


function journal:getMountDataByMountIndex(index)
	return self.dataProvider:Find(index)
end


function journal:getMountButtonByMountID(mountID)
	return self.view:FindFrameByPredicate(function(btn, data)
		return data.mountID == mountID
	end)
end


function journal:setSelectedMount(mountID, spellID, index)
	local scrollTo = not spellID
	if not spellID then
		local _
		_, spellID = util.getMountInfo(mountID)
	end
	local oldSelectedID = self.selectedMountID
	self.selectedMountID = mountID
	self.selectedSpellID = spellID
	self:updateMountDisplay()

	if oldSelectedID ~= mountID then
		local btn = self:getMountButtonByMountID(oldSelectedID)
		if btn then
			self:initMountButton(btn, btn:GetElementData())
		end
	end

	local btn = self:getMountButtonByMountID(mountID)
	if btn then
		self:initMountButton(btn, btn:GetElementData())
	end

	if scrollTo then
		if not index then
			index = self:getMountDataByMountID(mountID)
		end

		if index then
			local scrollOffset = self.scrollBox:GetDerivedScrollOffset()
			local indexOffset = self.scrollBox:GetExtentUntil(index)

			if indexOffset < scrollOffset then
				self.scrollBox:ScrollToElementDataIndex(index, ScrollBoxConstants.AlignBegin)
			elseif indexOffset + self.scrollBox:GetElementExtent(index) > scrollOffset + self.scrollBox:GetVisibleExtent() then
				self.scrollBox:ScrollToElementDataIndex(index, ScrollBoxConstants.AlignEnd)
			end
		end
	end

	self:event("MOUNT_SELECT")
end


function journal:selectMountByIndex(index)
	local data = self:getMountDataByMountIndex(index)
	if data then self:setSelectedMount(data.mountID, nil, index) end
end


function journal:filterDropDown_Initialize(btn, level, value)
	if level == 1 then
		self.filters.main(btn, level)
	elseif self.filters[value] then
		self.filters[value](btn, level)
	else
		self.filters[value[1]](btn, level, value[2])
	end
end
