local adddon = ...
local binding = CreateFrame("Frame", adddon.."Binding")
binding.mode = 1
binding:Hide()


binding:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self.action(GetCurrentBindingSet())
end)


function binding:createButtonBinding(parent, name, secureTemplate, macro)
	local button = CreateFrame("Button", nil, parent, "UIMenuButtonStretchTemplate")
	button.selectedHighlight = button:CreateTexture(nil, "OVERLAY")
	button.selectedHighlight:SetTexture("Interface/Buttons/UI-Silver-Button-Select")
	button.selectedHighlight:SetPoint("TOPLEFT", 0, -3)
	button.selectedHighlight:SetPoint("BOTTOMRIGHT", 0, -3)
	button.selectedHighlight:SetBlendMode("ADD")
	button.selectedHighlight:Hide()
	button:RegisterForClicks("AnyUp")
	button.secure = CreateFrame("Button", name, UIParent, secureTemplate or "SecureActionButtonTemplate")
	button.secure:SetAttribute("type", "macro")
	if macro then button.secure:SetAttribute("macrotext", macro) end
	button.command = "CLICK "..name..":LeftButton"
	button:SetScript("OnClick", function(self, button) binding:OnClick(self, button) end)
	button:SetScript("OnMouseWheel", function(self, delta) binding:OnKeyDown(delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN") end)
	self:setButtonText(button)
	return button
end


function binding:setButtonText(button)
	local key1 = GetBindingKey(button.command, self.mode)

	if key1 then
		button:SetText(GetBindingText(key1))
		button:SetAlpha(1)
	else
		button:SetText(GRAY_FONT_COLOR_CODE..NOT_BOUND..FONT_COLOR_CODE_CLOSE)
		button:SetAlpha(0.8)
	end
end


function binding:setSelected(button)
	if button then
		self.selected = button
		self:Show()
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


function binding:OnClick(button, key)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	if key == "LeftButton" or key == "RightButton" then
		if self.selected then
			self:setSelected()
		else
			self:setSelected(button)
		end
	else
		self:OnKeyDown(key)
	end
end


function binding:OnKeyDown(keyPressed)
	if GetBindingFromClick(keyPressed) == "SCREENSHOT" then
		Screenshot()
	elseif self.selected then
		keyPressed = GetConvertedKeyOrButton(keyPressed)

		if not IsKeyPressIgnoredForBinding(keyPressed) then
			keyPressed = CreateKeyChordString(keyPressed)

			self:setBinding(keyPressed, self.selected.command)
			self:setButtonText(self.selected)
			self:setSelected()
		end
	end
end
binding:SetScript("OnKeyDown", binding.OnKeyDown)


function binding:setBinding(key, selectedBinding)
	if not InCombatLockdown() then
		local oldKey = GetBindingKey(selectedBinding, self.mode)

		if SetBinding(key, selectedBinding, self.mode) and oldKey then
			SetBinding(oldKey, nil, self.mode)
		end
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
end