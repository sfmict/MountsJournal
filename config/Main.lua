local addon, L = ...
local util, mounts, binding = MountsJournalUtil, MountsJournal, _G[addon.."Binding"]
local config = CreateFrame("FRAME", "MountsJournalConfig", InterfaceOptionsFramePanelContainer)
config:Hide()
config.name = addon
config.macroName = "MJMacro"
config.secondMacroName = "MJSecondMacro"
config.secureButtonNameMount = addon.."_Mount"
config.secureButtonNameSecondMount = addon.."_SecondMount"


config:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
config:RegisterEvent("PLAYER_LOGIN")


-- BIND MOUNT
function config:PLAYER_LOGIN()
	self.bindMount = binding:createButtonBinding(nil, self.secureButtonNameMount, ("%s %s %d"):format(addon, SUMMONS, 1), "MJSecureActionButtonTemplate")
	self.bindSecondMount = binding:createButtonBinding(nil, self.secureButtonNameSecondMount, ("%s %s %d"):format(addon, SUMMONS, 2), "MJSecureActionButtonTemplate")
	self.bindSecondMount.secure.forceModifier = true
end


-- SHOW CONFIG
config:SetScript("OnShow", function(self)
	StaticPopupDialogs[util.addonName.."MACRO_EXISTS"] = {
		text = addon..": "..L["A macro named \"%s\" already exists, overwrite it?"],
		button1 = ACCEPT,
		button2 = CANCEL,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = function(popup, cb) popup:Hide() cb() end,
	}

	-- ENABLE APPLY
	local function applyEnable() self.applyBtn:Enable() end

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

	-- VERSION
	local ver = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	ver:SetPoint("TOPRIGHT", -16, 16)
	ver:SetTextColor(.5, .5, .5, 1)
	ver:SetJustifyH("RIGHT")
	ver:SetText(GetAddOnMetadata(addon, "Version"))

	-- TITLE
	local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetJustifyH("LEFT")
	title:SetText(L["%s Configuration"]:format(addon))

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
	leftPanel:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", 300, 32)

	-- WATER JUMP
	self.waterJump = CreateFrame("CheckButton", nil, leftPanel, "MJCheckButtonTemplate")
	self.waterJump:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 8, -20)
	self.waterJump.Text:SetText(L["Handle a jump in water"])
	self.waterJump.tooltipText = L["Handle a jump in water"]
	self.waterJump.tooltipRequirement = L["WaterJumpDescription"]
	self.waterJump:HookScript("OnClick", applyEnable)

	-- SUMMON 1
	local summon1 = leftPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	summon1:SetPoint("TOPLEFT", self.waterJump, "BOTTOMLEFT", 0, -20)
	summon1:SetText(SUMMONS.." 1")

	-- CREATE MACRO
	local createMacroBtn = CreateFrame("BUTTON", nil, leftPanel, "UIPanelButtonTemplate")
	createMacroBtn:SetSize(258, 30)
	createMacroBtn:SetPoint("TOPLEFT", summon1, "BOTTOMLEFT", 0, -5)
	createMacroBtn:SetText(L["CreateMacro"])
	createMacroBtn:SetScript("OnClick", function() self:createMacro(self.macroName, self.secureButtonNameMount, 413588, true) end)

	setTooltip(createMacroBtn, "ANCHOR_TOP", L["CreateMacro"], L["CreateMacroTooltip"])

	-- OR TEXT
	local macroOrBind = leftPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	macroOrBind:SetPoint("TOP", createMacroBtn, "BOTTOM", 0, -3)
	macroOrBind:SetText(L["or key bind"])

	-- BIND MOUNT
	self.bindMount:SetParent(leftPanel)
	self.bindMount:SetSize(258, 22)
	self.bindMount:SetPoint("TOPLEFT", createMacroBtn, "BOTTOMLEFT", 0, -20)

	-- HELP PLATE
	local helpPlate = CreateFrame("FRAME", nil, leftPanel, "MJHelpPlate")
	helpPlate:SetPoint("TOP", self.bindMount, "BOTTOM", 0, -20)
	helpPlate.tooltip = L["SecondMountTooltipTitle"]:format(SUMMONS)
	helpPlate.tooltipDescription = L["SecondMountTooltipDescription"]

	-- MODIFIER TEXT
	local modifierText = leftPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	modifierText:SetPoint("TOPLEFT", self.bindMount, "BOTTOMLEFT", 0, -80)
	modifierText:SetText(L["Modifier"]..":")

	-- MODIFIER COMBOBOX
	local modifierCombobox = CreateFrame("FRAME", "MountsJournalModifier", leftPanel, "MJDropDownButtonTemplate")
	self.modifierCombobox = modifierCombobox
	modifierCombobox:SetPoint("LEFT", modifierText, "RIGHT", 7, 0)
	modifierCombobox:ddSetInit(function(self, level)
		local info = {}
		for i, modifier in ipairs({"ALT", "CTRL", "SHIFT", "NONE"}) do
			info.text = _G[modifier.."_KEY"]
			info.value = modifier
			info.checked = function(btn) return modifierCombobox.selectedValue == btn.value end
			info.func = function(btn)
				self:ddSetSelectedValue(btn.value)
				config.applyBtn:Enable()
			end
			self:ddAddButton(info, level)
		end
	end)

	-- SUMMON 2
	local summon2 = leftPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	summon2:SetPoint("TOPLEFT", modifierText, "BOTTOMLEFT", 0, -20)
	summon2:SetText(SUMMONS.." 2")

	-- CREATE SECOND MACRO
	local createSecondMacroBtn = CreateFrame("BUTTON", nil, leftPanel, "UIPanelButtonTemplate")
	createSecondMacroBtn:SetSize(258, 30)
	createSecondMacroBtn:SetPoint("TOPLEFT", summon2, "BOTTOMLEFT", 0, -5)
	createSecondMacroBtn:SetText(L["CreateMacro"])
	createSecondMacroBtn:SetScript("OnClick", function() self:createMacro(self.secondMacroName, self.secureButtonNameSecondMount, 631718, true) end)

	setTooltip(createSecondMacroBtn, "ANCHOR_TOP", L["CreateMacro"], L["CreateMacroTooltip"])

	-- OR TEXT SECOND
	local macroOrBindSecond = leftPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	macroOrBindSecond:SetPoint("TOP", createSecondMacroBtn, "BOTTOM", 0, -3)
	macroOrBindSecond:SetText(L["or key bind"])

	-- BIND SECOND MOUNT
	self.bindSecondMount:SetParent(leftPanel)
	self.bindSecondMount:SetSize(258, 22)
	self.bindSecondMount:SetPoint("TOP", createSecondMacroBtn, "BOTTOM", 0, -20)

	-- UNBOUND MESSAGE
	binding.unboundMessage:SetParent(self)
	binding.unboundMessage:SetSize(500, 10)
	binding.unboundMessage:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 14, 14)

	-- RIGHT PANEL
	local rightPanel = CreateFrame("FRAME", nil, self, "MJOptionsPanel")
	rightPanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", 4, 0)
	rightPanel:SetPoint("BOTTOMRIGHT", self, -8, 32)

	local rightPanelScroll = CreateFrame("ScrollFrame", nil, rightPanel, "MJPanelScrollFrameTemplate")
	rightPanelScroll:SetPoint("TOPLEFT", rightPanel, 4, -6)
	rightPanelScroll:SetPoint("BOTTOMRIGHT", rightPanel, -26, 5)

	-- USE HERBALISM MOUNTS
	self.useHerbMounts = CreateFrame("CheckButton", nil, rightPanelScroll.child, "MJCheckButtonTemplate")
	self.useHerbMounts:SetPoint("TOPLEFT", rightPanelScroll.child, 9, -9)
	self.useHerbMounts.Text:SetText(L["UseHerbMounts"])
	self.useHerbMounts.tooltipText = L["UseHerbMounts"]
	self.useHerbMounts.tooltipRequirement = L["UseHerbMountsDescription"]
	self.useHerbMounts:HookScript("OnClick", applyEnable)

	-- USE HERBALISM MOUNTS ON HERBALISM ZONES
	self.herbMountsOnZones = util.createCheckboxChild(L["UseHerbMountsOnZones"], self.useHerbMounts)
	self.herbMountsOnZones.tooltipText = L["UseHerbMountsOnZones"]
	self.herbMountsOnZones.tooltipRequirement = L["UseHerbMountsDescription"]
	self.herbMountsOnZones.checkFunc = function() return mounts.config.herbMountsOnZones end
	self.herbMountsOnZones:HookScript("OnClick", applyEnable)

	-- USE REPAIR MOUNTS
	self.useRepairMounts = CreateFrame("CheckButton", nil, rightPanelScroll.child, "MJCheckButtonTemplate")
	self.useRepairMounts:SetPoint("TOPLEFT", self.herbMountsOnZones, "BOTTOMLEFT", -20, -15)
	self.useRepairMounts.Text:SetText(L["If item durability is less than"])
	self.useRepairMounts.tooltipText = L["If item durability is less than"]
	self.useRepairMounts.tooltipRequirement = L["UseRepairMountsDescription"]
	self.useRepairMounts.setEnabledFunc = function(btn)
		local checked = btn:GetChecked()
		self.repairPecent:SetEnabled(checked)
		self.repairMountsCombobox:SetEnabled(checked)
	end
	hooksecurefunc(self.useRepairMounts, "SetChecked", self.useRepairMounts.setEnabledFunc)
	self.useRepairMounts:HookScript("OnClick", function(btn)
		btn:setEnabledFunc()
		applyEnable()
	end)

	self.repairPecent = CreateFrame("Editbox", nil, rightPanelScroll.child, "MJNumberTextBox")
	self.repairPecent:SetPoint("LEFT", self.useRepairMounts.Text, "RIGHT", 3, 0)
	self.repairPecent:SetScript("OnTextChanged", function(editBox, userInput)
		if userInput then
			local value = tonumber(editBox:GetText()) or 0
			if value < 0 then
				editBox:SetNumber(0)
			elseif value > 100 then
				editBox:SetNumber(100)
			end
			applyEnable()
		end
	end)
	self.repairPecent:SetScript("OnMouseWheel", function(editBox, delta)
		if editBox:IsEnabled() then
			local value = (tonumber(editBox:GetText()) or 0) + (delta > 0 and 1 or -1)
			if value >= 0 and value <= 100 then
				editBox:SetNumber(value)
			end
			applyEnable()
		end
	end)

	self.repairPecentText = self.repairPecent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	self.repairPecentText:SetPoint("LEFT", self.repairPecent, "RIGHT", 3, 0)
	self.repairPecentText:SetText("%")

	-- USE REPAIR MOUNTS IN FLYABLE ZONES
	self.repairFlyable = util.createCheckboxChild(L["In flyable zones"], self.useRepairMounts)
	self.repairFlyable.tooltipText = L["In flyable zones"]
	self.repairFlyable.tooltipRequirement = L["UseRepairMountsDescription"]
	self.repairFlyable.checkFunc = function() return mounts.config.useRepairFlyable end
	self.repairFlyable.setEnabledFunc = function(btn)
		self.repairFlyablePercent:SetEnabled(btn:IsEnabled() and btn:GetChecked())
		self.repairFlyablePercentText:SetTextColor(btn.Text:GetTextColor())
	end
	hooksecurefunc(self.repairFlyable, "SetChecked", self.repairFlyable.setEnabledFunc)
	self.repairFlyable:HookScript("OnClick", function(btn)
		btn:setEnabledFunc()
		applyEnable()
	end)
	self.repairFlyable:HookScript("OnEnable", self.repairFlyable.setEnabledFunc)
	self.repairFlyable:HookScript("OnDisable", self.repairFlyable.setEnabledFunc)

	self.repairFlyablePercent = CreateFrame("Editbox", nil, rightPanelScroll.child, "MJNumberTextBox")
	self.repairFlyablePercent:SetPoint("LEFT", self.repairFlyable.Text, "RIGHT", 3, 0)
	self.repairFlyablePercent:SetScript("OnTextChanged", function(editBox, userInput)
		if userInput then
			local value = tonumber(editBox:GetText()) or 0
			if value < 0 then
				editBox:SetNumber(0)
			elseif value > 100 then
				editBox:SetNumber(100)
			end
			applyEnable()
		end
	end)
	self.repairFlyablePercent:SetScript("OnMouseWheel", function(editBox, delta)
		if editBox:IsEnabled() then
			local value = (tonumber(editBox:GetText()) or 0) + (delta > 0 and 1 or -1)
			if value >= 0 and value <= 100 then
				editBox:SetNumber(value)
			end
			applyEnable()
		end
	end)

	self.repairFlyablePercentText = self.repairPecent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	self.repairFlyablePercentText:SetPoint("LEFT", self.repairFlyablePercent, "RIGHT", 3, 0)
	self.repairFlyablePercentText:SetText("%")

	-- REPAIR MOUNTS COMBOBOX
	self.repairMountsCombobox = CreateFrame("FRAME", "MountsJournalRepairCombobox", rightPanelScroll.child, "MJDropDownButtonTemplate")
	self.repairMountsCombobox:SetWidth(230)
	self.repairMountsCombobox:SetPoint("TOPLEFT", self.repairFlyable, "BOTTOMLEFT", 0, -8)
	self.repairMountsCombobox:ddSetInit(function(self, level)
		local info = {}

		info.text = L["Random available mount"]
		info.value = nil
		info.checked = function(btn) return self.selectedValue == btn.value end
		info.func = function(btn)
			self:ddSetSelectedValue(btn.value)
			config.applyBtn:Enable()
		end
		self:ddAddButton(info, level)

		for i, mountID in ipairs(mounts.repairMounts) do
			local name, _, icon, _,_,_,_,_,_, shouldHideOnChar, isCollected = C_MountJournal.GetMountInfoByID(mountID)
			if not shouldHideOnChar then
				info.text = name
				info.icon = icon
				info.value = mountID
				info.disabled = not isCollected
				info.checked = function(btn) return self.selectedValue == btn.value end
				info.func = function(btn)
					self:ddSetSelectedValue(btn.value)
					config.applyBtn:Enable()
				end
				self:ddAddButton(info, level)
			end
		end
	end)

	-- USE MAGIC BROOM
	self.useMagicBroom = CreateFrame("CheckButton", nil, rightPanelScroll.child, "MJCheckButtonTemplate")
	self.useMagicBroom:SetPoint("TOPLEFT", self.repairMountsCombobox, "BOTTOMLEFT", -20, -20)
	local magicBroom = Item:CreateFromItemID(37011)
	if magicBroom:IsItemDataCached() then
		self.useMagicBroom.Text:SetText(L["UseMagicBroom"]:format(magicBroom:GetItemLink()))
	else
		magicBroom:ContinueOnItemLoad(function()
			self.useMagicBroom.Text:SetText(L["UseMagicBroom"]:format(magicBroom:GetItemLink()))
		end)
	end
	util.setHyperlinkTooltip(self.useMagicBroom)
	self.useMagicBroom.tooltipText = L["UseMagicBroomTitle"]
	self.useMagicBroom.tooltipRequirement = L["UseMagicBroomDescription"]
	self.useMagicBroom:HookScript("OnClick", applyEnable)

	-- NO PET IN RAID
	self.noPetInRaid = CreateFrame("CheckButton", nil, rightPanelScroll.child, "MJCheckButtonTemplate")
	self.noPetInRaid:SetPoint("TOPLEFT", self.useMagicBroom, "BOTTOMLEFT", 0, -15)
	self.noPetInRaid.Text:SetSize(245, 25)
	self.noPetInRaid.Text:SetText(L["NoPetInRaid"])
	self.noPetInRaid:HookScript("OnClick", applyEnable)

	-- NO PET IN GROUP
	self.noPetInGroup = CreateFrame("CheckButton", nil, rightPanelScroll.child, "MJCheckButtonTemplate")
	self.noPetInGroup:SetPoint("TOPLEFT", self.noPetInRaid, "BOTTOMLEFT", 0, -3)
	self.noPetInGroup.Text:SetSize(245, 25)
	self.noPetInGroup.Text:SetText(L["NoPetInGroup"])
	self.noPetInGroup:HookScript("OnClick", applyEnable)

	-- COPY MOUNT TARGET
	self.copyMountTarget = CreateFrame("CheckButton", nil, rightPanelScroll.child, "MJCheckButtonTemplate")
	self.copyMountTarget:SetPoint("TOPLEFT", self.noPetInGroup, "BOTTOMLEFT", 0, -15)
	self.copyMountTarget.Text:SetSize(245, 25)
	self.copyMountTarget.Text:SetText(L["CopyMountTarget"])
	self.copyMountTarget:HookScript("OnClick", applyEnable)

	-- ARROW BUTTONS
	self.arrowButtons = CreateFrame("CheckButton", nil, rightPanelScroll.child, "MJCheckButtonTemplate")
	self.arrowButtons:SetPoint("TOPLEFT", self.copyMountTarget, "BOTTOMLEFT", 0, -15)
	self.arrowButtons.Text:SetSize(245, 25)
	self.arrowButtons.Text:SetText(L["Enable arrow buttons to browse mounts"])
	self.arrowButtons:HookScript("OnClick", applyEnable)

	-- RESET HELP
	local resetHelp = CreateFrame("BUTTON", nil, rightPanelScroll.child, "UIPanelButtonTemplate")
	resetHelp:SetSize(128, 22)
	resetHelp:SetPoint("TOPLEFT", self.arrowButtons, "BOTTOMLEFT", 0, -15)
	resetHelp:SetText(RESET_TUTORIALS)
	resetHelp:SetScript("OnClick", function(btn)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		mounts.help.journal = 0
		util.showHelpJournal()
		btn:Disable()
	end)

	-- APPLY
	self.applyBtn = CreateFrame("BUTTON", nil, self, "UIPanelButtonTemplate")
	self.applyBtn:SetSize(96, 22)
	self.applyBtn:Disable()
	self.applyBtn:SetPoint("BOTTOMRIGHT", -8, 8)
	self.applyBtn:SetText(APPLY)
	self.applyBtn:SetScript("OnClick", function(btn)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self:okay()
		btn:Disable()
	end)

	-- UPDATE BINDING BUTTONS
	binding:on("SET_BINDING", function(_, btn)
		if self.bindMount ~= btn then binding:setButtonText(self.bindMount) end
		if self.bindSecondMount ~= btn then binding:setButtonText(self.bindSecondMount) end
		self.applyBtn:Enable()
	end)

	-- REFRESH
	self:SetScript("OnShow", function(self)
		binding.unboundMessage:Hide()
		modifierCombobox:ddSetSelectedValue(mounts.config.modifier)
		modifierCombobox:ddSetSelectedText(_G[mounts.config.modifier.."_KEY"])
		self.waterJump:SetChecked(mounts.config.waterJump)
		self.useHerbMounts:SetChecked(mounts.config.useHerbMounts)
		for _, child in ipairs(self.useHerbMounts.childs) do
			child:SetChecked(child:checkFunc())
		end
		self.useRepairMounts:SetChecked(mounts.config.useRepairMounts)
		for _, child in ipairs(self.useRepairMounts.childs) do
			child:SetChecked(child:checkFunc())
		end
		self.repairPecent:SetNumber(tonumber(mounts.config.useRepairMountsDurability) or 0)
		self.repairFlyablePercent:SetNumber(tonumber(mounts.config.useRepairFlyableDurability) or 0)
		self.repairMountsCombobox:ddSetSelectedValue(mounts.config.repairSelectedMount)
		self.repairMountsCombobox:ddSetSelectedText(not mounts.config.repairSelectedMount and L["Random available mount"] or C_MountJournal.GetMountInfoByID(mounts.config.repairSelectedMount))
		self.useMagicBroom:SetChecked(mounts.config.useMagicBroom)
		self.noPetInRaid:SetChecked(mounts.config.noPetInRaid)
		self.noPetInGroup:SetChecked(mounts.config.noPetInGroup)
		self.copyMountTarget:SetChecked(mounts.config.copyMountTarget)
		self.arrowButtons:SetChecked(mounts.config.arrowButtonsBrowse)
		resetHelp:Enable()
		self.applyBtn:Disable()
	end)
	self:GetScript("OnShow")(self)
