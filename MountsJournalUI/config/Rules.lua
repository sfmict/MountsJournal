local addon, ns = ...
local L, util, mounts, macroFrame, conds, actions, dataDialog = ns.L, ns.util, ns.mounts, ns.macroFrame, ns.conditions, ns.actions, ns.dataDialog
local strcmputf8i = strcmputf8i
local rules = CreateFrame("FRAME", "MountsJournalConfigRules")
ns.ruleConfig = rules
rules:Hide()


rules:SetScript("OnShow", function(self)
	self:SetScript("OnShow", function(self) self:updateFilters() end)

	local lsfdd = LibStub("LibSFDropDown-1.5")

	StaticPopupDialogs[util.addonName.."NEW_RULE_SET"] = {
		text = ns.addon..": "..L["New rule set"],
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = 1,
		maxLetters = 48,
		editBoxWidth = 350,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = function(self, cb) cb(self) end,
		EditBoxOnEnterPressed = function(self)
			StaticPopup_OnClick(self:GetParent(), 1)
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		OnShow = function(self)
			local editBox = self.editBox or self.EditBox
			editBox:SetText(UnitName("player").." - "..GetRealmName())
			editBox:HighlightText()
		end,
	}
	local function ruleSetExistsAccept(popup, data)
		if not popup then return end
		popup:Hide()
		if self.isCreate then self:createRuleSet(data) end
	end
	StaticPopupDialogs[util.addonName.."RULE_SET_EXISTS"] = {
		text = ns.addon..": "..L["A rule set with the same name exists."],
		button1 = OKAY,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = ruleSetExistsAccept,
		OnCancel = ruleSetExistsAccept,
	}
	StaticPopupDialogs[util.addonName.."DELETE_RULE_SET"] = {
		text = ns.addon..": "..L["Are you sure you want to delete rule set %s?"],
		button1 = DELETE,
		button2 = CANCEL,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = function(self, cb) cb() end,
	}

	-- VERSION
	local ver = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	ver:SetPoint("TOPRIGHT", -40, 15)
	ver:SetTextColor(.5, .5, .5, 1)
	ver:SetJustifyH("RIGHT")
	ver:SetText(C_AddOns.GetAddOnMetadata(addon, "Version"))

	-- RULE SETS TEXT
	local ruleSetsText = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	ruleSetsText:SetHeight(22)
	ruleSetsText:SetPoint("TOPLEFT", 20, -20)
	ruleSetsText:SetText(L["Rule Sets"])

	-- RULE SETS
	self.ruleSets = lsfdd:CreateStretchButtonOriginal(self, 150, 22)
	self.ruleSets:SetPoint("LEFT", ruleSetsText, "RIGHT", 5, 0)
	self.ruleSets:SetText(macroFrame.currentRuleSet.name)
	self.ruleSets:ddSetDisplayMode(addon)

	self.ruleSets:ddSetInitFunc(function(dd, level)
		local info = {}

		if level == 1 then
			local function selectRuleSet(btn)
				if IsShiftKeyDown() then
					util.insertChatLink("Rule Set", btn.value)
				else
					self:selectRuleSet(btn.value)
				end
			end

			local function removeRuleSet(btn)
				self:removeRuleSet(btn.value)
			end

			local function OnTooltipShow(btn, tooltip)
				tooltip:AddLine(L["Shift-click to create a chat link"])
			end

			info.list = {}
			for i, ruleSet in ipairs(macroFrame.ruleSetConfig) do
				local subInfo = {
					text = ruleSet.isDefault and ("%s %s"):format(ruleSet.name, DARKGRAY_COLOR:WrapTextInColorCode(DEFAULT)) or ruleSet.name,
					value = ruleSet.name,
					checked = ruleSet.name == macroFrame.currentRuleSet.name,
					func = selectRuleSet,
					OnTooltipShow = OnTooltipShow,
				}
				if #macroFrame.ruleSetConfig > 1 then
					subInfo.remove = removeRuleSet
				end
				tinsert(info.list, subInfo)
			end
			dd:ddAddButton(info)
			info.list = nil

			dd:ddAddSeparator(level)

			info.keepShownOnClick = true
			info.notCheckable = true
			info.hasArrow = true
			info.text = L["New rule set"]
			dd:ddAddButton(info, level)

			info.hasArrow = nil
			info.keepShownOnClick = nil

			if not macroFrame.currentRuleSet.isDefault then
				info.text = L["Set as default"]
				info.func = function()
					for i, ruleSet in ipairs(macroFrame.ruleSetConfig) do
						ruleSet.isDefault = nil
					end
					macroFrame.currentRuleSet.isDefault = true
				end
				dd:ddAddButton(info, level)
			end

			dd:ddAddSeparator(level)

			info.text = L["Export"]
			info.func = function() self:exportRuleSet() end
			dd:ddAddButton(info, level)

			info.text = L["Import"]
			info.func = function() self:importRuleSet() end
			dd:ddAddButton(info, level)
		else
			info.notCheckable = true

			info.text = L["Create"]
			info.func = function() self:createRuleSet() end
			dd:ddAddButton(info, level)

			info.text = L["Copy current"]
			info.func = function() self:createRuleSet(true) end
			dd:ddAddButton(info, level)
		end
	end)

	-- SNIPPET TOGGLE
	self.snippetToggle = CreateFrame("CheckButton", nil, self, "MJArrowToggleText")
	self.snippetToggle:SetPoint("TOPRIGHT", -20, -20)
	self.snippetToggle.text:SetText(L["Code Snippets"])
	self.snippetToggle:SetWidth(self.snippetToggle.text:GetStringWidth() + 31)
	self.snippetToggle:HookScript("OnClick", function(btn)
		ns.snippets:SetShown(btn:GetChecked())
	end)

	-- TITLE
	self.title = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	self.title:SetPoint("TOP", 0, -60)
	self.title:SetPoint("LEFT", 60, 0)
	self.title:SetPoint("RIGHT", -60, 0)
	self.title:SetText(L["RULES_TITLE"])
	self.title:SetJustifyH("LEFT")

	-- SUMMONS
	self.summons = lsfdd:CreateModernButtonOriginal(self)
	self.summons:SetPoint("LEFT", 20, 0)
	self.summons:SetPoint("TOP", self.title, "BOTTOM", 0, -15)
	self.summons:ddSetDisplayMode(addon)

	self.summons:ddSetInitFunc(function(dd)
		local info = {}

		local function func(btn)
			self:setSummonRules(btn.value)
		end

		for i = 1, 2 do
			info.text = SUMMONS.." "..i
			info.icon = mounts.config["summon"..i.."Icon"]
			info.value = i
			info.func = func
			dd:ddAddButton(info)
		end
	end)

	mounts:on("UPDATE_SUMMON_ICON", function(_, id, icon)
		if self.summonN ~= id then return end
		self.summons:ddSetSelectedText(("%s %d"):format(SUMMONS, id), icon)
	end)

	-- ALTERNATIVE MODE
	self.altMode = CreateFrame("CheckButton", nil, self, "MJCheckButtonTemplate")
	self.altMode:SetPoint("TOPLEFT", self.summons, "BOTTOMLEFT", 0, -5)
	self.altMode.Text:SetText(L["Alternative Mode"])
	self.altMode.tooltipText = L["Alternative Mode"]
	self.altMode.tooltipRequirement = L["SecondMountTooltipDescription"]
	self.altMode:HookScript("OnClick", function(btn)
		self.rules.altMode = btn:GetChecked()
	end)

	-- ADD RULE BUTTON
	self.addRuleBtn = CreateFrame("BUTTON", nil, self, "UIPanelButtonTemplate")
	self.addRuleBtn:SetPoint("LEFT", self.summons, "RIGHT", 10, 0)
	self.addRuleBtn:SetText(L["Add Rule"])
	self.addRuleBtn:SetSize(self.addRuleBtn:GetFontString():GetStringWidth() + 40, 22)
	self.addRuleBtn:SetScript("OnClick", function()
		self.ruleEditor:add(self.rules)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	-- IMPORT RULE BUTTON
	self.importRuleBtn = CreateFrame("BUTTON", nil, self, "UIPanelButtonTemplate")
	self.importRuleBtn:SetPoint("LEFT", self.addRuleBtn, "RIGHT", 10, 0)
	self.importRuleBtn:SetText(L["Import Rule"])
	self.importRuleBtn:SetSize(self.importRuleBtn:GetFontString():GetStringWidth() + 40, 22)
	self.importRuleBtn:SetScript("OnClick", function()
		self:importRule()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	-- RESET BUTTON
	self.resetRulesBtn = CreateFrame("BUTTON", nil, self, "UIPanelButtonTemplate")
	self.resetRulesBtn:SetPoint("TOP", self.addRuleBtn)
	self.resetRulesBtn:SetPoint("RIGHT", -20, 0)
	self.resetRulesBtn:SetText(L["Reset Rules"])
	self.resetRulesBtn:SetSize(self.resetRulesBtn:GetFontString():GetStringWidth() + 40, 22)
	self.resetRulesBtn:SetScript("OnClick", function()
		self:resetRules()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	-- SEARCH
	self.searchBox = CreateFrame("EditBox", nil, self, "SearchBoxTemplate")
	self.searchBox:SetPoint("RIGHT", self.resetRulesBtn, -2, 0)
	self.searchBox:SetPoint("BOTTOM", self.altMode, 0, 2)
	self.searchBox:SetSize(200, 19)
	self.searchBox:SetMaxLetters(40)
	self.searchBox:SetScript("OnTextChanged", function(searchBox, userInput)
		SearchBoxTemplate_OnTextChanged(searchBox)
		self:updateFilters()
	end)

	-- HINT
	self.hint = CreateFrame("FRAME", nil, self, "MJHelpPlate")
	self.hint:SetPoint("RIGHT", self.searchBox, "LEFT", 7, 0)
	self.hint:SetScale(.9)
	self.hint.tooltip = L["Rules"].." & "..L["Code Snippets"]
	self.hint.tooltipDescription = L["Right-click for more options"].."\n"..L["Shift-click to create a chat link"]

	-- RULE CLICKS
	local function btnClick(btn, button)
		if button == "LeftButton" then
			if IsShiftKeyDown() then
				util.insertChatLink("Rule", ("%s:%s:%s"):format(
					self.summonN,
					self:getRulePath(btn.list, btn.id),
					macroFrame.currentRuleSet.name
				))
			else
				self.ruleEditor:edit(btn.list, btn.id, btn.data)
			end
		elseif button == "MiddleButton" then
			btn.collapseExpand:Click()
		else
			self.ruleMenu:ddToggle(1, btn, "cursor")
		end
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end
	local function btnEnter(btn)
		if #btn.data > 3
		or btn.cond1:IsTruncated()
		or btn.cond2:IsTruncated()
		or btn.cond3:IsTruncated()
		then
			GameTooltip:SetOwner(btn, "ANCHOR_NONE")
			GameTooltip:SetPoint("BOTTOMLEFT", btn, "BOTTOMRIGHT")
			GameTooltip:SetText(L["Conditions"]..":")
			for i = 1, #btn.data do
				GameTooltip:AddLine(self:getCondText(btn.data[i]))
			end
			GameTooltip:Show()
		end
	end
	local function btnDown(btn)
		btn.x, btn.y = GetCursorPosition()
	end
	local function btnDragStart(btn)
		local level = btn:GetFrameLevel()
		self.cover.id = btn.id
		self.cover.list = btn.list
		self.cover:SetParent(btn)
		self.cover:SetAllPoints(btn)
		self.cover:SetFrameLevel(level + 2)
		self.cover:Show()
		self.dragBtn:SetSize(btn:GetSize())
		self.dragBtn:SetFrameLevel(level + 500)
		self:ruleButtonInit(self.dragBtn, btn:GetElementData(), true)
		local x, y = GetCursorPosition()
		local xd, yd = GetCursorDelta()
		local scale = btn:GetEffectiveScale()
		x = btn:GetLeft() + (x - btn.x - xd) / scale
		y = btn:GetBottom() + (y - btn.y - yd) / scale
		self.dragBtn:SetPoint("BOTTOMLEFT", UIParent, x, y)
		self.dragBtn:SetScript("OnUpdate", self.dragBtn.onUpdate)
		self.dragBtn:Show()
	end
	local function btnUpClick(btn)
		local parent = btn:GetParent()
		local list = parent.list
		local id = parent.id
		self:setRulePos(list, id, list, id - 1)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end
	local function btnDownClick(btn)
		local parent = btn:GetParent()
		local list = parent.list
		local id = parent.id
		self:setRulePos(list, id, list, id + 1)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end
	local function btnRemoveClick(btn)
		local parent = btn:GetParent()
		self:remove(parent.list, parent.id)
	end
	local function btnCollapseClick(btn)
		local parent = btn:GetParent()
		local node = parent:GetElementData()
		parent.data.isCollapsed = node:ToggleCollapsed(TreeDataProviderConstants.RetainChildCollapse, TreeDataProviderConstants.DoInvalidation) or nil
		parent:updateState()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end
	local function updateState(btn)
		local arrowRotation = btn:GetElementData():IsCollapsed() and math.pi or math.pi * .5
		btn.collapseExpand.normal:SetRotation(arrowRotation)
		btn.collapseExpand.pushed:SetRotation(arrowRotation)
		btn.collapseExpand.highlight:SetRotation(arrowRotation)
	end

	local function onAcqure(owner, btn, data, new)
		if new then
			if btn.collapseExpand then
				btn:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
				btn.collapseExpand:SetScript("OnClick", btnCollapseClick)
				btn.updateState = updateState
			else
				btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			end
			btn:RegisterForDrag("LeftButton")
			btn:SetScript("OnClick", btnClick)
			btn:HookScript("OnEnter", btnEnter)
			btn:SetScript("OnMouseDown", btnDown)
			btn:SetScript("OnDragStart", btnDragStart)
			btn.up:SetScript("OnClick", btnUpClick)
			btn.down:SetScript("OnClick", btnDownClick)
			btn.remove:SetScript("OnClick", btnRemoveClick)
		end
	end

	-- SCROLL
	self.scrollBox = CreateFrame("FRAME", nil, self, "WowScrollBoxList")

	self.scrollBar = CreateFrame("EventFrame", nil, self, "MinimalScrollBar")
	self.scrollBar:SetPoint("TOPLEFT", self.scrollBox, "TOPRIGHT", 8, -2)
	self.scrollBar:SetPoint("BOTTOMLEFT", self.scrollBox, "BOTTOMRIGHT", 8, 0)

	local indent = 12
	local top = 0
	local bottom = 0
	local left = 0
	local right = 0
	local spacing = 0
	self.view = CreateScrollBoxListTreeListView(indent, top, bottom, left, right, spacing)
	self.view:SetElementExtent(50)

	local ruleTemp = "MJRulePanelTemplate"
	local groupTemp = "MJRuleGroupTemplate"
	local ruleInit = function(...) self:ruleButtonInit(...) end
	local groupInit = function(...) self:ruleGroupInit(...) end

	self.view:SetElementFactory(function(factory, node)
		local data = node:GetData()
		if data[2].action then
			factory(ruleTemp, ruleInit)
		else
			factory(groupTemp, groupInit)
		end
	end)

	self.view:RegisterCallback(self.view.Event.OnAcquiredFrame, onAcqure, self)
	ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.scrollBar, self.view)

	local scrollBoxAnchorsWithBar = {
		CreateAnchor("TOPLEFT", self.altMode, "BOTTOMLEFT", 0, -5),
		CreateAnchor("BOTTOMRIGHT", -42, 20),
	}
	local scrollBoxAnchorsWithoutBar = {
		scrollBoxAnchorsWithBar[1],
		CreateAnchor("BOTTOMRIGHT", -20, 20),
	}
	ScrollUtil.AddManagedScrollBarVisibilityBehavior(self.scrollBox, self.scrollBar, scrollBoxAnchorsWithBar, scrollBoxAnchorsWithoutBar)

	-- COVER
	self.cover = CreateFrame("FRAME")
	self.cover:Hide()
	self.cover.bg = self.cover:CreateTexture(nil, "BACKGROUND")
	self.cover.bg:SetAllPoints()
	self.cover.bg:SetColorTexture(.2, .2, .2, .6)
	self.cover:SetScript("OnHide", self.Hide)

	-- SEPARATOR
	self.separator = CreateFrame("FRAME", nil, self)
	self.separator:Hide()
	self.separator:SetHeight(10)
	self.separator.bg = self.separator:CreateTexture(nil, "BACKGROUND")
	self.separator.bg:SetPoint("TOPLEFT", 0, -2)
	self.separator.bg:SetPoint("BOTTOMRIGHT", 0, -2)
	self.separator.bg:SetTexture("Interface\\Buttons\\UI-Silver-Button-Highlight")
	self.separator.bg:SetBlendMode("ADD")

	-- DRAG BUTTON
	self.dragBtn = CreateFrame("FRAME", nil, self, "MJRulePanelTemplate")
	self.dragBtn:Hide()
	self.dragBtn:SetAlpha(.5)
	self.dragBtn:SetMovable(true)
	self.dragBtn:SetMouseClickEnabled(false)
	self.dragBtn:SetMouseMotionEnabled(true)
	self.dragBtn.remove:Disable()
	self.dragBtn.up:Disable()
	self.dragBtn.down:Disable()

	local function isGroupList(gList, fList)
		if gList == fList then return true end
		for i, rule in ipairs(gList) do
			if rule.rules and isGroupList(rule.rules, fList) then
				return true
			end
		end
	end

	function self.dragBtn.onUpdate(btn, elapsed)
		local x, y = GetCursorDelta()
		local scale = btn:GetEffectiveScale()
		btn:AdjustPointsOffset(x / scale, y / scale)
		self.separator:Hide()
		self.separator.id = nil
		for i, f in ipairs(self.view:GetFrames()) do
			if f:IsMouseOver() then
				if f.list == btn.list and f.id == btn.id
				or btn.data.rules and isGroupList(btn.data.rules, f.list)
				then return end
				self.separator:ClearAllPoints()
				local x, y = GetCursorPosition()
				local xc, yc = f:GetCenter()
				y = y / scale
				if f.data.rules
				and f.data.rules ~= btn.list
				and math.abs(y - yc) < f:GetHeight() / 4
				then -- group
					self.separator.list = f.data.rules
					self.separator.id = 1
					self.separator:SetPoint("TOPLEFT", f, "CENTER", -150, 26)
					self.separator:SetPoint("BOTTOMRIGHT", f, "CENTER", 150, -34)
					self.separator:Show()
					return
				end
				if yc < y then -- up
					if (btn.list ~= f.list or btn.id + 1 ~= f.id)
					and f:GetTop() <= self.scrollBox:GetTop()
					then
						self.separator.id = f.id
						self.separator.list = f.list
						self.separator:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 5, -5)
						self.separator:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -5, -5)
						self.separator:Show()
					end
				else -- down
					if (btn.list ~= f.list or btn.id ~= f.id + 1)
					and math.floor(f:GetBottom() + .5) >= math.floor(self.scrollBox:GetBottom() + .5)
					--and (not f.data.rules or #f.data.rules == 0 or f.data.collapsed)
					then
						self.separator.id = f.id + 1
						self.separator.list = f.list
						self.separator:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 5, 5)
						self.separator:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", -5, 5)
						self.separator:Show()
					end
				end
				break
			end
		end
	end

	self.dragBtn:SetScript("OnShow", function(btn)
		btn:RegisterEvent("GLOBAL_MOUSE_UP")
	end)
	self.dragBtn:SetScript("OnHide", function(btn)
		btn:UnregisterEvent("GLOBAL_MOUSE_UP")
	end)
	self.dragBtn:SetScript("OnEvent", function(btn)
		btn:SetScript("OnUpdate", nil)
		btn:Hide()
		self.cover.id = nil
		self.cover:Hide()
		self.separator:Hide()
		local newID = self.separator.id
		if newID then
			local newList = self.separator.list
			local list = self.dragBtn.list
			local id = self.dragBtn.id
			if newList == list and newID > id then
				newID = newID - 1
			end
			self:setRulePos(list, id, newList, newID)
		end
	end)

	-- RULE MENU
	self.ruleMenu = lsfdd:SetMixin({})
	self.ruleMenu:ddSetDisplayMode(addon)
	self.ruleMenu:ddHideWhenButtonHidden(self.scrollBox)

	self.ruleMenu:ddSetInitFunc(function(dd, level, btn)
		local info = {}
		info.notCheckable = true

		info.text = L["Duplicate"]
		info.func = function() self:save(btn.list, btn.id + 1, util:copyTable(btn.data)) end
		dd:ddAddButton(info, level)

		info.text = L["Export"]
		info.func = function() self:exportRule(btn.list, btn.id) end
		dd:ddAddButton(info, level)

		info.text = DELETE
		info.func = function() self:remove(btn.list, btn.id) end
		dd:ddAddButton(info, level)

		info.func = nil
		info.text = CANCEL
		dd:ddAddButton(info, level)
	end)

	self.scrollBox:RegisterCallback(self.scrollBox.Event.OnDataRangeChanged, function()
		if self.doNotHideMenu then return end
		self.ruleMenu:ddOnHide()
	end)

	-- EVENTS
	macroFrame:on("RULE_LIST_UPDATE", function()
		if self:IsShown() then
			self.doNotHideMenu = true
			self:updateRuleList()
			self.doNotHideMenu = nil
		end
	end)

	-- INIT
	self:setSummonRules(1)
end)


