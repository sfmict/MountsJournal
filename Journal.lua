local _, L = ...
local mounts, config = MountsJournal, MountsJournalConfig
local journal = CreateFrame("Frame", "MountsJournalFrame")


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
	self[key] = ""
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
		local tab = CreateFrame("Button", nil, frame)
		tab.id = i
		tab:SetSize(105, 24)
		
		if i == 1 then
			tab:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 7, -4)
		else
			tab:SetPoint("LEFT", frame.tabs[i - 1], "RIGHT", -5, 0)
		end

		tab.text = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		tab.text:SetPoint("CENTER")
		tab.text:SetText(select(i, ...))

		tab.bgLeft = tab:CreateTexture(nil, "BACKGROUND")
		tab.bgLeft:SetTexture("Interface/ChatFrame/ChatFrameTab-BGLeft")
		tab.bgLeft:SetSize(16, 24)
		tab.bgLeft:SetPoint("TOPLEFT", 0, 2)
		tab.bgLeft:SetTexCoord(0, 1, 0.25, 1)

		tab.bgRight = tab:CreateTexture(nil, "BACKGROUND")
		tab.bgRight:SetTexture("Interface/ChatFrame/ChatFrameTab-BGRight")
		tab.bgRight:SetSize(16, 24)
		tab.bgRight:SetPoint("TOPRIGHT", 0, 2)
		tab.bgRight:SetTexCoord(0, 1, 0.25, 1)

		tab.bgCenter = tab:CreateTexture(nil, "BACKGROUND")
		tab.bgCenter:SetTexture("Interface/ChatFrame/ChatFrameTab-BGMid")
		tab.bgCenter:SetSize(3, 24)
		tab.bgCenter:SetPoint("TOPLEFT", 16, 2)
		tab.bgCenter:SetPoint("TOPRIGHT", -16, 2)
		tab.bgCenter:SetTexCoord(0, 1, 0.25, 1)

		tab.filtred = tab:CreateTexture(nil, "OVERLAY")
		tab.filtred:SetTexture("Interface/PaperDollInfoFrame/UI-Character-Tab-Highlight")
		tab.filtred:SetSize(16, 24)
		tab.filtred:SetPoint("TOPLEFT", 3, -6)
		tab.filtred:SetPoint("BOTTOMRIGHT", -3, 2)
		tab.filtred:SetTexCoord(0, 1, 0.40625, 0.75)
		tab.filtred:SetVertexColor(1, 1, 0.75)
		tab.filtred:SetBlendMode("ADD")

		tab.hlLeft = tab:CreateTexture(nil, "HIGHTLIGHT")
		tab.hlLeft:SetTexture("Interface/ChatFrame/ChatFrameTab-HighlightLeft")
		tab.hlLeft:SetSize(16, 24)
		tab.hlLeft:SetPoint("TOPLEFT", 0, 2)
		tab.hlLeft:SetTexCoord(0, 1, 0.25, 1)
		tab.hlLeft:SetVertexColor(0.1, 0.25, 0.5)
		tab.hlLeft:SetBlendMode("ADD")
		tab.hlLeft:Hide()

		tab.hlRight = tab:CreateTexture(nil, "HIGHTLIGHT")
		tab.hlRight:SetTexture("Interface/ChatFrame/ChatFrameTab-HighlightRight")
		tab.hlRight:SetSize(16, 24)
		tab.hlRight:SetPoint("TOPRIGHT", 0, 2)
		tab.hlRight:SetTexCoord(0, 1, 0.25, 1)
		tab.hlRight:SetVertexColor(0.1, 0.25, 0.5)
		tab.hlRight:SetBlendMode("ADD")
		tab.hlRight:Hide()

		tab.hlCenter = tab:CreateTexture(nil, "HIGHTLIGHT")
		tab.hlCenter:SetTexture("Interface/ChatFrame/ChatFrameTab-HighlightMid")
		tab.hlCenter:SetSize(3, 24)
		tab.hlCenter:SetPoint("TOPLEFT", 16, 2)
		tab.hlCenter:SetPoint("TOPRIGHT", -16, 2)
		tab.hlCenter:SetTexCoord(0, 1, 0.25, 1)
		tab.hlCenter:SetVertexColor(0.1, 0.25, 0.5)
		tab.hlCenter:SetBlendMode("ADD")
		tab.hlCenter:Hide()

		tab.selected = CreateFrame("FRAME", nil, tab)
		local selected = tab.selected
		selected:SetAllPoints()

		selected.left = selected:CreateTexture(nil, "OVERLAY")
		selected.left:SetTexture("Interface/ChatFrame/ChatFrameTab-SelectedLeft")
		selected.left:SetSize(16, 24)
		selected.left:SetPoint("TOPLEFT", 2, 0)
		selected.left:SetTexCoord(0, 1, 0.25, 1)
		selected.left:SetVertexColor(unpack(journal.colors.gold))
		selected.left:SetBlendMode("ADD")

		selected.right = selected:CreateTexture(nil, "OVERLAY")
		selected.right:SetTexture("Interface/ChatFrame/ChatFrameTab-SelectedRight")
		selected.right:SetSize(16, 24)
		selected.right:SetPoint("TOPRIGHT", -2, 0)
		selected.right:SetTexCoord(0, 1, 0.25, 1)
		selected.right:SetVertexColor(unpack(journal.colors.gold))
		selected.right:SetBlendMode("ADD")

		selected.center = selected:CreateTexture(nil, "OVERLAY")
		selected.center:SetTexture("Interface/ChatFrame/ChatFrameTab-SelectedMid")
		selected.center:SetSize(3, 24)
		selected.center:SetPoint("TOPLEFT", 18, 0)
		selected.center:SetPoint("TOPRIGHT", -18, 0)
		selected.center:SetTexCoord(0, 1, 0.25, 1)
		selected.center:SetVertexColor(unpack(journal.colors.gold))
		selected.center:SetBlendMode("ADD")

		selected.bg = selected:CreateTexture(nil, "ARTWORK")
		selected.bg:SetColorTexture(0.065, 0.065, 0.065)
		selected.bg:SetPoint("TOPLEFT", selected, "BOTTOMLEFT", 6, 2)
		selected.bg:SetPoint("BOTTOMRIGHT", selected, "BOTTOMRIGHT", -6, -2)

		tab:SetScript("OnEnter", function(self)
			self.hlLeft:Show()
			self.hlRight:Show()
			self.hlCenter:Show()
		end)
		tab:SetScript("OnLeave", function(self)
			self.hlLeft:Hide()
			self.hlRight:Hide()
			self.hlCenter:Hide()
		end)
		tab:SetScript("OnMouseDown", function(self)
			self.text:SetPoint("CENTER", 1, -1)
		end)
		tab:SetScript("OnMouseUp", function(self)
			self.text:SetPoint("CENTER")
		end)
		tab:SetScript("OnClick", tabClick)

		tab.content = CreateFrame("FRAME", nil, tab)
		tab.content:SetPoint("TOPLEFT", frame, "TOPLEFT")
		tab.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")

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
	if addonName == "Blizzard_Collections" and IsAddOnLoaded("MountsJournal") or addonName == "MountsJournal" and IsAddOnLoaded("Blizzard_Collections") then
		self:UnregisterEvent("ADDON_LOADED")

		mounts.filters.types = mounts.filters.types or {true, true, true}

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
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			mounts:setMountsList(self:GetChecked())
			journal:configureJournal()
		end)

		-- SELECTED BUTTONS
		journal.scrollButtons = MountJournal.ListScrollFrame.buttons
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

		-- FILTERS SEARTCH
		MountJournal.searchBox:SetPoint("TOPLEFT", MountJournal.LeftInset, "TOPLEFT", 34, -9)
		MountJournal.searchBox:SetSize(128, 20)

		-- FILTERS BAR
		journal.filtersBar = CreateFrame("FRAME", nil, MountJournal.LeftInset)
		local filtersBar = journal.filtersBar
		filtersBar:SetSize(235, 35)
		filtersBar:SetPoint("TOP", 0, -50)
		filtersBar:SetBackdrop({
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true,
			edgeSize = 16,
		})
		filtersBar:SetBackdropBorderColor(0.6, 0.6, 0.6)
		filtersBar.types, filtersBar.sources = setTabs(filtersBar, L["Types"], SOURCES)

		-- FILTERS CLEAR
		local clear = CreateFrame("button", nil, filtersBar)
		filtersBar.clear = clear
		clear:SetPoint("BOTTOMRIGHT", filtersBar, "TOPRIGHT", -5, 0)
		clear:SetSize(18, 18)
		clear:SetHitRectInsets(-2, -2, -2, -2)
		clear:SetNormalTexture("Interface/FriendsFrame/ClearBroadcastIcon")
		clear.texture = clear:GetRegions()
		clear.texture:SetAlpha(0.5)
		clear:SetScript("OnEnter", function(self) self.texture:SetAlpha(1) end)
		clear:SetScript("OnLeave", function(self) self.texture:SetAlpha(0.5) end)
		clear:SetScript("OnMouseDown", function(self) self:SetPoint("BOTTOMRIGHT", filtersBar, "TOPRIGHT", -4, -1) end)
		clear:SetScript("OnMouseUp", function(self) self:SetPoint("BOTTOMRIGHT", filtersBar, "TOPRIGHT", -5, 0) end)
		clear:SetScript("OnClick", journal.clearFilters)

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
				btn.icon:SetPoint("CENTER", 1, -1)
				btn.icon:SetSize(texture.width - 2, texture.height - 2)
			end)
			btn:SetScript("OnMouseUp", function()
				btn.icon:SetPoint("CENTER")
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

		journal:updateBtnFilters()

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

		local filterHeight = 51
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
				filtersBar:Show()
			else
				btnToggle.Icon:SetPoint("CENTER", 0, -1)
				btnToggle.Icon:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)
				scrollFrame:SetPoint(unpack(sfp))
				scrollBar:SetPoint(unpack(sbp))
				filtersBar:Hide()
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
		info.notCheckable = true

		if UIDROPDOWNMENU_MENU_VALUE == 1 then -- TYPES
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
		else -- SOURCES
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
		end
	end
