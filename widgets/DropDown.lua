local util = MountsJournalUtil
local dropDownOptions = {
	"keepShownOnClick",
	"hasArrow",
	"value",
	"owner",
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
local DropDownMenuButtonHeight = 16
local DropDownMenuSearchHeight = DropDownMenuButtonHeight * 20 + 26
local DROPDOWNBUTTON = nil


local dropDownMenusList = setmetatable({}, {
	__index = function(self, key)
		local frame = CreateFrame("FRAME", nil, key == 1 and UIParent or self[key - 1], "MJDropDownMenuTemplate")
		frame:SetFrameStrata("FULLSCREEN_DIALOG")
		frame.id = key
		frame.searchFrames = {}
		frame.buttonsList = setmetatable({}, {
			__index = function(self, key)
				local button = CreateFrame("BUTTON", nil, frame, "MJDropDownMenuButtonTemplate")
				button:SetPoint("RIGHT", -15, 0)
				self[key] = button
				return button
			end,
		})
		self[key] = frame
		return frame
	end,
})


local function ContainsMouse()
	for i = 1, #dropDownMenusList do
		local menu = dropDownMenusList[i]
		if menu:IsShown() and menu:IsMouseOver() then
			return true
		end
	end
	return false
end


local function ContainsFocus()
	local focus = GetMouseFocus()
	return focus and focus.MJNoGlobalMouseEvent
end


local menu1 = dropDownMenusList[1]
-- CLOSE ON ESC
menu1:SetScript("OnKeyDown", function(self, key)
	if key == GetBindingKey("TOGGLEGAMEMENU") then
		self:Hide()
		self:SetPropagateKeyboardInput(false)
	else
		self:SetPropagateKeyboardInput(true)
	end
end)
-- CLOSE WHEN CLICK ON A FREE PLACE
menu1:SetScript("OnEvent", function(self, event, button)
	if (button == "LeftButton" or button == "RightButton")
	and not (ContainsFocus() or ContainsMouse()) then
		self:Hide()
	end
end)
menu1:SetScript("OnShow", function(self)
	self:Raise()
	self:RegisterEvent("GLOBAL_MOUSE_DOWN")
end)
menu1:SetScript("OnHide", function(self)
	self:Hide()
	self:UnregisterEvent("GLOBAL_MOUSE_DOWN")
end)


MJDropDownButtonMixin = {}


function MJDropDownButtonMixin:ddSetSelectedValue(value, level, anchorFrame)
	self.selectedValue = value
	self:ddRefresh(level, anchorFrame)
end


function MJDropDownButtonMixin:ddSetSelectedText(text)
	self.Text:SetText(text)
end


function MJDropDownButtonMixin:ddSetInit(initFunction, displayMode)
	self.initialize = initFunction
	self.displayMode = displayMode
end


function MJDropDownButtonMixin:dropDownToggle(level, value, anchorFrame, xOffset, yOffset)
	if level == nil then level = 1 end
	local menu = dropDownMenusList[level]

	if menu:IsShown() then
		menu:Hide()
		if level == 1 and menu.anchorFrame == anchorFrame then return end
	end
	menu.anchorFrame = anchorFrame

	local displayMode
	if level == 1 then
		displayMode = self.displayMode
	else
		displayMode = dropDownMenusList[level - 1].displayMode
	end
	if displayMode == "menu" then
		menu.displayMode = "menu"
		menu.backdrop:Hide()
		menu.menuBackdrop:Show()
	else
		menu.displayMode = nil
		menu.backdrop:Show()
		menu.menuBackdrop:Hide()
	end

	if not xOffset or not yOffset then
		xOffset = -5
		yOffset = 5
	end

	menu.width = 0
	menu.height = 15
	menu.numButtons = 0
	wipe(menu.searchFrames)
	self:initialize(level, value)

	menu.width = menu.width + 30
	menu.height = menu.height + 15
	if menu.width < 60 then menu.width = 60 end
	if menu.height < 46 then menu.height = 46 end
	menu:SetSize(menu.width, menu.height)

	if level == 1 then
		DROPDOWNBUTTON = self
		menu:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", xOffset, yOffset)
	else
		if GetScreenWidth() - anchorFrame:GetRight() - 2 < menu.width then
			menu:SetPoint("TOPRIGHT", anchorFrame, "TOPLEFT", -2, 14)
		else
			menu:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 2, 14)
		end
	end
	menu:Show()
