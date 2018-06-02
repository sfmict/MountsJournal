local _, L = ...
local mounts, config = MountsJournal, MountsJournalConfig
local journal = CreateFrame("Frame", "MountsJournalFrame")


local COLLECTION_ACHIEVEMENT_CATEGORY = 15246
local MOUNT_ACHIEVEMENT_CATEGORY = 15248


journal.colors = {
	gold = {0.8, 0.6, 0},
	gray = {0.5, 0.5, 0.5},
	dark = {0.3, 0.3, 0.3},
	flyMount = {0.824, 0.78, 0.235},
	groundMount = {0.42, 0.302, 0.224},
	swimmingMount = {0.031, 0.333, 0.388},
}


journal.filters = {
	types = {
		fly = true,
		ground = true,
		swimming = true,
	},
}


journal.displayedMounts = {}
setmetatable(journal.displayedMounts, {__index = function(self, key)
	self[key] = ""
	return key
end})


journal:SetScript("OnEvent", function(self, event, ...)
	if journal[event] then
		journal[event](self, ...)
	end
end)
journal:RegisterEvent("ADDON_LOADED")


function journal:ADDON_LOADED(addonName)
	if addonName == "Blizzard_Collections" and IsAddOnLoaded("MountsJournal") or addonName == "MountsJournal" and IsAddOnLoaded("Blizzard_Collections") then
		self:UnregisterEvent("ADDON_LOADED")

		-- SETTINGS BUTTON
		local btnConfig = CreateFrame("Button", "MountsJournalBtnConfig", MountJournal, "UIPanelButtonTemplate")
		btnConfig:SetSize(80, 22)
		btnConfig:SetPoint("TOPLEFT", MountJournal.MountCount, "TOPRIGHT", 8, 1)
		btnConfig:SetText(L["Settings"])
		btnConfig:SetScript("OnClick", config.openConfig)

		-- ACHIEVEMENT
		local achiev = CreateFrame("button", nil, MountJournal)
		journal.achiev = achiev
		achiev:SetPoint("TOP", 60, -21)
		achiev:SetSize(60, 40)

		achiev.hightlight = achiev:CreateTexture(nil, "BACKGROUND")
		achiev.hightlight:SetAtlas("PetJournal-PetBattleAchievementGlow")
		achiev.hightlight:SetPoint("TOP")
		achiev.hightlight:SetSize(210, 40)
		achiev.hightlight:Hide()

		achiev.left = achiev:CreateTexture(nil, "BACKGROUND")
		achiev.left:SetAtlas("PetJournal-PetBattleAchievementBG")
		achiev.left:SetSize(46, 18)
		achiev.left:SetPoint("TOP", -56, -12)

		achiev.right = achiev:CreateTexture(nil, "BACKGROUND")
		achiev.right:SetAtlas("PetJournal-PetBattleAchievementBG")
		achiev.right:SetSize(46, 18)
		achiev.right:SetPoint("TOP", 55, -12)
		achiev.right:SetTexCoord(1, 0, 0, 1)

		achiev.icon = achiev:CreateTexture(nil, "OVERLAY")
		achiev.icon:SetTexture("Interface/AchievementFrame/UI-Achievement-Shields-NoPoints")
		achiev.icon:SetSize(30, 30)
		achiev.icon:SetPoint("RIGHT", 1, -2)
		achiev.icon:SetTexCoord(0, 0.5, 0, 0.5)

		achiev.text = achiev:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		achiev.text:SetPoint("CENTER", -17, 0)
		journal:ACHIEVEMENT_EARNED()

		achiev:SetScript("OnEnter", function(self) self.hightlight:Show() end)
		achiev:SetScript("OnLeave", function(self) self.hightlight:Hide() end)
		achiev:SetScript("OnClick", function()
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
		local perCharCheck = CreateFrame("CheckButton", "MountsJournalPerChar", MountJournal, "InterfaceOptionsCheckButtonTemplate")
		perCharCheck:SetPoint("LEFT", MountJournal.MountButton, "RIGHT", 6, -2)
		perCharCheck.label = _G[perCharCheck:GetName().."Text"]
		perCharCheck.label:SetFont("GameFontHighlight", 30)
		perCharCheck.label:SetPoint("LEFT", perCharCheck, "RIGHT", 1, 1)
		perCharCheck.label:SetText(L["Character Specific Mount List"])
		perCharCheck:SetChecked(mounts.perChar)
		perCharCheck:SetScript("OnClick", function(self)
			mounts:setMountsList(self:GetChecked())
			journal:configureJournal()
		end)

		-- BUTTONS
		journal.buttons = MountJournal.ListScrollFrame.buttons
		local texPath = "Interface/AddOns/MountsJournal/textures/"

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

		for _, child in pairs(journal.buttons) do
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

		-- FILTERS SEARTCH
		MountJournal.searchBox:SetPoint("TOPLEFT", MountJournal.LeftInset, "TOPLEFT", 34, -9)
		MountJournal.searchBox:SetSize(128, 20)

		-- FILTERS BAR
		journal.typeBar = CreateFrame("FRAME", nil, MountJournal.LeftInset)
		journal.typeBar:SetSize(229, 30)
		journal.typeBar:SetPoint("TOPLEFT", 4, -31)
		journal.typeBar:SetBackdrop({
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true,
			edgeSize = 16,
		})
		journal.typeBar:SetBackdropBorderColor(0.6, 0.6, 0.6)

		-- FILTERS CLEAR
		local clear = CreateFrame("button", nil, journal.typeBar)
		journal.typeBar.clear = clear
		clear:SetPoint("LEFT", journal.typeBar, "RIGHT", 2, 0)
		clear:SetSize(18, 18)
		clear:SetHitRectInsets(-2, -2, -2, -2)
		clear:SetNormalTexture("Interface/FriendsFrame/ClearBroadcastIcon")
		clear.texture = clear:GetRegions()
		clear.texture:SetAlpha(0.5)
		clear:SetScript("OnEnter", function(self) self.texture:SetAlpha(1) end)
		clear:SetScript("OnLeave", function(self) self.texture:SetAlpha(0.5) end)
		clear:SetScript("OnMouseDown", function(self) self:SetPoint("LEFT", journal.typeBar, "RIGHT", 3, -1) end)
		clear:SetScript("OnMouseUp", function(self) self:SetPoint("LEFT", journal.typeBar, "RIGHT", 2, 0) end)
		clear:SetScript("OnClick", journal.clearFilters)
		clear:Hide()

		-- FILTERS FLY GROUND SWIMMING
		journal.typeBar.buttons = {}
		local function CreateButtonFilter(name, pointX, pointY, color)
			local btn = CreateFrame("CheckButton", nil, journal.typeBar)
			btn.type = name
			btn:SetSize(73, 20)
			btn:SetPoint("TOP", pointX, pointY)

			btn:SetHighlightTexture(texPath.."button")
			btn:SetCheckedTexture("Interface/BUTTONS/ListButtons")
			local hightlight, checked = btn:GetRegions()
			hightlight:SetAlpha(0.8)
			hightlight:SetTexCoord(0.00390625, 0.8203125, 0.19140625, 0.37109375)
			checked:SetAlpha(0.8)
			checked:SetTexCoord(0.00390625, 0.8203125, 0.37890625, 0.55859375)

			btn:SetBackdrop({
				edgeFile = texPath.."border",
				tile = true,
				edgeSize = 8,
			})
			btn:SetBackdropBorderColor(0.4, 0.4, 0.4)

			btn.icon = btn:CreateTexture(nil, "OVERLAY")
			btn.icon:SetTexture(texPath..name)
			btn.icon:SetPoint("TOP", -1, -3)
			btn.icon:SetVertexColor(unpack(color))

			btn:SetScript("OnMouseDown", function()
				btn.icon:SetPoint("TOP", 0, -4)
				btn.icon:SetSize(30, 14)
			end)
			btn:SetScript("OnMouseUp", function()
				btn.icon:SetPoint("TOP", -1, -3)
				btn.icon:SetSize(32, 16)
			end)
			btn:SetScript("OnClick", journal.setBtnFilters)

			tinsert(journal.typeBar.buttons, btn)
		end

		CreateButtonFilter("fly", -73, -5, journal.colors.flyMount)
		CreateButtonFilter("ground", 0, -5, journal.colors.groundMount)
		CreateButtonFilter("swimming", 73, -5, journal.colors.swimmingMount)

		-- FILTERS TOGGLE BTN
		local btnToggle = CreateFrame("button", nil, MountJournal.LeftInset)
		btnToggle:SetPoint("TOPLEFT", MountJournal.LeftInset, "TOPLEFT", 4, -7)
		btnToggle:SetSize(24, 24)
		btnToggle:SetHitRectInsets(-2, -2, -2, -2)
		btnToggle:SetHighlightTexture("Interface/BUTTONS/UI-Common-MouseHilight")

		btnToggle.TopLeft = btnToggle:CreateTexture(nil, "BACKGROUND")
		btnToggle.TopLeft:SetTexture("Interface/Buttons/UI-Silver-Button-Up")
		btnToggle.TopLeft:SetTexCoord(0, 0.1015625, 0, 0.1875)
		btnToggle.TopLeft:SetSize(13, 6)
		btnToggle.TopLeft:SetPoint("TOPLEFT")

		btnToggle.TopRight = btnToggle:CreateTexture(nil, "BACKGROUND")
		btnToggle.TopRight:SetTexture("Interface/Buttons/UI-Silver-Button-Up")
		btnToggle.TopRight:SetTexCoord(0.5234375, 0.625, 0, 0.1875)
		btnToggle.TopRight:SetSize(13, 6)
		btnToggle.TopRight:SetPoint("TOPRIGHT")

		btnToggle.BottomLeft = btnToggle:CreateTexture(nil, "BACKGROUND")
		btnToggle.BottomLeft:SetTexture("Interface/Buttons/UI-Silver-Button-Up")
		btnToggle.BottomLeft:SetTexCoord(0, 0.1015625, 0.625, 0.8125)
		btnToggle.BottomLeft:SetSize(13, 6)
		btnToggle.BottomLeft:SetPoint("BOTTOMLEFT")

		btnToggle.BottomRight = btnToggle:CreateTexture(nil, "BACKGROUND")
		btnToggle.BottomRight:SetTexture("Interface/Buttons/UI-Silver-Button-Up")
		btnToggle.BottomRight:SetTexCoord(0.5234375, 0.625, 0.625, 0.8125)
		btnToggle.BottomRight:SetSize(13, 6)
		btnToggle.BottomRight:SetPoint("BOTTOMRIGHT")

		btnToggle.Left = btnToggle:CreateTexture(nil, "BACKGROUND")
		btnToggle.Left:SetTexture("Interface/Buttons/UI-Silver-Button-Up")
		btnToggle.Left:SetTexCoord(0, 0.09375, 0.1875, 0.625)
		btnToggle.Left:SetSize(12, 14)
		btnToggle.Left:SetVertexColor(0.65, 0.65, 0.65)
		btnToggle.Left:SetPoint("LEFT")

		btnToggle.Right = btnToggle:CreateTexture(nil, "BACKGROUND")
		btnToggle.Right:SetTexture("Interface/Buttons/UI-Silver-Button-Up")
		btnToggle.Right:SetTexCoord(0.53125, 0.625, 0.1875, 0.625)
		btnToggle.Right:SetSize(12, 14)
		btnToggle.Right:SetPoint("RIGHT")

		btnToggle.Icon = btnToggle:CreateTexture(nil, "ARTWORK")
		btnToggle.Icon:SetTexture("Interface/ChatFrame/ChatFrameExpandArrow")
		btnToggle.Icon:SetSize(14, 14)

		btnToggle:SetScript("OnMouseDown", function(self)
			self.TopLeft:SetTexture("Interface/Buttons/UI-Silver-Button-Down")
			self.TopRight:SetTexture("Interface/Buttons/UI-Silver-Button-Down")
			self.BottomLeft:SetTexture("Interface/Buttons/UI-Silver-Button-Down")
			self.BottomRight:SetTexture("Interface/Buttons/UI-Silver-Button-Down")
			self.Left:SetTexture("Interface/Buttons/UI-Silver-Button-Down")
			self.Right:SetTexture("Interface/Buttons/UI-Silver-Button-Down")
			if mounts.config.filterToggle then
				self.Icon:SetPoint("CENTER", -1, 0)
			else
				self.Icon:SetPoint("CENTER", -1, -2)
			end
		end)

		btnToggle:SetScript("OnMouseUp", function(self)
			self.TopLeft:SetTexture("Interface/Buttons/UI-Silver-Button-UP")
			self.TopRight:SetTexture("Interface/Buttons/UI-Silver-Button-UP")
			self.BottomLeft:SetTexture("Interface/Buttons/UI-Silver-Button-UP")
			self.BottomRight:SetTexture("Interface/Buttons/UI-Silver-Button-UP")
			self.Left:SetTexture("Interface/Buttons/UI-Silver-Button-UP")
			self.Right:SetTexture("Interface/Buttons/UI-Silver-Button-UP")
			if mounts.config.filterToggle then
				self.Icon:SetPoint("CENTER", 0, 1)
			else
				self.Icon:SetPoint("CENTER", 0, -1)
			end
		end)

		local filterHeight = 27
		local scrollFrame = MountJournal.ListScrollFrame
		local sfp = {scrollFrame:GetPoint()}
		local scrollBar = scrollFrame.scrollBar
		local sbp = {scrollBar:GetPoint()}

		local function setBtnToggleCheck()
			if mounts.config.filterToggle then
				btnToggle.Icon:SetPoint("CENTER", 0, 1)
				btnToggle.Icon:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)
				scrollFrame:SetPoint(sfp[1], sfp[2], sfp[3], sfp[4], sfp[5] - filterHeight)
				scrollBar:SetPoint(sbp[1], sbp[2], sbp[3], sbp[4], sbp[5] + filterHeight)
				journal.typeBar:Show()
			else
				btnToggle.Icon:SetPoint("CENTER", 0, -1)
				btnToggle.Icon:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)
				scrollFrame:SetPoint(unpack(sfp))
				scrollBar:SetPoint(unpack(sbp))
				journal.typeBar:Hide()
			end
		end
		setBtnToggleCheck()

		btnToggle:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			mounts.config.filterToggle = not mounts.config.filterToggle
			setBtnToggleCheck()
		end)

		-- HOOKS
		journal.func = {}
		journal:setSecureFunc(C_MountJournal, "GetNumDisplayedMounts", journal.getNumDisplayedMounts)
		journal:setSecureFunc(C_MountJournal, "GetDisplayedMountInfo")
		journal:setSecureFunc(C_MountJournal, "Pickup")
		journal:setSecureFunc(C_MountJournal, "SetIsFavorite")
		journal:setSecureFunc(C_MountJournal, "GetIsFavorite")
		journal:setSecureFunc(C_MountJournal, "GetDisplayedMountInfoExtra")
		journal:setSecureFunc(C_MountJournal, "GetDisplayedMountAllCreatureDisplayInfo")

		hooksecurefunc("MountJournal_UpdateMountList", journal.configureJournal)
		scrollFrame.update = MountJournal_UpdateMountList

		-- FILTERS
		MountJournalFilterDropDown.initialize = journal.filterDropDown_Initialize
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

	for _, btn in pairs(journal.buttons) do
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

	if level == 1 then
		info.isNotRadio = true

		info.text = COLLECTED
		info.func = function(_, _, _, value)
			C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED,value)
		end
		info.checked = C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED)
		UIDropDownMenu_AddButton(info, level)

		info.text = NOT_COLLECTED
		info.func = function(_, _, _, value)
			C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED,value)
		end
		info.checked = C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED)
		UIDropDownMenu_AddButton(info, level)

		info.text = MOUNT_JOURNAL_FILTER_UNUSABLE
		info.func = function(_, _, _, value)
			C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE, value)
		end
		info.checked = C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE)
		UIDropDownMenu_AddButton(info, level)

		info.checked = nil
		info.isNotRadio = nil
		info.func =  nil
		info.hasArrow = true
		info.notCheckable = true

		info.text = L["Types"]
		info.value = 1
		UIDropDownMenu_AddButton(info, level)

		info.text = SOURCES
		info.value = 2
		UIDropDownMenu_AddButton(info, level)
	else
		info.isNotRadio = true
		info.notCheckable = true

		if UIDROPDOWNMENU_MENU_VALUE == 1 then
			info.text = CHECK_ALL
			info.func = function()
				journal:setAllTypesFilters(true)
				UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
			end
			UIDropDownMenu_AddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				journal:setAllTypesFilters(false)
				UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
			end
			UIDropDownMenu_AddButton(info, level)

			info.notCheckable = false
			local types = journal.filters.types
			for k in pairs(types) do
				info.text = L["MOUNT_TYPE_"..strupper(k)]
				info.func = function(_, _, _, value)
					types[k] = value
					journal:updateBtnFilters()
				end
				info.checked = function() return types[k] end
				UIDropDownMenu_AddButton(info, level)
			end
		else
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
					info.func = function(_, _, _, value)
						-- journal:setSourceFilter(i, value)
						C_MountJournal.SetSourceFilter(i, value)
					end
					-- info.checked = function() return journal.filters.sources[i] end
					info.checked = function() return C_MountJournal.IsSourceChecked(i) end
					UIDropDownMenu_AddButton(info, level)
				end
			end
		end
	end