end)


function config:createMacro(macroName, buttonName, texture, openMacroFrame, overwrite)
	if InCombatLockdown() then return end
	local _, ctexture = GetMacroInfo(macroName)
	if ctexture and not overwrite then
		StaticPopup_Show(util.addonName.."MACRO_EXISTS", macroName, nil, function()
			self:createMacro(macroName, buttonName, ctexture, openMacroFrame, true)
		end)
		return
	end

	if overwrite then
		EditMacro(macroName, macroName, texture, "/click "..buttonName)
	else
		CreateMacro(macroName, texture, "/click "..buttonName)
	end

	if MacroFrame and MacroFrame:IsShown() then
		MacroFrame_Update()
	end

	if not openMacroFrame then return end

	if not IsAddOnLoaded("Blizzard_MacroUI") then
		LoadAddOn("Blizzard_MacroUI")
	end

	if not MacroFrame:IsShown() then
		InterfaceOptionsFrame:SetAttribute("UIPanelLayout-allowOtherPanels", 1)
		ShowUIPanel(MacroFrame)
		InterfaceOptionsFrame:SetAttribute("UIPanelLayout-allowOtherPanels", nil)
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
end


config.okay = function(self)
	binding.unboundMessage:Hide()
	mounts:setModifier(self.modifierCombobox.selectedValue)
	binding:saveBinding()
	mounts:setHandleWaterJump(self.waterJump:GetChecked())
	mounts.config.useHerbMounts = self.useHerbMounts:GetChecked()
	mounts.config.herbMountsOnZones = self.herbMountsOnZones:GetChecked()
	mounts:setHerbMount()
	mounts.config.useRepairMounts = self.useRepairMounts:GetChecked()
	mounts.config.useRepairMountsDurability = tonumber(self.repairPecent:GetText()) or 0
	mounts.config.useRepairFlyable = self.repairFlyable:GetChecked()
	mounts.config.useRepairFlyableDurability = tonumber(self.repairFlyablePercent:GetText()) or 0
	mounts:UPDATE_INVENTORY_DURABILITY()
	mounts.config.repairSelectedMount = self.repairMountsCombobox.selectedValue
	mounts:setUsableRepairMounts()
	mounts.config.useMagicBroom = self.useMagicBroom:GetChecked()
	mounts.config.noPetInRaid = self.noPetInRaid:GetChecked()
	mounts.config.noPetInGroup = self.noPetInGroup:GetChecked()
	mounts.config.copyMountTarget = self.copyMountTarget:GetChecked()
	mounts.config.arrowButtonsBrowse = self.arrowButtons:GetChecked()
	MountsJournalFrame:setArrowSelectMount(mounts.config.arrowButtonsBrowse)
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
SlashCmdList["MOUNTSCONFIG"] = function() config:openConfig() end