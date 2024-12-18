local addon, ns = ...
local L, util, mounts, macroFrame, conds, actions, calendar = ns.L, ns.util, ns.mounts, ns.macroFrame, ns.conditions, ns.actions, ns.calendar
local strcmputf8i = strcmputf8i
local rules = CreateFrame("FRAME", "MountsJournalConfigRules")
ns.ruleConfig = rules
rules:Hide()


rules:SetScript("OnShow", function(self)
	self:SetScript("OnShow", function(self) self:updateRuleList() end)
	self:SetScript("OnHide", function(self) self.ruleEditor:Hide() end)

	local lsfdd = LibStub("LibSFDropDown-1.5")

	StaticPopupDialogs[util.addonName.."NEW_RULE_SET"] = {
		text = addon..": "..L["New rule set"],
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = 1,
		maxLetters = 48,
		editBoxWidth = 350,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = function(self, cb) self:Hide() cb(self) end,
		EditBoxOnEnterPressed = function(self)
			StaticPopup_OnClick(self:GetParent(), 1)
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		OnShow = function(self)
			self.editBox:SetText(UnitName("player").." - "..GetRealmName())
			self.editBox:HighlightText()
		end,
	}
	local function ruleSetExistsAccept(popup, data)
		if not popup then return end
		popup:Hide()
		self:createRuleSet(data)
	end
	StaticPopupDialogs[util.addonName.."RULE_SET_EXISTS"] = {
		text = addon..": "..L["A rule set with the same name exists."],
		button1 = OKAY,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = ruleSetExistsAccept,
		OnCancel = ruleSetExistsAccept,
	}
	StaticPopupDialogs[util.addonName.."DELETE_RULE_SET"] = {
		text = addon..": "..L["Are you sure you want to delete rule set %s?"],
		button1 = DELETE,
		button2 = CANCEL,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = function(self, cb) self:Hide() cb() end,
	}

	-- VERSION
	local ver = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	ver:SetPoint("TOPRIGHT", -40, 15)
	ver:SetTextColor(.5, .5, .5, 1)
	ver:SetJustifyH("RIGHT")
	ver:SetText(C_AddOns.GetAddOnMetadata(addon, "Version"))

	-- RULE SETS
	self.ruleSets = lsfdd:CreateStretchButtonOriginal(self, 150, 22)
	self.ruleSets:SetPoint("TOPRIGHT", -20, -20)
	self.ruleSets:SetText(macroFrame.currentRuleSet.name)
	self.ruleSets:ddSetDisplayMode(addon)

	self.ruleSets:ddSetInitFunc(function(dd, level)
		local info = {}

		if level == 1 then
			local function selectRuleSet(btn)
				self:selectRuleSet(btn.value)
			end

			local function removeRuleSet(btn)
				self:removeRuleSet(btn.value)
			end

			info.list = {}
			for i, ruleSet in ipairs(macroFrame.ruleSetConfig) do
				local subInfo = {
					text = ruleSet.isDefault and ("%s %s"):format(ruleSet.name, DARKGRAY_COLOR:WrapTextInColorCode(DEFAULT)) or ruleSet.name,
					value = ruleSet.name,
					checked = ruleSet.name == macroFrame.currentRuleSet.name,
					func = selectRuleSet,
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

			if not macroFrame.currentRuleSet.isDefault then
				info.keepShownOnClick = nil
				info.hasArrow = nil
				info.text = L["Set as default"]
				info.func = function()
					for i, ruleSet in ipairs(macroFrame.ruleSetConfig) do
						ruleSet.isDefault = nil
					end
					macroFrame.currentRuleSet.isDefault = true
				end
				dd:ddAddButton(info, level)
			end
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

	-- RULE SETS TEXT
	local ruleSetsText = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	ruleSetsText:SetPoint("RIGHT", self.ruleSets, "LEFT", -5, 0)
	ruleSetsText:SetText(L["Rule Sets"])

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

	-- ADD RULE BUTTOM
	self.addRuleBtn = CreateFrame("BUTTON", nil, self, "UIPanelButtonTemplate")
	self.addRuleBtn:SetPoint("LEFT", self.summons, "RIGHT", 10, 0)
	self.addRuleBtn:SetText(L["Add Rule"])
	self.addRuleBtn:SetSize(self.addRuleBtn:GetFontString():GetStringWidth() + 40, 22)
	self.addRuleBtn:SetScript("OnClick", function()
		self.ruleEditor:addRule()
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

	-- RULE CLICKS
	local function btnClick(btn)
		self.ruleEditor:editRule(btn.id, btn.data)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end
	local function btnUpClick(btn)
		self:setRuleOrder(btn:GetParent().id, -1)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end
	local function btnDownClick(btn)
		self:setRuleOrder(btn:GetParent().id, 1)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end
	local function btnRemoveClick(btn) self:removeRule(btn:GetParent().id) end

	local function onAcqure(owner, btn, data, new)
		if new then
			btn:SetScript("OnClick", btnClick)
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

	self.view = CreateScrollBoxListLinearView()
	self.view:SetElementInitializer("MJRulePanelTemplate", function(...) self:ruleButtonInit(...) end)
	self.view:RegisterCallback(self.view.Event.OnAcquiredFrame, onAcqure, self)
	ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.scrollBar, self.view)

	local scrollBoxAnchorsWithBar = {
		CreateAnchor("TOPLEFT", self.summons, "BOTTOMLEFT", 0, -20),
		CreateAnchor("BOTTOMRIGHT", -42, 20),
	}
	local scrollBoxAnchorsWithoutBar = {
		scrollBoxAnchorsWithBar[1],
		CreateAnchor("BOTTOMRIGHT", -20, 20),
	}
	ScrollUtil.AddManagedScrollBarVisibilityBehavior(self.scrollBox, self.scrollBar, scrollBoxAnchorsWithBar, scrollBoxAnchorsWithoutBar)

	-- EVENTS
	macroFrame:on("RULE_LIST_UPDATE", function()
		if self:IsShown() then self:updateRuleList() end
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
		local text = popup.editBox:GetText()
		if text and text ~= "" then
			for i, ruleSet in ipairs(macroFrame.ruleSetConfig) do
				if ruleSet.name == text then
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
	self:updateRuleList()
end


function rules:resetRules()
	StaticPopup_Show(util.addonName.."YOU_WANT", NORMAL_FONT_COLOR:WrapTextInColorCode(L["Reset Rules"]), nil, function()
		wipe(self.rules)
		self.rules[1] = mounts:getDefaultRule()
		self:updateRuleList()
		macroFrame:setRuleFuncs()
	end)
end


function rules:saveRule(order, data)
	if order then
		tremove(self.rules, order)
	end
	tinsert(self.rules, order or 1, data)
	self:updateRuleList()
	macroFrame:setRuleFuncs()
	calendar:checkHolidayNames()
end


function rules:removeRule(order)
	StaticPopup_Show(util.addonName.."YOU_WANT", NORMAL_FONT_COLOR:WrapTextInColorCode(L["Remove Rule %d"]:format(order)), nil, function()
		tremove(self.rules, order)
		self:updateRuleList()
		macroFrame:setRuleFuncs()
		calendar:checkHolidayNames()
	end)
end


function rules:setRuleOrder(order, delta)
	local newOrder = order + delta
	local curRule = self.rules[order]
	self.rules[order] = self.rules[newOrder]
	self.rules[newOrder] = curRule
	self:updateRuleList()
	macroFrame:setRuleFuncs()
end


function rules:getCondValueText(cond)
	if cond[3] == nil then return "" end
	return conds[cond[2]]:getValueText(cond[3]) or RED_FONT_COLOR:WrapTextInColorCode(tostringall(cond[3]))
end


function rules:getActionValueText(action)
	if action[2] == nil then return "" end
	return actions[action[1]]:getValueText(action[2]) or RED_FONT_COLOR:WrapTextInColorCode(tostringall(action[2]))
end


function rules:getCondText(cond)
	if not cond then return end
	local value = self:getCondValueText(cond)
	return ("|cff%s%s%s|r"):format(
		cond[1] and ("cc4444%s "):format(L["NOT_CONDITION"]) or "44cc44",
		conds[cond[2]].text,
		value == "" and value or " : "..value
	)
end


function rules:getActionText(action)
	local value = self:getActionValueText(action)
	if value == "" then
		return actions[action[1]].text
	else
		return ("%s : %s"):format(actions[action[1]].text, value)
	end
end


function rules:ruleButtonInit(btn, data)
	btn.id = data[1]
	btn.data = data[2]
	btn.order:SetText(btn.id)
	btn.action:SetText(self:getActionText(btn.data.action))
	btn.up:SetShown(btn.id > 1)
	btn.down:SetShown(#self.rules > btn.id)

	btn.cond2:ClearAllPoints()
	if #btn.data == 2 then
		btn.cond2:SetPoint("TOPLEFT", btn, "LEFT", 30, 0)
	else
		btn.cond2:SetPoint("LEFT", 30, 0)
	end
	btn.cond2:SetPoint("RIGHT", btn, "CENTER", -21, 0)

	if #btn.data == 1 then
		btn.cond1:SetText()
		btn.cond2:SetText(self:getCondText(btn.data[1]))
		btn.cond3:SetText()
	else
		for i = 1, 3 do
			local text = self:getCondText(btn.data[i])
			if i == 3 and #btn.data > 3 then text = text.."…" end
			btn["cond"..i]:SetText(text)
		end
	end
end


function rules:updateRuleList()
	self.dataProvider = CreateDataProvider()
	for i = 1, #self.rules do
		self.dataProvider:Insert({i, self.rules[i]})
	end
	self.scrollBox:SetDataProvider(self.dataProvider, ScrollBoxConstants.RetainScrollPosition)
end