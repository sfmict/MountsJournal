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

	local colors = {
		"D6AB7D", -- classic
		"E43E5A", -- burning crusade
		"3FC7EB", -- wrath of the lich king
		"FF7C0A", -- cataclysm
		"00EF88", -- mists of pandaria
		"F48CBA", -- warlords of draenor
		"AAD372", -- legion
		"FFF468", -- battle for azeroth
		"9798FE", -- shadowlands
		"53B39F", -- dragonflight
		"90CCDD", -- the war within
	}
	local icons = {
		1385726,
		1378987,
		607688,
		536055,
		901157,
		1134497,
		1715536,
		3256381,
		4465334,
		5409250,
		6377935,
	}
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
		info.text = ("|cff%s%s|r"):format(colors[i] or "E8E8E8", _G["EXPANSION_NAME"..(i - 1)])
		info.icon = icons[i] or [[Interface\EncounterJournal\UI-EJ-BOSS-Default]]
		info.value = i
		dd:ddAddButton(info, level)
	end
end