local addon, L = ...
local util, mounts, config = MountsJournalUtil, MountsJournal, MountsJournalConfig
local journal = CreateFrame("FRAME", "MountsJournalFrame")


local COLLECTION_ACHIEVEMENT_CATEGORY = 15246
local MOUNT_ACHIEVEMENT_CATEGORY = 15248


journal.colors = {
	gold = CreateColor(0.8, 0.6, 0),
	gray = CreateColor(0.5, 0.5, 0.5),
	dark = CreateColor(0.3, 0.3, 0.3),
	mount1 = CreateColor(0.824, 0.78, 0.235),
	mount2 = CreateColor(0.42, 0.302, 0.224),
	mount3 = CreateColor(0.031, 0.333, 0.388),
}


journal.displayedMounts = {}
setmetatable(journal.displayedMounts, {__index = function(self, key)
	return key
end})


-- 1 FLY, 2 GROUND, 3 SWIMMING
journal.mountTypes = {
	[242] = 1,
	[247] = 1,
	[248] = 1,
	[398] = 1,
	[230] = 2,
	[241] = 2,
	[269] = 2,
	[284] = 2,
	[231] = 3,
	[232] = 3,
	[254] = 3,
}


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


journal:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		self[event](self, ...)
	end
end)
journal:RegisterEvent("ADDON_LOADED")


