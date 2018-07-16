local adddon = ...
local binding = CreateFrame("Frame", adddon.."Binding")
binding.mode = 1
binding:Hide()


function binding:createButtonBinding(parent, name, macro)
	local button = CreateFrame("Button", nil, parent, "UIMenuButtonStretchTemplate")
	button:SetSize(180, 22)
	button.selectedHighlight = button:CreateTexture(nil, "OVERLAY")
	button.selectedHighlight:SetTexture("Interface/Buttons/UI-Silver-Button-Select")
	button.selectedHighlight:SetSize(180, 20)
	button.selectedHighlight:SetPoint("CENTER", 0, -3)
	button.selectedHighlight:SetBlendMode("ADD")
	button.selectedHighlight:Hide()
	button:RegisterForClicks("AnyUp")
	button.secure = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
	button.secure:SetAttribute("type", "macro")
	button.secure:SetAttribute("macrotext", macro)
	button.command = "CLICK "..name..":LeftButton"
	button:SetScript("OnClick", function(self, button) binding:OnClick(self, button) end)
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



function binding:OnKeyDown(key)
	if GetBindingFromClick(key) == "SCREENSHOT" then
		Screenshot()
	elseif self.selected then
		local keyPressed = key
		if keyPressed == "UNKNOWN" then return end

		if keyPressed == "LeftButton" then
			keyPressed = "BUTTON1"
		elseif keyPressed == "RightButton" then
			keyPressed = "BUTTON2"
		elseif keyPressed == "MiddleButton" then
			keyPressed = "BUTTON3"
		elseif keyPressed == "Button4" then
			keyPressed = "BUTTON4"
		elseif keyOrButton == "Button5" then
			keyPressed = "BUTTON5"
		elseif keyPressed == "Button6" then
			keyPressed = "BUTTON6"
		elseif keyOrButton == "Button7" then
			keyPressed = "BUTTON7"
		elseif keyPressed == "Button8" then
			keyPressed = "BUTTON8"
		elseif keyOrButton == "Button9" then
			keyPressed = "BUTTON9"
		elseif keyPressed == "Button10" then
			keyPressed = "BUTTON10"
		elseif keyOrButton == "Button11" then
			keyPressed = "BUTTON11"
		elseif keyPressed == "Button12" then
			keyPressed = "BUTTON12"
		elseif keyOrButton == "Button13" then
			keyPressed = "BUTTON13"
		elseif keyPressed == "Button14" then
			keyPressed = "BUTTON14"
		elseif keyOrButton == "Button15" then
			keyPressed = "BUTTON15"
		elseif keyPressed == "Button16" then
			keyPressed = "BUTTON16"
		elseif keyOrButton == "Button17" then
			keyPressed = "BUTTON17"
		elseif keyPressed == "Button18" then
			keyPressed = "BUTTON18"
		elseif keyOrButton == "Button19" then
			keyPressed = "BUTTON19"
		elseif keyPressed == "Button20" then
			keyPressed = "BUTTON20"
		elseif keyOrButton == "Button21" then
			keyPressed = "BUTTON21"
		elseif keyPressed == "Button22" then
			keyPressed = "BUTTON22"
		elseif keyOrButton == "Button23" then
			keyPressed = "BUTTON23"
		elseif keyPressed == "Button24" then
			keyPressed = "BUTTON24"
		elseif keyOrButton == "Button25" then
			keyPressed = "BUTTON25"
		elseif keyPressed == "Button26" then
			keyPressed = "BUTTON26"
		elseif keyOrButton == "Button27" then
			keyPressed = "BUTTON27"
		elseif keyPressed == "Button28" then
			keyPressed = "BUTTON28"
		elseif keyOrButton == "Button29" then
			keyPressed = "BUTTON29"
		elseif keyPressed == "Button30" then
			keyPressed = "BUTTON30"
		elseif keyOrButton == "Button31" then
			keyPressed = "BUTTON31"
		end
		if keyPressed == "BUTTON1" or keyPressed == "BUTTON2" then
			return
		end

		if keyPressed == "LSHIFT" or
			keyPressed == "RSHIFT" or
			keyPressed == "LCTRL" or
			keyPressed == "RCTRL" or
			keyPressed == "LALT" or
			keyPressed == "RALT" then
			return
		end
		if IsShiftKeyDown() then
			keyPressed = "SHIFT-"..keyPressed
		end
		if IsControlKeyDown() then
			keyPressed = "CTRL-"..keyPressed
		end
		if IsAltKeyDown() then
			keyPressed = "ALT-"..keyPressed
		end

		self.selected.oldKey = GetBindingKey(self.selected.command, self.mode)
		self:setBinding(keyPressed, self.selected.command)
		self:setButtonText(self.selected)
		self:setSelected()
	end
end
binding:SetScript("OnKeyDown", binding.OnKeyDown)


function binding:setBinding(key, selectedBinding)
	if not InCombatLockdown() then
		local oldKey = GetBindingKey(selectedBinding, self.mode)

		if key then
			if SetBinding(key, selectedBinding, self.mode) then
				if oldKey then SetBinding(oldKey, nil, self.mode) end
				SaveBindings(GetCurrentBindingSet())
			end
		else
			if oldKey then
				SetBinding(oldKey, nil, self.mode)
				SaveBindings(GetCurrentBindingSet())
			end
		end
	end
end