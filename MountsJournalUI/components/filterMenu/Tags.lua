local addon, ns = ...
local L, journal = ns.L, ns.journal


function journal.filters.tags(dd, level)
	local filterTags = journal.tags.filter
	local info = {}
	info.keepShownOnClick = true
	info.isNotRadio = true

	info.text = L["No tag"]
	info.func = function(_,_,_, checked)
		filterTags.noTag = checked
		journal:updateMountsList()
	end
	info.checked = function() return filterTags.noTag end
	dd:ddAddButton(info, level)

	info.text = L["With all tags"]
	info.func = function(_,_,_, checked)
		filterTags.withAllTags = checked
		journal:updateMountsList()
	end
	info.checked = function() return filterTags.withAllTags end
	dd:ddAddButton(info, level)

	dd:ddAddSeparator(level)

	info.checked = nil
	info.notCheckable = true
	info.text = CHECK_ALL
	info.func = function()
		journal.tags:setAllFilterTags(true)
		journal:updateMountsList()
		dd:ddRefresh(level)
	end
	dd:ddAddButton(info, level)

	info.text = UNCHECK_ALL
	info.func = function()
		journal.tags:setAllFilterTags(false)
		journal:updateMountsList()
		dd:ddRefresh(level)
	end
	dd:ddAddButton(info, level)

	info.func = nil
	if #journal.tags.sortedTags == 0 then
		info.disabled = true
		info.text = EMPTY
		dd:ddAddButton(info, level)
		info.disabled = nil
	else
		info.list = {}
		local widgets = {{
			icon = "interface/worldmap/worldmappartyicon",
			OnClick = function(btn)
				PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
				filterTags.noTag = false
				filterTags.withAllTags = false
				journal.tags:setAllFilterTags(false)
				filterTags.tags[btn:text()][2] = true
				journal:updateMountsList()
				dd:ddRefresh(level)
			end,
		}}
		local text = function(btn) return journal.tags.sortedTags[btn.value] end
		local func = function(btn, _,_, checked)
			filterTags.tags[btn:text()][2] = checked
			journal:updateMountsList()
		end
		local checked = function(btn) return filterTags.tags[btn:text()][2] end
		local remove = function(btn) journal.tags:deleteTag(btn:text()) end
		local order = function(btn, step) journal.tags:setOrderTag(btn:text(), step) end

		for i, tag in ipairs(journal.tags.sortedTags) do
			info.list[i] = {
				keepShownOnClick = true,
				isNotRadio = true,
				widgets = widgets,
				text = text,
				func = func,
				checked = checked,
				remove = remove,
				order = order,
				value = i,
			}
		end
		dd:ddAddButton(info, level)
		info.list = nil
	end

	dd:ddAddSeparator(level)

	info.keepShownOnClick = nil
	info.notCheckable = true

	info.text = L["Add tag"]
	info.func = function()
		journal.tags:addTag()
	end
	dd:ddAddButton(info, level)
end