local addon, ns = ...
local L, mounts, journal = ns.L, ns.mounts, ns.journal
local specificDB = ns.specificDB


function journal.filters.specific(btn, level)
	local info = {}
	info.keepShownOnClick = true
	info.isNotRadio = true
	info.notCheckable = true

	info.text = CHECK_ALL
	info.func = function()
		journal:setAllFilters("specific", true)
		journal:updateMountsList()
		btn:ddRefresh(level)
	end
	btn:ddAddButton(info, level)

	info.text = UNCHECK_ALL
	info.func = function()
		journal:setAllFilters("specific", false)
		journal:updateMountsList()
		btn:ddRefresh(level)
	end
	btn:ddAddButton(info, level)

	info.notCheckable = nil
	local specific = mounts.filters.specific

	local icons = {
		repair = 136241,
		auctioneer = 136452,
		passenger = 134248,
	}

	for k, t in pairs(specificDB) do
		info.text = L[k]
		info.icon = icons[k]
		info.func = function(_,_,_, value)
			specific[k] = value
			journal:updateMountsList()
		end
		info.checked = function() return specific[k] end
		btn:ddAddButton(info, level)
	end

	info.text = L["Ride Along"]
	info.icon = 618976
	info.func = function(_,_,_, value)
		specific.rideAlong = value
		journal:updateMountsList()
	end
	info.checked = function() return specific.rideAlong end
	btn:ddAddButton(info, level)

	info.text = L["transform"]
	info.icon = 461140
	info.func = function(_,_,_, value)
		specific.transform = value
		journal:updateMountsList()
	end
	info.checked = function() return specific.transform end
	btn:ddAddButton(info, level)

	info.text = L["Multiple Models"]
	info.icon = 237185
	info.func = function(_,_,_, value)
		specific.multipleModels = value
		journal:updateMountsList()
	end
	info.checked = function() return specific.multipleModels end
	btn:ddAddButton(info, level)

	info.text = L["additional"]
	info.icon = ns.familyDBIcons.additional[0]
	info.func = function(_,_,_, value)
		specific.additional = value
		journal:updateMountsList()
	end
	info.checked = function() return specific.additional end
	btn:ddAddButton(info, level)

	info.text = L["rest"]
	info.icon = 413588
	info.func = function(_,_,_, value)
		specific.rest = value
		journal:updateMountsList()
	end
	info.checked = function() return specific.rest end
	btn:ddAddButton(info, level)
end