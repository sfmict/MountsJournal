local addon, ns = ...
local L, mounts, journal = ns.L, ns.mounts, ns.journal


function journal.filters.selected(dd, level)
	local info = {}
	info.keepShownOnClick = true
	info.isNotRadio = true
	info.notCheckable = true

	info.text = CHECK_ALL
	info.func = function()
		journal:setAllFilters("selected", true)
		journal:updateBtnFilters()
		journal:updateMountsList()
		dd:ddRefresh(level)
	end
	dd:ddAddButton(info, level)

	info.text = UNCHECK_ALL
	info.func = function()
		journal:setAllFilters("selected", false)
		journal:updateBtnFilters()
		journal:updateMountsList()
		dd:ddRefresh(level)
	end
	dd:ddAddButton(info, level)

	info.notCheckable = nil
	local selected = mounts.filters.selected

	local icons = {
		"Interface/AddOns/MountsJournal/textures/fly",
		"Interface/AddOns/MountsJournal/textures/ground",
		"Interface/AddOns/MountsJournal/textures/swimming",
		"Interface/BUTTONS/UI-GROUPLOOT-PASS-DOWN",
	}
	info.widgets = {{
		icon = "interface/worldmap/worldmappartyicon",
		OnClick = function(btn)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			journal:setAllFilters("selected", false)
			selected[btn.value] = true
			journal:updateMountsList()
			dd:ddRefresh(level)
		end,
	}}
	info.func = function(btn, _,_, checked)
		selected[btn.value] = checked
		journal:updateBtnFilters()
		journal:updateMountsList()
	end
	info.checked = function(btn) return selected[btn.value] end

	for i = 1, #icons do
		info.text = L["MOUNT_TYPE_"..i]
		info.icon = icons[i]
		info.value = i
		if i < 4 then
			local color = journal.colors["mount"..i]
			info.iconInfo = {
				tCoordLeft = .25,
				tCoordRight = .75,
				r = color.r,
				g = color.g,
				b = color.b,
			}
		else
			info.iconInfo = nil
		end
		dd:ddAddButton(info, level)
	end
end