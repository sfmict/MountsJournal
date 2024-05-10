local addon, L = ...
local mounts, journal = MountsJournal, MountsJournalFrame


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

	info.text = MOUNT_JOURNAL_FILTER_DRAGONRIDING
	info.func = function(_,_,_, value)
		selected[4] = value
		journal:updateBtnFilters()
		journal:updateMountsList()
	end
	info.checked = function() return selected[4] end
	btn:ddAddButton(info, level)

	for i = 1, 3 do
		info.text = L["MOUNT_TYPE_"..i]
		info.func = function(_,_,_, value)
			selected[i] = value
			journal:updateBtnFilters()
			journal:updateMountsList()
		end
		info.checked = function() return selected[i] end
		btn:ddAddButton(info, level)
	end

	info.text = L["MOUNT_TYPE_4"]
	info.func = function(_,_,_, value)
		selected[5] = value
		journal:updateBtnFilters()
		journal:updateMountsList()
	end
	info.checked = function() return selected[5] end
	btn:ddAddButton(info, level)
end