local _, ns = ...
local mounts, journal = ns.mounts, ns.journal


function journal.filters.sources(btn, level)
	local info = {}
	info.keepShownOnClick = true
	info.isNotRadio = true
	info.notCheckable = true

	info.text = CHECK_ALL
	info.func = function()
		journal:setAllFilters("sources", true)
		journal:updateBtnFilters()
		journal:updateMountsList()
		btn:ddRefresh(level)
	end
	btn:ddAddButton(info, level)

	info.text = UNCHECK_ALL
	info.func = function()
		journal:setAllFilters("sources", false)
		journal:updateBtnFilters()
		journal:updateMountsList()
		btn:ddRefresh(level)
	end
	btn:ddAddButton(info, level)

	local icons = {
		"Interface/AddOns/MountsJournal/textures/sources",
		"Interface/AddOns/MountsJournal/textures/sources",
		"Interface/AddOns/MountsJournal/textures/sources",
		"Interface/AddOns/MountsJournal/textures/sources",
		nil,
		"Interface/AddOns/MountsJournal/textures/sources",
		"Interface/AddOns/MountsJournal/textures/sources",
		"Interface/AddOns/MountsJournal/textures/sources",
		"Interface/AddOns/MountsJournal/textures/sources",
		"Interface/AddOns/MountsJournal/textures/sources",
		"Interface/AddOns/MountsJournal/textures/sources",
		4696085,
	}
	local iconInfos = {
		{
			tCoordLeft = 0,
			tCoordRight = .25,
			tCoordTop = 0,
			tCoordBottom = .25,
		},
		{
			tCoordLeft = .25,
			tCoordRight = .5,
			tCoordTop = 0,
			tCoordBottom = .25,
		},
		{
			tCoordLeft = .5,
			tCoordRight = .75,
			tCoordTop = 0,
			tCoordBottom = .25,
		},
		{
			tCoordLeft = .75,
			tCoordRight = 1,
			tCoordTop = 0,
			tCoordBottom = .25,
		},
		nil,
		{
			tCoordLeft = .25,
			tCoordRight = .5,
			tCoordTop = .25,
			tCoordBottom = .5,
		},
		{
			tCoordLeft = .5,
			tCoordRight = .75,
			tCoordTop = .25,
			tCoordBottom = .5,
		},
		{
			tCoordLeft = .75,
			tCoordRight = 1,
			tCoordTop = .25,
			tCoordBottom = .5,
		},
		{
			tCoordLeft = 0,
			tCoordRight = .25,
			tCoordTop = .5,
			tCoordBottom = .75,
		},
		{
			tCoordLeft = .25,
			tCoordRight = .5,
			tCoordTop = .5,
			tCoordBottom = .75,
		},
		{
			tCoordLeft = .5,
			tCoordRight = .75,
			tCoordTop = .5,
			tCoordBottom = .75,
		},
	}

	info.notCheckable = nil
	local sources = mounts.filters.sources
	for i = 1, C_PetJournal.GetNumPetSources() do
		if C_MountJournal.IsValidSourceFilter(i) then
			info.text = _G["BATTLE_PET_SOURCE_"..i]
			info.icon = icons[i]
			info.iconInfo = iconInfos[i]
			info.func = function(_,_,_, value)
				sources[i] = value
				journal:updateBtnFilters()
				journal:updateMountsList()
			end
			info.checked = function() return sources[i] end
			btn:ddAddButton(info, level)
		end
	end
end