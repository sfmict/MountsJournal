local addon, ns = ...
local L, journal = ns.L, ns.journal


function journal.filters.tags(btn, level)
	local filterTags = journal.tags.filter
	local info = {}
	info.keepShownOnClick = true
	info.isNotRadio = true

	info.text = L["No tag"]
	info.func = function(_,_,_, value)
		filterTags.noTag = value
		journal:updateMountsList()
	end
	info.checked = function() return filterTags.noTag end
	btn:ddAddButton(info, level)

	info.text = L["With all tags"]
	info.func = function(_,_,_, value)
		filterTags.withAllTags = value
		journal:updateMountsList()
	end
	info.checked = function() return filterTags.withAllTags end
	btn:ddAddButton(info, level)

	btn:ddAddSeparator(level)

	info.notCheckable = true
	info.text = CHECK_ALL
	info.func = function()
		journal.tags:setAllFilterTags(true)
		journal:updateMountsList()
		btn:ddRefresh(level)
	end
	btn:ddAddButton(info, level)

	info.text = UNCHECK_ALL
	info.func = function()
		journal.tags:setAllFilterTags(false)
		journal:updateMountsList()
		btn:ddRefresh(level)
	end
	btn:ddAddButton(info, level)

	info.func = nil
	if #journal.tags.sortedTags == 0 then
		info.disabled = true
		info.text = EMPTY
		btn:ddAddButton(info, level)
		info.disabled = nil
	else
		info.list = {}
		for i, tag in ipairs(journal.tags.sortedTags) do
			info.list[i] = {
				keepShownOnClick = true,
				isNotRadio = true,
				text = function() return journal.tags.sortedTags[i] end,
				func = function(btn, _,_, value)
					filterTags.tags[btn._text][2] = value
					journal:updateMountsList()
				end,
				checked = function(btn) return filterTags.tags[btn._text][2] end,
				remove = function(btn)
					journal.tags:deleteTag(btn._text)
				end,
				order = function(btn, step)
					journal.tags:setOrderTag(btn._text, step)
				end,
			}
		end
		btn:ddAddButton(info, level)
		info.list = nil
	end

	btn:ddAddSeparator(level)

	info.keepShownOnClick = nil
	info.notCheckable = true
	info.checked = nil

	info.text = L["Add tag"]
	info.func = function()
		journal.tags:addTag()
	end
	btn:ddAddButton(info, level)
end