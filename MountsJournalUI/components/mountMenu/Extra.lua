local addon, ns = ...
local L, journal = ns.L, ns.journal
local tags = journal.tags


function tags.mountMenu.extra(dd, level)
	local profileMenu = journal.bgFrame.profilesMenu
	local info = {}
	info.notCheckable = true

	info.text = L["Select all filtered mounts"]
	info.func = function(btn) profileMenu:setAllFiltredMounts(btn.text, true) end
	dd:ddAddButton(info, level)

	info.text = L["Unselect all filtered mounts"]
	info.func = function(btn) profileMenu:setAllFiltredMounts(btn.text, false) end
	dd:ddAddButton(info, level)

	dd:ddAddSeparator(level)

	info.text = L["Select all favorite mounts"]
	info.func = function(btn) profileMenu:setAllMounts(btn.text, true, true) end
	dd:ddAddButton(info, level)

	info.text = L["Unselect all favorite mounts"]
	info.func = function(btn) profileMenu:setAllMounts(btn.text, false, true) end
	dd:ddAddButton(info, level)

	dd:ddAddSeparator(level)

	info.text = L["Select all mounts"]
	info.func = function(btn) profileMenu:setAllMounts(btn.text, true) end
	dd:ddAddButton(info, level)

	info.text = L["Unselect all mounts"]
	info.func = function(btn) profileMenu:setAllMounts(btn.text, false) end
	dd:ddAddButton(info, level)
end
