local addon, L = ...
local mounts, config = MountsJournal, MountsJournalConfig
local journal = MountsJournalFrame


local COLLECTION_ACHIEVEMENT_CATEGORY = 15246
local MOUNT_ACHIEVEMENT_CATEGORY = 15248


journal.colors = {
	gold = {0.8, 0.6, 0},
	gray = {0.5, 0.5, 0.5},
	dark = {0.3, 0.3, 0.3},
	mount1 = {0.824, 0.78, 0.235},
	mount2 = {0.42, 0.302, 0.224},
	mount3 = {0.031, 0.333, 0.388},
}


journal.displayedMounts = {}
setmetatable(journal.displayedMounts, {__index = function(self, key)
	return key
end})


local function tabClick(self)
	local id = self.id

	for _, tab in pairs(self:GetParent().tabs) do
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
		local tab = CreateFrame("Button", nil, frame, "MJTabTemplate")
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
	if journal[event] then
		journal[event](self, ...)
	end
end)
journal:RegisterEvent("ADDON_LOADED")


function journal:ADDON_LOADED(addonName)
	if addonName == "Blizzard_Collections" and IsAddOnLoaded(addon) or addonName == addon and IsAddOnLoaded("Blizzard_Collections") then
		self:UnregisterEvent("ADDON_LOADED")

		local texPath = "Interface/AddOns/MountsJournal/textures/"
		local scrollFrame = MountJournal.ListScrollFrame
		journal.scrollButtons = scrollFrame.buttons
		journal.leftInset = MountJournal.LeftInset
		mounts.filters.types = mounts.filters.types or {true, true, true}
		mounts.filters.selected = mounts.filters.selected or {false, false, false}
		mounts.filters.factions = mounts.filters.factions or {true, true, true}
		mounts.filters.expansions = mounts.filters.expansions or {true, true, true, true, true, true, true, true}

		-- MOUNT COUNT
		local mountCount = MountJournal.MountCount
		journal.mountCount = mountCount
		mountCount:SetPoint("TOPLEFT", 70, -25)
		mountCount:SetHeight(34)
		mountCount.Count:SetPoint("RIGHT", -10, 6)
		mountCount.Label:SetPoint("LEFT", 10, 6)
		mountCount.collected = mountCount:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		mountCount.collected:SetPoint("RIGHT", -10, -6)
		mountCount.collectedLabel = mountCount:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		mountCount.collectedLabel:SetPoint("LEFT", 10, -6)
		mountCount.collectedLabel:SetText(L["Collected:"])

		-- SETTINGS BUTTON
		local btnConfig = CreateFrame("Button", "MountsJournalBtnConfig", MountJournal, "UIPanelButtonTemplate")
		btnConfig:SetSize(80, 22)
		btnConfig:SetPoint("BOTTOMRIGHT", -6, 4)
		btnConfig:SetText(L["Settings"])
		btnConfig:SetScript("OnClick", config.openConfig)

		-- ACHIEVEMENT
		journal.achiev:SetParent(MountJournal)
		journal.achiev:SetPoint("TOP", 0, -21)
		journal:ACHIEVEMENT_EARNED()
		journal.achiev:SetScript("OnClick", function()
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

		-- PER CHARACTER CHECK
		local perCharCheck = CreateFrame("CheckButton", nil, MountJournal, "InterfaceOptionsCheckButtonTemplate")
		perCharCheck:SetPoint("LEFT", MountJournal.MountButton, "RIGHT", 6, -2)
		perCharCheck.Text:SetFont("GameFontHighlight", 30)
		perCharCheck.Text:SetPoint("LEFT", perCharCheck, "RIGHT", 1, 1)
		perCharCheck.Text:SetText(L["Character Specific Mount List"])
		perCharCheck:SetChecked(mounts.perChar)
		perCharCheck:SetScript("OnClick", function(self)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			mounts:setMountsList(self:GetChecked())
			journal:configureJournal()
		end)

		-- SELECTED BUTTONS
		local function CreateButton(name, parent, pointX, pointY, OnClick)
			local btnFrame = CreateFrame("button", nil, parent)
			btnFrame:SetPoint("TOPRIGHT", pointX, pointY)
			btnFrame:SetSize(24, 12)
			btnFrame:SetScript("OnClick", OnClick)
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
			btnFrame.check:SetVertexColor(unpack(journal.colors.gold))
			btnFrame.check:SetAllPoints()

			btnFrame.icon = btnFrame:CreateTexture(nil, "OVERLAY")
			btnFrame.icon:SetTexture(texPath..name)
			btnFrame.icon:SetAllPoints()

			btnFrame:SetScript("OnMouseDown", function(self)
				self.icon:SetPoint("TOPLEFT", 1, -1)
				self.icon:SetPoint("BOTTOMRIGHT", -1, 1)
			end)
			btnFrame:SetScript("OnMouseUp", function(self)
				self.icon:SetAllPoints()
			end)
		end

		for _, child in pairs(journal.scrollButtons) do
			child:SetWidth(child:GetWidth() - 25)
			child.name:SetWidth(child.name:GetWidth() - 18)

			CreateButton("fly", child, 25, -3, function(self)
				journal:mountToggle(mounts.list.fly, self)
			end)
			CreateButton("ground", child, 25, -17, function(self)
				journal:mountToggle(mounts.list.ground, self)
			end)
			CreateButton("swimming", child, 25, -31, function(self)
				journal:mountToggle(mounts.list.swimming, self)
			end)
		end

		-- FILTERS PANEL
		local filtersPanel = CreateFrame("FRAME", nil, MountJournal, "InsetFrameTemplate")
		journal.filtersPanel = filtersPanel
		filtersPanel:SetPoint("TOPLEFT", 4, -60)
		filtersPanel:SetSize(280, 29)

		MountJournal.searchBox:SetPoint("TOPLEFT", filtersPanel, "TOPLEFT", 33, -4)
		MountJournal.searchBox:SetSize(151, 20)
		MountJournalFilterButton:SetPoint("TOPRIGHT", filtersPanel, "TOPRIGHT", -3, -4)

		-- FILTERS SHOWN PANEL
		local shownPanel = CreateFrame("FRAME", nil, MountJournal, "InsetFrameTemplate")
		journal.shownPanel = shownPanel
		shownPanel:SetPoint("TOPLEFT", filtersPanel, "BOTTOMLEFT", 0, -2)
		shownPanel:SetSize(280, 26)
		
		shownPanel.text = shownPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		shownPanel.text:SetPoint("LEFT", 8, -1)
		shownPanel.text:SetText(L["Shown:"])
		
		shownPanel.count = shownPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		shownPanel.count:SetPoint("LEFT", shownPanel.text ,"RIGHT", 2, 0)

		shownPanel.clear = CreateFrame("button", nil, shownPanel, "MJClearButtonTemplate")
		shownPanel.clear:SetPoint("RIGHT", -5, 0)
		shownPanel.clear:SetScript("OnClick", journal.clearAllFilters)

		-- SCROLL FRAME
		journal.leftInset:SetPoint("TOPLEFT", shownPanel, "BOTTOMLEFT", 0, -2)
		scrollFrame:SetPoint("TOPLEFT", journal.leftInset, "TOPLEFT", 3, -5)
		scrollFrame.scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 1, -12)

		-- FILTERS BAR
		local filtersBar = CreateFrame("FRAME", nil, filtersPanel)
		journal.filtersBar = filtersBar
		filtersBar:SetSize(235, 35)
		filtersBar:SetPoint("TOP", 0, -46)
		filtersBar:SetBackdrop({
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true,
			edgeSize = 16,
		})
		filtersBar:SetBackdropBorderColor(0.6, 0.6, 0.6)
		filtersBar.types, filtersBar.selected, filtersBar.sources = setTabs(filtersBar, "types", "selected", "sources")

		-- FILTERS CLEAR
		filtersBar.clear = CreateFrame("button", nil, filtersBar, "MJClearButtonTemplate")
		filtersBar.clear:SetPoint("BOTTOMRIGHT", filtersBar, "TOPRIGHT")
		filtersBar.clear:SetScript("OnClick", journal.clearBtnFilters)

		-- FILTERS BUTTONS
		local function CreateButtonFilter(id, parent, width, height, texture, tooltip)
			local btn = CreateFrame("CheckButton", nil, parent)
			btn.id = id
			btn:SetSize(width, height)
			if id == 1 then
				btn:SetPoint("LEFT", 5, 0)
			else
				local children = {parent:GetChildren()}
				btn:SetPoint("LEFT", children[#children - 1], "RIGHT")
			end

			if width ~= height then
				btn:SetHighlightTexture(texPath.."button")
				btn:SetCheckedTexture("Interface/BUTTONS/ListButtons")
				local hightlight, checked = btn:GetRegions()
				hightlight:SetAlpha(0.8)
				hightlight:SetTexCoord(0.00390625, 0.8203125, 0.19140625, 0.37109375)
				checked:SetAlpha(0.8)
				checked:SetTexCoord(0.00390625, 0.8203125, 0.37890625, 0.55859375)
			else
				btn:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
				btn:SetCheckedTexture("Interface/Buttons/CheckButtonHilight")
				local hightlight, checked = btn:GetRegions()
				hightlight:SetBlendMode("ADD")
				checked:SetAlpha(0.6)
				checked:SetBlendMode("ADD")
			end

			btn:SetBackdrop({
				edgeFile = texPath.."border",
				tile = true,
				edgeSize = 8,
			})
			btn:SetBackdropBorderColor(0.4, 0.4, 0.4)

			btn.icon = btn:CreateTexture(nil, "OVERLAY")
			btn.icon:SetTexture(texture.path)
			btn.icon:SetSize(texture.width, texture.height)
			btn.icon:SetPoint("CENTER")
			if texture.color then btn.icon:SetVertexColor(unpack(texture.color)) end
			if texture.texCoord then btn.icon:SetTexCoord(unpack(texture.texCoord)) end

			btn:SetScript("OnMouseDown", function()
				btn.icon:SetSize(texture.width - 2, texture.height - 2)
			end)
			btn:SetScript("OnMouseUp", function()
				btn.icon:SetSize(texture.width, texture.height)
			end)
			btn:SetScript("OnEnter", function()
				GameTooltip:SetOwner(btn, "ANCHOR_BOTTOM")
				GameTooltip:SetText(tooltip)
				GameTooltip:Show()
			end)
			btn:SetScript("OnLeave", function()
				GameTooltip_Hide()
			end)
			btn:SetScript("OnClick", function(self)
				journal:setBtnFilters(self:GetParent():GetParent().id)
			end)
		end

		--  FILTERS TYPES BUTTONS
		local typesTextures = {
			{path = texPath.."fly", color = journal.colors.mount1, width = 32, height = 16},
			{path = texPath.."ground", color = journal.colors.mount2, width = 32, height = 16},
			{path = texPath.."swimming", color = journal.colors.mount3, width = 32, height = 16},
		}

		for i = 1, #typesTextures do
			CreateButtonFilter(i, filtersBar.types, 75, 25, typesTextures[i], L["MOUNT_TYPE_"..i])
		end

		-- FILTERS SELECTED BUTTONS
		for i = 1, #typesTextures do
			CreateButtonFilter(i, filtersBar.selected, 75, 25, typesTextures[i], L["MOUNT_TYPE_"..i])
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
		}

		for i = 1, #sourcesTextures do
			if sourcesTextures[i] then
				CreateButtonFilter(i, filtersBar.sources, 25, 25, sourcesTextures[i], _G["BATTLE_PET_SOURCE_"..i])
			end
		end

		-- FILTERS BTN TOGGLE
		journal.btnToggle:SetParent(filtersPanel)
		journal.btnToggle:SetPoint("TOPLEFT", 3, -3)

		local function setBtnToggleCheck()
			if mounts.config.filterToggle then
				journal.btnToggle.icon:SetPoint("CENTER", 0, 1)
				journal.btnToggle.icon:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)
				filtersPanel:SetHeight(84)
				filtersBar:Show()
			else
				journal.btnToggle.icon:SetPoint("CENTER", 0, -1)
				journal.btnToggle.icon:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)
				filtersPanel:SetHeight(29)
				filtersBar:Hide()
			end
		end
		setBtnToggleCheck()

		journal.btnToggle:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			mounts.config.filterToggle = not mounts.config.filterToggle
			setBtnToggleCheck()
		end)

		-- HOOKS
		journal.func = {}
		journal:setSecureFunc(C_MountJournal, "GetNumDisplayedMounts", function() return #journal.displayedMounts end)
		journal:setSecureFunc(C_MountJournal, "GetDisplayedMountInfo")
		journal:setSecureFunc(C_MountJournal, "Pickup")
		journal:setSecureFunc(C_MountJournal, "SetIsFavorite")
		journal:setSecureFunc(C_MountJournal, "GetIsFavorite")
		journal:setSecureFunc(C_MountJournal, "GetDisplayedMountInfoExtra")
		journal:setSecureFunc(C_MountJournal, "GetDisplayedMountAllCreatureDisplayInfo")

		hooksecurefunc("MountJournal_UpdateMountList", journal.configureJournal)
		scrollFrame.update = MountJournal_UpdateMountList

		local fullUpdate = MountJournal_FullUpdate
		function MountJournal_FullUpdate(self)
			if self:IsVisible() then journal:updateMountsList() end
			fullUpdate(self)
		end

		-- FILTERS
		MountJournalFilterDropDown.initialize = journal.filterDropDown_Initialize
		journal:updateBtnFilters()
	end
end


function journal:ACHIEVEMENT_EARNED()
	journal.achiev.text:SetText(GetCategoryAchievementPoints(MOUNT_ACHIEVEMENT_CATEGORY, true))
end


function journal:configureJournal()
	local function setColor(btn, mountsTbl)
		if mounts:inTable(mountsTbl, btn.mountID) then
			btn.icon:SetVertexColor(unpack(journal.colors.gold))
			if not btn.check:IsShown() then btn.check:Show() end
		else
			btn.icon:SetVertexColor(unpack(journal.colors.gray))
			if btn.check:IsShown() then btn.check:Hide() end
		end
	end

	for _, btn in pairs(journal.scrollButtons) do
		if btn.index then
			if not btn.fly:IsShown() then
				btn.fly:Show()
				btn.ground:Show()
				btn.swimming:Show()
			end
			btn.fly.mountID = select(12, C_MountJournal.GetDisplayedMountInfo(btn.index))
			btn.ground.mountID = btn.fly.mountID
			btn.swimming.mountID = btn.fly.mountID
			setColor(btn.fly, mounts.list.fly)
			setColor(btn.ground, mounts.list.ground)
			setColor(btn.swimming, mounts.list.swimming)
		else
			if btn.fly:IsShown() then
				btn.fly:Hide()
				btn.ground:Hide()
				btn.swimming:Hide()
			end
		end
	end

	local count, collected = 0, 0
	for _, mountID in pairs(C_MountJournal.GetMountIDs()) do
		local _, _, _, _, _, _, _, _, _, hideOnChar, isCollected = C_MountJournal.GetMountInfoByID(mountID)
		if not hideOnChar then
			count = count + 1
			if isCollected then
				collected = collected + 1
			end
		end
	end
	journal.mountCount.Count:SetText(count)
	journal.mountCount.collected:SetText(collected)
end


function journal:mountToggle(tbl, btn)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	local pos = mounts:inTable(tbl, btn.mountID)
	if pos then
		tremove(tbl, pos)
		btn.icon:SetVertexColor(unpack(journal.colors.gray))
		btn.check:Hide()
	else
		tinsert(tbl, btn.mountID)
		btn.icon:SetVertexColor(unpack(journal.colors.gold))
		btn.check:Show()
	end
end


function journal:setSecureFunc(obj, funcName, func)
	if journal.func[funcName] ~= nil then return end

	journal.func[funcName] = obj[funcName]
	if func then
		obj[funcName] = func
	else
		obj[funcName] = function(index, ...)
			return journal.func[funcName](journal.displayedMounts[index], ...)
		end
	end
end


function journal:filterDropDown_Initialize(level)
	local info = UIDropDownMenu_CreateInfo()
	info.keepShownOnClick = true
	info.isNotRadio = true

	if level == 1 then
		info.text = COLLECTED
		info.func = function(_, _, _, value)
			C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED, value)
			journal:updateBtnFilters()
		end
		info.checked = C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED)
		UIDropDownMenu_AddButton(info, level)

		info.text = NOT_COLLECTED
		info.func = function(_, _, _, value)
			C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED, value)
			journal:updateBtnFilters()
		end
		info.checked = C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED)
		UIDropDownMenu_AddButton(info, level)

		info.text = MOUNT_JOURNAL_FILTER_UNUSABLE
		info.func = function(_, _, _, value)
			C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE, value)
			journal:updateBtnFilters()
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

		info.text = L["expansions"]
		info.value = 5
		UIDropDownMenu_AddButton(info, level)
	else
		info.notCheckable = true

		if UIDROPDOWNMENU_MENU_VALUE == 1 then -- TYPES
			info.text = CHECK_ALL
			info.func = function()
				journal:setAllFilters("types", true)
				MountJournal_UpdateMountList()
				UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
			end
			UIDropDownMenu_AddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				journal:setAllFilters("types", false)
				MountJournal_UpdateMountList()
				UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
			end
			UIDropDownMenu_AddButton(info, level)

			info.notCheckable = false
			local types = mounts.filters.types
			for i = 1, #types do
				info.text = L["MOUNT_TYPE_"..i]
				info.func = function(_, _, _, value)
					types[i] = value
					journal:updateBtnFilters()
					MountJournal_UpdateMountList()
				end
				info.checked = function() return types[i] end
				UIDropDownMenu_AddButton(info, level)
			end
		elseif UIDROPDOWNMENU_MENU_VALUE == 2 then -- SELECTED
			info.text = CHECK_ALL
			info.func = function()
				journal:setAllFilters("selected", true)
				MountJournal_UpdateMountList()
				UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
			end
			UIDropDownMenu_AddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				journal:setAllFilters("selected", false)
				MountJournal_UpdateMountList()
				UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
			end
			UIDropDownMenu_AddButton(info, level)

			info.notCheckable = false
			local selected = mounts.filters.selected
			for i = 1, #selected do
				info.text = L["MOUNT_TYPE_"..i]
				info.func = function(_, _, _, value)
					selected[i] = value
					journal:updateBtnFilters()
					MountJournal_UpdateMountList()
				end
				info.checked = function() return selected[i] end
				UIDropDownMenu_AddButton(info, level)
			end
		elseif UIDROPDOWNMENU_MENU_VALUE == 3 then -- SOURCES
			info.text = CHECK_ALL
			info.func = function()
				C_MountJournal.SetAllSourceFilters(true)
				journal:updateBtnFilters()
				UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
			end
			UIDropDownMenu_AddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				C_MountJournal.SetAllSourceFilters(false)
				journal:updateBtnFilters()
				UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
			end
			UIDropDownMenu_AddButton(info, level)

			info.notCheckable = false
			for i = 1, C_PetJournal.GetNumPetSources() do
				if C_MountJournal.IsValidSourceFilter(i) then
					info.text = _G["BATTLE_PET_SOURCE_"..i]
					info.func = function(_, _, _, value)
						C_MountJournal.SetSourceFilter(i, value)
						journal:updateBtnFilters()
					end
					info.checked = function() return C_MountJournal.IsSourceChecked(i) end
					UIDropDownMenu_AddButton(info, level)
				end
			end
		elseif UIDROPDOWNMENU_MENU_VALUE == 4 then -- FACTIONS
			info.text = CHECK_ALL
			info.func = function()
				journal:setAllFilters("factions", true)
				MountJournal_UpdateMountList()
				UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
			end
			UIDropDownMenu_AddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				journal:setAllFilters("factions", false)
				MountJournal_UpdateMountList()
				UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
			end
			UIDropDownMenu_AddButton(info, level)

			info.notCheckable = false
			local factions = mounts.filters.factions
			for i = 1, #factions do
				info.text = L["MOUNT_FACTION_"..i]
				info.func = function(_, _, _, value)
					factions[i] = value
					journal:updateBtnFilters()
					MountJournal_UpdateMountList()
				end
				info.checked = function() return factions[i] end
				UIDropDownMenu_AddButton(info, level)
			end
		else -- EXPANSIONS
			info.text = CHECK_ALL
			info.func = function()
				journal:setAllFilters("expansions", true)
				MountJournal_UpdateMountList()
				UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
			end
			UIDropDownMenu_AddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				journal:setAllFilters("expansions", false)
				MountJournal_UpdateMountList()
				UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
			end
			UIDropDownMenu_AddButton(info, level)

			info.notCheckable = false
			local expansions = mounts.filters.expansions
			for i = 1, 8 do
				info.text = L["MOUNT_EXPANSION_"..i]
				info.func = function(_, _, _, value)
					expansions[i] = value
					journal:updateBtnFilters()
					MountJournal_UpdateMountList()
				end
				info.checked = function() return expansions[i] end
				UIDropDownMenu_AddButton(info, level)
			end
		end
	end
