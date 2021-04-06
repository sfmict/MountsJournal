local addon, L = ...
local C_MountJournal, C_PetJournal, C_Timer, wipe, tinsert, next, pairs, ipairs, select, type, sort = C_MountJournal, C_PetJournal, C_Timer, wipe, tinsert, next, pairs, ipairs, select, type, sort
local util, mounts, config = MountsJournalUtil, MountsJournal, MountsJournalConfig
local journal = CreateFrame("FRAME", "MountsJournalFrame")
journal.mountTypes = util.mountTypes
util:setEventsMixin(journal)


local COLLECTION_ACHIEVEMENT_CATEGORY = 15246
local MOUNT_ACHIEVEMENT_CATEGORY = 15248


journal.colors = {
	gold = CreateColor(.8, .6, 0),
	gray = CreateColor(.5, .5, .5),
	dark = CreateColor(.3, .3, .3),
	mount1 = CreateColor(.824, .78, .235),
	mount2 = CreateColor(.42, .302, .224),
	mount3 = CreateColor(.031, .333, .388),
}


local metaMounts = {__index = {[0] = 0}}
journal.displayedMounts = setmetatable({}, metaMounts)
journal.indexByMountID = setmetatable({}, metaMounts)


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
	local contents = {}

	for i = 1, select("#", ...) do
		local tab = CreateFrame("BUTTON", nil, frame, "MJTabTemplate")
		tab.id = select(i, ...)

		if i == 1 then
			tab:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 4, -4)
		else
			tab:SetPoint("LEFT", frame.tabs[i - 1], "RIGHT", -5, 0)
		end

		tab.text:SetText(L[select(i, ...)])
		tab.content:SetPoint("TOPLEFT", frame, "TOPLEFT")
		tab.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
		tab:SetScript("OnClick", tabClick)

		tinsert(frame.tabs, tab)
		tinsert(contents, tab.content)
	end

	if #frame.tabs ~= 0 then
		tabClick(frame.tabs[1])
	end

	return unpack(contents)
end


journal:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
journal:RegisterEvent("ADDON_LOADED")


