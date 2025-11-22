local addon, ns = ...
MountsJournal.setMetaNS(ns)
local util, L = ns.util, ns.L
util.codeFont = "Interface\\Addons\\MountsJournalUI\\Fonts\\FiraCode-Regular.ttf"


local menuBackdrop = {
	bgFile = "Interface/ChatFrame/ChatFrameBackground",
	edgeFile = "Interface/ChatFrame/ChatFrameBackground",
	tile = true, edgeSize = 2, tileSize = 5,
}
local lsfdd = LibStub("LibSFDropDown-1.5")

local menuOnUpdate = function(self, elapsed)
	local r,g,b,a = self:GetBackdropBorderColor()
	if r > .4 then self.delta = -.2
	elseif r < .1 then self.delta = .2 end
	r = r + elapsed * self.delta
	self:SetBackdropBorderColor(r, r, r, a)
end

lsfdd:CreateMenuStyle(addon, function(parent)
	local f = CreateFrame("FRAME", nil, parent, "BackdropTemplate")
	f:SetPoint("TOPLEFT", 2, -2)
	f:SetPoint("BOTTOMRIGHT", -2, 2)
	f:SetBackdrop(menuBackdrop)
	f:SetBackdropColor(.06, .06, .09, .85)
	f:SetBackdropBorderColor(.3, .3, .3, .8)
	f:SetScript("OnUpdate", menuOnUpdate)
	f.delta = .2
	return f
end)


-- EXPANSIONS
util.expColors = setmetatable({
	"D6AB7D", -- classic
	"E43E5A", -- burning crusade
	"3FC7EB", -- wrath of the lich king
	"FF7C0A", -- cataclysm
	"00EF88", -- mists of pandaria
	"F48CBA", -- warlords of draenor
	"AAD372", -- legion
	"FFF468", -- battle for azeroth
	"9798FE", -- shadowlands
	"53B39F", -- dragonflight
	"90CCDD", -- the war within
	util.isMidnight and "994AD2" or nil, -- midnight
}, {
	__index = function(self, key)
		self[key] = "E8E8E8"
		return self[key]
	end
})
util.expIcons = setmetatable({
	1385726,
	1378987,
	607688,
	536055,
	901157,
	1134497,
	1715536,
	3256381,
	4465334,
	5409250,
	6980554,
	util.isMidnight and 7455547 or nil,
}, {
	__index = function(self, key)
		self[key] = [[Interface\EncounterJournal\UI-EJ-BOSS-Default]]
		return self[key]
	end
})


util.filterButtonBackdrop = {
	edgeFile = "Interface/AddOns/MountsJournal/textures/border",
	edgeSize = 8,
}


util.optionsPanelBackdrop = {
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	tile = true,
	tileEdge = true,
	tileSize = 14,
	edgeSize = 14,
	insets = {left = 4, right = 4, top = 4, bottom = 4}
}


util.modelScenebackdrop = {
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	tile = true,
	tileEdge = true,
	tileSize = 14,
	edgeSize = 14,
	insets = {left = 3, right = 3, top = 3, bottom = 3}
}


util.editBoxBackdrop = {
	bgFile = "Interface/ChatFrame/ChatFrameBackground",
	edgeFile = "Interface/ChatFrame/ChatFrameBackground",
	tile = true, edgeSize = 1, tileSize = 5,
}


util.sliderPanelBackdrop = {
	bgFile = "Interface/Buttons/UI-SliderBar-Background",
	edgeFile = "Interface/Buttons/UI-SliderBar-Border",
	tile = true,
	-- tileEdge = true,
	tileSize = 8,
	edgeSize = 2,
	insets = {left = 1, right = 1, top = 1, bottom = 1},
}


util.darkPanelBackdrop = {
	bgFile = "Interface/ChatFrame/ChatFrameBackground",
	-- bgFile = "Interface/Buttons/UI-SliderBar-Background",
	edgeFile = "Interface/Buttons/UI-SliderBar-Border",
	tile = true,
	tileEdge = true,
	tileSize = 8,
	edgeSize = 8,
	insets = {left = 3, right = 3, top = 6, bottom = 6},
}


do
	local function setEnabledChilds(self)
		local checked = self:GetChecked()
		for _, child in ipairs(self.childs) do
			child:SetEnabled(checked)
		end
	end

	local function disableChilds(self)
		for _, child in ipairs(self.childs) do
			child:Disable()
		end
	end

	function util.setCheckboxChild(parent, child, lastChild)
		if not parent.childs then
			parent.childs = {}
			hooksecurefunc(parent, "SetChecked", setEnabledChilds)
			parent:HookScript("OnClick", setEnabledChilds)
			parent:HookScript("OnEnable", setEnabledChilds)
			parent:HookScript("OnDisable", disableChilds)
		end
		parent.childs[#parent.childs + 1] = child
		if lastChild then parent.lastChild = child end
	end
end


function util.createCheckboxChild(text, parent)
	local check = CreateFrame("CheckButton", nil, parent:GetParent(), "MJCheckButtonTemplate")
	if parent.lastChild then
		check:SetPoint("TOPLEFT", parent.lastChild, "BOTTOMLEFT", 0, -3)
	else
		check:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 20, -3)
	end
	if text then check.Text:SetText(text) end
	util.setCheckboxChild(parent, check, true)
	return check
end


