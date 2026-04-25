local addon, ns = ...
local L, util, mounts, journal = ns.L, ns.util, ns.mounts, ns.journal
local tags = journal.tags
tags.mountMenu = {}


function tags.mountMenu.main(dd, level)
	local info = {}

	local _,_,_, active, isUsable, _, isFavorite, _,_,_, isCollected = util.getMountInfo(tags.menuMountID)
	local isMount = type(tags.menuMountID) == "number"
	local needsFanfare = isMount and C_MountJournal.NeedsFanfare(tags.menuMountID)
	info.notCheckable = true

	if needsFanfare then
		info.text = UNWRAP
	elseif active then
		info.text = BINDING_NAME_DISMOUNT
		info.disabled = not (isUsable and isMount)
	else
		info.text = MOUNT
		info.disabled = not (isUsable and isMount)
	end

	info.func = function()
		if needsFanfare then
			journal:setSelectedMount(tags.menuMountID, tags.menuSpellID)
		end
		journal:useMount(tags.menuMountID)
	end

	dd:ddAddButton(info, level)

	if not needsFanfare then
		info.disabled = not ((isCollected or not isMount) and journal:isCanFavorite(tags.menuMountID))
		info.text = isFavorite and BATTLE_PET_UNFAVORITE or BATTLE_PET_FAVORITE
		info.func = function() journal:setIsFavorite(tags.menuMountID, not isFavorite) end
		dd:ddAddButton(info, level)

		if isCollected then
			info.text = nil
			info.disabled = nil
			info.customFrame = journal.percentSlider
			info.customFrame:setText(L["Chance of summoning"])
			info.customFrame:setMinMax(1, 100)
			info.OnLoad = function(frame)
				local mountsWeight = journal.mountsWeight
				frame.level = level + 1
				frame:setValue(mountsWeight[tags.menuSpellID] or 100)
				frame.setFunc = function(value)
					if value == 100 then value = nil end
					if mountsWeight[tags.menuSpellID] ~= value then
						mountsWeight[tags.menuSpellID] = value
						local btn = journal:getMountButtonByMountID(tags.menuMountID)
						if btn then
							journal:initMountButton(btn, btn:GetElementData())
						end
					end
				end
			end
			dd:ddAddButton(info, level)
			info.customFrame = nil
			info.OnLoad = nil
		end

		info.disabled = nil
		info.keepShownOnClick = true
		info.notCheckable = nil
		info.isNotRadio = true
		info.func = function(_,_, mType)
			journal:mountToggle(mType, tags.menuSpellID, tags.menuMountID, journal.list)
		end

		info.text = L["SELECT_AS_TYPE_1"]
		info.arg2 = "fly"
		info.checked = function() return journal.list and journal.list.fly[tags.menuSpellID] end
		dd:ddAddButton(info, level)

		info.text = L["SELECT_AS_TYPE_2"]
		info.arg2 = "ground"
		info.checked = function() return journal.list and journal.list.ground[tags.menuSpellID] end
		dd:ddAddButton(info, level)

		info.text = L["SELECT_AS_TYPE_3"]
		info.arg2 = "swimming"
		info.checked = function() return journal.list and journal.list.swimming[tags.menuSpellID] end
		dd:ddAddButton(info, level)

		dd:ddAddSeparator(level)

		info.isNotRadio = nil
		info.func = nil
		info.notCheckable = true
		info.hasArrow = true
		info.text = L["Extra Actions"]
		info.value = "extra"
		dd:ddAddButton(info, level)

		info.text = L["Profiles"]
		info.value = "profiles"
		dd:ddAddButton(info, level)

		info.text = L["tags"]
		info.value = "tags"
		dd:ddAddButton(info, level)
	end
	--@do-not-package@
	if isMount then
		info.disabled = nil
		info.keepShownOnClick = true
		info.hasArrow = true
		info.text = L["Family"]
		info.value = "family"
		dd:ddAddButton(info, level)
	end
	--@end-do-not-package@

	dd:ddAddSeparator(level)

	info.disabled = nil
	info.hasArrow = nil
	info.notCheckable = nil
	info.value = nil
	info.keepShownOnClick = true
	info.isNotRadio = true
	info.text = HIDE
	info.func = function(_,_,_, checked)
		if checked then
			mounts.globalDB.hiddenMounts = mounts.globalDB.hiddenMounts or {}
			mounts.globalDB.hiddenMounts[tags.menuSpellID] = true
		elseif mounts.globalDB.hiddenMounts then
			mounts.globalDB.hiddenMounts[tags.menuSpellID] = nil
			if not next(mounts.globalDB.hiddenMounts) then
				mounts.globalDB.hiddenMounts = nil
			end
		end
		tags.doNotHideMenu = true
		journal:updateMountsList()
		tags.doNotHideMenu = nil
	end
	info.checked = journal:isMountHidden(tags.menuSpellID)
	dd:ddAddButton(info, level)

	info.keepShownOnClick = nil
	info.func = nil
	info.isNotRadio = nil
	info.notCheckable = true
	info.text = CANCEL
	dd:ddAddButton(info, level)
end
