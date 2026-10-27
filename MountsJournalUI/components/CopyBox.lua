local _, ns = ...
local cover = CreateFrame("BUTTON", nil, nil, "MJMotionPropagateTemplate")
cover:Hide()

local copyBox = CreateFrame("Editbox")
copyBox:Hide()
copyBox:SetAutoFocus(false)
copyBox:SetMultiLine(false)
copyBox:SetAltArrowKeyMode(true)
copyBox:SetJustifyH("CENTER")

copyBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
copyBox:SetScript("OnEditFocusLost", copyBox.Hide)
copyBox:SetScript("OnEscapePressed", copyBox.Hide)
copyBox:SetScript("OnHide", function(self)
	self:Hide()
	self.fontString:Show()
end)
copyBox:SetScript("OnTextChanged", function(self, userInput)
	if userInput then
		self:SetText(self.fontString:GetText())
		self:HighlightText()
	end
end)
copyBox:SetScript("OnEnter", function(self)
	cover:SetParent(self:GetParent())
	cover:SetAllPoints(self.fontString)
	cover:Show()
	cover.fontString = self.fontString
end)
cover:SetScript("OnClick", function(self)
	copyBox:Hide()
	copyBox:SetParent(self:GetParent())
	copyBox:ClearAllPoints()
	copyBox:SetPoint("TOPLEFT", self.fontString, -2, 0)
	copyBox:SetPoint("BOTTOMRIGHT", self.fontString, 2, 0)
	copyBox:SetFontObject(self.fontString:GetFontObject())
	copyBox:SetText(self.fontString:GetText())
	copyBox:SetCursorPosition(0)
	copyBox:Show()
	copyBox:SetFocus()
	copyBox.fontString = self.fontString
	copyBox.fontString:Hide()
	copyBox:SetFrameLevel(self:GetFrameLevel() - 1)
end)

local function fontString_OnEnter(self)
	if self:IsShown() then
		cover:SetParent(self:GetParent())
		cover:SetAllPoints(self)
		cover:Show()
		cover.fontString = self
	end
end

local function fontString_OnLeave(self)
	if self:IsShown() then
		cover:Hide()
	end
end

local function fontString_SetText(self, text)
	if copyBox.fontString == self and copyBox:IsShown() then
		copyBox:SetText(text)
		copyBox:SetCursorPosition(0)
		copyBox:HighlightText()
	end
end

function ns.util.setCopyBox(fontString)
	fontString:HookScript("OnEnter", fontString_OnEnter)
	fontString:HookScript("OnLeave", fontString_OnLeave)
	fontString:SetMouseClickEnabled(false)
	hooksecurefunc(fontString, "SetText", fontString_SetText)
end