end


function MJDropDownButtonMixin:ddRefresh(level, anchorFrame)
	if not level then level = 1 end
	if not anchorFrame then anchorFrame = self end
	local menu = dropDownMenusList[level]

	for _, button in ipairs(menu.buttonsList) do
		if button:IsShown() then
			if type(button.text) == "function" then
				button._text = button.text()
				button:SetText(button._text)
			end

			if not button.notCheckable then
				if type(button.checked) == "function" then button._checked = button:checked() end
				button.Check:SetShown(button._checked)
				button.UnCheck:SetShown(not button._checked)

				if self.dropDownSetText and button._checked and menu.anchorFrame == anchorFrame then
					self:ddSetSelectedText(button._text)
				end
			end
		else
			break
		end
	end

	for _, searchFrame in ipairs(menu.searchFrames) do
		if searchFrame:IsShown() then
			searchFrame:refresh()
			if self.dropDownSetText and menu.anchorFrame == anchorFrame then
				for _, button in ipairs(searchFrame.buttons) do
					local checked = button.checked
					if type(checked) == "function" then checked = checked(button) end
					if checked then
						local text = button.text
						if type(text) == "function" then text = text() end
						self:ddSetSelectedText(text)
					end
				end
			end
		end
	end
end


function MJDropDownButtonMixin:closeDropDownMenus(level)
	dropDownMenusList[level or 1]:Hide()
end


function MJDropDownButtonMixin:ddAddButton(info, level)
	if not level then level = 1 end
	local width = 0
	local menu = dropDownMenusList[level]

	if info.list then
		if #info.list > 20 then
			local searchFrame = self:getDropDownSearchFrame()
			searchFrame:SetParent(menu)
			searchFrame:SetPoint("TOPLEFT", 15, -menu.height)
			searchFrame:SetPoint("RIGHT", -15, 0)
			searchFrame.listScroll.ScrollChild.id = level

			for _, subInfo in ipairs(info.list) do
				searchFrame:addButton(subInfo)
			end

			width = searchFrame:getEntryWidth()
			if menu.width < width then menu.width = width end
			searchFrame:Show()

			tinsert(menu.searchFrames, searchFrame)
			menu.height = menu.height + DropDownMenuSearchHeight
		else
			for _, subInfo in ipairs(info.list) do
				self:ddAddButton(subInfo, level)
			end
		end
		return
	end

	menu.numButtons = menu.numButtons + 1
	local button = menu.buttonsList[menu.numButtons]
	button:SetDisabledFontObject(GameFontDisableSmallLeft)
	button:Enable()

	for _, opt in ipairs(dropDownOptions) do
		button[opt] = info[opt]
	end

	if info.isTitle then
		button:SetDisabledFontObject(GameFontNormalSmallLeft)
	end

	if info.disabled or info.isTitle then
		button:Disable()
	end

	button._text = info.text
	if button._text then
		if type(button._text) == "function" then button._text = button._text() end
		button:SetText(button._text)
		button.NormalText:Show()
	else
		button:SetText("")
	end
	width = width + button.NormalText:GetWidth()

	if info.remove then
		button.removeButton:Show()
		width = width + 16
	else
		button.removeButton:Hide()
	end

	if info.order then
		button.arrowDownButton:Show()
		button.arrowUpButton:Show()
		width = width + 24
	else
		button.arrowDownButton:Hide()
		button.arrowUpButton:Hide()
	end

	if info.icon then
		button.Icon:SetTexture(info.icon)
		if info.iconInfo then
			button.Icon:SetSize(info.iconInfo.tSizeX or DropDownMenuButtonHeight, info.iconInfo.tSizeY or DropDownMenuButtonHeight)
		end
		if info.iconOnly then
			button.Icon:SetPoint("LEFT")
			button.NormalText:Hide()
		else
			button.Icon:ClearAllPoints()
			button.Icon:SetPoint("RIGHT")
			button.NormalText:Show()
		end
		button.Icon:Show()
	else
		button.Icon:Hide()
	end

	if info.notCheckable then
		button.Check:Hide()
		button.UnCheck:Hide()
		button.NormalText:SetPoint("LEFT")
	else
		button.NormalText:SetPoint("LEFT", 20, 0)
		width = width + 30

		if info.isNotRadio then
			button.Check:SetTexCoord(0, .5, 0, .5)
			button.UnCheck:SetTexCoord(.5, 1, 0, .5)
		else
			button.Check:SetTexCoord(0, .5, .5, 1)
			button.UnCheck:SetTexCoord(.5, 1, .5, 1)
		end

		button._checked = info.checked
		if type(button._checked) == "function" then button._checked = button:_checked() end

		button.Check:SetShown(button._checked)
		button.UnCheck:SetShown(not button._checked)
	end

	if info.hasArrow then
		width = width + 12
	end
	button.ExpandArrow:SetShown(info.hasArrow)

	button:SetPoint("TOPLEFT", 15, -menu.height)
	button:Show()

	menu.height = menu.height + DropDownMenuButtonHeight
	if menu.width < width then menu.width = width end
