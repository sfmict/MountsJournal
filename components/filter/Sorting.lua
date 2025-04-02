local addon, ns = ...
local L, mounts, journal = ns.L, ns.mounts, ns.journal


function journal.filters.sorting(dd, level, value)
	local fSort = mounts.filters.sorting
	local kBy = value and "by"..value or "by"
	local kReverse = value and "reverse"..value or "reverse"
	local info = {}
	info.keepShownOnClick = true

	local func = function(_, by)
		fSort[kBy] = by
		journal:sortMounts()
		dd:ddRefresh(level)
	end
	local check = function(_, by)
		return fSort[kBy] == by
	end

	info.text = NAME
	info.arg1 = "name"
	info.func = func
	info.checked = check
	dd:ddAddButton(info, level)

	info.text = TYPE
	info.arg1 = "type"
	info.func = func
	info.checked = check
	dd:ddAddButton(info, level)

	info.text = L["Family"]
	info.arg1 = "family"
	info.func = func
	info.checked = check
	dd:ddAddButton(info, level)

	info.text = EXPANSION_FILTER_TEXT
	info.arg1 = "expansion"
	info.func = func
	info.checked = check
	dd:ddAddButton(info, level)

	info.text = L["Rarity"]
	info.arg1 = "rarity"
	info.func = func
	info.checked = check
	dd:ddAddButton(info, level)

	info.text = SUMMONS
	info.arg1 = "summons"
	info.func = func
	info.checked = check
	dd:ddAddButton(info, level)

	info.text = L["Travel time"]
	info.arg1 = "time"
	info.func = func
	info.checked = check
	dd:ddAddButton(info, level)

	info.text = L["Travel distance"]
	info.arg1 = "distance"
	info.func = func
	info.checked = check
	dd:ddAddButton(info, level)

	info.arg1 = nil
	info.func = nil
	info.checked = nil

	if not value or value < 3 then
		info.notCheckable = true
		info.hasArrow = true
		info.text = L["Then Sort By"]
		info.value = {"sorting", (value or 1) + 1}
		dd:ddAddButton(info, level)

		info.notCheckable = nil
		info.hasArrow = nil
	end

	dd:ddAddSeparator(level)

	info.isNotRadio = true
	info.text = L["Reverse Sort"]
	info.func = function(_,_,_, checked)
		fSort[kReverse] = checked
		journal:sortMounts()
	end
	info.checked = fSort[kReverse]
	dd:ddAddButton(info, level)

	if value then return end

	info.text = L["Collected First"]
	info.func = function(_,_,_, checked)
		fSort.collectedFirst = checked
		journal:sortMounts()
	end
	info.checked = fSort.collectedFirst
	dd:ddAddButton(info, level)

	info.text = L["Favorites First"]
	info.func = function(_,_,_, checked)
		fSort.favoritesFirst = checked
		journal:sortMounts()
	end
	info.checked = fSort.favoritesFirst
	dd:ddAddButton(info, level)

	info.text = L["Additional First"]
	info.func = function(_,_,_, checked)
		fSort.additionalFirst = checked
		journal:sortMounts()
	end
	info.checked = fSort.additionalFirst
	dd:ddAddButton(info, level)
end