function rules:selectRuleSet(ruleSetName)
	macroFrame:setRuleSet(ruleSetName)
	self.ruleSets:SetText(macroFrame.currentRuleSet.name)
	self:setSummonRules(self.summonN)
end


function rules:createRuleSet(copy)
	StaticPopup_Show(util.addonName.."NEW_RULE_SET", nil, nil, function(popup)
		local editBox = popup.editBox or popup.EditBox
		local text = editBox:GetText()
		popup:Hide()
		if text and text ~= "" then
			for i, ruleSet in ipairs(macroFrame.ruleSetConfig) do
				if ruleSet.name == text then
					self.isCreate = true
					StaticPopup_Show(util.addonName.."RULE_SET_EXISTS", nil, nil, copy)
					return
				end
			end
			local ruleSet = copy and util:copyTable(macroFrame.currentRuleSet) or {}
			ruleSet.name = text
			ruleSet.isDefault = nil
			mounts:checkRuleSet(ruleSet)
			tinsert(macroFrame.ruleSetConfig, ruleSet)
			sort(macroFrame.ruleSetConfig, function(a, b) return strcmputf8i(a.name, b.name) < 0 end)
			self:selectRuleSet(text)
		end
	end)
end


function rules:removeRuleSet(ruleSetName)
	StaticPopup_Show(util.addonName.."DELETE_RULE_SET", NORMAL_FONT_COLOR:WrapTextInColorCode(ruleSetName), nil, function()
		for i, ruleSet in ipairs(macroFrame.ruleSetConfig) do
			if ruleSet.name == ruleSetName then
				tremove(macroFrame.ruleSetConfig, i)
				if ruleSet.isDefault then
					macroFrame.ruleSetConfig[1].isDefault = true
				end
				break
			end
		end
		if macroFrame.currentRuleSet.name == ruleSetName then
			self:selectRuleSet()
		end
	end)
