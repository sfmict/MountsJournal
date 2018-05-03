local addon = ...
local configFrame = CreateFrame("Frame", addon.."ConfigFrame", InterfaceOptionsFramePanelContainer)
configFrame.name = addon

configFrame:SetScript("OnShow", function(...)
	local title = configFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(addon.." Configuration")

	local subtitle = configFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtitle:SetHeight(30)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subtitle:SetNonSpaceWrap(true)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetJustifyV("TOP")
	subtitle:SetText("This panel can be used to configure "..addon..".")

	local modifierText = configFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	modifierText:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 8, 0)
	modifierText:SetText("Modifier:")

	local modifierCombobox = CreateFrame("Frame", addon.."Modifier", configFrame, "UIDropDownMenuTemplate")
	modifierCombobox:SetPoint("TOPLEFT", modifierText, "BOTTOMRIGHT", -8, 21)
	UIDropDownMenu_SetText(modifierCombobox, "ALT key")

	configFrame.modifierValue = MountsJournal.config.modifier

	UIDropDownMenu_Initialize(modifierCombobox, function (self, level, menuList)
		local info = UIDropDownMenu_CreateInfo()
		for i, modifier in pairs({"ALT", "CTRL", "SHIFT"}) do
			info.menuList = i-1
			info.checked = modifier == configFrame.modifierValue
			info.text = modifier.." key"
			info.arg1 = modifier
			info.func = self.SetValue
			UIDropDownMenu_AddButton(info)
		end
	end)

	function modifierCombobox:SetValue(newValue)
		configFrame.modifierValue = newValue
		UIDropDownMenu_SetText(modifierCombobox, newValue.." key")
		CloseDropDownMenus()
	end

	modifierCombobox:SetScript("OnEnter", function()
		GameTooltip:SetOwner(modifierCombobox, "ANCHOR_TOPLEFT")
		GameTooltip:SetText("Modifier")
		GameTooltip:AddLine("|cffffffffIf modifier is down: when swimming, it is not waterfowl, if you can fly and you do not swim, then the ground.|r", 1, 0.82, 0, 1, true)
		GameTooltip:Show()
	end)

	modifierCombobox:SetScript("OnLeave", function()
		GameTooltip_Hide()
	end)

	local refresh = function()
		if not configFrame:IsVisible() then return end
		configFrame.modifierValue = MountsJournal.config.modifier
		UIDropDownMenu_SetText(modifierCombobox, configFrame.modifierValue.." key")
	end

	configFrame:SetScript("OnShow", refresh)
	refresh()
end)


configFrame.okay = function()
	MountsJournal:setModifier(configFrame.modifierValue)
end


InterfaceOptions_AddCategory(configFrame)