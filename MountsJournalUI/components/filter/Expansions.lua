local addon, ns = ...
local L, util, mounts, journal = ns.L, ns.util, ns.mounts, ns.journal


function journal.filters.expansions(dd, level)
	local info = {}
	info.keepShownOnClick = true
	info.isNotRadio = true
	info.notCheckable = true

	info.text = CHECK_ALL
	info.func = function()
		journal:setAllFilters("expansions", true)
		journal:updateMountsList()
		dd:ddRefresh(level)
	end
	dd:ddAddButton(info, level)

	info.text = UNCHECK_ALL
	info.func = function()
		journal:setAllFilters("expansions", false)
		journal:updateMountsList()
		dd:ddRefresh(level)
	end
	dd:ddAddButton(info, level)

	info.notCheckable = nil
	local expansions = mounts.filters.expansions

	info.iconInfo = {
		tSizeX = 40,
		tSizeY = 20,
	}
	info.widgets = {{
		icon = "interface/worldmap/worldmappartyicon",
		OnClick = function(btn)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			journal:setAllFilters("expansions", false)
			expansions[btn.value] = true
			journal:updateMountsList()
			dd:ddRefresh(level)
		end,
	}}
	info.func = function(btn, _,_, checked)
		expansions[btn.value] = checked
		journal:updateMountsList()
	end
	info.checked = function(btn) return expansions[btn.value] end

	for i = util.expansion, 1, -1 do
		info.text = ("|cff%s%s|r"):format(util.expColors[i], _G["EXPANSION_NAME"..(i - 1)])
		info.icon = util.expIcons[i]
		info.value = i
		dd:ddAddButton(info, level)
	end
end