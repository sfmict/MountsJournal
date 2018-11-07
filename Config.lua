local addon, L = ...
local mounts = MountsJournal
local binding = _G[addon.."Binding"]
local config = CreateFrame("Frame", "MountsJournalConfig", InterfaceOptionsFramePanelContainer)
config.name = addon


config:SetScript("OnEvent", function(self, event, ...)
	if config[event] then
		config[event](self, ...)
	end
end)
config:RegisterEvent("PLAYER_LOGIN")


-- BIND MOUNT
local function getMacroText()
	local text = "/"
	if not mounts.config.useMagicBroom or mounts:herbMountsExists() or mounts:waterWalkMountsExists() or not config.broom then
		text = text.."mount"
	else
		local modifier = mounts.config.modifier
		text = text.."use [nomounted,noswimming,nomod:"..modifier.."][nomounted,flyable,mod:"..modifier.."]"..config.broom.."\n/mount"
	end
	return text
end

local function setMacroText()
	if not InCombatLockdown() then
		local macrotext = getMacroText()
		config.bindMount.secure:SetAttribute("macrotext", macrotext)
		local texture = select(2, GetMacroInfo("MJMacro"))
		if texture then
			EditMacro("MJMacro", "MJMacro", texture, macrotext)
		end
	else
		config:RegisterEvent("PLAYER_REGEN_ENABLED")
	end
end

function config:PLAYER_LOGIN()
	self.bindMount = binding:createButtonBinding(config, "MountsJournal_Mount")
	self.bindMount:SetSize(232, 22)
	self.broom = GetItemInfo(37011)
	if self.broom then
		setMacroText()
	else
		self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
	end
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function config:GET_ITEM_INFO_RECEIVED(itemID)
	if itemID == 37011 then
		self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
		self.broom = GetItemInfo(37011)
		setMacroText()
	end
end

function config:PLAYER_REGEN_ENABLED()
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	setMacroText()
end

function config:PLAYER_ENTERING_WORLD()
	setMacroText()
end


