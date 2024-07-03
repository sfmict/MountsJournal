local addon = ...
local util = MountsJournalUtil
local binding = CreateFrame("Frame", addon.."Binding")
binding:Hide()


binding.unboundMessage = binding:CreateFontString(nil, "ARTWORK", "GameFontWhite")
binding.unboundMessage:Hide()
util.setEventsMixin(binding)


binding:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self.action(GetCurrentBindingSet())
end)


local function button_OnEnter(self)
	local key = GetBindingKey(self.command)
	if key then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip_AddHighlightLine(GameTooltip, KEY_BINDING_NAME_AND_KEY:format(GetBindingName(self.command), GetBindingText(key)))
		GameTooltip_AddNormalLine(GameTooltip, KEY_BINDING_TOOLTIP)
		GameTooltip:Show()
	end
end
local function button_OnLeave() GameTooltip:Hide() end
local function button_OnShow(...) binding:setButtonText(...) end
local function button_OnClick(...) binding:OnClick(...) end
local function button_OnMouseWheel(self, delta)
	if binding.selected == self then
		binding:OnKeyDown(delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN")
	end
end


function binding:createButtonBinding(name, description, secureTemplate, macro)
	local button = CreateFrame("Button", nil, parent, "UIMenuButtonStretchTemplate")
	button.selectedHighlight = button:CreateTexture(nil, "OVERLAY")
	button.selectedHighlight:SetTexture("Interface/Buttons/UI-Silver-Button-Select")
	button.selectedHighlight:SetPoint("TOPLEFT", 0, -3)
	button.selectedHighlight:SetPoint("BOTTOMRIGHT", 0, -3)
	button.selectedHighlight:SetBlendMode("ADD")
	button.selectedHighlight:Hide()
	button:RegisterForClicks("AnyUp")
	button.secure = CreateFrame("Button", name, UIParent, secureTemplate or "SecureActionButtonTemplate")
	button.secure:RegisterForClicks("AnyUp", "AnyDown")
	button.secure:SetAttribute("type", "macro")
	if macro then button.secure:SetAttribute("macrotext", macro) end
	button.command = "CLICK "..name..":LeftButton"
	_G["BINDING_NAME_"..button.command] = description or name
	button:SetScript("OnEnter", button_OnEnter)
	button:SetScript("OnLeave", button_OnLeave)
	button:SetScript("OnShow", button_OnShow)
	button:SetScript("OnClick", button_OnClick)
	button:SetScript("OnMouseWheel", button_OnMouseWheel)
	util.setEventsMixin(button)
	button:on("SET_BINDING", button_OnShow)
	self:setButtonText(button)
	return button
end


function binding:setButtonText(button)
	local key1 = GetBindingKey(button.command)

	if key1 then
		button:SetText(GetBindingText(key1))
		button:SetAlpha(1)
	else
		button:SetText(GRAY_FONT_COLOR:WrapTextInColorCode(NOT_BOUND))
		button:SetAlpha(.8)
	end
end


function binding:setSelected(button)
	if button then
		self.selected = button
		self:Show()
		self.unboundMessage:Hide()
		button.selectedHighlight:Show()
		button:GetHighlightTexture():SetAlpha(0)
	else
		if self.selected then
			local button = self.selected
			self.selected = nil
			self:Hide()
			button.selectedHighlight:Hide()
			button:GetHighlightTexture():SetAlpha(1)
		end
	end
end


function binding:OnClick(button, keyButton)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	if keyButton == "LeftButton" then
		if self.selected then
			self:setSelected()
		else
			self:setSelected(button)
		end
	elseif keyButton == "RightButton" then
		if InCombatLockdown() then return end
		local key = GetBindingKey(button.command)
		if key then
			if self.selected == button then binding:setSelected() end
			self:setBinding(key, button.command)
			self:event("SET_BINDING")
		end
	else
		self:OnKeyDown(keyButton)
	end
end


function binding:OnKeyDown(keyPressed)
	if InCombatLockdown() then return end
	local action = GetBindingFromClick(keyPressed)
	if action == "SCREENSHOT" then
		Screenshot()
	elseif keyPressed == "ESCAPE" and action == "TOGGLEGAMEMENU" then
		self:setSelected()
	elseif self.selected then
		keyPressed = GetConvertedKeyOrButton(keyPressed)

		if not IsKeyPressIgnoredForBinding(keyPressed) then
			keyPressed = CreateKeyChordStringUsingMetaKeyState(keyPressed)

			self:setBinding(keyPressed, self.selected.command)
			self:event("SET_BINDING")
			self:setSelected()
		end
	end
end
binding:SetScript("OnKeyDown", binding.OnKeyDown)
binding:SetScript("OnGamePadButtonDown", binding.OnKeyDown)


function binding:setBinding(key, selectedBinding)
	if InCombatLockdown() then return end
	local oldAction = GetBindingAction(key)
	if oldAction ~= "" and oldAction ~= selectedBinding then
		self.unboundMessage:SetText(KEY_UNBOUND_ERROR:format(GetBindingName(oldAction)))
		self.unboundMessage:Show()
	end

	local oldKey = GetBindingKey(selectedBinding)
	if SetBinding(key, selectedBinding) and oldKey then
		SetBinding(oldKey, nil)
	end
end


function binding:saveBinding()
	self:setSelected()
	if InCombatLockdown() then
		self.action = SaveBindings
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	else
		SaveBindings(GetCurrentBindingSet())
	end
end


function binding:resetBinding()
	self:setSelected()
	if InCombatLockdown() then
		self.action = LoadBindings
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	else
		LoadBindings(GetCurrentBindingSet())
	end
	self:event("SET_BINDING")
end