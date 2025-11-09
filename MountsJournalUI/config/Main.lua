local addon, ns = ...
local L, util, mounts, binding, journal = ns.L, ns.util, ns.mounts, ns.binding, ns.journal
local specificDB = ns.specificDB
local config = CreateFrame("FRAME", "MountsJournalConfig")
ns.config = config
config:Hide()
-- config.macroName = "MJMacro"
-- config.secondMacroName = "MJSecondMacro"


-- SHOW CONFIG
config:SetScript("OnShow", function(self)
	local lsfdd = LibStub("LibSFDropDown-1.5")
	local ltl = LibStub("LibThingsLoad-1.0")

	local randomMountIcon = 413588

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

	-- GROUP
	local function createGropPanel(parent, numCheck, numComboBox)
		local group = CreateFrame("FRAME", nil, parent, "MJOptionsPanel")
		group:SetPoint("RIGHT", parent:GetParent(), 0, 0)
		-- check = 26 + 3, combobox = 25 + 8 + 2
		group:SetHeight(29 * numCheck + 35 * (numComboBox or 0) + 3)
		return group
	end

	-- VERSION
	local ver = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	ver:SetPoint("TOPRIGHT", -40, 15)
	ver:SetTextColor(.5, .5, .5, 1)
	ver:SetJustifyH("RIGHT")
	ver:SetText(C_AddOns.GetAddOnMetadata(addon, "Version"))

	-- TITLE
	local subtitle = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	subtitle:SetHeight(30)
	subtitle:SetPoint("TOPLEFT", 16, -16)
	subtitle:SetNonSpaceWrap(true)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetJustifyV("TOP")
	subtitle:SetText(L["ConfigPanelTitle"])

	-- LEFT PANEL
	self.leftPanel = CreateFrame("FRAME", nil, self, "MJOptionsPanel")
	self.leftPanel:SetPoint("TOPLEFT", self, 8, -37)
	self.leftPanel:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", 300, 32)

	-- WATER JUMP
	self.waterJump = CreateFrame("CheckButton", nil, self.leftPanel, "MJCheckButtonTemplate")
	self.waterJump:SetPoint("TOPLEFT", self.leftPanel, 13, -15)
	self.waterJump.Text:SetText(L["Handle a jump in water"])
	self.waterJump.tooltipText = L["Handle a jump in water"]
	self.waterJump.tooltipRequirement = L["WaterJumpDescription"]
	self.waterJump:HookScript("OnClick", enableBtns)

	-- SUMMON 1 ICON
	self.summon1Icon = CreateFrame("BUTTON", nil, self.leftPanel, "MJIconButtonTemplate")
	self.summon1Icon:SetPoint("TOPLEFT", self.waterJump, "BOTTOMLEFT", 3, -12)
	self.summon1Icon:SetScript("OnClick", function(btn)
		self.iconData:init(btn, enableBtns)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	-- SUMMON 1
	local summon1 = self.leftPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	summon1:SetPoint("BOTTOMLEFT", self.summon1Icon, "BOTTOMRIGHT", 10, 0)
	summon1:SetText(SUMMONS.." 1")

	-- BIND MOUNT 1
	config.bindSummon1Key1,	config.bindSummon1Key2 = binding:createBindingButtons(util.secureButtonNameMount, self.leftPanel, ("%s %s %d"):format(ns.addon, SUMMONS, 1))
	self.bindSummon1Key1:SetWidth(258)
	self.bindSummon1Key1:SetPoint("TOPLEFT", self.summon1Icon, "BOTTOMLEFT", -3, -8)
	self.bindSummon1Key2:SetParent(self.leftPanel)

	-- HELP PLATE SECOND MOUNT
	local helpPlateSecond = CreateFrame("FRAME", nil, self.leftPanel, "MJHelpPlate")
	helpPlateSecond:SetPoint("TOP", self.bindSummon1Key2, "BOTTOM", 0, -10)
	helpPlateSecond.tooltip = L["SecondMountTooltipTitle"]:format(SUMMONS)
	helpPlateSecond.tooltipDescription = "\n"..L["SecondMountTooltipDescription"]

	-- MODIFIER TEXT
	local modifierText = self.leftPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	modifierText:SetPoint("TOPLEFT", self.bindSummon1Key2, "BOTTOMLEFT", 0, -70)
	modifierText:SetText(L["Modifier"]..":")

	-- MODIFIER COMBOBOX
	self.modifierCombobox = lsfdd:CreateModernButtonOriginal(self.leftPanel)
	self.modifierCombobox:SetPoint("LEFT", modifierText, "RIGHT", 7, 0)
	self.modifierCombobox:ddSetDisplayMode(addon)
	self.modifierCombobox:ddSetInitFunc(function(self, level)
		local info = {}
		for i, modifier in ipairs({"ALT", "CTRL", "SHIFT", "NONE"}) do
			info.text = _G[modifier.."_KEY"]
			info.value = modifier
			info.checked = function(btn) return self:ddGetSelectedValue() == btn.value end
			info.func = function(btn)
				self:ddSetSelectedValue(btn.value)
				enableBtns()
			end
			self:ddAddButton(info, level)
		end
	end)

	-- SUMMON 2 ICON
	self.summon2Icon = CreateFrame("BUTTON", nil, self.leftPanel, "MJIconButtonTemplate")
	self.summon2Icon:SetPoint("TOPLEFT", modifierText, "BOTTOMLEFT", 3, -12)
	self.summon2Icon:SetScript("OnClick", function(btn)
		self.iconData:init(btn, enableBtns)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	-- SUMMON 2
	local summon2 = self.leftPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	summon2:SetPoint("BOTTOMLEFT", self.summon2Icon, "BOTTOMRIGHT", 10, 0)
	summon2:SetText(SUMMONS.." 2")

	-- BIND MOUNT 2
	config.bindSummon2Key1, config.bindSummon2Key2 = binding:createBindingButtons(util.secureButtonNameSecondMount, self.leftPanel, ("%s %s %d"):format(ns.addon, SUMMONS, 2))
	self.bindSummon2Key1:SetSize(258, 22)
	self.bindSummon2Key1:SetPoint("TOPLEFT", self.summon2Icon, "BOTTOMLEFT", -3, -8)
	self.bindSummon2Key2:SetParent(self.leftPanel)

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

	-- HERB GROUP
	self.herbGroup = createGropPanel(self.rightPanelScroll.child, 2)
	self.herbGroup:SetPoint("TOPLEFT", 3, -2)

	-- USE HERBALISM MOUNTS
	self.useHerbMounts = CreateFrame("CheckButton", nil, self.herbGroup, "MJCheckButtonTemplate")
	self.useHerbMounts:SetPoint("TOPLEFT", self.herbGroup, 3, -3)
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

	-- REPAIR GROUP
	self.repairGroup = createGropPanel(self.rightPanelScroll.child, 3, 1)
	self.repairGroup:SetPoint("TOPLEFT", self.herbGroup, "BOTTOMLEFT", 0, -5)

	-- USE REPAIR MOUNTS
	self.useRepairMounts = CreateFrame("CheckButton", nil, self.repairGroup, "MJCheckButtonTemplate")
	self.useRepairMounts:SetPoint("TOPLEFT", self.repairGroup, 3, -3)
	self.useRepairMounts.Text:SetText(L["If item durability is less than"])
	self.useRepairMounts.tooltipText = L["If item durability is less than"]
	self.useRepairMounts.tooltipRequirement = L["UseRepairMountsDescription"]
	self.useRepairMounts:HookScript("OnClick",  enableBtns)

	-- editbox
	self.repairPercent = CreateFrame("Editbox", nil, self.repairGroup, "MJNumberTextBox")
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
				enableBtns()
			end
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
	self.repairFlyablePercent = CreateFrame("Editbox", nil, self.repairGroup, "MJNumberTextBox")
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
				enableBtns()
			end
		end
	end)
	util.setCheckboxChild(self.repairFlyable, self.repairFlyablePercent)

	-- text
	self.repairFlyablePercentText = self.repairPercent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	self.repairFlyablePercentText:SetPoint("LEFT", self.repairFlyablePercent, "RIGHT", 3, 0)
	self.repairFlyablePercentText:SetText("%")

	-- FREE SLOTS NUM
	self.freeSlots = CreateFrame("CheckButton", nil, self.repairGroup, "MJCheckButtonTemplate")
	self.freeSlots:SetPoint("TOPLEFT", self.repairFlyable, "BOTTOMLEFT", -20, -3)
	-- self.freeSlots.Text:SetPoint("RIGHT", self.repairGroup, -37, 0) -- width isn't redered correctly
	self.freeSlots.Text:SetWidth(264)
	self.freeSlots.Text:SetText(L["If the number of free slots in bags is less"])
	self.freeSlots:HookScript("OnClick",  enableBtns)

	-- editbox
	self.freeSlotsNum = CreateFrame("Editbox", nil, self.repairGroup, "MJNumberTextBox")
	self.freeSlotsNum:SetPoint("LEFT", self.freeSlots.Text, self.freeSlots.Text:GetWrappedWidth() + 3, 0)
	self.freeSlotsNum:SetScript("OnTextChanged", function(editBox, userInput)
		if userInput then
			local value = tonumber(editBox:GetText()) or 0
			if value < 1 then editBox:SetNumber(1) end
			enableBtns()
		end
	end)
	self.freeSlotsNum:SetScript("OnMouseWheel", function(editBox, delta)
		if editBox:IsEnabled() then
			local value = (tonumber(editBox:GetText()) or 0) + (delta > 0 and 1 or -1)
			if value > 0 then
				editBox:SetNumber(value)
				enableBtns()
			end
		end
	end)
	util.setCheckboxChild(self.freeSlots, self.freeSlotsNum)

	-- REPAIR MOUNTS COMBOBOX
	self.repairMountsCombobox = lsfdd:CreateModernButtonOriginal(self.repairGroup, 230)
	self.repairMountsCombobox:SetPoint("TOPLEFT", self.freeSlots, "BOTTOMLEFT", 2, -8)
	self.repairMountsCombobox:ddSetDisplayMode(addon)
	self.repairMountsCombobox:ddSetInitFunc(function(self, level)
		local info = {}

		info.text = L["Random available mount"]
		info.value = nil
		info.icon = randomMountIcon
		info.checked = function(btn) return self:ddGetSelectedValue() == btn.value end
		info.func = function(btn)
			self:ddSetSelectedValue(btn.value)
			enableBtns()
		end
		self:ddAddButton(info, level)

		info.tooltipWhileDisabled = true
		for spellID in pairs(specificDB.repair) do
			local mountID = C_MountJournal.GetMountFromSpell(spellID)
			local name, _, icon, _,_,_,_,_,_, shouldHideOnChar, isCollected = C_MountJournal.GetMountInfoByID(mountID)
			if not shouldHideOnChar then
				info.text = name
				info.icon = icon
				info.value = spellID
				info.disabled = not isCollected
				info.checked = function(btn) return self:ddGetSelectedValue() == btn.value end
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

	-- MAGIC BROOM GROUP
	self.magicBroomGroup = createGropPanel(self.rightPanelScroll.child, 1, 1)
	self.magicBroomGroup:SetPoint("TOPLEFT", self.repairGroup, "BOTTOMLEFT", 0, -5)

	-- USE MAGIC BROOM
	self.useMagicBroom = CreateFrame("CheckButton", nil, self.magicBroomGroup, "MJCheckButtonTemplate")
	self.useMagicBroom:SetPoint("TOPLEFT", self.magicBroomGroup, 3, -3)
	self.useMagicBroom.Text:SetPoint("RIGHT", self.magicBroomGroup, -4, 0)
	self.useMagicBroom.Text:SetText(L["UseHallowsEndMounts"])
	self.useMagicBroom.tooltipText = L["UseHallowsEndMounts"]
	self.useMagicBroom.tooltipRequirement = L["UseHallowsEndMountsDescription"]
	self.useMagicBroom:HookScript("OnClick", enableBtns)

	-- MAGIC BROOM COMBOBOX
	self.magicBroomCombobox = lsfdd:CreateModernButtonOriginal(self.magicBroomGroup, 230)
	self.magicBroomCombobox:SetPoint("TOPLEFT", self.useMagicBroom, "BOTTOMLEFT", 20, -8)
	self.magicBroomCombobox:ddSetDisplayMode(addon)

	ltl:SetScriptAfter(self.magicBroomCombobox, "OnClick", "Items",
		function(btn)
			local t = {}
			for i, data in ipairs(mounts.magicBrooms) do
				if data.itemID then t[#t + 1] = data.itemID end
			end
			return t
		end,
		function(btn)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			btn:ddToggle(1, nil, btn, -5, 0)
		end
	)

	self.magicBroomCombobox:ddSetInitFunc(function(self, level)
		local info = {}

		info.text = L["Random available mount"]
		info.value = nil
		info.icon = randomMountIcon
		info.checked = function(btn) return self:ddGetSelectedValue() == btn.value end
		info.func = function(btn)
			self:ddSetSelectedValue(btn.value)
			enableBtns()
		end
		self:ddAddButton(info, level)

		info.tooltipWhileDisabled = true
		for i, data in ipairs(mounts.magicBrooms) do
			if data.mountID then
				local name, spellID, icon, _,_,_,_,_,_, shouldHideOnChar, isCollected = C_MountJournal.GetMountInfoByID(data.mountID)
				info.disabled = not isCollected
				info.text = name
				info.icon = icon
				info.value = data
				info.checked = function(btn)
					local selectedValue = self:ddGetSelectedValue()
					return selectedValue and selectedValue.mountID == btn.value.mountID
				end
				info.func = function(btn)
					self:ddSetSelectedValue(btn.value)
					enableBtns()
				end
				info.OnTooltipShow = function(btn, tooltip)
					tooltip:SetMountBySpellID(spellID)
				end
				self:ddAddButton(info, level)
			elseif data.itemID then
				info.disabled = nil
				info.text = ltl:GetItemName(data.itemID)
				info.icon = ltl:GetItemIcon(data.itemID)
				info.value = data
				info.checked = function(btn)
					local selectedValue = self:ddGetSelectedValue()
					return selectedValue and selectedValue.itemID == btn.value.itemID
				end
				info.func = function(btn)
					self:ddSetSelectedValue(btn.value)
					enableBtns()
				end
				info.OnTooltipShow = function(btn, tooltip)
					tooltip:SetHyperlink(ltl:GetItemLink(data.itemID))
				end
				self:ddAddButton(info, level)
			end
		end
	end)
	util.setCheckboxChild(self.useMagicBroom, self.magicBroomCombobox)

	-- USE UNDERLIGHT ANGLER
	if C_Item.DoesItemExistByID(133755) then
		self.underlightAnglerGroup = createGropPanel(self.rightPanelScroll.child, 2)
		self.underlightAnglerGroup:SetPoint("TOPLEFT", self.magicBroomGroup, "BOTTOMLEFT", 0, -5)

		self.useUnderlightAngler = CreateFrame("CheckButton", nil, self.underlightAnglerGroup, "MJCheckButtonTemplate")
		self.useUnderlightAngler:SetPoint("TOPLEFT", self.underlightAnglerGroup, 3, -3)
		local underlightAngler = Item:CreateFromItemID(133755)
		underlightAngler:ContinueOnItemLoad(function()
			self.useUnderlightAngler.Text:SetText(L["Use %s"]:format(underlightAngler:GetItemLink()))
			self.useUnderlightAngler.tooltipText = L["Use %s"]:format(underlightAngler:GetItemName())
		end)
		util.setHyperlinkTooltip(self.useUnderlightAngler)
		self.useUnderlightAngler.tooltipRequirement = L["UseUnderlightAnglerDescription"]
		self.useUnderlightAngler:HookScript("OnClick", enableBtns)

		-- AUTO USE UNDERLIGHT ANGLER
		self.autoUseUnderlightAngler = util.createCheckboxChild(L["Use automatically"], self.useUnderlightAngler)
		self.autoUseUnderlightAngler:HookScript("OnClick", enableBtns)
	end

	-- PET GROUP
	self.petGroup = createGropPanel(self.rightPanelScroll.child, 4)
	self.petGroup:SetPoint("TOPLEFT", self.underlightAnglerGroup or self.magicBroomGroup, "BOTTOMLEFT", 0, -5)

	-- SUMMON PET EVERY N MINUTES
	self.summonPetEvery = CreateFrame("CheckButton", nil, self.petGroup, "MJCheckButtonTemplate")
	self.summonPetEvery:SetPoint("TOPLEFT", self.petGroup, 3, -3)
	self.summonPetEvery.Text:SetText(L["Summon a pet every"])
	self.summonPetEvery:HookScript("OnClick",  enableBtns)

	-- count
	self.summonPetEveryN = CreateFrame("Editbox", nil, self.petGroup, "MJNumberTextBox")
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
				enableBtns()
			end
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
	self.noPetInRaid = CreateFrame("CheckButton", nil, self.petGroup, "MJCheckButtonTemplate")
	self.noPetInRaid:SetPoint("TOPLEFT", self.summonPetOnlyFavorites, "BOTTOMLEFT", -20, -3)
	self.noPetInRaid.Text:SetPoint("RIGHT", self.petGroup, -4, 0)
	self.noPetInRaid.Text:SetText(L["NoPetInRaid"])
	self.noPetInRaid:HookScript("OnClick", enableBtns)

	-- NO PET IN GROUP
	self.noPetInGroup = CreateFrame("CheckButton", nil, self.petGroup, "MJCheckButtonTemplate")
	self.noPetInGroup:SetPoint("TOPLEFT", self.noPetInRaid, "BOTTOMLEFT", 0, -3)
	self.noPetInGroup.Text:SetPoint("RIGHT", self.petGroup, -4, 0)
	self.noPetInGroup.Text:SetText(L["NoPetInGroup"])
	self.noPetInGroup:HookScript("OnClick", enableBtns)

	-- MOUNT LIST GROUP
	self.mountListGroup = createGropPanel(self.rightPanelScroll.child, 3)
	self.mountListGroup:SetPoint("TOPLEFT", self.petGroup, "BOTTOMLEFT", 0, -5)

	-- COLORIZED NAMES
	self.coloredMountNames = CreateFrame("CheckButton", nil, self.mountListGroup, "MJCheckButtonTemplate")
	self.coloredMountNames:SetPoint("TOPLEFT", self.mountListGroup, 3, -3)
	self.coloredMountNames.Text:SetPoint("RIGHT", self.mountListGroup, -4, 0)
	self.coloredMountNames.Text:SetText(L["Colored mount names by rarity"])
	self.coloredMountNames:HookScript("OnClick", enableBtns)

	-- ARROW BUTTONS
	self.arrowButtons = CreateFrame("CheckButton", nil, self.mountListGroup, "MJCheckButtonTemplate")
	self.arrowButtons:SetPoint("TOPLEFT", self.coloredMountNames, "BOTTOMLEFT", 0, -3)
	self.arrowButtons.Text:SetPoint("RIGHT", self.mountListGroup, -4, 0)
	self.arrowButtons.Text:SetText(L["Enable arrow buttons to browse mounts"])
	self.arrowButtons:HookScript("OnClick", enableBtns)

	-- TYPE SELECTION BUTTONS
	self.showTypeSelBtn = CreateFrame("CheckButton", nil, self.mountListGroup, "MJCheckButtonTemplate")
	self.showTypeSelBtn:SetPoint("TOPLEFT", self.arrowButtons, "BOTTOMLEFT", 0, -3)
	self.showTypeSelBtn.Text:SetPoint("RIGHT", self.mountListGroup, -4, 0)
	self.showTypeSelBtn.Text:SetText(L["Show mount type selection buttons"])
	self.showTypeSelBtn:HookScript("OnClick", enableBtns)

		-- COPY MOUNT TARGET
	self.copyMountTarget = CreateFrame("CheckButton", nil, self.rightPanelScroll.child, "MJCheckButtonTemplate")
	self.copyMountTarget:SetPoint("TOPLEFT", self.showTypeSelBtn, "BOTTOMLEFT", 0, -15)
	self.copyMountTarget.Text:SetPoint("RIGHT", self.rightPanelScroll)
	self.copyMountTarget.Text:SetText(L["CopyMountTarget"])
	self.copyMountTarget:HookScript("OnClick", enableBtns)

	-- OPEN HYPERLINKS
	self.openLinks = CreateFrame("CheckButton", nil, self.rightPanelScroll.child, "MJCheckButtonTemplate")
	self.openLinks:SetPoint("TOPLEFT", self.copyMountTarget, "BOTTOMLEFT", 0, -15)
	self.openLinks.Text:SetPoint("RIGHT", self.rightPanelScroll)
	self.openLinks.Text:SetText(L["Open links in %s"]:format(ns.addon))
	self.openLinks.tooltipText = L["Open links in %s"]:format(ns.addon)
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

	-- STATISTIC COLLECTION
	self.statisticCollection = CreateFrame("CheckButton", nil, self.rightPanelScroll.child, "MJCheckButtonTemplate")
	self.statisticCollection:SetPoint("TOPLEFT", self.showWowheadLink, "BOTTOMLEFT", 0, -15)
	self.statisticCollection.Text:SetPoint("RIGHT", self.rightPanelScroll)
	self.statisticCollection.Text:SetText(L["Enable statistics collection"])
	self.statisticCollection.tooltipText = L["Enable statistics collection"]
	self.statisticCollection.tooltipRequirement = L["STATISTICS_DESCRIPTION"]
	self.statisticCollection:HookScript("OnClick", enableBtns)

	-- TOOLTIP GROUP
	self.tooltipGroup = createGropPanel(self.rightPanelScroll.child, 2)
	self.tooltipGroup:SetPoint("TOPLEFT", self.statisticCollection, "BOTTOMLEFT", -3, -12)

	-- TOOLTIP MOUNT
	self.tooltipMount = CreateFrame("CheckButton", nil, self.tooltipGroup, "MJCheckButtonTemplate")
	self.tooltipMount:SetPoint("TOPLEFT", self.tooltipGroup, 3, -3)
	self.tooltipMount.Text:SetPoint("RIGHT", self.tooltipGroup, -4, 0)
	self.tooltipMount.Text:SetText(L["Show mount in unit tooltip"])
	self.tooltipMount:HookScript("OnClick", enableBtns)

	-- TOOLTIP ITEMS
	self.tooltipItems = CreateFrame("CheckButton", nil, self.tooltipGroup, "MJCheckButtonTemplate")
	self.tooltipItems:SetPoint("TOPLEFT", self.tooltipMount, "BOTTOMLEFT", 0, -3)
	self.tooltipItems.Text:SetPoint("RIGHT", self.tooltipGroup, -4, 0)
	self.tooltipItems.Text:SetText(L["Add information to item tooltip"])
	self.tooltipItems:HookScript("OnClick", enableBtns)

	-- RESET HELP
	self.resetHelp = CreateFrame("BUTTON", nil, self.rightPanelScroll.child, "UIPanelButtonTemplate")
	self.resetHelp:SetSize(128, 22)
	self.resetHelp:SetPoint("TOPLEFT", self.tooltipItems, "BOTTOMLEFT", 0, -15)
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
	binding:on("SET_BINDING", enableBtns)

	-- REFRESH
	self.OnRefresh = function(self)
		binding.unboundMessage:Hide()
		self.modifierCombobox:ddSetSelectedValue(mounts.config.modifier)
		self.modifierCombobox:ddSetSelectedText(_G[mounts.config.modifier.."_KEY"])
		self.waterJump:SetChecked(mounts.config.waterJump)
		self.summon1Icon.icon:SetTexture(mounts.config.summon1Icon)
		self.summon2Icon.icon:SetTexture(mounts.config.summon2Icon)
		self.useHerbMounts:SetChecked(mounts.config.useHerbMounts)
		for _, child in ipairs(self.useHerbMounts.childs) do
			child:SetChecked(child:checkFunc())
		end
		self.useRepairMounts:SetChecked(mounts.config.useRepairMounts)
		self.repairFlyable:SetChecked(mounts.config.useRepairFlyable)
		self.repairPercent:SetNumber(tonumber(mounts.config.useRepairMountsDurability) or 0)
		self.repairFlyablePercent:SetNumber(tonumber(mounts.config.useRepairFlyableDurability) or 0)
		self.freeSlots:SetChecked(mounts.config.useRepairFreeSlots)
		self.freeSlotsNum:SetNumber(tonumber(mounts.config.useRepairFreeSlotsNum) or 0)
		self.repairMountsCombobox:ddSetSelectedValue(mounts.config.repairSelectedMount)
		if mounts.config.repairSelectedMount then
			local mountID = C_MountJournal.GetMountFromSpell(mounts.config.repairSelectedMount)
			local name, _, icon = C_MountJournal.GetMountInfoByID(mountID)
			self.repairMountsCombobox:ddSetSelectedText(name, icon)
		else
			self.repairMountsCombobox:ddSetSelectedText(L["Random available mount"], randomMountIcon)
		end
		self.useMagicBroom:SetChecked(mounts.config.useMagicBroom)
		self.magicBroomCombobox:ddSetSelectedValue(mounts.config.broomSelectedMount)
		if mounts.config.broomSelectedMount then
			if mounts.config.broomSelectedMount.mountID then
				local name, _, icon = C_MountJournal.GetMountInfoByID(mounts.config.broomSelectedMount.mountID)
				self.magicBroomCombobox:ddSetSelectedText(name, icon)
			elseif mounts.config.broomSelectedMount.itemID then
				local item = Item:CreateFromItemID(mounts.config.broomSelectedMount.itemID)
				item:ContinueOnItemLoad(function()
					self.magicBroomCombobox:ddSetSelectedText(item:GetItemName(), item:GetItemIcon())
				end)
			end
		else
			self.magicBroomCombobox:ddSetSelectedText(L["Random available mount"], randomMountIcon)
		end
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
		self.coloredMountNames:SetChecked(mounts.config.coloredMountNames)
		self.arrowButtons:SetChecked(mounts.config.arrowButtonsBrowse)
		self.showTypeSelBtn:SetChecked(mounts.config.showTypeSelBtn)
		self.copyMountTarget:SetChecked(mounts.config.copyMountTarget)
		self.openLinks:SetChecked(mounts.config.openHyperlinks)
		self.showWowheadLink:SetChecked(mounts.config.showWowheadLink)
		self.statisticCollection:SetChecked(mounts.config.statCollection)
		self.tooltipMount:SetChecked(mounts.config.tooltipMount)
		self.tooltipItems:SetChecked(mounts.config.tooltipItems)
		self.resetHelp:Enable()
		self.cancelBtn:Disable()
		self.applyBtn:Disable()
	end
	self:OnRefresh()
	self:SetScript("OnShow", self.OnRefresh)

	local function updateBtnIcon(i)
		local icon = self["summon"..i.."Icon"].icon:GetTexture()
		mounts.config["summon"..i.."Icon"] = icon
		journal.bgFrame["summon"..i].icon:SetTexture(icon)
		mounts.summonPanel["summon"..i].icon:SetTexture(icon)
	end

	-- COMMIT
	self.OnCommit = function(self)
		binding.unboundMessage:Hide()
		mounts.config.useHerbMounts = self.useHerbMounts:GetChecked()
		mounts.config.herbMountsOnZones = self.herbMountsOnZones:GetChecked()
		mounts.config.useRepairMounts = self.useRepairMounts:GetChecked()
		mounts.config.useRepairMountsDurability = tonumber(self.repairPercent:GetText()) or 0
		mounts.config.useRepairFlyable = self.repairFlyable:GetChecked()
		mounts.config.useRepairFlyableDurability = tonumber(self.repairFlyablePercent:GetText()) or 0
		mounts.config.useRepairFreeSlots = self.freeSlots:GetChecked()
		mounts.config.useRepairFreeSlotsNum = tonumber(self.freeSlotsNum:GetText()) or 0
		mounts.config.repairSelectedMount = self.repairMountsCombobox:ddGetSelectedValue()
		mounts.config.useMagicBroom = self.useMagicBroom:GetChecked()
		mounts.config.broomSelectedMount = self.magicBroomCombobox:ddGetSelectedValue()
		if self.useUnderlightAngler then
			mounts.config.useUnderlightAngler = self.useUnderlightAngler:GetChecked()
			mounts.config.autoUseUnderlightAngler = self.autoUseUnderlightAngler:GetChecked()
		end
		mounts.config.summonPetEvery = self.summonPetEvery:GetChecked()
		mounts.config.summonPetEveryN = tonumber(self.summonPetEveryN:GetText()) or 1
		mounts.config.summonPetOnlyFavorites = self.summonPetOnlyFavorites:GetChecked()
		mounts.config.noPetInRaid = self.noPetInRaid:GetChecked()
		mounts.config.noPetInGroup = self.noPetInGroup:GetChecked()
		mounts.config.coloredMountNames = self.coloredMountNames:GetChecked()
		mounts.config.arrowButtonsBrowse = self.arrowButtons:GetChecked()
		mounts.config.showTypeSelBtn = self.showTypeSelBtn:GetChecked()
		mounts.config.copyMountTarget = self.copyMountTarget:GetChecked()
		mounts.config.openHyperlinks = self.openLinks:GetChecked()
		mounts.config.showWowheadLink = self.showWowheadLink:GetChecked()
		mounts.config.statCollection = self.statisticCollection:GetChecked()
		mounts.config.tooltipMount = self.tooltipMount:GetChecked()
		mounts.config.tooltipItems = self.tooltipItems:GetChecked()

		updateBtnIcon(1)
		updateBtnIcon(2)
		binding:saveBinding()
		mounts:setHandleWaterJump(self.waterJump:GetChecked())
		mounts:setModifier(self.modifierCombobox:ddGetSelectedValue())
		mounts:UPDATE_INVENTORY_DURABILITY()
		mounts:setUsableRepairMounts()
		mounts:setHerbMount()
		ns.pets:setSummonEvery()
		journal:setScrollGridMounts(true)
		journal:setArrowSelectMount(mounts.config.arrowButtonsBrowse)
	end
end)


config:SetScript("OnHide", function()
	binding:resetBinding()
end)