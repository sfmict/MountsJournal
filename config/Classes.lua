local addon, L = ...
local util, mounts = MountsJournalUtil, MountsJournal
local classConfig = CreateFrame("Frame", "MountsJournalConfigClasses")
classConfig:Hide()


classConfig:SetScript("OnShow", function(self)
	self:SetScript("OnShow", nil)

	self.macrosConfig = mounts.config.macrosConfig
	self.charMacrosConfig = mounts.charDB.macrosConfig

	-- VERSION
	local ver = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	ver:SetPoint("TOPRIGHT", -40, 15)
	ver:SetTextColor(.5, .5, .5, 1)
	ver:SetJustifyH("RIGHT")
	ver:SetText(C_AddOns.GetAddOnMetadata(addon, "Version"))

	-- TITLE
	local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(L["Class settings"])

	-- SUBTITLE
	local subtitle = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	self.subtitle = subtitle
	subtitle:SetHeight(30)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -8)
	subtitle:SetNonSpaceWrap(true)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetJustifyV("TOP")

	-- LEFT PANEL
	self.leftPanel = CreateFrame("FRAME", nil, self, "MJOptionsPanel")
	self.leftPanel:SetPoint("TOPLEFT", 8, -67)
	self.leftPanel:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", 181, 8)

	-- CLASS BUTTONS
	local _, playerClassName = UnitClass("player")
	local firstClassFrame
	local lastClassFrame

	local function classClickFunc(btn)
		self.currentMacrosConfig = self.macrosConfig[btn.key]
		self:showClassSettings(btn)
	end

	for i = 1, GetNumClasses() do
		local localized, className = GetClassInfo(i)
		local classColor = C_ClassColor.GetClassColor(className)
		local classFrame = CreateFrame("BUTTON", nil, self.leftPanel, "MJClassButtonTemplate")

		if lastClassFrame then
			classFrame:SetPoint("TOPLEFT", lastClassFrame, "BOTTOMLEFT", 0, 0)
		else
			classFrame:SetPoint("TOPLEFT", self.leftPanel, 3, -3)
		end
		lastClassFrame = classFrame
		classFrame.key = className
		classFrame.default = util.getClassMacro(className, function()
			classFrame.default = util.getClassMacro(className)
			if self.rightPanel and self.rightPanel.currentBtn == classFrame then
				classFrame:Click()
			end
		end)
		classFrame.name:SetText(localized)
		classFrame.name:SetTextColor(classColor:GetRGB())
		classFrame.check:SetVertexColor(classColor:GetRGB())
		classFrame.highlight:SetVertexColor(classColor:GetRGB())
		classFrame.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[className]))
		classFrame:SetScript("OnClick", classClickFunc)

		if playerClassName == className then
			firstClassFrame = classFrame
		end
	end

	-- CURRENT CHARACTER
	local classColor = C_ClassColor.GetClassColor(playerClassName)
	local classFrame = CreateFrame("BUTTON", nil, self.leftPanel, "MJClassButtonTemplate")
	classFrame:SetPoint("TOPLEFT", lastClassFrame, "BOTTOMLEFT", 0, -20)
	classFrame.key = playerClassName
	classFrame.default = util.getClassMacro(playerClassName, function()
		classFrame.default = util.getClassMacro(playerClassName)
		if self.rightPanel and self.rightPanel.currentBtn == classFrame then
			classFrame:Click()
		end
	end)
	classFrame.name:SetPoint("RIGHT", -30, 0)
	classFrame.name:SetText(UnitName("player"))
	classFrame.name:SetTextColor(classColor:GetRGB())
	classFrame.description = L["CHARACTER_CLASS_DESCRIPTION"]
	classFrame.check:SetVertexColor(classColor:GetRGB())
	classFrame.highlight:SetVertexColor(classColor:GetRGB())
	classFrame.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[playerClassName]))
	classFrame:SetScript("OnClick", function(btn)
		self.currentMacrosConfig = self.charMacrosConfig
		self:showClassSettings(btn)
	end)
	if self.charMacrosConfig.enable then
		firstClassFrame = classFrame
	end

	-- CURRENT CHARACTER ENABLE
	self.charCheck = CreateFrame("CHECKBUTTON", nil, classFrame, "MJBaseCheckButtonTemplate")
	self.charCheck:SetPoint("RIGHT", -5, -1)
	self.charCheck:SetChecked(self.charMacrosConfig.enable)
	self.charCheck:HookScript("OnClick", function(btn)
		self.charMacrosConfig.enable = btn:GetChecked()
		util.refreshMacro()
	end)

	-- RIGHT PANEL
	local rightPanel = CreateFrame("FRAME", nil, self, "MJOptionsPanel")
	self.rightPanel = rightPanel
	rightPanel:SetPoint("TOPRIGHT", -8, -67)
	rightPanel:SetPoint("BOTTOMLEFT", self.leftPanel, "BOTTOMRIGHT", 0, 0)

	-- RIGHT PANEL SCROLL
	self.rightPanelScroll = CreateFrame("ScrollFrame", nil, rightPanel, "MJPanelScrollFrameTemplate")
	self.rightPanelScroll:SetPoint("TOPLEFT", rightPanel, 4, -6)
	self.rightPanelScroll:SetPoint("BOTTOMRIGHT", rightPanel, -26, 5)

	-- CLASS SLIDER FEATURE
	self.sliderPool = CreateFramePool("FRAME", self.rightPanelScroll.child, "MJSliderFrameTemplate", function(_, frame)
		frame:Hide()
		frame:ClearAllPoints()
		frame:SetPoint("RIGHT", self.rightPanelScroll, -5, 0)
		frame:SetEnabled(true)
	end)

	-- CLASS CHECKBOX FEATURE
	self.checkPool = CreateFramePool("CHECKBUTTON", self.rightPanelScroll.child, "MJCheckButtonTemplate", function(_, frame)
		frame:Hide()
		frame:ClearAllPoints()
		frame:Enable()
		if frame.childs then
			wipe(frame.childs)
		end
	end)

	-- MOVE FALL MACRO
	local moveFallMF = CreateFrame("FRAME", nil, self.rightPanelScroll.child, "MJMacroFrame")
	self.moveFallMF = moveFallMF
	self.macroEditBox = moveFallMF.editFrame
	moveFallMF:SetPoint("LEFT", 9, 0)
	moveFallMF:SetPoint("RIGHT", self.rightPanelScroll, -5, 0)
	moveFallMF.label:SetText(L["HELP_MACRO_MOVE_FALL"])
	moveFallMF.enable:HookScript("OnClick", function(btn)
		self.currentMacrosConfig.macroEnable = btn:GetChecked()
		util.refreshMacro()
	end)
	moveFallMF.defaultBtn:HookScript("OnClick", function()
		self.macroEditBox:SetText(self.rightPanel.currentBtn.default)
		self.macroEditBox:ClearFocus()
		local enable = not not self.currentMacrosConfig.macro
		moveFallMF.saveBtn:SetEnabled(enable)
		moveFallMF.cancelBtn:SetEnabled(enable)
	end)
	moveFallMF.cancelBtn:HookScript("OnClick", function()
		self.macroEditBox:SetText(self.currentMacrosConfig.macro or self.rightPanel.currentBtn.default)
		self.macroEditBox:ClearFocus()
	end)
	moveFallMF.saveBtn:HookScript("OnClick", function()
		self:macroSave()
		util.refreshMacro()
	end)

	-- COMBAT MACRO
	local combatMF = CreateFrame("FRAME", nil, self.rightPanelScroll.child, "MJMacroFrame")
	self.combatMF = combatMF
	self.combatMacroEditBox = combatMF.editFrame
	combatMF:SetPoint("TOPLEFT", moveFallMF.background, "BOTTOMLEFT", 0, -50)
	combatMF:SetPoint("RIGHT", self.rightPanelScroll, -5, 0)
	combatMF.label:SetText(L["HELP_MACRO_COMBAT"])
	combatMF.enable:HookScript("OnClick", function(btn)
		self.currentMacrosConfig.combatMacroEnable = btn:GetChecked()
		util.refreshMacro()
	end)
	combatMF.defaultBtn:HookScript("OnClick", function()
		self.combatMacroEditBox:SetText(self.rightPanel.currentBtn.default)
		self.combatMacroEditBox:ClearFocus()
		local enable = not not self.currentMacrosConfig.combatMacro
		combatMF.saveBtn:SetEnabled(enable)
		combatMF.cancelBtn:SetEnabled(enable)
	end)
	combatMF.cancelBtn:HookScript("OnClick", function()
		self.combatMacroEditBox:SetText(self.currentMacrosConfig.combatMacro or self.rightPanel.currentBtn.default)
		self.combatMacroEditBox:ClearFocus()
	end)
	combatMF.saveBtn:HookScript("OnClick", function()
		self:combatMacroSave()
		util.refreshMacro()
	end)

	firstClassFrame:Click()

	-- COMMIT
	self.OnCommit = function(self)
		self:macroSave()
		self:combatMacroSave()
		util.refreshMacro()
	end