do
	local function showTooltip(_,_, hyperLink)
		GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(hyperLink)
		GameTooltip:Show()
	end

	local function hideTooltip(self)
		GameTooltip:Hide()
	end

	function util.setHyperlinkTooltip(frame)
		frame:SetHyperlinksEnabled(true)
		frame:SetScript("OnHyperlinkEnter", showTooltip)
		frame:SetScript("OnHyperlinkLeave", hideTooltip)
	end
end


function util.cleanText(text)
	return text:trim():lower()
end


do
	local cover = CreateFrame("BUTTON")
	cover:Hide()

	local copyBox = CreateFrame("Editbox")
	copyBox:Hide()
	copyBox:SetAutoFocus(false)
	copyBox:SetMultiLine(false)
	copyBox:SetAltArrowKeyMode(true)
	copyBox:SetJustifyH("LEFT")
	copyBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
	copyBox:SetScript("OnEditFocusLost", copyBox.Hide)
	copyBox:SetScript("OnEscapePressed", copyBox.Hide)
	copyBox:SetScript("OnHide", function(self)
		self:Hide()
		self.fontString:Show()
	end)
	copyBox:SetScript("OnTextChanged", function(self, userInput)
		if userInput then
			self:SetText(self.fontString:GetText())
			self:HighlightText()
		end
	end)
	copyBox:SetScript("OnEnter", function(self)
		cover:SetParent(self:GetParent())
		cover:SetAllPoints(self.fontString)
		cover:Show()
		cover.fontString = self.fontString
	end)

	cover:SetScript("OnClick", function(self)
		copyBox:SetParent(self:GetParent())
		copyBox:SetPoint("TOPLEFT", self)
		copyBox:SetPoint("BOTTOMRIGHT", self, 4, 0)
		copyBox:SetFontObject(self.fontString:GetFontObject())
		copyBox:SetText(self.fontString:GetText())
		copyBox:SetCursorPosition(0)
		copyBox:Show()
		copyBox:SetFocus()
		copyBox.fontString = self.fontString
		copyBox.fontString:Hide()
		copyBox:SetFrameLevel(self:GetFrameLevel() - 1)
	end)
	cover:SetScript("OnEnter", function(self)
		self.fontString:GetScript("OnEnter")(self.fontString)
	end)
	cover:SetScript("OnLeave", function(self)
		self.fontString:GetScript("OnLeave")(self.fontString)
	end)

	local function fontString_OnEnter(self)
		if self:IsShown() then
			cover:SetParent(self:GetParent())
			cover:SetAllPoints(self)
			cover:Show()
			cover.fontString = self
		end
	end

	local function fontString_OnLeave(self)
		if self:IsShown() then
			cover:Hide()
		end
	end

	local function fontString_SetText(self, text)
		if copyBox.fontString == self and copyBox:IsShown() then
			copyBox:SetText(text)
			copyBox:SetCursorPosition(0)
			copyBox:HighlightText()
		end
	end

	function util.setCopyBox(fontString)
		fontString:HookScript("OnEnter", fontString_OnEnter)
		fontString:HookScript("OnLeave", fontString_OnLeave)
		fontString:SetMouseClickEnabled(false)
		hooksecurefunc(fontString, "SetText", fontString_SetText)
	end
end


function util.createCancelOk(parent)
	local cancel = CreateFrame("BUTTON", nil, parent, "UIPanelButtonTemplate")
	cancel:SetText(CANCEL)

	local ok = CreateFrame("BUTTON", nil, parent, "UIPanelButtonTemplate")
	ok:SetPoint("RIGHT", cancel, "LEFT", -5, 0)
	ok:SetText(OKAY)

	local width = math.max(cancel:GetFontString():GetStringWidth(), ok:GetFontString():GetStringWidth()) + 40
	cancel:SetSize(width, 22)
	ok:SetSize(width, 22)

	return cancel, ok
end


function util.addTooltipDLine(s1, s2)
	GameTooltip:AddDoubleLine(s1, s2, 1, 1, 1, NIGHT_FAE_BLUE_COLOR.r, NIGHT_FAE_BLUE_COLOR.g, NIGHT_FAE_BLUE_COLOR.b)
end


do
	local day = DAY_ONELETTER_ABBR:gsub(" ", "")
	local hour = HOUR_ONELETTER_ABBR:gsub(" ", "")
	local minute = MINUTE_ONELETTER_ABBR:gsub(" ", "")
	local second = SECOND_ONELETTER_ABBR:gsub(" ", "")
	local mstr = minute.." "..second
	local hstr = hour.." "..mstr
	local dstr = day.." "..hstr
	function util.getTimeBreakDown(time)
		local d,h,m,s = ChatFrame_TimeBreakDown(time)
		if d > 0 then
			return dstr:format(d,h,m,s)
		elseif h > 0 then
			return hstr:format(h,m,s)
		elseif m > 0 then
			return mstr:format(m,s)
		else
			return second:format(s)
		end
	end
end


do
	local text = "%s = %s"
	function util:getFormattedDistance(distance)
		return text:format(self.getImperialFormat(distance), self.getMetricFormat(distance))
	end
end


do
	local text = "%s/"..L["ABBR_HOUR"].." = %s/"..L["ABBR_HOUR"]
	function util:getFormattedAvgSpeed(distance, time)
		local avgSpeed = time > 0 and distance / time * 3600 or 0
		return text:format(self.getImperialFormat(avgSpeed), self.getMetricFormat(avgSpeed))
	end
end
