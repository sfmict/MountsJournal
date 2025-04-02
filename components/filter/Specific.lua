local addon, ns = ...
local L, mounts, journal = ns.L, ns.mounts, ns.journal
local specificDB = ns.specificDB


function journal.filters.specific(dd, level)
	local info = {}
	info.keepShownOnClick = true
	info.isNotRadio = true
	info.notCheckable = true

	info.text = CHECK_ALL
	info.func = function()
		journal:setAllFilters("specific", true)
		journal:updateMountsList()
		dd:ddRefresh(level)
	end
	dd:ddAddButton(info, level)

	info.text = UNCHECK_ALL
	info.func = function()
		journal:setAllFilters("specific", false)
		journal:updateMountsList()
		dd:ddRefresh(level)
	end
	dd:ddAddButton(info, level)

	info.notCheckable = nil
	local specific = mounts.filters.specific

	local icons = {
		repair = 136241,
		auctioneer = 136452,
		passenger = 134248,
	}
	info.widgets = {{
		icon = "interface/worldmap/worldmappartyicon",
		OnClick = function(btn)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			journal:setAllFilters("specific", false)
			specific[btn.value] = true
			journal:updateMountsList()
			dd:ddRefresh(level)
		end,
	}}
	info.func = function(btn, _,_, checked)
		specific[btn.value] = checked
		journal:updateMountsList()
	end
	info.checked = function(btn) return specific[btn.value] end

	for k, t in pairs(specificDB) do
		info.text = L[k]
		info.icon = icons[k]
		info.value = k
		dd:ddAddButton(info, level)
	end

	info.text = L["Ride Along"]
	info.icon = 618976
	info.value = "rideAlong"
	dd:ddAddButton(info, level)

	info.text = L["transform"]
	info.icon = 461140
	info.value = "transform"
	dd:ddAddButton(info, level)

	info.text = L["Multiple Models"]
	info.icon = 237185
	info.value = "multipleModels"
	dd:ddAddButton(info, level)

	info.text = L["additional"]
	info.icon = ns.familyDBIcons.additional[0]
	info.value = "additional"
	dd:ddAddButton(info, level)

	info.text = L["rest"]
	info.icon = 413588
	info.value = "rest"
	dd:ddAddButton(info, level)
end