local addon, ns = ...
local L, util, macroFrame, conds, actions = ns.L, ns.util, ns.macroFrame, ns.conditions, ns.actions
local rules = CreateFrame("FRAME", "MountsJournalConfigRules")
ns.ruleConfig = rules
rules:Hide()


rules:SetScript("OnShow", function(self)
	self:SetScript("OnShow", nil)
	self:SetScript("OnHide", function() self.ruleEditor:Hide() end)

	local lsfdd = LibStub("LibSFDropDown-1.5")

	-- VERSION
	local ver = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	ver:SetPoint("TOPRIGHT", -40, 15)
	ver:SetTextColor(.5, .5, .5, 1)
	ver:SetJustifyH("RIGHT")
	ver:SetText(C_AddOns.GetAddOnMetadata(addon, "Version"))

	-- SUMMONS
	self.summons = lsfdd:CreateButton(self)
	self.summons:SetPoint("TOPLEFT", 30, -30)
	self.summons:ddSetSelectedValue(1)
	self.summons:ddSetSelectedText(SUMMONS.." 1")

	self.summons:ddSetInitFunc(function(dd)
		local info = {}

		local function func(btn)
			dd:ddSetSelectedValue(btn.value)
			self:setSummonRules(btn.value)
		end

		for i = 1, 2 do
			info.text = SUMMONS.." "..i
			info.value = i
			info.func = func
			dd:ddAddButton(info)
		end
	end)

	-- ADD RULE BUTTOM
	self.addRule = CreateFrame("BUTTON", nil, self, "UIPanelButtonTemplate")
	self.addRule:SetPoint("LEFT", self.summons, "RIGHT", 10, 0)
	self.addRule:SetText(L["Add Rule"])
	self.addRule:SetSize(self.addRule:GetFontString():GetStringWidth() + 40, 22)
	self.addRule:SetScript("OnClick", function()
		self.ruleEditor:addRule()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	-- SCROLL
	self.scrollBox = CreateFrame("FRAME", nil, self, "WowScrollBoxList")

	self.scrollBar = CreateFrame("EventFrame", nil, self, "MinimalScrollBar")
	self.scrollBar:SetPoint("TOPLEFT", self.scrollBox, "TOPRIGHT", 8, -2)
	self.scrollBar:SetPoint("BOTTOMLEFT", self.scrollBox, "BOTTOMRIGHT", 8, 0)

	self.view = CreateScrollBoxListLinearView()
	self.view:SetElementInitializer("MJRulePanelTemplate", function(...) self:ruleButtonInit(...) end)
	ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.scrollBar, self.view)

	local scrollBoxAnchorsWithBar = {
		CreateAnchor("TOPLEFT", self.summons, "BOTTOMLEFT", 0, -20),
		CreateAnchor("BOTTOMRIGHT", -50, 30),
	}
	local scrollBoxAnchorsWithoutBar = {
		scrollBoxAnchorsWithBar[1],
		CreateAnchor("BOTTOMRIGHT", -30, 30),
	}
	ScrollUtil.AddManagedScrollBarVisibilityBehavior(self.scrollBox, self.scrollBar, scrollBoxAnchorsWithBar, scrollBoxAnchorsWithoutBar)

	-- INIT
	self:setSummonRules(1)
end)


function rules:setSummonRules(n)
	self.rules = macroFrame.ruleConfig[n]
	self:updateRuleList()
end


function rules:saveRule(order, data)
	if order then
		tremove(self.rules, order)
	end
	tinsert(self.rules, order or 1, data)
	self:updateRuleList()
	macroFrame:setRuleFuncs()
end


function rules:removeRule(order)
	StaticPopup_Show(util.addonName.."YOU_WANT", NORMAL_FONT_COLOR:WrapTextInColorCode(L["Remove Rule %d"]:format(order)), nil, function()
		tremove(self.rules, order)
		self:updateRuleList()
		macroFrame:setRuleFuncs()
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
	if cond[3] == nil then return end
	return conds[cond[2]]:getValueText(cond[3])
end


function rules:getActionValueText(action)
	if action[2] then	return actions[action[1]]:getValueText(action[2]) end
end


function rules:getCondText(conditions)
	local text = ""

	for i = 1, #conditions > 3 and 2 or #conditions do
		local cond = conditions[i]
		text = text..("\n|cff%s%s: %s|r"):format(
			cond[1] and ("cc4444%s "):format(L["Not"]) or "44cc44",
			conds[cond[2]].text,
			self:getCondValueText(cond)
		)
	end

	if #conditions > 3 then
		text = text.."\n..."
	end

	return text:sub(2)
end


function rules:getActionText(action)
	local value = self:getActionValueText(action)
	if value then
		return ("%s : %s"):format(actions[action[1]].text, value)
	else
		return actions[action[1]].text
	end
end


function rules:ruleButtonInit(btn, data)
	local btnData = data[2]
	btn.id = data[1]
	btn.order:SetText(btn.id)
	btn.conds:SetText(self:getCondText(btnData))
	btn.action:SetText(self:getActionText(btnData.action))

	btn:SetScript("OnClick", function(btn)
		self.ruleEditor:editRule(btn.id, btnData)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	btn.up:SetShown(btn.id > 1)
	btn.up:SetScript("OnClick", function(btn)
		self:setRuleOrder(btn:GetParent().id, -1)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	btn.down:SetShown(#self.rules > btn.id)
	btn.down:SetScript("OnClick", function(btn)
		self:setRuleOrder(btn:GetParent().id, 1)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	btn.remove:SetScript("OnClick", function(btn) self:removeRule(btn:GetParent().id) end)
end


function rules:updateRuleList()
	self.dataProvider = CreateDataProvider()
	for i = 1, #self.rules do
		self.dataProvider:Insert({i, self.rules[i]})
	end
	self.scrollBox:SetDataProvider(self.dataProvider, ScrollBoxConstants.RetainScrollPosition)
end