function journal:ADDON_LOADED(addonName)
	if addonName == "Blizzard_Collections" and IsAddOnLoaded(addon) or addonName == addon and IsAddOnLoaded("Blizzard_Collections") then
		self:UnregisterEvent("ADDON_LOADED")

		local texPath = "Interface/AddOns/MountsJournal/textures/"
		local scrollFrame = MountJournal.ListScrollFrame
		local mountDisplay = MountJournal.MountDisplay
		local modelScene = mountDisplay.ModelScene
		self.scrollButtons = scrollFrame.buttons
		self.leftInset = MountJournal.LeftInset
		self.rightInset = MountJournal.RightInset
		mounts.filters.types = mounts.filters.types or {true, true, true}
		mounts.filters.selected = mounts.filters.selected or {false, false, false}
		mounts.filters.factions = mounts.filters.factions or {true, true, true}
		mounts.filters.pet = mounts.filters.pet or {true, true, true, true}
		mounts.filters.expansions = mounts.filters.expansions or {}
		setmetatable(mounts.filters.expansions, {__index = function(self, key)
			self[key] = true
			return true
		end})

		-- MOUNT LIST UPDATE ANIMATION
		self.leftInset.updateAnimFrame = CreateFrame("FRAME", nil, self.leftInset, "MJUpdateAnimFrame")
		self.mountListUpdateAnim = self.leftInset.updateAnimFrame.anim

		-- MOUNT COUNT
		local mountCount = MountJournal.MountCount
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
		MountJournal.BottomLeftInset:Hide()
		local slotButton = MountJournal.BottomLeftInset.SlotButton
		slotButton:SetParent(MountJournal)
		slotButton:SetPoint("LEFT", self.mountCount, "RIGHT", 4, 0)
		slotButton:SetScale(.65)
		hooksecurefunc("MountJournal_UpdateEquipmentPalette", function()
			local effectsSuppressed = C_MountJournal.AreMountEquipmentEffectsSuppressed()
			local locked = not C_MountJournal.IsMountEquipmentUnlocked()
			slotButton:DesaturateHierarchy((effectsSuppressed or locked) and 1 or 0)
		end)
		self.leftInset:SetPoint("BOTTOMLEFT", MountJournal, "BOTTOMLEFT", 0, 26)
		HybridScrollFrame_CreateButtons(scrollFrame, "MountListButtonTemplate", 44, 0)
		self.rightInset:SetPoint("BOTTOMLEFT", self.leftInset, "BOTTOMRIGHT", 20, 0)

		-- NAVBAR BUTTON
		local navBarBtn = CreateFrame("CheckButton", nil, MountJournal, "MJMiniMapBtnTemplate")
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
		local navBar = CreateFrame("FRAME", nil, MountJournal, "MJNavBarTemplate")
		self.navBar = navBar
		navBar:SetPoint("TOPLEFT", 8, -60)
		navBar:SetPoint("TOPRIGHT", navBarBtn, "TOPLEFT", 0, 0)
		navBar:on("MAP_CHANGE", function()
			self:setEditMountsList()
			self:updateMountsList()
			MountJournal_UpdateMountList()
			self:updateMapSettings()
		end)
		self.rightInset:SetPoint("TOPRIGHT", navBarBtn, "BOTTOMRIGHT", -4, 0)

		-- WORDL MAP
		local worldMap = CreateFrame("FRAME", nil, MountJournal, "MJMapTemplate")
		self.worldMap = worldMap
		worldMap:SetPoint("TOPLEFT", self.rightInset)
		worldMap:SetPoint("TOPRIGHT", self.rightInset)

		-- MAP SETTINGS
		local mapSettings = CreateFrame("FRAME", nil, MountJournal, "MJMapSettingsTemplate")
		self.mapSettings = mapSettings
		mapSettings:SetPoint("TOPLEFT", worldMap, "BOTTOMLEFT", 0, -30)
		mapSettings:SetPoint("BOTTOMRIGHT", self.rightInset)
		mapSettings:SetScript("OnShow", function() self:updateMapSettings() end)
		mapSettings.dungeonRaidBtn:SetText(L["Dungeons and Raids"])
		mapSettings.dungeonRaidBtn.click = function(mapID) navBar:setMapID(mapID) end
		mapSettings.CurrentMap:SetText(L["Current Location"])
		mapSettings.CurrentMap:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			navBar:setCurrentMap()
		end)
		mapSettings.Ground.Text:SetText(L["Ground Mounts Only"])
		mapSettings.Ground:HookScript("OnClick", function(check) self:setFlag("groundOnly", check:GetChecked()) end)
		mapSettings.WaterWalk.Text:SetText(L["Water Walking"])
		mapSettings.WaterWalk.tooltipText = L["Water Walking"]
		mapSettings.WaterWalk.tooltipRequirement = L["WaterWalkFlagDescription"]
		mapSettings.WaterWalk:HookScript("OnClick", function(check) self:setFlag("waterWalkOnly", check:GetChecked()) end)
		mapSettings.HerbGathering.Text:SetText(L["Herb Gathering"])
		mapSettings.HerbGathering.tooltipText = L["Herb Gathering"]
		mapSettings.HerbGathering.tooltipRequirement = L["HerbGatheringFlagDescription"]
		mapSettings.HerbGathering:HookScript("OnClick", function(check) self:setFlag("herbGathering", check:GetChecked()) end)
		mapSettings.listFromMap.Text:SetText(L["ListMountsFromZone"])
		mapSettings.listFromMap.maps = {}
		mapSettings.listFromMap:SetScript("OnClick", function(btn) self:listFromMapClick(btn) end)
		mapSettings.relationClear:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			self.currentList.listFromID = nil
			self:getRemoveMountList(self.navBar.mapID)
			self:setEditMountsList()
			self:updateMountsList()
			MountJournal_UpdateMountList()
			self:updateMapSettings()
			mounts:setMountsList()
			self.existingsLists:refresh()
		end)
		UIDropDownMenu_Initialize(mapSettings.listFromMap.optionsMenu, self.listFromMapInit, "MENU")

		-- EXISTINGS LISTS TOGGLE
		mapSettings.existingsListsToggle:HookScript("OnClick", function(btn)
			self.existingsLists:SetShown(btn:GetChecked())
		end)

		-- EXISTINGS LISTS
		local existingsLists = CreateFrame("FRAME", nil, mapSettings, "MJExistingsListsPanelTemplate")
		self.existingsLists = existingsLists
		existingsLists:SetPoint("TOPLEFT", MountJournal, "TOPRIGHT")
		existingsLists:SetPoint("BOTTOMLEFT", MountJournal, "BOTTOMRIGHT")

		--MOUNTJOURNAL ONSHOW
		MountJournal:HookScript("OnShow", function()
			navBarBtn:SetChecked(false)
			mountDisplay:Show()
			self.mapSettings:Hide()
			self.worldMap:Hide()
		end)

		-- SETTINGS BUTTON
		local btnConfig = CreateFrame("BUTTON", "MountsJournalBtnConfig", MountJournal, "UIPanelButtonTemplate")
		btnConfig:SetSize(80, 22)
		btnConfig:SetPoint("BOTTOMRIGHT", -6, 4)
		btnConfig:SetText(L["Settings"])
		btnConfig:SetScript("OnClick", function() config:openConfig() end)

		-- ACHIEVEMENT
		self.achiev = CreateFrame("BUTTON", nil, MountJournal, "MJAchiev")
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
		local profilesMenu = CreateFrame("DropDownToggleButton", nil, MountJournal, "MJMenuButtonProfiles")
		self.profilesMenu = profilesMenu
		profilesMenu:SetPoint("LEFT", MountJournal.MountButton, "RIGHT", 6, 0)
		profilesMenu:on("SET_PROFILE", function()
			mounts:setDB()
			self:setEditMountsList()
			self:updateMountsList()
			MountJournal_UpdateMountList()
			self:updateMapSettings()
			self.existingsLists:refresh()
		end)

		-- SELECTED BUTTONS
		local function CreateButton(name, parent, pointX, pointY, OnClick)
			local btnFrame = CreateFrame("BUTTON", nil, parent)
			btnFrame:SetPoint("TOPRIGHT", pointX, pointY)
			btnFrame:SetSize(24, 12)
			btnFrame:SetScript("OnClick", OnClick)
			btnFrame.type = name
			parent[name] = btnFrame

			btnFrame:SetNormalTexture(texPath.."button")
			btnFrame:SetHighlightTexture(texPath.."button")
			local background, hightlight = btnFrame:GetRegions()
			background:SetTexCoord(0.00390625, 0.8203125, 0.00390625, 0.18359375)
			background:SetVertexColor(0.2,0.18,0.01)
			hightlight:SetTexCoord(0.00390625, 0.8203125, 0.19140625, 0.37109375)

			btnFrame.check = btnFrame:CreateTexture(nil, "OVERLAY")
			btnFrame.check:SetTexture(texPath.."button")
			btnFrame.check:SetTexCoord(0.00390625, 0.8203125, 0.37890625, 0.55859375)
			btnFrame.check:SetVertexColor(self.colors.gold:GetRGB())
			btnFrame.check:SetAllPoints()

			btnFrame.icon = btnFrame:CreateTexture(nil, "OVERLAY")
			btnFrame.icon:SetTexture(texPath..name)
			btnFrame.icon:SetSize(24, 12)
			btnFrame.icon:SetPoint("CENTER")

			btnFrame:SetScript("OnMouseDown", function(self)
				self.icon:SetScale(.8)
			end)
			btnFrame:SetScript("OnMouseUp", function(self)
				self.icon:SetScale(1)
			end)
		end

		local function btnClick(btn) self:mountToggle(btn) end
		for _, child in ipairs(self.scrollButtons) do
			child:SetWidth(child:GetWidth() - 25)
			child.name:SetWidth(child.name:GetWidth() - 18)
			child.icon:SetPoint("LEFT", child, "LEFT", -41, 0)
			child.icon:SetSize(40, 40)

			CreateButton("fly", child, 25, -3, btnClick)
			CreateButton("ground", child, 25, -17, btnClick)
			CreateButton("swimming", child, 25, -31, btnClick)

			child:HookScript("OnClick", function(btn, mouseBtn) self:mountDblClick(btn.index, mouseBtn) end)
		end

		-- FILTERS PANEL
		local filtersPanel = CreateFrame("FRAME", nil, MountJournal, "InsetFrameTemplate")
		self.filtersPanel = filtersPanel
		filtersPanel:SetPoint("TOPLEFT", navBar, "BOTTOMLEFT", -4, -4)
		filtersPanel:SetSize(280, 29)

		MountJournal.searchBox:SetPoint("TOPLEFT", filtersPanel, "TOPLEFT", 33, -4)
		MountJournal.searchBox:SetSize(151, 20)
		MountJournalFilterButton:SetPoint("TOPRIGHT", filtersPanel, "TOPRIGHT", -3, -4)

		-- FILTERS SHOWN PANEL
		local shownPanel = CreateFrame("FRAME", nil, MountJournal, "InsetFrameTemplate")
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
		scrollFrame:SetPoint("TOPLEFT", self.leftInset, "TOPLEFT", 3, -5)
		scrollFrame.scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 1, -12)

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

		--  FILTERS TYPES BUTTONS
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
			{path = texPath.."sources", texCoord = {0, 0.25, 0, 0.25}, width = 20, height = 20},
			{path = texPath.."sources", texCoord = {0.25, 0.5, 0, 0.25}, width = 20, height = 20},
			{path = texPath.."sources", texCoord = {0.5, 0.75, 0, 0.25}, width = 20, height = 20},
			{path = texPath.."sources", texCoord = {0.75, 1, 0, 0.25}, width = 20, height = 20},
			nil,
			{path = texPath.."sources", texCoord = {0.25, 0.5, 0.25, 0.5}, width = 20, height = 20},
			{path = texPath.."sources", texCoord = {0.5, 0.75, 0.25, 0.5}, width = 20, height = 20},
			{path = texPath.."sources", texCoord = {0.75, 1, 0.25, 0.5}, width = 20, height = 20},
			{path = texPath.."sources", texCoord = {0, 0.25, 0.5, 0.75}, width = 20, height = 20},
			{path = texPath.."sources", texCoord = {0.25, 0.5, 0.5, 0.75}, width = 20, height = 20},
			{path = texPath.."sources", texCoord = {0.5, 0.75, 0.5, 0.75}, width = 20, height = 20},
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

		local function setBtnToggleCheck()
			if mounts.config.filterToggle then
				filtersPanel:SetHeight(84)
				filtersBar:Show()
			else
				filtersPanel:SetHeight(29)
				filtersBar:Hide()
			end
		end
		setBtnToggleCheck()

		self.btnToggle:HookScript("OnClick", function(self)
			mounts.config.filterToggle = self:GetChecked()
			setBtnToggleCheck()
		end)

		-- MOUNT DESCRIPTION TOGGLE
		local infoButton = mountDisplay.InfoButton
		infoButton.Name:SetPoint("LEFT", infoButton.Icon, "RIGHT", 20, 0)

		local mountDescriptionToggle = CreateFrame("CheckButton", nil, infoButton, "MJArrowToggle")
		mountDescriptionToggle:SetPoint("LEFT", infoButton.Icon, "RIGHT", -2, 0)
		mountDescriptionToggle:SetSize(20, 40)
		mountDescriptionToggle.vertical = true
		mountDescriptionToggle:SetChecked(mounts.config.mountDescriptionToggle)

		local function setShownDescription(self)
			local checked = self:GetChecked()
			infoButton.Lore:SetShown(checked)
			infoButton.Source:SetShown(checked)
			mounts.config.mountDescriptionToggle = checked

			local activeCamera = modelScene.activeCamera
			if activeCamera then
				activeCamera:ApplyFromModelSceneCameraInfo(C_ModelInfo.GetModelSceneCameraInfoByID(activeCamera.modelSceneCameraInfo.modelSceneCameraID), nil, modelScene.cameraModificationType)
			end
		end
		setShownDescription(mountDescriptionToggle)
		mountDescriptionToggle:HookScript("OnClick", setShownDescription)

		-- PET SELECTION
		infoButton.petSelectionBtn = CreateFrame("BUTTON", nil, infoButton, "MJSetPetButton")
		infoButton.petSelectionBtn:SetPoint("LEFT", infoButton.Name, "RIGHT", 3, 0)

		-- MODEL SCENE
		modelScene.RotateLeftButton:Hide()
		modelScene.RotateRightButton:Hide()
		local modelControl = CreateFrame("FRAME", nil, modelScene, "MJControlFrameTemplate")
		modelControl:SetPoint("BOTTOM", -70, 10)
		modelControl.zoomIn.icon:SetTexCoord(0.57812500, 0.82812500, 0.14843750, 0.27343750)
		modelControl.zoomOut.icon:SetTexCoord(0.29687500, 0.54687500, 0.00781250, 0.13281250)
		modelControl.panButton.icon:SetTexCoord(0.29687500, 0.54687500, 0.28906250, 0.41406250)
		modelControl.rotateLeftButton.icon:SetTexCoord(0.01562500, 0.26562500, 0.28906250, 0.41406250)
		modelControl.rotateRightButton.icon:SetTexCoord(0.57812500, 0.82812500, 0.28906250, 0.41406250)
		modelControl.rotateUpButton.icon:SetTexCoord(0.01562500, 0.26562500, 0.28906250, 0.41406250)
		modelControl.rotateUpButton.icon:SetRotation(-math.pi / 1.6, .5, .43)
		modelControl.rotateDownButton.icon:SetTexCoord(0.57812500, 0.82812500, 0.41406250, 0.28906250)
		modelControl.rotateDownButton.icon:SetRotation(-math.pi / 1.6)

		hooksecurefunc(modelScene, "SetActiveCamera", function(self)
			local activeCamera = self.activeCamera

			local ApplyFromModelSceneCameraInfo = activeCamera.ApplyFromModelSceneCameraInfo
			function activeCamera:ApplyFromModelSceneCameraInfo(modelSceneCameraInfo, ...)
				modelSceneCameraInfo.target.z = mountDescriptionToggle:GetChecked() and 2.2 or 1
				ApplyFromModelSceneCameraInfo(self, modelSceneCameraInfo, ...)
			end

			activeCamera:SetLeftMouseButtonYMode(ORBIT_CAMERA_MOUSE_MODE_PITCH_ROTATION, true)
			activeCamera:SetRightMouseButtonXMode(ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL, true)
			activeCamera:SetRightMouseButtonYMode(ORBIT_CAMERA_MOUSE_PAN_VERTICAL, true)

			activeCamera.deltaModifierForCameraMode = {
				[ORBIT_CAMERA_MOUSE_MODE_YAW_ROTATION] = activeCamera:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_YAW_ROTATION),
				[ORBIT_CAMERA_MOUSE_MODE_PITCH_ROTATION] = -activeCamera:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_PITCH_ROTATION),
				[ORBIT_CAMERA_MOUSE_MODE_ROLL_ROTATION] = activeCamera:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_ROLL_ROTATION),
				[ORBIT_CAMERA_MOUSE_MODE_ZOOM] = activeCamera:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_ZOOM),
				[ORBIT_CAMERA_MOUSE_MODE_TARGET_HORIZONTAL] = activeCamera:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_TARGET_HORIZONTAL),
				[ORBIT_CAMERA_MOUSE_MODE_TARGET_VERTICAL] = activeCamera:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_MODE_TARGET_VERTICAL),
				[ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL] = activeCamera:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL),
				[ORBIT_CAMERA_MOUSE_PAN_VERTICAL] = activeCamera:GetDeltaModifierForCameraMode(ORBIT_CAMERA_MOUSE_PAN_VERTICAL),
			}
			setmetatable(activeCamera.deltaModifierForCameraMode, {__index = function()
				return 0
			end})
			function activeCamera:GetDeltaModifierForCameraMode(mode)
				return self.deltaModifierForCameraMode[mode]
			end
		end)

		modelControl.panButton:HookScript("OnMouseDown", function(self)
			self:GetParent():GetParent().isRightButtonDown = true
		end)
		modelControl.panButton:HookScript("OnMouseUp", function(self)
			self:GetParent():GetParent().isRightButtonDown = false
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
			local activeCamera = self:GetParent():GetParent().activeCamera
			activeCamera:ApplyFromModelSceneCameraInfo(activeCamera.modelSceneCameraInfo)
		end)

		-- MOUNT ANIMATIONS
		local animationsCombobox = CreateFrame("FRAME", "MountsJournalAnimations", modelScene, "UIDropDownMenuTemplate")
		animationsCombobox:SetPoint("LEFT", modelControl, "RIGHT", -5, -2)
		local animationsList = {
			{
				name = L["Default"],
				animation = 0,
			},
			{
				name = L["Mount special"],
				animation = 1371,
				isKit = true,
			},
			{
				name = L["Walk"],
				animation = 4,
				type = 2,
			},
			{
				name = L["Walk backwards"],
				animation = 13,
				type = 2,
			},
			{
				name = L["Run"],
				animation = 5,
				type = 2,
			},
			{
				name = L["Swim idle"],
				animation = 532,
				type = 3,
			},
			{
				name = L["Swim"],
				animation = 540,
				type = 3,
			},
			{
				name = L["Swim backwards"],
				animation = 534,
				type = 3,
			},
			{
				name = L["Fly stand"],
				animation = 548,
				type = 1,
			},
			{
				name = L["Fly"],
				animation = 558,
				type = 1,
			},
			{
				name = L["Fly backwards"],
				animation = 562,
				type = 1,
			},
		}

		local function mountPlayAnimation(animation, isKit)
			local actor = modelScene:GetActorByTag("unwrapped")
			actor:StopAnimationKit()
			if isKit then
				actor:PlayAnimationKit(animation)
			else
				actor:SetAnimation(animation)
			end
		end

		local currentMountType
		UIDropDownMenu_Initialize(animationsCombobox, function()
			local info = UIDropDownMenu_CreateInfo()
			local mountType = self.mountTypes[currentMountType] or 1
			if currentMountType == 231 then mountType = mountType - 1 end
			for _, v in ipairs(animationsList) do
				if v.type == nil or v.type >= mountType then
					info.checked = nil
					info.text = v.name
					info.value = v
					info.func = function(self)
						mountPlayAnimation(self.value.animation, self.value.isKit)
						UIDropDownMenu_SetSelectedValue(animationsCombobox, self.value)
					end
					UIDropDownMenu_AddButton(info)
				end
			end
		end)

		hooksecurefunc("MountJournal_Select", function(index)
			local actor = modelScene:GetActorByTag("unwrapped")
			if actor then
				actor:StopAnimationKit()
			end
			local mountID = select(12, C_MountJournal.GetDisplayedMountInfo(index))
			if mountID then
				currentMountType = select(5, C_MountJournal.GetMountInfoExtraByID(mountID))
			end
			UIDropDownMenu_SetSelectedValue(animationsCombobox, animationsList[1])
			UIDropDownMenu_SetText(animationsCombobox, animationsList[1].name)
			infoButton.petSelectionBtn:refresh()
			infoButton.petSelectionBtn.petSelectionList:Hide()
		end)

		-- PLAYER SHOW BUTTON
		modelScene.TogglePlayer:Hide()
		local playerToggle = CreateFrame("CheckButton", nil, modelScene, "MJPlayerShowToggle")
		playerToggle:SetPoint("LEFT", animationsCombobox, "RIGHT", 232, 5)
		function playerToggle:setPortrait() SetPortraitTexture(self.portrait, "player") end
		playerToggle:SetScript("OnEvent", playerToggle.setPortrait)
		playerToggle:HookScript("OnShow", function(self)
			self:setPortrait()
			self:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "player")
		end)
		playerToggle:SetScript("OnHide", function(self)
			self:UnregisterEvent("UNIT_PORTRAIT_UPDATE")
		end)
		playerToggle:HookScript("OnClick", function(self)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			C_Timer.After(0, function()
				local value = animationsCombobox.selectedValue
				mountPlayAnimation(value.animation, value.isKit)
			end)
		end)

		-- HOOKS
		self.func = {}
		self:setSecureFunc(C_MountJournal, "GetNumDisplayedMounts", function() return #self.displayedMounts end)
		self:setSecureFunc(C_MountJournal, "GetDisplayedMountInfo")
		self:setSecureFunc(C_MountJournal, "Pickup")
		self:setSecureFunc(C_MountJournal, "SetIsFavorite")
		self:setSecureFunc(C_MountJournal, "GetIsFavorite")
		self:setSecureFunc(C_MountJournal, "GetDisplayedMountInfoExtra")
		self:setSecureFunc(C_MountJournal, "GetDisplayedMountAllCreatureDisplayInfo")

		hooksecurefunc("MountJournal_UpdateMountList", function() self:configureJournal() end)
		scrollFrame.update = MountJournal_UpdateMountList

		local fullUpdate = MountJournal_FullUpdate
		function MountJournal_FullUpdate(self)
			if self:IsVisible() then
				journal:updateBtnFilters()
				journal:updateMountsList()
			end
			fullUpdate(self)
		end

		-- FILTERS
		MountJournalFilterDropDown.initialize = function(_, level) self:filterDropDown_Initialize(level) end
		self:setEditMountsList()
	end
end


function journal:setEditMountsList()
	self.db = mounts.charDB.currentProfileName and mounts.profiles[mounts.charDB.currentProfileName] or mounts.globalDB
	local mapID = self.navBar.mapID
	if mapID == mounts.defMountsListID then
		self.currentList = {
			fly = self.db.fly,
			ground = self.db.ground,
			swimming = self.db.swimming,
		}
		self.list = self.currentList
		self.listMapID = nil
	else
		local function getRelationMountList(mapID)
			local list = self.db.zoneMounts[mapID]
			if list and list.listFromID then
				return getRelationMountList(list.listFromID)
			end
			return list, mapID
		end
		self.currentList = self.db.zoneMounts[mapID]
		self.list, self.listMapID = getRelationMountList(mapID)
	end

	self.mountListUpdateAnim:Stop()
	self.mountListUpdateAnim:Play()
end


function journal:ACHIEVEMENT_EARNED()
	self.achiev.text:SetText(GetCategoryAchievementPoints(MOUNT_ACHIEVEMENT_CATEGORY, true))
end


function journal:configureJournal()
	local function setColor(btn, mountsTbl)
		if mountsTbl and util.inTable(mountsTbl, btn.mountID) then
			btn.icon:SetVertexColor(self.colors.gold:GetRGB())
			if not btn.check:IsShown() then btn.check:Show() end
		else
			btn.icon:SetVertexColor(self.colors.gray:GetRGB())
			if btn.check:IsShown() then btn.check:Hide() end
		end
	end

	for _, btn in ipairs(self.scrollButtons) do
		if btn.index then
			if not btn.fly:IsShown() then
				btn.fly:Show()
				btn.ground:Show()
				btn.swimming:Show()
			end
			btn.fly.mountID = select(12, C_MountJournal.GetDisplayedMountInfo(btn.index))
			btn.ground.mountID = btn.fly.mountID
			btn.swimming.mountID = btn.fly.mountID
			setColor(btn.fly, self.list and self.list.fly)
			setColor(btn.ground, self.list and self.list.ground)
			setColor(btn.swimming, self.list and self.list.swimming)
		else
			if btn.fly:IsShown() then
				btn.fly:Hide()
				btn.ground:Hide()
				btn.swimming:Hide()
			end
		end
	end

	self.mountCount.Count:SetText(self.mountCount.Count.num)
end


function journal:setCountMounts()
	local count, collected = 0, 0
	for _, mountID in ipairs(C_MountJournal.GetMountIDs()) do
		local _,_,_,_,_,_,_,_,_, hideOnChar, isCollected = C_MountJournal.GetMountInfoByID(mountID)
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
journal.COMPANION_LEARNED = journal.setCountMounts
journal.COMPANION_UNLEARNED = journal.setCountMounts


function journal:createMountList(mapID)
	self.db.zoneMounts[mapID] = {
		fly = {},
		ground = {},
		swimming = {},
		flags = {},
	}
	self:setEditMountsList()
end


function journal:getRemoveMountList(mapID)
	if not mapID then return end
	local list = self.db.zoneMounts[mapID]

	local flags
	for _, value in pairs(list.flags) do
		if value then
			flags = true
			break
		end
	end

	if #list.fly + #list.ground + #list.swimming == 0
	and not flags
	and not list.listFromID then
		self.db.zoneMounts[mapID] = nil
		self:setEditMountsList()
	end
end


function journal:mountToggle(btn)
	if not self.list then
		self:createMountList(self.listMapID)
	end
	local tbl = self.list[btn.type]

	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	local pos = util.inTable(tbl, btn.mountID)
	if pos then
		tremove(tbl, pos)
		btn.icon:SetVertexColor(self.colors.gray:GetRGB())
		btn.check:Hide()
		self:getRemoveMountList(self.listMapID)
	else
		tinsert(tbl, btn.mountID)
		btn.icon:SetVertexColor(self.colors.gold:GetRGB())
		btn.check:Show()
	end

	mounts:setMountsList()
	self.existingsLists:refresh()
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
	self.existingsLists:refresh()
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
		for mapID, mapConfig in pairs(self.db.zoneMounts) do
			if not mapConfig.listFromID 
			and mapID ~= self.navBar.mapID
			and #mapConfig.fly + #mapConfig.ground + #mapConfig.swimming > 0 then
				local mapInfo = util.getMapFullNameInfo(mapID)

				if not assocMaps[mapInfo.mapType] then
					assocMaps[mapInfo.mapType] = {
						name = mapLangTypes[mapInfo.mapType] or OTHER,
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
		ToggleDropDownMenu(1, nil, btn.optionsMenu, btn, 115, 15)
	end
end


function journal:listFromMapInit(level)
	if not level then return end

	local btn = self:GetParent()
	local info = UIDropDownMenu_CreateInfo()
	info.isNotRadio = true
	info.notCheckable = true

	if next(btn.maps) == nil then
		info.notClickable = true
		info.text = EMPTY
		UIDropDownMenu_AddButton(info, level)
	else
		local list = UIDROPDOWNMENU_MENU_VALUE or btn.maps

		local function setListFrom(_, mapID)
			if journal.navBar.mapID == mapID then return end
			if not journal.currentList then
				journal:createMountList(journal.navBar.mapID)
			end
			journal.currentList.listFromID = mapID
			journal:setEditMountsList()
			journal:updateMountsList()
			MountJournal_UpdateMountList()
			journal:updateMapSettings()
			mounts:setMountsList()
			journal.existingsLists:refresh()
			CloseDropDownMenus()
		end

		for _, mapInfo in ipairs(list) do
			if mapInfo.mapID then
				info.text = mapInfo.name
				info.func = setListFrom
				info.arg1 = mapInfo.mapID
			else
				info.keepShownOnClick = true
				info.hasArrow = true
				info.text = mapInfo.name
				info.value = mapInfo.list
			end
			UIDropDownMenu_AddButton(info, level)
		end
	end
end


function journal:updateMapSettings()
	local mapSettings = self.mapSettings
	if not mapSettings:IsShown() then return end

	local groundCheck = mapSettings.Ground
	local waterWalkCheck = mapSettings.WaterWalk
	local herbGathering = mapSettings.HerbGathering
	local listFromMap = mapSettings.listFromMap
	groundCheck:SetChecked(self.currentList and self.currentList.flags and self.currentList.flags.groundOnly)
	waterWalkCheck:SetChecked(self.currentList and self.currentList.flags and self.currentList.flags.waterWalkOnly)
	herbGathering:SetChecked(self.currentList and self.currentList.flags and self.currentList.flags.herbGathering)

	local optionsEnable = self.navBar.mapID ~= mounts.defMountsListID
	groundCheck:SetEnabled(optionsEnable)
	waterWalkCheck:SetEnabled(optionsEnable)
	herbGathering:SetEnabled(optionsEnable)
	listFromMap:SetEnabled(optionsEnable)

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


do
	local lastMountClick = 0
	local lastMountIndex = 0
	function journal:mountDblClick(index, btn)
		if btn == "RightButton" then return end

		if lastMountIndex == index and GetTime() - lastMountClick < 0.4 then
			local _,_,_, active, isUsable, _,_,_,_,_,_, mountID = C_MountJournal.GetDisplayedMountInfo(index)
			if active then
				C_MountJournal.Dismiss()
			elseif isUsable then
				C_MountJournal.SummonByID(mountID)
			end
		else
			lastMountIndex = index
			lastMountClick = GetTime()
		end
	end
end


function journal:setSecureFunc(obj, funcName, func)
	if self.func[funcName] ~= nil then return end

	self.func[funcName] = obj[funcName]
	if func then
		obj[funcName] = func
	else
		obj[funcName] = function(index, ...)
			return self.func[funcName](self.displayedMounts[index], ...)
		end
	end
end


function journal:filterDropDown_Initialize(level)
	local info = UIDropDownMenu_CreateInfo()
	info.keepShownOnClick = true
	info.isNotRadio = true

	if level == 1 then
		info.text = COLLECTED
		info.func = function(_,_,_, value)
			C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED, value)
		end
		info.checked = C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED)
		UIDropDownMenu_AddButton(info, level)

		info.text = NOT_COLLECTED
		info.func = function(_,_,_, value)
			C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED, value)
		end
		info.checked = C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED)
		UIDropDownMenu_AddButton(info, level)

		info.text = MOUNT_JOURNAL_FILTER_UNUSABLE
		info.func = function(_,_,_, value)
			C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE, value)
		end
		info.checked = C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE)
		UIDropDownMenu_AddButton(info, level)

		info.checked = nil
		info.isNotRadio = nil
		info.func =  nil
		info.hasArrow = true
		info.notCheckable = true

		info.text = L["types"]
		info.value = 1
		UIDropDownMenu_AddButton(info, level)

		info.text = L["selected"]
		info.value = 2
		UIDropDownMenu_AddButton(info, level)

		info.text = SOURCES
		info.value = 3
		UIDropDownMenu_AddButton(info, level)

		info.text = L["factions"]
		info.value = 4
		UIDropDownMenu_AddButton(info, level)

		info.text = PET
		info.value = 5
		UIDropDownMenu_AddButton(info, level)

		info.text = L["expansions"]
		info.value = 6
		UIDropDownMenu_AddButton(info, level)
	else
		info.notCheckable = true

		if UIDROPDOWNMENU_MENU_VALUE == 1 then -- TYPES
			info.text = CHECK_ALL
			info.func = function()
				self:setAllFilters("types", true)
				self:mountsListFullUpdate()
				UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
			end
			UIDropDownMenu_AddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				self:setAllFilters("types", false)
				self:mountsListFullUpdate()
				UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
			end
			UIDropDownMenu_AddButton(info, level)

			info.notCheckable = false
			local types = mounts.filters.types
			for i = 1, #types do
				info.text = L["MOUNT_TYPE_"..i]
				info.func = function(_,_,_, value)
					types[i] = value
					self:mountsListFullUpdate()
				end
				info.checked = function() return types[i] end
				UIDropDownMenu_AddButton(info, level)
			end
		elseif UIDROPDOWNMENU_MENU_VALUE == 2 then -- SELECTED
			info.text = CHECK_ALL
			info.func = function()
				self:setAllFilters("selected", true)
				self:mountsListFullUpdate()
				UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
			end
			UIDropDownMenu_AddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				self:setAllFilters("selected", false)
				self:mountsListFullUpdate()
				UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
			end
			UIDropDownMenu_AddButton(info, level)

			info.notCheckable = false
			local selected = mounts.filters.selected
			for i = 1, #selected do
				info.text = L["MOUNT_TYPE_"..i]
				info.func = function(_,_,_, value)
					selected[i] = value
					self:mountsListFullUpdate()
				end
				info.checked = function() return selected[i] end
				UIDropDownMenu_AddButton(info, level)
			end
		elseif UIDROPDOWNMENU_MENU_VALUE == 3 then -- SOURCES
			info.text = CHECK_ALL
			info.func = function()
				C_MountJournal.SetAllSourceFilters(true)
				UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
			end
			UIDropDownMenu_AddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				C_MountJournal.SetAllSourceFilters(false)
				UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
			end
			UIDropDownMenu_AddButton(info, level)

			info.notCheckable = false
			for i = 1, C_PetJournal.GetNumPetSources() do
				if C_MountJournal.IsValidSourceFilter(i) then
					info.text = _G["BATTLE_PET_SOURCE_"..i]
					info.func = function(_,_,_, value)
						C_MountJournal.SetSourceFilter(i, value)
					end
					info.checked = function() return C_MountJournal.IsSourceChecked(i) end
					UIDropDownMenu_AddButton(info, level)
				end
			end
		elseif UIDROPDOWNMENU_MENU_VALUE == 4 then -- FACTIONS
			info.text = CHECK_ALL
			info.func = function()
				self:setAllFilters("factions", true)
				self:mountsListFullUpdate()
				UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
			end
			UIDropDownMenu_AddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				self:setAllFilters("factions", false)
				self:mountsListFullUpdate()
				UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
			end
			UIDropDownMenu_AddButton(info, level)

			info.notCheckable = false
			local factions = mounts.filters.factions
			for i = 1, #factions do
				info.text = L["MOUNT_FACTION_"..i]
				info.func = function(_,_,_, value)
					factions[i] = value
					self:mountsListFullUpdate()
				end
				info.checked = function() return factions[i] end
				UIDropDownMenu_AddButton(info, level)
			end
		elseif UIDROPDOWNMENU_MENU_VALUE == 5 then -- PET
			info.text = CHECK_ALL
			info.func = function()
				self:setAllFilters("pet", true)
				self:mountsListFullUpdate()
				UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
			end
			UIDropDownMenu_AddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				self:setAllFilters("pet", false)
				self:mountsListFullUpdate()
				UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
			end
			UIDropDownMenu_AddButton(info, level)

			info.notCheckable = false
			local pet = mounts.filters.pet
			for i = 1, #pet do
				info.text = L["PET_"..i]
				info.func = function(_,_,_, value)
					pet[i] = value
					self:mountsListFullUpdate()
				end
				info.checked = function() return pet[i] end
				UIDropDownMenu_AddButton(info, level)
			end
		else -- EXPANSIONS
			info.text = CHECK_ALL
			info.func = function()
				self:setAllFilters("expansions", true)
				self:mountsListFullUpdate()
				UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
			end
			UIDropDownMenu_AddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				self:setAllFilters("expansions", false)
				self:mountsListFullUpdate()
				UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
			end
			UIDropDownMenu_AddButton(info, level)

			info.notCheckable = false
			local expansions = mounts.filters.expansions
			for i = 1, EJ_GetNumTiers() do
				info.text = _G["EXPANSION_NAME"..(i - 1)]
				info.func = function(_,_,_, value)
					expansions[i] = value
					self:mountsListFullUpdate()
				end
				info.checked = function() return expansions[i] end
				UIDropDownMenu_AddButton(info, level)
			end
		end
	end
