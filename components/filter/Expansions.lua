local addon, ns = ...
local L, util, mounts, journal = ns.L, ns.util, ns.mounts, ns.journal


function journal.filters.expansions(btn, level)
	local info = {}
	info.keepShownOnClick = true
	info.isNotRadio = true
	info.notCheckable = true

	info.text = CHECK_ALL
	info.func = function()
		journal:setAllFilters("expansions", true)
		journal:updateMountsList()
		btn:ddRefresh(level)
	end
	btn:ddAddButton(info, level)

	info.text = UNCHECK_ALL
	info.func = function()
		journal:setAllFilters("expansions", false)
		journal:updateMountsList()
		btn:ddRefresh(level)
	end
	btn:ddAddButton(info, level)

	info.notCheckable = nil
	local expansions = mounts.filters.expansions
	for i = 1, util.expansion do
		info.text = _G["EXPANSION_NAME"..(i - 1)]
		info.func = function(_,_,_, value)
			expansions[i] = value
			journal:updateMountsList()
		end
		info.checked = function() return expansions[i] end
		btn:ddAddButton(info, level)
	end
end