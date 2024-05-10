local addon, L = ...
local mounts, journal = MountsJournal, MountsJournalFrame


function journal.filters.sorting(btn, level)
	local fSort = mounts.filters.sorting
	local info = {}
	info.keepShownOnClick = true

	info.text = NAME
	info.func = function()
		fSort.by = "name"
		journal:sortMounts()
		btn:ddRefresh(level)
	end
	info.checked = function() return fSort.by == "name" end
	btn:ddAddButton(info, level)

	info.text = TYPE
	info.func = function()
		fSort.by = "type"
		journal:sortMounts()
		btn:ddRefresh(level)
	end
	info.checked = function() return fSort.by == "type" end
	btn:ddAddButton(info, level)

	info.text = EXPANSION_FILTER_TEXT
	info.func = function()
		fSort.by = "expansion"
		journal:sortMounts()
		btn:ddRefresh(level)
	end
	info.checked = function() return fSort.by == "expansion" end
	btn:ddAddButton(info, level)

	info.text = L["Rarity"]
	info.func = function()
		fSort.by = "rarity"
		journal:sortMounts()
		btn:ddRefresh(level)
	end
	info.checked = function() return fSort.by == "rarity" end
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

	info.text = L["Dragonriding First"]
	info.func = function(_,_,_, value)
		fSort.dragonridingFirst = value
		journal:sortMounts()
	end
	info.checked = fSort.dragonridingFirst
	btn:ddAddButton(info, level)
end