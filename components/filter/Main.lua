local addon, L = ...
local mounts, journal = MountsJournal, MountsJournalFrame
journal.filters = {}


function journal.filters.main(btn, level)
	local info = {}
	info.keepShownOnClick = true
	info.isNotRadio = true

	info.text = COLLECTED
	info.func = function(_,_,_, value)
		mounts.filters.collected = value
		journal:updateMountsList()
	end
	info.checked = mounts.filters.collected
	btn:ddAddButton(info, level)

	info.text = NOT_COLLECTED
	info.func = function(_,_,_, value)
		mounts.filters.notCollected = value
		journal:updateMountsList()
	end
	info.checked = mounts.filters.notCollected
	btn:ddAddButton(info, level)

	info.text = MOUNT_JOURNAL_FILTER_UNUSABLE
	info.func = function(_,_,_, value)
		mounts.filters.unusable = value
		journal:updateMountsList()
	end
	info.checked = mounts.filters.unusable
	btn:ddAddButton(info, level)

	info.text = L["With multiple models"]
	info.func = function(_,_,_, value)
		mounts.filters.multipleModels = value
		journal:updateMountsList()
	end
	info.checked = mounts.filters.multipleModels
	btn:ddAddButton(info, level)

	info.text = L["hidden for character"]
	info.func = function(_,_,_, value)
		mounts.filters.hideOnChar = value
		btn:ddRefresh(level)
		journal:setCountMounts()
		journal:updateMountsList()
	end
	info.checked = mounts.filters.hideOnChar
	btn:ddAddButton(info, level)

	info.indent = 16
	info.disabled = function() return not mounts.filters.hideOnChar end
	info.text = L["only hidden"]
	info.func = function(_,_,_, value)
		mounts.filters.onlyHideOnChar = value
		journal:updateMountsList()
	end
	info.checked = mounts.filters.onlyHideOnChar
	btn:ddAddButton(info, level)

	info.indent = nil
	info.disabled = nil
	info.text = L["Hidden by player"]
	info.func = function(_,_,_, value)
		mounts.filters.hiddenByPlayer = value
		btn:ddRefresh(level)
		journal:updateMountsList()
	end
	info.checked = mounts.filters.hiddenByPlayer
	btn:ddAddButton(info, level)

	info.indent = 16
	info.disabled = function() return not mounts.filters.hiddenByPlayer end
	info.text = L["only hidden"]
	info.func = function(_,_,_, value)
		mounts.filters.onlyHiddenByPlayer = value
		journal:updateMountsList()
	end
	info.checked = mounts.filters.onlyHiddenByPlayer
	btn:ddAddButton(info, level)

	info.indent = nil
	info.disabled = nil
	info.text = L["Only new"]
	info.func = function(_,_,_, value)
		mounts.filters.onlyNew = value
		journal:updateMountsList()
	end
	info.checked = mounts.filters.onlyNew
	btn:ddAddButton(info, level)

	btn:ddAddSpace(level)

	info.checked = nil
	info.isNotRadio = nil
	info.func = nil
	info.hasArrow = true
	info.notCheckable = true

	info.text = L["types"]
	info.value = "types"
	btn:ddAddButton(info, level)

	info.text = L["selected"]
	info.value = "selected"
	btn:ddAddButton(info, level)

	info.text = SOURCES
	info.value = "sources"
	btn:ddAddButton(info, level)

	info.text = L["Specific"]
	info.value = "specific"
	btn:ddAddButton(info, level)

	info.text = L["Family"]
	info.value = "family"
	btn:ddAddButton(info, level)

	info.text = L["factions"]
	info.value = "factions"
	btn:ddAddButton(info, level)

	info.text = PET
	info.value = "pet"
	btn:ddAddButton(info, level)

	info.text = L["expansions"]
	info.value = "expansions"
	btn:ddAddButton(info, level)

	info.text = L["Rarity"]
	info.value = "rarity"
	btn:ddAddButton(info, level)

	info.text = L["Chance of summoning"]
	info.value = "chance"
	btn:ddAddButton(info, level)

	info.text = L["tags"]
	info.value = "tags"
	btn:ddAddButton(info, level)

	btn:ddAddSpace(level)

	info.text = L["sorting"]
	info.value = "sorting"
	btn:ddAddButton(info, level)

	btn:ddAddSpace(level)

	info.keepShownOnClick = nil
	info.hasArrow = nil
	info.text = RESET
	info.func = function() journal:resetToDefaultFilters() end
	btn:ddAddButton(info, level)

	info.text = L["Set current filters as default"]
	info.func = function() journal:saveDefaultFilters() end
	btn:ddAddButton(info, level)

	info.text = L["Restore default filters"]
	info.func = function() journal:restoreDefaultFilters() end
	btn:ddAddButton(info, level)
end