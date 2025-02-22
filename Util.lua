local addon, ns = ...
local L = ns.L
local type, tremove, next, tostring = type, tremove, next, tostring
local C_MountJournal, C_UnitAuras, UnitExists = C_MountJournal, C_UnitAuras, UnitExists
local events, eventsMixin = {}, {}


function eventsMixin:on(event, func)
	if type(event) ~= "string" or type(func) ~= "function" then return self end
	local event, name = ("."):split(event, 2)

	if not events[event] then
		events[event] = {}
	end
	local handlerList = events[event]
	local k = tostring(self)..(name or tostring(func))
	local handler = function(...) func(self, ...) end

	if handlerList[k] then
		for i = 1, #handlerList do
			if handlerList[i] == handlerList[k] then
				tremove(handlerList, i)
				break
			end
		end
	end

	local index = #handlerList + 1
	handlerList[index] = handler
	handlerList[k] = handler
	return self
end


function eventsMixin:off(event, func)
	if type(event) ~= "string" then return self end
	local event, name = ("."):split(event, 2)

	local handlerList = events[event]
	if handlerList then
		if name or func then
			local k = tostring(self)..(name or tostring(func))
			local handler = handlerList[k]
			if handler then
				for i = 1, #handlerList do
					if handlerList[i] == handler then
						tremove(handlerList, i)
						break
					end
				end
				handlerList[k] = nil
				if #handlerList == 0 then
					events[event] = nil
				end
			end
		else
			events[event] = nil
		end
	end
	return self
end


function eventsMixin:event(event, ...)
	local handlerList = events[event]
	if handlerList then
		for i = 1, #handlerList do
			handlerList[i](...)
		end
	end
	return self
end


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


local util = {}
MountsJournalUtil = util
ns.util = util
util.addonName = ("%s_ADDON_"):format(addon:upper())
util.expansion = tonumber(GetBuildInfo():match("(.-)%."))
util.secureButtonNameMount = addon.."_Mount"
util.secureButtonNameSecondMount = addon.."_SecondMount"