end


function journal:clearBtnFilters()
	C_MountJournal.SetAllSourceFilters(true)
	self:setAllFilters("types", true)
	self:setAllFilters("selected", false)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	self:mountsListFullUpdate()
end


function journal:clearAllFilters()
	C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED, true)
	C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED, true)
	C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE, true)
	self:setAllFilters("factions", true)
	self:setAllFilters("pet", true)
	self:setAllFilters("expansions", true)
	self:clearBtnFilters()
end


function journal:setBtnFilters(tab)
	local i = 0
	local children = self.filtersBar[tab].childs

	if tab ~= "sources" then
		local default = tab == "types"
		local filters = mounts.filters[tab]

		for _, btn in ipairs(children) do
			local checked = btn:GetChecked()
			filters[btn.id] = checked
			if not checked and default then i = i + 1 end
		end

		if i == #filters then
			for k in ipairs(filters) do
				filters[k] = default
			end
		end
	else
		MountJournal:SetScript("OnEvent", nil)
		C_MountJournal.SetAllSourceFilters(false)
		for _, btn in ipairs(children) do
			local checked = btn:GetChecked()
			C_MountJournal.SetSourceFilter(btn.id, checked)
			if not checked then i = i + 1 end
		end

		if i == #children then
			C_MountJournal.SetAllSourceFilters(true)
		end
		MountJournal:SetScript("OnEvent", MountJournal_OnEvent)
	end

	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	self:mountsListFullUpdate()
