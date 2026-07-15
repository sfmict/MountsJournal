local addon, ns = ...
local util, journal = ns.util, ns.journal
local tags = journal.tags


function tags.mountMenu.customOrder(dd, level)
	local list = {}

	local func = function(btn)
		journal:setCustomOrder(journal:getCustomOrder(tags.menuMountID), btn.value)
	end

	for i, mountID in ipairs(journal.mountIDs) do
		local name, _, icon = util.getMountInfo(mountID)
		list[i] = {
			notCheckable = true,
			text = name,
			icon = icon,
			value = i,
			func = func,
		}
	end

	dd:ddAddButton({list = list}, level)
end
