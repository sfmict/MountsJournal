local addon, ns = ...
local L, journal = ns.L, ns.journal
local tags = journal.tags


function tags.mountMenu.tags(dd, level)
	local info = {}

	if #tags.sortedTags == 0 then
		info.isNotRadio = true
		info.keepShownOnClick = true
		info.notCheckable = true
		info.disabled = true
		info.text = EMPTY
		dd:ddAddButton(info, level)
	else
		info.list = {}

		local func = function(btn, _,_, value)
			if value then
				tags:addMountTag(tags.menuSpellID, btn.value)
			else
				tags:removeMountTag(tags.menuSpellID, btn.value, true)
			end
		end
		local checked = function(btn) return tags:getTagInMount(tags.menuSpellID, btn.value) end

		for i, tag in ipairs(tags.sortedTags) do
			info.list[i] = {
				isNotRadio = true,
				keepShownOnClick = true,
				text = tag,
				value = tag,
				func = func,
				checked = checked,
			}
		end
		dd:ddAddButton(info, level)

		dd:ddAddSeparator(level)

		info.list = nil
		info.notCheckable = true
		info.text = L["Add tag"]
		info.func = function() tags:addTag(tags.menuSpellID) end
		dd:ddAddButton(info, level)
	end
end