end


function journal:setAllFilters(type, enabled)
	local filters = mounts.filters[type]
	for k in ipairs(filters) do
		filters[k] = enabled
	end
end


function journal:updateBtnFilters()
	local filtersBar, f = self.filtersBar, {}

	-- TYPES AND SELECTED
	for typeFilter, filter in pairs(mounts.filters) do
		local default = typeFilter ~= "selected"
		local i = 0
		for _, v in ipairs(filter) do
			if v == default then i = i + 1 end
		end

		if i == #filter then
			if filtersBar[typeFilter] then
				for _, btn in ipairs(filtersBar[typeFilter].childs) do
					local color = default and self.colors["mount"..btn.id] or self.colors.dark
					btn:SetChecked(false)
					btn.icon:SetVertexColor(color:GetRGB())
				end
				filtersBar[typeFilter]:GetParent().filtred:Hide()
			end
		else
			f[typeFilter] = true
			f.checked = true
			if filtersBar[typeFilter] then
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

	-- SOURCES
	local sources, n = {}, 0

	for i = 1, C_PetJournal.GetNumPetSources() do
		if C_MountJournal.IsValidSourceFilter(i) then
			local checked = C_MountJournal.IsSourceChecked(i)
			sources[i] = checked
			if checked then n = n + 1 end
		end
	end

	if n == #sources - 1 then
		C_MountJournal.SetAllSourceFilters(true)
		for _, btn in ipairs(filtersBar.sources.childs) do
			btn:SetChecked(false)
			btn.icon:SetDesaturated()
		end
		filtersBar.sources:GetParent().filtred:Hide()
	else
		f.sources = true
		f.checked = true
		for _, btn in ipairs(filtersBar.sources.childs) do
			btn:SetChecked(sources[btn.id])
			btn.icon:SetDesaturated(not sources[btn.id])
		end
		filtersBar.sources:GetParent().filtred:Show()
	end

	-- CLEAR BTN FILTERS
	filtersBar.clear:SetShown(f.types or f.selected or f.sources)
	if not C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED) or not C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED) or not C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE) or f.checked then
		self.shownPanel:Show()
		self.leftInset:SetPoint("TOPLEFT", self.shownPanel, "BOTTOMLEFT", 0, -2)
	else
		self.shownPanel:Hide()
		self.leftInset:SetPoint("TOPLEFT", self.filtersPanel, "BOTTOMLEFT", 0, -2)
	end

	self.leftInset:GetHeight()
