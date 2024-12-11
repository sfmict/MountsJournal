local addon, ns = ...
local L, mounts, journal = ns.L, ns.mounts, ns.journal


function journal.filters.pet(btn, level)
	local info = {}
	info.keepShownOnClick = true
	info.isNotRadio = true
	info.notCheckable = true

	info.text = CHECK_ALL
	info.func = function()
		journal:setAllFilters("pet", true)
		journal:updateMountsList()
		btn:ddRefresh(level)
	end
	btn:ddAddButton(info, level)

	info.text = UNCHECK_ALL
	info.func = function()
		journal:setAllFilters("pet", false)
		journal:updateMountsList()
		btn:ddRefresh(level)
	end
	btn:ddAddButton(info, level)

	local icons = {
		922035,
		652131,
		647701,
		136509,
	}
	local iconInfo = {
		tCoordLeft = .13125,
		tCoordRight = .7125,
		tCoordTop = .13125,
		tCoordBottom = .7125,
	}

	info.notCheckable = nil
	local pet = mounts.filters.pet
	for i = 1, 4 do
		info.text = L["PET_"..i]
		info.icon = icons[i]
		info.iconInfo = i == 1 and iconInfo or nil
		info.func = function(_,_,_, value)
			pet[i] = value
			journal:updateMountsList()
		end
		info.checked = function() return pet[i] end
		btn:ddAddButton(info, level)
	end
end