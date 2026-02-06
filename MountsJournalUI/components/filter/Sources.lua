local _, ns = ...
local mounts, journal = ns.mounts, ns.journal


function journal.filters.sources(dd, level)
	local info = {}
	info.keepShownOnClick = true
	info.isNotRadio = true
	info.notCheckable = true

	info.text = CHECK_ALL
	info.func = function()
		journal:setAllFilters("sources", true)
		journal:updateBtnFilters()
		journal:updateMountsList()
		dd:ddRefresh(level)
	end
	dd:ddAddButton(info, level)

	info.text = UNCHECK_ALL
	info.func = function()
		journal:setAllFilters("sources", false)
		journal:updateBtnFilters()
		journal:updateMountsList()
		dd:ddRefresh(level)
	end
	dd:ddAddButton(info, level)

	info.notCheckable = nil
	local sources = mounts.filters.sources

	info.widgets = {{
		icon = "interface/worldmap/worldmappartyicon",
		OnClick = function(btn)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			journal:setAllFilters("sources", false)
			sources[btn.value] = true
			journal:updateMountsList()
			dd:ddRefresh(level)
		end,
	}}
	info.func = function(btn, _,_, checked)
		sources[btn.value] = checked
		journal:updateBtnFilters()
		journal:updateMountsList()
	end
	info.checked = function(btn) return sources[btn.value] end

	for i = 1, C_PetJournal.GetNumPetSources() do
		if C_MountJournal.IsValidSourceFilter(i) then
			local col = (i - 1) % 4 * .25
			local row = math.floor((i - 1) / 4) * .25
			info.text = _G["BATTLE_PET_SOURCE_"..i]
			info.icon = "Interface/AddOns/MountsJournal/textures/sources"
			info.iconInfo = {
				tCoordLeft = col,
				tCoordRight = col + .25,
				tCoordTop = row,
				tCoordBottom = row + .25,
			}
			info.value = i
			dd:ddAddButton(info, level)
		end
	end
end