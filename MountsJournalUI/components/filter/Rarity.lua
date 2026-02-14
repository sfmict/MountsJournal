local addon, ns = ...
local L, mounts, journal = ns.L, ns.mounts, ns.journal


function journal.filters.rarity(dd, level)
	local filterRarity = mounts.filters.mountsRarity
	local info = {}
	info.keepShownOnClick = true

	info.text = L["Any"]
	info.func = function(button)
		filterRarity.sign = button.value
		dd:ddRefresh(level)
		journal:updateMountsList()
	end
	info.checked = function() return not filterRarity.sign end
	dd:ddAddButton(info, level)

	info.text = L["> (more than)"]
	info.value = ">"
	info.checked = function() return filterRarity.sign == ">" end
	dd:ddAddButton(info, level)

	info.text = L["< (less than)"]
	info.value = "<"
	info.checked = function() return filterRarity.sign == "<" end
	dd:ddAddButton(info, level)

	info.text = L["= (equal to)"]
	info.value = "="
	info.checked = function() return filterRarity.sign == "=" end
	dd:ddAddButton(info, level)

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
				journal:updateMountsList()
			end
		end
	end
	dd:ddAddButton(info, level)
end