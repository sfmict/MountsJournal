local addon, L = ...
local mounts = MountsJournal
local config = MountsJournalConfig
local classConfig = CreateFrame("Frame", "MountsJournalConfigClasses", InterfaceOptionsFramePanelContainer)
classConfig.name = L["Class settings"]
classConfig.parent = addon


classConfig:SetScript("OnShow", function(self)
	self.macrosConfig = mounts.config.macrosConfig
	self.charMacrosConfig = MountsJournalChar.macrosConfig
	self.secure = config.bindMount.secure

	-- ADDON INFO
	local info = classConfig:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	info:SetPoint("TOPRIGHT", -16, 16)
	info:SetTextColor(.5, .5, .5, 1)
	info:SetText(format("%s %s: %s", GetAddOnMetadata(addon, "Version"), L["author"], GetAddOnMetadata(addon, "Author")))

	-- TITLE
	local title = classConfig:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(L["Class settings"])

	-- SUBTITLE
	local subtitle = classConfig:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	self.subtitle = subtitle
	subtitle:SetHeight(30)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -8)
	subtitle:SetNonSpaceWrap(true)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetJustifyV("TOP")

	-- LEFT PANEL
	local leftPanel = CreateFrame("FRAME", nil, classConfig, "MJOptionsPanel")
	leftPanel:SetPoint("TOPLEFT", 8, -67)
	leftPanel:SetPoint("BOTTOMRIGHT", classConfig, "BOTTOMLEFT", 181, 8)

	-- CLASS BUTTONS
	local _,playerClassName = UnitClass("player")
	local firstClassFrame
	local lastClassFrame
	for i = 1, GetNumClasses() do
		local localized, className = GetClassInfo(i)
		local classColor = C_ClassColor.GetClassColor(className)
		local classFrame = CreateFrame("BUTTON", nil, classConfig, "MJClassButtonTemplate")

		if lastClassFrame then
			classFrame:SetPoint("TOPLEFT", lastClassFrame, "BOTTOMLEFT", 0, 0)
		else
			classFrame:SetPoint("TOPLEFT", leftPanel, 3, -3)
		end
		lastClassFrame = classFrame
		classFrame.key = className
		classFrame.default = self.secure:getClassMacro(className)
		classFrame.name:SetText(localized)
		classFrame.name:SetTextColor(classColor:GetRGB())
		classFrame.check:SetVertexColor(classColor:GetRGB())
		classFrame.highlight:SetVertexColor(classColor:GetRGB())
		classFrame.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[className]))
		classFrame:SetScript("OnClick", function(btn) self:classClick(btn) end)
		
		if playerClassName == className then
			firstClassFrame = classFrame
		end
	end

	-- CURRENT CHARACTER
	local classColor = C_ClassColor.GetClassColor(playerClassName)
	local classFrame = CreateFrame("BUTTON", nil, classConfig, "MJClassButtonTemplate")
	classFrame:SetPoint("TOPLEFT", lastClassFrame, "BOTTOMLEFT", 0, -20)
	classFrame.key = playerClassName
	classFrame.default = self.secure:getClassMacro(playerClassName)
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

	-- CURRENT CHARACTER ENABLE
	local charCheck = CreateFrame("CHECKBUTTON", nil, classFrame, "MJBaseCheckButtonTemplate")
	charCheck:SetPoint("RIGHT", -5, -1)
	charCheck:SetChecked(self.charMacrosConfig.enable)
	charCheck:HookScript("OnClick", function(btn)
		self.charMacrosConfig.enable = btn:GetChecked()
		self.secure:refresh()
	end)

	-- RIGHT PANEL
	local rightPanel = CreateFrame("FRAME", nil, classConfig, "MJOptionsPanel")
	self.rightPanel = rightPanel
	rightPanel:SetPoint("TOPRIGHT", -8, -67)
	rightPanel:SetPoint("BOTTOMLEFT", leftPanel, "BOTTOMRIGHT", 0, 0)

	-- RIGHT PANEL SCROLL
	local rightPanelScroll = CreateFrame("ScrollFrame", nil, rightPanel, "UIPanelScrollFrameTemplate")
	rightPanelScroll:SetPoint("TOPLEFT", rightPanel, 4, -6)
	rightPanelScroll:SetPoint("BOTTOMRIGHT", rightPanel, -26, 5)
	rightPanelScroll.ScrollBar:SetBackdrop({bgFile='interface/buttons/white8x8'})
	rightPanelScroll.ScrollBar:SetBackdropColor(0,0,0,.2)
	rightPanelScroll.child = CreateFrame("FRAME")
	rightPanelScroll.child:SetSize(1, 1)
	rightPanelScroll:SetScrollChild(rightPanelScroll.child)

	-- CLASS FEATURE
	self.classCheck = CreateFrame("CHECKBUTTON", nil, rightPanelScroll.child, "MJCheckButtonTemplate")
	self.classCheck:SetPoint("TOPLEFT", 9, -9)
	self.classCheck.Text:SetSize(365, 30)
	self.classCheck:HookScript("OnClick", function(btn)
		self.currentMacrosConfig[btn.option] = btn:GetChecked()
		self.secure:refresh()
	end)
	config:setHyperlinkTooltip(self.classCheck)

	-- MOVE FALL MACRO
	local moveFallMF = CreateFrame("FRAME", nil, rightPanelScroll.child, "MJMacroFrame")
	self.moveFallMF = moveFallMF
	self.macroEditBox = moveFallMF.scrollFrame.editBox
	moveFallMF.lable:SetText(L["HELP_MACRO_MOVE_FALL"])
	moveFallMF.enable:HookScript("OnClick", function(btn)
		self.currentMacrosConfig.macroEnable = btn:GetChecked()
		self.secure:refresh()
	end)
	moveFallMF.defaultBtn:HookScript("OnClick", function()
		self.macroEditBox:SetText(self.rightPanel.currentBtn.default)
		self.macroEditBox:ClearFocus()
		self.currentMacrosConfig.macro = nil
		self.secure:refresh()
	end)
	moveFallMF.cancelBtn:HookScript("OnClick", function()
		self.macroEditBox:SetText(self.currentMacrosConfig.macro or self.rightPanel.currentBtn.default)
		self.macroEditBox:ClearFocus()
	end)
	moveFallMF.saveBtn:HookScript("OnClick", function()
		self:macroSave()
		self.secure:refresh()
	end)

	-- COMBAT MACRO
	local combatMF = CreateFrame("FRAME", nil, rightPanelScroll.child, "MJMacroFrame")
	self.combatMF = combatMF
	self.combatMacroEditBox = combatMF.scrollFrame.editBox
	combatMF:SetPoint("TOPLEFT", moveFallMF, "BOTTOMLEFT", 0, -100)
	combatMF.lable:SetText(L["HELP_MACRO_COMBAT"])
	combatMF.enable:HookScript("OnClick", function(btn)
		self.currentMacrosConfig.combatMacroEnable = btn:GetChecked()
		self.secure:refresh()
	end)
	combatMF.defaultBtn:HookScript("OnClick", function()
		self.combatMacroEditBox:SetText(self.rightPanel.currentBtn.default)
		self.combatMacroEditBox:ClearFocus()
		self.currentMacrosConfig.combatMacro = nil
		self.secure:refresh()
	end)
	combatMF.cancelBtn:HookScript("OnClick", function()
		self.combatMacroEditBox:SetText(self.currentMacrosConfig.combatMacro or self.rightPanel.currentBtn.default)
		self.combatMacroEditBox:ClearFocus()
	end)
	combatMF.saveBtn:HookScript("OnClick", function()
		self:combatMacroSave()
		self.secure:refresh()
	end)

	firstClassFrame:Click()
	classConfig:SetScript("OnShow", function() end)
