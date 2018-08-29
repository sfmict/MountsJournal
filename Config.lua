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
	config.waterJump = CreateFrame("CheckButton", nil, config, "InterfaceOptionsCheckButtonTemplate")
	config.waterJump:SetPoint("TOPLEFT", modifierText, "BOTTOMLEFT", 0, -10)
	config.waterJump.Text:SetFont("GameFontHighlight", 30)
	config.waterJump.Text:SetPoint("LEFT", config.waterJump, "RIGHT", 1, 0)
	config.waterJump.Text:SetText(L["Handle a jump in water"])
	config.waterJump.tooltipText = L["Handle a jump in water"]
	config.waterJump.tooltipRequirement = L["WaterJumpDescription"]

	-- CREATE MACRO
	local createMacroBtn = CreateFrame("Button", nil, config, "UIPanelButtonTemplate")
	createMacroBtn:SetSize(232, 40)
	createMacroBtn:SetPoint("TOPLEFT", config.waterJump, "BOTTOMLEFT", 0, -25)
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
	macroOrBind:SetPoint("TOP", createMacroBtn, "BOTTOM", 0, -3)
	macroOrBind:SetText(L["or key bind"])

	-- BIND MOUNT
	bindMount:SetSize(232, 22)
	bindMount:SetPoint("TOP", createMacroBtn, "BOTTOM", 0, -20)

	-- WATER WALKER ALWAYS
	config.waterWalkAlways = CreateFrame("CheckButton", nil, config, "InterfaceOptionsCheckButtonTemplate")
	config.waterWalkAlways:SetPoint("LEFT", modifierCombobox, "RIGHT", 180, 2)
	config.waterWalkAlways.Text:SetFont("GameFontHighlight", 30)
	config.waterWalkAlways.Text:SetPoint("LEFT", config.waterWalkAlways, "RIGHT", 1, 0)
	config.waterWalkAlways.Text:SetText(L["Water Walking Always"])
	config.waterWalkAlways.tooltipText = L["Water Walking"]
	config.waterWalkAlways.tooltipRequirement = L["WaterWalkingDescription"]

	-- WATER WALK INSTANCE
	config.waterWalkInstance = CreateFrame("CheckButton", nil, config, "InterfaceOptionsCheckButtonTemplate")
	config.waterWalkInstance:SetPoint("TOPLEFT", config.waterWalkAlways, "BOTTOMLEFT", 0, 0)
	config.waterWalkInstance.Text:SetFont("GameFontHighlight", 30)
	config.waterWalkInstance.Text:SetPoint("LEFT", config.waterWalkInstance, "RIGHT", 1, 0)
	config.waterWalkInstance.Text:SetText(L["Water Walking in dungeons"])
	config.waterWalkInstance.tooltipText = L["Water Walking"]
	config.waterWalkInstance.tooltipRequirement = L["WaterWalkingDescription"]
	config.waterWalkInstance:SetScript("OnClick", function(self) config:setEnableDungeons() end)

-- WATER WALK IN DUNGEONS
	config.dungeons = {}
	local function createDungeonCheckbox(text, id)
		local dungeon = CreateFrame("CheckButton", nil, config, "InterfaceOptionsCheckButtonTemplate")
		dungeon.id = id
		if #config.dungeons == 0 then
			dungeon:SetPoint("TOPLEFT", config.waterWalkInstance, "BOTTOMLEFT", 20, 0)
		else
			dungeon:SetPoint("TOPLEFT", config.dungeons[#config.dungeons], "BOTTOMLEFT", 0, 0)
		end
		dungeon.Text:SetFont("GameFontHighlight", 30)
		dungeon.Text:SetPoint("LEFT", dungeon, "RIGHT", 1, 0)
		dungeon.Text:SetText(L[text])
		dungeon.tooltipText = L["Water Walking"]
		dungeon.tooltipRequirement = L["WaterWalkingDescription"]
		tinsert(config.dungeons, dungeon)
	end

	createDungeonCheckbox("Eye of Azchara (Legion)", 1456)
	createDungeonCheckbox("Tol Dagor (BFA)", 1771)

	-- USE HERBALISM MOUNTS
	config.useHerbMounts = CreateFrame("CheckButton", nil, config, "InterfaceOptionsCheckButtonTemplate")
	config.useHerbMounts:SetPoint("TOPLEFT", config.waterWalkInstance, "BOTTOMLEFT", 0, -26 * 3)
	config.useHerbMounts.Text:SetFont("GameFontHighlight", 30)
	config.useHerbMounts.Text:SetPoint("LEFT", config.useHerbMounts, "RIGHT", 1, 0)
	config.useHerbMounts.Text:SetText(L["UseHerbMounts"])
	config.useHerbMounts.tooltipText = L["UseHerbMounts"]
	config.useHerbMounts.tooltipRequirement = L["UseHerbMountsDescription"]

	-- REFRESH
	local function refresh()
		if not config:IsVisible() then return end
		config.modifierValue = mounts.config.modifier
		UIDropDownMenu_SetText(modifierCombobox, config.modifierValue.." key")
		config.waterJump:SetChecked(mounts.config.waterJump)
		binding:setButtonText(bindMount)
		config.waterWalkAlways:SetChecked(mounts.config.waterWalkAll)
		config.waterWalkInstance:SetChecked(mounts.config.waterWalkInstance)
		config:setEnableDungeons()
		for _, dungeon in pairs(config.dungeons) do
			dungeon:SetChecked(mounts:inTable(mounts.config.waterWalkList, dungeon.id))
		end
		config.useHerbMounts:SetChecked(mounts.config.useHerbMounts)
	end

	config:SetScript("OnShow", refresh)
	refresh()
end)


function config:setEnableDungeons()
	if self.waterWalkInstance:GetChecked() then
		for _, dungeon in pairs(self.dungeons) do
			dungeon:Enable()
		end
	else
		for _, dungeon in pairs(self.dungeons) do
			dungeon:Disable()
		end
	end
end


config.okay = function(self)
	mounts:setModifier(self.modifierValue)
	binding:saveBinding()
	mounts:setHandleWaterJump(self.waterJump:GetChecked())
	mounts.config.waterWalkAll = self.waterWalkAlways:GetChecked()
	mounts.config.waterWalkInstance = self.waterWalkInstance:GetChecked()
	wipe(mounts.config.waterWalkList)
	for _, dungeon in pairs(self.dungeons) do
		if dungeon:GetChecked() then
			tinsert(mounts.config.waterWalkList, dungeon.id)
		end
	end
	mounts.config.useHerbMounts = self.useHerbMounts:GetChecked()
end


config.cancel = function()
	binding:resetBinding()
end


-- ADD CATEGORY
InterfaceOptions_AddCategory(config)


-- OPEN CONFIG
function config:openConfig()
	if InterfaceOptionsFrameAddOns:IsVisible() and config:IsVisible() then
		InterfaceOptionsFrame:Hide()
		config:cancel()
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