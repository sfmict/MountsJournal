local addon, ns = ...
local L, mounts, journal = ns.L, ns.mounts, ns.journal


function journal.filters.factions(dd, level)
	local info = {}
	info.keepShownOnClick = true
	info.isNotRadio = true
	info.notCheckable = true

	info.text = CHECK_ALL
	info.func = function()
		journal:setAllFilters("factions", true)
		journal:updateMountsList()
		dd:ddRefresh(level)
	end
	dd:ddAddButton(info, level)

	info.text = UNCHECK_ALL
	info.func = function()
		journal:setAllFilters("factions", false)
		journal:updateMountsList()
		dd:ddRefresh(level)
	end
	dd:ddAddButton(info, level)

	info.notCheckable = nil
	local factions = mounts.filters.factions

	local icons = {
		2565244,
		2565243,
		200286,
	}
	local iconInfo = {
		tCoordLeft = .25,
		tCoordRight = .85,
		tCoordTop = .2,
		tCoordBottom = .8,
	}
	info.widgets = {{
		icon = "interface/worldmap/worldmappartyicon",
		OnClick = function(btn)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			journal:setAllFilters("factions", false)
			factions[btn.value] = true
			journal:updateMountsList()
			dd:ddRefresh(level)
		end,
	}}
	info.func = function(btn, _,_, checked)
		factions[btn.value] = checked
		journal:updateMountsList()
	end
	info.checked = function(btn) return factions[btn.value] end

	for i = 1, 3 do
		info.text = L["MOUNT_FACTION_"..i]
		info.icon = icons[i]
		info.iconInfo = i == 3 and iconInfo or nil
		info.value = i
		dd:ddAddButton(info, level)
	end
end
