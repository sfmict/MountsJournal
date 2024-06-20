local _, L = ...


MJExistingListsMixin = {}


function MJExistingListsMixin:onLoad()
	self.util = MountsJournalUtil
	self.journal = MountsJournalFrame

	self.searchBox:SetScript("OnTextChanged", function(searchBox)
		SearchBoxTemplate_OnTextChanged(searchBox)
		self:refresh()
	end)

	self.categories = {
		{name = L["Zones with list"], expanded = true},
		{name = L["Zones with relation"], expanded = true},
		{name = L["Zones with flags"], expanded = true},
	}

	self.toggleOnClick = function(btn)
		btn.category.expanded = not btn.category.expanded
		self:refresh()
	end
	self.buttonOnClick = function(btn)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self.journal.navBar:setMapID(btn.mapID)
	end

	local function toggleInit(...) self:toggleInit(...) end
	local function buttonInit(...) self:buttonInit(...) end
	local function Factory(factory, data)
		if data.id then
			factory("MJCollapseButtonTemplate", toggleInit)
		else
			factory("MJOptionButtonTemplate", buttonInit)
		end
	end

	self.view = CreateScrollBoxListLinearView()
	self.view:SetElementFactory(Factory)
	ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.scrollBar, self.view)
end


function MJExistingListsMixin:toggleInit(btn, data)
	btn:SetText(data.name)
	btn.category = self.categories[data.id]
	btn.toggle:SetTexture(btn.category.expanded and "Interface/Buttons/UI-MinusButton-UP" or "Interface/Buttons/UI-PlusButton-UP")
	btn:SetScript("OnClick", self.toggleOnClick)
end


function MJExistingListsMixin:buttonInit(btn, data)
	btn:SetText(data.name)
	btn:SetEnabled(not data.disabled)
	local color = data.isGray and GRAY_FONT_COLOR or WHITE_FONT_COLOR
	btn.text:SetTextColor(color:GetRGB())
	btn.mapID = data.mapID
	btn:SetScript("OnClick", self.buttonOnClick)
end


function MJExistingListsMixin:getTextWidth(data)
	local frames = self.view:GetFrames()
	if #frames == 0 then
		self.view:AcquireInternal(1, data)
		self.view:InvokeInitializers()
	end
	frames[1]:SetText(data.name)
	return frames[1].text:GetStringWidth()
end


function MJExistingListsMixin:addCategory(dataProvider, id, tbl)
	local category = self.categories[id]
	local data = {name = ("%s [%d]"):format(self.categories[id].name, #tbl), id = id}
	self.lastWidth = math.max(self.lastWidth, self:getTextWidth(data))
	dataProvider:Insert(data)

	if category.expanded then
		if #tbl == 0 then
			tbl[1] = {name = EMPTY, isGray = true, disabled = true}
		elseif #tbl > 1 then
			sort(tbl, function(a, b)
				return not a.isGray and b.isGray
					or a.isGray == b.isGray and a.name < b.name
			end)
		end
		for i = 1, #tbl do dataProvider:Insert(tbl[i]) end
	end
end


do
	local function getTextBool(bool)
		return bool and "+" or "-"
	end

	function MJExistingListsMixin:refresh()
		if not self:IsVisible() then return end
		self.lastWidth = 0
		local text = self.util.cleanText(self.searchBox:GetText())
		local list, relation, flags = {}, {}, {}

		local function addData(tbl, mapID, groupID, flags)
			local btnText = self.util.getMapFullNameInfo(mapID).name
			if groupID then
				btnText = ("[%d] %s"):format(groupID, btnText)
			elseif flags then
				btnText = ("%s [%s%s%s]"):format(
					btnText,
					getTextBool(flags.groundOnly),
					getTextBool(flags.waterWalkOnly),
					getTextBool(flags.herbGathering)
				)
			end
			if #text == 0 or btnText:lower():find(text, 1, true) then
				local data = {
					name = btnText,
					mapID = mapID,
					isGray = flags and not flags.enableFlags
				}
				self.lastWidth = math.max(self.lastWidth, self:getTextWidth(data))
				tbl[#tbl + 1] = data
			end
		end

		for mapID, mapConfig in pairs(self.journal.zoneMounts) do
			if mapConfig.listFromID then
				addData(relation, mapID, mapConfig.listFromID)
			elseif next(mapConfig.fly) or next(mapConfig.ground) or next(mapConfig.swimming) then
				addData(list, mapID)
			end

			local flagExists
			for _, value in pairs(mapConfig.flags) do
				if value then
					flagExists = true
					break
				end
			end
			if flagExists then addData(flags, mapID, nil, mapConfig.flags) end
		end

		local dataProvider = CreateDataProvider()
		self:addCategory(dataProvider, 1, list)
		self:addCategory(dataProvider, 2, relation)
		self:addCategory(dataProvider, 3, flags)
		self.scrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)

		self:SetWidth(self.lastWidth + 65)
	end
end