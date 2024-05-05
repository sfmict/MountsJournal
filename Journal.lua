local addon, L = ...
local C_MountJournal, C_PetJournal, wipe, tinsert, next, pairs, ipairs, select, type, sort, math = C_MountJournal, C_PetJournal, wipe, tinsert, next, pairs, ipairs, select, type, sort, math
local util, mounts, config = MountsJournalUtil, MountsJournal, MountsJournalConfig
local journal = CreateFrame("FRAME", "MountsJournalFrame")
journal.mountTypes = util.mountTypes
util.setEventsMixin(journal)


local MOUNT_ACHIEVEMENT_CATEGORY = 15248


journal.colors = {
	gold = CreateColor(.8, .6, 0),
	gray = CreateColor(.5, .5, .5),
	dark = CreateColor(.3, .3, .3),
	mount1 = CreateColor(.824, .78, .235),
	mount2 = CreateColor(.42, .302, .224),
	mount3 = CreateColor(.031, .333, .388),
	mount4 = CreateColor(.03, .48, .03),
}


local metaMounts = {__index = {[0] = 0}}
journal.indexByMountID = setmetatable({}, metaMounts)


function journal:init()
	self.init = nil

	local lsfdd = LibStub("LibSFDropDown-1.5")
	local texPath = "Interface/AddOns/MountsJournal/textures/"
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
	if mounts.filters.sorting.additionalFirst == nil then
		mounts.filters.sorting.additionalFirst = true
	end
	if mounts.filters.sorting.dragonridingFirst == nil then
		mounts.filters.sorting.dragonridingFirst = true
	end
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
	for spellID, mount in next, mounts.additionalMounts do
		self.mountIDs[#self.mountIDs + 1] = mount
	end

	-- BACKGROUND FRAME
	self.bgFrame = CreateFrame("FRAME", "MountsJournalBackground", self.CollectionsJournal, "MJMountJournalFrameTemplate")
	self.bgFrame:SetPoint("TOPLEFT", self.CollectionsJournal, "TOPLEFT", 0, 0)
	self.bgFrame:SetTitle(MOUNTS)
	self.bgFrame:SetPortraitToAsset("Interface/Icons/MountJournalPortrait")

	local minWidth, minHeight = self.CollectionsJournal:GetSize()
	local maxWidth = UIParent:GetWidth() - self.bgFrame:GetLeft() * 2
	local maxHeight = self.bgFrame:GetTop() - CollectionsJournalTab1:GetHeight()
	local width = max(min(mounts.config.journalWidth or minWidth, maxWidth), minWidth)
	local height = max(min(mounts.config.journalHeight or minHeight, maxHeight), minHeight)
	self.bgFrame:SetSize(width, height)

	self.bgFrame:SetScript("OnShow", function()
		self.CollectionsJournal.NineSlice:Hide()
		self:RegisterEvent("COMPANION_UPDATE")
		self:RegisterEvent("UI_MODEL_SCENE_INFO_UPDATED")
		self:RegisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		self:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "player")
		self:updateCollectionTabs()
		self.leftInset:EnableKeyboard(not InCombatLockdown())
		self:updateMountsList()
		self:updateMountDisplay(true)
		self.mountSpecial:SetEnabled(IsMounted())
	end)

	self.bgFrame:SetScript("OnHide", function()
		self.CollectionsJournal.NineSlice:Show()
		self:UnregisterEvent("COMPANION_UPDATE")
		self:UnregisterEvent("UI_MODEL_SCENE_INFO_UPDATED")
		self:UnregisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")
		self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		self:UnregisterEvent("UNIT_PORTRAIT_UPDATE")
		self:updateCollectionTabs()
		self.mountDisplay:Show()
		self.navBarBtn:SetChecked(false)
		self.mapSettings:Hide()
		self.worldMap:Hide()
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
	self.navBarBtn = self.bgFrame.navBarBtn
	self.navBar = self.bgFrame.navBar
	self.worldMap = self.bgFrame.worldMap
	self.mapSettings = self.bgFrame.mapSettings
	self.existingLists = self.mapSettings.existingLists
	self.filtersPanel = self.bgFrame.filtersPanel
	self.filtersToggle = self.filtersPanel.btnToggle
	self.gridToggleButton = self.filtersPanel.gridToggleButton
	self.searchBox = self.filtersPanel.searchBox
	self.filtersBar = self.filtersPanel.filtersBar
	self.shownPanel = self.bgFrame.shownPanel
	self.leftInset = self.bgFrame.leftInset
	self.mountDisplay = self.bgFrame.mountDisplay
	self.modelScene = self.mountDisplay.modelScene
	self.multipleMountBtn = self.modelScene.multipleMountBtn
	self.mountListUpdateAnim = self.leftInset.updateAnimFrame.anim
	self.scrollBox = self.bgFrame.scrollBox
	self.summonButton = self.bgFrame.summonButton
	self.percentSlider = self.bgFrame.percentSlider
	self.mountSpecial = self.bgFrame.mountSpecial

	-- USE MountsJournal BUTTON
	self.useMountsJournalButton:SetParent(self.CollectionsJournal)
	self.useMountsJournalButton:SetFrameLevel(self.bgFrame:GetFrameLevel() + 10)
	self.useMountsJournalButton:SetScript("OnShow", nil)
	self.useMountsJournalButton:SetScript("OnHide", nil)
	self.useMountsJournalButton:SetPoint("BOTTOMLEFT", self.bgFrame, "BOTTOMLEFT", 281, 2)

	-- SECURE FRAMES
	local sMountJournal = CreateFrame("FRAME", nil, self.MountJournal, "SecureHandlerShowHideTemplate")
	sMountJournal:SetFrameRef("randomButton", self.MountJournal.SummonRandomFavoriteButton)
	sMountJournal:SetFrameRef("useMountsJournalButton", self.useMountsJournalButton)
	sMountJournal:SetFrameRef("bgFrame", self.bgFrame)
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
		if self:GetAttribute("isShow") then
			useMountsJournalButton:Show()
			if self:GetAttribute("useDefaultJournal") then
				randomButton:Show()
				bgFrame:Hide()
				useMountsJournalButton:SetPoint("BOTTOMLEFT", "$parent", "BOTTOMLEFT", 281, 2)
			else
				randomButton:Hide()
				bgFrame:Show()
				useMountsJournalButton:SetPoint("BOTTOMLEFT", bgFrame, "BOTTOMLEFT", 281, 2)
			end
		else
			randomButton:Show()
			useMountsJournalButton:Hide()
			bgFrame:Hide()
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

	-- CLOSE BUTTON
	self.bgFrame.closeButton:SetAttribute("type", "click")
	self.bgFrame.closeButton:SetAttribute("clickbutton", self.CollectionsJournal.CloseButton)

	-- MOUNT COUNT
	self.mountCount.collectedLabel:SetText(L["Collected:"])
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
	summon1:SetNormalTexture(413588)
	summon1.icon = summon1:GetNormalTexture()
	summon1:SetAttribute("clickbutton", _G[config.secureButtonNameMount])
	summon1:SetScript("OnDragStart", function()
		if InCombatLockdown() then return end
		if not GetMacroInfo(config.macroName) then
			config:createMacro(config.macroName, config.secureButtonNameMount, 413588)
		end
		PickupMacro(config.macroName)
	end)
	summon1:SetScript("OnEnter", function(btn)
		GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
		GameTooltip_SetTitle(GameTooltip, addon.." \""..SUMMONS.." 1\"")
		GameTooltip:AddLine(L["Normal mount summon"])
		GameTooltip_AddColoredLine(GameTooltip, "\nMacro: /click "..config.secureButtonNameMount, NIGHT_FAE_BLUE_COLOR, false)
		if InCombatLockdown() then
			GameTooltip_AddErrorLine(GameTooltip, SPELL_FAILED_AFFECTING_COMBAT)
		end
		GameTooltip:Show()
	end)

	local summon2 = self.bgFrame.summon2
	summon2:SetNormalTexture(631718)
	summon2.icon = summon2:GetNormalTexture()
	summon2:SetAttribute("clickbutton", _G[config.secureButtonNameSecondMount])
	summon2:SetScript("OnDragStart", function()
		if InCombatLockdown() then return end
		if not GetMacroInfo(config.secondMacroName) then
			config:createMacro(config.secondMacroName, config.secureButtonNameSecondMount, 631718)
		end
		PickupMacro(config.secondMacroName)
	end)
	summon2:SetScript("OnEnter", function(btn)
		GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
		GameTooltip_SetTitle(GameTooltip, addon.." \""..SUMMONS.." 2\"")
		GameTooltip_AddNormalLine(GameTooltip, L["SecondMountTooltipDescription"]:gsub("\n\n", "\n"))
		GameTooltip_AddColoredLine(GameTooltip, "\nMacro: /click "..config.secureButtonNameSecondMount, NIGHT_FAE_BLUE_COLOR, false)
		if InCombatLockdown() then
			GameTooltip_AddErrorLine(GameTooltip, SPELL_FAILED_AFFECTING_COMBAT)
		end
		GameTooltip:Show()
	end)

	local summon3 = self.bgFrame.summon3
	summon3:SetNormalTexture(132239)
	summon3.icon = summon3:GetNormalTexture()
	summon3:SetAttribute("clickbutton", _G[config.secureButtonNameThirdMount])
	summon3:SetScript("OnDragStart", function()
		if InCombatLockdown() then return end
		if not GetMacroInfo(config.thirdMacroName) then
			config:createMacro(config.thirdMacroName, config.secureButtonNameThirdMount, 132239)
		end
		PickupMacro(config.thirdMacroName)
	end)
	summon3:SetScript("OnEnter", function(btn)
		GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
		GameTooltip_SetTitle(GameTooltip, addon.." \""..SUMMONS.." 3\"")
		GameTooltip_AddNormalLine(GameTooltip, L["ThirdMountTooltipDescription"])
		GameTooltip_AddColoredLine(GameTooltip, "\nMacro: /click "..config.secureButtonNameThirdMount, NIGHT_FAE_BLUE_COLOR, false)
		if InCombatLockdown() then
			GameTooltip_AddErrorLine(GameTooltip, SPELL_FAILED_AFFECTING_COMBAT)
		end
		GameTooltip:Show()
	end)

	-- NAVBAR BUTTON
	self.navBarBtn:HookScript("OnClick", function(btn)
		local checked = btn:GetChecked()
		self.mountDisplay:SetShown(not checked)
		self.worldMap:SetShown(checked)
		self.mapSettings:SetShown(checked)
	end)
	self.navBarBtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -4, -32)
		GameTooltip:SetText(L["Map / Model"])
		GameTooltip:Show()
	end)
	self.navBarBtn:SetScript("OnLeave", function() GameTooltip_Hide() end)

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
	self.mapSettings.Fly = util.createCheckboxChild(L["Regular Flying Mounts Only"], self.mapSettings.Flags)
	self.mapSettings.Fly:HookScript("OnClick", function(check) self:setFlag("regularFlyOnly", check:GetChecked()) end)
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
	ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.bgFrame.scrollBar, self.view)

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
			self.filtersPanel:SetHeight(84)
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

	-- WOWHEAD LINK
	util.setCopyBox(self.mountDisplay.info.link)

	local langButton = self.mountDisplay.info.linkLang
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
			fr = "Français",
			it = "Italiano",
			pt = "Português Brasileiro",
			ru = "Русский",
			ko = "한국어",
			cn = "简体中文",
		}

		local function langSelect(btn)
			mounts.config.wowheadLinkLang = btn.value
			langButton:SetText(btn.value)
			self:updateMountDisplay(true)
		end

		for i, lang in ipairs({"de", "en", "es", "fr", "it", "pt", "ru", "ko", "cn"}) do
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
		{id = 4, path = texPath.."dragonriding", width = 16, height = 16, tooltip = MOUNT_JOURNAL_FILTER_DRAGONRIDING},
		{id = 1, path = texPath.."fly", width = 32, height = 16, tooltip = L["MOUNT_TYPE_1"]},
		{id = 2, path = texPath.."ground", width = 32, height = 16, tooltip = L["MOUNT_TYPE_2"]},
		{id = 3, path = texPath.."swimming", width = 32, height = 16, tooltip = L["MOUNT_TYPE_3"]},
	}

	for i = 1, #typesTextures do
		CreateButtonFilter(i, self.filtersBar.types, 62.5, 25, typesTextures[i])
	end

	-- FILTERS SELECTED BUTTONS
	typesTextures[5] = {id = 5, path = "Interface/BUTTONS/UI-GROUPLOOT-PASS-DOWN", width = 16, height = 16, tooltip = L["MOUNT_TYPE_4"]}
	for i = 1, #typesTextures do
		CreateButtonFilter(i, self.filtersBar.selected, 50, 25, typesTextures[i])
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
	}

	for i = 1, #sourcesTextures do
		local t = sourcesTextures[i]
		t.tooltip = _G["BATTLE_PET_SOURCE_"..t.id]
		CreateButtonFilter(i, self.filtersBar.sources, 25, 25, t)
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

	-- MODEL SCENE MULTIPLE BUTTON
	lsfdd:SetMixin(self.multipleMountBtn)
	self.multipleMountBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	self.multipleMountBtn:ddSetDisplayMode(addon)
	self.multipleMountBtn:ddHideWhenButtonHidden()
	self.multipleMountBtn:ddSetNoGlobalMouseEvent(true)

	self.multipleMountBtn:ddSetInitFunc(function(btn, level)
		local info = {}
		local allCreatureDisplays = C_MountJournal.GetMountAllCreatureDisplayInfoByID(self.selectedMountID)
		local func = function(_, creatureID)
			self:updateMountDisplay(true, creatureID)
		end

		for i = 1, #allCreatureDisplays do
			local creatureID = allCreatureDisplays[i].creatureDisplayID
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
			local allCreatureDisplays, index = C_MountJournal.GetMountAllCreatureDisplayInfoByID(self.selectedMountID)
			for i = 1, #allCreatureDisplays do
				if self.mountDisplay.lastCreatureID == allCreatureDisplays[i].creatureDisplayID then
					index = i
					break
				end
			end
			if index then
				index = Wrap(index + 1, #allCreatureDisplays)
				self:updateMountDisplay(true, allCreatureDisplays[index].creatureDisplayID)
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
			btn:SetAttribute("macrotext", "")
		elseif self.selectedMountID then
			if self.selectedMountID:isActive() then
				btn:SetAttribute("macrotext", "/dismount")
			else
				btn:SetAttribute("macrotext", self.selectedMountID.macro)
			end
		end
	end)

	-- PROFILES
	self:on("UPDATE_PROFILE", function(self, changeProfile)
		mounts:setDB()
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
		parent:SetResizeBounds(minWidth, minHeight, maxWidth, maxHeight)
		parent:StartSizing("BOTTOMRIGHT")
	end)
	resize:SetScript("OnDragStop", function(btn)
		local parent = btn:GetParent()
		parent:StopMovingOrSizing()
		mounts.config.journalWidth, mounts.config.journalHeight = parent:GetSize()
		self:event("JOURNAL_RESIZED")
	end)

	-- SETTINGS BUTTON
	self.bgFrame.btnConfig:SetText(L["Settings"])
	self.bgFrame.btnConfig:SetScript("OnClick", function() config:openConfig() end)

	-- MOUNT SPECIAL
	self.mountSpecial:SetText("!")
	self.mountSpecial.normal = self.mountSpecial:GetFontString()
	self.mountSpecial.normal:ClearAllPoints()
	self.mountSpecial.normal:SetPoint("CENTER")
	self.mountSpecial:SetEnabled(IsMounted())
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
	self.MountJournal.SummonRandomFavoriteButton:Hide()
	self.CollectionsJournal.NineSlice:Hide()
	self:RegisterEvent("COMPANION_UPDATE")
	self:RegisterEvent("UI_MODEL_SCENE_INFO_UPDATED")
	self:RegisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")
	self:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "player")

	self:updateCollectionTabs()
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
	if addonName == "Blizzard_Collections" and select(2, IsAddOnLoaded(addon))
	or addonName == addon and select(2, IsAddOnLoaded("Blizzard_Collections")) then
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
		if not C_MountJournal.IsValidTypeFilter(i) then break end
		backup.types[i] = C_MountJournal.IsTypeChecked(i)
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


