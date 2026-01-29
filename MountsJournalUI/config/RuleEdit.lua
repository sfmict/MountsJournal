local addon, ns = ...
local L, util, rules, conds, actions = ns.L, ns.util, ns.ruleConfig, ns.conditions, ns.actions
local ruleEditor = CreateFrame("FRAME", nil, rules, "MJEscHideTemplate")
rules.ruleEditor = ruleEditor
ruleEditor:Hide()
ruleEditor:HookScript("OnHide", ruleEditor.Hide)


local escOnShow = ruleEditor:GetScript("OnShow")
ruleEditor:HookScript("OnShow", function(self)
	self:EnableMouse(true)
	self:SetFrameLevel(1100)
	self:SetAllPoints()
	self:SetScript("OnShow", escOnShow)

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
	local function btnPoolInitFunc(f)
		f:Hide()
		f:SetScript("OnHide", btnPoolOnHide)
	end
	self.btnPool = CreateFramePool("BUTTON", nil, "MJConditionDropDownTemplate", resetPoolFunc, false, btnPoolInitFunc)

	local function editPoolOnHide(f)
		f.link.value = nil -- abort loading item
		self.editPool:Release(f)
	end
	local function editPoolInitFunc(f)
		f:Hide()
		f:SetScript("OnHide", editPoolOnHide)
		f.link = f.linkFrame.link
		util.setHyperlinkTooltip(f.linkFrame)
	end
	self.editPool = CreateFramePool("EditBox", nil, "MJConditionEditBoxTemplate", resetPoolFunc, false, editPoolInitFunc)

	-- PANELS
	self.panel = CreateFrame("FRAME", nil, self, "MJDarkPanelTemplate")
	self.panel:SetPoint("TOPLEFT", 10, -10)
	self.panel:SetPoint("BOTTOMRIGHT", -10, 10)
	self.panel:SetBackdropColor(.1, .1, .1, .85)

	-- type buttons
	self.addTypeButton1 = CreateFrame("BUTTON", nil, self.panel, "MJRuleTypeButtonTemplate")
	self.addTypeButton1:SetPoint("TOPRIGHT", self.panel, "TOP", 0, -20)
	self.addTypeButton1:SetText(L["Add Rule"])
	self.addTypeButton1:SetScript("OnClick", function(btn)
		self:selectAddBtn(btn)
		self.data.action = {}
		self.data.rules = nil
		self.data.name = nil
		self:setActionOption()
		self:ruleCheck()
	end)
	self.addTypeButton1.endPos = 10
	self.addTypeButton1.bg:SetTexCoord(1197/2048,1622/2048,1063/2048,1161/2048)
	self.addTypeButton1.highlight:SetTexCoord(1197/2048,1622/2048,1063/2048,1161/2048)

	self.addTypeButton2 = CreateFrame("BUTTON", nil, self.panel, "MJRuleTypeButtonTemplate")
	self.addTypeButton2:SetPoint("TOPLEFT", self.panel, "TOP", 0, -20)
	self.addTypeButton2:SetText(L["Add Group"])
	self.addTypeButton2:SetScript("OnClick", function(btn)
		self:selectAddBtn(btn)
		self.data.action = nil
		self.data.rules = {}
		self.data.name = ""
		self:setActionOption()
		self:ruleCheck()
	end)
	self.addTypeButton2.endPos = -10
	self.addTypeButton2.bg:SetTexCoord(380/2048,805/2048,1186/2048,1285/2048)
	self.addTypeButton2.highlight:SetTexCoord(380/2048,805/2048,1186/2048,1285/2048)

	local width = math.max(self.addTypeButton1:GetFontString():GetStringWidth(), self.addTypeButton2:GetFontString():GetStringWidth()) + 30
	self.addTypeButton1:SetWidth(width)
	self.addTypeButton2:SetWidth(width)

	local typeSlice = self.addTypeButton1:CreateTexture(nil, "BORDER")
	self.panel.typeSlice = typeSlice
	typeSlice:SetAtlas("glues-characterSelect-TopHUD-BG-divider-dis")
	typeSlice:SetSize(2, 34)
	typeSlice:SetPoint("RIGHT", 1, 3)
	typeSlice:SetAlpha(.5)

	local typeCheckTex = self.addTypeButton1:CreateTexture(nil, "ARTWORK")
	self.panel.typeCheckTex = typeCheckTex
	typeCheckTex:SetSize(width, 34)
	typeCheckTex:SetPoint("CENTER", 0, 0)
	typeCheckTex:SetAtlas("glues-gameMode-glw-bottom")
	typeCheckTex:SetAlpha(.4)

	-- title
	self.title = self.panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
	self.title:SetPoint("TOP", 0, -20)
	self.title:SetText(" ")

	self.condText = self.panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	self.condText:SetPoint("TOP", self.title, "BOTTOM", 0, -4)
	self.condText:SetPoint("LEFT", 40, 0)
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
			self:ruleCheck()
		end
	end)

	self.actionText = self.panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	self.actionText:SetPoint("BOTTOMLEFT", self.actionPanel, "TOPLEFT", 10, 4)

	self.scrollBox = CreateFrame("FRAME", nil, self.panel, "WowScrollBoxList")
	self.scrollBox:SetPoint("TOPLEFT", self.condText, "BOTTOMLEFT", -10, -4)
	self.scrollBox:SetPoint("BOTTOMLEFT", self.actionText, "TOPLEFT", -10, 10)
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
		rules:save(self.list, self.order, self.data, self.order)
		btn:GetParent():GetParent():Hide()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	-- modal utils
	local function saveStatus(panel, frame, notShow)
		local status = {}
		for i = 1, frame:GetNumPoints() do
			status[i] = {frame:GetPoint(i)}
		end
		status.parent = frame:GetParent()
		status.show = frame:IsShown()
		panel.status[frame] = status

		frame:SetParent(panel)
		frame:ClearAllPoints()
		if not notShow then frame:Show() end
		frame.SetPoint = nop
		frame.ClearAllPoints = nop
	end

	local function restoreStatus(panel)
		for frame, status in next, panel.status do
			frame.SetPoint = nil
			frame.ClearAllPoints = nil
			frame:ClearAllPoints()
			for i = 1, #status do
				frame:SetPoint(unpack(status[i]))
			end
			frame:SetParent(status.parent)
			frame:SetShown(status.show)
		end
	end

	-- MAP SELECT
	self.mapSelect = CreateFrame("FRAME", nil, self.panel, "MJDarkPanelTemplate,MJEscHideTemplate")
	self.mapSelect:Hide()
	self.mapSelect:EnableMouse(true)
	self.mapSelect:SetFrameLevel(1200)
	self.mapSelect:SetAllPoints()
	self.mapSelect:HookScript("OnShow", function(panel)
		panel.status = {}

		local navBar = ns.journal.navBar
		saveStatus(panel, navBar)
		panel.SetPoint(navBar, "TOPLEFT", 15, -15)
		panel.SetPoint(navBar, "TOPRIGHT", -15, 15)
		panel.tabMapID = navBar.tabMapID
		navBar.tabMapID = panel.condData[3] or navBar.defMapID

		local worldMap = ns.journal.worldMap
		saveStatus(panel, worldMap)
		panel.SetPoint(worldMap, "TOPLEFT", navBar, "BOTTOMLEFT")
		panel.SetPoint(worldMap, "BOTTOMRIGHT", -15, 78)

		local mapControl = ns.journal.mapSettings.mapControl
		saveStatus(panel, mapControl)
		panel.SetPoint(mapControl, "TOPLEFT", worldMap, "BOTTOMLEFT")
		panel.SetPoint(mapControl, "TOPRIGHT", worldMap, "BOTTOMRIGHT")

		local currentMap = ns.journal.mapSettings.CurrentMap
		saveStatus(panel, currentMap)
		panel.SetPoint(currentMap, "LEFT", mapControl, 134, 0)
		panel.SetPoint(currentMap, "RIGHt", mapControl, -3, 0)

		local dnr = ns.journal.mapSettings.dnr
		saveStatus(panel, dnr)
		panel.SetPoint(dnr, "TOPLEFT", mapControl, 3, -3)
		panel.SetPoint(dnr, "RIGHT", currentMap, "LEFT", 2, 0)
	end)
	self.mapSelect:HookScript("OnHide", function(panel)
		panel:Hide()
		restoreStatus(panel)
		ns.journal.navBar.tabMapID = panel.tabMapID
		panel.tabMapID = nil
		panel.status = nil
		panel.panel = nil
		panel.condData = nil
	end)

	self.mapSelect.cancel, self.mapSelect.ok = util.createCancelOk(self.mapSelect)
	self.mapSelect.cancel:SetPoint("BOTTOMRIGHT", -30, 15)

	self.mapSelect.cancel:SetScript("OnClick", function(btn)
		btn:GetParent():Hide()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	self.mapSelect.ok:SetScript("OnClick", function(btn)
		local panel = btn:GetParent()
		panel.condData[3] = ns.journal.navBar.mapID
		self:ruleCheck()
		self:setCondValueOption(panel.panel, panel.condData)
		panel:Hide()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	-- MOUNT SELECT
	self.mountSelect = CreateFrame("FRAME", nil, self.panel, "MJDarkPanelTemplate,MJEscHideTemplate")
	self.mountSelect:Hide()
	self.mountSelect:EnableMouse(true)
	self.mountSelect:SetFrameLevel(1200)
	self.mountSelect:SetAllPoints()
	self.mountSelect:HookScript("OnShow", function(panel)
		panel.status = {}

		local filtersPanel = ns.journal.filtersPanel
		saveStatus(panel, filtersPanel)
		panel.SetPoint(filtersPanel, "TOP", 0, -6)

		local shownPanel = ns.journal.filtersPanel.shownPanel
		saveStatus(panel, shownPanel, true)
		panel.SetPoint(shownPanel, "TOP", filtersPanel, "BOTTOM", 0, -2)
		panel.SetPoint(shownPanel, "LEFT", filtersPanel)
		panel.SetPoint(shownPanel, "RIGHT", filtersPanel)

		local leftInset = ns.journal.leftInset
		saveStatus(panel, leftInset)
		panel.SetPoint(leftInset, "TOP", shownPanel, "BOTTOM", 0, -2)
		panel.SetPoint(leftInset, "LEFT", filtersPanel, 0, 0)
		panel.SetPoint(leftInset, "RIGHT", filtersPanel, -17, 0)
		panel.SetPoint(leftInset, "BOTTOM", 0, 6)
		ns.journal.tags.selectFunc = function(spellID)
			self.mountSelect:Hide()
			self.data.action[2] = spellID
			self:ruleCheck()
			self:setActionValueOption()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		end
	end)
	self.mountSelect:HookScript("OnHide", function(panel)
		panel:Hide()
		restoreStatus(panel)
		ns.journal:setShownCountMounts()
		ns.journal.tags.selectFunc = nil
		panel.status = nil
	end)

	self.mountSelect.close = CreateFrame("BUTTON", nil, self.mountSelect, "UIPanelCloseButtonNoScripts")
	self.mountSelect.close:SetSize(22, 22)
	self.mountSelect.close:SetPoint("TOPRIGHT", -4, -7)
	self.mountSelect.close:SetFrameLevel(self.mountSelect:GetFrameLevel() + 1)
	self.mountSelect.close:SetScript("OnClick", function(btn)
		btn:GetParent():Hide()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	-- EVENTS
	ns.macroFrame:on("RULE_LIST_UPDATE", function()
		if self:IsShown() then self:updateConditionList() end
	end)
end)


do
	local function typeOnUpdate(panel, elapsed)
		--local endPos = 0
		local newPos = panel.tPos + (panel.tEndPos - panel.tPos) * elapsed * 10

		if math.abs(panel.tEndPos - panel.tPos) < 1
		or newPos > 0 and panel.tPos < 0
		or newPos < 0 and panel.tPos > 0
		then
			newPos = panel.tEndPos
			panel:SetScript("OnUpdate", nil)
		end

		panel.tPos = newPos
		panel.typeCheckTex:SetPoint("CENTER", panel.tRFrame, newPos, 0)
	end

	function ruleEditor:selectAddBtn(btn, pos)
		self.panel.tRFrame = btn
		self.panel.tEndPos = btn.endPos
		self.panel.tPos = pos or self.panel.typeCheckTex:GetCenter() - btn:GetCenter()
		self.panel:SetScript("OnUpdate", typeOnUpdate)
	end
end


function ruleEditor:add(list, data)
	self:Show()
	self.title:Hide()
	self.addTypeButton1:Show()
	self.addTypeButton2:Show()

	self.list = list
	self.order = nil
	self.data = data or {{false}, action = {}}

	self:selectAddBtn(self.data.action and self.addTypeButton1 or self.addTypeButton2, 0)
	self:setActionOption()
	self:ruleCheck()
	self:updateConditionList()
end


function ruleEditor:edit(list, order, data)
	self:Show()
	self.title:Show()
	self.addTypeButton1:Hide()
	self.addTypeButton2:Hide()

	if data.action then
		self.title:SetText(L["Edit Rule"])
	else
		self.title:SetText(L["Edit Group"])
	end

	self.list = list
	self.order = order
	self.data = util:copyTable(data)

	self:setActionOption()
	self:ruleCheck()
	self:updateConditionList()
end


function ruleEditor:addCondition()
	self.data[#self.data + 1] = {false}
	self:ruleCheck()
	self:updateConditionList()
end


function ruleEditor:removeCondition(order)
	tremove(self.data, order)
	self:ruleCheck()
	self:updateConditionList()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end


function ruleEditor:ruleCheck()
	local check = rules:ruleCheck(self.data)
	self.ok:SetEnabled(check)
end


function ruleEditor:getCondTooltip(condData)
	local cond = conds[condData[2]]
	return cond.getValueDescription and cond:getValueDescription()
end


function ruleEditor:openCondValueMenu(btn, btnData)
	local function func(f)
		btnData[3] = f.value
		btn:SetText(rules:getCondValueText(btnData))
		self:ruleCheck()
	end

	local list = conds[btnData[2]]:getValueList(btnData[3], func, self.menu)
	self.menu:ddToggle(1, list, btn)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end


function ruleEditor:setCondValueOption(panel, btnData, setFocus)
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
			if cond.setValueLink then
				cond:setValueLink(panel.optionValue.link, btnData[3])
			else
				panel.optionValue.link:SetText("")
			end
			self:ruleCheck()
		end)
		local receiveDrag = cond.receiveDrag and function(editBox)
			cond:receiveDrag(editBox)
		end
		panel.optionValue:SetScript("OnMouseUp", receiveDrag)
		panel.optionValue:SetScript("OnReceiveDrag", receiveDrag)
	end

	panel.optionValue:SetParent(panel)
	panel.optionValue:SetPoint("LEFT", panel.optionType, "RIGHT", 10, 0)
	panel.optionValue:SetPoint("RIGHT", panel.remove, "LEFT", -10, 0)
	panel.optionValue:Show()
	panel.optionValue:SetText(rules:getCondValueText(btnData))
	if panel.optionValue.SetCursorPosition then
		panel.optionValue:SetCursorPosition(0)
	end
	if setFocus and panel.optionValue.SetFocus then
		panel.optionValue:SetFocus()
	end
	panel.optionValue.tooltip = self:getCondTooltip(btnData)
end


function ruleEditor:openCondTypeMenu(btn, btnData)
	local function func(f)
		btnData[2] = f.value
		btnData[3] = nil
		btn:SetText(f.text)
		self:setCondValueOption(btn:GetParent(), btnData, true)
		self:ruleCheck()
	end

	local list = conds:getMenuList(btnData[2], func)
	self.menu:ddToggle(1, list, btn)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end


function ruleEditor:setActionOption()
	local actionData = self.data.action
	local panel = self.actionPanel

	if actionData then
		self.actionText:SetText(L["Action"])
		panel.groupName:Hide()
		panel.optionType:Show()
		panel.optionType:SetText(actionData[1] and actions[actionData[1]].text or "")
		self:setActionValueOption()
	else
		self.actionText:SetText(LFG_LIST_BAD_NAME)
		if panel.optionValue then panel.optionValue:Hide() end
		panel:SetHeight(50)
		panel.optionType:Hide()
		panel.groupName:Show()
		panel.groupName:SetText(self.data.name)
		panel.groupName:SetScript("OnTextChanged", function(editBox)
			self.data.name = editBox:GetText():trim()
			self:ruleCheck()
		end)
	end
end


function ruleEditor:getActionTooltip(actionData)
	local action = actions[actionData[1]]
	return action.getValueDescription and action:getValueDescription()
end


function ruleEditor:openActionValueMenu(btn, actionData)
	local function func(f)
		actionData[2] = f.value
		btn:SetText(rules:getActionValueText(actionData))
		self:ruleCheck()
	end

	local list = actions[actionData[1]]:getValueList(actionData[2], func)
	self.menu:ddToggle(1, list, btn)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end


function ruleEditor:setActionValueOption(setFocus)
	local actionData = self.data.action
	local panel = self.actionPanel

	if panel.optionValue then
		panel.optionValue:Hide()
	end

	panel:SetHeight(50)
	if not actionData[1] then return end

	local action = actions[actionData[1]]
	if not action.getValueText then return end

	if action.maxLetters then
		panel:SetHeight(140)
		panel.optionValue = panel.macro
		local editBox = panel.macro.editFrame:GetEditBox()
		editBox.CHAR_LIMIT = MACROFRAME_CHAR_LIMIT:gsub("255", action.maxLetters)
		editBox:SetMaxLetters(action.maxLetters)
		editBox:SetText(rules:getActionValueText(actionData))
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
		panel.optionValue:SetNumeric(action.isNumeric)
		panel.optionValue:SetScript("OnTextChanged", function(editBox)
			local text = editBox:GetText()
			if action.isNumeric then
				actionData[2] = tonumber(text)
			else
				actionData[2] = #text > 0 and text or nil
			end
			if action.setValueLink then
				action:setValueLink(panel.optionValue.link, actionData[2])
			else
				panel.optionValue.link:SetText("")
			end
			self:ruleCheck()
		end)
		local receiveDrag = action.receiveDrag and function(editBox)
			action:receiveDrag(editBox)
		end
		panel.optionValue:SetScript("OnMouseUp", receiveDrag)
		panel.optionValue:SetScript("OnReceiveDrag", receiveDrag)
	end

	panel.optionValue:SetParent(panel)
	panel.optionValue:SetPoint("LEFT", panel.optionType, "RIGHT", 10, 0)
	panel.optionValue:SetPoint("RIGHT", -30, 0)
	panel.optionValue:Show()
	panel.optionValue:SetText(rules:getActionValueText(actionData))
	if panel.optionValue.SetCursorPosition then
		panel.optionValue:SetCursorPosition(0)
	end
	if setFocus and panel.optionValue.SetFocus then
		panel.optionValue:SetFocus()
	end
	panel.optionValue.tooltip = self:getActionTooltip(actionData)
end


function ruleEditor:openActionTypeMenu(btn)
	local actionData = self.data.action

	local function func(f)
		actionData[1] = f.value
		actionData[2] = nil
		btn.text:SetText(f.text)
		self:setActionValueOption(true)
		self:ruleCheck()
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

		panel.remove:Show()
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