local addon, L = ...
local mounts = MountsJournal
local binding = _G[addon.."Binding"]
local config = CreateFrame("FRAME", "MountsJournalConfig", InterfaceOptionsFramePanelContainer)
config.name = addon


config:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		self[event](self, ...)
	end
end)
config:RegisterEvent("PLAYER_LOGIN")


-- BIND MOUNT
do
	local function setMacroText(self)
		if not InCombatLockdown() then
			local texture = select(2, GetMacroInfo("MJMacro"))
			if texture then
				EditMacro("MJMacro", "MJMacro", texture, "/click MountsJournal_Mount")
			end
		else
			self:RegisterEvent("PLAYER_REGEN_ENABLED")
		end
	end

	function config:PLAYER_REGEN_ENABLED()
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		setMacroText(self)
	end

	function config:PLAYER_LOGIN()
		self.bindMount = binding:createButtonBinding(self, "MountsJournal_Mount", "MJSecureActionButtonTemplate")
		self.bindMount:SetSize(232, 22)
		setMacroText(self)
	end
end


-- SHOW CONFIG
config:SetScript("OnShow", function(self)
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
		local check = CreateFrame("CheckButton", nil, parent, "MJCheckButtonTemplate")
		check.id = id
		if #tbl == 0 then
			check:SetPoint("TOPLEFT", point, "BOTTOMLEFT", 20, 0)
		else
			check:SetPoint("TOPLEFT", tbl[#tbl], "BOTTOMLEFT", 0, 0)
		end
		check.Text:SetText(text)
		check.tooltipText = L["Water Walking"]
		check.tooltipRequirement = L["WaterWalkingDescription"]
		tinsert(tbl, check)
	end

	-- ADDON INFO
	local info = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	info:SetPoint("TOPRIGHT", -16, 16)
	info:SetTextColor(.5, .5, .5, 1)
	info:SetText(format("%s %s: %s", GetAddOnMetadata(addon, "Version"), L["author"], GetAddOnMetadata(addon, "Author")))

	-- TITLE
	local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(format(L["%s Configuration"], addon))

	-- SUBTITLE
	local subtitle = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtitle:SetHeight(30)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -8)
	subtitle:SetNonSpaceWrap(true)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetJustifyV("TOP")
	subtitle:SetText(L["ConfigPanelTitle"])

	-- LEFT PANEL
	local leftPanel = CreateFrame("FRAME", nil, self, "MJOptionsPanel")
	leftPanel:SetPoint("TOPLEFT", self, 8, -67)
	leftPanel:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", 300, 8)

	-- MODIFIER TEXT
	local modifierText = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	modifierText:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 8, -20)
	modifierText:SetText(L["Modifier"]..":")

	-- MODIFIER COMBOBOX
	local modifierCombobox = CreateFrame("FRAME", "MountsJournalModifier", self, "UIDropDownMenuTemplate")
	self.modifierCombobox = modifierCombobox
	modifierCombobox:SetPoint("TOPLEFT", modifierText, "BOTTOMRIGHT", -8, 21)

	UIDropDownMenu_Initialize(modifierCombobox, function (self, level, menuList)
		local info = UIDropDownMenu_CreateInfo()
		for i, modifier in ipairs({"ALT", "CTRL", "SHIFT"}) do
			info.checked = nil
			info.text = modifier.." key"
			info.value = modifier
			info.func = function(self)
				UIDropDownMenu_SetSelectedValue(modifierCombobox, self.value)
			end
			UIDropDownMenu_AddButton(info)
		end
	end)

	setTooltip(modifierCombobox, "ANCHOR_TOPLEFT", L["Modifier"], L["ModifierDescription"])

	-- WATER JUMP
	self.waterJump = CreateFrame("CheckButton", nil, self, "MJCheckButtonTemplate")
	self.waterJump:SetPoint("TOPLEFT", modifierText, "BOTTOMLEFT", 0, -10)
	self.waterJump.Text:SetText(L["Handle a jump in water"])
	self.waterJump.tooltipText = L["Handle a jump in water"]
	self.waterJump.tooltipRequirement = L["WaterJumpDescription"]

	-- CREATE MACRO
	local createMacroBtn = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
	createMacroBtn:SetSize(232, 40)
	createMacroBtn:SetPoint("TOPLEFT", self.waterJump, "BOTTOMLEFT", 0, -25)
	createMacroBtn:SetText(L["CreateMacro"])
	createMacroBtn:SetScript("OnClick", function()
		local macroName = "MJMacro"
		DeleteMacro(macroName)
		CreateMacro(macroName, select(3, GetSpellInfo(150544)), "/click MountsJournal_Mount")

		if not IsAddOnLoaded("Blizzard_MacroUI") then
			LoadAddOn("Blizzard_MacroUI")
		end

		if MacroFrame:IsShown() then
			MacroFrame_Update()
		else
			self:okay()
			local b_CanOpenPanels = CanOpenPanels
			CanOpenPanels = function() return 1 end
			ShowUIPanel(MacroFrame, 1)
			CanOpenPanels = b_CanOpenPanels
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
	local macroOrBind = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	macroOrBind:SetPoint("TOP", createMacroBtn, "BOTTOM", 0, -3)
	macroOrBind:SetText(L["or key bind"])

	-- BIND MOUNT
	self.bindMount:SetPoint("TOP", createMacroBtn, "BOTTOM", 0, -20)

	-- RIGHT PANEL
	local rightPanel = CreateFrame("FRAME", nil, self, "MJOptionsPanel")
	rightPanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", 4, 0)
	rightPanel:SetPoint("BOTTOMRIGHT", self, -8, 8)

	local rightPanelScroll = CreateFrame("ScrollFrame", nil, rightPanel, "UIPanelScrollFrameTemplate")
	rightPanelScroll:SetPoint("TOPLEFT", rightPanel, 4, -6)
	rightPanelScroll:SetPoint("BOTTOMRIGHT", rightPanel, -26, 5)
	rightPanelScroll.ScrollBar:SetBackdrop({bgFile='interface/buttons/white8x8'})
	rightPanelScroll.ScrollBar:SetBackdropColor(0,0,0,.2)
	rightPanelScroll.child = CreateFrame("FRAME")
	rightPanelScroll.child:SetSize(1, 1)
	rightPanelScroll:SetScrollChild(rightPanelScroll.child)

	-- WATER WALKER ALWAYS
	self.waterWalkAlways = CreateFrame("CheckButton", nil, rightPanelScroll.child, "MJCheckButtonTemplate")
	self.waterWalkAlways:SetPoint("TOPLEFT", rightPanelScroll.child, 9, -9)
	self.waterWalkAlways.Text:SetText(L["Water Walking Always"])
	self.waterWalkAlways.tooltipText = L["Water Walking"]
	self.waterWalkAlways.tooltipRequirement = L["WaterWalkingDescription"]

	-- WATER WALK INSTANCE
	self.waterWalkInstance = CreateFrame("CheckButton", nil, rightPanelScroll.child, "MJCheckButtonTemplate")
	self.waterWalkInstance:SetPoint("TOPLEFT", self.waterWalkAlways, "BOTTOMLEFT", 0, 0)
	self.waterWalkInstance.Text:SetText(L["Water Walking in dungeons"])
	self.waterWalkInstance.tooltipText = L["Water Walking"]
	self.waterWalkInstance.tooltipRequirement = L["WaterWalkingDescription"]
	self.waterWalkInstance:HookScript("OnClick", function(checkBtn)
		self:setEnableCheckButtons(checkBtn:GetChecked(), self.dungeons)
	end)

	-- WATER WALK DUNGEONS
	self.dungeons = {}
	local function createDungeonCheckbox(mapID, expansion, instanceID)
		local info = C_Map.GetMapInfo(mapID)
		if info and info.name then
			createCheckboxChild(format("%s %s", info.name, expansion), instanceID, self.dungeons, rightPanelScroll.child, self.waterWalkInstance)
		end
	end
	createDungeonCheckbox(713, "(Legion)", 1456) -- Око Азшары
	createDungeonCheckbox(974, "(BFA)", 1771) -- Тол Дагор

	-- WATER WALK IN EXPEDITIONS
	self.waterWalkExpedition = CreateFrame("CheckButton", nil, rightPanelScroll.child, "MJCheckButtonTemplate")
	self.waterWalkExpedition:SetPoint("TOPLEFT", self.dungeons[#self.dungeons], "BOTTOMLEFT", -20, 0)
	self.waterWalkExpedition.Text:SetText(L["Water Walking in expeditions"])
	self.waterWalkExpedition.tooltipText = L["Water Walking"]
	self.waterWalkExpedition.tooltipRequirement = L["WaterWalkingDescription"]
	self.waterWalkExpedition:HookScript("OnClick", function(checkBtn)
		self:setEnableCheckButtons(checkBtn:GetChecked(), self.expeditions)
	end)

	-- WATER WALK EXPEDITIONS
	local expeditions = {}
	for instanceID, mapID in pairs(mounts.expeditions) do
		local info = C_Map.GetMapInfo(mapID)
		tinsert(expeditions, {instanceID, info.name})
	end
	sort(expeditions, function(a, b) return a[2] < b[2] end)
	self.expeditions = {}
	for i = 1, #expeditions do
		createCheckboxChild(expeditions[i][2], expeditions[i][1], self.expeditions, rightPanelScroll.child, self.waterWalkExpedition)
	end

	-- USE HERBALISM MOUNTS
	self.useHerbMounts = CreateFrame("CheckButton", nil, rightPanelScroll.child, "MJCheckButtonTemplate")
	self.useHerbMounts:SetPoint("TOPLEFT", self.expeditions[#self.expeditions], "BOTTOMLEFT", -20, -26)
	self.useHerbMounts.Text:SetText(L["UseHerbMounts"])
	self.useHerbMounts.tooltipText = L["UseHerbMounts"]
	self.useHerbMounts.tooltipRequirement = L["UseHerbMountsDescription"]

	-- USE MAGIC BROOM
	self.useMagicBroom = CreateFrame("CheckButton", nil, rightPanelScroll.child, "MJCheckButtonTemplate")
	self.useMagicBroom:SetPoint("TOPLEFT", self.useHerbMounts, "BOTTOMLEFT", 0, -26)
	local magicBroom = Item:CreateFromItemID(37011)
	magicBroom:ContinueOnItemLoad(function()
		self.useMagicBroom.Text:SetText(format(L["UseMagicBroom"], magicBroom:GetItemLink()))
	end)
	self:setHyperlinkTooltip(self.useMagicBroom)
	self.useMagicBroom.tooltipText = L["UseMagicBroomTitle"]
	self.useMagicBroom.tooltipRequirement = L["UseMagicBroomDescription"]

	-- REFRESH
	local function refresh(self)
		if not self:IsVisible() then return end
		UIDropDownMenu_SetSelectedValue(modifierCombobox, mounts.config.modifier)
		UIDropDownMenu_SetText(modifierCombobox, mounts.config.modifier.." key")
		self.waterJump:SetChecked(mounts.config.waterJump)
		binding:setButtonText(self.bindMount)
		self.waterWalkAlways:SetChecked(mounts.config.waterWalkAll)
		self.waterWalkInstance:SetChecked(mounts.config.waterWalkInstance)
		self:setEnableCheckButtons(mounts.config.waterWalkInstance, self.dungeons)
		for _,dungeon in ipairs(self.dungeons) do
			dungeon:SetChecked(mounts.config.waterWalkList[dungeon.id])
		end
		self.waterWalkExpedition:SetChecked(mounts.config.waterWalkExpedition)
		self:setEnableCheckButtons(mounts.config.waterWalkExpedition, self.expeditions)
		for _,expedition in ipairs(self.expeditions) do
			expedition:SetChecked(mounts.config.waterWalkExpeditionList[expedition.id])
		end
		self.useHerbMounts:SetChecked(mounts.config.useHerbMounts)
		self.useMagicBroom:SetChecked(mounts.config.useMagicBroom)
	end

	self:SetScript("OnShow", refresh)
	refresh(self)
end)


function config:setEnableCheckButtons(enable, tbl)
	for _,check in ipairs(tbl) do
		check:SetEnabled(enable)
	end
end


do
	local function showTooltip(_,_,hyperLink)
		GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(hyperLink)
		GameTooltip:Show()
	end

	local function hideTooltip(self)
		GameTooltip:Hide()
	end

	function config:setHyperlinkTooltip(frame)
		frame:SetHyperlinksEnabled(true)
		frame:SetScript("OnHyperlinkEnter", showTooltip)
		frame:SetScript("OnHyperlinkLeave", hideTooltip)
	end
end


config.okay = function(self)
	mounts:setModifier(self.modifierCombobox.selectedValue)
	binding:saveBinding()
	mounts:setHandleWaterJump(self.waterJump:GetChecked())
	mounts.config.waterWalkAll = self.waterWalkAlways:GetChecked()
	mounts.config.waterWalkInstance = self.waterWalkInstance:GetChecked()
	wipe(mounts.config.waterWalkList)
	for _,dungeon in ipairs(self.dungeons) do
		mounts.config.waterWalkList[dungeon.id] = dungeon:GetChecked()
	end
	mounts.config.waterWalkExpedition = self.waterWalkExpedition:GetChecked()
	wipe(mounts.config.waterWalkExpeditionList)
	for _,expedition in ipairs(self.expeditions) do
		mounts.config.waterWalkExpeditionList[expedition.id] = expedition:GetChecked()
	end
	mounts.config.useHerbMounts = self.useHerbMounts:GetChecked()
	mounts.config.useMagicBroom = self.useMagicBroom:GetChecked()
end


config.cancel = function()
	binding:resetBinding()
end


-- ADD CATEGORY
InterfaceOptions_AddCategory(config)


-- OPEN CONFIG
function config:openConfig()
	if InterfaceOptionsFrameAddOns:IsVisible() and self:IsVisible() then
		InterfaceOptionsFrame:Hide()
		self:cancel()
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