end


function rules:setSummonRules(n)
	self.summonN = n
	self.rules = macroFrame.currentRuleSet[n]
	self.summons:ddSetSelectedValue(n)
	self.summons:ddSetSelectedText(("%s %d"):format(SUMMONS, n), mounts.config["summon"..n.."Icon"])
	self.altMode:SetChecked(self.rules.altMode)
	self:updateFilters()
end


function rules:resetRules()
	StaticPopup_Show(util.addonName.."YOU_WANT", NORMAL_FONT_COLOR:WrapTextInColorCode(L["Reset Rules"]), nil, function()
		wipe(self.rules)
		self.rules[1] = mounts:getDefaultRule()
		self:updateFilters()
		macroFrame:setRuleFuncs()
	end)
end


do
	local function getPath(list, pList)
		for i, rule in ipairs(pList) do
			if rule.rules then
				if rule.rules == list then return i end
				local path = getPath(list, rule.rules)
				if path then return i..">"..path end
			end
		end
	end


	function rules:getRulePath(list, order)
		if list == self.rules then return order end
		return getPath(list, self.rules)..">"..order
	end
end


function rules:save(list, order, data, isEdit)
	if isEdit then
		tremove(list, order)
	end
	tinsert(list, order or 1, data)
	self:updateFilters()
	macroFrame:setRuleFuncs()
