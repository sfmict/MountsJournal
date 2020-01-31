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


function MJDropDownSearchMixin:OnSetOwningButton()
	local listFrame = self:GetOwningDropdown()
	self:SetFrameLevel(listFrame:GetFrameLevel() + 3)
	local spaceInfo = {
		notCheckable = true,
		disabled = true,
	}
	local level = (tonumber(listFrame:GetName():match("%d+")))
	for i = 1, self.numButtons - 1 do
		UIDropDownMenu_AddButton(spaceInfo, level)
	end
	if #self.listScroll.buttons ~= 0 then
		local btn = self.listScroll.buttons[1]
		for _, info in ipairs(self.buttons) do
			if info.text then
				btn:SetText(info.text)
				local width = btn.normalText:GetWidth() + 50

				if info.notCheckable then
					width = width - 20
				end

				if listFrame.maxWidth < width then
					listFrame.maxWidth = width
					self:SetWidth(width)
				end
			end
		end
	end
	HybridScrollFrame_ScrollToIndex(self.listScroll, 1, function() return 0 end)
	self.searchBox:SetText("")
	self:updateFilters()
end


function MJDropDownSearchMixin:reset()
	wipe(self.buttons)
end


function MJDropDownSearchMixin:onShow()
	self:SetPoint("TOPRIGHT", self.owningButton, "TOPRIGHT")
	local listFrame = self:GetOwningDropdown()
	listFrame:SetHeight((listFrame.numButtons * UIDROPDOWNMENU_BUTTON_HEIGHT) + (UIDROPDOWNMENU_BORDER_HEIGHT * 2))
end


function MJDropDownSearchMixin:updateFilters()
	local text = self.searchBox:GetText():lower():gsub("[%(%)%.%%%+%-%*%?%[%^%$]", function(char) return "%"..char end)

	wipe(self.filtredButtons)
	for _, btn in ipairs(self.buttons) do
		if text:len() == 0 or btn.text:lower():find(text) then
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
			btn.keepShownOnClick = info.keepShownOnClick
			btn.arg1 = info.arg1
			btn.arg2 = info.arg2

			if info.text then
				btn:SetText(info.text)
			end

			if info.notCheckable then
				btn.normalText:SetPoint("LEFT")
				btn.Check:Hide()
				btn.Uncheck:Hide()
			else
				btn.normalText:SetPoint("LEFT", 20, 0)
				local checked = info.checked
				if type(checked) == "function" then checked = checked(btn) end
				if checked then
					btn.Check:Show()
					btn.Uncheck:Hide()
				else
					btn.Check:Hide()
					btn.Uncheck:Show()
				end
			end

			btn:SetScript("OnClick", function(btn)
				PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
				if type(info.func) == "function" then info.func(btn, btn.arg1, btn.arg2) end
				if not btn.keepShownOnClick then
					self:GetOwningDropdown():Hide()
				else
					self:refresh()
				end
			end)

			btn:SetWidth(self:GetOwningDropdown().maxWidth - 25)
			btn:Show()
		else
			btn:Hide()
		end
	end

	HybridScrollFrame_Update(scrollFrame, scrollFrame.buttonHeight * numButtons, scrollFrame:GetHeight())
end


function MJDropDownSearchMixin:addButton(info)
	tinsert(self.buttons, {
		notCheckable = info.notCheckable,
		keepShownOnClick = info.keepShownOnClick,
		text = info.text,
		arg1 = info.arg1,
		arg2 = info.arg2,
		checked = info.checked,
		func = info.func,
	})
end