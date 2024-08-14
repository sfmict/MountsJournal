local addon, ns = ...
local L, mounts, journal = ns.L, ns.mounts, ns.journal


function journal.filters.chance(btn, level)
	local filterWeight = mounts.filters.mountsWeight
	local info = {}
	info.keepShownOnClick = true

	info.text = L["Any"]
	info.func = function(button)
		filterWeight.sign = button.value
		btn:ddRefresh(level)
		journal:updateMountsList()
	end
	info.checked = function() return not filterWeight.sign end
	btn:ddAddButton(info, level)

	info.text = L["> (more than)"]
	info.value = ">"
	info.checked = function() return filterWeight.sign == ">" end
	btn:ddAddButton(info, level)

	info.text = L["< (less than)"]
	info.value = "<"
	info.checked = function() return filterWeight.sign == "<" end
	btn:ddAddButton(info, level)

	info.text = L["= (equal to)"]
	info.value = "="
	info.checked = function() return filterWeight.sign == "=" end
	btn:ddAddButton(info, level)

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
			end
		end
	end
	btn:ddAddButton(info, level)
end