function journal:updateCollectionTabs()
	local relativeFrame = self.bgFrame:IsShown() and self.bgFrame or CollectionsJournal
	local tab = CollectionsJournalTab1
	local point, _, rPoint, x, y = tab:GetPoint()
	tab:SetPoint(point, relativeFrame, rPoint, x, y)
end


function journal:COMPANION_UPDATE(companionType)
	if companionType == "MOUNT" then
		self:updateScrollMountList()
		self:updateMountDisplay()
		self.mountSpecial:SetEnabled(not not util.getUnitMount("player"))
	end
end


function journal:getMountInfo(mount)
	-- name, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, _, isForDragonriding
	if type(mount) == "number" then
		return C_MountJournal.GetMountInfoByID(mount)
	else
		return mount.name, mount.spellID, mount.icon, mount:isActive(), mount:isUsable(), 0, mount:getIsFavorite(), false, nil, not mount:isShown(), true, nil, mount.dragonriding
	end
end


function journal:getMountInfoExtra(mount)
	-- expansion, rarity, creatureDisplayID, descriptionText, sourceText, isSelfMount, mountType, modelSceneID, animID, spellVisualKitID, disablePlayerMountPreview
	if type(mount) == "number" then
		return mounts.mountsDB[mount][1], mounts.mountsDB[mount][2], C_MountJournal.GetMountInfoExtraByID(mount)
	else
		return mount.expansion, nil, mount.creatureID, mount.description, mount.sourceText, true, mount.mountType, mount.modelSceneID
	end