function journal:ADDON_LOADED(addonName)
	if addonName == "Blizzard_Collections" and select(2, IsAddOnLoaded(addon))
	or addonName == addon and select(2, IsAddOnLoaded("Blizzard_Collections")) then
		self:UnregisterEvent("ADDON_LOADED")

		local function void() end
		local function disableMethods(frame)
			frame.SetSize = void
			frame.SetWidth = void
			frame.SetHeight = void
			frame.ClearAllPoints = void
			frame.SetPoint = void
		end

		self.searchText = ""
		local texPath = "Interface/AddOns/MountsJournal/textures/"
		self.MountJournal = MountJournal
		local mountDisplay = self.MountJournal.MountDisplay
		self.modelScene = mountDisplay.ModelScene
		self.mountIDs = C_MountJournal.GetMountIDs()
		self.searchBox = self.MountJournal.searchBox
		self.scrollFrame = self.MountJournal.ListScrollFrame
		self.scrollButtons = self.scrollFrame.buttons
		self.leftInset = self.MountJournal.LeftInset
		self.rightInset = self.MountJournal.RightInset

		-- FILTERS INIT
		if mounts.filters.collected == nil then mounts.filters.collected = true end
		if mounts.filters.notCollected == nil then mounts.filters.notCollected = true end
		if mounts.filters.unusable == nil then mounts.filters.unusable = true end
		local filtersMeta = {__index = function(self, key)
			self[key] = true
			return self[key]
		end}
		mounts.filters.types = setmetatable(mounts.filters.types or {}, filtersMeta)
		mounts.filters.selected = setmetatable(mounts.filters.selected or {}, {__index = function(self, key)
			self[key] = false
			return self[key]
		end})
		mounts.filters.sources = setmetatable(mounts.filters.sources or {}, filtersMeta)
		mounts.filters.factions = setmetatable(mounts.filters.factions or {}, filtersMeta)
		mounts.filters.pet = setmetatable(mounts.filters.pet or {}, filtersMeta)
		mounts.filters.expansions = setmetatable(mounts.filters.expansions or {}, filtersMeta)
		mounts.filters.tags = mounts.filters.tags or {
			noTag = true,
			withAllTags = false,
			tags = {},
		}
		mounts.filters.sorting = mounts.filters.sorting or {
			by = "name",
			favoritesFirst = true,
		}

		self.MountJournal:UnregisterEvent("MOUNT_JOURNAL_SEARCH_UPDATED")
		self.MountJournal:UnregisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")
		self:RegisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")

		-- FILTERS BUTTON
		local filtersButton = MountJournalFilterButton
		util.setMixin(filtersButton, MJDropDownButtonMixin)
		filtersButton.MJNoGlobalMouseEvent = true
		filtersButton:SetScript("OnHide", filtersButton.onHide)
		filtersButton:ddSetInit(function(...) self:filterDropDown_Initialize(...) end, "menu")
		filtersButton:SetScript("OnMouseDown", UIMenuButtonStretchMixin.OnMouseDown)
		filtersButton:SetScript("OnClick", function(self)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			self:dropDownToggle(1, nil, self, 74, 15)
		end)

		-- MOUNT LIST UPDATE ANIMATION
		self.leftInset.updateAnimFrame = CreateFrame("FRAME", nil, self.leftInset, "MJUpdateAnimFrame")
		self.mountListUpdateAnim = self.leftInset.updateAnimFrame.anim

		-- MOUNT COUNT
		local mountCount = self.MountJournal.MountCount
		self.mountCount = mountCount
		mountCount:SetPoint("TOPLEFT", 70, -25)
		mountCount:SetHeight(34)
		mountCount.Count:SetPoint("RIGHT", -10, 6)
		mountCount.Label:SetPoint("LEFT", 10, 6)
		mountCount.collected = mountCount:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		mountCount.collected:SetPoint("RIGHT", -10, -6)
		mountCount.collectedLabel = mountCount:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		mountCount.collectedLabel:SetPoint("LEFT", 10, -6)
		mountCount.collectedLabel:SetText(L["Collected:"])

		self:setCountMounts()
		self:RegisterEvent("COMPANION_LEARNED")
		self:RegisterEvent("COMPANION_UNLEARNED")

		-- MOUNT EQUIPMENT
		self.MountJournal.BottomLeftInset:Hide()
		local slotButton = self.MountJournal.BottomLeftInset.SlotButton
		slotButton:SetParent(self.MountJournal)
		slotButton:SetPoint("LEFT", self.mountCount, "RIGHT", 4, 0)
		slotButton:SetScale(.65)
		hooksecurefunc("MountJournal_UpdateEquipmentPalette", function()
			local effectsSuppressed = C_MountJournal.AreMountEquipmentEffectsSuppressed()
			local locked = not C_PlayerInfo.CanPlayerUseMountEquipment()
			slotButton:DesaturateHierarchy((effectsSuppressed or locked) and 1 or 0)
		end)
		self.leftInset:SetPoint("BOTTOMLEFT", self.MountJournal, "BOTTOMLEFT", 0, 26)
		HybridScrollFrame_CreateButtons(self.scrollFrame, "MountListButtonTemplate", 44, 0)
		self.rightInset:SetPoint("BOTTOMLEFT", self.leftInset, "BOTTOMRIGHT", 20, 0)

		-- NAVBAR BUTTON
		local navBarBtn = CreateFrame("CheckButton", nil, self.MountJournal, "MJMiniMapBtnTemplate")
		self.navBarBtn = navBarBtn
		navBarBtn:SetPoint("TOPRIGHT", -2, -60)
		navBarBtn:HookScript("OnClick", function(btn)
			local checked = btn:GetChecked()
			mountDisplay:SetShown(not checked)
			self.worldMap:SetShown(checked)
			self.mapSettings:SetShown(checked)
		end)
		navBarBtn:SetScript("OnEnter", function()
			GameTooltip:SetOwner(navBarBtn, "ANCHOR_RIGHT", -4, -32)
			GameTooltip:SetText(L["Map / Model"])
			GameTooltip:Show()
		end)
		navBarBtn:SetScript("OnLeave", function() GameTooltip_Hide() end)

		-- NAVBAR
		local navBar = CreateFrame("FRAME", nil, self.MountJournal, "MJNavBarTemplate")
		self.navBar = navBar
		navBar:SetPoint("TOPLEFT", 8, -60)
		navBar:SetPoint("TOPRIGHT", navBarBtn, "TOPLEFT", 0, 0)
		navBar:on("MAP_CHANGE", function()
			self:setEditMountsList()
			self:updateMountsList()
			self:updateMapSettings()

			self.mountListUpdateAnim:Stop()
			self.mountListUpdateAnim:Play()
		end)
		self.rightInset:SetPoint("TOPRIGHT", navBarBtn, "BOTTOMRIGHT", -4, 0)

		-- WORDL MAP
		local worldMap = CreateFrame("FRAME", nil, self.MountJournal, "MJMapTemplate")
		self.worldMap = worldMap
		worldMap:SetPoint("TOPLEFT", self.rightInset)
		worldMap:SetPoint("TOPRIGHT", self.rightInset)

		-- MAP SETTINGS
		local mapSettings = CreateFrame("FRAME", nil, self.MountJournal, "MJMapSettingsTemplate")
		self.mapSettings = mapSettings
		mapSettings:SetPoint("TOPLEFT", worldMap, "BOTTOMLEFT", 0, -30)
		mapSettings:SetPoint("BOTTOMRIGHT", self.rightInset)
		mapSettings:SetScript("OnShow", function() self:updateMapSettings() end)
		mapSettings.dungeonRaidBtn:SetText(L["Dungeons and Raids"])
		mapSettings.CurrentMap:SetText(L["Current Location"])
		mapSettings.CurrentMap:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			navBar:setCurrentMap()
		end)
		mapSettings.hint.tooltip = L["ZoneSettingsTooltip"]
		mapSettings.hint.tooltipDescription = L["ZoneSettingsTooltipDescription"]
		mapSettings.Flags.Text:SetText(L["Enable Flags"])
		mapSettings.Flags:HookScript("OnClick", function(check) self:setFlag("enableFlags", check:GetChecked()) end)
		mapSettings.Ground = util.createCheckboxChild(L["Ground Mounts Only"], mapSettings.Flags)
		mapSettings.Ground:HookScript("OnClick", function(check) self:setFlag("groundOnly", check:GetChecked()) end)
		mapSettings.WaterWalk = util.createCheckboxChild(L["Water Walking"], mapSettings.Flags)
		mapSettings.WaterWalk.tooltipText = L["Water Walking"]
		mapSettings.WaterWalk.tooltipRequirement = L["WaterWalkFlagDescription"]
		mapSettings.WaterWalk:HookScript("OnClick", function(check) self:setFlag("waterWalkOnly", check:GetChecked()) end)
		mapSettings.HerbGathering = util.createCheckboxChild(L["Herb Gathering"], mapSettings.Flags)
		mapSettings.HerbGathering.tooltipText = L["Herb Gathering"]
		mapSettings.HerbGathering.tooltipRequirement = L["HerbGatheringFlagDescription"]
		mapSettings.HerbGathering:HookScript("OnClick", function(check) self:setFlag("herbGathering", check:GetChecked()) end)
		mapSettings.listFromMap.Text:SetText(L["ListMountsFromZone"])
		mapSettings.listFromMap.maps = {}
		mapSettings.listFromMap:SetScript("OnClick", function(btn) self:listFromMapClick(btn) end)
		mapSettings.listFromMap:ddSetInit(self.listFromMapInit, "menu")
		mapSettings.relationClear:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			self.currentList.listFromID = nil
			self:getRemoveMountList(self.navBar.mapID)
			self:setEditMountsList()
			self:updateMountsList()
			self:updateMapSettings()
			mounts:setMountsList()
			self.existingLists:refresh()

			self.mountListUpdateAnim:Stop()
			self.mountListUpdateAnim:Play()
		end)

		-- EXISTING LISTS TOGGLE
		mapSettings.existingListsToggle:HookScript("OnClick", function(btn)
			self.existingLists:SetShown(btn:GetChecked())
		end)

		-- EXISTING LISTS
		self.existingLists = CreateFrame("FRAME", nil, mapSettings, "MJExistingListsPanelTemplate")
		self.existingLists:SetPoint("TOPLEFT", self.MountJournal, "TOPRIGHT")
		self.existingLists:SetPoint("BOTTOMLEFT", self.MountJournal, "BOTTOMRIGHT")

		--MOUNTJOURNAL ONSHOW
		self.MountJournal:HookScript("OnShow", function()
			navBarBtn:SetChecked(false)
			mountDisplay:Show()
			self.mapSettings:Hide()
			self.worldMap:Hide()
			util.showHelpJournal()
		end)

		-- SETTINGS BUTTON
		self.btnConfig = CreateFrame("BUTTON", "MountsJournalBtnConfig", self.MountJournal, "UIPanelButtonTemplate")
		self.btnConfig:SetSize(80, 22)
		self.btnConfig:SetPoint("BOTTOMRIGHT", -6, 4)
		self.btnConfig:SetText(L["Settings"])
		self.btnConfig:SetScript("OnClick", function() config:openConfig() end)

		-- ACHIEVEMENT
		self.achiev = CreateFrame("BUTTON", nil, self.MountJournal, "MJAchiev")
		self.achiev:SetPoint("TOP", 0, -21)
		self:ACHIEVEMENT_EARNED()
		self.achiev:SetScript("OnClick", function()
			ToggleAchievementFrame()
			local i = 1
			local button = _G["AchievementFrameCategoriesContainerButton"..i]
			while button do
				if button.categoryID == COLLECTION_ACHIEVEMENT_CATEGORY then
					button:Click()
				elseif button.categoryID == MOUNT_ACHIEVEMENT_CATEGORY then
					button:Click()
					return
				end
				i = i + 1
				button = _G["AchievementFrameCategoriesContainerButton"..i]
			end
		end)
		self:RegisterEvent("ACHIEVEMENT_EARNED")

		-- PROFILES
		self.profilesMenu = CreateFrame("Button", nil, self.MountJournal, "MJMenuButtonProfiles")
		self.profilesMenu:SetPoint("LEFT", self.MountJournal.MountButton, "RIGHT", 6, 0)
		self.profilesMenu:on("UPDATE_PROFILE", function(_, changeProfile)
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

		-- SELECTED BUTTONS
		function MountJournal_GetMountButtonByMountID(mountID)
			local buttons = self.scrollFrame.buttons
			for i = 1, #buttons do
				local button = buttons[i]
				if mounts.config.gridToggle then
					for j = 1, 3 do
						local grid3Button = button.grid3list["mount"..j]
						if grid3Button.mountID == mountID then
							return grid3Button
						end
					end
				else
					if button.mountID == mountID then
						return button
					end
				end
			end
		end

		function MountJournal_SetSelected(mountID, spellID, button)
			MountJournal.selectedMountID = mountID
			MountJournal.selectedSpellID = spellID
			MountJournal_UpdateMountList()
			MountJournal_UpdateMountDisplay()

			if not button then
				button = MountJournal_GetMountButtonByMountID(mountID)
			end
			if not button or self.scrollFrame:GetBottom() >= button:GetTop() then
				local index
				for i = 1, #self.displayedMounts do
					if mountID == self.displayedMounts[i] then
						index = i
						break
					end
				end
				if index then
					if mounts.config.gridToggle then index = math.ceil(index / 3) end
					HybridScrollFrame_ScrollToIndex(self.scrollFrame, index, MountJournal_GetMountButtonHeight)
				end
			end

			self:event("MOUNT_SELECT", mountID)
		end

		local function typeClick(btn) self:mountToggle(btn) end
		local function grid3Click(btn, mouse) self.tags:listItemClick(btn:GetParent(), mouse) end
		local function btnClick(btn, mouse) self.tags:listItemClick(btn, mouse) end
		local function dragClick(btn, mouse) self.tags:dragButtonClick(btn, mouse) end

		local function CreateButtonMountToggle(name, parent, pointX, pointY)
			local btnFrame = CreateFrame("CheckButton", nil, parent, "MJSetMountToggleTemplate")
			btnFrame:SetPoint("TOPRIGHT", pointX, pointY)
			btnFrame:SetScript("OnClick", typeClick)
			btnFrame.type = name
			parent[name] = btnFrame
			btnFrame.icon:SetTexture(texPath..name)
		end

		for _, child in ipairs(self.scrollButtons) do
			child:SetWidth(child:GetWidth() - 25)
			disableMethods(child)
			child.name:SetWidth(child.name:GetWidth() - 18)
			child.icon:SetPoint("LEFT", child, "LEFT", -41, 0)
			child.icon:SetSize(40, 40)

			CreateButtonMountToggle("fly", child, 25, -3)
			CreateButtonMountToggle("ground", child, 25, -17)
			CreateButtonMountToggle("swimming", child, 25, -31)

			child.grid3list = CreateFrame("BUTTON", nil, child, "MJGrid3MountListButtonTemplate")
			child.grid3list:SetPoint("LEFT", -41, 0)
			for i = 1, 3 do
				local btn = child.grid3list["mount"..i]
				btn.fly:SetScript("OnClick", typeClick)
				btn.ground:SetScript("OnClick", typeClick)
				btn.swimming:SetScript("OnClick", typeClick)
				btn.DragButton:SetScript("OnClick", grid3Click)
			end

			child:SetScript("OnClick", btnClick)
			child.DragButton:SetScript("OnClick", dragClick)
		end

		-- FILTERS PANEL
		local filtersPanel = CreateFrame("FRAME", nil, self.MountJournal, "InsetFrameTemplate")
		self.filtersPanel = filtersPanel
		filtersPanel:SetPoint("TOPLEFT", navBar, "BOTTOMLEFT", -4, -4)
		filtersPanel:SetSize(280, 29)

		self.searchBox:SetPoint("TOPLEFT", filtersPanel, "TOPLEFT", 54, -4)
		self.searchBox:SetSize(131, 20)
		filtersButton:SetPoint("TOPRIGHT", filtersPanel, "TOPRIGHT", -3, -4)
		disableMethods(filtersButton)

		-- FILTERS SHOWN PANEL
		local shownPanel = CreateFrame("FRAME", nil, self.MountJournal, "InsetFrameTemplate")
		self.shownPanel = shownPanel
		shownPanel:SetPoint("TOPLEFT", filtersPanel, "BOTTOMLEFT", 0, -2)
		shownPanel:SetSize(280, 26)

		shownPanel.text = shownPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		shownPanel.text:SetPoint("LEFT", 8, -1)
		shownPanel.text:SetText(L["Shown:"])

		shownPanel.count = shownPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		shownPanel.count:SetPoint("LEFT", shownPanel.text, "RIGHT", 2, 0)

		shownPanel.clear = CreateFrame("BUTTON", nil, shownPanel, "MJClearButtonTemplate")
		shownPanel.clear:SetPoint("RIGHT", -5, 0)
		shownPanel.clear:SetScript("OnClick", function() self:clearAllFilters() end)

		-- SCROLL FRAME
		self.scrollFrame:SetPoint("TOPLEFT", self.leftInset, "TOPLEFT", 3, -5)
		self.scrollFrame.scrollBar:SetPoint("TOPLEFT", self.scrollFrame, "TOPRIGHT", 1, -12)

		-- FILTERS BAR
		local filtersBar = CreateFrame("FRAME", nil, filtersPanel, "MJFilterPanelTemplate")
		self.filtersBar = filtersBar
		filtersBar:SetSize(259, 35)
		filtersBar:SetPoint("TOP", 0, -46)
		filtersBar.types, filtersBar.selected, filtersBar.sources = setTabs(filtersBar, "types", "selected", "sources")

		-- FILTERS CLEAR
		filtersBar.clear = CreateFrame("BUTTON", nil, filtersBar, "MJClearButtonTemplate")
		filtersBar.clear:SetPoint("BOTTOMRIGHT", filtersBar, "TOPRIGHT")
		filtersBar.clear:SetScript("OnClick", function() self:clearBtnFilters() end)

		-- FILTERS BUTTONS
		local function CreateButtonFilter(id, parent, width, height, texture, tooltip)
			local btn = CreateFrame("CheckButton", nil, parent, width == height and "MJFilterButtonSquareTemplate" or "MJFilterButtonRectangleTemplate")
			btn.id = id
			btn:SetSize(width, height)
			if id == 1 then
				btn:SetPoint("LEFT", 5, 0)
				parent.childs = {}
			else
				btn:SetPoint("LEFT", parent.childs[#parent.childs], "RIGHT")
			end
			tinsert(parent.childs, btn)

			btn.icon:SetTexture(texture.path)
			btn.icon:SetSize(texture.width, texture.height)
			if texture.texCoord then btn.icon:SetTexCoord(unpack(texture.texCoord)) end

			btn:SetScript("OnEnter", function(btn)
				GameTooltip:SetOwner(btn, "ANCHOR_BOTTOM")
				GameTooltip:SetText(tooltip)
				GameTooltip:Show()
			end)
			btn:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)
			btn:SetScript("OnClick", function(btn)
				self:setBtnFilters(btn:GetParent():GetParent().id)
			end)
		end

		-- FILTERS TYPES BUTTONS
		local typesTextures = {
			{path = texPath.."fly", width = 32, height = 16},
			{path = texPath.."ground", width = 32, height = 16},
			{path = texPath.."swimming", width = 32, height = 16},
		}

		for i = 1, #typesTextures do
			CreateButtonFilter(i, filtersBar.types, 83, 25, typesTextures[i], L["MOUNT_TYPE_"..i])
		end

		-- FILTERS SELECTED BUTTONS
		for i = 1, #typesTextures do
			CreateButtonFilter(i, filtersBar.selected, 83, 25, typesTextures[i], L["MOUNT_TYPE_"..i])
		end

		-- FILTERS SOURCES BUTTONS
		local sourcesTextures = {
			{path = texPath.."sources", texCoord = {0, .25, 0, .25}, width = 20, height = 20},
			{path = texPath.."sources", texCoord = {.25, .5, 0, .25}, width = 20, height = 20},
			{path = texPath.."sources", texCoord = {.5, .75, 0, .25}, width = 20, height = 20},
			{path = texPath.."sources", texCoord = {.75, 1, 0, .25}, width = 20, height = 20},
			nil,
			{path = texPath.."sources", texCoord = {.25, .5, .25, .5}, width = 20, height = 20},
			{path = texPath.."sources", texCoord = {.5, .75, .25, .5}, width = 20, height = 20},
			{path = texPath.."sources", texCoord = {.75, 1, .25, .5}, width = 20, height = 20},
			{path = texPath.."sources", texCoord = {0, .25, .5, .75}, width = 20, height = 20},
			{path = texPath.."sources", texCoord = {.25, .5, .5, .75}, width = 20, height = 20},
			{path = texPath.."sources", texCoord = {.5, .75, .5, .75}, width = 20, height = 20},
		}

		for i = 1, #sourcesTextures do
			if sourcesTextures[i] then
				CreateButtonFilter(i, filtersBar.sources, 25, 25, sourcesTextures[i], _G["BATTLE_PET_SOURCE_"..i])
			end
		end

		-- FILTERS BTN TOGGLE
		self.btnToggle = CreateFrame("CheckButton", nil, filtersPanel, "MJArrowToggle")
		self.btnToggle:SetPoint("TOPLEFT", 3, -3)
		self.btnToggle.vertical = true
		self.btnToggle:SetChecked(mounts.config.filterToggle)

		function self.btnToggle:setBtnToggleCheck()
			if mounts.config.filterToggle then
				filtersPanel:SetHeight(84)
				filtersBar:Show()
			else
				filtersPanel:SetHeight(29)
				filtersBar:Hide()
			end
		end
		self.btnToggle:setBtnToggleCheck()

		self.btnToggle:HookScript("OnClick", function(btn)
			mounts.config.filterToggle = btn:GetChecked()
			btn:setBtnToggleCheck()
		end)

		-- GRID TOGGLE BUTTON
		self.gridToggleButton = CreateFrame("CheckButton", nil, filtersPanel, "MJGridToggle")
		self.gridToggleButton:SetPoint("LEFT", self.btnToggle, "RIGHT", -2, 0)
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

		-- MOUNT DESCRIPTION TOGGLE
		local infoButton = mountDisplay.InfoButton
		infoButton.Name:SetPoint("LEFT", infoButton.Icon, "RIGHT", 20, 0)

		local mountDescriptionToggle = CreateFrame("CheckButton", nil, infoButton, "MJArrowToggle")
		mountDescriptionToggle:SetPoint("LEFT", infoButton.Icon, "RIGHT", -2, 0)
		mountDescriptionToggle:SetSize(20, 40)
		mountDescriptionToggle.vertical = true
		mountDescriptionToggle:SetChecked(mounts.config.mountDescriptionToggle)

		local function setShownDescription(btn)
			local checked = btn:GetChecked()
			infoButton.Lore:SetShown(checked)
			infoButton.Source:SetShown(checked)
			mounts.config.mountDescriptionToggle = checked

			local activeCamera = self.modelScene.activeCamera
			if activeCamera then
				activeCamera.yOffset = activeCamera.yOffset + (checked and 40 or -40)
			end
		end
		setShownDescription(mountDescriptionToggle)
		mountDescriptionToggle:HookScript("OnClick", setShownDescription)

		-- PET SELECTION
		infoButton.petSelectionBtn = CreateFrame("BUTTON", nil, infoButton, "MJSetPetButton")
		infoButton.petSelectionBtn:SetPoint("LEFT", infoButton.Name, "RIGHT", 3, 0)

		-- MODEL SCENE
		self.modelScene.RotateLeftButton:Hide()
		self.modelScene.RotateRightButton:Hide()
		local modelControl = CreateFrame("FRAME", nil, self.modelScene, "MJControlFrameTemplate")
		modelControl:SetPoint("BOTTOM", -70, 10)
		modelControl.zoomIn.icon:SetTexCoord(.57812500, .82812500, .14843750, .27343750)
		modelControl.zoomOut.icon:SetTexCoord(.29687500, .54687500, .00781250, .13281250)
		modelControl.panButton.icon:SetTexCoord(.29687500, .54687500, .28906250, .41406250)
		modelControl.rotateLeftButton.icon:SetTexCoord(.01562500, .26562500, .28906250, .41406250)
		modelControl.rotateRightButton.icon:SetTexCoord(.57812500, .82812500, .28906250, .41406250)
		modelControl.rotateUpButton.icon:SetTexCoord(.01562500, .26562500, .28906250, .41406250)
		modelControl.rotateUpButton.icon:SetRotation(-math.pi / 1.6, .5, .43)
		modelControl.rotateDownButton.icon:SetTexCoord(.57812500, .82812500, .41406250, .28906250)
		modelControl.rotateDownButton.icon:SetRotation(-math.pi / 1.6)

		hooksecurefunc(self.modelScene, "SetActiveCamera", function(self)
			journal:event("SET_ACTIVE_CAMERA", self.activeCamera)
		end)

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

		-- MOUNT ANIMATIONS
		self.animationsCombobox = CreateFrame("FRAME", nil, self.modelScene, "MJMountAnimationPanel")
		self.animationsCombobox:SetPoint("LEFT", modelControl, "RIGHT", 10, 0)

		-- PLAYER SHOW BUTTON
		self.modelScene.TogglePlayer:Hide()
		local playerToggle = CreateFrame("CheckButton", nil, self.modelScene, "MJPlayerShowToggle")
		playerToggle:SetPoint("LEFT", self.animationsCombobox, "RIGHT", 11, 1)
		function playerToggle:setPortrait() SetPortraitTexture(self.portrait, "player") end
		playerToggle:SetScript("OnEvent", playerToggle.setPortrait)
		playerToggle:HookScript("OnShow", function(self)
			self:setPortrait()
			self:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "player")
		end)
		playerToggle:SetScript("OnHide", function(self)
			self:UnregisterEvent("UNIT_PORTRAIT_UPDATE")
		end)
		playerToggle:HookScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			self.animationsCombobox:replayAnimation()
		end)

		-- HOOKS
		self.func = {}
		self:setSecureFunc(C_MountJournal, "SetSearch", function(text)
			if type(text) == "string" then
				self.searchText = text
				self:updateMountsList()
			end
		end)
		self:setSecureFunc(C_MountJournal, "SetCollectedFilterSetting", function(filter, enabled)
			if filter == LE_MOUNT_JOURNAL_FILTER_COLLECTED then filter = "collected"
			elseif filter == LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED then filter = "notCollected"
			elseif filter == LE_MOUNT_JOURNAL_FILTER_UNUSABLE then filter = "unusable"
			else return end
			if type(enabled) == "boolean" then
				mounts.filters[filter] = enabled
				self:updateMountsList()
			end
		end)
		self:setSecureFunc(C_MountJournal, "SetAllSourceFilters", function(enabled)
			if type(enabled) == "boolean" then
				self:setAllFilters("sources", enabled)
				self:updateMountsList()
			end
		end)
		self:setSecureFunc(C_MountJournal, "SetSourceFilter", function(i, value)
			if type(i) == "number" and type(value) == "boolean" then
				mounts.filters.sources[i] = value
				self:updateMountsList()
			end
		end)
		self:setSecureFunc(C_MountJournal, "GetCollectedFilterSetting", function(filter)
			if filter == LE_MOUNT_JOURNAL_FILTER_COLLECTED then filter = "collected"
			elseif filter == LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED then filter = "notCollected"
			elseif filter == LE_MOUNT_JOURNAL_FILTER_UNUSABLE then filter = "unusable" end
			return mounts.filters[filter]
		end)
		self:setSecureFunc(C_MountJournal, "IsSourceChecked", function(i)
			if type(i) == "number" then
				return mounts.filters.sources[i]
			end
		end)
		self:setSecureFunc(C_MountJournal, "GetNumDisplayedMounts", function()
			return #self.displayedMounts
		end)
		self:setSecureFunc(C_MountJournal, "GetDisplayedMountInfo", function(index)
			local mountID = self.displayedMounts[index]
			if mountID then return C_MountJournal.GetMountInfoByID(mountID) end
		end)
		self:setSecureFunc(C_MountJournal, "GetDisplayedMountInfoExtra", function(index)
			local mountID = self.displayedMounts[index]
			if mountID then return C_MountJournal.GetMountInfoExtraByID(mountID) end
		end)
		self:setSecureFunc(C_MountJournal, "GetDisplayedMountAllCreatureDisplayInfo", function(index)
			local mountID = self.displayedMounts[index]
			if mountID then return C_MountJournal.GetMountAllCreatureDisplayInfoByID(mountID) end
		end)
		self:setSecureFunc(C_MountJournal, "Pickup")
		self:setSecureFunc(C_MountJournal, "SetIsFavorite")
		self:setSecureFunc(C_MountJournal, "GetIsFavorite")

		-- FIX TAINTS
		for i = 1, UIDROPDOWNMENU_MAXBUTTONS do
			_G["DropDownList1Button"..i].checked = nil
		end

		-- HOOK UPDATE MOUNT LIST
		hooksecurefunc("MountJournal_UpdateMountList", function() self:configureJournal() end)
		self.MountJournal_UpdateMountList = MountJournal_UpdateMountList
		self.grid3_UpdateMountList = function() self:grid3UpdateMountList() end
		self:setScrollGridMounts(mounts.config.gridToggle)

		-- MODULES INIT
		self:event("MODULES_INIT")

		-- UPDATE LISTS
		self:setEditMountsList()
		self:updateIndexByMountID()
		self:updateBtnFilters()
	end
