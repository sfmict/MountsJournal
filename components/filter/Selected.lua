local addon, ns = ...
local L, mounts, journal = ns.L, ns.mounts, ns.journal


function journal.filters.selected(btn, level)
	local info = {}
	info.keepShownOnClick = true
	info.isNotRadio = true
	info.notCheckable = true

	info.text = CHECK_ALL
	info.func = function()
		journal:setAllFilters("selected", true)
		journal:updateBtnFilters()
		journal:updateMountsList()
		btn:ddRefresh(level)
	end
	btn:ddAddButton(info, level)

	info.text = UNCHECK_ALL
	info.func = function()
		journal:setAllFilters("selected", false)
		journal:updateBtnFilters()
		journal:updateMountsList()
		btn:ddRefresh(level)
	end
	btn:ddAddButton(info, level)

	info.notCheckable = nil
	local selected = mounts.filters.selected

	local icons = {
		"Interface/AddOns/MountsJournal/textures/fly",
		"Interface/AddOns/MountsJournal/textures/ground",
		"Interface/AddOns/MountsJournal/textures/swimming",
		"Interface/BUTTONS/UI-GROUPLOOT-PASS-DOWN",
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

	for i = 1, 4 do
		info.text = L["MOUNT_TYPE_"..i]
		info.icon = icons[i]
		info.iconInfo = iconInfos[i]
		info.func = function(_,_,_, value)
			selected[i] = value
			journal:updateBtnFilters()
			journal:updateMountsList()
		end
		info.checked = function() return selected[i] end
		btn:ddAddButton(info, level)
	end
end