end


function MJDropDownButtonMixin:ddAddSeparator(level)
	local info = {
		disabled = true,
		notCheckable = true,
		iconOnly = true,
		icon = "Interface/Common/UI-TooltipDivider-Transparent",
		iconInfo = {
			tSizeX = 0,
			tSizeY = 8,
		},
	}
	self:ddAddButton(info, level)
end


local dropDownSearchFrames = {}
function MJDropDownButtonMixin:getDropDownSearchFrame()
	for _, frame in ipairs(dropDownSearchFrames) do
		if not frame:IsShown() then return frame:reset() end
	end
	local frame = CreateFrame("FRAME", nil, nil, "MJDropdownMenuSearchTemplate")
	tinsert(dropDownSearchFrames, frame)
	return frame:reset()
end


MJDropDownMenuButtonMixin = {}


function MJDropDownMenuButtonMixin:onLoad()
	self.removeButton:SetScript("OnClick", function()
		self:remove(self.arg1, self.arg2)
		DROPDOWNBUTTON:closeDropDownMenus()
	end)

	self.arrowUpButton:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self:order(-1)
		DROPDOWNBUTTON:ddRefresh(self:GetParent().id, DROPDOWNBUTTON.anchorFrame)
	end)
	self.arrowDownButton:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self:order(1)
		DROPDOWNBUTTON:ddRefresh(self:GetParent().id, DROPDOWNBUTTON.anchorFrame)
	end)
end


function MJDropDownMenuButtonMixin:onClick()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)

	if not self.notCheckable then
		self._checked = not self._checked
		if self.keepShownOnClick then
			self.Check:SetShown(self._checked)
			self.UnCheck:SetShown(not self._checked)
		end
	end

	if type(self.func) == "function" then
		self:func(self.arg1, self.arg2, self._checked)
	end

	if not self.keepShownOnClick then
		DROPDOWNBUTTON:closeDropDownMenus()
	end
end


function MJDropDownMenuButtonMixin:onEnter()
	self.isEnter = true
	if self:IsEnabled() then self.highlight:Show() end

	local level = self:GetParent().id + 1
	if self.hasArrow and self:IsEnabled() then
		DROPDOWNBUTTON:dropDownToggle(level, self.value, self)
	else
		DROPDOWNBUTTON:closeDropDownMenus(level)
	end

	if self.remove then
		self.removeButton:SetAlpha(1)
	end
	if self.order then
		self.arrowDownButton:SetAlpha(1)
		self.arrowUpButton:SetAlpha(1)
	end
end


function MJDropDownMenuButtonMixin:onLeave()
	self.isEnter = nil
	self.highlight:Hide()
	self.removeButton:SetAlpha(0)
	self.arrowDownButton:SetAlpha(0)
	self.arrowUpButton:SetAlpha(0)
end


function MJDropDownMenuButtonMixin:onDisable()
	self.Check:SetDesaturated(true)
	self.Check:SetAlpha(.5)
	self.UnCheck:SetDesaturated(true)
	self.UnCheck:SetAlpha(.5)
	self.ExpandArrow:SetDesaturated(true)
	self.ExpandArrow:SetAlpha(.5)