end


function journal:setScrollGridMounts(grid)
	local scrollFrame = self.scrollFrame
	local offset = math.floor((scrollFrame.offset or 0) + .1)

	if grid then
		offset = math.ceil((offset + 1) / 3) - 1
		scrollFrame.update = self.grid3_UpdateMountList
		MountJournal_UpdateMountList = self.grid3_UpdateMountList

		for _, btn in ipairs(scrollFrame.buttons) do
			btn.DragButton:Hide()
			btn.background:Hide()
			btn.factionIcon:Hide()
			btn.favorite:Hide()
			btn.fly:Hide()
			btn.ground:Hide()
			btn.swimming:Hide()
			btn.icon:Hide()
			btn.name:Hide()
			btn.new:Hide()
			btn.newGlow:Hide()
			btn.selectedTexture:Hide()
			btn:Disable()
			btn.grid3list:Show()
		end
	else
		offset = offset * 3
		scrollFrame.update = self.MountJournal_UpdateMountList
		MountJournal_UpdateMountList = self.MountJournal_UpdateMountList

		for _, btn in ipairs(scrollFrame.buttons) do
			btn.DragButton:Show()
			btn.background:Show()
			btn.fly:Show()
			btn.ground:Show()
			btn.swimming:Show()
			btn.icon:Show()
			btn.name:Show()
			btn.grid3list:Hide()
		end
	end

	scrollFrame.update()
	scrollFrame.scrollBar:SetValue(offset * scrollFrame.buttonHeight)
