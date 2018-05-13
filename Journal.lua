local _, L = ...
local mounts, config = MountsJournal, MountsJournalConfig
local journal = CreateFrame("Frame", "MountsJounralFrames")


journal.colors = {
	function() return 0.2, 0.1843137254901961, 0.01568627450980392, 1 end,
	function() return 0.6823529411764706, 0.6431372549019608, 0.20392156862745098, 1 end,
}

-- local colors = {
-- 	["gold"] = {0.8, 0.6, 0}
-- }
-- print(unpack(colors.gold))


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
		end)

		-- BUTTONS
		journal.buttons = {MountJournalListScrollFrameScrollChild:GetChildren()}

		local function CreateButton(name, parent, pointX, pointY, bgTex, OnClick)
			local btnFrame = CreateFrame("button", nil, parent)
			btnFrame:SetPoint("TOPRIGHT", pointX, pointY)
			btnFrame:SetSize(24, 12)
			btnFrame:SetScript("OnClick", OnClick)
			parent[name] = btnFrame

			btnFrame.icon = btnFrame:CreateTexture(nil, "OVERLAY")
			btnFrame.icon:SetTexture(bgTex)
			btnFrame.icon:SetAllPoints()

			btnFrame.check = btnFrame:CreateTexture(nil, "OVERLAY")
			btnFrame.check:SetTexture("Interface/AddOns/MountsJournal/textures/button.blp")
			btnFrame.check:SetTexCoord(0.00390625, 0.8203125, 0.37890625, 0.55859375)
			btnFrame.check:SetAllPoints()
			
			btnFrame:SetNormalTexture("Interface/AddOns/MountsJournal/textures/button.blp")
			btnFrame:SetHighlightTexture("Interface/AddOns/MountsJournal/textures/button.blp")
			local _, _, background, hightlight = btnFrame:GetRegions()
			background:SetTexCoord(0.00390625, 0.8203125, 0.00390625, 0.18359375)
			background:SetVertexColor(0.1,0.05,0)
			hightlight:SetTexCoord(0.00390625, 0.8203125, 0.19140625, 0.37109375)

			-- btnFrame:SetNormalTexture(bgTex)
			-- btnFrame:SetHighligatTexture("Interface/Buttons/CheckButtonHilight-Blue")
			-- btnFrame.icon, btnFrame.hightlight = btnFrame:GetRegions()
			-- btnFrame.hightlight:SetTexCoord(0.25, 0.75, 0.2, 0.8)
			-- btnFrame.hightlight:SetAllPoints()
			-- btnFrame.hightlight:SetBlendMode("ADD")
			-- btnFrame.hightlight:SetVertexColor(0.8,0.6,0)
			-- local btnTex = btnFrame:CreateTexture(nil, "BACKGROUND")
			-- btnFrame.background = btnTex
			-- btnTex:SetAllPoints()
		end

		local texPath = "Interface/AddOns/MountsJournal/textures/"
		for _,child in pairs(journal.buttons) do
			child:SetWidth(child:GetWidth() - 25)
			child.name:SetWidth(child.name:GetWidth() - 18)

			CreateButton("fly", child, 25, -3, texPath.."fly.blp", function(self)
				journal:mountToggle(mounts.list.fly, self, self.mountID)
			end)
			CreateButton("ground", child, 25, -17, texPath.."ground.blp", function(self)
				journal:mountToggle(mounts.list.ground, self, self.mountID)
			end)
			CreateButton("swimming", child, 25, -31, texPath.."swimming.blp", function(self)
				journal:mountToggle(mounts.list.swimming, self, self.mountID)
			end)
		end

		-- EVENTS
		MountJournal:HookScript("OnShow", journal.configureJournal)
		MountJournalListScrollFrame:HookScript("OnUpdate", journal.configureJournal)
	end
end


function journal:configureJournal()
	local function setColor(btn, mountsTbl)
		if mounts:inTable(mountsTbl, btn.mountID) then
			btn.icon:SetVertexColor(0.8,0.6,0)
			btn.check:Show()
			-- btn.background:SetColorTexture(journal.colors[2]())
		else
			btn.icon:SetVertexColor(0.5,0.5,0.5)
			btn.check:Hide()
			-- btn.background:SetColorTexture(journal.colors[1]())
		end
	end

	for _,btn in pairs(journal.buttons) do
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


function journal:mountToggle(tbl, button, mountID)
	local pos = mounts:inTable(tbl, mountID)
	if pos then
		tremove(tbl, pos)
		btn.icon:SetVertexColor(0.5,0.5,0.5)
		-- button.background:SetColorTexture(journal.colors[1]())
	else
		tinsert(tbl, mountID)
		btn.icon:SetVertexColor(0.8,0.6,0)
		-- button.background:SetColorTexture(journal.colors[2]())
	end
end