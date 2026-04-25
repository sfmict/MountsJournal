local addon, ns = ...
local L, journal, mounts = ns.L, ns.journal, ns.mounts
local tags = journal.tags


function tags.mountMenu.profiles(dd, level, profile)
	local info = {}

	if profile then
		info.keepShownOnClick = true
		info.isNotRadio = true

		info.func = function(_,_, mType)
			local list, zoneMounts = journal:getTFromProfile(profile)
			journal:mountToggle(mType, tags.menuSpellID, tags.menuMountID, list, zoneMounts)
			dd:ddRefresh(level - 2)
		end

		local list = journal:getTFromProfile(profile)

		info.text = L["SELECT_AS_TYPE_1"]
		info.arg2 = "fly"
		info.checked = list and list.fly[tags.menuSpellID]
		dd:ddAddButton(info, level)

		info.text = L["SELECT_AS_TYPE_2"]
		info.arg2 = "ground"
		info.checked = list and list.ground[tags.menuSpellID]
		dd:ddAddButton(info, level)

		info.text = L["SELECT_AS_TYPE_3"]
		info.arg2 = "swimming"
		info.checked = list and list.swimming[tags.menuSpellID]
		dd:ddAddButton(info, level)
	else
		local list = {}

		for name, profile in next, mounts.profiles do
			list[#list + 1] = {
				notCheckable = true,
				hasArrow = true,
				text = name,
				value = {"profiles", profile}
			}
		end
		sort(list, function(a, b) return strcmputf8i(a.text, b.text) < 0 end)

		tinsert(list, 1, {
			notCheckable = true,
			hasArrow = true,
			text = DEFAULT,
			value = {"profiles", mounts.defProfile},
		})

		info.listMaxSize = 30
		info.list = list
		dd:ddAddButton(info, level)
	end
end