end


function journal:grid3UpdateMountList()
	local scrollFrame = self.scrollFrame
	local offset = HybridScrollFrame_GetOffset(scrollFrame)
	local numDisplayedMounts = #self.displayedMounts
	local selectedSpellID = self.MountJournal.selectedSpellID

	for i, btn in ipairs(scrollFrame.buttons) do
		for j = 1, 3 do
			local index = (offset + i - 1) * 3 + j
			local btnGrid = btn.grid3list["mount"..j]

			if index <= numDisplayedMounts then
				local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, isFiltered, isCollected, mountID = C_MountJournal.GetDisplayedMountInfo(index)
				local needsFanfare = C_MountJournal.NeedsFanfare(mountID)

				btnGrid.index = index
				btnGrid.spellID = spellID
				btnGrid.mountID = mountID
				btnGrid.active = active
				btnGrid.selected = selectedSpellID == spellID
				btnGrid.icon:SetTexture(needsFanfare and COLLECTIONS_FANFARE_ICON or icon)
				btnGrid.icon:SetVertexColor(1, 1, 1)
				btnGrid.favorite:SetShown(isFavorite)
				btnGrid.DragButton:Enable()
				btnGrid.DragButton.selectedTexture:SetShown(btnGrid.selected)
				btnGrid:Show()
				btnGrid:Enable()

				if isUsable or needsFanfare then
					btnGrid.icon:SetDesaturated()
					btnGrid.icon:SetAlpha(1)
				elseif isCollected then
					btnGrid.icon:SetDesaturated(true)
					btnGrid.icon:SetVertexColor(.58823529411765, .19607843137255, .19607843137255)
					btnGrid.icon:SetAlpha(.75)
				else
					btnGrid.icon:SetDesaturated(true)
					btnGrid.icon:SetAlpha(.5)
				end

				if btnGrid.showingTooltip then
					MountJournalMountButton_UpdateTooltip(btnGrid)
				end
			else
				btnGrid.icon:SetTexture("Interface/PetBattles/MountJournalEmptyIcon")
				btnGrid.icon:SetDesaturated(true)
				btnGrid.icon:SetVertexColor(.4, .4, .4)
				btnGrid.icon:SetAlpha(.5)
				btnGrid.index = nil
				btnGrid.spellID = 0
				btnGrid.selected = false
				btnGrid:Disable()
				btnGrid.DragButton:Disable()
				btnGrid.DragButton.selectedTexture:Hide()
				btnGrid.favorite:Hide()
			end
		end
	end

	HybridScrollFrame_Update(scrollFrame, scrollFrame.buttonHeight * math.ceil(numDisplayedMounts / 3), scrollFrame:GetHeight())
	self:configureJournal(true)