end


function journal:setScrollGridMounts(grid)
	local index = self.view:CalculateDataIndices(self.scrollBox)
	local template

	if grid then
		template = "MJMountGrid3ListButtons"
		self.initMountButton = self.grid3InitMountButton
		self.view:SetPadding(0,0,2,0,0)
		index = math.ceil(index / 3)
	else
		template = "MJMountDefaultListButton"
		self.initMountButton = self.defaultInitMountButton
		self.view:SetPadding(0,0,41,25,0)
		index = (index - 1) * 3 + 1
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
	local function setColor(self, btn, checked)
		local color = checked and self.colors.gold or self.colors.gray
		btn.icon:SetVertexColor(color:GetRGB())
		btn:SetChecked(checked)
	end

	function journal:updateMountToggleButton(btn, isForDragonriding)
		if isForDragonriding then
			btn.dragonriding:Show()
			btn.fly:Hide()
			setColor(self, btn.dragonriding, self.list and self.list.dragonriding[btn.spellID])
		else
			btn.dragonriding:Hide()
			btn.fly:Show()
			setColor(self, btn.fly, self.list and self.list.fly[btn.spellID])
		end
		setColor(self, btn.ground, self.list and self.list.ground[btn.spellID])
		setColor(self, btn.swimming, self.list and self.list.swimming[btn.spellID])
	end
