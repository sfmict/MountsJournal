local _, L = ...
local mounts, config = MountsJournal, MountsJournalConfig
local journal = CreateFrame("Frame", "MountsJournalFrame")


journal.colors = {
	["gold"] = {0.8, 0.6, 0},
	["gray"] = {0.5, 0.5, 0.5},
}


journal:SetScript("OnEvent", function(self, event, ...)
	if journal[event] then
		journal[event](self, ...)
	end
end)
journal:RegisterEvent("ADDON_LOADED")


function journal:ADDON_LOADED(addonName)
	if addonName == "Blizzard_Collections" and IsAddOnLoaded("MountsJournal") or addonName == "MountsJournal" and IsAddOnLoaded("Blizzard_Collections") then
		self:UnregisterEvent("ADDON_LOADED")

		-- SETTINGS BUTTON
		local btnConfig = CreateFrame("Button", "MountsJournalBtnConfig", MountJournal, "UIPanelButtonTemplate")
		btnConfig:SetSize(80, 22)
		btnConfig:SetPoint("TOPLEFT", MountJournal.MountCount, "TOPRIGHT", 8, 1)
		btnConfig:SetText(L["Settings"])
		btnConfig:SetScript("OnClick", config.openConfig)

		-- PER CHARACTER CHECK
		local perCharCheck = CreateFrame("CheckButton", "MountsJournalPerChar", MountJournal, "InterfaceOptionsCheckButtonTemplate")
		perCharCheck:SetPoint("TOPLEFT", btnConfig, "TOPRIGHT", 6, 2)
		perCharCheck.label = _G[perCharCheck:GetName().."Text"]
		perCharCheck.label:SetFont("GameFontHighlight", 30)
		perCharCheck.label:SetPoint("LEFT", perCharCheck, "RIGHT", 1, 0)
		perCharCheck.label:SetSize(150, 35)
		perCharCheck.label:SetText(L["Character Specific Mount List"])
		perCharCheck:SetChecked(mounts.perChar)
		perCharCheck:SetScript("OnClick", function(self)
			mounts:setMountsList(self:GetChecked())
			journal:configureJournal()
		end)

		-- BUTTONS
		journal.buttons = MountJournal.ListScrollFrame.buttons
		local texPath = "Interface/AddOns/MountsJournal/textures/"

		local function CreateButton(name, parent, pointX, pointY, bgTex, OnClick)
			local btnFrame = CreateFrame("button", nil, parent)
			btnFrame:SetPoint("TOPRIGHT", pointX, pointY)
			btnFrame:SetSize(24, 12)
			btnFrame:SetScript("OnClick", OnClick)
			parent[name] = btnFrame

			btnFrame:SetNormalTexture(texPath.."button.blp")
			btnFrame:SetHighlightTexture(texPath.."button.blp")
			local background, hightlight = btnFrame:GetRegions()
			background:SetTexCoord(0.00390625, 0.8203125, 0.00390625, 0.18359375)
			background:SetVertexColor(0.2,0.18,0.01)
			hightlight:SetTexCoord(0.00390625, 0.8203125, 0.19140625, 0.37109375)

			btnFrame.check = btnFrame:CreateTexture(nil, "OVERLAY")
			btnFrame.check:SetTexture(texPath.."button.blp")
			btnFrame.check:SetTexCoord(0.00390625, 0.8203125, 0.37890625, 0.55859375)
			btnFrame.check:SetVertexColor(unpack(journal.colors.gold))
			btnFrame.check:SetAllPoints()

			btnFrame.icon = btnFrame:CreateTexture(nil, "OVERLAY")
			btnFrame.icon:SetTexture(bgTex)
			btnFrame.icon:SetAllPoints()
		end

		for _, child in pairs(journal.buttons) do
			child:SetWidth(child:GetWidth() - 25)
			child.name:SetWidth(child.name:GetWidth() - 18)

			CreateButton("fly", child, 25, -3, texPath.."fly.blp", function(self)
				journal:mountToggle(mounts.list.fly, self)
			end)
			CreateButton("ground", child, 25, -17, texPath.."ground.blp", function(self)
				journal:mountToggle(mounts.list.ground, self)
			end)
			CreateButton("swimming", child, 25, -31, texPath.."swimming.blp", function(self)
				journal:mountToggle(mounts.list.swimming, self)
			end)
		end

		-- FILTERS SEARTCH
		MountJournal.searchBox:SetPoint("TOPLEFT", MountJournal.LeftInset, "TOPLEFT", 34, -9)
		MountJournal.searchBox:SetSize(128, 20)

		-- FILTERS TOGGLE BTN
		local btnToggle = CreateFrame("button", nil, MountJournal.LeftInset)
		btnToggle:SetPoint("TOPLEFT", MountJournal.LeftInset, "TOPLEFT", 4, -7)
		btnToggle:SetSize(24, 24)
		btnToggle:SetHitRectInsets(-2, -2, -2, -2)

		btnToggle.TopLeft = btnToggle:CreateTexture(nil, "BACKGROUND")
		btnToggle.TopLeft:SetTexture("Interface/Buttons/UI-Silver-Button-Up")
		btnToggle.TopLeft:SetTexCoord(0, 0.1015625, 0, 0.1875)
		btnToggle.TopLeft:SetSize(13, 6)
		btnToggle.TopLeft:SetVertexColor(0.65, 0.65, 0.65)
		btnToggle.TopLeft:SetPoint("TOPLEFT")

		btnToggle.TopRight = btnToggle:CreateTexture(nil, "BACKGROUND")
		btnToggle.TopRight:SetTexture("Interface/Buttons/UI-Silver-Button-Up")
		btnToggle.TopRight:SetTexCoord(0.5234375, 0.625, 0, 0.1875)
		btnToggle.TopRight:SetSize(13, 6)
		btnToggle.TopRight:SetVertexColor(0.65, 0.65, 0.65)
		btnToggle.TopRight:SetPoint("TOPRIGHT")

		btnToggle.BottomLeft = btnToggle:CreateTexture(nil, "BACKGROUND")
		btnToggle.BottomLeft:SetTexture("Interface/Buttons/UI-Silver-Button-Up")
		btnToggle.BottomLeft:SetTexCoord(0, 0.1015625, 0.625, 0.8125)
		btnToggle.BottomLeft:SetSize(13, 6)
		btnToggle.BottomLeft:SetVertexColor(0.65, 0.65, 0.65)
		btnToggle.BottomLeft:SetPoint("BOTTOMLEFT")

		btnToggle.BottomRight = btnToggle:CreateTexture(nil, "BACKGROUND")
		btnToggle.BottomRight:SetTexture("Interface/Buttons/UI-Silver-Button-Up")
		btnToggle.BottomRight:SetTexCoord(0.5234375, 0.625, 0.625, 0.8125)
		btnToggle.BottomRight:SetSize(13, 6)
		btnToggle.BottomRight:SetVertexColor(0.65, 0.65, 0.65)
		btnToggle.BottomRight:SetPoint("BOTTOMRIGHT")

		btnToggle.Left = btnToggle:CreateTexture(nil, "BACKGROUND")
		btnToggle.Left:SetTexture("Interface/Buttons/UI-Silver-Button-Up")
		btnToggle.Left:SetTexCoord(0, 0.09375, 0.1875, 0.625)
		btnToggle.Left:SetSize(12, 14)
		btnToggle.Left:SetVertexColor(0.65, 0.65, 0.65)
		btnToggle.Left:SetPoint("LEFT")

		btnToggle.Right = btnToggle:CreateTexture(nil, "BACKGROUND")
		btnToggle.Right:SetTexture("Interface/Buttons/UI-Silver-Button-Up")
		btnToggle.Right:SetTexCoord(0.53125, 0.625, 0.1875, 0.625)
		btnToggle.Right:SetSize(12, 14)
		btnToggle.Right:SetVertexColor(0.65, 0.65, 0.65)
		btnToggle.Right:SetPoint("RIGHT")

		btnToggle.Icon = btnToggle:CreateTexture(nil, "ARTWORK")
		btnToggle.Icon:SetTexture("Interface/ChatFrame/ChatFrameExpandArrow")
		-- btnToggle.Icon:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)
		btnToggle.Icon:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)
		-- btnToggle.Icon:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)
		btnToggle.Icon:SetSize(14, 14)
		btnToggle.Icon:SetPoint("CENTER", 0, -1)

		-- HOOKS
		journal.func = {}
		journal:setSecureFunc(C_MountJournal, "GetNumDisplayedMounts", function() return #journal.displayedMounts end)
		journal:setSecureFunc(C_MountJournal, "GetDisplayedMountInfo")
		journal:setSecureFunc(C_MountJournal, "Pickup")
		journal:setSecureFunc(C_MountJournal, "SetIsFavorite")
		journal:setSecureFunc(C_MountJournal, "GetIsFavorite")
		journal:setSecureFunc(C_MountJournal, "GetDisplayedMountInfoExtra")
		journal:setSecureFunc(C_MountJournal, "GetDisplayedMountAllCreatureDisplayInfo")

		local updateMountList = MountJournal_UpdateMountList
		function MountJournal_UpdateMountList()
			journal:setDisplayedMounts()
			updateMountList()
			journal:configureJournal()
		end
		MountJournal.ListScrollFrame.update = MountJournal_UpdateMountList

		journal:setDisplayedMounts()
	end
end


function journal:configureJournal()
	local function setColor(btn, mountsTbl)
		if mounts:inTable(mountsTbl, btn.mountID) then
			btn.icon:SetVertexColor(unpack(journal.colors.gold))
			if not btn.check:IsShown() then btn.check:Show() end
		else
			btn.icon:SetVertexColor(unpack(journal.colors.gray))
			if btn.check:IsShown() then btn.check:Hide() end
		end
	end

	for _, btn in pairs(journal.buttons) do
		if btn.index then
			if not btn.fly:IsShown() then
				btn.fly:Show()
				btn.ground:Show()
				btn.swimming:Show()
			end
			btn.fly.mountID = select(12, C_MountJournal.GetDisplayedMountInfo(btn.index))
			btn.ground.mountID = btn.fly.mountID
			btn.swimming.mountID = btn.fly.mountID
			setColor(btn.fly, mounts.list.fly)
			setColor(btn.ground, mounts.list.ground)
			setColor(btn.swimming, mounts.list.swimming)
		else
			if btn.fly:IsShown() then
				btn.fly:Hide()
				btn.ground:Hide()
				btn.swimming:Hide()
			end
		end
	end
end


function journal:mountToggle(tbl, btn)
	local pos = mounts:inTable(tbl, btn.mountID)
	if pos then
		tremove(tbl, pos)
		btn.icon:SetVertexColor(unpack(journal.colors.gray))
		btn.check:Hide()
	else
		tinsert(tbl, btn.mountID)
		btn.icon:SetVertexColor(unpack(journal.colors.gold))
		btn.check:Show()
	end
end


function journal:setSecureFunc(obj, funcName, func)
	if journal.func[funcName] ~= nil then return end

	journal.func[funcName] = obj[funcName]
	if func then
		obj[funcName] = func
	else
		obj[funcName] = function(index, ...)
			return journal.func[funcName](journal.displayedMounts[index], ...)
		end
	end
end


function journal:setDisplayedMounts()
	local displayedMounts = {}
	for i = 1, journal.func.GetNumDisplayedMounts() do
		local mountID = select(12, journal.func.GetDisplayedMountInfo(i))
		local mountType = select(5, C_MountJournal.GetMountInfoExtraByID(mountID))
		-- if mountType == 248 then
			tinsert(displayedMounts, i)
		-- end
	end

	journal.displayedMounts = displayedMounts
end