end


function journal:setEditMountsList()
	self.db = mounts.charDB.currentProfileName and mounts.profiles[mounts.charDB.currentProfileName] or mounts.defProfile
	self.zoneMounts = self.db.zoneMountsFromProfile and mounts.defProfile.zoneMounts or self.db.zoneMounts
	local mapID = self.navBar.mapID
	if mapID == mounts.defMountsListID then
		self.currentList = self.db
		self.listMapID = nil
		self.list = self.currentList
	else
		self.currentList = self.zoneMounts[mapID]
		self.listMapID = mapID
		self.list = self.currentList
		while self.list and self.list.listFromID do
			self.listMapID = self.list.listFromID
			self.list = self.zoneMounts[self.listMapID]
		end
	end
	self.petForMount = self.db.petListFromProfile and mounts.defProfile.petForMount or self.db.petForMount
end


function journal:ACHIEVEMENT_EARNED()
	self.achiev.text:SetText(GetCategoryAchievementPoints(MOUNT_ACHIEVEMENT_CATEGORY, true))
end


do
	local function setColor(self, btn, checked)
		local color = checked and self.colors.gold or self.colors.gray
		btn.icon:SetVertexColor(color:GetRGB())
		btn:SetChecked(checked)
	end

	function journal:updateMountToggleButton(btn)
		if btn.index then
			btn.fly:Enable()
			btn.ground:Enable()
			btn.swimming:Enable()
			setColor(self, btn.fly, self.list and self.list.fly[btn.mountID])
			setColor(self, btn.ground, self.list and self.list.ground[btn.mountID])
			setColor(self, btn.swimming, self.list and self.list.swimming[btn.mountID])
		else
			btn.fly:Disable()
			btn.ground:Disable()
			btn.swimming:Disable()
		end
	end