end


local function getColorWeight(weight)
	if weight > 50 then
		return ("|cff%02xff00%d%%|r"):format((100 - weight) * 5.1, weight)
	else
		return ("|cffff%02x00%d%%|r"):format(weight * 5.1, weight)
	end
end


local function getQualityColor(mountID)
	local rarity = mounts.mountsDB[mountID][2]
	if rarity > 50 then
		return ITEM_QUALITY_COLORS[1].color
	elseif rarity > 20 then
		return ITEM_QUALITY_COLORS[2].color
	elseif rarity > 10 then
		return ITEM_QUALITY_COLORS[3].color
	elseif rarity > 1 then
		return ITEM_QUALITY_COLORS[4].color
	else
		return ITEM_QUALITY_COLORS[5].color
	end
end


function journal:defaultInitMountButton(btn, data)
	local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, isFiltered, isCollected, _, isForDragonriding = self:getMountInfo(data.mountID)

	local needsFanfare, qualityColor
	if type(data.mountID) == "number" then
		needsFanfare = C_MountJournal.NeedsFanfare(data.mountID)
		qualityColor = getQualityColor(data.mountID)
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
	btn.dragonridingText:SetShown(isForDragonriding)
	btn.new:SetShown(needsFanfare)
	btn.newGlow:SetShown(needsFanfare)
	btn.background:SetVertexColor(1, 1, 1)
	btn.selectedTexture:SetShown(data.mountID == self.selectedMountID)

	local yOffset = 1
	if isForDragonriding then
		yOffset = btn.name:GetNumLines() == 1 and 5 or 6
	end
	btn.name:SetPoint("LEFT", 6, yOffset)

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

	self:updateMountToggleButton(btn, isForDragonriding)
end


function journal:grid3InitMountButton(btn, data)
	for i = 1, #btn.mounts do
		local g3btn = btn.mounts[i]

		if data[i] then
			local mountID = data[i].mountID
			local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, isFiltered, isCollected, _, isForDragonriding = self:getMountInfo(mountID)

			local needsFanfare, qualityColor
			if type(mountID) == "number" then
				needsFanfare = C_MountJournal.NeedsFanfare(mountID)
				qualityColor = getQualityColor(mountID)
			else
				qualityColor = HIGHLIGHT_FONT_COLOR
			end

			g3btn.spellID = spellID
			g3btn.mountID = mountID
			g3btn.active = active
			g3btn.icon:SetTexture(needsFanfare and COLLECTIONS_FANFARE_ICON or icon)
			g3btn.icon:SetVertexColor(1, 1, 1)
			g3btn.qualityBorder:SetVertexColor(qualityColor:GetRGB())
			g3btn:Enable()
			g3btn.selectedTexture:SetShown(mountID == self.selectedMountID)
			g3btn.hidden:SetShown(self:isMountHidden(spellID))
			g3btn.favorite:SetShown(isFavorite)

			local mountWeight = self.mountsWeight[spellID]
			if mountWeight then
				g3btn.mountWeight:SetText(getColorWeight(mountWeight))
				g3btn.mountWeight:Show()
				g3btn.mountWeightBG:Show()
			else
				g3btn.mountWeight:Hide()
				g3btn.mountWeightBG:Hide()
			end

			if isUsable or needsFanfare then
				g3btn.icon:SetDesaturated()
				g3btn.icon:SetAlpha(1)
			elseif isCollected then
				g3btn.icon:SetDesaturated(true)
				-- 150/255, 50/255, 50/255
				g3btn.icon:SetVertexColor(.58823529411765, .19607843137255, .19607843137255)
				g3btn.icon:SetAlpha(.75)
				g3btn.qualityBorder:SetAlpha(.75)
			else
				g3btn.icon:SetDesaturated(true)
				g3btn.icon:SetAlpha(.35)
				g3btn.qualityBorder:SetAlpha(.25)
			end

			self:updateMountToggleButton(g3btn, isForDragonriding)
			g3btn:Show()
		else
			g3btn:Hide()
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
					delta = delta * 3
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
	local fSort, db = mounts.filters.sorting, mounts.mountsDB
	local numNeedingFanfare = C_MountJournal.GetNumMountsNeedingFanfare()

	local mCache = setmetatable({}, {__index = function(t, mount)
		if type(mount) == "number" then
			local name, spellID, _,_,_,_, isFavorite, _,_,_, isCollected, _, isForDragonriding = C_MountJournal.GetMountInfoByID(mount)
			t[mount] = {name, isFavorite, isCollected, isForDragonriding, spellID}
			if numNeedingFanfare > 0 and C_MountJournal.NeedsFanfare(mount) then
				t[mount][6] = true
				numNeedingFanfare = numNeedingFanfare - 1
			end
			if fSort.by == "type" then
				local _,_,_,_, mType = C_MountJournal.GetMountInfoExtraByID(mount)
				mType = self.mountTypes[mType]
				t[mount][8] = type(mType) == "number" and mType or mType[1]
			elseif fSort.by == "expansion" then
				t[mount][8] = db[mount][1]
			elseif fSort.by == "rarity" then
				t[mount][8] = db[mount][2]
			end
		else
			t[mount] = {mount.name, mount:getIsFavorite(), true, mount.dragonriding, mount.spellID, false, true}
			if fSort.by == "type" then
				local mType = self.mountTypes[mount.mountType]
				t[mount][8] = type(mType) == "number" and mType or mType[1]
			elseif fSort.by == "expansion" then
				t[mount][8] = mount.expansion
			elseif fSort.by == "rarity" then
				t[mount][8] = 100
			end
		end
		return t[mount]
	end})

	sort(self.mountIDs, function(a, b)
		if a == b then return false end
		local ma = mCache[a]
		local mb = mCache[b]

		-- FANFARE
		local needFanfareA = ma[6]
		local needFanfareB = mb[6]

		if needFanfareA and not needFanfareB then return true
		elseif not needFanfareA and needFanfareB then return false end

		-- COLLECTED
		local isCollectedA = ma[3]
		local isCollectedB = mb[3]

		if isCollectedA and not isCollectedB then return true
		elseif not isCollectedA and isCollectedB then return false end

		-- FAVORITES
		if fSort.favoritesFirst then
			local isFavoriteA = ma[2]
			local isFavoriteB = mb[2]

			if isFavoriteA and not isFavoriteB then return true
			elseif not isFavoriteA and isFavoriteB then return false end
		end

		-- ADDITIONAL
		if fSort.additionalFirst then
			local isAdditionalA = ma[7]
			local isAdditionalB = mb[7]

			if isAdditionalA and not isAdditionalB then return true
			elseif not isAdditionalA and isAdditionalB then return false end
		end

		-- DRAGONRIDING
		if fSort.dragonridingFirst then
			local isForDragonridingA = ma[4]
			local isForDragonridingB = mb[4]

			if isForDragonridingA and not isForDragonridingB then return true
			elseif not isForDragonridingA and isForDragonridingB then return false end
		end

		-- BY
		if fSort.by ~= "name" then
			local byA = ma[8]
			local byB = mb[8]

			if byA < byB then return not fSort.reverse
			elseif byA > byB then return fSort.reverse end
		end

		-- NAME
		local nameA = ma[1]
		local nameB = mb[1]
		local reverse = fSort.by == "name" and fSort.reverse

		if nameA < nameB then return not reverse
		elseif nameA > nameB then return reverse end

		return ma[5] < mb[5]
	end)

	self:updateMountsList()
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
		dragonriding = {},
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
	for _, value in pairs(list.flags) do
		if value then
			flags = true
			break
		end
	end

	if not (next(list.dragonriding) or next(list.fly) or next(list.ground) or next(list.swimming))
	and not flags
	and not list.listFromID then
		self.zoneMounts[mapID] = nil
		self:setEditMountsList()
	end
