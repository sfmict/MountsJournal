local addon, ns = ...
local type, select, tremove = type, select, tremove
local C_MountJournal, C_UnitAuras, AuraUtil = C_MountJournal, C_UnitAuras, AuraUtil
local events, eventsMixin = {}, {}


function eventsMixin:on(event, func)
	if type(event) ~= "string" or type(func) ~= "function" then return end
	local event, name = ("."):split(event, 2)

	if not events[event] then
		events[event] = {}
	end
	events[event][#events[event] + 1] = {
		name = name,
		func = func,
		self = self,
	}
	return self
end


function eventsMixin:off(event, func)
	if type(event) ~= "string" then return end
	local event, name = ("."):split(event, 2)

	local handlerList = events[event]
	if handlerList then
		if name ~= nil or type(func) == "function" then
			local i = 1
			local handler = handlerList[i]
			while handler do
				if (not name or handler.name == name) and (not func or handler.func == func) then
					tremove(handlerList, i)
				else
					i = i + 1
				end
				handler = handlerList[i]
			end
			if #handlerList == 0 then
				events[event] = nil
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
			local handler = handlerList[i]
			handler.func(handler.self, ...)
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
	if r > .4 then self.delta = -.3
	elseif r < .1 then self.delta = .3 end
	elapsed = elapsed * self.delta
	r = r + elapsed
	self:SetBackdropBorderColor(r, r, r, a)
end

lsfdd:CreateMenuStyle(addon, function(parent)
	local f = CreateFrame("FRAME", nil, parent, "BackdropTemplate")
	f:SetBackdrop(menuBackdrop)
	f:SetBackdropColor(.06, .06, .1, .9)
	f:SetBackdropBorderColor(.3, .3, .3, .8)
	f:SetScript("OnUpdate", menuOnUpdate)
	f.delta = .3
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
	local GetAuraSlots, GetAuraDataBySlot, count, ctok, a,b,c,d,e = C_UnitAuras.GetAuraSlots, C_UnitAuras.GetAuraDataBySlot
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
	local GetAuraSlots, GetAuraDataBySlot, count, ctok, a,b,c,d,e = C_UnitAuras.GetAuraSlots, C_UnitAuras.GetAuraDataBySlot
	local filter = unit == "player" and "HELPFUL PLAYER" or "HELPFUL"
	repeat
		ctok, a,b,c,d,e = GetAuraSlots(unit, filter, 5, ctok)
		while a do
			local data = GetAuraDataBySlot(unit, a)
			local mountID = C_MountJournal.GetMountFromSpell(data.spellId)
			if mountID or ns.additionalMounts[data.spellId] then
				return data.spellId, mountID
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