end


function journal:clearFilters()
	local types = journal.filters.types
	for k in pairs(types) do
		types[k] = true
	end

	journal:updateBtnFilters()
end


function journal:setBtnFilters()
	local types, i = journal.filters.types, 0

	for _, btn in pairs(journal.typeBar.buttons) do
		local checked = btn:GetChecked()
		types[btn.type] = checked
		if not checked then i = i + 1 end
	end

	if i == 3 then
		for k in pairs(types) do
			types[k] = true
		end
	end

	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	journal:updateBtnFilters()
end


function journal:setAllTypesFilters(enabled)
	local types = journal.filters.types
	for k in pairs(types) do
		types[k] = enabled
	end
	journal:updateBtnFilters()
end


function journal:updateBtnFilters()
	local types, i = journal.filters.types, 0

	for _, v in pairs(types) do
		if v then i = i + 1 end
	end

	if i == 3 then
		for _, btn in pairs(journal.typeBar.buttons) do
			btn:SetChecked(false)
			btn.icon:SetVertexColor(unpack(journal.colors[btn.type.."Mount"]))
			journal.typeBar.clear:Hide()
		end
	else
		for _, btn in pairs(journal.typeBar.buttons) do
			local checked = types[btn.type]
			local color = checked and journal.colors[btn.type.."Mount"] or journal.colors.dark
			btn:SetChecked(checked)
			btn.icon:SetVertexColor(unpack(color))
			journal.typeBar.clear:Show()
		end
	end

	MountJournal_UpdateMountList()
end


function journal:getNumDisplayedMounts()
	local types = journal.filters.types
	wipe(journal.displayedMounts)
	journal.displayedMounts[0] = 0

	for i = 1, journal.func.GetNumDisplayedMounts() do
		local mountID = select(12, journal.func.GetDisplayedMountInfo(i))
		local mountType = select(5, C_MountJournal.GetMountInfoExtraByID(mountID))

		-- FLY
		if types.fly and mounts:inTable({242, 247, 248}, mountType)
		-- GROUND
		or types.ground and mounts:inTable({230, 241, 269, 284}, mountType)
		-- SWIMMING
		or types.swimming and mounts:inTable({231, 232, 254}, mountType) then
			tinsert(journal.displayedMounts, i)
		end
	end

	return #journal.displayedMounts
end