end


function journal:clearBtnFilters()
	C_MountJournal.SetAllSourceFilters(true)
	journal:setAllFilters("types", true)
	journal:setAllFilters("selected", false)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	MountJournal_UpdateMountList()
end


function journal:clearAllFilters()
	C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED, true)
	C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED, true)
	C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE, true)
	journal:setAllFilters("factions", true)
	journal:setAllFilters("expansions", true)
	journal:clearBtnFilters()
end


function journal:setBtnFilters(tab)
	local i = 0
	local children = {journal.filtersBar[tab]:GetChildren()}

	if tab ~= "sources" then
		local default = tab == "types"
		local filters = mounts.filters[tab]

		for _, btn in pairs(children) do
			local checked = btn:GetChecked()
			filters[btn.id] = checked
			if not checked and default then i = i + 1 end
		end

		if i == #filters then
			for k in pairs(filters) do
				filters[k] = default
			end
		end
	else
		for _, btn in pairs(children) do
			local checked = btn:GetChecked()
			C_MountJournal.SetSourceFilter(btn.id, checked)
			if not checked then i = i + 1 end
		end

		if i == #children then
			C_MountJournal.SetAllSourceFilters(true)
		end
	end

	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	journal:updateBtnFilters()
	MountJournal_UpdateMountList()
