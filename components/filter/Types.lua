local addon, L = ...
local mounts, journal = MountsJournal, MountsJournalFrame


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

	info.text = MOUNT_JOURNAL_FILTER_DRAGONRIDING
	info.func = function(_,_,_, value)
		types[4] = value
		journal:updateBtnFilters()
		journal:updateMountsList()
	end
	info.checked = function() return types[4] end
	btn:ddAddButton(info, level)

	for i = 1, 3 do
		info.text = L["MOUNT_TYPE_"..i]
		info.func = function(_,_,_, value)
			types[i] = value
			journal:updateBtnFilters()
			journal:updateMountsList()
		end
		info.checked = function() return types[i] end
		btn:ddAddButton(info, level)
	end
end