local addon, L = ...
local aboutConfig = CreateFrame("FRAME", "MountsJournalConfigAbout", InterfaceOptionsFramePanelContainer)
aboutConfig.name = L["About"]
aboutConfig.parent = addon


aboutConfig:SetScript("OnShow", function(self)
	self:SetScript("OnShow", function(self)
		self.model:PlayAnimKit(1371)
	end)

	self.model = CreateFrame("PlayerModel", nil, self)
	self.model:SetSize(220, 220)
	self.model:SetPoint("TOPLEFT", 25, 20)
	self.model:SetDisplayInfo(55907)
	self.model:SetRotation(.4)
	self.model:PlayAnimKit(1371)

	-- ADDON NAME
	local addonName = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	addonName:SetPoint("TOP", 0, -48)
	addonName:SetText(addon)

	-- AUTHOR
	local author = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	author:SetPoint("TOPRIGHT", addonName, "BOTTOM", -2, -48)
	author:SetText(L["author"])

	local authorName = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	authorName:SetPoint("LEFT", author, "RIGHT", 4, 0)
	authorName:SetText(GetAddOnMetadata(addon, "Author"))

	-- VERSION
	local versionText = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	versionText:SetPoint("TOPRIGHT", author, "BOTTOMRIGHT", 0, -8)
	versionText:SetText(GAME_VERSION_LABEL)

	local version = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	version:SetPoint("LEFT", versionText, "RIGHT", 4, 0)
	version:SetText(GetAddOnMetadata(addon, "Version"))

	-- HELP TRANSLATION
	local helpText = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	helpText:SetPoint("TOP", version, "BOTTOM", 0, -48)
	helpText:SetPoint("LEFT", 32, 0)
	helpText:SetText(L["Help with translation of %s. Thanks."]:format(addon))

	local link = "https://www.curseforge.com/wow/addons/mountsjournal/localization"
	local editbox = CreateFrame("Editbox", nil, self)
	editbox:SetAutoFocus(false)
	editbox:SetAltArrowKeyMode(true)
	editbox:SetFontObject("GameFontHighlight")
	editbox:SetSize(410, 20)
	editbox:SetPoint("TOPLEFT", helpText, "BOTTOMLEFT", 8, 0)
	editbox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
	editbox:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)
	editbox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	editbox:SetScript("OnTextChanged", function(self)
		self:SetText(link)
		self:SetCursorPosition(0)
		if self:HasFocus() then self:HighlightText() end
	end)

	-- TRANSLATORS
	local translators = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	translators:SetPoint("TOPLEFT", helpText, "BOTTOMLEFT", 0, -80)
	translators:SetText(L["Localization Translators:"])


	local langs = {
		{"deDE", "Flammenengel92"},
		{"zhTW", "BNS333"},
	}

	local list = {}
	for _, l in ipairs(langs) do
		local str = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		if #list > 0 then
			str:SetPoint("TOPLEFT", list[#list], "BOTTOMLEFT", 0, -10)
		else
			str:SetPoint("TOP", translators, "BOTTOM", 0, -16)
			str:SetPoint("LEFT", 96, 0)
			str:SetPoint("RIGHT", -96, 0)
		end
		str:SetJustifyH("LEFT")
		str:SetText(("|cff82c5ff%s:|r |cffffff9a%s|r"):format(l[1], l[2]))
		tinsert(list, str)
	end
end)


InterfaceOptions_AddCategory(aboutConfig)