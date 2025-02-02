local addon, ns = ...
local L, util, codeEdit = ns.L, ns.util, ns.codeEdit
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
	self.defSnippet = "if true then\nreturn true\nend\nreturn false"

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
		OnAccept = function(self, cb) self:Hide() cb() end,
	}

	-- ADD BUTTON
	self.addSnipBtn = CreateFrame("BUTTON", nil, self, "UIPanelButtonTemplate")
	self.addSnipBtn:SetHeight(24)
	self.addSnipBtn:SetPoint("TOP", 0, -24)
	self.addSnipBtn:SetPoint("LEFT", 8, 0)
	self.addSnipBtn:SetPoint("RIGHT", -3, 0)
	self.addSnipBtn:SetText(L["Add Snippet"])
	self.addSnipBtn:SetScript("OnClick", function()
		codeEdit:open(self:getNextName(), self.defSnippet, function(_, ...)
			return self:add(...)
		end)
		codeEdit:nameFocus()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	-- SEARCH
	self.searchBox = CreateFrame("EditBox", nil, self, "SearchBoxTemplate")
	self.searchBox:SetPoint("TOP", self.addSnipBtn, "BOTTOM", 0, -2)
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
	local function click(btn)
		codeEdit:open(btn.sName, self.snippets[btn.sName], function(...)
			return self:edit(...)
		end)
		codeEdit:codeFocus()
	end

	local function removeClick(btn)
		self:remove(btn:GetParent().sName)
	end

	local function onAcqure(owner, btn, data, new)
		if new then
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