end


function journal:mountsListFullUpdate()
	self:updateBtnFilters()
	self:updateMountsList()
	MountJournal_UpdateMountList()
end


function journal:updateMountsList()
	local types, selected, factions, pet, expansions, list, GetDisplayedMountInfo, GetMountInfoExtraByID = mounts.filters.types, mounts.filters.selected, mounts.filters.factions, mounts.filters.pet, mounts.filters.expansions, self.list, self.func.GetDisplayedMountInfo, C_MountJournal.GetMountInfoExtraByID
	wipe(self.displayedMounts)

	for i = 1, self.func.GetNumDisplayedMounts() do
		local _, spellID, _,_,_,_,_,_, mountFaction, _,_, mountID = GetDisplayedMountInfo(i)
		local _,_,_,_, mountType = GetMountInfoExtraByID(mountID)
		local petID = self.db.petForMount[spellID]
		mountFaction = mountFaction or 2

		-- TYPE
		if types[self.mountTypes[mountType]]
		-- FACTION
		and factions[mountFaction + 1]
		-- SELECTED
		and (not selected[1] and not selected[2] and not selected[3]
			-- FLY
			or selected[1] and list and util.inTable(list.fly, mountID)
			-- GROUND
			or selected[2] and list and util.inTable(list.ground, mountID)
			-- SWIMMING
			or selected[3] and list and util.inTable(list.swimming, mountID))
		-- PET
		and pet[petID and (type(petID) == "number" and petID or 3) or 4]
		-- EXPANSIONS
		and expansions[mounts.mountsDB[mountID]] then
			tinsert(self.displayedMounts, i)
		end
	end
	self.shownPanel.count:SetText(#self.displayedMounts)
end