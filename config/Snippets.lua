local addon, ns = ...
local L, util, codeEdit, dataDialog = ns.L, ns.util, ns.codeEdit, ns.dataDialog
local strcmputf8i = strcmputf8i
local snippets = CreateFrame("FRAME", "MountsJournalSnippets", ns.ruleConfig, "DefaultPanelTemplate")
ns.snippets = snippets
snippets:Hide()


snippets:SetScript("OnShow", function(self)
	self:SetScript("OnShow", function(self) end)

	self:SetWidth(300)
	self:SetPoint("TOPLEFT", ns.journal.bgFrame, "TOPRIGHT", -4, 0)
	self:SetPoint("BOTTOMLEFT", ns.journal.bgFrame, "BOTTOMRIGHT", -4, 0)
	self:EnableMouse(true)
	self:SetTitle(L["Code Snippets"])

	self.snippets = ns.mounts.globalDB.snippets
	self.newName = L["Snippet"].."(%d)"

	-- DIALOGS
	local function ruleSetExistsAccept(popup)
		if not popup then return end
		popup:Hide()
		codeEdit:nameFocus()
	end
	StaticPopupDialogs[util.addonName.."SNIPPET_EXISTS"] = {
		text = addon..": "..L["A snippet with the same name exists."],
		button1 = OKAY,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = ruleSetExistsAccept,
		OnCancel = ruleSetExistsAccept,
	}
	StaticPopupDialogs[util.addonName.."DELETE_SNIPPET"] = {
		text = addon..": "..L["Are you sure you want to delete snippet %s?"],
		button1 = DELETE,
		button2 = CANCEL,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = function(self, cb) cb() end,
	}

	-- ADD BUTTON
	self.addSnipBtn = CreateFrame("BUTTON", nil, self, "UIPanelButtonTemplate")
	self.addSnipBtn:SetHeight(24)
	self.addSnipBtn:SetPoint("TOP", 0, -24)
	self.addSnipBtn:SetPoint("LEFT", 8, 0)
	self.addSnipBtn:SetPoint("RIGHT", -3, 0)
	self.addSnipBtn:SetText(L["Add Snippet"])
	self.addSnipBtn:SetScript("OnClick", function()
		codeEdit:open(self:getNextName(), nil, function(_, ...)
			return self:add(...)
		end)
		codeEdit:nameFocus()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	-- IMPORT BUTTON
	self.importBtn = CreateFrame("BUTTON", nil, self, "UIPanelButtonTemplate")
	self.importBtn:SetHeight(24)
	self.importBtn:SetPoint("TOPLEFT", self.addSnipBtn, "BOTTOMLEFT", 0, -2)
	self.importBtn:SetPoint("TOPRIGHT", self.addSnipBtn, "BOTTOMRIGHT", 0, -2)
	self.importBtn:SetText(L["Import Snippet"])
	self.importBtn:SetScript("OnClick", function()
		self:import()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	-- SEARCH
	self.searchBox = CreateFrame("EditBox", nil, self, "SearchBoxTemplate")
	self.searchBox:SetPoint("TOP", self.importBtn, "BOTTOM", 0, -2)
	self.searchBox:SetPoint("LEFT", 14, 0)
	self.searchBox:SetPoint("RIGHT", -4, 0)
	self.searchBox:SetHeight(20)
	self.searchBox:SetMaxLetters(40)
	self.searchBox:SetScript("OnTextChanged", function(searchBox, userInput)
		SearchBoxTemplate_OnTextChanged(searchBox)
		self:updateFilters()
	end)

	-- BACKGROUND
	self.bg = CreateFrame("FRAME", nil, self, "MJOptionBackgroundTemplate")
	self.bg:SetPoint("TOP", self.searchBox, "BOTTOM", 0, -2)
	self.bg:SetPoint("LEFT", 9, 0)
	self.bg:SetPoint("BOTTOMRIGHT", -20, 6)

	-- SNIPEET CLICKS
	local function click(btn, button)
		if button == "LeftButton" then
			if IsShiftKeyDown() then
				util.insertChatLink("Snippet", btn.sName)
			else
				codeEdit:open(btn.sName, self.snippets[btn.sName], function(...)
					return self:edit(...)
				end)
				codeEdit:codeFocus()
			end
		else
			self.snipMenu:ddToggle(1, btn, "cursor")
		end
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end

	local function removeClick(btn)
		self:remove(btn:GetParent().sName)
	end

	local function onAcqure(owner, btn, data, new)
		if new then
			btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			btn:SetScript("OnClick", click)
			btn.remove:SetScript("OnClick", removeClick)
		end
	end

	-- SCROLL
	self.scrollBox = CreateFrame("FRAME", nil, self, "WowScrollBoxList")
	self.scrollBox:SetPoint("TOPLEFT", self.bg, 10, -8)
	self.scrollBox:SetPoint("BOTTOMRIGHT", self.bg, -10, 8)

	self.scrollBar = CreateFrame("EventFrame", nil, self, "MinimalScrollBar")
	self.scrollBar:SetPoint("TOPLEFT", self.bg, "TOPRIGHT", 3, -4)
	self.scrollBar:SetPoint("BOTTOMLEFT", self.bg, "BOTTOMRIGHT", 3, 2)

	self.view = CreateScrollBoxListLinearView(3, 3, 0, 0, 4)
	self.view:SetElementInitializer("MJSnippetListPanelTemplate", function(...) self:btnInit(...) end)
	self.view:RegisterCallback(self.view.Event.OnAcquiredFrame, onAcqure, self)
	ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.scrollBar, self.view)

	-- SNIPPET MENU
	self.snipMenu = LibStub("LibSFDropDown-1.5"):SetMixin({})
	self.snipMenu:ddSetDisplayMode(addon)
	self.snipMenu:ddHideWhenButtonHidden(self.scrollBox)

	self.snipMenu:ddSetInitFunc(function(dd, level, btn)
		local info = {}
		info.notCheckable = true

		info.text = L["Export"]
		info.func = function() self:export(btn.sName) end
		dd:ddAddButton(info, level)

		info.text = DELETE
		info.func = function() self:remove(btn.sName) end
		dd:ddAddButton(info, level)

		info.func = nil
		info.text = CANCEL
		dd:ddAddButton(info, level)
	end)

	-- INIT
	self:updateFilters()
end)


function snippets:getNextName()
	local i = 1
	while true do
		local name = self.newName:format(i)
		if not self.snippets[name] then return name end
		i = i + 1
	end
end


do
	local function updateSpaces(s)
		local str = "\n"
		for i = 1, #s:gsub(" *\n", "") / ns.mounts.globalDB.editorTabSpaces do
			str = str.." "
		end
		return str
	end
	local function minimize(code)
		return code:gsub(" *\n *", updateSpaces)
	end


	function snippets:add(name, code)
		if self.snippets[name] then
			StaticPopup_Show(util.addonName.."SNIPPET_EXISTS")
			return
		end
		self.snippets[name] = minimize(code)
		self:updateFilters()
		ns.mounts:event("RULE_LIST_UPDATE")
		return true
	end


	function snippets:edit(oldName, name, code)
		if oldName ~= name then
			if self.snippets[name] then
				StaticPopup_Show(util.addonName.."SNIPPET_EXISTS")
				return
			end
			self.snippets[oldName] = nil
			for _, ruleSet in ipairs(ns.macroFrame.ruleSetConfig) do
				for _, rules in ipairs(ruleSet) do
					for _, rule in ipairs(rules) do
						for _, cond in ipairs(rule) do
							if cond[2] == "snip" and cond[3] == oldName then
								cond[3] = name
							end
						end
					end
				end
			end
			ns.macroFrame:setRuleFuncs()
		end
		ns.macroFrame:resetSnippet(oldName)
		self.snippets[name] = minimize(code)
		self:updateFilters()
		ns.mounts:event("RULE_LIST_UPDATE")
		return true
	end
end


function snippets:remove(name)
	StaticPopup_Show(util.addonName.."DELETE_SNIPPET", NORMAL_FONT_COLOR:WrapTextInColorCode(name), nil, function()
		ns.macroFrame:resetSnippet(name)
		self.snippets[name] = nil
		self:updateFilters()
		ns.mounts:event("RULE_LIST_UPDATE")
	end)
end


function snippets:export(name)
	local snippet = self.snippets[name]
	if not snippet then return end
	dataDialog:open({
		type = "export",
		data = {type = "snippet", name = name, code = snippet}
	})
end


function snippets:import()
	dataDialog:open({
		type = "import",
		valid = function(data)
			if data.type ~= "snippet"
			or type(data.name) ~= "string"
			or type(data.code) ~= "string"
			then return end
			util.openJournalTab(1, 3)
			if not ns.ruleConfig.snippetToggle:GetChecked() then ns.ruleConfig.snippetToggle:Click() end
			codeEdit:open(data.name, data.code, function(_, ...)
				return self:add(...)
			end)
			codeEdit:codeFocus()
			dataDialog:Hide()
		end,
	})
end


function snippets:dataImport(data, name, characterName)
	dataDialog:open({
		type = "dataImport",
		typeLang = L["Snippet"],
		id = name,
		fromName = characterName,
		data = data,
		save = function(code)
			util.openJournalTab(1, 3)
			if not ns.ruleConfig.snippetToggle:GetChecked() then ns.ruleConfig.snippetToggle:Click() end
			codeEdit:open(name, code, function(_, ...)
				return self:add(...)
			end)
			codeEdit:nameFocus()
			return true
		end
	})
end


function snippets:btnInit(btn, data)
	btn.sName = data[2]
	btn.name:SetText(data[2])
	btn.code:SetText(self.snippets[data[2]]:gsub("[|]", "|%1"))
end


function snippets:updateFilters()
	local text = util.cleanText(self.searchBox:GetText())
	self.dataProvider = CreateDataProvider()

	local sorted = {}
	for name in next, self.snippets do sorted[#sorted + 1] = name end
	sort(sorted, function(a, b) return strcmputf8i(a, b) < 0 end)

	for i = 1, #sorted do
		local name = sorted[i]
		if #text == 0 or name:find(text, 1, true) then
			self.dataProvider:Insert({i, name})
		end
	end

	self.scrollBox:SetDataProvider(self.dataProvider, ScrollBoxConstants.RetainScrollPosition)
end