end


function MJDropDownMenuButtonMixin:onEnable()
	self.Check:SetDesaturated()
	self.Check:SetAlpha(1)
	self.UnCheck:SetDesaturated()
	self.UnCheck:SetAlpha(1)
	self.ExpandArrow:SetDesaturated()
	self.ExpandArrow:SetAlpha(1)
end


MJDropDownMenuSearchMixin = {}


function MJDropDownMenuSearchMixin:onLoad()
	self.buttons = {}
	self.filtredButtons = {}
	self:SetHeight(DropDownMenuSearchHeight)

	self.searchBox:SetScript("OnTextChanged", function(searchBox)
		SearchBoxTemplate_OnTextChanged(searchBox)
		self:updateFilters()
	end)

	self.listScroll:SetSize(30, DropDownMenuSearchHeight - 26)
	self.listScroll.update = function() self:refresh() end
	self.listScroll.scrollBar.doNotHide = true
	HybridScrollFrame_CreateButtons(self.listScroll, "MJDropDownMenuButtonTemplate")
end


function MJDropDownMenuSearchMixin:reset()
	self.index = 1
	self.width = 0
	wipe(self.buttons)
	return self
end


function MJDropDownMenuSearchMixin:getEntryWidth()
	return self.width
end


function MJDropDownMenuSearchMixin:onShow()
	self.searchBox:SetText("")
	self:updateFilters()
	HybridScrollFrame_ScrollToIndex(self.listScroll, self.index, function()
		return self.listScroll.buttonHeight
	end)
end


function MJDropDownMenuSearchMixin:updateFilters()
	local text = util.cleanText(self.searchBox:GetText())

	wipe(self.filtredButtons)
	for _, btn in ipairs(self.buttons) do
		if text:len() == 0 or (type(btn.text) == "function" and btn.text() or btn.text):lower():find(text) then
			tinsert(self.filtredButtons, btn)
		end
	end

	self:refresh()
end


function MJDropDownMenuSearchMixin:refresh()
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

			btn._text = btn.text

			if btn._text then
				if type(btn._text) == "function" then btn._text = btn._text() end
				btn:SetText(btn._text)
			else
				btn:SetText("")
			end

			if info.remove then
				btn.removeButton:Show()
			else
				btn.removeButton:Hide()
			end

			if info.order then
				btn.arrowDownButton:Show()
				btn.arrowUpButton:Show()
			else
				btn.arrowDownButton:Hide()
				btn.arrowUpButton:Hide()
			end

			if btn.notCheckable then
				btn.Check:Hide()
				btn.UnCheck:Hide()
				btn.NormalText:SetPoint("LEFT")
			else
				btn.NormalText:SetPoint("LEFT", 20, 0)

				if info.isNotRadio then
					btn.Check:SetTexCoord(0, .5, 0, .5)
					btn.UnCheck:SetTexCoord(.5, 1, 0, .5)
				else
					btn.Check:SetTexCoord(0, .5, .5, 1)
					btn.UnCheck:SetTexCoord(.5, 1, .5, 1)
				end

				btn._checked = btn.checked
				if type(btn._checked) == "function" then btn._checked = btn:_checked() end

				btn.Check:SetShown(btn._checked)
				btn.UnCheck:SetShown(not btn._checked)
			end

			if btn.isEnter then
				btn:GetScript("OnEnter")(btn)
			end

			btn:SetWidth(self:GetWidth() - 25)
			btn:Show()
		else
			btn:Hide()
		end
	end

	HybridScrollFrame_Update(scrollFrame, scrollFrame.buttonHeight * numButtons, scrollFrame:GetHeight())
end


function MJDropDownMenuSearchMixin:addButton(info)
	local button = {}
	for _, opt in ipairs(dropDownOptions) do
		button[opt] = info[opt]
	end
	tinsert(self.buttons, button)

	local btn = self.listScroll.buttons[1]
	if btn then
		if info.text then
			btn:SetText(type(info.text) == "function" and info.text() or info.text)
			local width = btn.NormalText:GetWidth() + 50

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