end


function journal:mountToggle(btn)
	if not self.list then
		self:createMountList(self.listMapID)
	end
	local tbl = self.list[btn.type]
	local spellID = btn:GetParent().spellID

	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	if tbl[spellID] then
		tbl[spellID] = nil
		btn.icon:SetVertexColor(self.colors.gray:GetRGB())
		self:getRemoveMountList(self.listMapID)
	else
		tbl[spellID] = true
		btn.icon:SetVertexColor(self.colors.gold:GetRGB())
	end

	-- mounts:setMountsList()
	self.existingLists:refresh()
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
		btn:ddToggle(1, btn.maps, btn, 116, 21)
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
	mapSettings.Fly:SetChecked(flags and flags.regularFlyOnly)
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

		if self.mountDisplay.lastMountID ~= self.selectedMountID or forceSceneChange then
			local _, rarity, creatureDisplayID, descriptionText, sourceText, isSelfMount, mountType, modelSceneID, animID, spellVisualKitID, disablePlayerMountPreview = self:getMountInfoExtra(self.selectedMountID)
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
	local info = {}
	info.keepShownOnClick = true
	info.isNotRadio = true

	if level == 1 then
		info.text = COLLECTED
		info.func = function(_,_,_, value)
			mounts.filters.collected = value
			self:updateMountsList()
		end
		info.checked = mounts.filters.collected
		btn:ddAddButton(info, level)

		info.text = NOT_COLLECTED
		info.func = function(_,_,_, value)
			mounts.filters.notCollected = value
			self:updateMountsList()
		end
		info.checked = mounts.filters.notCollected
		btn:ddAddButton(info, level)

		info.text = MOUNT_JOURNAL_FILTER_UNUSABLE
		info.func = function(_,_,_, value)
			mounts.filters.unusable = value
			self:updateMountsList()
		end
		info.checked = mounts.filters.unusable
		btn:ddAddButton(info, level)

		info.text = L["With multiple models"]
		info.func = function(_,_,_, value)
			mounts.filters.multipleModels = value
			self:updateMountsList()
		end
		info.checked = mounts.filters.multipleModels
		btn:ddAddButton(info, level)

		info.text = L["hidden for character"]
		info.func = function(_,_,_, value)
			mounts.filters.hideOnChar = value
			btn:ddRefresh(level)
			self:setCountMounts()
			self:updateMountsList()
		end
		info.checked = mounts.filters.hideOnChar
		btn:ddAddButton(info, level)

		info.indent = 16
		info.disabled = function() return not mounts.filters.hideOnChar end
		info.text = L["only hidden"]
		info.func = function(_,_,_, value)
			mounts.filters.onlyHideOnChar = value
			self:updateMountsList()
		end
		info.checked = mounts.filters.onlyHideOnChar
		btn:ddAddButton(info, level)

		info.indent = nil
		info.disabled = nil
		info.text = L["Hidden by player"]
		info.func = function(_,_,_, value)
			mounts.filters.hiddenByPlayer = value
			btn:ddRefresh(level)
			self:updateMountsList()
		end
		info.checked = mounts.filters.hiddenByPlayer
		btn:ddAddButton(info, level)

		info.indent = 16
		info.disabled = function() return not mounts.filters.hiddenByPlayer end
		info.text = L["only hidden"]
		info.func = function(_,_,_, value)
			mounts.filters.onlyHiddenByPlayer = value
			self:updateMountsList()
		end
		info.checked = mounts.filters.onlyHiddenByPlayer
		btn:ddAddButton(info, level)

		info.indent = nil
		info.disabled = nil
		info.text = L["Only new"]
		info.func = function(_,_,_, value)
			mounts.filters.onlyNew = value
			self:updateMountsList()
		end
		info.checked = mounts.filters.onlyNew
		btn:ddAddButton(info, level)

		btn:ddAddSpace(level)

		info.checked = nil
		info.isNotRadio = nil
		info.func = nil
		info.hasArrow = true
		info.notCheckable = true

		info.text = L["types"]
		info.value = 1
		btn:ddAddButton(info, level)

		info.text = L["selected"]
		info.value = 2
		btn:ddAddButton(info, level)

		info.text = SOURCES
		info.value = 3
		btn:ddAddButton(info, level)

		info.text = L["Specific"]
		info.value = 4
		btn:ddAddButton(info, level)

		info.text = L["factions"]
		info.value = 5
		btn:ddAddButton(info, level)

		info.text = PET
		info.value = 6
		btn:ddAddButton(info, level)

		info.text = L["expansions"]
		info.value = 7
		btn:ddAddButton(info, level)

		info.text = L["Rarity"]
		info.value = 8
		btn:ddAddButton(info, level)

		info.text = L["Chance of summoning"]
		info.value = 9
		btn:ddAddButton(info, level)

		info.text = L["tags"]
		info.value = 10
		btn:ddAddButton(info, level)

		btn:ddAddSpace(level)

		info.text = L["sorting"]
		info.value = 11
		btn:ddAddButton(info, level)

		btn:ddAddSpace(level)

		info.keepShownOnClick = nil
		info.hasArrow = nil
		info.text = RESET
		info.func = function() self:resetToDefaultFilters() end
		btn:ddAddButton(info, level)

		info.text = L["Set current filters as default"]
		info.func = function() self:saveDefaultFilters() end
		btn:ddAddButton(info, level)

		info.text = L["Restore default filters"]
		info.func = function() self:restoreDefaultFilters() end
		btn:ddAddButton(info, level)
	else
		info.notCheckable = true

		if value == 1 then -- TYPES
			info.text = CHECK_ALL
			info.func = function()
				self:setAllFilters("types", true)
				self:updateBtnFilters()
				self:updateMountsList()
				btn:ddRefresh(level)
			end
			btn:ddAddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				self:setAllFilters("types", false)
				self:updateBtnFilters()
				self:updateMountsList()
				btn:ddRefresh(level)
			end
			btn:ddAddButton(info, level)

			info.notCheckable = nil
			local types = mounts.filters.types

			info.text = MOUNT_JOURNAL_FILTER_DRAGONRIDING
			info.func = function(_,_,_, value)
				types[4] = value
				self:updateBtnFilters()
				self:updateMountsList()
			end
			info.checked = function() return types[4] end
			btn:ddAddButton(info, level)

			for i = 1, 3 do
				info.text = L["MOUNT_TYPE_"..i]
				info.func = function(_,_,_, value)
					types[i] = value
					self:updateBtnFilters()
					self:updateMountsList()
				end
				info.checked = function() return types[i] end
				btn:ddAddButton(info, level)
			end
		elseif value == 2 then -- SELECTED
			info.text = CHECK_ALL
			info.func = function()
				self:setAllFilters("selected", true)
				self:updateBtnFilters()
				self:updateMountsList()
				btn:ddRefresh(level)
			end
			btn:ddAddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				self:setAllFilters("selected", false)
				self:updateBtnFilters()
				self:updateMountsList()
				btn:ddRefresh(level)
			end
			btn:ddAddButton(info, level)

			info.notCheckable = nil
			local selected = mounts.filters.selected

			info.text = MOUNT_JOURNAL_FILTER_DRAGONRIDING
			info.func = function(_,_,_, value)
				selected[4] = value
				self:updateBtnFilters()
				self:updateMountsList()
			end
			info.checked = function() return selected[4] end
			btn:ddAddButton(info, level)

			for i = 1, 3 do
				info.text = L["MOUNT_TYPE_"..i]
				info.func = function(_,_,_, value)
					selected[i] = value
					self:updateBtnFilters()
					self:updateMountsList()
				end
				info.checked = function() return selected[i] end
				btn:ddAddButton(info, level)
			end

			info.text = L["MOUNT_TYPE_4"]
			info.func = function(_,_,_, value)
				selected[5] = value
				self:updateBtnFilters()
				self:updateMountsList()
			end
			info.checked = function() return selected[5] end
			btn:ddAddButton(info, level)
		elseif value == 3 then -- SOURCES
			info.text = CHECK_ALL
			info.func = function()
				self:setAllFilters("sources", true)
				self:updateBtnFilters()
				self:updateMountsList()
				btn:ddRefresh(level)
			end
			btn:ddAddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				self:setAllFilters("sources", false)
				self:updateBtnFilters()
				self:updateMountsList()
				btn:ddRefresh(level)
			end
			btn:ddAddButton(info, level)

			info.notCheckable = nil
			local sources = mounts.filters.sources
			for i = 1, C_PetJournal.GetNumPetSources() do
				if C_MountJournal.IsValidSourceFilter(i) then
					info.text = _G["BATTLE_PET_SOURCE_"..i]
					info.func = function(_,_,_, value)
						sources[i] = value
						self:updateBtnFilters()
						self:updateMountsList()
					end
					info.checked = function() return sources[i] end
					btn:ddAddButton(info, level)
				end
			end
		elseif value == 4 then -- SPECIFIC
			info.text = CHECK_ALL
			info.func = function()
				self:setAllFilters("specific", true)
				self:updateMountsList()
				btn:ddRefresh(level)
			end
			btn:ddAddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				self:setAllFilters("specific", false)
				self:updateMountsList()
				btn:ddRefresh(level)
			end
			btn:ddAddButton(info, level)

			info.notCheckable = nil
			local specific = mounts.filters.specific

			for k, t in pairs(mounts.specificDB) do
				info.text = L[k]
				info.func = function(_,_,_, value)
					specific[k] = value
					self:updateMountsList()
				end
				info.checked = function() return specific[k] end
				btn:ddAddButton(info, level)
			end

			info.text = L["transform"]
			info.func = function(_,_,_, value)
				specific.transform = value
				self:updateMountsList()
			end
			info.checked = function() return specific.transform end
			btn:ddAddButton(info, level)

			info.text = L["additional"]
			info.func = function(_,_,_, value)
				specific.additional = value
				self:updateMountsList()
			end
			info.checked = function() return specific.additional end
			btn:ddAddButton(info, level)

			info.text = L["rest"]
			info.func = function(_,_,_, value)
				specific.rest = value
				self:updateMountsList()
			end
			info.checked = function() return specific.rest end
			btn:ddAddButton(info, level)
		elseif value == 5 then -- FACTIONS
			info.text = CHECK_ALL
			info.func = function()
				self:setAllFilters("factions", true)
				self:updateMountsList()
				btn:ddRefresh(level)
			end
			btn:ddAddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				self:setAllFilters("factions", false)
				self:updateMountsList()
				btn:ddRefresh(level)
			end
			btn:ddAddButton(info, level)

			info.notCheckable = nil
			local factions = mounts.filters.factions
			for i = 1, 3 do
				info.text = L["MOUNT_FACTION_"..i]
				info.func = function(_,_,_, value)
					factions[i] = value
					self:updateMountsList()
				end
				info.checked = function() return factions[i] end
				btn:ddAddButton(info, level)
			end
		elseif value == 6 then -- PET
			info.text = CHECK_ALL
			info.func = function()
				self:setAllFilters("pet", true)
				self:updateMountsList()
				btn:ddRefresh(level)
			end
			btn:ddAddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				self:setAllFilters("pet", false)
				self:updateMountsList()
				btn:ddRefresh(level)
			end
			btn:ddAddButton(info, level)

			info.notCheckable = nil
			local pet = mounts.filters.pet
			for i = 1, 4 do
				info.text = L["PET_"..i]
				info.func = function(_,_,_, value)
					pet[i] = value
					self:updateMountsList()
				end
				info.checked = function() return pet[i] end
				btn:ddAddButton(info, level)
			end
		elseif value == 7 then -- EXPANSIONS
			info.text = CHECK_ALL
			info.func = function()
				self:setAllFilters("expansions", true)
				self:updateMountsList()
				btn:ddRefresh(level)
			end
			btn:ddAddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				self:setAllFilters("expansions", false)
				self:updateMountsList()
				btn:ddRefresh(level)
			end
			btn:ddAddButton(info, level)

			info.notCheckable = nil
			local expansions = mounts.filters.expansions
			for i = 1, util.expansion do
				info.text = _G["EXPANSION_NAME"..(i - 1)]
				info.func = function(_,_,_, value)
					expansions[i] = value
					self:updateMountsList()
				end
				info.checked = function() return expansions[i] end
				btn:ddAddButton(info, level)
			end
		elseif value == 8 then -- RARITY
			local filterRarity = mounts.filters.mountsRarity

			info.notCheckable = nil
			info.isNotRadio = nil

			info.text = L["Any"]
			info.func = function(button)
				filterRarity.sign = button.value
				btn:ddRefresh(level)
				self:updateMountsList()
			end
			info.checked = function() return not filterRarity.sign end
			btn:ddAddButton(info, level)

			info.text = L["> (more than)"]
			info.value = ">"
			info.checked = function() return filterRarity.sign == ">" end
			btn:ddAddButton(info, level)

			info.text = L["< (less than)"]
			info.value = "<"
			info.checked = function() return filterRarity.sign == "<" end
			btn:ddAddButton(info, level)

			info.text = L["= (equal to)"]
			info.value = "="
			info.checked = function() return filterRarity.sign == "=" end
			btn:ddAddButton(info, level)

			info.text = nil
			info.value = nil
			info.func = nil
			info.checked = nil
			info.customFrame = self.percentSlider
			info.customFrame:setText(L["Rarity"])
			info.customFrame:setMinMax(0, 100)
			info.OnLoad = function(frame)
				frame.level = level + 1
				frame:setValue(filterRarity.value)
				frame.setFunc = function(value)
					if filterRarity.value ~= value then
						filterRarity.value = value
					end
				end
			end
			btn:ddAddButton(info, level)
		elseif value == 9 then -- CHANCE OF SUMMONING
			local filterWeight = mounts.filters.mountsWeight

			info.notCheckable = nil
			info.isNotRadio = nil

			info.text = L["Any"]
			info.func = function(button)
				filterWeight.sign = button.value
				btn:ddRefresh(level)
				self:updateMountsList()
			end
			info.checked = function() return not filterWeight.sign end
			btn:ddAddButton(info, level)

			info.text = L["> (more than)"]
			info.value = ">"
			info.checked = function() return filterWeight.sign == ">" end
			btn:ddAddButton(info, level)

			info.text = L["< (less than)"]
			info.value = "<"
			info.checked = function() return filterWeight.sign == "<" end
			btn:ddAddButton(info, level)

			info.text = L["= (equal to)"]
			info.value = "="
			info.checked = function() return filterWeight.sign == "=" end
			btn:ddAddButton(info, level)

			info.text = nil
			info.value = nil
			info.func = nil
			info.checked = nil
			info.customFrame = self.percentSlider
			info.customFrame:setText(L["Chance of summoning"])
			info.customFrame:setMinMax(1, 100)
			info.OnLoad = function(frame)
				frame.level = level + 1
				frame:setValue(filterWeight.weight)
				frame.setFunc = function(value)
					if filterWeight.weight ~= value then
						filterWeight.weight = value
					end
				end
			end
			btn:ddAddButton(info, level)
		elseif value == 10 then -- TAGS
			local filterTags = self.tags.filter

			info.notCheckable = nil
			info.text = L["No tag"]
			info.func = function(_,_,_, value)
				filterTags.noTag = value
				self:updateMountsList()
			end
			info.checked = function() return filterTags.noTag end
			btn:ddAddButton(info, level)

			info.text = L["With all tags"]
			info.func = function(_,_,_, value)
				filterTags.withAllTags = value
				self:updateMountsList()
			end
			info.checked = function() return filterTags.withAllTags end
			btn:ddAddButton(info, level)

			btn:ddAddSeparator(level)

			info.notCheckable = true
			info.text = CHECK_ALL
			info.func = function()
				self.tags:setAllFilterTags(true)
				self:updateMountsList()
				btn:ddRefresh(level)
			end
			btn:ddAddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				self.tags:setAllFilterTags(false)
				self:updateMountsList()
				btn:ddRefresh(level)
			end
			btn:ddAddButton(info, level)

			info.func = nil
			if #self.tags.sortedTags == 0 then
				info.disabled = true
				info.text = EMPTY
				btn:ddAddButton(info, level)
				info.disabled = nil
			else
				info.list = {}
				for i, tag in ipairs(self.tags.sortedTags) do
					info.list[i] = {
						keepShownOnClick = true,
						isNotRadio = true,
						text = function() return self.tags.sortedTags[i] end,
						func = function(btn, _,_, value)
							filterTags.tags[btn._text][2] = value
							self:updateMountsList()
						end,
						checked = function(btn) return filterTags.tags[btn._text][2] end,
						remove = function(btn)
							self.tags:deleteTag(btn._text)
						end,
						order = function(btn, step)
							self.tags:setOrderTag(btn._text, step)
						end,
					}
				end
				btn:ddAddButton(info, level)
				info.list = nil
			end

			btn:ddAddSeparator(level)

			info.keepShownOnClick = nil
			info.notCheckable = true
			info.checked = nil

			info.text = L["Add tag"]
			info.func = function()
				self.tags:addTag()
			end
			btn:ddAddButton(info, level)
		else -- SORTING
			local fSort = mounts.filters.sorting
			info.isNotRadio = nil
			info.notCheckable = nil

			info.text = NAME
			info.func = function()
				fSort.by = "name"
				self:sortMounts()
				btn:ddRefresh(level)
			end
			info.checked = function() return fSort.by == "name" end
			btn:ddAddButton(info, level)

			info.text = TYPE
			info.func = function()
				fSort.by = "type"
				self:sortMounts()
				btn:ddRefresh(level)
			end
			info.checked = function() return fSort.by == "type" end
			btn:ddAddButton(info, level)

			info.text = EXPANSION_FILTER_TEXT
			info.func = function()
				fSort.by = "expansion"
				self:sortMounts()
				btn:ddRefresh(level)
			end
			info.checked = function() return fSort.by == "expansion" end
			btn:ddAddButton(info, level)

			info.text = L["Rarity"]
			info.func = function()
				fSort.by = "rarity"
				self:sortMounts()
				btn:ddRefresh(level)
			end
			info.checked = function() return fSort.by == "rarity" end
			btn:ddAddButton(info, level)

			btn:ddAddSeparator(level)

			info.isNotRadio = true
			info.text = L["Reverse Sort"]
			info.func = function(_,_,_, value)
				fSort.reverse = value
				self:sortMounts()
			end
			info.checked = fSort.reverse
			btn:ddAddButton(info, level)

			info.text = L["Favorites First"]
			info.func = function(_,_,_, value)
				fSort.favoritesFirst = value
				self:sortMounts()
			end
			info.checked = fSort.favoritesFirst
			btn:ddAddButton(info, level)

			info.text = L["Additional First"]
			info.func = function(_,_,_, value)
				fSort.additionalFirst = value
				self:sortMounts()
			end
			info.checked = fSort.additionalFirst
			btn:ddAddButton(info, level)

			info.text = L["Dragonriding First"]
			info.func = function(_,_,_, value)
				fSort.dragonridingFirst = value
				self:sortMounts()
			end
			info.checked = fSort.dragonridingFirst
			btn:ddAddButton(info, level)
		end
	end
