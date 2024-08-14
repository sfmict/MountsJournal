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

	for i = 1, 4 do
		info.text = L["MOUNT_TYPE_"..i]
		info.func = function(_,_,_, value)
			selected[i] = value
			journal:updateBtnFilters()
			journal:updateMountsList()
		end
		info.checked = function() return selected[i] end
		btn:ddAddButton(info, level)
	end
end