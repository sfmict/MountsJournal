local addon, ns = ...
local L, mounts, journal = ns.L, ns.mounts, ns.journal


function journal.filters.factions(btn, level)
	local info = {}
	info.keepShownOnClick = true
	info.isNotRadio = true
	info.notCheckable = true

	info.text = CHECK_ALL
	info.func = function()
		journal:setAllFilters("factions", true)
		journal:updateMountsList()
		btn:ddRefresh(level)
	end
	btn:ddAddButton(info, level)

	info.text = UNCHECK_ALL
	info.func = function()
		journal:setAllFilters("factions", false)
		journal:updateMountsList()
		btn:ddRefresh(level)
	end
	btn:ddAddButton(info, level)

	info.notCheckable = nil
	local factions = mounts.filters.factions
	for i = 1, 3 do
		info.text = L["MOUNT_FACTION_"..i]
		info.func = function(_,_,_, value)
			factions[i] = value
			journal:updateMountsList()
		end
		info.checked = function() return factions[i] end
		btn:ddAddButton(info, level)
	end
end
