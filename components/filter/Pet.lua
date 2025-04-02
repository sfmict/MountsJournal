local addon, ns = ...
local L, mounts, journal = ns.L, ns.mounts, ns.journal


function journal.filters.pet(dd, level)
	local info = {}
	info.keepShownOnClick = true
	info.isNotRadio = true
	info.notCheckable = true

	info.text = CHECK_ALL
	info.func = function()
		journal:setAllFilters("pet", true)
		journal:updateMountsList()
		dd:ddRefresh(level)
	end
	dd:ddAddButton(info, level)

	info.text = UNCHECK_ALL
	info.func = function()
		journal:setAllFilters("pet", false)
		journal:updateMountsList()
		dd:ddRefresh(level)
	end
	dd:ddAddButton(info, level)

	info.notCheckable = nil
	local pet = mounts.filters.pet

	local icons = {
		922035,
		652131,
		647701,
		136509,
	}
	local iconInfo = {
		tCoordLeft = .13125,
		tCoordRight = .7125,
		tCoordTop = .13125,
		tCoordBottom = .7125,
	}
	info.widgets = {{
		icon = "interface/worldmap/worldmappartyicon",
		OnClick = function(btn)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			journal:setAllFilters("pet", false)
			pet[btn.value] = true
			journal:updateMountsList()
			dd:ddRefresh(level)
		end,
	}}
	info.func = function(btn, _,_, checked)
		pet[btn.value] = checked
		journal:updateMountsList()
	end
	info.checked = function(btn) return pet[btn.value] end

	for i = 1, 4 do
		info.text = L["PET_"..i]
		info.icon = icons[i]
		info.iconInfo = i == 1 and iconInfo or nil
		info.value = i
		dd:ddAddButton(info, level)
	end
end