local _,L = ...


MJExistingsListsMixin = {}


function MJExistingsListsMixin:onLoad()
	self.navBar = MountsJournalFrame.navBar
	self.mounts = MountsJournal
	self.util = MountsJournalUtil
	self.child = self.scrollFrame.child
	self.optionsButtonPool = CreateFramePool("BUTTON", self.child, "MJOptionButtonTemplate", function(_,frame)
		frame:Hide()
		frame:ClearAllPoints()
		frame:Enable()
	end)
	self.lists = {}
	local listsInfo = {
		withList = {
			name = L["Zones with list"],
			nextKey = "withRelation",
		},
		withRelation = {
			name = L["Zones with relation"],
			nextKey = "withFlags",
		},
		withFlags = {
			name = L["Zones with flags"],
		},
	}

	for k, listInfo in pairs(listsInfo) do
		self.lists[k] = CreateFrame("CheckButton", nil, self.child, "MJCollapseButtonTemplate")
		self.lists[k]:SetText(listInfo.name)
		self.lists[k].childs = {}
		self.lists[k].nextKey = listInfo.nextKey
		self.lists[k]:SetScript("OnClick", function(btn) self:collapse(btn) end)
	end

	self.lists.withList:SetPoint("TOPLEFT", self.scrollFrame)
	self.lists.withList:SetPoint("TOPRIGHT", self.scrollFrame)
end


function MJExistingsListsMixin:collapse(btn)
	local checked = btn:GetChecked()
	btn.toggle.plusMinus:SetTexture(checked and "Interface/Buttons/UI-PlusButton-UP" or "Interface/Buttons/UI-MinusButton-UP")

	local lastChild
	for _,child in ipairs(btn.childs) do
		child:SetShown(not checked)
		lastChild = child
	end

	if btn.nextKey then
		self.lists[btn.nextKey]:SetPoint("TOPLEFT", checked and btn or lastChild,"BOTTOMLEFT")
		self.lists[btn.nextKey]:SetPoint("TOPRIGHT", checked and btn or lastChild,"BOTTOMRIGHT")
	end
end


function MJExistingsListsMixin:optionClick(btn)
	MountsJournalFrame.navBar:setMapID()
end


function MJExistingsListsMixin:refresh()
	if not self:IsVisible() then return end
	fprint("refresh")
	local lastWidth = 0

	for _,withList in pairs(self.lists) do
		local width = withList.text:GetStringWidth()
		if width > lastWidth then
			lastWidth = width
		end
		wipe(withList.childs)
	end
	self.optionsButtonPool:ReleaseAll()
	lastWidth = lastWidth + 10

	for mapID, mapConfig in pairs(self.mounts.db.zoneMounts) do
		if mapConfig.listFromID then
			-- local optionButton = self.optionsButtonPool:Acquire()
			-- optionButton:SetText(self.util.getMapFullNameInfo(mapID).name)
			-- local width = optionButton.text:GetStringWidth()
			-- if width > lastWidth then
			-- 	lastWidth = width
			-- end
			tinsert(self.lists.withRelation.childs, optionButton)
		elseif #mapConfig.fly + #mapConfig.ground + #mapConfig.swimming ~= 0 then
			local optionButton = self.optionsButtonPool:Acquire()
			optionButton:SetText(self.util.getMapFullNameInfo(mapID).name)
			-- optionButton:SetScript("OnClick", function()
				-- self.navBar:setMapID(mapID)
				-- self.navBar:refresh()
				-- fprint(mapID)
				-- MountsJournalFrame.navBar:setMapID(mapID)
				-- fprint(self)
			-- end)
			local width = optionButton.text:GetStringWidth()
			if width > lastWidth then
				lastWidth = width
			end
			tinsert(self.lists.withList.childs, optionButton)
		end

		-- if mapConfig.flags.groundOnly or mapConfig.flags.waterWalkOnly then
		-- 	local optionButton = self.optionsButtonPool:Acquire()
		-- 	optionButton:SetText(self.util.getMapFullNameInfo(mapID).name)
		-- 	local width = optionButton.text:GetStringWidth()
		-- 	if width > lastWidth then
		-- 		lastWidth = width
		-- 	end
		-- 	tinsert(self.lists.withFlags.childs, optionButton)
		-- end
	end

	for _,withList in pairs(self.lists) do
		fprint(#withList.childs)
		if #withList.childs == 0 then
			local optionButton = self.optionsButtonPool:Acquire()
			optionButton:SetText(EMPTY)
			optionButton:Disable()
			tinsert(withList.childs, optionButton)
		end

		local lastChild
		for _,child in ipairs(withList.childs) do
			child:SetPoint("TOPLEFT", lastChild or withList, "BOTTOMLEFT")
			child:SetPoint("TOPRIGHT", lastChild or withList, "BOTTOMRIGHT")
			lastChild = child
		end
		self:collapse(withList)
	end

	self:SetWidth(lastWidth + 62)
end