end)


do
	local generalOptions = {
		-- {
		-- 	isShown = function()
		-- 		local class = classConfig.rightPanel.currentBtn.key
		-- 		if class ~= "PALADIN" and class ~= "SHAMAN" and class ~= "DEMONHUNTER" and class ~= "EVOKER" then
		-- 			local _,_, raceID = UnitRace("player")
		-- 			return raceID == 22
		-- 		end
		-- 	end,
		-- 	key = "useRunningWild",
		-- 	text = L["WORGEN_USERUNNINGWILD"],
		-- 	hlink = C_Spell.GetSpellLink(87840),
		-- 	childs = {
		-- 		{
		-- 			widget = "slider",
		-- 			key = "runningWildsummoningChance",
		-- 			text = L["Chance of summoning"],
		-- 			min = 1,
		-- 			max = 100,
		-- 			step = 1,
		-- 			defaultValue = 100,
		-- 		},
		-- 	},
		-- },
	}


	local classOptions = {
		PRIEST = {
			{
				key = "useLevitation",
				text = L["CLASS_USEWHENCHARACTERFALLS"],
				hlink = C_Spell.GetSpellLink(111759),
			},
		},
		DEATHKNIGHT = {
			{
				key = "usePathOfFrost",
				text = L["CLASS_USEWATERWALKINGSPELL"],
				hlink = C_Spell.GetSpellLink(3714),
				childs = {
					{
						key = "useOnlyInWaterWalkLocation",
						text = L["CLASS_USEONLYWATERWALKLOCATION"],
					},
				},
			},
		},
		SHAMAN = {
			{
				key = "useWaterWalking",
				text = L["CLASS_USEWATERWALKINGSPELL"],
				hlink = C_Spell.GetSpellLink(546),
				childs = {
					{
						key = "useOnlyInWaterWalkLocation",
						text = L["CLASS_USEONLYWATERWALKLOCATION"],
					},
				},
			},
		},
		MAGE = {
			{
				key = "useSlowFall",
				text = L["CLASS_USEWHENCHARACTERFALLS"],
				hlink = C_Spell.GetSpellLink(130),
			},
		},
		MONK = {
			{
				key = "useZenFlight",
				text = L["CLASS_USEWHENCHARACTERFALLS"],
				hlink = C_Spell.GetSpellLink(125883),
			},
		},
		DRUID = {
			{
				key = "useLastDruidForm",
				childs = {
					{
						key = "useDruidFormSpecialization",
					},
				},
			},
			{
				key = "useMacroAlways",
			},
		},
	}


	local function optionSliderOnChange(slider, value)
		classConfig.currentMacrosConfig[slider.key] = value
	end


	local function optionClick(btn)
		local isEnabled = btn:GetChecked()
		classConfig.currentMacrosConfig[btn.key] = isEnabled
		util.refreshMacro()

		if type(btn.childs) == "table" then
			for _, childOption in ipairs(btn.childs) do
				childOption:SetEnabled(isEnabled)
			end
		end
	end


	function classConfig:createOption(option, prefix, lastOptionFrame, indent)
		indent = indent or 0
		local text = (option.text or L[(prefix.."_"..option.key):upper()]):format(option.hlink)
		local yOffset = lastOptionFrame and lastOptionFrame:GetObjectType() == "Frame" and -15 or 0

		if option.widget == "slider" then
			local optionFrame = self.sliderPool:Acquire()
			optionFrame:setStep(option.step)
			optionFrame:setMinMax(option.min, option.max)
			optionFrame:setText(text)
			optionFrame:setValue(self.currentMacrosConfig[option.key] or option.defaultValue)

			if not optionFrame.key then
				optionFrame:setOnChanged(optionSliderOnChange)
			end
			optionFrame.key = option.key

			if lastOptionFrame then
				optionFrame:SetPoint("TOPLEFT", lastOptionFrame, "BOTTOMLEFT", indent, yOffset)
			else
				optionFrame:SetPoint("TOPLEFT", 9, -9)
			end
			optionFrame:Show()

			return optionFrame, 0
		else
			local optionFrame = self.checkPool:Acquire()
			optionFrame:SetChecked(self.currentMacrosConfig[option.key])
			optionFrame.Text:SetText(text)

			if not optionFrame.key then
				optionFrame.Text:SetPoint("RIGHT", self.rightPanelScroll, -5, 0)
				optionFrame:HookScript("OnClick", optionClick)
			end
			optionFrame.key = option.key

			if option.hlink and not optionFrame:GetHyperlinksEnabled() then
				util.setHyperlinkTooltip(optionFrame)
			end

			if lastOptionFrame then
				optionFrame:SetPoint("TOPLEFT", lastOptionFrame, "BOTTOMLEFT", indent, yOffset)
			else
				optionFrame:SetPoint("TOPLEFT", 9, -9)
			end
			optionFrame:Show()

			if option.childs then
				optionFrame.childs = optionFrame.childs or {}
				local isEnabled = optionFrame:GetChecked()
				lastOptionFrame, subIndent = optionFrame, 0
				for i, subOption in ipairs(option.childs) do
					lastOptionFrame, subIndent = self:createOption(subOption, prefix, lastOptionFrame, i == 1 and 20 or subIndent)
					lastOptionFrame:SetEnabled(isEnabled)
					tinsert(optionFrame.childs, lastOptionFrame)
				end
				return lastOptionFrame, subIndent - 20
			end

			return optionFrame, 0
		end
	end


	function classConfig:showClassSettings(btn)
		if self.rightPanel.currentBtn then
			self.rightPanel.currentBtn.check:Hide()
		end
		self.subtitle:SetText(("%s: %s %s"):format(L["Settings"], btn.name:GetText(), btn.description or ""))
		self.rightPanel.currentBtn = btn
		btn.check:Show()

		self.moveFallMF.enable:SetChecked(self.currentMacrosConfig.macroEnable)
		self.macroEditBox:SetText(self.currentMacrosConfig.macro or btn.default)
		self.moveFallMF.saveBtn:Disable()
		self.moveFallMF.cancelBtn:Disable()
		self.combatMF.enable:SetChecked(self.currentMacrosConfig.combatMacroEnable)
		self.combatMacroEditBox:SetText(self.currentMacrosConfig.combatMacro or btn.default)
		self.combatMF.saveBtn:Disable()
		self.combatMF.cancelBtn:Disable()

		self.sliderPool:ReleaseAll()
		self.checkPool:ReleaseAll()
		local lastOptionFrame, indent

		for _, option in ipairs(generalOptions) do
			if option.isShown() then
				lastOptionFrame, indent = self:createOption(option, btn.key, lastOptionFrame, indent)
			end
		end

		if classOptions[btn.key] then
			for _, option in ipairs(classOptions[btn.key]) do
				lastOptionFrame, indent = self:createOption(option, btn.key, lastOptionFrame, indent)
			end
		end

		if lastOptionFrame then
			self.moveFallMF:SetPoint("TOP", lastOptionFrame, "BOTTOM", 0, -24)
		else
			self.moveFallMF:SetPoint("TOP", 0, -14)
		end
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end
end


function classConfig:macroSave()
	local text = self.macroEditBox:GetEditBox():GetText()
	if text == self.rightPanel.currentBtn.default then
		self.currentMacrosConfig.macro = nil
	else
		self.currentMacrosConfig.macro = text
	end
	self.macroEditBox:ClearFocus()
end


function classConfig:combatMacroSave()
	local text = self.combatMacroEditBox:GetEditBox():GetText()
	if text == self.rightPanel.currentBtn.default then
		self.currentMacrosConfig.combatMacro = nil
	else
		self.currentMacrosConfig.combatMacro = text
	end
	self.combatMacroEditBox:ClearFocus()
end