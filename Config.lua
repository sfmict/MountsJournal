local addon, L = ...
local config = CreateFrame("Frame", "MountsJournalConfig", InterfaceOptionsFramePanelContainer)
config.name = addon


config:SetScript("OnShow", function()
	-- TOOLTIP
	local function setTooltip(frame, anchor, title, text)
		frame:SetScript("OnEnter", function()
			GameTooltip:SetOwner(frame, anchor)
			GameTooltip:SetText(title)
			GameTooltip:AddLine(text, 1, 1, 1, 1, true)
			GameTooltip:Show()
		end)

		frame:SetScript("OnLeave", function()
			GameTooltip_Hide()
		end)
	end

	-- TITLE
	local title = config:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(format(L["%s Configuration"], addon))

	-- SUBTITLE
	local subtitle = config:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtitle:SetHeight(30)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subtitle:SetNonSpaceWrap(true)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetJustifyV("TOP")
	subtitle:SetText(format(L["ConfigPanelTitle %s."], addon))

	-- MODIFIER TEXT
	local modifierText = config:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	modifierText:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 8, 0)
	modifierText:SetText(L["Modifier"]..":")

	-- MODIFIER COMBOBOX
	local modifierCombobox = CreateFrame("Frame", "MountsJournalModifier", config, "UIDropDownMenuTemplate")
	modifierCombobox:SetPoint("TOPLEFT", modifierText, "BOTTOMRIGHT", -8, 21)

	config.modifierValue = MountsJournal.config.modifier

	UIDropDownMenu_Initialize(modifierCombobox, function (self, level, menuList)
		local info = {}
		for i, modifier in pairs({"ALT", "CTRL", "SHIFT"}) do
			info.menuList = i - 1
			info.checked = modifier == config.modifierValue
			info.text = modifier.." key"
			info.arg1 = modifier
			info.func = self.SetValue
			UIDropDownMenu_AddButton(info)
		end
	end)

	function modifierCombobox:SetValue(newValue)
		config.modifierValue = newValue
		UIDropDownMenu_SetText(modifierCombobox, newValue.." key")
		CloseDropDownMenus()
	end

	setTooltip(modifierCombobox, "ANCHOR_TOPLEFT", L["Modifier"], L["ModifierDescription"])

	-- WATER WALK CHECK
	local waterWalkCheck = CreateFrame("CheckButton", "MountsJournalWaterWalkEye", config, "InterfaceOptionsCheckButtonTemplate")
	waterWalkCheck:SetPoint("LEFT", modifierCombobox, "RIGHT", 180, 2)
	waterWalkCheck.label = _G[waterWalkCheck:GetName().."Text"]
	waterWalkCheck.label:SetFont("GameFontHighlight", 30)
	waterWalkCheck.label:SetPoint("LEFT", waterWalkCheck, "RIGHT", 1, 0)
	waterWalkCheck.label:SetText(L["Water Walking in Eye of Azchara"])
	waterWalkCheck.tooltipText = L["Water Walking"]
	waterWalkCheck.tooltipRequirement = L["WaterWalkingDescription"]

	-- CREATE MACRO
	local createMacroBtn = CreateFrame("Button", nil, config, "UIPanelButtonTemplate")
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

		if MacroFrame:IsShown() then
			MacroFrame_Update()
		else
			MacroFrame_Show()
		end

		if MacroFrame.selectedTab ~= 1 then
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			PanelTemplates_SetTab(MacroFrame, MacroFrameTab1:GetID())
			MacroFrame_SaveMacro()
			MacroFrame_SetAccountMacros()
		end

		local index = GetMacroIndexByName(macroName)
		local line = ceil(index / 6)
		MacroButtonScrollFrame:SetVerticalScroll(line < 3 and 0 or 46 * (line - 2))
		MacroButton_OnClick(_G["MacroButton"..index])
	end)

	setTooltip(createMacroBtn, "ANCHOR_TOP", L["CreateMacro"], L["CreateMacroTooltip"])

	-- REFRESH
	local function refresh()
		if not config:IsVisible() then return end
		config.modifierValue = MountsJournal.config.modifier
		UIDropDownMenu_SetText(modifierCombobox, config.modifierValue.." key")
		waterWalkCheck:SetChecked(MountsJournal.config.waterWalkInstance)
	end

	config:SetScript("OnShow", refresh)
	refresh()
end)


config.okay = function()
	MountsJournal:setModifier(config.modifierValue)
	MountsJournal.config.waterWalkInstance = MountsJournalWaterWalk:GetChecked()
end


-- ADD CATEGORY
InterfaceOptions_AddCategory(config)


-- OPEN CONFIG
function config:openConfig()
	if InterfaceOptionsFrameAddOns:IsVisible() and MountsJournalConfig:IsVisible() then
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
SlashCmdList["MOUNTSCONFIG"] = config.openConfig