end


function journal:saveDefaultFilters()
	local filters = mounts.filters
	local defFilters = mounts.defFilters

	defFilters.collected = filters.collected
	defFilters.notCollected = filters.notCollected
	defFilters.unusable = filters.unusable
	defFilters.multipleModels = filters.multipleModels
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
	defFilters.multipleModels = false
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
	if not defFilters.multipleModels ~= not filters.multipleModels then add(L["With multiple models"]) end
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
	filters.multipleModels = defFilters.multipleModels
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
					if btn.id > 4 then
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
					if btn.id > 4 then
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
		if list.dragonriding[spellID] then if filter[4] then return true end
		else i = i + 1 end
		return i == 4 and filter[5]
	else
		return filter[5]
	end
end


function journal:getFilterSpecific(spellID, isSelfMount)
	local filter = mounts.filters.specific
	local i = 0
	if isSelfMount then if filter.transform then return true end
	else i = i + 1 end
	if mounts.additionalMounts[spellID] then if filter.additional then return true end
	else i = i + 1 end
	for k, t in pairs(mounts.specificDB) do
		if t[spellID] then if filter[k] then return true end
		else i = i + 1 end
	end
	return i == 4 and filter.rest
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
	local filters, list, newMounts, tags = mounts.filters, self.list, mounts.newMounts, self.tags
	local sources, factions, pet, expansions = filters.sources, filters.factions, filters.pet, filters.expansions
	local text = util.cleanText(self.searchBox:GetText())
	local numMounts, data = 0
	self.dataProvider = CreateDataProvider()

	for i = 1, #self.mountIDs do
		local mountID = self.mountIDs[i]
		local name, spellID, _,_, isUsable, sourceType, _,_, mountFaction, shouldHideOnChar, isCollected = self:getMountInfo(mountID)
		local expansion, rarity, _,_, sourceText, isSelfMount, mountType = self:getMountInfoExtra(mountID)
		local petID = self.petForMount[spellID]
		local isMountHidden = self:isMountHidden(spellID)

		-- HIDDEN FOR CHARACTER
		if (not shouldHideOnChar or filters.hideOnChar)
		and (not (filters.hideOnChar and filters.onlyHideOnChar) or shouldHideOnChar)
		-- HIDDEN BY PLAYER
		and (not isMountHidden or filters.hiddenByPlayer)
		and (not (filters.hiddenByPlayer and filters.onlyHiddenByPlayer) or isMountHidden)
		-- COLLECTED
		and (isCollected and filters.collected or not isCollected and filters.notCollected)
		-- UNUSABLE
		and (isUsable or not isCollected or filters.unusable)
		-- MUTIPLE MODELS
		and (not filters.multipleModels or self.mountsWithMultipleModels[mountID])
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
		and self:getFilterSpecific(spellID, isSelfMount)
		-- MOUNTS RARITY
		and self:getFilterRarity(rarity or 100)
		-- MOUNTS WEIGHT
		and self:getFilterWeight(spellID)
		-- TAGS
		and tags:getFilterMount(spellID) then
			numMounts = numMounts + 1
			local mountData = {index = numMounts, mountID = mountID}

			if mounts.config.gridToggle then
				if data and #data < 3 then
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