-- SHOW CONFIG
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

	-- CHECKBOX CHILD
	local function createCheckboxChild(text, id, tbl, parent, point)
		local check = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
		check.id = id
		if #tbl == 0 then
			check:SetPoint("TOPLEFT", point, "BOTTOMLEFT", 20, 0)
		else
			check:SetPoint("TOPLEFT", tbl[#tbl], "BOTTOMLEFT", 0, 0)
		end
		check.Text:SetFont("GameFontHighlight", 30)
		check.Text:SetPoint("LEFT", check, "RIGHT", 1, 0)
		check.Text:SetText(text)
		check.tooltipText = L["Water Walking"]
		check.tooltipRequirement = L["WaterWalkingDescription"]
		tinsert(tbl, check)
	end

	-- ADDON INFO
	local info = config:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	info:SetPoint("BOTTOMRIGHT", -16, 16)
	info:SetTextColor(.5, .5, .5, 1)
	info:SetText(format("%s %s: %s", GetAddOnMetadata(addon, "Version"), L["author"], GetAddOnMetadata(addon, "Author")))

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

	-- LEFT PANEL
	local leftPanel = CreateFrame("Frame", nil, config, "MJOptionsPanel")
	leftPanel:SetPoint("TOPLEFT", config, 8, -67)
	leftPanel:SetPoint("BOTTOMRIGHT", config, "BOTTOMLEFT", 300, 35)

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
		local macroName = "MJMacro"
		DeleteMacro(macroName)
		CreateMacro(macroName, select(3, GetSpellInfo(150544)), getMacroText())

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
	config.bindMount:SetPoint("TOP", createMacroBtn, "BOTTOM", 0, -20)

	-- RIGHT PANEL
	local rightPanel = CreateFrame("Frame", nil, config, "MJOptionsPanel")
	rightPanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", 4, 0)
	rightPanel:SetPoint("BOTTOMRIGHT", config, -8, 35)

	local rightPanelScroll = CreateFrame("ScrollFrame", nil, rightPanel, "UIPanelScrollFrameTemplate")
	rightPanelScroll:SetPoint("TOPLEFT", rightPanel, 4, -4)
	rightPanelScroll:SetPoint("BOTTOMRIGHT", rightPanel, -26, 3)
	rightPanelScroll.ScrollBar:SetBackdrop({bgFile='interface/buttons/white8x8'})
	rightPanelScroll.ScrollBar:SetBackdropColor(0,0,0,.2)
	rightPanelScroll.child = CreateFrame("Frame")
	rightPanelScroll.child:SetSize(1, 1)
	rightPanelScroll:SetScrollChild(rightPanelScroll.child)

	-- WATER WALKER ALWAYS
	config.waterWalkAlways = CreateFrame("CheckButton", nil, rightPanelScroll.child, "InterfaceOptionsCheckButtonTemplate")
	config.waterWalkAlways:SetPoint("TOPLEFT", rightPanelScroll.child, 9, -11)
	config.waterWalkAlways.Text:SetFont("GameFontHighlight", 30)
	config.waterWalkAlways.Text:SetPoint("LEFT", config.waterWalkAlways, "RIGHT", 1, 0)
	config.waterWalkAlways.Text:SetText(L["Water Walking Always"])
	config.waterWalkAlways.tooltipText = L["Water Walking"]
	config.waterWalkAlways.tooltipRequirement = L["WaterWalkingDescription"]

	-- WATER WALK INSTANCE
	config.waterWalkInstance = CreateFrame("CheckButton", nil, rightPanelScroll.child, "InterfaceOptionsCheckButtonTemplate")
	config.waterWalkInstance:SetPoint("TOPLEFT", config.waterWalkAlways, "BOTTOMLEFT", 0, 0)
	config.waterWalkInstance.Text:SetFont("GameFontHighlight", 30)
	config.waterWalkInstance.Text:SetPoint("LEFT", config.waterWalkInstance, "RIGHT", 1, 0)
	config.waterWalkInstance.Text:SetText(L["Water Walking in dungeons"])
	config.waterWalkInstance.tooltipText = L["Water Walking"]
	config.waterWalkInstance.tooltipRequirement = L["WaterWalkingDescription"]
	config.waterWalkInstance:SetScript("OnClick", function(self)
		config:setEnableCheckButtons(self:GetChecked(), config.dungeons)
	end)

	-- WATER WALK IN DUNGEONS
	config.dungeons = {}
	local function createDungeonCheckbox(text, id)
		createCheckboxChild(text, id, config.dungeons, rightPanelScroll.child, config.waterWalkInstance)
	end
	createDungeonCheckbox(L["Eye of Azchara (Legion)"], 1456)
	createDungeonCheckbox(L["Tol Dagor (BFA)"], 1771)

	-- WATER WALK EXPEDITION
	config.waterWalkExpedition = CreateFrame("CheckButton", nil, rightPanelScroll.child, "InterfaceOptionsCheckButtonTemplate")
	config.waterWalkExpedition:SetPoint("TOPLEFT", config.dungeons[#config.dungeons], "BOTTOMLEFT", -20, 0)
	config.waterWalkExpedition.Text:SetFont("GameFontHighlight", 30)
	config.waterWalkExpedition.Text:SetPoint("LEFT", config.waterWalkExpedition, "RIGHT", 1, 0)
	config.waterWalkExpedition.Text:SetText(L["Water Walking in expeditions"])
	config.waterWalkExpedition.tooltipText = L["Water Walking"]
	config.waterWalkExpedition.tooltipRequirement = L["WaterWalkingDescription"]
	config.waterWalkExpedition:SetScript("OnClick", function(self)
		config:setEnableCheckButtons(self:GetChecked(), config.expeditions)
	end)

	-- WATER WALK IN EXPEDITIONS
	config.expeditions = {}
	local function createExpeditionCheckbox(text, id)
		createCheckboxChild(text, id, config.expeditions, rightPanelScroll.child, config.waterWalkExpedition)
	end
	createExpeditionCheckbox(L["Un'gol Ruins"], 1813)
	createExpeditionCheckbox(L["Verdant Wilds"], 1882)
	createExpeditionCheckbox(L["Whispering Reef"], 1883)
	createExpeditionCheckbox(L["Rotting Mire"], 1892)
	createExpeditionCheckbox(L["Dread Chain"], 1893)
	createExpeditionCheckbox(L["Molten Cay"], 1897)
	createExpeditionCheckbox(L["Skittering Hollow"], 1898)

	-- USE HERBALISM MOUNTS
	config.useHerbMounts = CreateFrame("CheckButton", nil, rightPanelScroll.child, "InterfaceOptionsCheckButtonTemplate")
	config.useHerbMounts:SetPoint("TOPLEFT", config.expeditions[#config.expeditions], "BOTTOMLEFT", -20, -26)
	config.useHerbMounts.Text:SetFont("GameFontHighlight", 30)
	config.useHerbMounts.Text:SetPoint("LEFT", config.useHerbMounts, "RIGHT", 1, 0)
	config.useHerbMounts.Text:SetText(L["UseHerbMounts"])
	config.useHerbMounts.tooltipText = L["UseHerbMounts"]
	config.useHerbMounts.tooltipRequirement = L["UseHerbMountsDescription"]

	-- USE MAGIC BROOM
	config.useMagicBroom = CreateFrame("CheckButton", nil, rightPanelScroll.child, "InterfaceOptionsCheckButtonTemplate")
	config.useMagicBroom:SetPoint("TOPLEFT", config.useHerbMounts, "BOTTOMLEFT", 0, -26)
	config.useMagicBroom.Text:SetFont("GameFontHighlight", 30)
	config.useMagicBroom.Text:SetPoint("LEFT", config.useMagicBroom, "RIGHT", 1, 0)
	config.useMagicBroom.Text:SetText(L["UseMagicBroom"])
	config.useMagicBroom.tooltipText = L["UseMagicBroom"]
	config.useMagicBroom.tooltipRequirement = format("%s\n\n|cffff0000%s|r", L["UseMagicBroomDescription"], L["NeedRecreateMacro"])

	-- REFRESH
	local function refresh()
		if not config:IsVisible() then return end
		config.modifierValue = mounts.config.modifier
		UIDropDownMenu_SetText(modifierCombobox, config.modifierValue.." key")
		config.waterJump:SetChecked(mounts.config.waterJump)
		binding:setButtonText(config.bindMount)
		config.waterWalkAlways:SetChecked(mounts.config.waterWalkAll)
		config.waterWalkInstance:SetChecked(mounts.config.waterWalkInstance)
		config:setEnableCheckButtons(mounts.config.waterWalkInstance, config.dungeons)
		for _, dungeon in pairs(config.dungeons) do
			dungeon:SetChecked(mounts.config.waterWalkList[dungeon.id])
		end
		config.waterWalkExpedition:SetChecked(mounts.config.waterWalkExpedition)
		config:setEnableCheckButtons(mounts.config.waterWalkExpedition, config.expeditions)
		for _, expedition in pairs(config.expeditions) do
			expedition:SetChecked(mounts.config.waterWalkExpeditionList[expedition.id])
		end
		config.useHerbMounts:SetChecked(mounts.config.useHerbMounts)
		config.useMagicBroom:SetChecked(mounts.config.useMagicBroom)
	end

	config:SetScript("OnShow", refresh)
	refresh()
end)


function config:setEnableCheckButtons(enable, tbl)
	if enable then
		for _, check in pairs(tbl) do
			check:Enable()
			check.Text:SetTextColor(1,1,1,1)
		end
	else
		for _, check in pairs(tbl) do
			check:Disable()
			check.Text:SetTextColor(.5,.5,.5,1)
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
		mounts.config.waterWalkList[dungeon.id] = dungeon:GetChecked()
	end
	mounts.config.waterWalkExpedition = self.waterWalkExpedition:GetChecked()
	wipe(mounts.config.waterWalkExpeditionList)
	for _, expedition in pairs(self.expeditions) do
		mounts.config.waterWalkExpeditionList[expedition.id] = expedition:GetChecked()
	end
	mounts.config.useHerbMounts = self.useHerbMounts:GetChecked()
	mounts.config.useMagicBroom = self.useMagicBroom:GetChecked()
	setMacroText()
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