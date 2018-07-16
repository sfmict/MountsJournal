local addon, L = ...
local mounts = MountsJournal
local binding = _G[addon.."Binding"]
local config = CreateFrame("Frame", "MountsJournalConfig", InterfaceOptionsFramePanelContainer)
config.name = addon


-- BIND MOUNT
local bindMount = binding:createButtonBinding(config, "MountsJournal_Mount", "/mount")


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
	modifierText:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 8, -20)
	modifierText:SetText(L["Modifier"]..":")

	-- MODIFIER COMBOBOX
	local modifierCombobox = CreateFrame("Frame", "MountsJournalModifier", config, "UIDropDownMenuTemplate")
	modifierCombobox:SetPoint("TOPLEFT", modifierText, "BOTTOMRIGHT", -8, 21)

	config.modifierValue = mounts.config.modifier

	UIDropDownMenu_Initialize(modifierCombobox, function (self, level, menuList)
		local info = UIDropDownMenu_CreateInfo()
		for i, modifier in pairs({"ALT", "CTRL", "SHIFT"}) do
			info.menuList = i - 1
			info.checked = modifier == config.modifierValue
			info.text = modifier.." key"
			info.arg1 = modifier
			info.func = function(_, value)
				config.modifierValue = value
				UIDropDownMenu_SetText(modifierCombobox, value.." key")
			end
			UIDropDownMenu_AddButton(info)
		end
	end)

	setTooltip(modifierCombobox, "ANCHOR_TOPLEFT", L["Modifier"], L["ModifierDescription"])

	-- WATER JUMP
	local waterJump = CreateFrame("CheckButton", "MountsJournalWaterJump", config, "InterfaceOptionsCheckButtonTemplate")
	waterJump:SetPoint("TOPLEFT", modifierText, "BOTTOMLEFT", 0, -10)
	waterJump.label = _G[waterJump:GetName().."Text"]
	waterJump.label:SetFont("GameFontHighlight", 30)
	waterJump.label:SetPoint("LEFT", waterJump, "RIGHT", 1, 0)
	waterJump.label:SetText(L["Handle a jump in water"])
	waterJump.tooltipText = L["Handle a jump in water"]
	waterJump.tooltipRequirement = L["После прыжка в воде будет вызывать не подводный маунт."]

	-- CREATE MACRO
	local createMacroBtn = CreateFrame("Button", nil, config, "UIPanelButtonTemplate")
	createMacroBtn:SetSize(232, 40)
	createMacroBtn:SetPoint("TOPLEFT", waterJump, "BOTTOMLEFT", 0, -25)
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

	-- OR TEXT
	local macroOrBind = config:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	macroOrBind:SetPoint("TOP", createMacroBtn, "BOTTOM", 0, -4)
	macroOrBind:SetText(L["or key bind"])

	-- BIND MOUNT
	bindMount:SetSize(232, 22)
	bindMount:SetPoint("TOP", createMacroBtn, "BOTTOM", 0, -20)

	-- WATER WALKER EYE
	local waterWalkerEye = CreateFrame("CheckButton", "MountsJournalWaterWalkEye", config, "InterfaceOptionsCheckButtonTemplate")
	waterWalkerEye:SetPoint("LEFT", modifierCombobox, "RIGHT", 180, 2)
	waterWalkerEye.label = _G[waterWalkerEye:GetName().."Text"]
	waterWalkerEye.label:SetFont("GameFontHighlight", 30)
	waterWalkerEye.label:SetPoint("LEFT", waterWalkerEye, "RIGHT", 1, 0)
	waterWalkerEye.label:SetText(L["Water Walking in Eye of Azchara"])
	waterWalkerEye.tooltipText = L["Water Walking"]
	waterWalkerEye.tooltipRequirement = L["WaterWalkingDescription"]

	-- WATER WALKER ALWAYS
	local waterWalkerAlways = CreateFrame("CheckButton", "MountsJournalWaterWalkAlways", config, "InterfaceOptionsCheckButtonTemplate")
	waterWalkerAlways:SetPoint("TOPLEFT", waterWalkerEye, "BOTTOMLEFT", 0, 0)
	waterWalkerAlways.label = _G[waterWalkerAlways:GetName().."Text"]
	waterWalkerAlways.label:SetFont("GameFontHighlight", 30)
	waterWalkerAlways.label:SetPoint("LEFT", waterWalkerAlways, "RIGHT", 1, 0)
	waterWalkerAlways.label:SetText(L["Water Walking Always"])
	waterWalkerAlways.tooltipText = L["Water Walking"]
	waterWalkerAlways.tooltipRequirement = L["WaterWalkingDescription"]

	-- REFRESH
	local function refresh()
		if not config:IsVisible() then return end
		config.modifierValue = mounts.config.modifier
		UIDropDownMenu_SetText(modifierCombobox, config.modifierValue.." key")
		waterJump:SetChecked(mounts.config.waterJump)
		waterWalkerEye:SetChecked(mounts.config.waterWalkInstance)
		waterWalkerAlways:SetChecked(mounts.config.waterWalkAll)
		bindMount.oldKey = false
		binding:setButtonText(bindMount)
	end

	config:SetScript("OnShow", refresh)
	refresh()
end)


config.okay = function()
	mounts:setModifier(config.modifierValue)
	binding:saveBinding()
	mounts:setHandleWaterJump(MountsJournalWaterJump:GetChecked())
	mounts.config.waterWalkInstance = MountsJournalWaterWalkEye:GetChecked()
	mounts.config.waterWalkAll = MountsJournalWaterWalkAlways:GetChecked()
end


config.cancel = function()
	binding:resetBinding()
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