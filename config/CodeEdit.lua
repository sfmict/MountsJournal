local addon, ns = ...
local L = ns.L
local codeEdit = CreateFrame("FRAME", "MountsJournalCodeEdit", ns.ruleConfig, "MJDarkPanelTemplate,MJEscHideTemplate")
ns.codeEdit = codeEdit
codeEdit:Hide()


local escOnShow = codeEdit:GetScript("OnShow")
codeEdit:HookScript("OnShow", function(self)
	self:SetScript("OnShow", escOnShow)
	self:EnableMouse(true)
	self:SetFrameLevel(1600)
	self:SetPoint("TOPLEFT", ns.journal.bgFrame, 0, -18)
	self:SetPoint("BOTTOMRIGHT", ns.snippets)

	-- NAME
	self.nameEdit = CreateFrame("EditBox", nil, self, "InputBoxInstructionsTemplate")
	self.nameEdit:SetAutoFocus(false)
	self.nameEdit:SetSize(300, 22)
	self.nameEdit:SetPoint("TOPLEFT", 40, -40)
	self.nameEdit:SetScript("OnEscapePressed", EditBox_ClearFocus)
	self.nameEdit:SetScript("OnEnterPressed", EditBox_ClearFocus)

	-- CONTROL BTNS
	self.cancelBtn = CreateFrame("BUTTON", nil, self, "UIPanelButtonTemplate")
	self.cancelBtn:SetPoint("BOTTOMRIGHT", -40, 20)
	self.cancelBtn:SetText(CANCEL)
	self.cancelBtn:SetScript("OnClick", function(btn)
		btn:GetParent():Hide()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	self.completeBtn = CreateFrame("BUTTON", nil, self, "UIPanelButtonTemplate")
	self.completeBtn:SetPoint("RIGHT", self.cancelBtn, "LEFt", -20, 0)
	self.completeBtn:SetText(COMPLETE)
	self.completeBtn:SetScript("OnClick", function(btn)
		local p = btn:GetParent()
		if p.cb(p.name, p.nameEdit:GetText(), p.editFrame:GetEditBox():GetText()) then p:Hide() end
	end)

	local width = math.max(self.cancelBtn:GetFontString():GetStringWidth(), self.completeBtn:GetFontString():GetStringWidth()) + 40
	self.cancelBtn:SetWidth(width)
	self.completeBtn:SetWidth(width)

	-- CODE
	self.codeBtn = CreateFrame("BUTTON", nil, self, "BackdropTemplate")
	self.codeBtn:SetPoint("TOPLEFT", self.nameEdit, "BOTTOMLEFT", -8, -20)
	self.codeBtn:SetPoint("BOTTOMRIGHT", self.cancelBtn, "TOPRIGHT", 0, 20)
	self.codeBtn:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileEdge = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	self.codeBtn:SetBackdropColor(.1, .1, .1)
	self.codeBtn:SetBackdropBorderColor(FRIENDS_GRAY_COLOR:GetRGB())
	self.codeBtn:SetScript("OnClick", function(btn) btn:GetParent().editFrame:GetEditBox():SetFocus() end)

	self.codeBtn.funcText = self.codeBtn:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	self.codeBtn.funcText:SetPoint("BOTTOMLEFT", self.codeBtn, "TOPLEFT", 2, 0)
	self.codeBtn.funcText:SetText("function(env)")

	self.codeBtn.endText = self.codeBtn:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	self.codeBtn.endText:SetPoint("TOPLEFT", self.codeBtn, "BOTTOMLEFT", 2, 0)
	self.codeBtn.endText:SetText("end")

	self.scrollBar = CreateFrame("EventFrame", nil, self, "WowTrimScrollBar")
	self.scrollBar:SetPoint("TOPRIGHT", self.codeBtn, -4, -5)
	self.scrollBar:SetPoint("BOTTOMRIGHT", self.codeBtn, -4, 4)

	self.editFrame = CreateFrame("FRAME", nil, self, "ScrollingEditBoxTemplate")

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
end)


function codeEdit:open(name, code, cb)
	self:Show()
	self.name = name
	self.nameEdit:SetText(name)
	self.editFrame:SetText(code)
	self.cb = cb
end


function codeEdit:nameFocus()
	self.nameEdit:SetFocus()
	self.nameEdit:HighlightText()
end


function codeEdit:codeFocus()
	self.editFrame:GetEditBox():SetFocus()
end