end


function journal:setAllFilters(type, enabled)
	local filters = mounts.filters[type]
	for k in pairs(filters) do
		filters[k] = enabled
	end
	journal:updateBtnFilters()
end


function journal:updateBtnFilters()
	local filtersBar, f = journal.filtersBar, {}

	-- TYPES AND SELECTED
	for typeFilter, filter in pairs(mounts.filters) do
		local default = typeFilter ~= "selected"
		local i = 0
		for _, v in pairs(filter) do
			if v == default then i = i + 1 end
		end

		if i == #filter then
			f[typeFilter] = true
			if filtersBar[typeFilter] then
				for _, btn in pairs({filtersBar[typeFilter]:GetChildren()}) do
					local color = default and journal.colors["mount"..btn.id] or journal.colors.dark
					btn:SetChecked(false)
					btn.icon:SetVertexColor(unpack(color))
				end
				filtersBar[typeFilter]:GetParent().filtred:Hide()
			end
		elseif filtersBar[typeFilter] then
			for _, btn in pairs({filtersBar[typeFilter]:GetChildren()}) do
				local checked = filter[btn.id]
				local color = checked and journal.colors["mount"..btn.id] or journal.colors.dark
				btn:SetChecked(checked)
				btn.icon:SetVertexColor(unpack(color))
			end
			filtersBar[typeFilter]:GetParent().filtred:Show()
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
		for _, btn in pairs({filtersBar.sources:GetChildren()}) do
			btn:SetChecked(false)
			btn.icon:SetDesaturated(nil)
		end
		filtersBar.sources:GetParent().filtred:Hide()
	else
		for _, btn in pairs({filtersBar.sources:GetChildren()}) do
			btn:SetChecked(sources[btn.id])
			btn.icon:SetDesaturated(not sources[btn.id])
		end
		filtersBar.sources:GetParent().filtred:Show()
	end

	-- CLEAR BTN FILTERS
	filtersBar.clear:SetShown(not f.types or not f.selected or n ~= #sources - 1)
	if not C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED) or not C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED) or not C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE) or not f.types or not f.selected or not f.factions or not f.expansions or n ~= #sources - 1 then
		journal.shownPanel:Show()
		journal.leftInset:SetPoint("TOPLEFT", journal.shownPanel, "BOTTOMLEFT", 0, -2)
	else
		journal.shownPanel:Hide()
		journal.leftInset:SetPoint("TOPLEFT", journal.filtersPanel, "BOTTOMLEFT", 0, -2)
	end

	journal:updateMountsList()
	journal.leftInset:GetHeight()