end)


do
	local classOptions = {
		DEATHKNIGHT = {
			key = "usePathOfFrost",
			hlink = GetSpellLink(3714),
		},
		SHAMAN = {
			key = "useWaterWalking",
			hlink = GetSpellLink(546),
		},
		DRUID = {
			key ="useMacroAlways",
		},
	}

	function classConfig:showClassSettings(btn)
		if self.rightPanel.currentBtn then
			self.rightPanel.currentBtn.check:Hide()
		end
		self.subtitle:SetText(format("%s: %s %s", L["Settings"], btn.name:GetText(), btn.description or ""))
		self.rightPanel.currentBtn = btn
		btn.check:Show()

		self.moveFallMF.enable:SetChecked(self.currentMacrosConfig.macroEnable)
		self.macroEditBox:SetText(self.currentMacrosConfig.macro or btn.default)
		self.combatMF.enable:SetChecked(self.currentMacrosConfig.combatMacroEnable)
		self.combatMacroEditBox:SetText(self.currentMacrosConfig.combatMacro or btn.default)

		if classOptions[btn.key] then
			local classOption = classOptions[btn.key]
			self.classCheck.option = classOption.key
			self.classCheck:SetChecked(self.currentMacrosConfig[classOption.key])
			self.classCheck.Text:SetText(format(L[strupper(btn.key.."_"..classOption.key)], classOption.hlink))
			self.classCheck:Show()
			self.moveFallMF:SetPoint("TOPLEFT", self.classCheck, "BOTTOMLEFT", 0, -70)
		else
			self.classCheck:Hide()
			self.moveFallMF:SetPoint("TOPLEFT", 9, -60)
		end
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end
end


function classConfig:classClick(btn)
	if not self.macrosConfig[btn.key] then
		self.macrosConfig[btn.key] = {}
	end
	self.currentMacrosConfig = self.macrosConfig[btn.key]

	self:showClassSettings(btn)
end


function classConfig:macroSave()
	local text = self.macroEditBox:GetText()
	if text == self.rightPanel.currentBtn.default then
		self.currentMacrosConfig.macro = nil
	else
		self.currentMacrosConfig.macro = text
	end
	self.macroEditBox:ClearFocus()
end


function classConfig:combatMacroSave()
	local text = self.combatMacroEditBox:GetText()
	if text == self.rightPanel.currentBtn.default then
		self.currentMacrosConfig.combatMacro = nil
	else
		self.currentMacrosConfig.combatMacro = text
	end
	self.combatMacroEditBox:ClearFocus()
end


classConfig.okay = function(self)
	self:macroSave()
	self:combatMacroSave()
	self.secure:refresh()
end


InterfaceOptions_AddCategory(classConfig)