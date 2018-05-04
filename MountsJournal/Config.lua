local addon, L = ...
local configFrame = CreateFrame("Frame", "MountsJournalConfigFrame", InterfaceOptionsFramePanelContainer)
configFrame.name = addon


configFrame:SetScript("OnShow", function(...)
	-- TITLE
	local title = configFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(format(L["%s Configuration"], addon))

	-- SUBTITLE
	local subtitle = configFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtitle:SetHeight(30)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subtitle:SetNonSpaceWrap(true)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetJustifyV("TOP")
	subtitle:SetText(format(L["ConfigPanelTitle %s."], addon))

	-- MODIFIER TEXT
	local modifierText = configFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	modifierText:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 8, 0)
	modifierText:SetText(L["Modifier"]..":")

	-- MODIFIER COMBOBOX
	local modifierCombobox = CreateFrame("Frame", "MountsJournalModifier", configFrame, "UIDropDownMenuTemplate")
	modifierCombobox:SetPoint("TOPLEFT", modifierText, "BOTTOMRIGHT", -8, 21)
	UIDropDownMenu_SetText(modifierCombobox, "ALT key")

	configFrame.modifierValue = MountsJournal.config.modifier

	UIDropDownMenu_Initialize(modifierCombobox, function (self, level, menuList)
		local info = UIDropDownMenu_CreateInfo()
		for i, modifier in pairs({"ALT", "CTRL", "SHIFT"}) do
			info.menuList = i - 1
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
		GameTooltip:SetText(L["Modifier"])
		GameTooltip:AddLine(L["ModifierDescription"], 1, 1, 1, 1, true)
		GameTooltip:Show()
	end)

	modifierCombobox:SetScript("OnLeave", function()
		GameTooltip_Hide()
	end)

	-- CREATE MACRO
	local createMacroBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
	createMacroBtn:SetSize(232, 40)
	createMacroBtn:SetPoint("TOPLEFT", modifierText, "BOTTOMLEFT", 0, -25)
	createMacroBtn:SetText(L["CreateMacroBtn"])
	createMacroBtn:SetScript("OnClick", function()
		local macroName = addon.."Macro"
		DeleteMacro(macroName)
		CreateMacro(macroName, select(3, GetSpellInfo(150544)), "/mount")

		if not IsAddOnLoaded("Blizzard_MacroUI") then
			LoadAddOn("Blizzard_MacroUI")
		end

		MacroFrame_Show()
		if MacroFrame.selectedTab ~= 1 then
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			PanelTemplates_SetTab(MacroFrame, MacroFrameTab1:GetID())
			MacroFrame_SaveMacro()
			MacroFrame_SetAccountMacros()
		end

		local index = GetMacroIndexByName(macroName)
		local line = ceil(index / 6)
		MacroButtonScrollFrame:SetVerticalScroll(line < 3 and 0 or 46 * (line - 2))
		MacroButton_OnClick(({MacroButtonContainer:GetChildren()})[index])
	end)

	createMacroBtn:SetScript("OnEnter", function()
		GameTooltip:SetOwner(createMacroBtn, "ANCHOR_TOP")
		GameTooltip:SetText(L["CreateMacro"])
		GameTooltip:AddLine(L["CreateMacroTooltip"], 1, 1, 1, 1, true)
		GameTooltip:Show()
	end)

	createMacroBtn:SetScript("OnLeave", function()
		GameTooltip_Hide()
	end)

	-- REFRESH
	local function refresh()
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


-- ADD CATEGORY
InterfaceOptions_AddCategory(configFrame)


-- OPEN CONFIG
local function openConfig()
	if InterfaceOptionsFrameAddOns:IsVisible() and MountsJournalConfigFrame:IsVisible() then
		InterfaceOptionsFrame:Hide()
	else
		InterfaceOptionsFrame_OpenToCategory(addon)
		if not InterfaceOptionsFrameAddOns:IsVisible() then
			InterfaceOptionsFrame_OpenToCategory(addon)
		end
	end
end


SLASH_MOUNTSCONFIG1 = "/mountconfig"
SLASH_MOUNTSCONFIG2 = "/mco"
SlashCmdList["MOUNTSCONFIG"] = openConfig


-- EVENTS
configFrame:SetScript("OnEvent", function(self, event, ...)
	if configFrame[event] then
		configFrame[event](self, ...)
	end
end)
configFrame:RegisterEvent("ADDON_LOADED")


-- BUTTON CONFIG
function configFrame:ADDON_LOADED(addonName)
	if addonName == "Blizzard_Collections" or addonName == "MountJournal" and IsAddOnLoaded("Blizzard_Collections") then
		self:UnregisterEvent("ADDON_LOADED")

		local btnConfig = CreateFrame("Button", "MountsJournalBtnConfig", MountJournal, "UIPanelButtonTemplate")
		btnConfig:SetSize(80, 22)
		btnConfig:SetPoint("TOPLEFT", MountJournal.MountCount, "TOPRIGHT", 8, 1)
		btnConfig:SetText(L["Settings"])
		btnConfig:SetScript("OnClick", openConfig)
	end
end