end


function rules:remove(list, order)
	StaticPopup_Show(util.addonName.."YOU_WANT", NORMAL_FONT_COLOR:WrapTextInColorCode(L["Remove Rule %s"]:format(self:getRulePath(list, order))), nil, function()
		tremove(list, order)
		self:updateFilters()
		macroFrame:setRuleFuncs()
	end)
end


function rules:setRulePos(list, order, newList, newOrder)
	table.insert(newList, newOrder, table.remove(list, order))
	self:updateFilters()
	macroFrame:setRuleFuncs()
end


function rules:ruleCheck(rule)
	if type(rule) ~= "table"
	or type(rule.action) == "table" and not actions[rule.action[1]]
	then return end

	if type(rule.name) == "string" and type(rule.rules) == "table" then
		for i, sRule in ipairs(rule.rules) do
			if not self:ruleCheck(sRule) then return end
		end
	end

	for i = 1, #rule do
		local cond = rule[i]
		if not conds[cond[2]]
		or conds[cond[2]].getValueList and not cond[3]
		then return end
	end

	return true
end


function rules:exportRule(list, order)
	dataDialog:open({
		type = "export",
		data = {type = "rule", data = list[order]},
	})
end


function rules:importRule()
	dataDialog:open({
		type = "import",
		valid = function(data)
			if data.type ~= "rule" then return end
			return self:ruleCheck(data.data)
		end,
		save = function(data)
			local rule = data.data
			if self:ruleCheck(rule) then
				util.openJournalTab(1, 3)
				self:save(self.rules, 1, rule)
				return true
			end
		end,
	})