end


function journal:configureJournal(isGrid)
	for _, btn in ipairs(self.scrollButtons) do
		if isGrid then
			for i = 1, 3 do
				self:updateMountToggleButton(btn.grid3list["mount"..i])
			end
		else
			self:updateMountToggleButton(btn)
		end
	end

	self.mountCount.Count:SetText(self.mountCount.Count.num)
end


function journal:setCountMounts()
	local count, collected = 0, 0
	for i = 1, #self.mountIDs do
		local _,_,_,_,_,_,_,_,_, hideOnChar, isCollected = C_MountJournal.GetMountInfoByID(self.mountIDs[i])
		if not hideOnChar then
			count = count + 1
			if isCollected then
				collected = collected + 1
			end
		end
	end
	self.mountCount.Count.num = count
	self.mountCount.Count:SetText(count)
	self.mountCount.collected:SetText(collected)
end


function journal:sortMounts()
	local fSort = mounts.filters.sorting

	sort(self.mountIDs, function(a, b)
		local nameA, _,_,_,_,_, isFavoriteA, _,_,_, isCollectedA = C_MountJournal.GetMountInfoByID(a)
		local nameB, _,_,_,_,_, isFavoriteB, _,_,_, isCollectedB = C_MountJournal.GetMountInfoByID(b)

		-- FAVORITES
		if fSort.favoritesFirst then
			if isFavoriteA and not isFavoriteB then return true
			elseif not isFavoriteA and isFavoriteB then return false end
		end

		-- COLLECTED
		if isCollectedA and not isCollectedB then return true
		elseif not isCollectedA and isCollectedB then return false end

		-- TYPE
		if fSort.by == "type" then
			local _,_,_,_, typeA = C_MountJournal.GetMountInfoExtraByID(a)
			local _,_,_,_, typeB = C_MountJournal.GetMountInfoExtraByID(b)

			if self.mountTypes[typeA] < self.mountTypes[typeB] then return not fSort.reverse
			elseif self.mountTypes[typeA] > self.mountTypes[typeB] then return fSort.reverse end
		-- EXPANSION
		elseif fSort.by == "expansion" then
			if mounts.mountsDB[a] < mounts.mountsDB[b] then return not fSort.reverse
			elseif mounts.mountsDB[a] > mounts.mountsDB[b] then return fSort.reverse end
		-- NAME
		elseif fSort.by == "name" and fSort.reverse then
			if nameA > nameB then return true
			elseif nameA < nameB then return false end
		end

		if fSort.by ~= "name" or not fSort.reverse then
			if nameA < nameB then return true
			elseif nameA > nameB then return false end
		end
		return a < b
	end)

	self:updateMountsList()
end


