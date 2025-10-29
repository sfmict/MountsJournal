local addon, ns = ...
local L, util = ns.L, ns.util


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

	local drIconInfo = {
		tCoordLeft = .20,
		tCoordRight = .80,
		tCoordTop = .20,
		tCoordBottom = .80,
	}
	local list = {
		{
			name = DUNGEONS,
			icon = 1488824,
			iconInfo = drIconInfo,
			list = {},
		},
		{
			name = RAIDS,
			icon = 1488825,
			iconInfo = drIconInfo,
			list = {},
		}
	}
	local expIconInfo = {
		tSizeX = 40,
		tSizeY = 20,
	}
	local mapExclude = {
		[379] = true, -- Вершина Кун-Лай
		[543] = true, -- Горгронд
		[929] = true, -- Точка массированного вторжения: госпожа Фолнуна
	}

	local currentTier = EJ_GetCurrentTier()
	local numTiers = EJ_GetNumTiers()
	for i = 1, numTiers do
		EJ_SelectTier(i)
		for _, v in ipairs(list) do
			local tier = {
				name = ("|cff%s%s|r"):format(util.expColors[i], EJ_GetTierInfo(i)),
				icon = util.expIcons[i],
				iconInfo = expIconInfo,
				list = {},
			}
			local showRaid = v.name == RAIDS
			local index = 1
			local instanceID, instanceName = EJ_GetInstanceByIndex(index, showRaid)
			while instanceID do
				EJ_SelectInstance(instanceID)
				local _,_,_,_,_, icon, mapID = EJ_GetInstanceInfo(instanceID)
				if mapID and mapID > 0 and not mapExclude[mapID] then
					tinsert(tier.list, {name = instanceName, icon = icon, mapID = mapID})
				end
				index = index + 1
				instanceID, instanceName = EJ_GetInstanceByIndex(index, showRaid)
			end
			--if not rawget(util.expIcons, i) then
			--	local j, lastBossID = 1
			--	while true do
			--		local _,_, bossID = EJ_GetEncounterInfoByIndex(j)
			--		if not bossID then
			--			break
			--		else
			--			j = j + 1
			--			lastBossID = bossID
			--		end
			--	end
			--	if lastBossID then
			--		local _,_,_,_, icon = EJ_GetCreatureInfo(1, lastBossID)
			--		fprint(icon, showRaid)
			--		tier.icon = icon
			--	end
			--end
			--if tier.icon == nil then tier.icon = util.expIcons[i] end
			v.list[numTiers - i + 1] = tier
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
			info.icon = v.icon
			info.iconInfo = v.iconInfo
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