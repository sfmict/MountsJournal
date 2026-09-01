local addon, ns = ...
local L, util, mounts, binding, journal = ns.L, ns.util, ns.mounts, ns.binding, ns.journal
local specificDB = ns.specificDB
local config = CreateFrame("FRAME", "MountsJournalConfig")
ns.config = config
config:Hide()


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

	-- GROUP
	local grx, gry = 6, -8
	local function createGroupPanel(parent, anchorFrame, x, y)
		local group = CreateFrame("FRAME", nil, parent, "MJOptionsPanel")
		if anchorFrame then
			group:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", x, y)
		else
			group:SetPoint("TOPLEFT", x, y)
		end
		group:SetPoint("RIGHT", parent:GetParent(), 0, 0)
		return group
	end

	local function setGroupHeight(group, lastFrame)
		group:SetHeight(group:GetTop() - lastFrame:GetBottom() + (lastFrame:IsObjectType("CheckButton") and 8 or 11))
	end

	-- CHECKBOX
	local function createCheckbox(parent, text, tooltipText, tooltipRequirement)
		local f = CreateFrame("CheckButton", nil, parent, "MJCheckButtonTemplate")
		f.Text:SetText(text)
		f.tooltipText = tooltipText
		f.tooltipRequirement = tooltipRequirement
		f:HookScript("OnClick",  enableBtns)
		return f
	end

	-- CHECKBOX CHILD
	local function createCheckboxChild(parent, text, tooltipText, tooltipRequirement, checkFunc)
		local f = util.createCheckboxChild(text, parent)
		f.tooltipText = tooltipText
		f.tooltipRequirement = tooltipRequirement
		f.checkFunc = checkFunc
		f:HookScript("OnClick", enableBtns)
		return f
	end

	-- NUMBERBOX
	local createNumberBox do
		local onTextChanged = function(editBox, userInput)
			local value = tonumber(editBox:GetText())
			if value then
				if value < editBox.min then value = editBox.min
				elseif value > editBox.max then value = editBox.max end
				editBox.defValue = value
				if userInput then enableBtns() end
			end
		end
		local onEnterPressed = function(editBox)
			local value = tonumber(editBox:GetText()) or editBox.min
			if value < editBox.min then editBox:SetNumber(editBox.min)
			elseif value > editBox.max then editBox:SetNumber(editBox.max) end
			editBox.defValue = value
			editBox:ClearFocus()
			enableBtns()
		end
		local onEditFocusLost = function(editBox)
			editBox:SetNumber(editBox.defValue or editBox.min)
		end
		local onMouseWheel = function(editBox, delta)
			if editBox:IsEnabled() then
				local value = (tonumber(editBox:GetText()) or editBox.min) + delta
				if value >= editBox.min and value <= editBox.max then
					editBox:SetNumber(value)
					enableBtns()
				end
			end
		end

		function createNumberBox(parent, min, max)
			local f = CreateFrame("Editbox", nil, parent, "MJNumberTextBox")
			f.min = min
			f.max = max
			f:SetScript("OnTextChanged", onTextChanged)
			f:SetScript("OnEnterPressed", onEnterPressed)
			f:SetScript("OnEditFocusLost", onEditFocusLost)
			f:SetScript("OnMouseWheel", onMouseWheel)
			return f
		end
	end

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
	self.waterJump = createCheckbox(self.leftPanel, L["Handle a jump in water"], L["Handle a jump in water"], L["WaterJumpDescription"])
	self.waterJump:SetPoint("TOPLEFT", self.leftPanel, 13, -15)

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
	self.bindSummon1Key1, self.bindSummon1Key2 = binding:createBindingButtons(util.secureButtonNameMount, self.leftPanel, ("%s %s %d"):format(ns.addon, SUMMONS, 1))
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
	self.bindSummon2Key1, self.bindSummon2Key2 = binding:createBindingButtons(util.secureButtonNameSecondMount, self.leftPanel, ("%s %s %d"):format(ns.addon, SUMMONS, 2))
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

	do -- HERB GROUP
		self.herbGroup = createGroupPanel(self.rightPanelScroll.child, nil, 3, -2)

		-- USE HERBALISM MOUNTS
		self.useHerbMounts = createCheckbox(self.herbGroup, L["UseHerbMounts"], L["UseHerbMounts"], L["UseHerbMountsDescription"])
		self.useHerbMounts:SetPoint("TOPLEFT", self.herbGroup, grx, gry)

		-- USE HERBALISM MOUNTS ON HERBALISM ZONES
		self.herbMountsOnZones = createCheckboxChild(self.useHerbMounts, L["UseHerbMountsOnZones"], L["UseHerbMountsOnZones"], L["UseHerbMountsDescription"], function()
			return mounts.config.herbMountsOnZones
		end)

		setGroupHeight(self.herbGroup, self.herbMountsOnZones)
	end

	do -- REPAIR GROUP
		self.repairGroup = createGroupPanel(self.rightPanelScroll.child, self.herbGroup, 0, -8)

		-- USE REPAIR MOUNTS
		self.useRepairMounts = createCheckbox(self.repairGroup, L["If item durability is less than"], L["If item durability is less than"], L["UseRepairMountsDescription"])
		self.useRepairMounts:SetPoint("TOPLEFT", self.repairGroup, grx, gry)

		-- editbox
		self.repairPercent = createNumberBox(self.repairGroup, 0, 100)
		self.repairPercent:SetPoint("LEFT", self.useRepairMounts.Text, "RIGHT", 3, 0)
		util.setCheckboxChild(self.useRepairMounts, self.repairPercent)

		-- text
		self.repairPercentText = self.repairPercent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		self.repairPercentText:SetPoint("LEFT", self.repairPercent, "RIGHT", 3, 0)
		self.repairPercentText:SetText("%")

		-- USE REPAIR MOUNTS IN FLYABLE ZONES
		self.repairFlyable = createCheckboxChild(self.useRepairMounts, L["In flyable zones"], L["In flyable zones"], L["UseRepairMountsDescription"])

		-- editbox
		self.repairFlyablePercent = createNumberBox(self.repairGroup, 0, 100)
		self.repairFlyablePercent:SetPoint("LEFT", self.repairFlyable.Text, "RIGHT", 3, 0)
		util.setCheckboxChild(self.repairFlyable, self.repairFlyablePercent)

		-- text
		self.repairFlyablePercentText = self.repairPercent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		self.repairFlyablePercentText:SetPoint("LEFT", self.repairFlyablePercent, "RIGHT", 3, 0)
		self.repairFlyablePercentText:SetText("%")

		-- FREE SLOTS NUM
		self.freeSlots = createCheckbox(self.repairGroup, L["If the number of free slots in bags is less"])
		self.freeSlots:SetPoint("TOPLEFT", self.repairFlyable, "BOTTOMLEFT", -20, -3)
		-- self.freeSlots.Text:SetPoint("RIGHT", self.repairGroup, -37, 0) -- width isn't redered correctly
		self.freeSlots.Text:SetWidth(264)

		-- editbox
		self.freeSlotsNum = createNumberBox(self.repairGroup, 1, 999)
		self.freeSlotsNum:SetPoint("LEFT", self.freeSlots.Text, self.freeSlots.Text:GetWrappedWidth() + 3, 0)
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

		setGroupHeight(self.repairGroup, self.repairMountsCombobox)
	end

	do -- MAGIC BROOM GROUP
		self.magicBroomGroup = createGroupPanel(self.rightPanelScroll.child, self.repairGroup, 0, -8)

		-- USE MAGIC BROOM
		self.useMagicBroom = createCheckbox(self.magicBroomGroup, L["UseHallowsEndMounts"], L["UseHallowsEndMounts"], L["UseHallowsEndMountsDescription"])
		self.useMagicBroom:SetPoint("TOPLEFT", self.magicBroomGroup, grx, gry)
		self.useMagicBroom.Text:SetPoint("RIGHT", self.magicBroomGroup, -4, 0)

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

		setGroupHeight(self.magicBroomGroup, self.magicBroomCombobox)
	end

	do -- USE UNDERLIGHT ANGLER
		if C_Item.DoesItemExistByID(133755) then
			self.underlightAnglerGroup = createGroupPanel(self.rightPanelScroll.child, self.magicBroomGroup, 0, -8)

			self.useUnderlightAngler = createCheckbox(self.underlightAnglerGroup, nil, nil, L["UseUnderlightAnglerDescription"])
			self.useUnderlightAngler:SetPoint("TOPLEFT", self.underlightAnglerGroup, grx, gry)
			local underlightAngler = Item:CreateFromItemID(133755)
			underlightAngler:ContinueOnItemLoad(function()
				self.useUnderlightAngler.Text:SetText(L["Use %s"]:format(underlightAngler:GetItemLink()))
				self.useUnderlightAngler.tooltipText = L["Use %s"]:format(underlightAngler:GetItemName())
			end)
			util.setHyperlinkTooltip(self.useUnderlightAngler)

			-- AUTO USE UNDERLIGHT ANGLER
			self.autoUseUnderlightAngler = createCheckboxChild(self.useUnderlightAngler, L["Use automatically"])

			setGroupHeight(self.underlightAnglerGroup, self.autoUseUnderlightAngler)
		end
	end

	do -- PET GROUP
		self.petGroup = createGroupPanel(self.rightPanelScroll.child, self.underlightAnglerGroup or self.magicBroomGroup, 0, -8)

		-- SUMMON PET EVERY N MINUTES
		self.summonPetEvery = createCheckbox(self.petGroup, L["Summon a pet every"])
		self.summonPetEvery:SetPoint("TOPLEFT", self.petGroup, grx, gry)

		-- count
		self.summonPetEveryN = createNumberBox(self.petGroup, 1, 999)
		self.summonPetEveryN:SetPoint("LEFT", self.summonPetEvery.Text, "RIGHT", 3, 0)
		util.setCheckboxChild(self.summonPetEvery, self.summonPetEveryN)

		-- minutes
		self.summonPetMinutes = self.summonPetEveryN:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		self.summonPetMinutes:SetPoint("LEFT", self.summonPetEveryN, "RIGHT", 3, 0)
		self.summonPetMinutes:SetText(L["min"])

		-- SUMMON ONLY FAVORITES
		self.summonPetOnlyFavorites = createCheckboxChild(self.summonPetEvery, L["Summon only favorites"], nil, nil, function()
			return mounts.config.summonPetOnlyFavorites
		end)

		-- NO PET IN RAID
		self.noPetInRaid = createCheckbox(self.petGroup, L["NoPetInRaid"])
		self.noPetInRaid:SetPoint("TOPLEFT", self.summonPetOnlyFavorites, "BOTTOMLEFT", -20, -3)
		self.noPetInRaid.Text:SetPoint("RIGHT", self.petGroup, -4, 0)

		-- NO PET IN GROUP
		self.noPetInGroup = createCheckbox(self.petGroup, L["NoPetInGroup"])
		self.noPetInGroup:SetPoint("TOPLEFT", self.noPetInRaid, "BOTTOMLEFT", 0, -3)
		self.noPetInGroup.Text:SetPoint("RIGHT", self.petGroup, -4, 0)

		setGroupHeight(self.petGroup, self.noPetInGroup)
	end

	do -- MOUNT LIST GROUP
		self.mountListGroup = createGroupPanel(self.rightPanelScroll.child, self.petGroup, 0, -8)

		-- COLORIZED NAMES
		self.coloredMountNames = createCheckbox(self.mountListGroup, L["Colored mount names by rarity"])
		self.coloredMountNames:SetPoint("TOPLEFT", self.mountListGroup, grx, gry)
		self.coloredMountNames.Text:SetPoint("RIGHT", self.mountListGroup, -4, 0)

		-- EXPANSION ART
		self.expansionArt = createCheckbox(self.mountListGroup, L["Show mount expansion art"], L["Show mount expansion art"], L["MOUNT_EXPANSION_ART_DESCRIPTION"])
		self.expansionArt:SetPoint("TOPLEFT", self.coloredMountNames, "BOTTOMLEFT", 0, -3)
		self.expansionArt.Text:SetPoint("RIGHT", self.mountListGroup, -4, 0)

		-- ARROW BUTTONS
		self.arrowButtons = createCheckbox(self.mountListGroup, L["Enable arrow buttons to browse mounts"])
		self.arrowButtons:SetPoint("TOPLEFT", self.expansionArt, "BOTTOMLEFT", 0, -3)
		self.arrowButtons.Text:SetPoint("RIGHT", self.mountListGroup, -4, 0)

		-- TYPE SELECTION BUTTONS
		self.showTypeSelBtn = createCheckbox(self.mountListGroup, L["Show mount type selection buttons"])
		self.showTypeSelBtn:SetPoint("TOPLEFT", self.arrowButtons, "BOTTOMLEFT", 0, -3)
		self.showTypeSelBtn.Text:SetPoint("RIGHT", self.mountListGroup, -4, 0)

		setGroupHeight(self.mountListGroup, self.showTypeSelBtn)
	end

	do -- SUMMON MOUNT GROUP
		self.summonGroup = createGroupPanel(self.rightPanelScroll.child, self.mountListGroup, 0, -8)

		-- COPY MOUNT TARGET
		self.copyMountTarget = createCheckbox(self.summonGroup, L["CopyMountTarget"])
		self.copyMountTarget:SetPoint("TOPLEFT", self.summonGroup, grx, gry)
		self.copyMountTarget.Text:SetPoint("RIGHT", self.summonGroup, -4, 0)

		-- RANDOM MOUNT EVERY LABEL
		self.randomMountEveryLabel = self.summonGroup:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		self.randomMountEveryLabel:SetPoint("TOPLEFT", self.copyMountTarget, "BOTTOMLEFT", 7, -6)
		self.randomMountEveryLabel:SetText(L["Change random mount"]..":")
		self.summonGroup:SetHeight(self.summonGroup:GetHeight() + self.randomMountEveryLabel:GetHeight())

		-- RANDOM MOUNT EVERY
		self.randomMountEvery = lsfdd:CreateModernButtonOriginal(self.summonGroup, 230)
		self.randomMountEvery:SetPoint("TOPLEFT", self.randomMountEveryLabel, "BOTTOMLEFT", -5, -2)
		self.randomMountEvery:ddSetDisplayMode(addon)
		self.randomMountEvery.getValueText = function(value)
			if value == 0 then return L["On each summon"]
			elseif value == 30 then return L["Every %s sec"]:format(value)
			else return L["Every %s min"]:format(value / 60) end
		end
		self.randomMountEvery:ddSetInitFunc(function(dd, level)
			local info = {}

			info.checked = function(btn) return dd:ddGetSelectedValue() == btn.value end
			info.func = function(btn)
				dd:ddSetSelectedValue(btn.value)
				enableBtns()
			end

			for i, v in ipairs({0,.5,1,3,5,10,15,20,25,30}) do
				info.value = v * 60
				info.text = dd.getValueText(info.value)
				dd:ddAddButton(info, level)
			end
		end)

		setGroupHeight(self.summonGroup, self.randomMountEvery)
	end

	-- OPEN HYPERLINKS
	local dressUpMod = ("-"):split(GetModifiedClick("DRESSUP"))
	local chatLinkMod = ("-"):split(GetModifiedClick("CHATLINK"))
	self.openLinks = createCheckbox(self.rightPanelScroll.child, L["Open links in %s"]:format(ns.addon), L["Open links in %s"]:format(ns.addon), ("%s+%s %s\n%s+%s+%s %s"):format(dressUpMod, L["Click opens in"], ns.addon, dressUpMod, chatLinkMod, L["Click opens in"], DRESSUP_FRAME))
	self.openLinks:SetPoint("TOPLEFT", self.summonGroup, "BOTTOMLEFT", grx, -10)
	self.openLinks.Text:SetPoint("RIGHT", self.rightPanelScroll)

	-- WOWHEAD LINK SHOW
	self.showWowheadLink = createCheckbox(self.rightPanelScroll.child, L["Show wowhead link in mount preview"])
	self.showWowheadLink:SetPoint("TOPLEFT", self.openLinks, "BOTTOMLEFT", 0, -15)
	self.showWowheadLink.Text:SetPoint("RIGHT", self.rightPanelScroll)

	-- STATISTIC COLLECTION
	self.statisticCollection = createCheckbox(self.rightPanelScroll.child, L["Enable statistics collection"], L["Enable statistics collection"], L["STATISTICS_DESCRIPTION"])
	self.statisticCollection:SetPoint("TOPLEFT", self.showWowheadLink, "BOTTOMLEFT", 0, -15)
	self.statisticCollection.Text:SetPoint("RIGHT", self.rightPanelScroll)

	do -- TOOLTIP GROUP
		self.tooltipGroup = createGroupPanel(self.rightPanelScroll.child, self.statisticCollection, -grx, -10)

		-- TOOLTIP MOUNT
		self.tooltipMount = createCheckbox(self.tooltipGroup, L["Show mount in unit tooltip"])
		self.tooltipMount:SetPoint("TOPLEFT", self.tooltipGroup, grx, gry)
		self.tooltipMount.Text:SetPoint("RIGHT", self.tooltipGroup, -4, 0)

		-- TOOLTIP ITEMS
		self.tooltipItems = createCheckbox(self.tooltipGroup, L["Add information to item tooltip"])
		self.tooltipItems:SetPoint("TOPLEFT", self.tooltipMount, "BOTTOMLEFT", 0, -3)
		self.tooltipItems.Text:SetPoint("RIGHT", self.tooltipGroup, -4, 0)

		setGroupHeight(self.tooltipGroup, self.tooltipItems)
	end

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

	-- CHILD
	self.rightPanelScroll.child:SetHeight(self.rightPanelScroll.child:GetTop() - self.resetHelp:GetBottom() + 5)

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
		self.expansionArt:SetChecked(mounts.config.showExpansionArt)
		self.arrowButtons:SetChecked(mounts.config.arrowButtonsBrowse)
		self.showTypeSelBtn:SetChecked(mounts.config.showTypeSelBtn)
		self.copyMountTarget:SetChecked(mounts.config.copyMountTarget)
		self.randomMountEvery:ddSetSelectedValue(mounts.config.randomMountEvery)
		self.randomMountEvery:ddSetSelectedText(self.randomMountEvery.getValueText(mounts.config.randomMountEvery))
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
		mounts:event("UPDATE_SUMMON_ICON", i, icon)
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
		mounts.config.showExpansionArt = self.expansionArt:GetChecked()
		mounts.config.arrowButtonsBrowse = self.arrowButtons:GetChecked()
		mounts.config.showTypeSelBtn = self.showTypeSelBtn:GetChecked()
		mounts.config.copyMountTarget = self.copyMountTarget:GetChecked()
		mounts.config.randomMountEvery = self.randomMountEvery:ddGetSelectedValue()
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