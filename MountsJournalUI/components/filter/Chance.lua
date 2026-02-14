local addon, ns = ...
local L, mounts, journal = ns.L, ns.mounts, ns.journal


function journal.filters.chance(dd, level)
	local filterWeight = mounts.filters.mountsWeight
	local info = {}
	info.keepShownOnClick = true

	info.text = L["Any"]
	info.func = function(button)
		filterWeight.sign = button.value
		dd:ddRefresh(level)
		journal:updateMountsList()
	end
	info.checked = function() return not filterWeight.sign end
	dd:ddAddButton(info, level)

	info.text = L["> (more than)"]
	info.value = ">"
	info.checked = function() return filterWeight.sign == ">" end
	dd:ddAddButton(info, level)

	info.text = L["< (less than)"]
	info.value = "<"
	info.checked = function() return filterWeight.sign == "<" end
	dd:ddAddButton(info, level)

	info.text = L["= (equal to)"]
	info.value = "="
	info.checked = function() return filterWeight.sign == "=" end
	dd:ddAddButton(info, level)

	info.text = nil
	info.value = nil
	info.func = nil
	info.checked = nil
	info.customFrame = journal.percentSlider
	info.customFrame:setText(L["Chance of summoning"])
	info.customFrame:setMinMax(1, 100)
	info.OnLoad = function(frame)
		frame.level = level + 1
		frame:setValue(filterWeight.weight)
		frame.setFunc = function(value)
			if filterWeight.weight ~= value then
				filterWeight.weight = value
				journal:updateMountsList()
			end
		end
	end
	dd:ddAddButton(info, level)
end