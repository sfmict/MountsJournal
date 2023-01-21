local addon, L = ...
local list = {
	{
		name = DUNGEONS,
		list = {},
	},
	{
		name = RAIDS,
		list = {},
	}
}

local mapExclude = {
	[379] = true, -- Вершина Кун-Лай
	[543] = true, -- Горгронд
	[929] = true, -- Точка массированного вторжения: госпожа Фолнуна
}

local currentTier = EJ_GetCurrentTier()
for i = 1, EJ_GetNumTiers() do
	EJ_SelectTier(i)
	for _, v in ipairs(list) do
		v.list[i] = {
			name = EJ_GetTierInfo(i),
			list = {},
		}
		local showRaid = v.name == RAIDS
		local index = 1
		local instanceID, instanceName = EJ_GetInstanceByIndex(index, showRaid)
		while instanceID do
			EJ_SelectInstance(instanceID)
			local _,_,_,_,_,_, mapID = EJ_GetInstanceInfo()
			if mapID and mapID > 0 and not mapExclude[mapID] then
				tinsert(v.list[i].list, {name = instanceName, mapID = mapID})
			end
			index = index + 1
			instanceID, instanceName = EJ_GetInstanceByIndex(index, showRaid)
		end
		if #v.list[i].list == 0 then v.list[i] = nil end
	end
end
EJ_SelectTier(currentTier)


MountsJournalFrame:on("MODULES_INIT", function(journal)
	local dd = LibStub("LibSFDropDown-1.4"):CreateStretchButtonOriginal(journal.mapSettings, nil, 24)
	dd:SetPoint("TOPLEFT", journal.mapSettings.mapControl, "TOPLEFT", 3, -3)
	dd:SetPoint("RIGHT", journal.mapSettings.CurrentMap, "LEFT", 2, 0)
	dd:SetText(L["Dungeons and Raids"])
	dd.navBar = journal.navBar
	journal.mapSettings.dnr = dd

	dd:ddSetDisplayMode(addon)
	dd:ddSetInitFunc(function(self, level, value)
		local info = {}

		info.isNotRadio = true
		info.notCheckable = true

		for _, v in ipairs(value) do
			info.text = v.name
			if v.list then
				info.keepShownOnClick = true
				info.hasArrow = true
				info.value = v.list
			else
				info.func = function()
					self.navBar:setMapID(v.mapID)
				end
			end
			self:ddAddButton(info, level)
		end
	end)

	dd:SetScript("OnClick", function(self)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self:ddToggle(1, list, self, 112, 18)
	end)
end)