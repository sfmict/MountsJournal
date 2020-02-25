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
end


function eventsMixin:event(event, ...)
	local handlerList = self._events[event]
	if handlerList then
		for _, handler in ipairs(handlerList) do
			handler.func(self, ...)
		end
	end
end


MountsJournalUtil = {}


function MountsJournalUtil.createFromEventsMixin(...)
	local mixin = CreateFromMixins(eventsMixin, ...)
	setmetatable(mixin, eventsMeta)
	return mixin
end


function MountsJournalUtil.setEventsMixin(frame)
	for k, v in pairs(eventsMixin) do
		frame[k] = v
	end
	frame:initEvents()
end


function MountsJournalUtil.inTable(tbl, item)
	for key, value in ipairs(tbl) do
		if value == item then
			return key
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
					mapInfo.name = format("%s(%s)", mapInfo.name, mapGroupMemberInfo.name)
					break
				end
			end
		end
	end

	return mapInfo
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
	return text:lower():gsub("^%s*(.-)%s*$", "%1"):gsub("[%(%)%.%%%+%-%*%?%[%^%$]", "%%%1")
end