local addon = ...
local eventsMixin, eventsMeta = {}, {
	__newindex = function(self, key, value)
		if key == "onLoad" and type(value) == "function" then
			rawset(self, key, function(self)
				self:initEvents()
				value(self)
			end)
		else
			rawset(self, key, value)
		end
	end
}


function eventsMixin:initEvents()
	self.initEvents = nil
	self._events = {}
end


function eventsMixin:on(event, func)
	if type(event) ~= "string" or type(func) ~= "function" then return end
	local event, name = strsplit(".", event, 2)

	if not self._events[event] then
		self._events[event] = {}
	end
	tinsert(self._events[event], {
		name = name,
		func = func,
	})
	return self
end


function eventsMixin:off(event, func)
	if type(event) ~= "string" then return end
	local event, name = strsplit(".", event, 2)

	local handlerList = self._events[event]
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
				self._events[event] = nil
			end
		else
			self._events[event] = nil
		end
	end
	return self
end


function eventsMixin:event(event, ...)
	local handlerList = self._events[event]
	if handlerList then
		for i = 1, #handlerList do
			handlerList[i].func(self, ...)
		end
	end
	return self
end


MountsJournalUtil = {}
MountsJournalUtil.addonName = ("%s_ADDON_"):format(addon:upper())


-- 1 FLY, 2 GROUND, 3 SWIMMING
MountsJournalUtil.mountTypes = setmetatable({
	[242] = 1,
	[247] = 1,
	[248] = 1,
	[398] = 1,
	[230] = 2,
	[241] = 2,
	[284] = 2,
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


MountsJournalUtil.filterButtonBackdrop = {
	edgeFile = "Interface/AddOns/MountsJournal/textures/border",
	edgeSize = 8,
}


MountsJournalUtil.optionsPanelBackdrop = {
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	tile = true,
	tileEdge = true,
	tileSize = 14,
	edgeSize = 14,
	insets = {left = 4, right = 4, top = 4, bottom = 4}
}


MountsJournalUtil.editBoxBackdrop = {
	bgFile = "Interface/ChatFrame/ChatFrameBackground",
	edgeFile = "Interface/ChatFrame/ChatFrameBackground",
	tile = true, edgeSize = 1, tileSize = 5,
}


function MountsJournalUtil.createFromEventsMixin(...)
	local mixin = CreateFromMixins(eventsMixin, ...)
	setmetatable(mixin, eventsMeta)
	return mixin
end


function MountsJournalUtil:setEventsMixin(frame)
	self.setMixin(frame, eventsMixin)
	frame:initEvents()
end


function MountsJournalUtil.setMixin(frame, mixin)
	for k, v in pairs(mixin) do
		frame[k] = v
	end
end


function MountsJournalUtil.inTable(tbl, item)
	for i = 1, #tbl do
		if tbl[i] == item then
			return i
		end
	end
	return false
end


function MountsJournalUtil.getMapFullNameInfo(mapID)
	local mapInfo = C_Map.GetMapInfo(mapID)

	local mapGroupID = C_Map.GetMapGroupID(mapID)
	if mapGroupID then
		local mapGroupInfo = C_Map.GetMapGroupMembersInfo(mapGroupID)
		if mapGroupInfo then
			for _, mapGroupMemberInfo in ipairs(mapGroupInfo) do
				if mapGroupMemberInfo.mapID == mapID then
					mapInfo.name = ("%s(%s)"):format(mapInfo.name, mapGroupMemberInfo.name)
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

	function MountsJournalUtil.createCheckboxChild(text, parent)
		if not parent.childs then
			parent.childs = {}
			hooksecurefunc(parent, "SetChecked", setEnabledChilds)
			parent:HookScript("OnClick", setEnabledChilds)
			parent:HookScript("OnEnable", setEnabledChilds)
			parent:HookScript("OnDisable", disableChilds)
		end

		local check = CreateFrame("CheckButton", nil, parent:GetParent(), "MJCheckButtonTemplate")
		if #parent.childs == 0 then
			check:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 20, -3)
		else
			check:SetPoint("TOPLEFT", parent.childs[#parent.childs], "BOTTOMLEFT", 0, -3)
		end
		check.Text:SetText(text)
		tinsert(parent.childs, check)
		return check
	end
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

	function MountsJournalUtil.setHyperlinkTooltip(frame)
		frame:SetHyperlinksEnabled(true)
		frame:SetScript("OnHyperlinkEnter", showTooltip)
		frame:SetScript("OnHyperlinkLeave", hideTooltip)
	end
end


function MountsJournalUtil:copyTable(t)
	local n = {}
	for k, v in pairs(t) do
		n[k] = type(v) == "table" and self:copyTable(v) or v
	end
	return n
end


function MountsJournalUtil.getGroupType()
	return IsInRaid() and "raid" or IsInGroup() and "group"
end


function MountsJournalUtil.cleanText(text)
	return text:trim():lower():gsub("[%(%)%.%%%+%-%*%?%[%^%$]", "%%%1")
end