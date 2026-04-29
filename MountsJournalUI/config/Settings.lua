local addon, ns = ...
local L = ns.L


ns.journal:on("MODULES_INIT", function(journal)
	local bg, activeContent = journal.bgFrame.settingsBackground

	-- VERSION
	local aver = bg:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	aver:SetPoint("TOPRIGHT", -40, 15)
	aver:SetTextColor(.5, .5, .5, 1)
	aver:SetText(C_AddOns.GetAddOnMetadata(addon, "Version"))
	ns.util.setCopyBox(aver)

	-- WOW VERSION
	local ver, build = GetBuildInfo()
	local wver = bg:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	wver:SetPoint("BOTTOMRIGHT", aver, "TOPRIGHT", 0, 2)
	wver:SetTextColor(.5, .5, .5, 1)
	wver:SetText(ver.."."..build)
	ns.util.setCopyBox(wver)

	-- TABS
	local index = 0
	local function onTabClick(self)
		PanelTemplates_SetTab(bg, self.id)
		activeContent:Hide()
		activeContent = self.content
		activeContent:Show()
		-- aver:SetShown(self.id ~= index)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end

	local function addTab(name, content)
		index = index + 1

		local tab = CreateFrame("BUTTON", nil, bg, "PanelTopTabButtonTemplate")
		tab:SetText(name)
		tab.id = index
		tab.content = content
		tab:SetScript("OnClick", onTabClick)
		content:SetParent(tab)
		content:SetAllPoints(bg)

		if index == 1 then
			tab:SetPoint("TOPLEFT", 54, 32)
			activeContent = content
		end
	end

	addTab(L["Main"], ns.config)
	addTab(L["Class settings"], ns.classConfig)
	addTab(L["Rules"], ns.ruleConfig)
	addTab(L["About"], ns.aboutConfig)

	PanelTemplates_SetNumTabs(bg, index)
	PanelTemplates_SetTab(bg, 1)

	bg:SetScript("OnShow", function() activeContent:Show() end)
	bg:SetScript("OnHide", function() activeContent:Hide() end)
end)