end


function rules:dataImportRule(data, rName, characterName)
	dataDialog:open({
		type = "dataImport",
		typeLang = L["Rule"],
		id = rName,
		fromName = characterName,
		data = data,
		save = function(rule)
			if self:ruleCheck(rule) then
				util.openJournalTab(1, 3)
				self:save(self.rules, 1, rule)
				return true
			end
		end,
	})
end


function rules:exportRuleSet()
	local ruleSet = util:copyTable(macroFrame.currentRuleSet)
	ruleSet.name = nil
	ruleSet.isDefault = nil
	dataDialog:open({
		type = "export",
		data = {type = "ruleSet", data = ruleSet}
	})
end


function rules:saveImportedRuleSet(ruleSet, name)
	for i, ruleSet in ipairs(macroFrame.ruleSetConfig) do
		if ruleSet.name == name then
			self.isCreate = nil
			StaticPopup_Show(util.addonName.."RULE_SET_EXISTS")
			return
		end
	end
	util.openJournalTab(1, 3)
	ruleSet.name = name
	ruleSet.isDefault = nil
	mounts:checkRuleSet(ruleSet)
	tinsert(macroFrame.ruleSetConfig, ruleSet)
	sort(macroFrame.ruleSetConfig, function(a, b) return strcmputf8i(a.name, b.name) < 0 end)
	self:selectRuleSet(name)
	return true
