local addon, ns = ...
local L, mounts, journal = ns.L, ns.mounts, ns.journal


function journal.filters.sorting(btn, level)
	local fSort = mounts.filters.sorting
	local info = {}
	info.keepShownOnClick = true

	local func = function(_, by)
		fSort.by = by
		journal:sortMounts()
		btn:ddRefresh(level)
	end
	local check = function(_, by)
		return fSort.by == by
	end

	info.text = NAME
	info.arg1 = "name"
	info.func = func
	info.checked = check
	btn:ddAddButton(info, level)

	info.text = TYPE
	info.arg1 = "type"
	info.func = func
	info.checked = check
	btn:ddAddButton(info, level)

	info.text = L["Family"]
	info.arg1 = "family"
	info.func = func
	info.checked = check
	btn:ddAddButton(info, level)

	info.text = EXPANSION_FILTER_TEXT
	info.arg1 = "expansion"
	info.func = func
	info.checked = check
	btn:ddAddButton(info, level)

	info.text = L["Rarity"]
	info.arg1 = "rarity"
	info.func = func
	info.checked = check
	btn:ddAddButton(info, level)

	btn:ddAddSeparator(level)

	info.isNotRadio = true
	info.text = L["Reverse Sort"]
	info.func = function(_,_,_, value)
		fSort.reverse = value
		journal:sortMounts()
	end
	info.checked = fSort.reverse
	btn:ddAddButton(info, level)

	info.text = L["Collected First"]
	info.func = function(_,_,_, value)
		fSort.collectedFirst = value
		journal:sortMounts()
	end
	info.checked = fSort.favoritesFirst
	btn:ddAddButton(info, level)

	info.text = L["Favorites First"]
	info.func = function(_,_,_, value)
		fSort.favoritesFirst = value
		journal:sortMounts()
	end
	info.checked = fSort.favoritesFirst
	btn:ddAddButton(info, level)

	info.text = L["Additional First"]
	info.func = function(_,_,_, value)
		fSort.additionalFirst = value
		journal:sortMounts()
	end
	info.checked = fSort.additionalFirst
	btn:ddAddButton(info, level)
end