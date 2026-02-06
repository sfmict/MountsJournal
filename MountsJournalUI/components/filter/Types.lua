local addon, ns = ...
local L, mounts, journal = ns.L, ns.mounts, ns.journal


function journal.filters.types(dd, level)
	local info = {}
	info.keepShownOnClick = true
	info.isNotRadio = true
	info.notCheckable = true

	info.text = CHECK_ALL
	info.func = function()
		journal:setAllFilters("types", true)
		journal:updateBtnFilters()
		journal:updateMountsList()
		dd:ddRefresh(level)
	end
	dd:ddAddButton(info, level)

	info.text = UNCHECK_ALL
	info.func = function()
		journal:setAllFilters("types", false)
		journal:updateBtnFilters()
		journal:updateMountsList()
		dd:ddRefresh(level)
	end
	dd:ddAddButton(info, level)

	info.notCheckable = nil
	local types = mounts.filters.types

	local icons = {
		"Interface/AddOns/MountsJournal/textures/fly",
		"Interface/AddOns/MountsJournal/textures/ground",
		"Interface/AddOns/MountsJournal/textures/swimming",
	}
	info.widgets = {{
		icon = "interface/worldmap/worldmappartyicon",
		OnClick = function(btn)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			journal:setAllFilters("types", false)
			types[btn.value] = true
			journal:updateMountsList()
			dd:ddRefresh(level)
		end,
	}}
	info.func = function(btn, _,_, checked)
		types[btn.value] = checked
		journal:updateBtnFilters()
		journal:updateMountsList()
	end
	info.checked = function(btn) return types[btn.value] end

	for i = 1, #icons do
		local color = journal.colors["mount"..i]
		info.text = L["MOUNT_TYPE_"..i]
		info.icon = icons[i]
		info.iconInfo = {
			tCoordLeft = .25,
			tCoordRight = .75,
			r = color.r,
			g = color.g,
			b = color.b,
		}
		info.value = i
		dd:ddAddButton(info, level)
	end
end