end


function rules:importRuleSet()
	dataDialog:open({
		type = "import",
		defName = UnitName("player").." - "..GetRealmName(),
		valid = function(data)
			if data.type ~= "ruleSet" then return end
			local ruleSet = data.data
			if type(ruleSet) == "table" then
				for _, rules in ipairs(ruleSet) do
					if type(rules) ~= "table" then return end
					for _, rule in ipairs(rules) do
						if not self:ruleCheck(rule) then return end
					end
				end
				return true
			end
		end,
		save = function(data, name) return self:saveImportedRuleSet(data.data, name) end,
	})
end


function rules:dataImportRuleSet(data, rsName, characterName)
	dataDialog:open({
		type = "dataImport",
		defName = rsName,
		typeLang = L["Rule Set"],
		id = rsName,
		fromName = characterName,
		data = data,
		save = function(data, name) return self:saveImportedRuleSet(data, name) end,
	})
end


function rules:getCondValueText(cond)
	if cond[3] == nil then return "" end
	return conds[cond[2]]:getValueText(cond[3]) or RED_FONT_COLOR:WrapTextInColorCode(tostringall(cond[3]))
end


function rules:getCondValueDisplay(cond)
	return conds[cond[2]].getValueDisplay and conds[cond[2]]:getValueDisplay(cond[3]) or self:getCondValueText(cond)
