local addon, ns = ...
local L, util, mounts = ns.L, ns.util, ns.mounts


ns.journal:on("MODULES_INIT", function(journal)
	local stFr = CreateFrame("FRAME", nil, nil, "DefaultPanelTemplate,MJEscHideTemplate")
	journal.statsFrame = stFr
	stFr:Hide()

	stFr:SetScript("OnDragStart", stFr.StartMoving)
	stFr:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local x, y = self:GetCenter()
		local scale = self:GetEffectiveScale()
		mounts.config.statisticFrameX = x * scale
		mounts.config.statisticFrameY = y * scale
	end)
	stFr:HookScript("OnHide", stFr.Hide)

	local escOnShow = stFr:GetScript("OnShow")
	stFr:SetScript("OnShow", function(self)
		self:SetSize(356, 434)
		self:SetParent(journal.bgFrame) -- TitleContainer frameLevel fix
		self:SetFrameLevel(journal.bgFrame:GetFrameLevel() + 1001)
		self:SetFlattensRenderLayers(true)
		self:SetClampedToScreen(true)
		self:EnableMouse(true)
		self:SetMovable(true)
		self:RegisterForDrag("LeftButton")
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
		self.close:SetFrameLevel(self:GetFrameLevel() + 520)
		self.close:SetScript("OnClick", function(btn)
			btn:GetParent():Hide()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		end)

		-- COMBOBOX
		self.statsType = LibStub("LibSFDropDown-1.5"):CreateModernButtonOriginal(self)
		self.statsType:SetPoint("TOPLEFT", 8, -22)
		self.statsType:SetPoint("RIGHT", -4, 0)

		self.statsType:ddSetDisplayMode(addon)
		self.statsType:ddSetMinMenuWidth(self.statsType:GetWidth() - 20)
		self.statsType:ddSetSelectedValue(1)
		self.statsType:ddSetSelectedText(L["Latest Additions"])

		self.statsType:ddSetInitFunc(function(dd, level)
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

		-- MODES
		self.statsModes = {
			[1] = { -- Latest Additions
				getValue = function(spellID)
					local value = mounts:getMountDate(spellID)
					if value then return value, util.formatDate(value) end
				end,
			},
			[2] = { -- Summons
				getValue = function(spellID)
					local value = mounts:getMountSummons(spellID)
					if value > 0 then return value, value end
				end,
				getTotal = function(self, mode)
					return self.totalStr:format(mode.sumValue)
				end,
			},
			[3] = { -- Travel time
				getValue = function(spellID)
					local value = mounts:getMountTime(spellID)
					if value > 0 then return value, util.timeBreakDown(value) end
				end,
				getTotal = function(self, mode)
					return self.totalStr:format(util.timeBreakDown(mode.sumValue))
				end,
			},
			[4] = { -- Travel distance
				getValue = function(spellID)
					local value = mounts:getMountDistance(spellID)
					if value > 0 then return value, util:formatDistance(value) end
				end,
				getTotal = function(self, mode)
					return self.totalStr:format(util:formatDistance(mode.sumValue))
				end,
			},
			[5] = { -- Avg. speed
				getValue = function(spellID, mode)
					local mTime = mounts:getMountTime(spellID)
					local distance = mounts:getMountDistance(spellID)
					if mTime and mTime > 0 and distance then
						local value = distance / mTime
						mode.sumTime = mode.sumTime + mTime
						mode.sumDistance = mode.sumDistance + distance
						return value, util:formatAvgSpeed(value)
					end
				end,
				getTotal = function(self, mode)
					return L["Avg. speed"]..":  "..util:formatAvgSpeedByTimeDistance(mode.sumTime, mode.sumDistance)
				end,
			},
		}

		-- INSET
		self.inset = CreateFrame("FRAME", nil, self, "InsetFrameTemplate")
		self.inset:SetPoint("TOP", self.statsType, "BOTTOM")
		self.inset:SetPoint("LEFT", 8, 0)
		self.inset:SetPoint("BOTTOMRIGHT", -20, 20)

		-- BUTTON LIST INIT
		local function btnEnter(btn)
			GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
			GameTooltip:SetText(btn.data.name)

			local spellID = btn.data.spellID
			local mountDate = mounts:getMountDate(spellID)
			if mountDate then
				util.addTooltipDLine(L["Receipt date"], util.formatDate(mountDate))
			end

			local summons = mounts:getMountSummons(spellID)
			if summons > 0 then
				 util.addTooltipDLine(SUMMONS, summons)
			end

			local mountTime = mounts:getMountTime(spellID)
			if mountTime > 0 then
				util.addTooltipDLine(L["Travel time"], util.timeBreakDown(mountTime))
			end

			local mountDistance = mounts:getMountDistance(spellID)
			if mountDistance > 0 then
				util.addTooltipDLine(L["Travel distance"], util:formatDistance(mountDistance))
				util.addTooltipDLine(L["Avg. speed"], util:formatAvgSpeedByTimeDistance(mountTime, mountDistance))
			end

			GameTooltip:Show()
		end
		local function btnClick(btn)
			journal:setSelectedMount(btn.data.mount)
		end

		local function onAcquire(owner, btn, data, new)
			if new then
				btn:SetScript("OnEnter", btnEnter)
				btn:SetScript("OnLeave", GameTooltip_Hide)
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
		self.view:SetElementInitializer("MJMountStatsListButtonTemplate", function(...) self:buttonInit(...) end)
		self.view:RegisterCallback(self.view.Event.OnAcquiredFrame, onAcquire, self)

		ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.scrollBar, self.view)

		-- TOTAL
		self.totalFontStr = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		self.totalFontStr:SetPoint("BOTTOMRIGHT", -30, 5)
		self.totalStr = TOTAL..":  %s"

		-- INIT
		self:SetScript("OnShow", function(self)
			escOnShow(self)
			self:updateList()
		end)
		self:GetScript("OnShow")(self)
	end)

	function stFr:buttonInit(btn, data)
		local qualityColor = data.isMount and util.getRarityColor(data.mount) or HIGHLIGHT_FONT_COLOR

		btn.dragButton.icon:SetTexture(data.icon)
		btn.dragButton.qualityBorder:SetVertexColor(qualityColor:GetRGB())
		btn.dragButton.hidden:SetShown(journal:isMountHidden(data.spellID))
		btn.dragButton.favorite:SetShown(data.isFavorite)

		btn.data = data
		btn.name:SetText(data.name)
		btn.name:SetTextColor((mounts.config.coloredMountNames and qualityColor or NORMAL_FONT_COLOR):GetRGB())
		btn.value:SetText(data.fValue)

		local statShown = self.statsType:ddGetSelectedValue() ~= 1
		btn.stat:SetShown(statShown)
		if statShown then
			btn.stat:SetWidth((btn.background:GetWidth() - 6) * data.value / self.maxValue)
		end
	end

	function stFr:updateList()
		local selectedType = self.statsType:ddGetSelectedValue()
		local mode = self.statsModes[selectedType]
		local list = {}
		self.maxValue = 0
		mode.sumValue, mode.sumTime, mode.sumDistance = 0, 0, 0

		for i = 1, #journal.mountIDs do
			local mount = journal.mountIDs[i]
			local isMount, name, spellID, icon, _,_,_, isFavorite = util.getMountInfo(mount)
			local value, fValue = mode.getValue(spellID, mode)
			if value then
				list[#list + 1] = {
					mount = mount,
					isMount = isMount,
					name = name,
					spellID = spellID,
					icon = icon,
					isFavorite = isFavorite,
					value = value,
					fValue = fValue,
				}
				self.maxValue = math.max(self.maxValue, value)
				mode.sumValue = mode.sumValue + value
			end
		end

		local hasTotal = mode.getTotal ~= nil
		self.totalFontStr:SetShown(hasTotal)
		if hasTotal then
			self.totalFontStr:SetText(mode.getTotal(self, mode))
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