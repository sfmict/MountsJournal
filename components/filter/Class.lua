local addon, ns = ...
local journal = ns.journal


function journal.filters.class(dd, level)
	local specific = ns.mounts.filters.specific
	local info = {}
	info.keepShownOnClick = true
	info.isNotRadio = true

	info.icon = "Interface/Glues/CharacterCreate/UI-CharacterCreate-Classes"
	info.widgets = {{
		icon = "interface/worldmap/worldmappartyicon",
		OnClick = function(btn)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			journal:setAllFilters("specific", false)
			specific[btn.value] = true
			journal:updateMountsList()
			dd:ddRefresh(level)
			dd:ddRefresh(level - 1)
		end,
	}}
	info.func = function(btn, _,_, checked)
		specific[btn.value] = checked
		journal:updateMountsList()
		dd:ddRefresh(level - 1)
	end
	info.checked = function(btn) return specific[btn.value] end

	local classes = ns.classFilterIDs
	for i = 1, #classes do
		local localized, className, id = GetClassInfo(classes[i])
		local classColor = C_ClassColor.GetClassColor(className)
		local t = CLASS_ICON_TCOORDS[className]
		info.text = classColor:WrapTextInColorCode(localized)
		info.iconInfo = {
			tCoordLeft = t[1],
			tCoordRight = t[2],
			tCoordTop = t[3],
			tCoordBottom = t[4],
		}
		info.value = id
		dd:ddAddButton(info, level)
	end
end