local addon, ns = ...
local L, util, rules, conds, actions = ns.L, ns.util, ns.ruleConfig, ns.conditions, ns.actions
local ruleEditor = CreateFrame("FRAME", nil, rules)
rules.ruleEditor = ruleEditor
ruleEditor:Hide()


ruleEditor:SetScript("OnShow", function(self)
	self:EnableMouse(true)
	self:SetFrameLevel(1100)
	self:SetAllPoints()
	self:SetScript("OnKeyDown", function(self, key)
		if key == GetBindingKey("TOGGLEGAMEMENU") then
			self:Hide()
			self:SetPropagateKeyboardInput(false)
		else
			self:SetPropagateKeyboardInput(true)
		end
	end)
	self:SetScript("OnShow", function(self)
		self:EnableKeyboard(not InCombatLockdown())
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	end)
	self:GetScript("OnShow")(self)
	self:SetScript("OnHide", function(self)
		self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end)
	self:SetScript("OnEvent", function(self, event)
		if event == "PLAYER_REGEN_DISABLED" then
			self:EnableKeyboard(false)
			self.mountSelect:EnableKeyboard(false)
			self.mapSelect:EnableKeyboard(false)
		elseif event == "PLAYER_REGEN_ENABLED" then
			self:EnableKeyboard(true)
			self.mountSelect:EnableKeyboard(true)
			self.mapSelect:EnableKeyboard(true)
		end
	end)

	self.bg = self:CreateTexture(nil, "BACKGROUND")
	self.bg:SetColorTexture(.5, .5, .5, .2)
	self.bg:SetAllPoints()

	-- ADD CONDITION FRAME
	self.plusFrame = CreateFrame("BUTTON")
	self.plusFrame.bg = self.plusFrame:CreateTexture(nil, "BACKGROUND")
	self.plusFrame.bg:SetSize(38, 38)
	self.plusFrame.bg:SetPoint("CENTER")
	self.plusFrame.bg:SetTexture("interface/paperdollinfoframe/character-plus")
	self.plusFrame.bg:SetVertexColor(1, .5, .5)
	self.plusFrame.highlight = self.plusFrame:CreateTexture(nil, "HIGHLIGHT")
	self.plusFrame.highlight:SetPoint("TOPLEFT", 4, -4)
	self.plusFrame.highlight:SetPoint("BOTTOMRIGHT", -4, 4)
	self.plusFrame.highlight:SetColorTexture(.8, .6, .1, .1)
	self.plusFrame:SetScript("OnHide", self.Hide)
	self.plusFrame:SetScript("OnClick", function()
		self:addCondition()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	-- MENU
	self.menu = LibStub("LibSFDropDown-1.5"):SetMixin({})
	self.menu:ddHideWhenButtonHidden(self)
	self.menu:ddSetDisplayMode(addon)
	self.menu:ddSetInitFunc(function(dd, level, value)
		if value.custom then
			for i = 1, #value do
				dd:ddAddButton(value[i], level)
			end
		else
			local info = {list = value, listMaxSize = 30}
			dd:ddAddButton(info, level)
		end
	end)

	-- POOLS
	local function resetPoolFunc(pool, f)
		f:Hide()
		f:ClearAllPoints()
		local parent = f:GetParent()
		if parent then parent.optionValue = nil end
	end
	local function btnPoolOnHide(f)
		self.btnPool:Release(f)
	end
	local function initBtnPoolFunc(f)
		f:Hide()
		f:SetScript("OnHide", btnPoolOnHide)
	end
	self.btnPool = CreateFramePool("BUTTON", nil, "MJConditionDropDownTemplate", resetPoolFunc, false, initBtnPoolFunc)

	local function editPoolOnHide(f)
		self.editPool:Release(f)
	end
	local function initEditPoolFunc(f)
		f:Hide()
		f:SetScript("OnHide", editPoolOnHide)
	end
	self.editPool = CreateFramePool("EditBox", nil, "MJConditionEditBoxTemplate", resetPoolFunc, false, initEditPoolFunc)

	-- PANELS
	self.panel = CreateFrame("FRAME", nil, self, "MJDarkPanelTemplate")
	self.panel:SetPoint("TOPLEFT", 40, -40)
	self.panel:SetPoint("BOTTOMRIGHT", -40, 40)
	self.panel:SetBackdropColor(.1, .1, .1, .85)

	self.title = self.panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
	self.title:SetPoint("TOP", 0, -20)

	self.condText = self.panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	self.condText:SetPoint("TOPLEFT", 40, -60)
	self.condText:SetText(L["Conditions"])

	self.actionPanel = CreateFrame("FRAME", nil, self.panel, "MJActionPanelTemplate")
	self.actionPanel:SetPoint("BOTTOMLEFT", 30, 45)
	self.actionPanel:SetPoint("BOTTOMRIGHT", -30, 45)
	self.actionPanel.optionType:SetScript("OnClick", function(btn) self:openActionTypeMenu(btn) end)
	self.actionPanel.macro.editFrame:GetEditBox():HookScript("OnTextChanged", function(editBox, userInput)
		self.actionPanel.macro.limitText:SetFormattedText(editBox.CHAR_LIMIT, editBox:GetNumLetters())
		if userInput then
			local text = editBox:GetText()
			self.data.action[2] = #text > 0 and text or nil
			self:checkRule()
		end
	end)

	self.actionText = self.panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	self.actionText:SetPoint("BOTTOMLEFT", self.actionPanel, "TOPLEFT", 10, 10)
	self.actionText:SetText(L["Action"])

	self.scrollBox = CreateFrame("FRAME", nil, self.panel, "WowScrollBoxList")
	self.scrollBox:SetPoint("TOPLEFT", self.condText, "BOTTOMLEFT", -10, -10)
	self.scrollBox:SetPoint("BOTTOMLEFT", self.actionText, "TOPLEFT", -10, 15)
	self.scrollBox:SetPoint("RIGHT", -55, 0)

	self.scrollBar = CreateFrame("EventFrame", nil, self.panel, "MinimalScrollBar")
	self.scrollBar:SetPoint("TOPLEFT", self.scrollBox, "TOPRIGHT", 8, -2)
	self.scrollBar:SetPoint("BOTTOMLEFT", self.scrollBox, "BOTTOMRIGHT", 8, 0)

	self.view = CreateScrollBoxListLinearView()
	self.view:SetElementInitializer("MJConditionPanelTemplate", function(...) self:conditionButtonInit(...) end)
	ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.scrollBar, self.view)

	-- OK & CANCEL
	self.cancel, self.ok = util.createCancelOk(self.panel)
	self.cancel:SetPoint("BOTTOMRIGHT", -30, 15)

	self.cancel:SetScript("OnClick", function(btn)
		btn:GetParent():GetParent():Hide()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	self.ok:SetScript("OnClick", function(btn)
		rules:saveRule(self.order, self.data)
		btn:GetParent():GetParent():Hide()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	-- modal utils
	local function saveStatus(panel, frame)
		local status = {}
		for i = 1, frame:GetNumPoints() do
			status[i] = {frame:GetPoint(i)}
		end
		status.parent = frame:GetParent()
		status.show = frame:IsShown()
		panel.status[frame] = status

		frame:SetParent(panel)
		frame:ClearAllPoints()
		frame:Show()
	end

	local function restoreStatus(panel)
		for frame, status in next, panel.status do
			frame:ClearAllPoints()
			for i = 1, #status do
				frame:SetPoint(unpack(status[i]))
			end
			frame:SetParent(status.parent)
			frame:SetShown(status.show)
		end
	end

	-- MAP SELECT
	self.mapSelect = CreateFrame("FRAME", nil, self.panel, "MJDarkPanelTemplate")
	self.mapSelect:Hide()
	self.mapSelect:EnableMouse(true)
	self.mapSelect:SetFrameLevel(1200)
	self.mapSelect:SetAllPoints()
	self.mapSelect:SetScript("OnShow", function(panel)
		panel:EnableKeyboard(not InCombatLockdown())
		panel.status = {}

		local navBar = ns.journal.navBar
		saveStatus(panel, navBar)
		navBar:SetPoint("TOPLEFT", 15, -15)
		navBar:SetPoint("TOPRIGHT", -15, 15)
		panel.tabMapID = navBar.tabMapID
		navBar.tabMapID = panel.condData[3] or navBar.defMapID

		local worldMap = ns.journal.worldMap
		saveStatus(panel, worldMap)
		worldMap:SetPoint("TOPLEFT", navBar, "BOTTOMLEFT")
		worldMap:SetPoint("BOTTOMRIGHT", -15, 82)

		local mapControl = ns.journal.mapSettings.mapControl
		saveStatus(panel, mapControl)
		mapControl:SetPoint("TOPLEFT", worldMap, "BOTTOMLEFT")
		mapControl:SetPoint("TOPRIGHT", worldMap, "BOTTOMRIGHT")

		local currentMap = ns.journal.mapSettings.CurrentMap
		saveStatus(panel, currentMap)
		currentMap:SetPoint("LEFT", mapControl, 134, 0)
		currentMap:SetPoint("RIGHt", mapControl, -3, 0)

		local dnr = ns.journal.mapSettings.dnr
		saveStatus(panel, dnr)
		dnr:SetPoint("TOPLEFT", mapControl, 3, -3)
		dnr:SetPoint("RIGHT", currentMap, "LEFT", 2, 0)
	end)
	self.mapSelect:SetScript("OnHide", function(panel)
		panel:Hide()
		restoreStatus(panel)
		ns.journal.navBar.tabMapID = panel.tabMapID
		panel.tabMapID = nil
		panel.status = nil
		panel.panel = nil
		panel.condData = nil
	end)
	self.mapSelect:SetScript("OnKeyDown", self:GetScript("OnKeyDown"))

	self.mapSelect.cancel, self.mapSelect.ok = util.createCancelOk(self.mapSelect)
	self.mapSelect.cancel:SetPoint("BOTTOMRIGHT", -30, 15)

	self.mapSelect.cancel:SetScript("OnClick", function(btn)
		btn:GetParent():Hide()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	self.mapSelect.ok:SetScript("OnClick", function(btn)
		local panel = btn:GetParent()
		panel.condData[3] = ns.journal.navBar.mapID
		self:checkRule()
		self:setCondValueOption(panel.panel, panel.condData)
		panel:Hide()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	-- MOUNT SELECT
	self.mountSelect = CreateFrame("FRAME", nil, self.panel, "MJDarkPanelTemplate")
	self.mountSelect:Hide()
	self.mountSelect:EnableMouse(true)
	self.mountSelect:SetFrameLevel(1200)
	self.mountSelect:SetAllPoints()
	self.mountSelect:SetScript("OnShow", function(panel)
		panel:EnableKeyboard(not InCombatLockdown())
		panel.status = {}

		local filtersPanel = ns.journal.filtersPanel
		saveStatus(panel, filtersPanel)
		filtersPanel:SetPoint("TOP", 0, -6)

		local leftInset = ns.journal.leftInset
		saveStatus(panel, leftInset)
		leftInset:SetPoint("TOPRIGHT", ns.journal.filtersPanel, "BOTTOMRIGHT", -17, -2)
		leftInset:SetPoint("BOTTOM", 0, 6)
		ns.journal:setShownCountMounts()
		ns.journal.tags.selectFunc = function(spellID)
			self.mountSelect:Hide()
			self.data.action[2] = spellID
			self:checkRule()
			self:setActionValueOption()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		end
	end)
	self.mountSelect:SetScript("OnHide", function(panel)
		panel:Hide()
		restoreStatus(panel)
		ns.journal:setShownCountMounts()
		ns.journal.tags.selectFunc = nil
		panel.status = nil
	end)
	self.mountSelect:SetScript("OnKeyDown", self:GetScript("OnKeyDown"))

	self.mountSelect.close = CreateFrame("BUTTON", nil, self.mountSelect, "UIPanelCloseButtonNoScripts")
	self.mountSelect.close:SetSize(22, 22)
	self.mountSelect.close:SetPoint("TOPRIGHT", -4, -7)
	self.mountSelect.close:SetFrameLevel(self.mountSelect:GetFrameLevel() + 1)
	self.mountSelect.close:SetScript("OnClick", function(btn)
		btn:GetParent():Hide()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)
end)


function ruleEditor:addRule()
	self:Show()
	self.title:SetText(L["Add Rule"])

	self.order = nil
	self.data = {
		{false},
		action = {},
	}

	self.actionPanel.optionType:SetText()
	self:setActionValueOption()
	self:checkRule()
	self:updateConditionList()
end


function ruleEditor:editRule(order, data)
	self:Show()
	self.title:SetText(L["Edit Rule"])

	self.order = order
	self.data = util:copyTable(data)

	self.actionPanel.optionType:SetText(actions[data.action[1]].text)
	self:setActionValueOption()
	self:checkRule()
	self:updateConditionList()
end


function ruleEditor:addCondition()
	self.data[#self.data + 1] = {false}
	self:checkRule()
	self:updateConditionList()
end


function ruleEditor:removeCondition(order)
	tremove(self.data, order)
	self:checkRule()
	self:updateConditionList()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end


function ruleEditor:checkRule()
	local check = true

	for i = 1, #self.data do
		local cond = self.data[i]
		if not cond[2] or conds[cond[2]].getValueText and not cond[3] then
			check = false
			break
		end
	end

	local action = self.data.action
	if not action[1] or actions[action[1]].getValueText and not action[2] then
		check = false
	end

	self.ok:SetEnabled(check)
end


function ruleEditor:getCondTooltip(condData)
	local cond = conds[condData[2]]
	return cond.getDescription and cond:getDescription()
end


function ruleEditor:openCondValueMenu(btn, btnData)
	local function func(f)
		btnData[3] = f.value
		btn:SetText(rules:getCondValueText(btnData))
		self:checkRule()
	end

	local list = conds[btnData[2]]:getValueList(btnData[3], func, self.menu)
	self.menu:ddToggle(1, list, btn)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end


function ruleEditor:setCondValueOption(panel, btnData)
	if not btnData[2] then return end

	if panel.optionValue then
		panel.optionValue:Hide()
	end

	local cond = conds[btnData[2]]
	if not cond.getValueText then return end

	if cond.getValueList then
		panel.optionValue = self.btnPool:Acquire()
		panel.optionValue:SetScript("OnClick", function(btn) self:openCondValueMenu(btn, btnData) end)
	elseif btnData[2] == "map" then
		panel.optionValue = self.btnPool:Acquire()
		panel.optionValue:SetScript("OnClick", function()
			self.menu:ddCloseMenus()
			self.mapSelect.panel = panel
			self.mapSelect.condData = btnData
			self.mapSelect:Show()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		end)
	else
		panel.optionValue = self.editPool:Acquire()
		panel.optionValue:SetNumeric(cond.isNumeric)
		panel.optionValue:SetScript("OnTextChanged", function(editBox)
			local text = editBox:GetText()
			if cond.isNumeric then
				btnData[3] = tonumber(text)
			else
				btnData[3] = #text > 0 and text or nil
			end
			self:checkRule()
		end)
	end

	panel.optionValue:SetParent(panel)
	panel.optionValue:SetPoint("LEFT", panel.optionType, "RIGHT", 10, 0)
	panel.optionValue:SetPoint("RIGHT", panel.remove, "LEFT", -10, 0)
	panel.optionValue:Show()
	panel.optionValue:SetText(rules:getCondValueText(btnData))
	panel.optionValue.tooltip = self:getCondTooltip(btnData)
end


function ruleEditor:openCondTypeMenu(btn, btnData)
	local function func(f)
		btnData[2] = f.value
		btnData[3] = nil
		btn:SetText(f.text)
		self:setCondValueOption(btn:GetParent(), btnData)
		self:checkRule()
	end

	local list = conds:getMenuList(btnData[2], func)
	self.menu:ddToggle(1, list, btn)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end


function ruleEditor:getActionTooltip(actionData)
	local action = actions[actionData[1]]
	return action.getDescription and action:getDescription()
end


function ruleEditor:openActionValueMenu(btn, actionData)
	local function func(f)
		actionData[2] = f.value
		btn:SetText(rules:getActionValueText(actionData))
		self:checkRule()
	end

	local list = actions[actionData[1]]:getValueList(actionData[2], func)
	self.menu:ddToggle(1, list, btn)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end


function ruleEditor:setActionValueOption()
	local actionData = self.data.action
	local panel = self.actionPanel
	panel:SetHeight(50)
	if not actionData[1] then return end

	if panel.optionValue then
		panel.optionValue:Hide()
	end

	local action = actions[actionData[1]]
	if action.maxLetters then
		panel:SetHeight(140)
		panel.optionValue = panel.macro
		local editBox = panel.macro.editFrame:GetEditBox()
		editBox.CHAR_LIMIT = MACROFRAME_CHAR_LIMIT:gsub("255", action.maxLetters)
		editBox:SetMaxLetters(action.maxLetters)
		editBox:SetText(rules:getActionValueText(actionData) or "")
		editBox:GetScript("OnTextChanged")(editBox)
		panel.macro:Show()
		return
	elseif action.getValueList then
		panel.optionValue = self.btnPool:Acquire()
		panel.optionValue:SetScript("OnClick", function(btn) self:openActionValueMenu(btn, actionData) end)
	elseif actionData[1] == "mount" then
		panel.optionValue = self.btnPool:Acquire()
		panel.optionValue:SetScript("OnClick", function()
			self.menu:ddCloseMenus()
			self.mountSelect:Show()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		end)
	else
		panel.optionValue = self.editPool:Acquire()
		panel.optionValue:SetNumeric(true)
		panel.optionValue:SetScript("OnTextChanged", function(editBox)
			actionData[2] = tonumber(editBox:GetText())
			self:checkRule()
		end)
	end

	panel.optionValue:SetParent(panel)
	panel.optionValue:SetPoint("LEFT", panel.optionType, "RIGHT", 10, 0)
	panel.optionValue:SetPoint("RIGHT", -30, 0)
	panel.optionValue:Show()
	panel.optionValue:SetText(rules:getActionValueText(actionData) or "")
	panel.optionValue.tooltip = self:getActionTooltip(actionData)
end


function ruleEditor:openActionTypeMenu(btn)
	local actionData = self.data.action

	local function func(f)
		actionData[1] = f.value
		actionData[2] = nil
		btn.text:SetText(f.text)
		self:setActionValueOption()
		self:checkRule()
	end

	local list = actions:getMenuList(actionData[1], func)
	self.menu:ddToggle(1, list, btn)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end


function ruleEditor:conditionButtonInit(panel, data)
	local btnData = data[2]
	if btnData == "add" then
		panel.order:SetText("")
		panel.notCheck:Hide()
		panel.optionType:Hide()
		panel.remove:Hide()

		self.plusFrame:SetParent(panel)
		self.plusFrame:SetAllPoints()
		self.plusFrame:Show()
	else
		panel.order:SetText(data[1])

		panel.notCheck:Show()
		panel.notCheck:SetChecked(btnData[1])
		panel.notCheck.Text:SetText(L["NOT_CONDITION"])
		panel.notCheck:SetScript("OnClick",function(btn)
			local checked = btn:GetChecked()
			btnData[1] = checked
			PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
		end)

		panel.optionType:Show()
		panel.optionType:SetText(btnData[2] and conds[btnData[2]].text)
		panel.optionType:SetScript("OnClick", function(btn) self:openCondTypeMenu(btn, btnData) end)

		self:setCondValueOption(panel, btnData)

		panel.remove:SetShown(data[1] ~= 1)
		panel.remove:SetScript("OnClick", function() self:removeCondition(data[1]) end)
	end
end


function ruleEditor:updateConditionList()
	self.dataProvider = CreateDataProvider()
	for i = 1, #self.data do
		self.dataProvider:Insert({i, self.data[i]})
	end
	self.dataProvider:Insert({#self.data + 1, "add"})
	self.scrollBox:SetDataProvider(self.dataProvider, ScrollBoxConstants.RetainScrollPosition)
end