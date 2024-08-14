local addon, ns = ...
local L = ns.L


ns.journal:on("MODULES_INIT", function(journal)
	local dd = LibStub("LibSFDropDown-1.5"):CreateStretchButtonOriginal(journal.mapSettings, nil, 24)
	dd:SetPoint("TOPLEFT", journal.mapSettings.mapControl, "TOPLEFT", 3, -3)
	dd:SetPoint("RIGHT", journal.mapSettings.CurrentMap, "LEFT", 2, 0)
	dd:SetText(L["Dungeons and Raids"])
	dd.navBar = journal.navBar
	journal.mapSettings.dnr = dd

	if C_AddOns.IsAddOnLoaded("Blizzard_EncounterJournal") then
		local oldOnEvent = EncounterJournal:GetScript("OnEvent")
		EncounterJournal:SetScript("OnEvent", function(self, event, ...)
			if event ~= "EJ_LOOT_DATA_RECIEVED" and event ~= "EJ_DIFFICULTY_UPDATE" or self:IsShown() then
				oldOnEvent(self, event, ...)
			end
		end)
	end

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
				local _,_,_,_,_,_, mapID = EJ_GetInstanceInfo(instanceID)
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
	if EncounterJournal then
		if EncounterJournal.instanceID then EJ_SelectInstance(EncounterJournal.instanceID) end
		if EncounterJournal.encounterID then EJ_SelectEncounter(EncounterJournal.encounterID) end
	end

	dd:ddSetDisplayMode(addon)
	dd:ddSetValue(list)
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
end)