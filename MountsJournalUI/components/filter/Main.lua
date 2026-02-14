local addon, ns = ...
local L, mounts, journal = ns.L, ns.mounts, ns.journal
journal.filters = {}


function journal.filters.main(dd, level)
	local info = {}
	info.keepShownOnClick = true
	info.isNotRadio = true

	info.text = COLLECTED
	info.func = function(_,_,_, checked)
		mounts.filters.collected = checked
		journal:updateMountsList()
	end
	info.checked = mounts.filters.collected
	dd:ddAddButton(info, level)

	info.text = NOT_COLLECTED
	info.func = function(_,_,_, checked)
		mounts.filters.notCollected = checked
		journal:updateMountsList()
	end
	info.checked = mounts.filters.notCollected
	dd:ddAddButton(info, level)

	info.text = MOUNT_JOURNAL_FILTER_UNUSABLE
	info.func = function(_,_,_, checked)
		mounts.filters.unusable = checked
		journal:updateMountsList()
	end
	info.checked = mounts.filters.unusable
	dd:ddAddButton(info, level)

	info.text = L["hidden for character"]
	info.func = function(_,_,_, checked)
		mounts.filters.hideOnChar = checked
		dd:ddRefresh(level)
		journal:setCountMounts()
		journal:updateMountsList()
	end
	info.checked = mounts.filters.hideOnChar
	dd:ddAddButton(info, level)

	info.indent = 16
	info.disabled = function() return not mounts.filters.hideOnChar end
	info.text = L["only hidden"]
	info.func = function(_,_,_, checked)
		mounts.filters.onlyHideOnChar = checked
		journal:updateMountsList()
	end
	info.checked = mounts.filters.onlyHideOnChar
	dd:ddAddButton(info, level)

	info.indent = nil
	info.disabled = nil
	info.text = L["Hidden by player"]
	info.func = function(_,_,_, checked)
		mounts.filters.hiddenByPlayer = checked
		dd:ddRefresh(level)
		journal:updateMountsList()
	end
	info.checked = mounts.filters.hiddenByPlayer
	dd:ddAddButton(info, level)

	info.indent = 16
	info.disabled = function() return not mounts.filters.hiddenByPlayer end
	info.text = L["only hidden"]
	info.func = function(_,_,_, checked)
		mounts.filters.onlyHiddenByPlayer = checked
		journal:updateMountsList()
	end
	info.checked = mounts.filters.onlyHiddenByPlayer
	dd:ddAddButton(info, level)

	info.indent = nil
	info.disabled = nil
	info.text = L["Only new"]
	info.func = function(_,_,_, checked)
		mounts.filters.onlyNew = checked
		journal:updateMountsList()
	end
	info.checked = mounts.filters.onlyNew
	dd:ddAddButton(info, level)

	dd:ddAddSpace(level)

	info.checked = nil
	info.isNotRadio = nil
	info.func = nil
	info.hasArrow = true
	info.notCheckable = true

	info.text = L["types"]
	info.value = "types"
	dd:ddAddButton(info, level)

	info.text = L["selected"]
	info.value = "selected"
	dd:ddAddButton(info, level)

	info.text = SOURCES
	info.value = "sources"
	dd:ddAddButton(info, level)

	info.text = L["Specific"]
	info.value = "specific"
	dd:ddAddButton(info, level)

	info.text = L["Family"]
	info.value = "family"
	dd:ddAddButton(info, level)

	info.text = L["expansions"]
	info.value = "expansions"
	dd:ddAddButton(info, level)

	info.text = COLOR
	info.value = "color"
	dd:ddAddButton(info, level)

	info.text = L["factions"]
	info.value = "factions"
	dd:ddAddButton(info, level)

	info.text = PET
	info.value = "pet"
	dd:ddAddButton(info, level)

	info.text = L["Rarity"]
	info.value = "rarity"
	dd:ddAddButton(info, level)

	info.text = L["Chance of summoning"]
	info.value = "chance"
	dd:ddAddButton(info, level)

	info.text = L["tags"]
	info.value = "tags"
	dd:ddAddButton(info, level)

	dd:ddAddSpace(level)

	info.text = L["sorting"]
	info.value = "sorting"
	dd:ddAddButton(info, level)

	dd:ddAddSpace(level)

	info.keepShownOnClick = nil
	info.hasArrow = nil
	info.text = RESET
	info.func = function() journal:resetToDefaultFilters() end
	dd:ddAddButton(info, level)

	info.text = L["Set current filters as default"]
	info.func = function() journal:saveDefaultFilters() end
	dd:ddAddButton(info, level)

	info.text = L["Restore default filters"]
	info.func = function() journal:restoreDefaultFilters() end
	dd:ddAddButton(info, level)
end