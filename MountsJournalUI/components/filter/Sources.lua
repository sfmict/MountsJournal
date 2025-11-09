local _, ns = ...
local mounts, journal = ns.mounts, ns.journal


function journal.filters.sources(dd, level)
	local info = {}
	info.keepShownOnClick = true
	info.isNotRadio = true
	info.notCheckable = true

	info.text = CHECK_ALL
	info.func = function()
		journal:setAllFilters("sources", true)
		journal:updateBtnFilters()
		journal:updateMountsList()
		dd:ddRefresh(level)
	end
	dd:ddAddButton(info, level)

	info.text = UNCHECK_ALL
	info.func = function()
		journal:setAllFilters("sources", false)
		journal:updateBtnFilters()
		journal:updateMountsList()
		dd:ddRefresh(level)
	end
	dd:ddAddButton(info, level)

	info.notCheckable = nil
	local sources = mounts.filters.sources

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
	info.widgets = {{
		icon = "interface/worldmap/worldmappartyicon",
		OnClick = function(btn)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			journal:setAllFilters("sources", false)
			sources[btn.value] = true
			journal:updateMountsList()
			dd:ddRefresh(level)
		end,
	}}
	info.func = function(btn, _,_, checked)
		sources[btn.value] = checked
		journal:updateBtnFilters()
		journal:updateMountsList()
	end
	info.checked = function(btn) return sources[btn.value] end

	for i = 1, C_PetJournal.GetNumPetSources() do
		if C_MountJournal.IsValidSourceFilter(i) then
			info.text = _G["BATTLE_PET_SOURCE_"..i]
			info.icon = icons[i]
			info.iconInfo = iconInfos[i]
			info.value = i
			dd:ddAddButton(info, level)
		end
	end
end