end


function rules:getActionValueText(action)
	if action[2] == nil then return "" end
	return actions[action[1]]:getValueText(action[2]) or RED_FONT_COLOR:WrapTextInColorCode(tostringall(action[2]))
end


function rules:getActionValueDisplay(action)
	return actions[action[1]].getValueDisplay and actions[action[1]]:getValueDisplay(action[2]) or self:getActionValueText(action)
end


function rules:getCondText(cond)
	if not cond then return end
	local value = self:getCondValueDisplay(cond)
	local condText = "|cff44cc44"..conds[cond[2]].text
	if cond[1] then condText = ("|cffcc4444%s|r %s"):format(L["NOT_CONDITION"], condText) end
	if value == "" then
		return condText
	else
		return ("%s:|r |cffeeeeee%s|r"):format(condText, value)
	end
end


function rules:getActionText(rule)
	local action = rule.action
	if action then
		local value = self:getActionValueDisplay(action)
		if value == "" then
			return actions[action[1]].text
		else
			return ("%s:\n|cffeeeeee%s|r"):format(actions[action[1]].text, value)
		end
	else
		local name = rule.name
		if name == "" then name = "|cff808080--|r" end
		return LFG_LIST_BAD_NAME..":\n|cffeeeeee"..name
	end
end


function rules:ruleButtonInit(btn, node, isDrag)
	local data = node:GetData()
	btn.id = data[1]
	btn.data = data[2]
	btn.list = data[3]
	btn.order:SetText(btn.id)
	btn.action:SetText(self:getActionText(btn.data))
	btn.up:SetShown(btn.id > 1)
	btn.down:SetShown(#self.rules > btn.id)

	btn.cond2:ClearAllPoints()
	if #btn.data == 2 then
		btn.cond2:SetPoint("TOPLEFT", btn, "LEFT", 41, -1)
	else
		btn.cond2:SetPoint("LEFT", 41, 0)
	end
	btn.cond2:SetPoint("RIGHT", btn, "CENTER", -21, 0)

	if #btn.data == 1 then
		btn.cond1:SetText()
		btn.cond2:SetText(self:getCondText(btn.data[1]))
		btn.cond3:SetText()
	else
		btn.cond1:SetText(self:getCondText(btn.data[1]))
		btn.cond2:SetText(self:getCondText(btn.data[2]))
		local text = self:getCondText(btn.data[3])
		btn.cond3:SetText(#btn.data > 3 and text.."…" or text)
	end

	if not isDrag and self.cover.list == btn.list and self.cover.id == btn.id then
		self.cover:SetParent(btn)
		self.cover:SetAllPoints(btn)
		self.cover:Show()
	end
end


function rules:ruleGroupInit(btn, node, isDrag)
	self:ruleButtonInit(btn, node, isDrag)
	btn:updateState()
end


function rules:updateRuleList()
	self.scrollBox:SetDataProvider(self.dataProvider, ScrollBoxConstants.RetainScrollPosition)
end


do
	local deleteStr, len = {
		{"|?|c%x%x%x%x%x%x%x%x", 10},
		{"|?|r", 2},
	}
	local function compareFunc(s)
		return #s == len and "" or s
	end
	local function find(text, str)
		for i = 1, #deleteStr do
			local ds = deleteStr[i]
			len = ds[2]
			text = text:gsub(ds[1], compareFunc)
		end
		if text:find("Друг в группе") then
			fprint(text:find("n"))
		end
		return text:lower():find(str, 1, true)
	end


	function rules:condFind(rule, text)
		for i = 1, #rule do
			if find(self:getCondText(rule[i]), text) then return true end
		end
	end


	function rules:addDataList(text, list, pNode)
		local empty = true
		for i = 1, #list do
			local rule = list[i]
			if rule.name
			or self.notSearched
			or find(self:getActionText(rule), text)
			or self:condFind(rule, text)
			then
				local node = pNode:Insert({i, rule, list})
				if rule.rules then
					if self:addDataList(text, rule.rules, node)
					or self.notSearched
					or find(self:getActionText(rule), text)
					or self:condFind(rule, text)
					then
						empty = false
						node:SetCollapsed(rule.isCollapsed and self.notSearched)
					else
						pNode:Remove(node)
					end
				else
					empty = false
				end
			end
		end
		return not empty
	end
end


function rules:updateFilters()
	local text = util.cleanText(self.searchBox:GetText())
	self.dataProvider = CreateTreeDataProvider()
	self.notSearched = #text == 0
	self:addDataList(text, self.rules, self.dataProvider)
	self:updateRuleList()
end
