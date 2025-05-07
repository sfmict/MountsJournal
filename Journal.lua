local addon, ns = ...
local L, util, mounts = ns.L, ns.util, ns.mounts
local newMounts, mountsDB, specificDB = ns.newMounts, ns.mountsDB, ns.specificDB
local C_MountJournal, C_PetJournal, wipe, tinsert, next, pairs, ipairs, select, type, sort, math, InCombatLockdown = C_MountJournal, C_PetJournal, wipe, tinsert, next, pairs, ipairs, select, type, sort, math, InCombatLockdown
local journal = CreateFrame("FRAME", "MountsJournalFrame")
ns.journal = journal
journal.mountTypes = util.mountTypes
util.setEventsMixin(journal)


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


local metaMounts = {__index = {[0] = 0}}
journal.indexByMountID = setmetatable({}, metaMounts)


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
		local allCreatureDisplays = C_MountJournal.GetMountAllCreatureDisplayInfoByID(mountID)
		if allCreatureDisplays and #allCreatureDisplays > 1 then
			self.mountsWithMultipleModels[mountID] = true
		end
	end

	-- ADDITIONAL MOUNTS
	for spellID, mount in next, ns.additionalMounts do
		if mount.allCreature then self.mountsWithMultipleModels[mount] = true end
		self.mountIDs[#self.mountIDs + 1] = mount
	end

	-- BACKGROUND FRAME
	self.bgFrame = CreateFrame("FRAME", "MountsJournalBackground", self.CollectionsJournal, "MJMountJournalFrameTemplate")
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
		self.leftInset:EnableKeyboard(not InCombatLockdown())
		local by = mounts.filters.sorting.by
		if by == "summons" or by == "time" or by == "distance" then
			self:sortMounts()
		else
			self:updateMountsList()
		end
		self:updateMountDisplay(true)
		local isMounted = not not util.getUnitMount("player")
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
	self.leftInset = self.bgFrame.leftInset
	self.mountDisplay = self.bgFrame.mountDisplay
	self.modelScene = self.mountDisplay.modelScene
	self.multipleMountBtn = self.modelScene.multipleMountBtn
	self.mountListUpdateAnim = self.leftInset.updateAnimFrame.anim
	self.scrollBox = self.leftInset.scrollBox
	self.summonButton = self.bgFrame.summonButton
	self.percentSlider = self.bgFrame.percentSlider
	self.mountSpecial = self.bgFrame.mountSpecial
	self.mountSpeed = self.bgFrame.rightInset.mountSpeed

	-- USE MountsJournal BUTTON
	self.useMountsJournalButton:SetParent(self.CollectionsJournal)
	self.useMountsJournalButton:SetFrameLevel(self.bgFrame:GetFrameLevel() + 10)
	self.useMountsJournalButton:SetScript("OnShow", nil)
	self.useMountsJournalButton:SetScript("OnHide", nil)
	self.useMountsJournalButton:SetPoint("BOTTOMLEFT", self.bgFrame, "BOTTOMLEFT", 281, 2)

	-- SECURE FRAMES
	local sMountJournal = CreateFrame("FRAME", nil, self.MountJournal, "SecureHandlerShowHideTemplate")
	self._s = sMountJournal
	local randomButton = self.MountJournal.SummonRandomFavoriteButton or self.MountJournal.SummonRandomFavoriteSpellFrame
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

		if tab == 2 then
			self.filtersPanel:SetPoint("TOPLEFT", self.navBar, "BOTTOMLEFT", -1, -1)
		else
			self.filtersPanel:SetPoint("TOPLEFT", 4, -60)
		end

		self.bgFrame.settingsBackground:SetShown(tab == 1)
		self.achiev:SetShown(tab ~= 1)
		self.bgFrame.targetMount:SetShown(tab ~= 1)
		self.bgFrame.OpenDynamicFlightSkillTreeButton:SetShown(tab ~= 1 and DragonridingUtil.IsDragonridingUnlocked())
		self.navBar:SetShown(tab == 2)
		self.filtersPanel:SetShown(tab ~= 1)
		self.leftInset:SetShown(tab ~= 1)
		self.bgFrame.rightInset:SetShown(tab ~= 1)
		self.mountDisplay:SetShown(tab == 3)
		self.worldMap:SetShown(tab == 2)
		self.mapSettings:SetShown(tab == 2)
		self.bgFrame.profilesMenu:SetShown(tab ~= 1)
		self.mountSpecial:SetShown(tab ~= 1)
		self.bgFrame.summonPanelSettings:SetShown(tab ~= 1 and self.summonPanel:IsShown())
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
	local minWidth, minHeight = self.CollectionsJournal:GetSize()
	local maxWidth = UIParent:GetWidth() - self.bgFrame:GetLeft() * 2
	local maxHeight = self.bgFrame:GetTop() - CollectionsJournalTab1:GetHeight()
	self.minTabWidth = (self.CollectionsJournal.Tabs[self.CollectionsJournal.numTabs]:GetRight() or 0) - self.CollectionsJournal:GetLeft() + self.bgFrame:GetRight() - self.bgFrame.Tabs[#self.bgFrame.Tabs]:GetLeft() + 20
	local width = Clamp(mounts.config.journalWidth or minWidth, max(minWidth, self.minTabWidth), maxWidth)
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
	local summon1 = self.bgFrame.summon1
	summon1.id = 1
	summon1.icon:SetTexture(mounts.config.summon1Icon)
	summon1:SetAttribute("clickbutton", _G[util.secureButtonNameMount])
	summon1:SetScript("OnDragStart", function()
		self.summonPanel:startDrag()
	-- 	if not GetMacroInfo(config.macroName) then
	-- 		config:createMacro(config.macroName, config.secureButtonNameMount, 413588)
	-- 	end
	-- 	PickupMacro(config.macroName)
	end)
	summon1:SetScript("OnDragStop", function()
		self.summonPanel:stopDrag()
	end)
	summon1:SetScript("OnEnter", function(btn)
		GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
		GameTooltip_SetTitle(GameTooltip, ("%s \"%s %d\""):format(addon, SUMMONS, btn.id))
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

	local summon2 = self.bgFrame.summon2
	summon2.id = 2
	summon2.icon:SetTexture(mounts.config.summon2Icon)
	summon2:SetAttribute("clickbutton", _G[util.secureButtonNameSecondMount])
	summon2:SetScript("OnDragStart", function()
		self.summonPanel:startDrag()
	-- 	if InCombatLockdown() then return end
	-- 	if not GetMacroInfo(config.secondMacroName) then
	-- 		config:createMacro(config.secondMacroName, config.secureButtonNameSecondMount, 631718)
	-- 	end
	-- 	PickupMacro(config.secondMacroName)
	end)
	summon2:SetScript("OnDragStop", function()
		self.summonPanel:stopDrag()
	end)
	summon2:SetScript("OnEnter", summon1:GetScript("OnEnter"))

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

	-- SCROLL FRAME
	self.view = CreateScrollBoxListLinearView()
	self:setScrollGridMounts(mounts.config.gridToggle)
	ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.leftInset.scrollBar, self.view)

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

	self.filtersToggle.setFiltersToggleCheck = function()
		if mounts.config.filterToggle then
			self.filtersPanel:SetHeight(82)
			self.filtersBar:Show()
		else
			self.filtersPanel:SetHeight(29)
			self.filtersBar:Hide()
		end
	end
	self.filtersToggle.setFiltersToggleCheck()

	self.filtersToggle:HookScript("OnClick", function(btn)
		mounts.config.filterToggle = btn:GetChecked()
		btn.setFiltersToggleCheck()
	end)

	-- GRID TOGGLE BUTTON
	self.gridToggleButton:SetChecked(mounts.config.gridToggle)

	function self.gridToggleButton:setCoordIcon()
		if self:GetChecked() then
			self.icon:SetTexCoord(0, .625, 0, .25)
		else
			self.icon:SetTexCoord(0, .625, .28125, .5325)
		end
	end
	self.gridToggleButton:setCoordIcon()

	self.gridToggleButton:SetScript("OnClick", function(btn)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		local checked = btn:GetChecked()
		mounts.config.gridToggle = checked
		btn:setCoordIcon()
		self:setScrollGridMounts(checked)
	end)

	-- MODELSCENE
	self.modelScene:HookScript("OnEnter", function(modelScene)
		modelScene:GetParent():SetScript("OnUpdate", nil)
		modelScene.multipleMountBtn:SetAlpha(.5)
		modelScene.modelControl:SetAlpha(.5)
		modelScene.animationsCombobox:SetAlpha(.5)
		modelScene.playerToggle:SetAlpha(.5)
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
			modelScene.playerToggle:SetAlpha(0)
		else
			modelScene.multipleMountBtn:SetAlpha(alpha)
			modelScene.modelControl:SetAlpha(alpha)
			modelScene.animationsCombobox:SetAlpha(alpha)
			modelScene.playerToggle:SetAlpha(alpha)
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

		local function langSelect(btn)
			mounts.config.wowheadLinkLang = btn.value
			langButton:SetText(btn.value)
			self:updateMountDisplay(true)
		end

		for i, lang in ipairs({"de", "en", "es", "mx", "fr", "it", "pt", "ru", "ko", "cn", "tw"}) do
			info.value = lang
			info.text = langs[lang]
			info.checked = lang == mounts.config.wowheadLinkLang
			info.func = langSelect
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
	local mountListUpdate = function()
		self.tags.doNotHideMenu = true
		self:updateMountsList()
		self.tags.doNotHideMenu = nil
	end
	self.percentSlider:setOnChanged(function(frame, value)
		frame.setFunc(value)
		frame.slider.isModified = true
	end)
	self.percentSlider:SetScript("OnEnter", function(frame)
		self.filtersButton:ddCloseMenus(frame.level)
	end)
	self.percentSlider.slider:HookScript("OnEnter", weightControl_OnEnter)
	self.percentSlider.slider:HookScript("OnMouseUp", function(slider)
		mountListUpdate()
		slider.isModified = nil
	end)
	self.percentSlider.slider:HookScript("OnHide", function(slider)
		if slider.isModified then
			self:updateMountsList()
			slider.isModified = nil
		end
	end)
	self.percentSlider.slider:HookScript("OnMouseWheel", mountListUpdate)
	self.percentSlider.edit:HookScript("OnEnter", weightControl_OnEnter)
	self.percentSlider.edit:HookScript("OnEnterPressed", mountListUpdate)
	self.percentSlider.edit:HookScript("OnMouseWheel", mountListUpdate)

	-- FILTERS BUTTONS
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

	local function CreateButtonFilter(i, parent, width, height, texture)
		local btn = CreateFrame("CheckButton", nil, parent, width == height and "MJFilterButtonSquareTemplate" or "MJFilterButtonRectangleTemplate")
		btn.id = texture.id
		btn.tooltip = texture.tooltip
		btn:SetSize(width, height)
		if i == 1 then
			btn:SetPoint("LEFT", 5, 0)
			parent.childs = {}
		else
			btn:SetPoint("LEFT", parent.childs[#parent.childs], "RIGHT")
		end
		parent.childs[#parent.childs + 1] = btn

		btn.icon:SetTexture(texture.path)
		btn.icon:SetSize(texture.width, texture.height)
		if texture.texCoord then btn.icon:SetTexCoord(unpack(texture.texCoord)) end

		btn:SetScript("OnClick", filterClick)
		btn:SetScript("OnEnter", filterEnter)
		btn:SetScript("OnLeave", filterLeave)
	end

	-- FILTERS TYPES BUTTONS
	local typesTextures = {
		{id = 1, path = self.tFly, width = 32, height = 16, tooltip = L["MOUNT_TYPE_1"]},
		{id = 2, path = self.tGround, width = 32, height = 16, tooltip = L["MOUNT_TYPE_2"]},
		{id = 3, path = self.tSwimming, width = 32, height = 16, tooltip = L["MOUNT_TYPE_3"]},
	}

	for i = 1, #typesTextures do
		CreateButtonFilter(i, self.filtersBar.types, 88, 24, typesTextures[i])
	end

	-- FILTERS SELECTED BUTTONS
	typesTextures[4] = {id = 4, path = "Interface/BUTTONS/UI-GROUPLOOT-PASS-DOWN", width = 16, height = 16, tooltip = L["MOUNT_TYPE_4"]}
	for i = 1, #typesTextures do
		CreateButtonFilter(i, self.filtersBar.selected, 66, 24, typesTextures[i])
	end

	-- FILTERS SOURCES BUTTONS
	local sourcesTextures = {
		{id = 1, path = texPath.."sources", texCoord = {0, .25, 0, .25}, width = 20, height = 20},
		{id = 2, path = texPath.."sources", texCoord = {.25, .5, 0, .25}, width = 20, height = 20},
		{id = 3, path = texPath.."sources", texCoord = {.5, .75, 0, .25}, width = 20, height = 20},
		{id = 4, path = texPath.."sources", texCoord = {.75, 1, 0, .25}, width = 20, height = 20},
		{id = 6, path = texPath.."sources", texCoord = {.25, .5, .25, .5}, width = 20, height = 20},
		{id = 7, path = texPath.."sources", texCoord = {.5, .75, .25, .5}, width = 20, height = 20},
		{id = 8, path = texPath.."sources", texCoord = {.75, 1, .25, .5}, width = 20, height = 20},
		{id = 9, path = texPath.."sources", texCoord = {0, .25, .5, .75}, width = 20, height = 20},
		{id = 10, path = texPath.."sources", texCoord = {.25, .5, .5, .75}, width = 20, height = 20},
		{id = 11, path = texPath.."sources", texCoord = {.5, .75, .5, .75}, width = 20, height = 20},
		{id = 12, path = 4696085, width = 20, height = 20},
	}

	for i = 1, #sourcesTextures do
		local t = sourcesTextures[i]
		t.tooltip = _G["BATTLE_PET_SOURCE_"..t.id]
		CreateButtonFilter(i, self.filtersBar.sources, 24, 24, t)
	end

	-- SHOWN PANEL
	self.shownPanel.text:SetText(L["Shown:"])
	self.shownPanel.clear:SetScript("OnClick", function() self:resetToDefaultFilters() end)

	-- MODEL SCENE ACTOR
	hooksecurefunc(self.modelScene, "AcquireAndInitializeActor", function(self, actorInfo)
		if actorInfo.scriptTag == "unwrapped" then
			self:GetActorByTag("unwrapped"):SetOnSizeChangedCallback(function()
				journal:event("MOUNT_MODEL_LOADED")
			end)
		end
	end)

	-- MODEL SCENE CAMERA
	hooksecurefunc(self.modelScene, "SetActiveCamera", function(self)
		journal:event("SET_ACTIVE_CAMERA", self.activeCamera)
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
		btn.highlight:Show()
		btn:SetAlpha(1)
		GameTooltip:SetOwner(btn, "ANCHOR_NONE")
		GameTooltip:SetPoint("RIGHT", btn, "LEFT", 14, 0)

		local name, _,_,_,_,_,_,_, faction = self:getMountInfo(self.selectedMountID)
		local expansion, familyID, _,_,_,_,_, mountType = self:getMountInfoExtra(self.selectedMountID)
		GameTooltip:SetText(name, nil, nil, nil, nil, true)

		-- type
		local mType, typeStr = self.mountTypes[mountType]
		if type(mType) == "table" then
			typeStr = L["MOUNT_TYPE_"..mType[1]]
			for i = 2, #mType do
				typeStr = ("%s, %s"):format(typeStr, L["MOUNT_TYPE_"..mType[i]])
			end
		else
			typeStr = L["MOUNT_TYPE_"..mType]
		end
		util.addTooltipDLine(L["types"], typeStr)

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
		local mTags = self.tags.mountTags[self.selectedSpellID]
		if mTags then
			util.addTooltipDLine(L["tags"], table.concat(GetKeysArray(mTags), ", "))
		end

		-- faction
		util.addTooltipDLine(L["factions"], L["MOUNT_FACTION_"..((faction or 2) + 1)])

		-- expanstion
		util.addTooltipDLine(EXPANSION_FILTER_TEXT, _G["EXPANSION_NAME"..(expansion - 1)])

		-- receipt date
		local mountDate = mounts:getMountDate(self.selectedSpellID)
		if mountDate then
			local tDate = date("*t", mountDate)
			util.addTooltipDLine(L["Receipt date"], FormatShortDate(tDate.day, tDate.month, tDate.year))
		end

		-- statistic
		local summons = mounts:getMountSummons(self.selectedSpellID)
		if summons > 0 then util.addTooltipDLine(SUMMONS, summons) end

		local mountTime = mounts:getMountTime(self.selectedSpellID)
		if mountTime > 0 then util.addTooltipDLine(L["Travel time"], util.getTimeBreakDown(mountTime)) end

		local mountDistance = mounts:getMountDistance(self.selectedSpellID)
		if mountDistance > 0 then
			util.addTooltipDLine(L["Travel distance"], util:getFormattedDistance(mountDistance))
			util.addTooltipDLine(L["Avg. speed"], util:getFormattedAvgSpeed(mountDistance, mountTime))
		end

		GameTooltip:Show()
	end)

	msMountHint:SetScript("OnLeave", function(btn)
		btn.highlight:Hide()
		btn:SetAlpha(.5)
		GameTooltip:Hide()
	end)

	local function updateMountHint()
		if msMountHint:IsMouseOver() then
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
		local info = {}
		local allCreatureDisplays = self:getMountAllCreatureDisplayInfo(self.selectedMountID)
		local func = function(_, creatureID)
			self:updateMountDisplay(true, creatureID)
		end

		for i = 1, #allCreatureDisplays do
			local creatureID = allCreatureDisplays[i]
			info.text = MODEL.." "..i
			info.arg1 = creatureID
			info.func = func
			info.checked = self.mountDisplay.lastCreatureID == creatureID
			btn:ddAddButton(info, level)
		end
	end)

	self.multipleMountBtn:SetScript("OnClick", function(btn, mouseBtn)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		if mouseBtn == "LeftButton" then
			btn:ddCloseMenus()
			local allCreatureDisplays = self:getMountAllCreatureDisplayInfo(self.selectedMountID)
			for i = 1, #allCreatureDisplays do
				if self.mountDisplay.lastCreatureID == allCreatureDisplays[i] then
					local index = Wrap(i + 1, #allCreatureDisplays)
					self:updateMountDisplay(true, allCreatureDisplays[index])
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
	playerToggle:SetChecked(GetCVarBool("mountJournalShowPlayer"))
	SetPortraitTexture(playerToggle.portrait, "player")
	playerToggle:RegisterEvent("PORTRAITS_UPDATED")
	playerToggle:SetScript("OnEvent", function(playerToggle)
		SetPortraitTexture(playerToggle.portrait, "player")
		if playerToggle.portrait:GetTexture() then
			playerToggle:UnregisterEvent("PORTRAITS_UPDATED")
			playerToggle:SetScript("OnEvent", nil)
			self:updateMountDisplay(true)
		end
	end)
	playerToggle:SetScript("OnClick", function(btn)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		SetCVar("mountJournalShowPlayer", btn:GetChecked() and 1 or 0)
		self:updateMountDisplay(true)
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
			self:useMount(self.selectedMountID)
			btn:SetAttribute("macrotext", nil)
		elseif self.selectedMountID then
			btn:SetAttribute("macrotext", self.selectedMountID.macro)
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
	resize:RegisterForDrag("LeftButton")
	resize:SetScript("OnDragStart", function(btn)
		local parent = btn:GetParent()
		local minWidth, minHeight = self.CollectionsJournal:GetSize()
		local maxWidth = UIParent:GetWidth() - parent:GetLeft() * 2
		local maxHeight = parent:GetTop() - CollectionsJournalTab1:GetHeight()
		parent:SetResizeBounds(max(minWidth, self.minTabWidth), minHeight, maxWidth, maxHeight)
		parent:StartSizing("BOTTOMRIGHT", true)
	end)
	resize:SetScript("OnDragStop", function(btn)
		local parent = btn:GetParent()
		parent:StopMovingOrSizing()
		mounts.config.journalWidth, mounts.config.journalHeight = parent:GetSize()
		self:event("JOURNAL_RESIZED")
	end)
	resize:SetScript("OnEnter", function()
		if SetCursor then SetCursor("UI_RESIZE_CURSOR") end
	end)
	resize:SetScript("OnLeave", function()
		if SetCursor then SetCursor(nil) end
	end)

	-- MOUNT SPECIAL
	local isMounted = not not util.getUnitMount("player")
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
		DoEmote("MountSpecial")
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

	self:updateCollectionTabs(true)
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
journal:RegisterEvent("ADDON_LOADED")


function journal:ADDON_LOADED(addonName)
	if addonName == "Blizzard_Collections" and select(2, C_AddOns.IsAddOnLoaded(addon))
	or addonName == addon and select(2, C_AddOns.IsAddOnLoaded("Blizzard_Collections")) then
		self:UnregisterEvent("ADDON_LOADED")
		self.ADDON_LOADED = nil

		self.mjFiltersBackup = {sources = {}, types = {}}
		self.frameState = {}
		self.CollectionsJournal = CollectionsJournal
		self.MountJournal = MountJournal

		self.useMountsJournalButton = CreateFrame("CheckButton", nil, self.MountJournal, "MJUseMountsJournalButtonTemplate")
		self.useMountsJournalButton:SetPoint("BOTTOMLEFT", self.CollectionsJournal, "BOTTOMLEFT", 281, 2)
		self.useMountsJournalButton.Text:SetFontObject("GameFontNormal")
		self.useMountsJournalButton.Text:SetText(addon)
		self.useMountsJournalButton:SetChecked(not mounts.config.useDefaultJournal)

		self.useMountsJournalButton:SetScript("OnEnter", function(btn)
			if not btn:IsEnabled() then
				GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
				GameTooltip_SetTitle(GameTooltip, addon)
				GameTooltip_AddErrorLine(GameTooltip, SPELL_FAILED_AFFECTING_COMBAT)
				GameTooltip:Show()
			end
		end)

		self.useMountsJournalButton:SetScript("OnEnable", function(btn)
			btn.Text:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
		end)

		self.useMountsJournalButton:HookScript("OnClick", function(btn)
			local checked = btn:GetChecked()
			mounts.config.useDefaultJournal = not checked
			if checked then
				if self.init then
					self:init()
				else
					self:setMJFiltersBackup()
					self:hideFrames()
				end
			else
				self:restoreMJFilters()
				self:restoreFrames()
			end
		end)

		self.useMountsJournalButton:SetScript("OnShow", function(btn)
			if InCombatLockdown() then
				btn:Disable()
			else
				btn:Enable()
				if not mounts.config.useDefaultJournal then
					self:init()
				end
			end
			self:RegisterEvent("PLAYER_REGEN_DISABLED")
			self:RegisterEvent("PLAYER_REGEN_ENABLED")
		end)

		self.useMountsJournalButton:SetScript("OnHide", function()
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
			self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		end)
	end
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
	self:RegisterEvent("PLAYER_LEAVING_WORLD")
	self:updateIndexByMountID(true)
end


function journal:restoreMJFilters()
	local backup = self.mjFiltersBackup
	if not backup.isBackuped then return end
	self:UnregisterEvent("MOUNT_JOURNAL_SEARCH_UPDATED")
	self:UnregisterEvent("PLAYER_LEAVING_WORLD")
	C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED, backup.collected)
	C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED, backup.notCollected)
	C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE, backup.unusable)
	for i = 1, C_PetJournal.GetNumPetSources() do
		if C_MountJournal.IsValidSourceFilter(i) then
			C_MountJournal.SetSourceFilter(i, backup.sources[i])
		end
	end
	for i = 1, Enum.MountTypeMeta.NumValues do
		if not C_MountJournal.IsValidTypeFilter(i) then break end
		C_MountJournal.SetTypeFilter(i, backup.types[i])
	end
	backup.isBackuped = false
end
journal.PLAYER_LEAVING_WORLD = journal.restoreMJFilters


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
		self:updateMountsList()
	end
end


function journal:PLAYER_REGEN_ENABLED()
	if self.init then
		self.useMountsJournalButton:Enable()
		if not mounts.config.useDefaultJournal then
			self:init()
		end
	else
		self.leftInset:EnableKeyboard(true)
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
	if companionType == "MOUNT" and InCombatLockdown() then
		self:updateMounted(not not util.getUnitMount("player"))
	end
end


function journal:updateSpeed(speed)
	self.mountSpeed:SetText(util:getFormattedSpeed(speed))
end


function journal:getMountInfo(mount)
	-- name, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, _, isForDragonriding
	if type(mount) == "number" then
		return C_MountJournal.GetMountInfoByID(mount)
	else
		return mount.name, mount.spellID, mount.icon, mount:isActive(), mount:isUsable(), 0, mount:getIsFavorite(), false, nil, not mount.isShown, mount:isCollected()
	end
end


function journal:getMountInfoExtra(mount)
	-- expansion, familyID, rarity, creatureDisplayID, descriptionText, sourceText, isSelfMount, mountType, modelSceneID, animID, spellVisualKitID, disablePlayerMountPreview
	if type(mount) == "number" then
		local mountDB = mountsDB[mount]
		return mountDB[1], mountDB[2], mountDB[3], C_MountJournal.GetMountInfoExtraByID(mount)
	else
		return mount.expansion, mount.familyID, nil, mount.creatureID, mount.description, mount.sourceText, mount.selfMount, mount.mountType, mount.modelSceneID, 0, 0
	end
end


function journal:getMountAllCreatureDisplayInfo(mount)
	if type(mount) == "number" then
		local allCreatureDisplays = C_MountJournal.GetMountAllCreatureDisplayInfoByID(self.selectedMountID)
		local list = {}
		for i = 1, #allCreatureDisplays do
			list[i] = allCreatureDisplays[i].creatureDisplayID
		end
		return list
	else
		return mount.allCreature
	end
end


function journal:setScrollGridMounts(grid, isSwitch)
	local index = self.view:CalculateDataIndices(self.scrollBox)
	local template, padding

	if grid then
		local oldGridN = self.gridN
		if mounts.config.showTypeSelBtn then
			self.gridN = 3
			padding = 2
			template = "MJMountGridListButtonWithTypeBtns"
		else
			self.gridN = 4
			padding = 7
			template = "MJMountGridListButtonDef"
		end
		self.initMountButton = self.gridInitMountButton
		self.view:SetPadding(0,0,padding,0,0)
		self.view:SetElementExtent(44)
		if isSwitch then
			index = math.ceil((index * oldGridN - oldGridN + 1) / self.gridN)
		else
			index = math.ceil(index / self.gridN)
		end
	else
		local extent
		if mounts.config.showTypeSelBtn then
			self.gridN = 3
			extent = 44
			padding = 25
			template = "MJMountDefaultListButtonWithTypeBtns"
		else
			self.gridN = 4
			extent = 40
			padding = 0
			template = "MJMountDefaultListButton"
		end
		self.initMountButton = self.defaultInitMountButton
		self.view:SetPadding(0,0,41,padding,0)
		self.view:SetElementExtent(extent)
		if not isSwitch then index = (index - 1) * self.gridN + 1 end
	end

	self.view:SetElementInitializer(template, function(...)
		self:initMountButton(...)
	end)

	if self.dataProvider then
		self:updateMountsList()
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
					local last = btn.toggle[index - 1]
					if last then
						btn.toggleBG:SetPoint("BOTTOMRIGHT", last, -1, -1)
						btn.toggleBG:Show()
					else
						btn.toggleBG:Hide()
					end
				end
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
	local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, isFiltered, isCollected = self:getMountInfo(data.mountID)

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

	btn:Enable()
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
	for i = 1, #btn.mounts do
		local gbtn = btn.mounts[i]

		if data[i] then
			local mountID = data[i].mountID
			local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, isFiltered, isCollected = self:getMountInfo(mountID)

			local needsFanfare, qualityColor
			if type(mountID) == "number" then
				needsFanfare = C_MountJournal.NeedsFanfare(mountID)
				qualityColor = util.getRarityColor(mountID)
			else
				qualityColor = HIGHLIGHT_FONT_COLOR
			end

			gbtn.spellID = spellID
			gbtn.mountID = mountID
			gbtn.icon:SetTexture(needsFanfare and COLLECTIONS_FANFARE_ICON or icon)
			gbtn.icon:SetVertexColor(1, 1, 1)
			gbtn.qualityBorder:SetVertexColor(qualityColor:GetRGB())
			gbtn:Enable()
			gbtn.selectedTexture:SetShown(mountID == self.selectedMountID)
			gbtn.hidden:SetShown(self:isMountHidden(spellID))
			gbtn.favorite:SetShown(isFavorite)

			local mountWeight = self.mountsWeight[spellID]
			if mountWeight then
				gbtn.mountWeight:SetText(getColorWeight(mountWeight))
				gbtn.mountWeight:Show()
				gbtn.mountWeightBG:Show()
			else
				gbtn.mountWeight:Hide()
				gbtn.mountWeightBG:Hide()
			end

			if isUsable or needsFanfare then
				gbtn.icon:SetDesaturated()
				gbtn.icon:SetAlpha(1)
			elseif isCollected then
				gbtn.icon:SetDesaturated(true)
				-- 150/255, 50/255, 50/255
				gbtn.icon:SetVertexColor(.58823529411765, .19607843137255, .19607843137255)
				gbtn.icon:SetAlpha(.75)
				gbtn.qualityBorder:SetAlpha(.75)
			else
				gbtn.icon:SetDesaturated(true)
				gbtn.icon:SetAlpha(.35)
				gbtn.qualityBorder:SetAlpha(.25)
			end

			self:updateMountToggleButton(gbtn)
			gbtn:Show()
		else
			gbtn:Hide()
		end
	end
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
				if mounts.config.gridToggle and (key == "UP" or key == "DOWN") then
					delta = delta * self.gridN
				end

				index = nil
				if self.selectedMountID then
					local data = self:getMountDataByMountID(self.selectedMountID)
					if data then
						index = updateIndex(data.index, delta)
					end
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


function journal:setEditMountsList()
	self.db = mounts.charDB.currentProfileName and mounts.profiles[mounts.charDB.currentProfileName] or mounts.defProfile
	self.zoneMounts = self.db.zoneMountsFromProfile and mounts.defProfile.zoneMounts or self.db.zoneMounts
	local mapID = self.navBar.mapID
	if mapID == self.navBar.defMapID then
		self.currentList = self.db
		self.listMapID = nil
		self.list = self.currentList
	else
		self.currentList = self.zoneMounts[mapID]
		self.listMapID = mapID
		self.list = self.currentList
		while self.list and self.list.listFromID do
			if self.list.listFromID == self.navBar.defMapID then
				self.listMapID = nil
				self.list = self.db
			else
				self.listMapID = self.list.listFromID
				self.list = self.zoneMounts[self.listMapID]
			end
		end
	end
	self.petForMount = self.db.petListFromProfile and mounts.defProfile.petForMount or self.db.petForMount
	self.mountsWeight = self.db.mountsWeight
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


function journal:sortMounts()
	local fSort, db = mounts.filters.sorting, mountsDB
	local numNeedingFanfare = C_MountJournal.GetNumMountsNeedingFanfare()

	local function getByMountID(by, mount, data)
		if by == "type" then
			local _,_,_,_, mType = C_MountJournal.GetMountInfoExtraByID(mount)
			mType = self.mountTypes[mType]
			return type(mType) == "number" and mType or mType[1]
		elseif by == "family" then
			local family = db[mount][2]
			return type(family) == "number" and family or family[1]
		elseif by == "expansion" then
			return db[mount][1]
		elseif by == "rarity" then
			return db[mount][3]
		elseif by == "summons" then
			return mounts:getMountSummons(data.spellID)
		elseif by == "time" then
			return mounts:getMountTime(data.spellID)
		elseif by == "distance" then
			return mounts:getMountDistance(data.spellID)
		end
		return data.name
	end

	local function getByMount(by, mount, data)
		if by == "type" then
			local mType = self.mountTypes[mount.mountType]
			return type(mType) == "number" and mType or mType[1]
		elseif by == "family" then
			local family = mount.familyID
			return type(family) == "number" and family or family[1]
		elseif by == "expansion" then
			return mount.expansion
		elseif by == "rarity" then
			return 100
		elseif by == "summons" then
			return mounts:getMountSummons(data.spellID)
		elseif by == "time" then
			return mounts:getMountTime(data.spellID)
		elseif by == "distance" then
			return mounts:getMountDistance(data.spellID)
		end
		return data.name
	end

	local mCache = setmetatable({}, {__index = function(t, mount)
		local data = {}
		if type(mount) == "number" then
			local name, spellID, _,_,_,_, isFavorite, _,_,_, isCollected = C_MountJournal.GetMountInfoByID(mount)
			data.name = name
			data.isFavorite = isFavorite
			data.isCollected = isCollected
			data.spellID = spellID
			if numNeedingFanfare > 0 and C_MountJournal.NeedsFanfare(mount) then
				data.needFanfare = true
				numNeedingFanfare = numNeedingFanfare - 1
			end
			data.by = getByMountID(fSort.by, mount, data)
			data.by2 = fSort.by2 == fSort.by and data.by or getByMountID(fSort.by2, mount, data)
			if fSort.by3 == fSort.by then data.by3 = data.by
			elseif fSort.by3 == fSort.by2 then data.by3 = data.by2
			else data.by3 = getByMountID(fSort.by3, mount, data) end
		else
			data.name = mount.name
			data.isFavorite = mount:getIsFavorite()
			data.isCollected = mount:isCollected()
			data.spellID = mount.spellID
			data.needsFanfare = false
			data.additional = true
			data.by = getByMount(fSort.by, mount, data)
			data.by2 = fSort.by2 == fSort.by and data.by or getByMount(fSort.by2, mount, data)
			if fSort.by3 == fSort.by then data.by3 = data.by
			elseif fSort.by3 == fSort.by2 then data.by3 = data.by2
			else data.by3 = getByMount(fSort.by3, mount, data) end
		end
		t[mount] = data
		return data
	end})

	sort(self.mountIDs, function(a, b)
		if a == b then return false end
		local ma = mCache[a]
		local mb = mCache[b]

		-- FANFARE
		if ma.needFanfare and not mb.needFanfare then return true
		elseif not ma.needFanfare and mb.needFanfare then return false end

		-- COLLECTED
		if fSort.collectedFirst then
			if ma.isCollected and not mb.isCollected then return true
			elseif not ma.isCollected and mb.isCollected then return false end
		end

		-- FAVORITES
		if fSort.favoritesFirst then
			if ma.isFavorite and not mb.isFavorite then return true
			elseif not ma.isFavorite and mb.isFavorite then return false end
		end

		-- ADDITIONAL
		if fSort.additionalFirst then
			if ma.additional and not mb.additional then return true
			elseif not ma.additional and mb.additional then return false end
		end

		-- BY
		if ma.by < mb.by then return not fSort.reverse
		elseif ma.by > mb.by then return fSort.reverse end

		if ma.by2 < mb.by2 then return not fSort.reverse2
		elseif ma.by2 > mb.by2 then return fSort.reverse2 end

		if ma.by3 < mb.by3 then return not fSort.reverse3
		elseif ma.by3 > mb.by3 then return fSort.reverse3 end

		return ma.spellID < mb.spellID
	end)

	self:updateMountsList()
end


function journal:isCanFavorite(mountID)
	if type(mountID) == "table" then return true end
	local index = self.indexByMountID[mountID]
	if index and mountID ~= C_MountJournal.GetDisplayedMountID(index) then
		self:updateIndexByMountID(true)
		index = self.indexByMountID[mountID]
	end
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
		local index = self.indexByMountID[mountID]
		if index and mountID ~= C_MountJournal.GetDisplayedMountID(index) then
			self:updateIndexByMountID(true)
			index = self.indexByMountID[mountID]
		end
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


function journal:createMountList(mapID)
	self.zoneMounts[mapID] = {
		fly = {},
		ground = {},
		swimming = {},
		flags = {},
	}
	self:setEditMountsList()
end


function journal:getRemoveMountList(mapID)
	if not mapID then return end
	local list = self.zoneMounts[mapID]

	local flags
	for _, value in next, list.flags do
		if value then
			flags = true
			break
		end
	end

	if not (next(list.fly) or next(list.ground) or next(list.swimming))
	and not flags
	and not list.listFromID then
		self.zoneMounts[mapID] = nil
		self:setEditMountsList()
	end
end


function journal:mountToggle(mountType, spellID, mountID)
	if not self.list then
		self:createMountList(self.listMapID)
	end
	local tbl = self.list[mountType]
	tbl[spellID] = not tbl[spellID] or nil
	self:getRemoveMountList(self.listMapID)

	local btn = self:getMountButtonByMountID(mountID)
	if btn then self:initMountButton(btn, btn:GetElementData()) end

	-- mounts:setMountsList()
	self.existingLists:refresh()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end


function journal:setFlag(flag, enable)
	if self.navBar.mapID == self.navBar.defMapID then return end

	if enable and not (self.currentList and self.currentList.flags) then
		self:createMountList(self.navBar.mapID)
	end
	self.currentList.flags[flag] = enable
	if not enable then
		self:getRemoveMountList(self.navBar.mapID)
	end

	-- mounts:setMountsList()
	self.existingLists:refresh()
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


function journal:updateMountDisplay(forceSceneChange, creatureID)
	local info = self.mountDisplay.info
	if self.selectedMountID then
		local creatureName, spellID, icon, active, isUsable = self:getMountInfo(self.selectedMountID)
		local isMount = type(self.selectedMountID) == "number"
		local needsFanfare = isMount and C_MountJournal.NeedsFanfare(self.selectedMountID)

		if self.mountDisplay.lastMountID ~= self.selectedMountID or forceSceneChange or MountJournal_GetPendingMountChanges() then
			local _,_, rarity, creatureDisplayID, descriptionText, sourceText, isSelfMount, mountType, modelSceneID, animID, spellVisualKitID, disablePlayerMountPreview = self:getMountInfoExtra(self.selectedMountID)
			if not creatureID then
				if self.mountDisplay.lastMountID == self.selectedMountID then
					creatureID = self.mountDisplay.lastCreatureID
				else
					if not creatureDisplayID then
						local allCreatureDisplays = C_MountJournal.GetMountAllCreatureDisplayInfoByID(self.selectedMountID)
						if allCreatureDisplays and #allCreatureDisplays > 0 then
							creatureDisplayID = allCreatureDisplays[1].creatureDisplayID
						else
							creatureDisplayID = 0
						end
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

			info.link:SetShown(mounts.config.showWowheadLink)
			info.linkLang:SetShown(mounts.config.showWowheadLink)
			local lang = mounts.config.wowheadLinkLang
			info.link:SetText("wowhead.com"..(lang == "en" and "" or "/"..lang).."/spell="..spellID)
			info.name:SetText(creatureName)
			info.source:SetText(sourceText)
			info.lore:SetText(descriptionText)
			self.multipleMountBtn:SetShown(self.mountsWithMultipleModels[self.selectedMountID])

			self:event("MOUNT_MODEL_UPDATE", mountType, not isMount)

			self.modelScene:TransitionToModelSceneID(modelSceneID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_MAINTAIN, forceSceneChange)
			self.modelScene:PrepareForFanfare(needsFanfare)

			local mountActor = self.modelScene:GetActorByTag("unwrapped")
			if mountActor then
				if creatureID == "player" then
					self.modelScene:GetActorByTag("player-rider"):ClearModel()
					local sheathWeapons = true
					local autoDress = true
					local hideWeapons = false
					local usePlayerNativeForm = true
					if mountActor:SetModelByUnit("player", sheathWeapons, autoDress, hideWeapons, usePlayerNativeForm) then
						mountActor:SetAnimationBlendOperation(Enum.ModelBlendOperation.None)
						mountActor:SetAnimation(618)
					else
						mountActor:ClearModel()
					end
				else
					mountActor:SetModelByCreatureDisplayID(creatureID, true)
					-- mount self idle animation
					if isSelfMount then
						mountActor:SetAnimationBlendOperation(Enum.ModelBlendOperation.None)
						mountActor:SetAnimation(618)
					else
						mountActor:SetAnimationBlendOperation(Enum.ModelBlendOperation.Anim)
						mountActor:SetAnimation(0)
					end
					self.modelScene:AttachPlayerToMount(mountActor, animID, isSelfMount, disablePlayerMountPreview or not GetCVarBool("mountJournalShowPlayer"), spellVisualKitID, PlayerUtil.ShouldUseNativeFormInModelScene())
				end
			end
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
		self.modelScene:StartUnwrapAnimation(function()
			C_MountJournal.ClearFanfare(mountID)
		end)
	else
		C_MountJournal.SummonByID(mountID)
	end
end


local function getGridTogglePredicate(predicate)
	if mounts.config.gridToggle then
		return function(btn, data)
			data = data or btn
			for i = 1, #data do
				if predicate(btn[i] or btn, data[i]) then return true end
			end
		end
	else
		return predicate
	end
end


function journal:getMountDataByMountID(mountID)
	local mountData
	local predicate = getGridTogglePredicate(function(data)
		if data.mountID == mountID then
			mountData = data
			return true
		end
	end)
	local dataIndex = self.scrollBox:FindByPredicate(predicate)
	return mountData, dataIndex
end


function journal:getMountDataByMountIndex(index)
	local mountData
	local predicate = getGridTogglePredicate(function(data)
		if data.index == index then
			mountData = data
			return true
		end
	end)
	local dataIndex = self.scrollBox:FindByPredicate(predicate)
	return mountData, dataIndex
end


function journal:getMountButtonByMountID(mountID)
	local predicate = getGridTogglePredicate(function(btn, data)
		return data.mountID == mountID
	end)
	return self.scrollBox:FindFrameByPredicate(predicate)
end


function journal:setSelectedMount(mountID, spellID, dataIndex)
	local scrollTo = not spellID
	if not spellID then
		local _
		_, spellID = self:getMountInfo(mountID)
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
		if not dataIndex then
			local _
			_, dataIndex = self:getMountDataByMountID(mountID)
		end

		if dataIndex then
			local scrollOffset = self.scrollBox:GetDerivedScrollOffset()
			local indexOffset = self.scrollBox:GetExtentUntil(dataIndex)

			if indexOffset < scrollOffset then
				self.scrollBox:ScrollToElementDataIndex(dataIndex, ScrollBoxConstants.AlignBegin)
			elseif indexOffset + self.scrollBox:GetElementExtent(dataIndex) > scrollOffset + self.scrollBox:GetVisibleExtent() then
				self.scrollBox:ScrollToElementDataIndex(dataIndex, ScrollBoxConstants.AlignEnd)
			end
		end
	end

	self:event("MOUNT_SELECT")
end


function journal:selectMountByIndex(index)
	local data, dataIndex = self:getMountDataByMountIndex(index)
	if data then self:setSelectedMount(data.mountID, nil, dataIndex) end
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


function journal:saveDefaultFilters()
	local filters = mounts.filters
	local defFilters = mounts.defFilters

	defFilters.collected = filters.collected
	defFilters.notCollected = filters.notCollected
	defFilters.unusable = filters.unusable
	defFilters.hideOnChar = filters.hideOnChar
	defFilters.onlyHideOnChar = filters.onlyHideOnChar
	defFilters.hiddenByPlayer = filters.hiddenByPlayer
	defFilters.onlyHiddenByPlayer = filters.onlyHiddenByPlayer
	defFilters.onlyNew = filters.onlyNew
	defFilters.mountsRarity.sign = filters.mountsRarity.sign
	defFilters.mountsRarity.value = filters.mountsRarity.value
	defFilters.mountsWeight.sign = filters.mountsWeight.sign
	defFilters.mountsWeight.weight = filters.mountsWeight.weight
	defFilters.tags.noTag = filters.tags.noTag
	defFilters.tags.withAllTags = filters.tags.withAllTags

	for i = 1, #filters.types do
		defFilters.types[i] = filters.types[i]
	end
	for i = 1, #filters.selected do
		defFilters.selected[i] = filters.selected[i]
	end
	for i = 1, #filters.sources do
		defFilters.sources[i] = filters.sources[i]
	end
	for k, value in pairs(filters.specific) do
		defFilters.specific[k] = value
	end
	for k, value in pairs(filters.family) do
		defFilters.family[k] = value
	end
	for i = 1, #filters.factions do
		defFilters.factions[i] = filters.factions[i]
	end
	for i = 1, #filters.pet do
		defFilters.pet[i] = filters.pet[i]
	end
	for i = 1, #filters.expansions do
		defFilters.expansions[i] = filters.expansions[i]
	end
	for tag, value in pairs(filters.tags.tags) do
		defFilters.tags.tags[tag] = value[2]
	end

	self:setShownCountMounts()
end


function journal:restoreDefaultFilters()
	local defFilters = mounts.defFilters

	defFilters.collected = true
	defFilters.notCollected = true
	defFilters.unusable = true
	defFilters.hideOnChar = false
	defFilters.onlyHideOnChar = false
	defFilters.hiddenByPlayer = false
	defFilters.onlyHiddenByPlayer = false
	defFilters.onlyNew = false
	defFilters.mountsRarity.sign = nil
	defFilters.mountsRarity.value = 100
	defFilters.mountsWeight.sign = nil
	defFilters.mountsWeight.weight = 100
	defFilters.tags.noTag = true
	defFilters.tags.withAllTags = false
	wipe(defFilters.types)
	wipe(defFilters.selected)
	wipe(defFilters.sources)
	wipe(defFilters.specific)
	wipe(defFilters.family)
	wipe(defFilters.factions)
	wipe(defFilters.pet)
	wipe(defFilters.expansions)
	wipe(defFilters.tags.tags)

	self:setShownCountMounts()
end


function journal:isDefaultFilters()
	local filters = mounts.filters
	local defFilters = mounts.defFilters
	local isDefault = true
	local filterStr = ""

	local function add(text)
		isDefault = false
		if not filterStr:find(text, 3, true) then
			filterStr = filterStr..", "..text
		end
	end

	if #self.searchBox:GetText() ~= 0 then add(SEARCH) end
	if defFilters.collected ~= filters.collected then add(COLLECTED) end
	if defFilters.notCollected ~= filters.notCollected then add(NOT_COLLECTED) end
	if defFilters.unusable ~= filters.unusable then add(MOUNT_JOURNAL_FILTER_UNUSABLE) end

	if not defFilters.hideOnChar ~= not filters.hideOnChar then add(L["hidden for character"]) end
	if not defFilters.onlyHideOnChar ~= not filters.onlyHideOnChar then add(L["hidden for character"]) end
	if not defFilters.hiddenByPlayer ~= not filters.hiddenByPlayer then add(L["Hidden by player"]) end
	if not defFilters.onlyHiddenByPlayer ~= not filters.onlyHiddenByPlayer then add(L["Hidden by player"]) end
	if not defFilters.onlyNew ~= not filters.onlyNew then add(L["Only new"]) end
	for i = 1, #filters.types do
		if defFilters.types[i] ~= filters.types[i] then add(L["types"]) break end
	end
	for i = 1, #filters.selected do
		if defFilters.selected[i] ~= filters.selected[i] then add(L["selected"]) break end
	end
	for i = 1, #filters.sources do
		if defFilters.sources[i] ~= filters.sources[i] then add(SOURCES) break end
	end
	for k, value in pairs(filters.specific) do
		if defFilters.specific[k] ~= value then add(L["Specific"]) break end
	end
	for k, value in pairs(filters.family) do
		if defFilters.family[k] ~= value then add(L["Family"]) break end
	end
	for i = 1, #filters.factions do
		if defFilters.factions[i] ~= filters.factions[i] then add(L["factions"]) break end
	end
	for i = 1, #filters.pet do
		if defFilters.pet[i] ~= filters.pet[i] then add(PET) break end
	end
	for i = 1, #filters.expansions do
		if defFilters.expansions[i] ~= filters.expansions[i] then add(L["expansions"]) break end
	end
	if defFilters.mountsRarity.sign ~= filters.mountsRarity.sign then add(L["Rarity"]) end
	if defFilters.mountsRarity.value ~= filters.mountsRarity.value then add(L["Rarity"]) end
	if defFilters.mountsWeight.sign ~= filters.mountsWeight.sign then add(L["Chance of summoning"]) end
	if defFilters.mountsWeight.weight ~= filters.mountsWeight.weight then add(L["Chance of summoning"]) end
	if defFilters.tags.noTag ~= filters.tags.noTag then add(L["tags"]) end
	if defFilters.tags.withAllTags ~= filters.tags.withAllTags then add(L["tags"]) end
	for tag, value in pairs(filters.tags.tags) do
		if defFilters.tags.tags[tag] ~= value[2] then add(L["tags"]) break end
	end

	self.shownPanel.filters:SetText("("..filterStr:sub(3)..")")
	return isDefault
end


function journal:setAllFilters(typeFilter, enabled)
	local filter = mounts.filters[typeFilter]
	for k in pairs(filter) do
		filter[k] = enabled
	end
end


function journal:clearBtnFilters()
	self:setAllFilters("sources", true)
	self:setAllFilters("types", true)
	self:setAllFilters("selected", true)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	self:updateBtnFilters()
	self:updateMountsList()
end


function journal:resetToDefaultFilters()
	local filters = mounts.filters
	local defFilters = mounts.defFilters

	filters.collected = defFilters.collected
	filters.notCollected = defFilters.notCollected
	filters.unusable = defFilters.unusable
	filters.hideOnChar = defFilters.hideOnChar
	filters.onlyHideOnChar = defFilters.onlyHideOnChar
	filters.hiddenByPlayer = defFilters.hiddenByPlayer
	filters.onlyHiddenByPlayer = defFilters.onlyHiddenByPlayer
	filters.onlyNew = defFilters.onlyNew
	filters.mountsRarity.sign = defFilters.mountsRarity.sign
	filters.mountsRarity.value = defFilters.mountsRarity.value
	filters.mountsWeight.sign = defFilters.mountsWeight.sign
	filters.mountsWeight.weight = defFilters.mountsWeight.weight
	filters.tags.noTag = defFilters.tags.noTag
	filters.tags.withAllTags = defFilters.tags.withAllTags

	for i = 1, #filters.types do
		filters.types[i] = defFilters.types[i]
	end
	for i = 1, #filters.selected do
		filters.selected[i] = defFilters.selected[i]
	end
	for i = 1, #filters.sources do
		filters.sources[i] = defFilters.sources[i]
	end
	for k in pairs(filters.specific) do
		filters.specific[k] = defFilters.specific[k]
	end
	for k in pairs(filters.family) do
		filters.family[k] = defFilters.family[k]
	end
	for i = 1, #filters.factions do
		filters.factions[i] = defFilters.factions[i]
	end
	for i = 1, #filters.pet do
		filters.pet[i] = defFilters.pet[i]
	end
	for i = 1, #filters.expansions do
		filters.expansions[i] = defFilters.expansions[i]
	end
	for tag, value in pairs(filters.tags.tags) do
		value[2] = defFilters.tags.tags[tag]
	end

	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	self.searchBox:SetText("")
	self:updateBtnFilters()
	self:updateMountsList()
	self:setCountMounts()
end


function journal:setBtnFilters(tab)
	local i = 0
	local children = self.filtersBar[tab].childs
	local filters = mounts.filters[tab]

	for _, btn in ipairs(children) do
		local checked = btn:GetChecked()
		filters[btn.id] = checked
		if not checked then i = i + 1 end
	end

	if i == #children then
		self:setAllFilters(tab, true)
	end

	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	self:updateBtnFilters()
	self:updateMountsList()
end


function journal:updateBtnFilters()
	local filtersBar, clearShow = self.filtersBar, false

	for typeFilter, filter in pairs(mounts.filters) do
		-- SOURCES
		if typeFilter == "sources" then
			local i, n = 0, 0
			for k, v in pairs(filter) do
				if k ~= 0 then
					i = i + 1
					if v == true then n = n + 1 end
				end
			end

			if i == n then
				filter[0] = true
				for _, btn in ipairs(filtersBar.sources.childs) do
					btn:SetChecked(false)
					btn.icon:SetDesaturated()
				end
				filtersBar.sources:GetParent().filtred:Hide()
			else
				clearShow = true
				filter[0] = false
				for _, btn in ipairs(filtersBar.sources.childs) do
					local checked = filter[btn.id]
					btn:SetChecked(checked)
					btn.icon:SetDesaturated(not checked)
				end
				filtersBar.sources:GetParent().filtred:Show()
			end

		-- TYPES AND SELECTED
		elseif filtersBar[typeFilter] then
			local i = 0
			for _, v in ipairs(filter) do
				if v then i = i + 1 end
			end

			if i == #filter then
				for _, btn in ipairs(filtersBar[typeFilter].childs) do
					btn:SetChecked(false)
					if btn.id > 3 then
						btn.icon:SetDesaturated()
					else
						btn.icon:SetVertexColor(self.colors["mount"..btn.id]:GetRGB())
					end
				end
				filtersBar[typeFilter]:GetParent().filtred:Hide()
			else
				clearShow = true
				for _, btn in ipairs(filtersBar[typeFilter].childs) do
					local checked = filter[btn.id]
					btn:SetChecked(checked)
					if btn.id > 3 then
						btn.icon:SetDesaturated(not checked)
					else
						local color = checked and self.colors["mount"..btn.id] or self.colors.dark
						btn.icon:SetVertexColor(color:GetRGB())
					end
				end
				filtersBar[typeFilter]:GetParent().filtred:Show()
			end
		end
	end

	-- CLEAR BTN FILTERS
	filtersBar.clear:SetShown(clearShow)
end


function journal:isMountHidden(spellID)
	return mounts.globalDB.hiddenMounts and mounts.globalDB.hiddenMounts[spellID]
end


function journal:getFilterSelected(spellID)
	local filter = mounts.filters.selected
	local list = self.list
	if list then
		local i = 0
		if list.fly[spellID] then if filter[1] then return true end
		else i = i + 1 end
		if list.ground[spellID] then if filter[2] then return true end
		else i = i + 1 end
		if list.swimming[spellID] then if filter[3] then return true end
		else i = i + 1 end
		return i == 3 and filter[4]
	else
		return filter[4]
	end
end


function journal:getFilterSpecific(spellID, isSelfMount, mountType, mountID)
	local filter = mounts.filters.specific
	local i = 0
	if isSelfMount then if filter.transform then return true end
	else i = i + 1 end
	if ns.additionalMounts[spellID] then if filter.additional then return true end
	else i = i + 1 end
	if mountType == 402 then if filter.rideAlong then return true end
	else i = i + 1 end
	if self.mountsWithMultipleModels[mountID] then if filter.multipleModels then return true end
	else i = i + 1 end
	for k, t in pairs(specificDB) do
		if t[spellID] then if filter[k] then return true end
		else i = i + 1 end
	end
	return i == 7 and filter.rest
end


function journal:getFilterFamily(familyID)
	local filter = mounts.filters.family
	if type(familyID) == "table" then
		for i = 1, #familyID do
			if filter[familyID[i]] then return true end
		end
	else
		return filter[familyID]
	end
end


function journal:getFilterRarity(rarity)
	local filter = mounts.filters.mountsRarity
	if not filter.sign then
		return true
	elseif filter.sign == ">" then
		return rarity > filter.value
	elseif filter.sign == "<" then
		return rarity < filter.value
	else
		return math.floor(rarity + .5) == filter.value
	end
end


function journal:getFilterWeight(spellID)
	local filter = mounts.filters.mountsWeight
	if not filter.sign then
		return true
	else
		local mountWeight = self.mountsWeight[spellID] or 100
		if filter.sign == ">" then
			return mountWeight > filter.weight
		elseif filter.sign == "<" then
			return mountWeight < filter.weight
		else
			return mountWeight == filter.weight
		end
	end
end


function journal:getFilterType(mountType)
	local types = mounts.filters.types
	local mType = self.mountTypes[mountType]
	if type(mType) == "table" then
		for i = 1, #mType do
			if types[mType[i]] then return true end
		end
	else
		return types[mType]
	end
end


function journal:getCustomSearchFilter(text, mountID, spellID, mountType)
	local id = text:match("^id:(%d+)")
	if id then return tonumber(id) == mountID end

	id = text:match("^spell:(%d+)")
	if id then return tonumber(id) == spellID end

	id = text:match("^type:(%d+)")
	if id then return tonumber(id) == mountType end
end


function journal:setShownCountMounts(numMounts)
	if numMounts then
		self.shownPanel.count:SetText(numMounts)
		self.shownNumMouns = numMounts
	end

	if self:isDefaultFilters() then
		self.shownPanel:Hide()
		self.leftInset:SetPoint("TOPLEFT", self.filtersPanel, "BOTTOMLEFT", 0, -2)
	else
		self.shownPanel:Show()
		self.leftInset:SetPoint("TOPLEFT", self.shownPanel, "BOTTOMLEFT", 0, -2)
	end
	-- self.leftInset:GetHeight()
end


function journal:updateScrollMountList()
	self.scrollBox:SetDataProvider(self.dataProvider, ScrollBoxConstants.RetainScrollPosition)
end


function journal:updateMountsList()
	local filters, list, newMounts, tags = mounts.filters, self.list, newMounts, self.tags
	local sources, factions, pet, expansions = filters.sources, filters.factions, filters.pet, filters.expansions
	local text = util.cleanText(self.searchBox:GetText())
	local numMounts, data = 0
	self.dataProvider = CreateDataProvider()

	for i = 1, #self.mountIDs do
		local mountID = self.mountIDs[i]
		local name, spellID, _,_, isUsable, sourceType, _,_, mountFaction, shouldHideOnChar, isCollected = self:getMountInfo(mountID)
		local expansion, familyID, rarity, _,_, sourceText, isSelfMount, mountType = self:getMountInfoExtra(mountID)
		local petID = self.petForMount[spellID]
		local isMountHidden = self:isMountHidden(spellID)

		-- FAMILY
		if self:getFilterFamily(familyID)
		-- HIDDEN FOR CHARACTER
		and (not shouldHideOnChar or filters.hideOnChar)
		and (not (filters.hideOnChar and filters.onlyHideOnChar) or shouldHideOnChar)
		-- HIDDEN BY PLAYER
		and (not isMountHidden or filters.hiddenByPlayer)
		and (not (filters.hiddenByPlayer and filters.onlyHiddenByPlayer) or isMountHidden)
		-- COLLECTED
		and (isCollected and filters.collected or not isCollected and filters.notCollected)
		-- UNUSABLE
		and (isUsable or not isCollected or filters.unusable)
		-- EXPANSIONS
		and expansions[expansion]
		-- ONLY NEW
		and (not filters.onlyNew or newMounts[mountID])
		-- SOURCES
		and sources[sourceType]
		-- SEARCH
		and (#text == 0
			or name:lower():find(text, 1, true)
			or sourceText:lower():find(text, 1, true)
			or tags:find(spellID, text)
			or self:getCustomSearchFilter(text, mountID, spellID, mountType))
		-- TYPE
		and self:getFilterType(mountType)
		-- FACTION
		and factions[(mountFaction or 2) + 1]
		-- SELECTED
		and self:getFilterSelected(spellID)
		-- PET
		and pet[petID and (type(petID) == "number" and petID or 3) or 4]
		-- SPECIFIC
		and self:getFilterSpecific(spellID, isSelfMount, mountType, mountID)
		-- MOUNTS RARITY
		and self:getFilterRarity(rarity or 100)
		-- MOUNTS WEIGHT
		and self:getFilterWeight(spellID)
		-- TAGS
		and tags:getFilterMount(spellID) then
			numMounts = numMounts + 1
			local mountData = {index = numMounts, mountID = mountID}

			if mounts.config.gridToggle then
				if data and #data < self.gridN then
					data[#data + 1] = mountData
				else
					data = {mountData}
					self.dataProvider:Insert(data)
				end
			else
				self.dataProvider:Insert(mountData)
			end
		end
	end

	self:updateScrollMountList()
	self:setShownCountMounts(numMounts)
end