function journal:updateIndexByMountID()
	self:UnregisterEvent("MOUNT_JOURNAL_SEARCH_UPDATED")
	self.func.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED, true)
	self.func.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED, true)
	self.func.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE, true)
	self.func.SetAllSourceFilters(true)
	self.func.SetSearch("")
	self:RegisterEvent("MOUNT_JOURNAL_SEARCH_UPDATED")

	wipe(self.indexByMountID)
	for i = 1, self.func.GetNumDisplayedMounts() do
		local _,_,_,_,_,_,_,_,_,_,_, mountID = self.func.GetDisplayedMountInfo(i)
		self.indexByMountID[mountID] = i
	end

	self:sortMounts()
end
journal.MOUNT_JOURNAL_SEARCH_UPDATED = journal.updateIndexByMountID -- UPDATE indexByMountID WHEN SET FAVORITE


function journal:mountLearnedUpdate()
	self:setCountMounts()
	self:MOUNT_JOURNAL_SEARCH_UPDATED()
end
journal.COMPANION_LEARNED = journal.mountLearnedUpdate
journal.COMPANION_UNLEARNED = journal.mountLearnedUpdate


-- isUsable FLAG CHANGED
function journal:MOUNT_JOURNAL_USABILITY_CHANGED()
	if self.MountJournal:IsVisible() then
		self:updateMountsList()
		MountJournal_UpdateMountDisplay()
	end
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
	for _, value in pairs(list.flags) do
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


function journal:mountToggle(btn)
	if not self.list then
		self:createMountList(self.listMapID)
	end
	local tbl = self.list[btn.type]
	local mountID = btn:GetParent().mountID

	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	if tbl[mountID] then
		tbl[mountID] = nil
		btn.icon:SetVertexColor(self.colors.gray:GetRGB())
		self:getRemoveMountList(self.listMapID)
	else
		tbl[mountID] = true
		btn.icon:SetVertexColor(self.colors.gold:GetRGB())
	end

	mounts:setMountsList()
	self.existingLists:refresh()
end


function journal:setFlag(flag, enable)
	if self.navBar.mapID == mounts.defMountsListID then return end

	if enable and not (self.currentList and self.currentList.flags) then
		self:createMountList(self.navBar.mapID)
	end
	self.currentList.flags[flag] = enable
	if not enable then
		self:getRemoveMountList(self.navBar.mapID)
	end

	mounts:setMountsList()
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

		sort(btn.maps, function(a, b) return a.name < b.name end)
		for _, mapInfo in ipairs(btn.maps) do
			sort(mapInfo.list, function(a, b) return a.name < b.name end)
		end

		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		btn:dropDownToggle(1, btn.maps, btn, 115, 15)
	end
end


function journal:listFromMapInit(level, value)
	local info = {}
	info.notCheckable = true

	if next(value) == nil then
		info.disabled = true
		info.text = EMPTY
		self:ddAddButton(info, level)
	elseif level == 2 then
		local function setListFrom(_, mapID)
			if journal.navBar.mapID == mapID then return end
			if not journal.currentList then
				journal:createMountList(journal.navBar.mapID)
			end
			journal.currentList.listFromID = mapID
			journal:setEditMountsList()
			journal:updateMountsList()
			journal:updateMapSettings()
			mounts:setMountsList()
			journal.existingLists:refresh()

			journal.mountListUpdateAnim:Stop()
			journal.mountListUpdateAnim:Play()
		end

		info.list = {}
		for _, mapInfo in ipairs(value) do
			tinsert(info.list, {
				notCheckable = true,
				text = mapInfo.name,
				arg1 = mapInfo.mapID,
				func = setListFrom,
			})
			self:ddAddButton(info, level)
		end
	else
		for _, mapInfo in ipairs(value) do
			info.keepShownOnClick = true
			info.hasArrow = true
			info.text = mapInfo.name
			info.value = mapInfo.list
			self:ddAddButton(info, level)
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

	local optionsEnable = self.navBar.mapID ~= mounts.defMountsListID
	mapSettings.Flags:SetEnabled(optionsEnable)
	mapSettings.listFromMap:SetEnabled(optionsEnable)

	local relationText = mapSettings.relationMap.text
	local relationClear = mapSettings.relationClear
	if self.currentList and self.currentList.listFromID then
		relationText:SetText(util.getMapFullNameInfo(self.currentList.listFromID).name)
		relationText:SetTextColor(self.colors.gold:GetRGB())
		relationClear:Show()
	else
		relationText:SetText(L["No relation"])
		relationText:SetTextColor(self.colors.gray:GetRGB())
		relationClear:Hide()
	end
end


function journal:setSecureFunc(obj, funcName, func)
	if self.func[funcName] ~= nil then return end

	self.func[funcName] = obj[funcName]
	if func then
		obj[funcName] = func
	else
		obj[funcName] = function(index, ...)
			index = self.indexByMountID[self.displayedMounts[index]]
			if index then
				return self.func[funcName](index, ...)
			end
		end
	end
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
		info.checked = function() return mounts.filters.collected end
		btn:ddAddButton(info, level)

		info.text = NOT_COLLECTED
		info.func = function(_,_,_, value)
			mounts.filters.notCollected = value
			self:updateMountsList()
		end
		info.checked = function() return mounts.filters.notCollected end
		btn:ddAddButton(info, level)

		info.text = MOUNT_JOURNAL_FILTER_UNUSABLE
		info.func = function(_,_,_, value)
			mounts.filters.unusable = value
			self:updateMountsList()
		end
		info.checked = function() return mounts.filters.unusable end
		btn:ddAddButton(info, level)

		info.text = L["hidden for character"]
		info.func = function(_,_,_, value)
			mounts.filters.hideOnChar = value
			self:updateMountsList()
		end
		info.checked = function() return mounts.filters.hideOnChar end
		btn:ddAddButton(info, level)

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

		info.text = L["factions"]
		info.value = 4
		btn:ddAddButton(info, level)

		info.text = PET
		info.value = 5
		btn:ddAddButton(info, level)

		info.text = L["expansions"]
		info.value = 6
		btn:ddAddButton(info, level)

		info.text = L["tags"]
		info.value = 7
		btn:ddAddButton(info, level)

		info.text = L["sorting"]
		info.value = 8
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

			info.notCheckable = false
			local types = mounts.filters.types
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

			info.notCheckable = false
			local selected = mounts.filters.selected
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

			info.notCheckable = false
			local sources = mounts.filters.sources
			for i = 1, C_PetJournal.GetNumPetSources() do
				if C_MountJournal.IsValidSourceFilter(i) then
					info.text = _G["BATTLE_PET_SOURCE_"..i]
					info.func = function(_,_,_, value)
						sources[i] = value
						if not value then sources[0] = value end
						self:updateBtnFilters()
						self:updateMountsList()
					end
					info.checked = function() return sources[i] end
					btn:ddAddButton(info, level)
				end
			end
		elseif value == 4 then -- FACTIONS
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

			info.notCheckable = false
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
		elseif value == 5 then -- PET
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

			info.notCheckable = false
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
		elseif value == 6 then -- EXPANSIONS
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

			info.notCheckable = false
			local expansions = mounts.filters.expansions
			for i = 1, EJ_GetNumTiers() do
				info.text = _G["EXPANSION_NAME"..(i - 1)]
				info.func = function(_,_,_, value)
					expansions[i] = value
					self:updateMountsList()
				end
				info.checked = function() return expansions[i] end
				btn:ddAddButton(info, level)
			end
		elseif value == 7 then -- TAGS
			local filterTags = self.tags.filter

			info.notCheckable = false
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

			if #self.tags.sortedTags == 0 then
				info.text = EMPTY
				info.disabled = true
				btn:ddAddButton(info, level)
				info.disabled = nil
			else
				info.list = {}
				for i, tag in ipairs(self.tags.sortedTags) do
					tinsert(info.list, {
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
					})
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

			btn:ddAddSeparator(level)

			info.isNotRadio = true
			info.text = L["Reverse Sort"]
			info.func = function(_,_,_, value)
				fSort.reverse = value
				self:sortMounts()
			end
			info.checked = fSort.reverse
			btn:ddAddButton(info, level)

			info.isNotRadio = true
			info.text = L["Favorites First"]
			info.func = function(_,_,_, value)
				fSort.favoritesFirst = value
				self:sortMounts()
			end
			info.checked = fSort.favoritesFirst
			btn:ddAddButton(info, level)
		end
	end
