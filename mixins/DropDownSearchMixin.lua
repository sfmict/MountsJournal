local util = MountsJournalUtil
local dropDownOptions = {
	"keepShownOnClick",
	"arg1",
	"arg2",
	"notCheckable",
	"isNotRadio",
	"text",
	"checked",
	"func",
	"remove",
	"order",
}


local dropDownMenuButtonFrames = {}
function util.getDropDownMenuButtonFrame()
	for _, frame in ipairs(dropDownMenuButtonFrames) do
		if not frame:IsShown() then return frame:reset() end
	end
	local frame = CreateFrame("BUTTON", nil, MountJournal, "MJDropDownMenuButtonTemplate")
	tinsert(dropDownMenuButtonFrames, frame)
	return frame:reset()
end


MJDropDownMenuButtonMixin = {}


function MJDropDownMenuButtonMixin:reset()
	for _, opt in ipairs(dropDownOptions) do
		self[opt] = nil
	end
	return self
end


function MJDropDownMenuButtonMixin:refresh()
	self._checked = self.checked
	self._text = self.text

	if self._text then
		if type(self._text) == "function" then self._text = self._text() end
		self:SetText(self._text)
	end
	self.width = self.normalText:GetWidth() + 40

	if self.remove then
		self.removeButton:Show()
		self.width = self.width + 16
	else
		self.removeButton:Hide()
	end

	if self.order then
		self.arrowDownButton:Show()
		self.arrowUpButton:Show()
		self.width = self.width + 24
	else
		self.arrowDownButton:Hide()
		self.arrowUpButton:Hide()
	end

	if self.notCheckable then
		self.normalText:SetPoint("LEFT")
		self.Check:Hide()
		self.Uncheck:Hide()
		self.width = self.width - 30
	else
		self.normalText:SetPoint("LEFT", 20, 0)
		if type(self._checked) == "function" then self._checked = self:_checked() end
		if self._checked then
			self.Check:Show()
			self.Uncheck:Hide()
		else
			self.Check:Hide()
			self.Uncheck:Show()
		end

		if self.isNotRadio then
			self.Check:SetTexCoord(0, .5, 0, .5)
			self.Uncheck:SetTexCoord(.5, 1, 0, .5)
		else
			self.Check:SetTexCoord(0, .5, .5, 1)
			self.Uncheck:SetTexCoord(.5, 1, .5, 1)
		end
	end
end


function MJDropDownMenuButtonMixin:OnSetOwningButton()
	self:refresh()

	self:SetScript("OnClick", function(self)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		if not self.notCheckable then self._checked = not self._checked end
		if type(self.func) == "function" then self:func(self.arg1, self.arg2, self._checked) end
		if not self.keepShownOnClick then
			self:GetOwningDropdown():Hide()
		else
			self:refresh()
		end
	end)

	if self.remove then
		self.removeButton:SetScript("OnClick", function()
			self:remove(self.arg1, self.arg2)
			self:GetOwningDropdown():Hide()
		end)
	end

	if self.order then
		self.arrowUpButton:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			self:order(-1)
		end)
		self.arrowDownButton:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			self:order(1)
		end)
	end

	self.owningButton.checked = function() self:refresh() end
	self.owningButton.IsShown = function() return self:IsShown() end
	self.owningButton.SetWidth = function(_, width) self:SetWidth(width) end

	self:SetScript("OnHide", function(self)
		self.owningButton.checked = nil
		self.owningButton.IsShown = nil
		self.owningButton.SetWidth = nil
	end)
end


function MJDropDownMenuButtonMixin:GetPreferredEntryWidth()
	return self.width
end


local dropDownSearchFrames = {}
function util.getDropDownSearchFrame()
	for _, frame in ipairs(dropDownSearchFrames) do
		if not frame:IsShown() then return frame:reset() end
	end
	local frame = CreateFrame("FRAME", nil, MountJournal, "MJMenuDropDownSearchTemplate")
	tinsert(dropDownSearchFrames, frame)
	return frame:reset()
end


MJDropDownSearchMixin = {}


function MJDropDownSearchMixin:onLoad()
	self.buttons = {}
	self.filtredButtons = {}
	self.numButtons = 20 + math.ceil(26 / UIDROPDOWNMENU_BUTTON_HEIGHT)
	self.height = UIDROPDOWNMENU_BUTTON_HEIGHT * self.numButtons
	self:SetHeight(self.height)

	self.searchBox:SetScript("OnTextChanged", function(searchBox)
		SearchBoxTemplate_OnTextChanged(searchBox)
		self:updateFilters()
	end)

	self.listScroll:SetSize(30, self.height - 26)
	self.listScroll.update = function() self:refresh() end
	self.listScroll.scrollBar.doNotHide = true
	HybridScrollFrame_CreateButtons(self.listScroll, "MJDropDownMenuButtonTemplate")
