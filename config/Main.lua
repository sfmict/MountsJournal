local addon, L = ...
local util, mounts, binding = MountsJournalUtil, MountsJournal, _G[addon.."Binding"]
local config = CreateFrame("FRAME", "MountsJournalConfig")
config:Hide()
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
	self:SetScript("OnShow", nil)

	StaticPopupDialogs[util.addonName.."MACRO_EXISTS"] = {
		text = addon..": "..L["A macro named \"%s\" already exists, overwrite it?"],
		button1 = ACCEPT,
		button2 = CANCEL,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = function(popup, cb) popup:Hide() cb() end,
	}

	-- ENABLE APPLY
	local function enableBtns()
		self.applyBtn:Enable()
		self.cancelBtn:Enable()
	end

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
	ver:SetPoint("TOPLEFT", 40, 20)
	ver:SetTextColor(.5, .5, .5, 1)
	ver:SetJustifyH("RIGHT")
	ver:SetText(C_AddOns.GetAddOnMetadata(addon, "Version"))

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
	self.leftPanel = CreateFrame("FRAME", nil, self, "MJOptionsPanel")
	self.leftPanel:SetPoint("TOPLEFT", self, 8, -67)
	self.leftPanel:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", 300, 32)

	-- WATER JUMP
	self.waterJump = CreateFrame("CheckButton", nil, self.leftPanel, "MJCheckButtonTemplate")
	self.waterJump:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 8, -20)
	self.waterJump.Text:SetText(L["Handle a jump in water"])
	self.waterJump.tooltipText = L["Handle a jump in water"]
	self.waterJump.tooltipRequirement = L["WaterJumpDescription"]
	self.waterJump:HookScript("OnClick", enableBtns)

	-- SUMMON 1
	local summon1 = self.leftPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	summon1:SetPoint("TOPLEFT", self.waterJump, "BOTTOMLEFT", 0, -20)
	summon1:SetText(SUMMONS.." 1")

	-- CREATE MACRO
	self.createMacroBtn = CreateFrame("BUTTON", nil, self.leftPanel, "UIPanelButtonTemplate")
	self.createMacroBtn:SetSize(258, 30)
	self.createMacroBtn:SetPoint("TOPLEFT", summon1, "BOTTOMLEFT", 0, -5)
	self.createMacroBtn:SetText(L["CreateMacro"])
	self.createMacroBtn:SetScript("OnClick", function() self:createMacro(self.macroName, self.secureButtonNameMount, 413588, true) end)

	setTooltip(self.createMacroBtn, "ANCHOR_TOP", L["CreateMacro"], L["CreateMacroTooltip"])

	-- OR TEXT
	local macroOrBind = self.leftPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	macroOrBind:SetPoint("TOP", self.createMacroBtn, "BOTTOM", 0, -3)
	macroOrBind:SetText(L["or key bind"])

	-- BIND MOUNT
	self.bindMount:SetParent(self.leftPanel)
	self.bindMount:SetSize(258, 22)
	self.bindMount:SetPoint("TOPLEFT", self.createMacroBtn, "BOTTOMLEFT", 0, -20)

	-- HELP PLATE
	local helpPlate = CreateFrame("FRAME", nil, self.leftPanel, "MJHelpPlate")
	helpPlate:SetPoint("TOP", self.bindMount, "BOTTOM", 0, -20)
	helpPlate.tooltip = L["SecondMountTooltipTitle"]:format(SUMMONS)
	helpPlate.tooltipDescription = "\n"..L["SecondMountTooltipDescription"]

	-- MODIFIER TEXT
	local modifierText = self.leftPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	modifierText:SetPoint("TOPLEFT", self.bindMount, "BOTTOMLEFT", 0, -80)
	modifierText:SetText(L["Modifier"]..":")

	-- MODIFIER COMBOBOX
	local modifierCombobox = LibStub("LibSFDropDown-1.4"):CreateButton(self.leftPanel)
	self.modifierCombobox = modifierCombobox
	modifierCombobox:SetPoint("LEFT", modifierText, "RIGHT", 7, 0)
	modifierCombobox:ddSetInitFunc(function(self, level)
		local info = {}
		for i, modifier in ipairs({"ALT", "CTRL", "SHIFT", "NONE"}) do
			info.text = _G[modifier.."_KEY"]
			info.value = modifier
			info.checked = function(btn) return modifierCombobox.selectedValue == btn.value end
			info.func = function(btn)
				self:ddSetSelectedValue(btn.value)
				enableBtns()
			end
			self:ddAddButton(info, level)
		end
	end)

	-- SUMMON 2
	local summon2 = self.leftPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	summon2:SetPoint("TOPLEFT", modifierText, "BOTTOMLEFT", 0, -20)
	summon2:SetText(SUMMONS.." 2")

	-- CREATE SECOND MACRO
	self.createSecondMacroBtn = CreateFrame("BUTTON", nil, self.leftPanel, "UIPanelButtonTemplate")
	self.createSecondMacroBtn:SetSize(258, 30)
	self.createSecondMacroBtn:SetPoint("TOPLEFT", summon2, "BOTTOMLEFT", 0, -5)
	self.createSecondMacroBtn:SetText(L["CreateMacro"])
	self.createSecondMacroBtn:SetScript("OnClick", function() self:createMacro(self.secondMacroName, self.secureButtonNameSecondMount, 631718, true) end)

	setTooltip(self.createSecondMacroBtn, "ANCHOR_TOP", L["CreateMacro"], L["CreateMacroTooltip"])

	-- OR TEXT SECOND
	local macroOrBindSecond = self.leftPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	macroOrBindSecond:SetPoint("TOP", self.createSecondMacroBtn, "BOTTOM", 0, -3)
	macroOrBindSecond:SetText(L["or key bind"])

	-- BIND SECOND MOUNT
	self.bindSecondMount:SetParent(self.leftPanel)
	self.bindSecondMount:SetSize(258, 22)
	self.bindSecondMount:SetPoint("TOP", self.createSecondMacroBtn, "BOTTOM", 0, -20)

	-- UNBOUND MESSAGE
	binding.unboundMessage:SetParent(self)
	binding.unboundMessage:SetSize(500, 10)
	binding.unboundMessage:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 14, 14)

	-- RIGHT PANEL
	self.rightPanel = CreateFrame("FRAME", nil, self, "MJOptionsPanel")
	self.rightPanel:SetPoint("TOPLEFT", self.leftPanel, "TOPRIGHT", 4, 0)
	self.rightPanel:SetPoint("BOTTOMRIGHT", self, -8, 32)

	self.rightPanelScroll = CreateFrame("ScrollFrame", nil, self.rightPanel, "MJPanelScrollFrameTemplate")
	self.rightPanelScroll:SetPoint("TOPLEFT", self.rightPanel, 4, -6)
	self.rightPanelScroll:SetPoint("BOTTOMRIGHT", self.rightPanel, -26, 5)

	-- USE HERBALISM MOUNTS
	self.useHerbMounts = CreateFrame("CheckButton", nil, self.rightPanelScroll.child, "MJCheckButtonTemplate")
	self.useHerbMounts:SetPoint("TOPLEFT", self.rightPanelScroll.child, 9, -9)
	self.useHerbMounts.Text:SetText(L["UseHerbMounts"])
	self.useHerbMounts.tooltipText = L["UseHerbMounts"]
	self.useHerbMounts.tooltipRequirement = L["UseHerbMountsDescription"]
	self.useHerbMounts:HookScript("OnClick", enableBtns)

	-- USE HERBALISM MOUNTS ON HERBALISM ZONES
	self.herbMountsOnZones = util.createCheckboxChild(L["UseHerbMountsOnZones"], self.useHerbMounts)
	self.herbMountsOnZones.tooltipText = L["UseHerbMountsOnZones"]
	self.herbMountsOnZones.tooltipRequirement = L["UseHerbMountsDescription"]
	self.herbMountsOnZones.checkFunc = function() return mounts.config.herbMountsOnZones end
	self.herbMountsOnZones:HookScript("OnClick", enableBtns)

	-- USE REPAIR MOUNTS
	self.useRepairMounts = CreateFrame("CheckButton", nil, self.rightPanelScroll.child, "MJCheckButtonTemplate")
	self.useRepairMounts:SetPoint("TOPLEFT", self.herbMountsOnZones, "BOTTOMLEFT", -20, -15)
	self.useRepairMounts.Text:SetText(L["If item durability is less than"])
	self.useRepairMounts.tooltipText = L["If item durability is less than"]
	self.useRepairMounts.tooltipRequirement = L["UseRepairMountsDescription"]
	self.useRepairMounts:HookScript("OnClick",  enableBtns)

	-- editbox
	self.repairPercent = CreateFrame("Editbox", nil, self.rightPanelScroll.child, "MJNumberTextBox")
	self.repairPercent:SetPoint("LEFT", self.useRepairMounts.Text, "RIGHT", 3, 0)
	self.repairPercent:SetScript("OnTextChanged", function(editBox, userInput)
		if userInput then
			local value = tonumber(editBox:GetText()) or 0
			if value < 0 then
				editBox:SetNumber(0)
			elseif value > 100 then
				editBox:SetNumber(100)
			end
			enableBtns()
		end
	end)
	self.repairPercent:SetScript("OnMouseWheel", function(editBox, delta)
		if editBox:IsEnabled() then
			local value = (tonumber(editBox:GetText()) or 0) + (delta > 0 and 1 or -1)
			if value >= 0 and value <= 100 then
				editBox:SetNumber(value)
			end
			enableBtns()
		end
	end)
	util.setCheckboxChild(self.useRepairMounts, self.repairPercent)

	-- text
	self.repairPercentText = self.repairPercent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	self.repairPercentText:SetPoint("LEFT", self.repairPercent, "RIGHT", 3, 0)
	self.repairPercentText:SetText("%")

	-- USE REPAIR MOUNTS IN FLYABLE ZONES
	self.repairFlyable = util.createCheckboxChild(L["In flyable zones"], self.useRepairMounts)
	self.repairFlyable.tooltipText = L["In flyable zones"]
	self.repairFlyable.tooltipRequirement = L["UseRepairMountsDescription"]
	self.repairFlyable.setEnabledFunc = function(btn)
		self.repairFlyablePercentText:SetTextColor(btn.Text:GetTextColor())
	end
	self.repairFlyable:HookScript("OnEnable", self.repairFlyable.setEnabledFunc)
	self.repairFlyable:HookScript("OnDisable", self.repairFlyable.setEnabledFunc)
	self.repairFlyable:HookScript("OnClick", enableBtns)

	-- editbox
	self.repairFlyablePercent = CreateFrame("Editbox", nil, self.rightPanelScroll.child, "MJNumberTextBox")
	self.repairFlyablePercent:SetPoint("LEFT", self.repairFlyable.Text, "RIGHT", 3, 0)
	self.repairFlyablePercent:SetScript("OnTextChanged", function(editBox, userInput)
		if userInput then
			local value = tonumber(editBox:GetText()) or 0
			if value < 0 then
				editBox:SetNumber(0)
			elseif value > 100 then
				editBox:SetNumber(100)
			end
			enableBtns()
		end
	end)
	self.repairFlyablePercent:SetScript("OnMouseWheel", function(editBox, delta)
		if editBox:IsEnabled() then
			local value = (tonumber(editBox:GetText()) or 0) + (delta > 0 and 1 or -1)
			if value >= 0 and value <= 100 then
				editBox:SetNumber(value)
			end
			enableBtns()
		end
	end)
	util.setCheckboxChild(self.repairFlyable, self.repairFlyablePercent)

	-- text
	self.repairFlyablePercentText = self.repairPercent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	self.repairFlyablePercentText:SetPoint("LEFT", self.repairFlyablePercent, "RIGHT", 3, 0)
	self.repairFlyablePercentText:SetText("%")

	-- REPAIR MOUNTS COMBOBOX
	self.repairMountsCombobox = LibStub("LibSFDropDown-1.4"):CreateButton(self.rightPanelScroll.child, 230)
	self.repairMountsCombobox:SetPoint("TOPLEFT", self.repairFlyable, "BOTTOMLEFT", 0, -8)
	self.repairMountsCombobox:ddSetInitFunc(function(self, level)
		local info = {}

		info.text = L["Random available mount"]
		info.value = nil
		info.icon = 413588
		info.checked = function(btn) return self.selectedValue == btn.value end
		info.func = function(btn)
			self:ddSetSelectedValue(btn.value)
			enableBtns()
		end
		self:ddAddButton(info, level)

		info.tooltipWhileDisabled = true
		for i, mountID in ipairs(mounts.repairMounts) do
			local name, spellID, icon, _,_,_,_,_,_, shouldHideOnChar, isCollected = C_MountJournal.GetMountInfoByID(mountID)
			if not shouldHideOnChar then
				info.text = name
				info.icon = icon
				info.value = mountID
				info.disabled = not isCollected
				info.checked = function(btn) return self.selectedValue == btn.value end
				info.func = function(btn)
					self:ddSetSelectedValue(btn.value)
					enableBtns()
				end
				info.OnTooltipShow = function(btn, tooltip)
					tooltip:SetMountBySpellID(spellID)
				end
				self:ddAddButton(info, level)
			end
		end
	end)
	util.setCheckboxChild(self.useRepairMounts, self.repairMountsCombobox)

	-- USE MAGIC BROOM
	self.useMagicBroom = CreateFrame("CheckButton", nil, self.rightPanelScroll.child, "MJCheckButtonTemplate")
	self.useMagicBroom:SetPoint("TOPLEFT", self.repairMountsCombobox, "BOTTOMLEFT", -20, -20)
	local magicBroom = Item:CreateFromItemID(37011)
	if magicBroom:IsItemDataCached() then
		self.useMagicBroom.Text:SetText(L["Use %s"]:format(magicBroom:GetItemLink()))
	else
		magicBroom:ContinueOnItemLoad(function()
			self.useMagicBroom.Text:SetText(L["Use %s"]:format(magicBroom:GetItemLink()))
		end)
	end
	util.setHyperlinkTooltip(self.useMagicBroom)
	self.useMagicBroom.tooltipText = L["UseMagicBroomTitle"]
	self.useMagicBroom.tooltipRequirement = L["UseMagicBroomDescription"]
	self.useMagicBroom:HookScript("OnClick", enableBtns)

	-- USE UNDERLIGHT ANGLER
	if C_Item.DoesItemExistByID(133755) then
		self.useUnderlightAngler = CreateFrame("CheckButton", nil, self.rightPanelScroll.child, "MJCheckButtonTemplate")
		self.useUnderlightAngler:SetPoint("TOPLEFT", self.useMagicBroom, "BOTTOMLEFT", 0, -15)
		local underlightAngler = Item:CreateFromItemID(133755)
		if underlightAngler:IsItemDataCached() then
			self.useUnderlightAngler.Text:SetText(L["Use %s"]:format(underlightAngler:GetItemLink()))
			self.useUnderlightAngler.tooltipText = L["Use %s"]:format(underlightAngler:GetItemName())
		else
			underlightAngler:ContinueOnItemLoad(function()
				self.useUnderlightAngler.Text:SetText(L["Use %s"]:format(underlightAngler:GetItemLink()))
				self.useUnderlightAngler.tooltipText = L["Use %s"]:format(underlightAngler:GetItemName())
			end)
		end
		util.setHyperlinkTooltip(self.useUnderlightAngler)
		self.useUnderlightAngler.tooltipRequirement = L["UseUnderlightAnglerDescription"]
		self.useUnderlightAngler:HookScript("OnClick", enableBtns)

		-- AUTO USE UNDERLIGHT ANGLER
		self.autoUseUnderlightAngler = util.createCheckboxChild(L["Use automatically"], self.useUnderlightAngler)
		self.autoUseUnderlightAngler:HookScript("OnClick", enableBtns)
	end

	-- SUMMON PET EVERY N MINUTES
	self.summonPetEvery = CreateFrame("CheckButton", nil, self.rightPanelScroll.child, "MJCheckButtonTemplate")
	if self.autoUseUnderlightAngler then
		self.summonPetEvery:SetPoint("TOPLEFT", self.autoUseUnderlightAngler, "BOTTOMLEFT", -20, -15)
	else
		self.summonPetEvery:SetPoint("TOPLEFT", self.useMagicBroom, "BOTTOMLEFT", 0, -15)
	end
	self.summonPetEvery.Text:SetText(L["Summon a pet every"])
	self.summonPetEvery:HookScript("OnClick",  enableBtns)

	-- count
	self.summonPetEveryN = CreateFrame("Editbox", nil, self.rightPanelScroll.child, "MJNumberTextBox")
	self.summonPetEveryN:SetPoint("LEFT", self.summonPetEvery.Text, "RIGHT", 3, 0)
	self.summonPetEveryN:SetScript("OnTextChanged", function(editBox, userInput)
		if userInput then
			local value = tonumber(editBox:GetText()) or 0
			if value < 1 then
				editBox:SetNumber(1)
			elseif value > 999 then
				editBox:SetNumber(999)
			end
			enableBtns()
		end
	end)
	self.summonPetEveryN:SetScript("OnMouseWheel", function(editBox, delta)
		if editBox:IsEnabled() then
			local value = (tonumber(editBox:GetText()) or 0) + (delta > 0 and 1 or -1)
			if value >= 1 and value <= 999 then
				editBox:SetNumber(value)
			end
			enableBtns()
		end
	end)
	util.setCheckboxChild(self.summonPetEvery, self.summonPetEveryN)

	-- minutes
	self.summonPetMinutes = self.summonPetEveryN:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	self.summonPetMinutes:SetPoint("LEFT", self.summonPetEveryN, "RIGHT", 3, 0)
	self.summonPetMinutes:SetText(L["min"])

	-- SUMMON ONLY FAVORITES
	self.summonPetOnlyFavorites = util.createCheckboxChild(L["Summon only favorites"], self.summonPetEvery)
	self.summonPetOnlyFavorites.checkFunc = function() return mounts.config.summonPetOnlyFavorites end
	self.summonPetOnlyFavorites:HookScript("OnClick", enableBtns)

	-- NO PET IN RAID
	self.noPetInRaid = CreateFrame("CheckButton", nil, self.rightPanelScroll.child, "MJCheckButtonTemplate")
	self.noPetInRaid:SetPoint("TOPLEFT", self.summonPetOnlyFavorites, "BOTTOMLEFT", -20, -3)
	self.noPetInRaid.Text:SetPoint("RIGHT", self.rightPanelScroll)
	self.noPetInRaid.Text:SetText(L["NoPetInRaid"])
	self.noPetInRaid:HookScript("OnClick", enableBtns)

	-- NO PET IN GROUP
	self.noPetInGroup = CreateFrame("CheckButton", nil, self.rightPanelScroll.child, "MJCheckButtonTemplate")
	self.noPetInGroup:SetPoint("TOPLEFT", self.noPetInRaid, "BOTTOMLEFT", 0, -3)
	self.noPetInGroup.Text:SetPoint("RIGHT", self.rightPanelScroll)
	self.noPetInGroup.Text:SetText(L["NoPetInGroup"])
	self.noPetInGroup:HookScript("OnClick", enableBtns)

	-- COPY MOUNT TARGET
	self.copyMountTarget = CreateFrame("CheckButton", nil, self.rightPanelScroll.child, "MJCheckButtonTemplate")
	self.copyMountTarget:SetPoint("TOPLEFT", self.noPetInGroup, "BOTTOMLEFT", 0, -15)
	self.copyMountTarget.Text:SetPoint("RIGHT", self.rightPanelScroll)
	self.copyMountTarget.Text:SetText(L["CopyMountTarget"])
	self.copyMountTarget:HookScript("OnClick", enableBtns)

	-- ARROW BUTTONS
	self.arrowButtons = CreateFrame("CheckButton", nil, self.rightPanelScroll.child, "MJCheckButtonTemplate")
	self.arrowButtons:SetPoint("TOPLEFT", self.copyMountTarget, "BOTTOMLEFT", 0, -15)
	self.arrowButtons.Text:SetPoint("RIGHT", self.rightPanelScroll)
	self.arrowButtons.Text:SetText(L["Enable arrow buttons to browse mounts"])
	self.arrowButtons:HookScript("OnClick", enableBtns)

	-- OPEN HYPERLINKS
	self.openLinks = CreateFrame("CheckButton", nil, self.rightPanelScroll.child, "MJCheckButtonTemplate")
	self.openLinks:SetPoint("TOPLEFT", self.arrowButtons, "BOTTOMLEFT", 0, -15)
	self.openLinks.Text:SetPoint("RIGHT", self.rightPanelScroll)
	self.openLinks.Text:SetText(L["Open links in %s"]:format(addon))
	self.openLinks.tooltipText = L["Open links in %s"]:format(addon)
	local dressUpMod = ("-"):split(GetModifiedClick("DRESSUP"))
	local chatLinkMod = ("-"):split(GetModifiedClick("CHATLINK"))
	self.openLinks.tooltipRequirement = ("%s+%s %s\n%s+%s+%s %s"):format(dressUpMod, L["Click opens in"], addon, dressUpMod, chatLinkMod, L["Click opens in"], DRESSUP_FRAME)
	self.openLinks:HookScript("OnClick", enableBtns)

	-- WOWHEAD LINK SHOW
	self.showWowheadLink = CreateFrame("CheckButton", nil, self.rightPanelScroll.child, "MJCheckButtonTemplate")
	self.showWowheadLink:SetPoint("TOPLEFT", self.openLinks, "BOTTOMLEFT", 0, -15)
	self.showWowheadLink.Text:SetPoint("RIGHT", self.rightPanelScroll)
	self.showWowheadLink.Text:SetText(L["Show wowhead link in mount preview"])
	self.showWowheadLink:HookScript("OnClick", enableBtns)

	-- RESET HELP
	self.resetHelp = CreateFrame("BUTTON", nil, self.rightPanelScroll.child, "UIPanelButtonTemplate")
	self.resetHelp:SetSize(128, 22)
	self.resetHelp:SetPoint("TOPLEFT", self.showWowheadLink, "BOTTOMLEFT", 0, -15)
	self.resetHelp:SetText(RESET_TUTORIALS)
	self.resetHelp:SetScript("OnClick", function(btn)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		mounts.help.journal = 0
		util.showHelpJournal()
		btn:Disable()
	end)

	-- CANCEL
	self.cancelBtn = CreateFrame("BUTTON", nil, self, "UIPanelButtonTemplate")
	self.cancelBtn:SetSize(96, 22)
	self.cancelBtn:Disable()
	self.cancelBtn:SetPoint("BOTTOMRIGHT", -8, 8)
	self.cancelBtn:SetText(CANCEL)
	self.cancelBtn:SetScript("OnClick", function(btn)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self:GetScript("OnHide")(self)
		binding:setButtonText(self.bindMount)
		binding:setButtonText(self.bindSecondMount)
		self:OnRefresh()
		self.applyBtn:Disable()
		btn:Disable()
	end)

	-- APPLY
	self.applyBtn = CreateFrame("BUTTON", nil, self, "UIPanelButtonTemplate")
	self.applyBtn:SetSize(96, 22)
	self.applyBtn:Disable()
	self.applyBtn:SetPoint("RIGHT", self.cancelBtn, "LEFT", -5, 0)
	self.applyBtn:SetText(APPLY)
	self.applyBtn:SetScript("OnClick", function(btn)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self:OnCommit()
		self.cancelBtn:Disable()
		btn:Disable()
	end)

	-- UPDATE BINDING BUTTONS
	binding:on("SET_BINDING", function(binding, btn)
		if self.bindMount ~= btn then binding:setButtonText(self.bindMount) end
		if self.bindSecondMount ~= btn then binding:setButtonText(self.bindSecondMount) end
		enableBtns()
	end)

	-- REFRESH
	self.OnRefresh = function(self)
		self:SetPoint("TOPLEFT", -12, 8)
		binding.unboundMessage:Hide()
		modifierCombobox:ddSetSelectedValue(mounts.config.modifier)
		modifierCombobox:ddSetSelectedText(_G[mounts.config.modifier.."_KEY"])
		self.waterJump:SetChecked(mounts.config.waterJump)
		self.useHerbMounts:SetChecked(mounts.config.useHerbMounts)
		for _, child in ipairs(self.useHerbMounts.childs) do
			child:SetChecked(child:checkFunc())
		end
		self.useRepairMounts:SetChecked(mounts.config.useRepairMounts)
		self.repairFlyable:SetChecked(mounts.config.useRepairFlyable)
		self.repairPercent:SetNumber(tonumber(mounts.config.useRepairMountsDurability) or 0)
		self.repairFlyablePercent:SetNumber(tonumber(mounts.config.useRepairFlyableDurability) or 0)
		self.repairMountsCombobox:ddSetSelectedValue(mounts.config.repairSelectedMount)
		if mounts.config.repairSelectedMount then
			local name, _, icon = C_MountJournal.GetMountInfoByID(mounts.config.repairSelectedMount)
			self.repairMountsCombobox:ddSetSelectedText(name, icon)
		else
			self.repairMountsCombobox:ddSetSelectedText(L["Random available mount"], 413588)
		end
		self.useMagicBroom:SetChecked(mounts.config.useMagicBroom)
		if self.useUnderlightAngler then
			self.useUnderlightAngler:SetChecked(mounts.config.useUnderlightAngler)
			self.autoUseUnderlightAngler:SetChecked(mounts.config.autoUseUnderlightAngler)
		end
		self.summonPetEvery:SetChecked(mounts.config.summonPetEvery)
		self.summonPetEveryN:SetNumber(tonumber(mounts.config.summonPetEveryN) or 1)
		for _, child in ipairs(self.summonPetEvery.childs) do
			if child.checkFunc then child:SetChecked(child:checkFunc()) end
		end
		self.noPetInRaid:SetChecked(mounts.config.noPetInRaid)
		self.noPetInGroup:SetChecked(mounts.config.noPetInGroup)
		self.copyMountTarget:SetChecked(mounts.config.copyMountTarget)
		self.arrowButtons:SetChecked(mounts.config.arrowButtonsBrowse)
		self.openLinks:SetChecked(mounts.config.openHyperlinks)
		self.showWowheadLink:SetChecked(mounts.config.showWowheadLink)
		self.resetHelp:Enable()
		self.cancelBtn:Disable()
		self.applyBtn:Disable()
	end
	self:OnRefresh()

	-- COMMIT
	self.OnCommit = function(self)
		binding.unboundMessage:Hide()
		mounts.config.useHerbMounts = self.useHerbMounts:GetChecked()
		mounts.config.herbMountsOnZones = self.herbMountsOnZones:GetChecked()
		mounts.config.useRepairMounts = self.useRepairMounts:GetChecked()
		mounts.config.useRepairMountsDurability = tonumber(self.repairPercent:GetText()) or 0
		mounts.config.useRepairFlyable = self.repairFlyable:GetChecked()
		mounts.config.useRepairFlyableDurability = tonumber(self.repairFlyablePercent:GetText()) or 0
		mounts.config.repairSelectedMount = self.repairMountsCombobox.selectedValue
		mounts.config.useMagicBroom = self.useMagicBroom:GetChecked()
		if self.useUnderlightAngler then
			mounts.config.useUnderlightAngler = self.useUnderlightAngler:GetChecked()
			mounts.config.autoUseUnderlightAngler = self.autoUseUnderlightAngler:GetChecked()
		end
		mounts.config.summonPetEvery = self.summonPetEvery:GetChecked()
		mounts.config.summonPetEveryN = tonumber(self.summonPetEveryN:GetText()) or 1
		mounts.config.summonPetOnlyFavorites = self.summonPetOnlyFavorites:GetChecked()
		mounts.config.noPetInRaid = self.noPetInRaid:GetChecked()
		mounts.config.noPetInGroup = self.noPetInGroup:GetChecked()
		mounts.config.copyMountTarget = self.copyMountTarget:GetChecked()
		mounts.config.arrowButtonsBrowse = self.arrowButtons:GetChecked()
		mounts.config.openHyperlinks = self.openLinks:GetChecked()
		mounts.config.showWowheadLink = self.showWowheadLink:GetChecked()

		binding:saveBinding()
		mounts:setHandleWaterJump(self.waterJump:GetChecked())
		mounts:setModifier(self.modifierCombobox.selectedValue)
		mounts:UPDATE_INVENTORY_DURABILITY()
		mounts:setUsableRepairMounts()
		mounts:setHerbMount()
		mounts.pets:setSummonEvery()
		MountsJournalFrame:setArrowSelectMount(mounts.config.arrowButtonsBrowse)
	end
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

	local macro = "/click "..buttonName
	if GetCVarBool("ActionButtonUseKeyDown") then
		macro = macro.." LeftButton 1"
	end

	if overwrite then
		EditMacro(macroName, macroName, texture, macro)
	else
		CreateMacro(macroName, texture, macro)
	end

	if not openMacroFrame then return end

	if not IsAddOnLoaded("Blizzard_MacroUI") then
		LoadAddOn("Blizzard_MacroUI")
	end

	if not MacroFrame:IsShown() then
		local centerFrame, allowOtherPanels = GetUIPanel("center")
		if centerFrame then
			allowOtherPanels = centerFrame:GetAttribute("UIPanelLayout-allowOtherPanels")
			centerFrame:SetAttribute("UIPanelLayout-allowOtherPanels", 1)
		end
		ShowUIPanel(MacroFrame, 1)
		if centerFrame then
			centerFrame:SetAttribute("UIPanelLayout-allowOtherPanels", allowOtherPanels)
		end
	end

	local index = GetMacroIndexByName(macroName)
	MacroFrame.MacroSelector:OnSelection(index)
	MacroFrame.MacroSelector:ScrollToSelectedIndex()
end


config:SetScript("OnHide", function()
	binding:resetBinding()
end)


-- ADD CATEGORY
local category, layout = Settings.RegisterCanvasLayoutCategory(config, addon)
category.ID = addon
-- layout:AddAnchorPoint("TOPLEFT", -12, 8)
-- layout:AddAnchorPoint("BOTTOMRIGHT", 0, 0)
Settings.RegisterAddOnCategory(category)


-- OPEN CONFIG
function config:openConfig()
	if SettingsPanel:IsVisible() and self:IsVisible() then
		HideUIPanel(SettingsPanel)
	else
		-- Settings.GetCategory(addon).expanded = true
		Settings.OpenToCategory(addon, true)
		-- SettingsPanel:GetCategoryList():CreateCategories()
	end
end


SLASH_MOUNTSCONFIG1 = "/mountconfig"
SLASH_MOUNTSCONFIG2 = "/mco"
SlashCmdList["MOUNTSCONFIG"] = function() config:openConfig() end