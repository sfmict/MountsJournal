local mounts = MountsJournal
local journal = CreateFrame("Frame", "MountsJounralFrames")

journal.colors = {
	function() return 0.2, 0.1843137254901961, 0.01568627450980392, 1 end,
	function() return 0.8941176470588236, 0.7176470588235294, 0.11372549019607843, 1 end,
}


function journal:inTable(table, item)
	for key, value in pairs(table) do
		if value == item then
			return key
		end
	end
	return false
end


journal:SetScript("OnEvent", function(self, event, ...)
	if journal[event] then
		journal[event](self, ...)
	end
end)
journal:RegisterEvent("ADDON_LOADED")


function journal:ADDON_LOADED(addon)
	if addon == "Blizzard_Collections" then
		journal:Blizzard_Collections()
	end

	if addon == "CursorMod" then
		if not journal.Blizzard_Collections_Loaded and IsAddOnLoaded("Blizzard_Collections") then
			mounts.Journal:Blizzard_Collections()
			print("bliz")
		end
	end
end


function journal:Blizzard_Collections()
	journal.Blizzard_Collections_Loaded = true

	MountJournal:HookScript("OnShow", journal.configureJournal)
	MountJournalListScrollFrame:HookScript("OnUpdate", journal.configureJournal)
	-- journal:RegisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")
	-- journal:RegisterEvent("COMPANION_LEARNED")
	-- journal:RegisterEvent("COMPANION_UNLEARNED")
	-- journal:RegisterEvent("COMPANION_UPDATE")
	-- journal:RegisterEvent("MOUNT_JOURNAL_SEARCH_UPDATED")

	journal.flyButtons = {}
	journal.groundButtons = {}
	journal.swimmingButtons = {}

	local function CreateButton(parent, pointX, pointY, bg, OnClick)
		local btnFrame = CreateFrame("button", nil, parent)
		-- mountFrame:SetNormalTexture("Interface\\AddOns\\CursorMod\\texture\\point.blp")
		local btnTex = btnFrame:CreateTexture(nil, "BACKGROUND")
		btnFrame.background = btnTex
		btnTex:SetAllPoints()
		btnTex:SetColorTexture(journal.colors[1]())
		btnFrame:SetPoint("TOPRIGHT", pointX, pointY)
		btnFrame:SetSize(18, 12)
		btnFrame:SetScript("OnClick", OnClick)
		return btnFrame
	end

	for _,child in pairs({MountJournalListScrollFrameScrollChild:GetChildren()}) do
		tinsert(journal.flyButtons, CreateButton(child, -2, -2, nil, function(self)
			journal:mountToggle(mounts.fly, self, self.mountID)
		end))
		tinsert(journal.groundButtons, CreateButton(child, -2, -17, nil, function(self)
			journal:mountToggle(mounts.ground, self, self.mountID)
		end))
		tinsert(journal.swimmingButtons, CreateButton(child, -2, -32, nil, function(self)
			journal:mountToggle(mounts.swimming, self, self.mountID)
		end))
	end
end


function journal:configureJournal()
	local function setTexture(buttonsTbl, mountsTbl)
		for _,btn in pairs(buttonsTbl) do
			local index = btn:GetParent().index
			if index then
				if not btn:IsShown() then btn:Show() end
				btn.mountID = select(12, C_MountJournal.GetDisplayedMountInfo(index))
				if journal:inTable(mountsTbl, btn.mountID) then
					btn.background:SetColorTexture(journal.colors[2]())
				else
					btn.background:SetColorTexture(journal.colors[1]())
				end
			else
				if btn:IsShown() then btn:Hide() end
			end
		end
	end

	setTexture(journal.flyButtons, mounts.fly)
	setTexture(journal.groundButtons, mounts.ground)
	setTexture(journal.swimmingButtons, mounts.swimming)
end


function journal:mountToggle(tbl, button, mountID)
	local pos = journal:inTable(tbl, mountID)
	if pos then
		tremove(tbl, pos)
		button.background:SetColorTexture(journal.colors[1]())
	else
		tinsert(tbl, mountID)
		button.background:SetColorTexture(journal.colors[2]())
	end
end