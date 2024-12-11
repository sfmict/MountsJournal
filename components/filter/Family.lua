local addon, ns = ...
local L, mounts, journal = ns.L, ns.mounts, ns.journal
local familyDB = ns.familyDB


function journal.filters.family(dd, level, subFamily)
	local filterFamily = mounts.filters.family
	local info = {}
	info.keepShownOnClick = true
	info.isNotRadio = true

	local widgets = {{icon = "interface/worldmap/worldmappartyicon"}}
	local check = function(btn)
		return filterFamily[btn.value]
	end

	if subFamily then
		local sortedNames = {}
		for k in next, familyDB[subFamily] do
			sortedNames[#sortedNames + 1] = {k, L[k]}
		end
		sort(sortedNames, function(a, b)
			return b[1] == "Others" or a[1] ~= "Others" and strcmputf8i(a[2], b[2]) < 0
		end)

		widgets[1].OnClick = function(btn)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			journal:setAllFilters("family", false)
			filterFamily[btn.value] = true
			journal:updateMountsList()
			dd:ddRefresh(level)
			dd:ddRefresh(level - 1)
		end
		local func = function(btn, _,_, checked)
			filterFamily[btn.value] = checked
			journal:updateMountsList()
			dd:ddRefresh(level - 1)
		end

		for i, name in ipairs(sortedNames) do
			info.text = name[2]
			info.icon = ns.familyDBIcons[subFamily][name[1]]
			info.value = familyDB[subFamily][name[1]]
			info.widgets = widgets
			info.func = func
			info.checked = check
			dd:ddAddButton(info, level)
		end
	else
		info.notCheckable = true

		info.text = CHECK_ALL
		info.func = function()
			journal:setAllFilters("family", true)
			journal:updateMountsList()
			dd:ddRefresh(level)
		end
		dd:ddAddButton(info, level)

		info.text = UNCHECK_ALL
		info.func = function()
			journal:setAllFilters("family", false)
			journal:updateMountsList()
			dd:ddRefresh(level)
		end
		dd:ddAddButton(info, level)

		local sortedNames = {}
		for k in next, familyDB do
			sortedNames[#sortedNames + 1] = {k, L[k]}
		end
		sort(sortedNames, function(a, b)
			return b[1] == "rest" or a[1] ~= "rest" and strcmputf8i(a[2], b[2]) < 0
		end)

		widgets[1].OnClick = function(btn)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			journal:setAllFilters("family", false)
			filterFamily[btn.value] = true
			journal:updateMountsList()
			dd:ddRefresh(level)
		end
		local func = function(btn, _,_, checked)
			filterFamily[btn.value] = checked
			journal:updateMountsList()
		end

		local subWidgets = {
			{
				icon = "interface/worldmap/worldmappartyicon",
				OnClick = function(btn)
					PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
					journal:setAllFilters("family", false)
					for k, v in next, familyDB[btn.value[2]] do
						filterFamily[v] = true
					end
					journal:updateMountsList()
					dd:ddRefresh(level)
					dd:ddRefresh(level + 1)
				end
			}
		}
		local subFunc = function(btn, _,_, checked)
			for k, v in next, familyDB[btn.value[2]] do
				filterFamily[v] = checked
			end
			journal:updateMountsList()
			dd:ddRefresh(level)
			dd:ddRefresh(level + 1)
		end
		local subCheck = function(btn)
			local i, j = 0, 0
			for k, v in next, familyDB[btn.value[2]] do
				i = i + 1
				if filterFamily[v] then j = j + 1 end
			end
			return i == j and 1 or j > 0 and 2
		end

		local list = {}
		for i, name in ipairs(sortedNames) do
			local subInfo = {}
			subInfo.keepShownOnClick = true
			subInfo.isNotRadio = true
			subInfo.text = name[2]

			if type(familyDB[name[1]]) == "number" then
				subInfo.icon = ns.familyDBIcons[name[1]]
				subInfo.value = familyDB[name[1]]
				subInfo.widgets = widgets
				subInfo.func = func
				subInfo.checked = check
			else
				subInfo.hasArrow = true
				subInfo.icon = ns.familyDBIcons[name[1]][0]
				subInfo.value = {"family", name[1]}
				subInfo.widgets = subWidgets
				subInfo.func = subFunc
				subInfo.checked = subCheck
			end

			list[i] = subInfo
		end

		info.listMaxSize = 30
		info.list = list
		dd:ddAddButton(info, level)
	end
end