end


function journal:clearFilters()
	C_MountJournal.SetAllSourceFilters(true)
	journal:setAllTypesFilters(true)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end


function journal:setBtnFilters(tab)
	local i = 0

	if tab == 1 then
		local types = mounts.filters.types
		local children = {journal.filtersBar.types:GetChildren()}

		for _, btn in pairs(children) do
			local checked = btn:GetChecked()
			types[btn.id] = checked
			if not checked then i = i + 1 end
		end

		if i == #children then
			for k in pairs(types) do
				types[k] = true
			end
		end
	else
		local children = {journal.filtersBar.sources:GetChildren()}

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


function journal:setAllTypesFilters(enabled)
	local types = mounts.filters.types
	for k in pairs(types) do
		types[k] = enabled
	end
	journal:updateBtnFilters()
	MountJournal_UpdateMountList()
end


function journal:updateBtnFilters()
	local types, filtersBar, i = mounts.filters.types, journal.filtersBar, 0

	-- TYPES
	for _, v in pairs(types) do
		if v then i = i + 1 end
	end

	if i == #types then
		for _, btn in pairs({filtersBar.types:GetChildren()}) do
			btn:SetChecked(false)
			btn.icon:SetVertexColor(unpack(journal.colors["mount"..btn.id]))
		end
		filtersBar.clear:Hide()
		filtersBar.types:GetParent().filtred:Hide()
	else
		for _, btn in pairs({filtersBar.types:GetChildren()}) do
			local checked = types[btn.id]
			local color = checked and journal.colors["mount"..btn.id] or journal.colors.dark
			btn:SetChecked(checked)
			btn.icon:SetVertexColor(unpack(color))
		end
		filtersBar.clear:Show()
		filtersBar.types:GetParent().filtred:Show()
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

	-- CLEAR FILTERS
	filtersBar.clear:SetShown(i ~= #types or n ~= #sources - 1)
end


function journal:getNumDisplayedMounts()
	local types = mounts.filters.types
	wipe(journal.displayedMounts)
	journal.displayedMounts[0] = 0

	for i = 1, journal.func.GetNumDisplayedMounts() do
		local mountID = select(12, journal.func.GetDisplayedMountInfo(i))
		local mountType = select(5, C_MountJournal.GetMountInfoExtraByID(mountID))

		-- FLY
		if types[1] and mounts:inTable({242, 247, 248}, mountType)
		-- GROUND
		or types[2] and mounts:inTable({230, 241, 269, 284}, mountType)
		-- SWIMMING
		or types[3] and mounts:inTable({231, 232, 254}, mountType) then
			tinsert(journal.displayedMounts, i)
		end
	end

	return #journal.displayedMounts
end