end


-- 1 FLY, 2 GROUND, 3 SWIMMING
local mountTypes = {
	[242] = 1,
	[247] = 1,
	[248] = 1,
	[230] = 2,
	[241] = 2,
	[269] = 2,
	[284] = 2,
	[231] = 3,
	[232] = 3,
	[254] = 3,
}
local mountFactions = {
	[0] = 1, -- HORDE
	[1] = 2, -- ALLIANCE
	[2] = 3, -- BOTH
}
function journal:updateMountsList()
	local types, selected, factions, expansions, list = mounts.filters.types, mounts.filters.selected, mounts.filters.factions, mounts.filters.expansions, mounts.list
	wipe(journal.displayedMounts)

	for i = 1, journal.func.GetNumDisplayedMounts() do
		local _,_,_,_,_,_,_,_,mountFaction,_,_,mountID = journal.func.GetDisplayedMountInfo(i)
		local mountType = select(5, C_MountJournal.GetMountInfoExtraByID(mountID))
		mountFaction = mountFaction or 2

		-- TYPE
		if types[mountTypes[mountType]]
		-- FACTION
		and factions[mountFactions[mountFaction]]
		-- SELECTED
		and (not selected[1] and not selected[2] and not selected[3]
			-- FLY
		or selected[1] and mounts:inTable(list.fly, mountID)
			-- GROUND
		or selected[2] and mounts:inTable(list.ground, mountID)
			-- SWIMMING
		or selected[3] and mounts:inTable(list.swimming, mountID))
		-- EXPANSIONS
		and expansions[mounts.db[mountID]] then
			tinsert(journal.displayedMounts, i)
		end
	end

	journal.shownPanel.count:SetText(#journal.displayedMounts)
end