end


function journal:clearBtnFilters()
	self:setAllFilters("sources", true)
	self:setAllFilters("types", true)
	self:setAllFilters("selected", false)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	self:updateBtnFilters()
	self:updateMountsList()
end


function journal:clearAllFilters()
	mounts.filters.collected = true
	mounts.filters.notCollected = true
	mounts.filters.unusable = true
	mounts.filters.hideOnChar = false
	self.searchBox:SetText("")
	self:setAllFilters("factions", true)
	self:setAllFilters("pet", true)
	self:setAllFilters("expansions", true)
	self.tags:resetFilter()
	self:clearBtnFilters()
end


function journal:setBtnFilters(tab)
	local i = 0
	local children = self.filtersBar[tab].childs
	local filters = mounts.filters[tab]

	if tab ~= "sources" then
		local default = tab ~= "selected"

		for _, btn in ipairs(children) do
			local checked = btn:GetChecked()
			filters[btn.id] = checked
			if not checked and default then i = i + 1 end
		end

		if i == #filters then
			self:setAllFilters(tab, default)
		end
	else
		for _, btn in ipairs(children) do
			local checked = btn:GetChecked()
			filters[btn.id] = checked
			if not checked then i = i + 1 end
		end

		if i == #children then
			self:setAllFilters("sources", true)
		else
			filters[0] = false
		end
	end

	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	self:updateBtnFilters()
	self:updateMountsList()
end


function journal:setAllFilters(typeFilter, enabled)
	local filter = mounts.filters[typeFilter]
	for k in pairs(filter) do
		filter[k] = enabled
	end
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
				for _, btn in ipairs(filtersBar.sources.childs) do
					local checked = filter[btn.id]
					btn:SetChecked(checked)
					btn.icon:SetDesaturated(not checked)
				end
				filtersBar.sources:GetParent().filtred:Show()
			end

		-- TYPES AND SELECTED
		elseif filtersBar[typeFilter] then
			local default = typeFilter ~= "selected"
			local i = 0
			for _, v in ipairs(filter) do
				if v == default then i = i + 1 end
			end

			if i == #filter then
				for _, btn in ipairs(filtersBar[typeFilter].childs) do
					local color = default and self.colors["mount"..btn.id] or self.colors.dark
					btn:SetChecked(false)
					btn.icon:SetVertexColor(color:GetRGB())
				end
				filtersBar[typeFilter]:GetParent().filtred:Hide()
			else
				clearShow = true
				for _, btn in ipairs(filtersBar[typeFilter].childs) do
					local checked = filter[btn.id]
					local color = checked and self.colors["mount"..btn.id] or self.colors.dark
					btn:SetChecked(checked)
					btn.icon:SetVertexColor(color:GetRGB())
				end
				filtersBar[typeFilter]:GetParent().filtred:Show()
			end
		end
	end

	-- CLEAR BTN FILTERS
	filtersBar.clear:SetShown(clearShow)
end


function journal:updateMountsList()
	local filters, mountTypes, list, mountsDB, tags, GetMountInfoByID, GetMountInfoExtraByID = mounts.filters, self.mountTypes, self.list, mounts.mountsDB, self.tags, C_MountJournal.GetMountInfoByID, C_MountJournal.GetMountInfoExtraByID
	local sources, types, selected, factions, pet, expansions = filters.sources, filters.types, filters.selected, filters.factions, filters.pet, filters.expansions
	local text = util.cleanText(self.searchText)
	wipe(self.displayedMounts)

	for i = 1, #self.mountIDs do
		local mountID = self.mountIDs[i]
		local name, spellID, _,_, isUsable, sourceType, _,_, mountFaction, shouldHideOnChar, isCollected = GetMountInfoByID(mountID)
		local _,_, sourceText, _, mountType = GetMountInfoExtraByID(mountID)
		local petID = self.petForMount[spellID]

		-- HIDDEN FOR CHARACTER
		if (not shouldHideOnChar or filters.hideOnChar)
		-- COLLECTED
		and (isCollected and filters.collected or not isCollected and filters.notCollected)
		-- UNUSABLE
		and (isUsable or not isCollected or filters.unusable)
		-- SOURCES
		and sources[sourceType]
		-- SEARCH
		and (text:len() == 0
			or name:lower():find(text)
			or sourceText:lower():find(text)
			or tags:find(mountID, text))
		-- TYPE
		and types[mountTypes[mountType]]
		-- FACTION
		and factions[(mountFaction or 2) + 1]
		-- SELECTED
		and (not (selected[1] or selected[2] or selected[3]) or list and
			(selected[1] and list.fly[mountID]
			or selected[2] and list.ground[mountID]
			or selected[3] and list.swimming[mountID]))
		-- PET
		and pet[petID and (type(petID) == "number" and petID or 3) or 4]
		-- EXPANSIONS
		and expansions[mountsDB[mountID]]
		-- TAGS
		and tags:getFilterMount(mountID) then
			tinsert(self.displayedMounts, mountID)
		end
	end

	local numShowMounts = #self.displayedMounts
	self.shownPanel.count:SetText(numShowMounts)
	if filters.hideOnChar or self.mountCount.Count.num ~= numShowMounts then
		self.shownPanel:Show()
		self.leftInset:SetPoint("TOPLEFT", self.shownPanel, "BOTTOMLEFT", 0, -2)
	else
		self.shownPanel:Hide()
		self.leftInset:SetPoint("TOPLEFT", self.filtersPanel, "BOTTOMLEFT", 0, -2)
	end
	self.leftInset:GetHeight()

	self.scrollFrame.update()
end