-- 1 FLY, 2 GROUND, 3 SWIMMING
util.mountTypes = setmetatable({
	[242] = 1,
	[247] = 1,
	[402] = 1,
	[407] = {1, 3},
	[411] = 1,
	[424] = 1,
	[426] = 1,
	[430] = 1,
	[436] = {1, 3},
	[437] = 1,
	[442] = 1,
	[444] = 1,
	[445] = 1,
	[230] = 2,
	[241] = 2,
	[284] = 2,
	[408] = 2,
	[412] = {2, 3},
	[231] = 3,
	[232] = 3,
	[254] = 3,
}, {
	__index = function(self, key)
		if type(key) == "number" then
			self[key] = 1
			return self[key]
		end
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


function util.setMixin(obj, mixin)
	for k, v in pairs(mixin) do
		obj[k] = v
	end
	return obj
end


function util.createFromEventsMixin()
	return util.setMixin({}, eventsMixin)
end


function util.setEventsMixin(frame)
	util.setMixin(frame, eventsMixin)
end


function util.inTable(tbl, item)
	for i = 1, #tbl do
		if tbl[i] == item then
			return i
		end
	end
	return false
end


function util.getMapFullNameInfo(mapID)
	local mapInfo = C_Map.GetMapInfo(mapID)

	local mapGroupID = C_Map.GetMapGroupID(mapID)
	if mapGroupID then
		local mapGroupInfo = C_Map.GetMapGroupMembersInfo(mapGroupID)
		if mapGroupInfo then
			for _, mapGroupMemberInfo in ipairs(mapGroupInfo) do
				if mapGroupMemberInfo.mapID == mapID then
					mapInfo.name = ("%s (%s)"):format(mapInfo.name, mapGroupMemberInfo.name)
					break
				end
			end
		end
	end

	return mapInfo
end


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


function util:copyTable(t)
	local n = {}
	for k, v in pairs(t) do
		n[k] = type(v) == "table" and self:copyTable(v) or v
	end
	return n
end


function util.getGroupType()
	return IsInRaid() and "raid" or IsInGroup() and "group"
end


function util.cleanText(text)
	return text:trim():lower()
end


function util.checkAura(unit, spellID, filter)
	if not UnitExists(unit) then return false end
	local GetAuraSlots, GetAuraDataBySlot, ctok, a,b,c,d,e = C_UnitAuras.GetAuraSlots, C_UnitAuras.GetAuraDataBySlot
	repeat
		ctok, a,b,c,d,e = GetAuraSlots(unit, filter, 5, ctok)
		while a do
			if GetAuraDataBySlot(unit, a).spellId == spellID then return true end
			a,b,c,d,e = b,c,d,e
		end
	until not ctok
	return false
end


function util.getUnitMount(unit)
	if not UnitExists(unit) then return end
	local GetAuraSlots, GetAuraDataBySlot, ctok, a,b,c,d,e = C_UnitAuras.GetAuraSlots, C_UnitAuras.GetAuraDataBySlot
	local filter = unit == "player" and "HELPFUL PLAYER" or "HELPFUL"
	repeat
		ctok, a,b,c,d,e = GetAuraSlots(unit, filter, 5, ctok)
		while a do
			local data = GetAuraDataBySlot(unit, a)
			if ns.additionalMountBuffs[data.spellId] then
				return ns.additionalMountBuffs[data.spellId].spellID, nil, data.auraInstanceID
			else
				local mountID = C_MountJournal.GetMountFromSpell(data.spellId)
				if mountID then return data.spellId, mountID, data.auraInstanceID end
			end
			a,b,c,d,e = b,c,d,e
		end
	until not ctok
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


function util.getRarityColor(mountID)
	local rarity = ns.mountsDB[mountID][3]
	if rarity > 50 then
		return ITEM_QUALITY_COLORS[1].color
	elseif rarity > 20 then
		return ITEM_QUALITY_COLORS[2].color
	elseif rarity > 10 then
		return ITEM_QUALITY_COLORS[3].color
	elseif rarity > 1 then
		return ITEM_QUALITY_COLORS[4].color
	else
		return ITEM_QUALITY_COLORS[5].color
	end
end


function util.addTooltipDLine(s1, s2)
	GameTooltip:AddDoubleLine(s1, s2, 1, 1, 1, NIGHT_FAE_BLUE_COLOR.r, NIGHT_FAE_BLUE_COLOR.g, NIGHT_FAE_BLUE_COLOR.b)
end


function util.getTimeBreakDown(time)
	local d,h,m,s = ChatFrame_TimeBreakDown(time)
	if d > 0 then
		return ("%d:%.2d:%.2d:%.2d"):format(d,h,m,s)
	elseif h > 0 then
		return ("%.2d:%.2d:%.2d"):format(h,m,s)
	else
		return ("%.2d:%.2d"):format(m,s)
	end
end


do
	local ABBR_YARD = " "..L["ABBR_YARD"]
	local ABBR_MILE = " "..L["ABBR_MILE"]
	function util.getImperialFormat(distance)
		if distance < 1760 then
			return math.floor(distance)..ABBR_YARD
		elseif distance < 176e4 then
			return (math.floor(distance / 176) / 10)..ABBR_MILE
		end
		return math.floor(distance / 1760)..ABBR_MILE
	end
end


do
	local ABBR_METER = " "..L["ABBR_METER"]
	local ABBR_KILOMETER = " "..L["ABBR_KILOMETER"]
	function util.getMetricFormat(distance)
		distance = distance * .9144
		if distance < 1e3 then
			return math.floor(distance)..ABBR_METER
		elseif distance < 1e6 then
			return (math.floor(distance / 100) / 10)..ABBR_KILOMETER
		end
		return math.floor(distance / 1e3)..ABBR_KILOMETER
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


do
	local text = "%s/"..L["ABBR_HOUR"]
	local speedFormat = GetLocale() ~= "enUS" and util.getMetricFormat or util.getImperialFormat
	function util:getFormattedSpeed(speed)
		return text:format(speedFormat(speed * 3600))
	end
end