local addon, ns = ...
local L, util = ns.L, ns.util
local dataDialog = CreateFrame("FRAME", "MountsJournalDataDialog", nil, "DefaultPanelTemplate,MJEscHideTemplate")
ns.dataDialog = dataDialog
dataDialog:Hide()


local escOnShow = dataDialog:GetScript("OnShow")
dataDialog:HookScript("OnShow", function(self)
	self:SetScript("OnShow", escOnShow)
	self:SetSize(300, 300)
	self:SetParent(ns.journal.bgFrame)
	self:SetPoint("CENTER")
	self:SetFrameLevel(2000)
	self:SetClampedToScreen(true)
	self:EnableMouse(true)
	self:SetMovable(true)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart", self.StartMoving)
	self:SetScript("OnDragStop", self.StopMovingOrSizing)
	self:HookScript("OnHide", function(self)
		self.info = nil
		self.data = nil
		self:Hide()
	end)

	-- NAME
	self.nameString = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	self.nameString:SetPoint("TOPLEFT", 10, -30)
	self.nameString:SetText(NAME)

	self.nameEdit = CreateFrame("EditBox", nil, self, "InputBoxTemplate")
	self.nameEdit:SetHeight(22)
	self.nameEdit:SetPoint("LEFT", self.nameString, "RIGHT", 5, 0)
	self.nameEdit:SetPoint("RIGHT", -6, 0)
	self.nameEdit:SetAutoFocus(false)
	self.nameEdit:SetTextInsets(0, 5, 0, 0)

	-- LABEL
	self.label = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	self.label:SetPoint("BOTTOMRIGHT", -4, 30)

	-- EDIT
	self.codeBtn = CreateFrame("BUTTON", nil, self, "BackdropTemplate")
	self.codeBtn:SetPoint("BOTTOMRIGHT", -4, 30)
	self.codeBtn:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileEdge = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	self.codeBtn:SetBackdropColor(.05, .05, .05)
	self.codeBtn:SetBackdropBorderColor(FRIENDS_GRAY_COLOR:GetRGB())
	self.codeBtn:SetScript("OnClick", function(btn) btn:GetParent().editBox:SetFocus() end)

	self.scrollBar = CreateFrame("EventFrame", nil, self.codeBtn, "WowTrimScrollBar")
	self.scrollBar:SetPoint("TOPRIGHT", self.codeBtn, -4, -5)
	self.scrollBar:SetPoint("BOTTOMRIGHT", self.codeBtn, -4, 4)

	self.editFrame = CreateFrame("FRAME", nil, self.codeBtn, "ScrollingEditBoxTemplate")
	self.editBox = self.editFrame:GetEditBox()

	self.editBox:HookScript("OnTextChanged", function(editBox)
		if self.info.type ~= "import" then return end
		local data = util.getDataFromString(editBox:GetText(), true)
		if type(data) == "table" and data.v == "retail" and (not self.info.valid or self.info.valid(data)) then
			if self.info.defName then
				self.nameEdit:SetFocus()
				self.nameEdit:HighlightText()
			end
			self.data = data
			self.btn1:Enable()
		else
			self.btn1:Disable()
		end
	end)

	self.editBox:HookScript("OnMouseUp", function(editBox)
		editBox:HighlightText()
	end)

	local anchorsToFrame = {
		CreateAnchor("TOPLEFT", self.codeBtn, "TOPLEFT", 8, -8),
		CreateAnchor("BOTTOMRIGHT", self.codeBtn, "BOTTOMRIGHT", -8, 8),
	}
	local anchorsToBar = {
		anchorsToFrame[1],
		CreateAnchor("BOTTOMRIGHT", self.scrollBar, "BOTTOMLEFT", -3, 4),
	}
	local scrollBox = self.editFrame:GetScrollBox()
	ScrollUtil.RegisterScrollBoxWithScrollBar(scrollBox, self.scrollBar)
	ScrollUtil.AddManagedScrollBarVisibilityBehavior(scrollBox, self.scrollBar, anchorsToBar, anchorsToFrame)

	-- CONTROL BTNS
	self.btn1 = CreateFrame("BUTTON", nil, self, "UIPanelButtonTemplate")
	self.btn1:SetPoint("BOTTOMRIGHT", self, "BOTTOM", -5, 5)
	self.btn1:SetSize(120, 22)
	self.btn1:SetText(SAVE)
	self.btn1:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		local name = self.nameEdit:GetText():trim()
		if self.codeBtn:IsShown() and name == "" or self.info.save and not self.info.save(self.data, name) then
			self.nameEdit:SetFocus()
			self.nameEdit:HighlightText()
			return
		end
		self:Hide()
	end)

	self.btn2 = CreateFrame("BUTTON", nil, self, "UIPanelButtonTemplate")
	self.btn2:SetPoint("BOTTOM", 0, 5)
	self.btn2:SetSize(120, 22)
	self.btn2:SetScript("OnClick", function()
		self:Hide()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)
end)


function dataDialog:open(info)
	self:Show()
	self.info = info
	self.btn2:ClearAllPoints()

	if info.type == "import" then
		self:SetTitle(L["Import"])
		self.label:Hide()
		self.codeBtn:Show()

		if info.defName then
			self.nameString:Show()
			self.nameEdit:Show()
			self.nameEdit:SetText(info.defName)
			self.codeBtn:SetPoint("TOPLEFT", self.nameString, "BOTTOMLEFT", -3, -4)
		else
			self.nameString:Hide()
			self.nameEdit:Hide()
			self.codeBtn:SetPoint("TOPLEFT", 7, -24)
		end

		self.editBox:SetText("")
		self.editBox:SetFocus()

		self.btn1:Disable()
		self.btn1:Show()

		self.btn2:SetText(CANCEL)
		self.btn2:SetPoint("BOTTOMLEFT", self, "BOTTOM", 5, 5)
	elseif info.type == "export" then
		self:SetTitle(L["Export"])
		self.label:Hide()
		self.nameString:Hide()
		self.nameEdit:Hide()
		self.codeBtn:SetPoint("TOPLEFT", 7, -24)
		self.codeBtn:Show()

		info.data.v = "retail"
		local str = util.getStringFromData(info.data, true)

		self.editBox:SetText(str)
		self.editBox:SetFocus()
		self.editBox:HighlightText()
		self.editBox:SetCursorPosition(0)

		self.btn1:Hide()
		self.btn2:SetText(OKAY)
		self.btn2:SetPoint("BOTTOM", 0, 5)
	elseif info.type == "dataImport" then
		local color = NIGHT_FAE_BLUE_COLOR:GenerateHexColorMarkup()
		self:SetTitle(L["Import"])
		self.codeBtn:Hide()
		self.label:Show()
		self.label:SetFormattedText("%s: %s%s|r\n%s: %s%s|r", info.typeLang, color, info.id, L["Received from"], color, info.fromName)
		self.data = info.data

		if info.defName then
			self.nameString:Show()
			self.nameEdit:Show()
			self.nameEdit:SetText(info.defName)
			self.nameEdit:SetFocus()
			self.nameEdit:HighlightText()
			self.nameEdit:SetCursorPosition(0)
			self.label:SetPoint("TOPLEFT", self.nameString, "BOTTOMLEFT", -3, -4)
		else
			self.nameString:Hide()
			self.nameEdit:Hide()
			self.label:SetPoint("TOPLEFT", 7, -24)
		end

		self.btn1:Enable()
		self.btn1:Show()

		self.btn2:SetText(CANCEL)
		self.btn2:SetPoint("BOTTOMLEFT", self, "BOTTOM", 5, 5)
	end
end