end


function MJDropDownSearchMixin:reset()
	self.index = 1
	self.width = 0
	wipe(self.buttons)
	return self
end


function MJDropDownSearchMixin:OnSetOwningButton()
	local listFrame = self:GetOwningDropdown()
	self:SetFrameLevel(listFrame:GetFrameLevel() + 3)
	local spaceInfo = {
		notCheckable = true,
		disabled = true,
	}
	local level = listFrame:GetID()
	for i = 1, self.numButtons - 1 do
		UIDropDownMenu_AddButton(spaceInfo, level)
	end
	self.searchBox:SetText("")

	self.owningButton.checked = function() self:refresh() end
	self.owningButton.IsShown = function() return self:IsShown() end
	self.owningButton.SetWidth = function(_, width) self:SetWidth(width) end

	self:SetScript("OnHide", function(self)
		self.owningButton.checked = nil
		self.owningButton.IsShown = nil
		self.owningButton.SetWidth = nil
	end)
end


function MJDropDownSearchMixin:GetPreferredEntryWidth()
	return self.width
end


function MJDropDownSearchMixin:onShow()
	self:SetPoint(self.owningButton:GetPoint())
	local listFrame = self:GetOwningDropdown()
	listFrame:SetHeight(listFrame.numButtons * UIDROPDOWNMENU_BUTTON_HEIGHT + UIDROPDOWNMENU_BORDER_HEIGHT * 2)
	self:updateFilters()
	HybridScrollFrame_ScrollToIndex(self.listScroll, self.index, function()
		return self.listScroll.buttonHeight
	end)
end


function MJDropDownSearchMixin:updateFilters()
	local text = util.cleanText(self.searchBox:GetText())

	wipe(self.filtredButtons)
	for _, btn in ipairs(self.buttons) do
		if text:len() == 0 or (type(btn.text) == "function" and btn.text() or btn.text):lower():find(text) then
			tinsert(self.filtredButtons, btn)
		end
	end

	self:refresh()
end


function MJDropDownSearchMixin:refresh()
	local scrollFrame = self.listScroll
	local offset = HybridScrollFrame_GetOffset(scrollFrame)
	local numButtons = #self.filtredButtons

	for i, btn in ipairs(scrollFrame.buttons) do
		local index = i + offset

		if index <= numButtons then
			local info = self.filtredButtons[index]
			for _, opt in ipairs(dropDownOptions) do
				btn[opt] = info[opt]
			end
			btn:refresh()

			btn:SetScript("OnClick", function(btn)
				PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
				if not btn.notCheckable then btn._checked = not btn._checked end
				if type(btn.func) == "function" then btn:func(btn.arg1, btn.arg2, btn._checked) end
				if not btn.keepShownOnClick then
					self:GetOwningDropdown():Hide()
				else
					self:refresh()
				end
			end)

			if btn.remove then
				btn.removeButton:SetScript("OnClick", function()
					btn:remove(btn.arg1, btn.arg2)
					self:GetOwningDropdown():Hide()
				end)
			end

			if btn.order then
				btn.arrowUpButton:SetScript("OnClick", function()
					PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
					btn:order(-1)
					self:refresh()
				end)
				btn.arrowDownButton:SetScript("OnClick", function()
					PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
					btn:order(1)
					self:refresh()
				end)
			end

			btn:SetWidth(self:GetWidth() - 25)
			btn:Show()
		else
			btn:Hide()
		end
	end

	HybridScrollFrame_Update(scrollFrame, scrollFrame.buttonHeight * numButtons, scrollFrame:GetHeight())
end


function MJDropDownSearchMixin:addButton(info)
	tinsert(self.buttons, util:copyTable(info))

	local btn = self.listScroll.buttons[1]
	if btn then
		if info.text then
			btn:SetText(type(info.text) == "function" and info.text() or info.text)
			local width = btn.normalText:GetWidth() + 50

			if info.notCheckable then
				width = width - 20
			elseif not info.isNotRadio then
				local checked = info.checked
				if type(checked) == "function" then checked = checked(info) end
				if checked then self.index = #self.buttons end
			end

			if info.remove then
				width = width + 16
			end

			if info.order then
				width = width + 24
			end

			if self.width < width then
				self.width = width
			end
		end
	end
end