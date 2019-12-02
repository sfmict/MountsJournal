local addon, L = ...
local util, mounts, binding = MountsJournalUtil, MountsJournal, _G[addon.."Binding"]
local config = CreateFrame("FRAME", "MountsJournalConfig", InterfaceOptionsFramePanelContainer)
config.name = addon
local secureButtonName = "MountsJournal_Mount"


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
				EditMacro("MJMacro", "MJMacro", texture, "/click "..secureButtonName)
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
		self.bindMount = binding:createButtonBinding(self, secureButtonName, "MJSecureActionButtonTemplate")
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
	local function createCheckboxChild(text, parent)
		if not parent.childs then
			parent.childs = {}
			parent:HookScript("OnClick", function(self)
				for _, child in ipairs(self.childs) do
					child:SetEnabled(self:GetChecked())
				end
			end)
		end

		local check = CreateFrame("CheckButton", nil, parent:GetParent(), "MJCheckButtonTemplate")
		if #parent.childs == 0 then
			check:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 20, 0)
		else
			check:SetPoint("TOPLEFT", parent.childs[#parent.childs], "BOTTOMLEFT", 0, 0)
		end
		check.Text:SetText(text)
		tinsert(parent.childs, check)
		return check
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

	UIDropDownMenu_Initialize(modifierCombobox, function(self, level, menuList)
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
		CreateMacro(macroName, select(3, GetSpellInfo(150544)), "/click "..secureButtonName)

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

	-- USE HERBALISM MOUNTS
	self.useHerbMounts = CreateFrame("CheckButton", nil, rightPanelScroll.child, "MJCheckButtonTemplate")
	self.useHerbMounts:SetPoint("TOPLEFT", rightPanelScroll.child, 9, -9)
	self.useHerbMounts.Text:SetText(L["UseHerbMounts"])
	self.useHerbMounts.tooltipText = L["UseHerbMounts"]
	self.useHerbMounts.tooltipRequirement = L["UseHerbMountsDescription"]

	-- USE HERBALISM MOUNTS ON HERBALISM ZONES
	self.herbMountsOnZones = createCheckboxChild(L["UseHerbMountsOnZones"], self.useHerbMounts)
	self.herbMountsOnZones.tooltipText = L["UseHerbMountsOnZones"]
	self.herbMountsOnZones.tooltipRequirement = L["UseHerbMountsDescription"]
	self.herbMountsOnZones.checkFunc = function() return mounts.config.herbMountsOnZones end

	-- USE MAGIC BROOM
	self.useMagicBroom = CreateFrame("CheckButton", nil, rightPanelScroll.child, "MJCheckButtonTemplate")
	self.useMagicBroom:SetPoint("TOPLEFT", self.herbMountsOnZones, "BOTTOMLEFT", -20, -26)
	local magicBroom = Item:CreateFromItemID(37011)
	magicBroom:ContinueOnItemLoad(function()
		self.useMagicBroom.Text:SetText(format(L["UseMagicBroom"], magicBroom:GetItemLink()))
	end)
	util.setHyperlinkTooltip(self.useMagicBroom)
	self.useMagicBroom.tooltipText = L["UseMagicBroomTitle"]
	self.useMagicBroom.tooltipRequirement = L["UseMagicBroomDescription"]

	-- NO PET IN RAID
	self.noPetInRaid = CreateFrame("CheckButton", nil, rightPanelScroll.child, "MJCheckButtonTemplate")
	self.noPetInRaid:SetPoint("TOPLEFT", self.useMagicBroom, "BOTTOMLEFT", 0, -26)
	self.noPetInRaid.Text:SetSize(245, 25)
	self.noPetInRaid.Text:SetText(L["NoPetInRaid"])

	-- NO PET IN GROUP
	self.noPetInGroup = CreateFrame("CheckButton", nil, rightPanelScroll.child, "MJCheckButtonTemplate")
	self.noPetInGroup:SetPoint("TOPLEFT", self.noPetInRaid, "BOTTOMLEFT", 0, -3)
	self.noPetInGroup.Text:SetSize(245, 25)
	self.noPetInGroup.Text:SetText(L["NoPetInGroup"])


	-- REFRESH
	local function refresh(self)
		if not self:IsVisible() then return end
		UIDropDownMenu_SetSelectedValue(modifierCombobox, mounts.config.modifier)
		UIDropDownMenu_SetText(modifierCombobox, mounts.config.modifier.." key")
		self.waterJump:SetChecked(mounts.config.waterJump)
		binding:setButtonText(self.bindMount)
		self.useHerbMounts:SetChecked(mounts.config.useHerbMounts)
		for _, child in ipairs(self.useHerbMounts.childs) do
			child:SetEnabled(mounts.config.useHerbMounts)
			child:SetChecked(child:checkFunc())
		end
		self.useMagicBroom:SetChecked(mounts.config.useMagicBroom)
		self.noPetInRaid:SetChecked(mounts.config.noPetInRaid)
		self.noPetInGroup:SetChecked(mounts.config.noPetInGroup)
	end

	self:SetScript("OnShow", refresh)
	refresh(self)
end)


function config:setEnableCheckButtons(enable, tbl)
	for _, check in ipairs(tbl) do
		check:SetEnabled(enable)
	end
end


config.okay = function(self)
	mounts:setModifier(self.modifierCombobox.selectedValue)
	binding:saveBinding()
	mounts:setHandleWaterJump(self.waterJump:GetChecked())
	mounts.config.useHerbMounts = self.useHerbMounts:GetChecked()
	mounts.config.herbMountsOnZones = self.herbMountsOnZones:GetChecked()
	mounts:setHerbMount()
	mounts.config.useMagicBroom = self.useMagicBroom:GetChecked()
	mounts.config.noPetInRaid = self.noPetInRaid:GetChecked()
	mounts.config.noPetInGroup = self.noPetInGroup:GetChecked()
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