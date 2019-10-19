local _,L = ...


MJExistingsListsMixin = {}


function MJExistingsListsMixin:onLoad()
	self.journal = MountsJournalFrame
	self.util = MountsJournalUtil
	self.child = self.scrollFrame.child
	self.optionsButtonPool = CreateFramePool("BUTTON", self.child, "MJOptionButtonTemplate", function(_,frame)
		frame:Hide()
		frame:ClearAllPoints()
		frame:Enable()
	end)
	self.lists = {}
	local listsInfo = {
		L["Zones with list"],
		L["Zones with relation"],
		L["Zones with flags"],
	}

	for i, name in ipairs(listsInfo) do
		local button = CreateFrame("CheckButton", nil, self.child, "MJCollapseButtonTemplate")
		button:SetText(name)
		button.childs = {}
		button:SetScript("OnClick", function(btn)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			self:collapse(btn, i)
		end)
		tinsert(self.lists, button)
	end

	self.lists[1]:SetPoint("TOPLEFT", self.child)
	self.lists[1]:SetPoint("TOPRIGHT", self.child)
end


function MJExistingsListsMixin:collapse(btn, i)
	local checked = btn:GetChecked()
	btn.toggle.plusMinus:SetTexture(checked and "Interface/Buttons/UI-PlusButton-UP" or "Interface/Buttons/UI-MinusButton-UP")

	for _,child in ipairs(btn.childs) do
		child:SetShown(not checked)
	end

	local nextButton = self.lists[i + 1]
	if nextButton then
		local relativeFrame = checked and btn or btn.childs[#btn.childs]
		nextButton:SetPoint("TOPLEFT", relativeFrame,"BOTTOMLEFT")
		nextButton:SetPoint("TOPRIGHT", relativeFrame,"BOTTOMRIGHT")
	end
end


function MJExistingsListsMixin:refresh()
	if not self:IsVisible() then return end
	local lastWidth = 0

	for _,withList in ipairs(self.lists) do
		local width = withList.text:GetStringWidth()
		if width > lastWidth then
			lastWidth = width
		end
		wipe(withList.childs)
	end
	self.optionsButtonPool:ReleaseAll()
	lastWidth = lastWidth + 10

	local function createOptionButton(mapID)
		local optionButton = self.optionsButtonPool:Acquire()
		optionButton:SetText(self.util.getMapFullNameInfo(mapID).name)
		optionButton:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			self.journal.navBar:setMapID(mapID)
		end)
		local width = optionButton.text:GetStringWidth()
		if width > lastWidth then
			lastWidth = width
		end
		return optionButton
	end

	for mapID, mapConfig in pairs(self.journal.db.zoneMounts) do
		if mapConfig.listFromID then
			tinsert(self.lists[2].childs, createOptionButton(mapID))
		elseif #mapConfig.fly + #mapConfig.ground + #mapConfig.swimming ~= 0 then
			tinsert(self.lists[1].childs, createOptionButton(mapID))
		end

		local flags
		for _, value in pairs(mapConfig.flags) do
			if value then
				flags = true
				break
			end
		end

		if flags then
			tinsert(self.lists[3].childs, createOptionButton(mapID))
		end
	end

	for i, withList in ipairs(self.lists) do
		sort(withList.childs, function(a, b) return a:GetText() < b:GetText() end)

		if #withList.childs == 0 then
			local optionButton = self.optionsButtonPool:Acquire()
			optionButton:SetText(EMPTY)
			optionButton:Disable()
			tinsert(withList.childs, optionButton)
		end

		local lastChild
		for _,child in ipairs(withList.childs) do
			local relativeFrame = lastChild or withList
			child:SetPoint("TOPLEFT", relativeFrame, "BOTTOMLEFT")
			child:SetPoint("TOPRIGHT", relativeFrame, "BOTTOMRIGHT")
			lastChild = child
		end
		self:collapse(withList, i)
	end

	self.child:SetWidth(lastWidth + 35)
	self:SetWidth(lastWidth + 65)
end