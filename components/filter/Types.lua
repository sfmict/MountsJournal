local addon, ns = ...
local L, mounts, journal = ns.L, ns.mounts, ns.journal


function journal.filters.types(btn, level)
	local info = {}
	info.keepShownOnClick = true
	info.isNotRadio = true
	info.notCheckable = true

	info.text = CHECK_ALL
	info.func = function()
		journal:setAllFilters("types", true)
		journal:updateBtnFilters()
		journal:updateMountsList()
		btn:ddRefresh(level)
	end
	btn:ddAddButton(info, level)

	info.text = UNCHECK_ALL
	info.func = function()
		journal:setAllFilters("types", false)
		journal:updateBtnFilters()
		journal:updateMountsList()
		btn:ddRefresh(level)
	end
	btn:ddAddButton(info, level)

	info.notCheckable = nil
	local types = mounts.filters.types

	local icons = {
		"Interface/AddOns/MountsJournal/textures/fly",
		"Interface/AddOns/MountsJournal/textures/ground",
		"Interface/AddOns/MountsJournal/textures/swimming",
	}
	local iconInfos = {
		{
			tCoordLeft = .25,
			tCoordRight = .75,
			r = journal.colors.mount1.r,
			g = journal.colors.mount1.g,
			b = journal.colors.mount1.b,
		},
		{
			tCoordLeft = .25,
			tCoordRight = .75,
			r = journal.colors.mount2.r,
			g = journal.colors.mount2.g,
			b = journal.colors.mount2.b,
		},
		{
			tCoordLeft = .25,
			tCoordRight = .75,
			r = journal.colors.mount3.r,
			g = journal.colors.mount3.g,
			b = journal.colors.mount3.b,
		},
	}

	for i = 1, 3 do
		info.text = L["MOUNT_TYPE_"..i]
		info.icon = icons[i]
		info.iconInfo = iconInfos[i]
		info.func = function(_,_,_, value)
			types[i] = value
			journal:updateBtnFilters()
			journal:updateMountsList()
		end
		info.checked = function() return types[i] end
		btn:ddAddButton(info, level)
	end
end