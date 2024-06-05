local addon, L = ...
local mounts, journal = MountsJournal, MountsJournalFrame


function journal.filters.family(dd, level, subFamily)
	local filterFamily = mounts.filters.family
	local familyDB = mounts.familyDB
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
		sort(sortedNames, function(a, b) return a[2] < b[2] end)

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
		sort(sortedNames, function(a, b) return a[2] < b[2] end)

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
		local textFunc = function(btn)
			local i, j = 0, 0
			for k, v in next, familyDB[btn.value[2]] do
				i = i + 1
				if filterFamily[v] then j = j + 1 end
			end
			local name = L[btn.value[2]]
			return j > 0 and j < i and "*"..name or name
		end
		local subFunc = function(btn, _,_, checked)
			for k, v in next, familyDB[btn.value[2]] do
				filterFamily[v] = checked
			end
			journal:updateMountsList()
			dd:ddRefresh(level)
			dd:ddRefresh(level + 1)
		end
		local subCheck = function(btn)
			for k, v in next, familyDB[btn.value[2]] do
				if not filterFamily[v] then return false end
			end
			return true
		end

		local list = {}
		for i, name in ipairs(sortedNames) do
			local subInfo = {
				keepShownOnClick = true,
				isNotRadio = true,
			}

			if type(familyDB[name[1]]) == "number" then
				subInfo.text = name[2]
				subInfo.value = familyDB[name[1]]
				subInfo.widgets = widgets
				subInfo.func = func
				subInfo.checked = check
			else
				subInfo.hasArrow = true
				subInfo.text = textFunc
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