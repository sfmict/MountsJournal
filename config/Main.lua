local addon, L = ...
local util, mounts, binding = MountsJournalUtil, MountsJournal, _G[addon.."Binding"]
local config = CreateFrame("FRAME", "MountsJournalConfig", InterfaceOptionsFramePanelContainer)
config.name = addon
local macroName, secondMacroName = "MJMacro", "MJSecondMacro"
local secureButtonNameMount = addon.."_Mount"
local secureButtonNameSecondMount = addon.."_SecondMount"


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
			-- MACRO
			local texture = select(2, GetMacroInfo(macroName))
			if texture then
				EditMacro(macroName, macroName, texture, "/click "..secureButtonNameMount)
			end
			-- SECOND MACRO
			texture = select(2, GetMacroInfo(secondMacroName))
			if texture then
				EditMacro(secondMacroName, secondMacroName, texture, "/click "..secureButtonNameSecondMount)
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
		self.bindMount = binding:createButtonBinding(nil, secureButtonNameMount, "MJSecureActionButtonTemplate")
		self.bindSecondMount = binding:createButtonBinding(nil, secureButtonNameSecondMount, "MJSecureActionButtonTemplate")
		self.bindSecondMount.secure.forceModifier = true
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
			check:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 20, -3)
		else
			check:SetPoint("TOPLEFT", parent.childs[#parent.childs], "BOTTOMLEFT", 0, -3)
		end
		check.Text:SetText(text)
		tinsert(parent.childs, check)
		return check
	end

	-- ADDON INFO
	local info = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	info:SetPoint("TOPRIGHT", -16, 16)
	info:SetTextColor(.5, .5, .5, 1)
	info:SetJustifyH("RIGHT")
	info:SetText(("%s %s: %s"):format(GetAddOnMetadata(addon, "Version"), L["author"], GetAddOnMetadata(addon, "Author")))

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
	self.waterJump:HookScript("OnClick", function() self.applyBtn:Enable() end)

	-- SUMMON 1
	local summon1 = leftPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	summon1:SetPoint("TOPLEFT", self.waterJump, "BOTTOMLEFT", 0, -20)
	summon1:SetText(SUMMONS.." 1")

	-- CREATE MACRO
	local createMacroBtn = CreateFrame("BUTTON", nil, leftPanel, "UIPanelButtonTemplate")
	createMacroBtn:SetSize(258, 30)
	createMacroBtn:SetPoint("TOPLEFT", summon1, "BOTTOMLEFT", 0, -5)
	createMacroBtn:SetText(L["CreateMacro"])
	createMacroBtn:SetScript("OnClick", function() self:createMacro(macroName, secureButtonNameMount, 413588) end)

	setTooltip(createMacroBtn, "ANCHOR_TOP", L["CreateMacro"], L["CreateMacroTooltip"])

	-- OR TEXT
	local macroOrBind = leftPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	macroOrBind:SetPoint("TOP", createMacroBtn, "BOTTOM", 0, -3)
	macroOrBind:SetText(L["or key bind"])

	-- BIND MOUNT
	self.bindMount:SetParent(leftPanel)
	self.bindMount:SetSize(258, 22)
	self.bindMount:SetPoint("TOPLEFT", createMacroBtn, "BOTTOMLEFT", 0, -20)
	self.bindMount:on("SET_BINDING", function()
		binding:setButtonText(self.bindSecondMount)
		self.applyBtn:Enable()
	end)

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
	createSecondMacroBtn:SetScript("OnClick", function() self:createMacro(secondMacroName, secureButtonNameSecondMount, 631718) end)

	setTooltip(createSecondMacroBtn, "ANCHOR_TOP", L["CreateMacro"], L["CreateMacroTooltip"])

	-- OR TEXT SECOND
	local macroOrBindSecond = leftPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	macroOrBindSecond:SetPoint("TOP", createSecondMacroBtn, "BOTTOM", 0, -3)
	macroOrBindSecond:SetText(L["or key bind"])

	-- BIND SECOND MOUNT
	self.bindSecondMount:SetParent(leftPanel)
	self.bindSecondMount:SetSize(258, 22)
	self.bindSecondMount:SetPoint("TOP", createSecondMacroBtn, "BOTTOM", 0, -20)
	self.bindSecondMount:on("SET_BINDING", function()
		binding:setButtonText(self.bindMount)
		self.applyBtn:Enable()
	end)

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
	self.useHerbMounts:HookScript("OnClick", function() self.applyBtn:Enable() end)

	-- USE HERBALISM MOUNTS ON HERBALISM ZONES
	self.herbMountsOnZones = createCheckboxChild(L["UseHerbMountsOnZones"], self.useHerbMounts)
	self.herbMountsOnZones.tooltipText = L["UseHerbMountsOnZones"]
	self.herbMountsOnZones.tooltipRequirement = L["UseHerbMountsDescription"]
	self.herbMountsOnZones.checkFunc = function() return mounts.config.herbMountsOnZones end
	self.herbMountsOnZones:HookScript("OnClick", function() self.applyBtn:Enable() end)

	-- USE MAGIC BROOM
	self.useMagicBroom = CreateFrame("CheckButton", nil, rightPanelScroll.child, "MJCheckButtonTemplate")
	self.useMagicBroom:SetPoint("TOPLEFT", self.herbMountsOnZones, "BOTTOMLEFT", -20, -26)
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
	self.useMagicBroom:HookScript("OnClick", function() self.applyBtn:Enable() end)

	-- NO PET IN RAID
	self.noPetInRaid = CreateFrame("CheckButton", nil, rightPanelScroll.child, "MJCheckButtonTemplate")
	self.noPetInRaid:SetPoint("TOPLEFT", self.useMagicBroom, "BOTTOMLEFT", 0, -26)
	self.noPetInRaid.Text:SetSize(245, 25)
	self.noPetInRaid.Text:SetText(L["NoPetInRaid"])
	self.noPetInRaid:HookScript("OnClick", function() self.applyBtn:Enable() end)

	-- NO PET IN GROUP
	self.noPetInGroup = CreateFrame("CheckButton", nil, rightPanelScroll.child, "MJCheckButtonTemplate")
	self.noPetInGroup:SetPoint("TOPLEFT", self.noPetInRaid, "BOTTOMLEFT", 0, -3)
	self.noPetInGroup.Text:SetSize(245, 25)
	self.noPetInGroup.Text:SetText(L["NoPetInGroup"])
	self.noPetInGroup:HookScript("OnClick", function() self.applyBtn:Enable() end)

	-- DISABLE AUTO SCROLL
	self.disableAutoScroll = CreateFrame("CheckButton", nil, rightPanelScroll.child, "MJCheckButtonTemplate")
	self.disableAutoScroll:SetPoint("TOPLEFT", self.noPetInGroup, "BOTTOMLEFT", 0, -26)
	self.disableAutoScroll.Text:SetSize(245, 25)
	self.disableAutoScroll.Text:SetText(L["DisableAutoScroll"])
	self.disableAutoScroll:HookScript("OnClick", function() self.applyBtn:Enable() end)

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

	-- REFRESH
	self.refresh = function(self)
		binding.unboundMessage:Hide()
		modifierCombobox:ddSetSelectedValue(mounts.config.modifier)
		modifierCombobox:ddSetSelectedText(_G[mounts.config.modifier.."_KEY"])
		self.waterJump:SetChecked(mounts.config.waterJump)
		binding:setButtonText(self.bindMount)
		binding:setButtonText(self.bindSecondMount)
		self.useHerbMounts:SetChecked(mounts.config.useHerbMounts)
		for _, child in ipairs(self.useHerbMounts.childs) do
			child:SetEnabled(mounts.config.useHerbMounts)
			child:SetChecked(child:checkFunc())
		end
		self.useMagicBroom:SetChecked(mounts.config.useMagicBroom)
		self.noPetInRaid:SetChecked(mounts.config.noPetInRaid)
		self.noPetInGroup:SetChecked(mounts.config.noPetInGroup)
		self.disableAutoScroll:SetChecked(mounts.config.disableAutoScroll)
		self.applyBtn:Disable()
	end

	self:SetScript("OnShow", nil)
end)


function config:createMacro(macroName, buttonName, texture)
	DeleteMacro(macroName)
	CreateMacro(macroName, texture, "/click "..buttonName)

	if not IsAddOnLoaded("Blizzard_MacroUI") then
		LoadAddOn("Blizzard_MacroUI")
	end

	if MacroFrame:IsShown() then
		MacroFrame_Update()
	else
		InterfaceOptionsFrame:SetAttribute("UIPanelLayout-allowOtherPanels", 1)
		local b_HideUIPanel = HideUIPanel
		HideUIPanel = function() end
		ShowUIPanel(MacroFrame)
		HideUIPanel = b_HideUIPanel
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
	mounts.config.useMagicBroom = self.useMagicBroom:GetChecked()
	mounts.config.noPetInRaid = self.noPetInRaid:GetChecked()
	mounts.config.noPetInGroup = self.noPetInGroup:GetChecked()
	mounts.config.disableAutoScroll = self.disableAutoScroll:GetChecked()
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