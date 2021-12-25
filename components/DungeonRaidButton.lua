local _, L = ...


MountsJournalFrame:on("MODULES_INIT", function(journal)
	local dd = LibStub("LibSFDropDown-1.2"):CreateStretchButton(journal.mapSettings, nil, 24)
	dd:SetPoint("TOPLEFT", journal.mapSettings.mapControl, "TOPLEFT", 3, -3)
	dd:SetPoint("RIGHT", journal.mapSettings.CurrentMap, "LEFT", 2, 0)
	dd:SetText(L["Dungeons and Raids"])
	dd.navBar = journal.navBar
	dd.list = {
		{
			name = DUNGEONS,
			list = {},
		},
		{
			name = RAIDS,
			list = {},
		}
	}

	local currentTier = EJ_GetCurrentTier()
	local mapExclude = {
		[379] = true, -- Вершина Кун-Лай
		[543] = true, -- Горгронд
		[929] = true, -- Точка массированного вторжения: госпожа Фолнуна
	}
	for i = 1, EJ_GetNumTiers() do
		EJ_SelectTier(i)
		for _, v in ipairs(dd.list) do
			v.list[i] = {
				name = _G["EXPANSION_NAME"..(i - 1)],
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
		end
	end
	EJ_SelectTier(currentTier)

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

		if #value == 0 then
			info.text = EMPTY
			info.disabled = true
			self:ddAddButton(info, level)
		end
	end)

	dd:SetScript("OnClick", function(self)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self:ddToggle(1, self.list, self, 112, 18)
	end)
end)