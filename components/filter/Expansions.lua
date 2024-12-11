local addon, ns = ...
local L, util, mounts, journal = ns.L, ns.util, ns.mounts, ns.journal


function journal.filters.expansions(btn, level)
	local info = {}
	info.keepShownOnClick = true
	info.isNotRadio = true
	info.notCheckable = true

	info.text = CHECK_ALL
	info.func = function()
		journal:setAllFilters("expansions", true)
		journal:updateMountsList()
		btn:ddRefresh(level)
	end
	btn:ddAddButton(info, level)

	info.text = UNCHECK_ALL
	info.func = function()
		journal:setAllFilters("expansions", false)
		journal:updateMountsList()
		btn:ddRefresh(level)
	end
	btn:ddAddButton(info, level)

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

	info.notCheckable = nil
	local expansions = mounts.filters.expansions
	for i = util.expansion, 1, -1 do
		info.text = ("|cff%s%s|r"):format(colors[i] or "E8E8E8", _G["EXPANSION_NAME"..(i - 1)])
		info.func = function(_,_,_, value)
			expansions[i] = value
			journal:updateMountsList()
		end
		info.checked = function() return expansions[i] end
		btn:ddAddButton(info, level)
	end
end