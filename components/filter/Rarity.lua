local addon, L = ...
local mounts, journal = MountsJournal, MountsJournalFrame


function journal.filters.rarity(btn, level)
	local filterRarity = mounts.filters.mountsRarity
	local info = {}
	info.keepShownOnClick = true

	info.text = L["Any"]
	info.func = function(button)
		filterRarity.sign = button.value
		btn:ddRefresh(level)
		journal:updateMountsList()
	end
	info.checked = function() return not filterRarity.sign end
	btn:ddAddButton(info, level)

	info.text = L["> (more than)"]
	info.value = ">"
	info.checked = function() return filterRarity.sign == ">" end
	btn:ddAddButton(info, level)

	info.text = L["< (less than)"]
	info.value = "<"
	info.checked = function() return filterRarity.sign == "<" end
	btn:ddAddButton(info, level)

	info.text = L["= (equal to)"]
	info.value = "="
	info.checked = function() return filterRarity.sign == "=" end
	btn:ddAddButton(info, level)

	info.text = nil
	info.value = nil
	info.func = nil
	info.checked = nil
	info.customFrame = journal.percentSlider
	info.customFrame:setText(L["Rarity"])
	info.customFrame:setMinMax(0, 100)
	info.OnLoad = function(frame)
		frame.level = level + 1
		frame:setValue(filterRarity.value)
		frame.setFunc = function(value)
			if filterRarity.value ~= value then
				filterRarity.value = value
			end
		end
	end
	btn:ddAddButton(info, level)
end