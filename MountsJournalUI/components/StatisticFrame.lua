local addon, ns = ...
local L, util, mounts = ns.L, ns.util, ns.mounts


ns.journal:on("MODULES_INIT", function(journal)
	local stFr = CreateFrame("FRAME", nil, journal.bgFrame, "DefaultPanelTemplate,MJEscHideTemplate")
	journal.statisticFrame = stFr
	stFr:SetSize(352, 424)
	stFr:SetFrameLevel(journal.bgFrame:GetFrameLevel() + 1001)
	stFr:SetFlattensRenderLayers(true)
	stFr:SetClampedToScreen(true)
	stFr:EnableMouse(true)
	stFr:SetMovable(true)
	stFr:RegisterForDrag("LeftButton")

	stFr:SetScript("OnDragStart", stFr.StartMoving)
	stFr:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local x, y = self:GetCenter()
		local scale = self:GetEffectiveScale()
		mounts.config.statisticFrameX = x * scale
		mounts.config.statisticFrameY = y * scale
	end)
	stFr:HookScript("OnHide", function(self)
		self:Hide()
	end)

	stFr:HookScript("OnShow", function(self)
		self:SetTitle(STATISTICS)

		-- POSITION
		self:ClearAllPoints()
		if mounts.config.statisticFrameX and mounts.config.statisticFrameY then
			local scale = self:GetEffectiveScale()
			self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", mounts.config.statisticFrameX / scale, mounts.config.statisticFrameY / scale)
		else
			self:SetPoint("TOP", 0, -60)
		end

		-- CLOSE
		self.close = CreateFrame("BUTTON", nil, self, "UIPanelCloseButtonNoScripts")
		self.close:SetSize(22, 22)
		self.close:SetPoint("TOPRIGHT", 0, 0)
		self.close:SetFrameLevel(self:GetFrameLevel() + 1)
		self.close:SetScript("OnClick", function(btn)
			btn:GetParent():Hide()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		end)

		-- COMBOBOX
		self.statisticType = LibStub("LibSFDropDown-1.5"):CreateModernButtonOriginal(self)
		self.statisticType:SetPoint("TOPLEFT", 8, -22)
		self.statisticType:SetPoint("RIGHT", -4, 0)

		self.statisticType:ddSetDisplayMode(addon)
		self.statisticType:ddSetMinMenuWidth(self.statisticType:GetWidth() - 20)
		self.statisticType:ddSetSelectedValue(1)
		self.statisticType:ddSetSelectedText(L["Latest Additions"])

		self.statisticType:ddSetInitFunc(function(dd, level)
			local info = {}

			info.func = function(btn)
				dd:ddSetSelectedValue(btn.value)
				self:updateList()
			end

			for i, v in ipairs({L["Latest Additions"], SUMMONS, L["Travel time"], L["Travel distance"], L["Avg. speed"]}) do
				info.text = v
				info.value = i
				dd:ddAddButton(info, level)
			end
		end)

		-- INSET
		self.inset = CreateFrame("FRAME", nil, self, "InsetFrameTemplate")
		self.inset:SetPoint("TOP", self.statisticType, "BOTTOM")
		self.inset:SetPoint("LEFT", 6, 0)
		self.inset:SetPoint("BOTTOMRIGHT", -18, 5)

		-- BUTTON LIST INIT
		local function btnClick(btn)
			journal:setSelectedMount(btn.mount)
		end

		local function onAcqure(owner, btn, data, new)
			if new then
				btn:SetScript("OnClick", btnClick)
			end
		end

		-- SCROLL
		self.scrollBox = CreateFrame("FRAME", nil, self.inset, "WowScrollBoxList")
		self.scrollBox:SetPoint("TOPLEFT", self.inset, 2, -4)
		self.scrollBox:SetPoint("BOTTOMRIGHT", -4, 3)

		self.scrollBar = CreateFrame("EventFrame", nil, self, "MinimalScrollBar")
		self.scrollBar:SetPoint("TOPLEFT", self.scrollBox, "TOPRIGHT", 8, -2)
		self.scrollBar:SetPoint("BOTTOMLEFT", self.scrollBox, "BOTTOMRIGHT", 8, 0)

		local top = 0
		local bottom = 0
		local left = 41
		local right = 0
		local spacing = 0
		self.view = CreateScrollBoxListLinearView(top, bottom, left, right, spacing)
		self.view:SetElementInitializer("MJMountStatisticListButtonTemplate", function(...) self:buttonInit(...) end)
		self.view:RegisterCallback(self.view.Event.OnAcquiredFrame, onAcqure, self)

		ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.scrollBar, self.view)

		-- INIT
		self:SetScript("OnShow", function(self) self:updateList() end)
		self:GetScript("OnShow")(self)
	end)

	function stFr:buttonInit(btn, data)
		btn.mount = data.mount

		local qualityColor = data.isMount and util.getRarityColor(data.mount) or HIGHLIGHT_FONT_COLOR

		btn.dragButton.icon:SetTexture(data.icon)
		btn.dragButton.qualityBorder:SetVertexColor(qualityColor:GetRGB())
		btn.dragButton.hidden:SetShown(journal:isMountHidden(data.spellID))
		btn.dragButton.favorite:SetShown(data.isFavorite)

		btn.name:SetText(data.name)
		btn.name:SetTextColor((mounts.config.coloredMountNames and qualityColor or NORMAL_FONT_COLOR):GetRGB())

		local selectedType, vText = self.statisticType:ddGetSelectedValue()
		if selectedType == 1 then
			local tDate = date("*t", data.value)
			vText = FormatShortDate(tDate.day, tDate.month, tDate.year)
		elseif selectedType == 2 then
			vText = data.value
		elseif selectedType == 3 then
			vText = util.getTimeBreakDown(data.value)
		elseif selectedType == 4 then
			vText = util:getFormattedDistance(data.value)
		elseif selectedType == 5 then
			vText = util:getFormattedAvgSpeed(data.value)
		end
		btn.value:SetText(vText)

		btn.stat:SetShown(selectedType ~= 1)
		if selectedType ~= 1 then
			btn.stat:SetWidth((btn.background:GetWidth() - 6) * data.value / self.maxValue)
		end
	end

	function stFr:setMountList(list, func)
		self.maxValue = 0
		for i = 1, #journal.mountIDs do
			local mount = journal.mountIDs[i]
			local isMount, name, spellID, icon, _,_,_, isFavorite = util.getMountInfo(mount)
			local value = func(spellID)
			if value and value > 0 then
				list[#list + 1] = {
					mount = mount,
					isMount = isMount,
					name = name,
					spellID = spellID,
					icon = icon,
					isFavorite = isFavorite,
					value = value,
				}
				self.maxValue = math.max(self.maxValue, value)
			end
		end
	end

	function stFr:updateList()
		local list = {}
		local selectedType = self.statisticType:ddGetSelectedValue()

		if selectedType == 1 then
			self:setMountList(list, function(spellID)
				return mounts:getMountDate(spellID)
			end)
		elseif selectedType == 2 then
			self:setMountList(list, function(spellID)
				return mounts:getMountSummons(spellID)
			end)
		elseif selectedType == 3 then
			self:setMountList(list, function(spellID)
				return mounts:getMountTime(spellID)
			end)
		elseif selectedType == 4 then
			self:setMountList(list, function(spellID)
				return mounts:getMountDistance(spellID)
			end)
		elseif selectedType == 5 then
			self:setMountList(list, function(spellID)
				local mTime = mounts:getMountTime(spellID)
				local distance = mounts:getMountDistance(spellID)
				if mTime and mTime > 0 and distance then
					return distance / mTime
				end
			end)
		end

		sort(list, function(a, b)
			if a == b then return false end
			if a.value ~= b.value then return a.value > b.value end
			if a.name ~= b.name then return strcmputf8i(a.name, b.name) < 0 end
			return a.spellID < b.spellID
		end)

		self.dataProvider = CreateDataProvider(list)
		self.scrollBox:SetDataProvider(self.dataProvider, ScrollBoxConstants.RetainScrollPosition)
	end
end)