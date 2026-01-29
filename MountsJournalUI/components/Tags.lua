local addon, ns = ...
local L, util, mounts, journal, tags = ns.L, ns.util, ns.mounts, ns.journal, {}
local mountsDB, familyDB = ns.mountsDB, ns.familyDB
local pairs, ipairs, next, tinsert, wipe = pairs, ipairs, next, tinsert, wipe
local ltl = LibStub("LibThingsLoad-1.0")
journal.tags = tags
journal:on("MODULES_INIT", function() tags:init() end)
--@do-not-package@
local searchStr
--@end-do-not-package@


function tags:init()
	self.init = nil

	StaticPopupDialogs[util.addonName.."ADD_TAG"] = {
		text = ns.addon..": "..L["Add tag"],
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = 1,
		maxLetters = 48,
		editBoxWidth = 200,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = function(popup, cb)
			local editBox = popup.editBox or popup.EditBox
			local text = editBox:GetText()
			if text and text ~= "" then cb(popup, text) end
		end,
		EditBoxOnEnterPressed = function(self)
			StaticPopup_OnClick(self:GetParent(), 1)
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		OnShow = function(self)
			local editBox = self.editBox or self.EditBox
			editBox:SetFocus()
		end,
	}
	StaticPopupDialogs[util.addonName.."TAG_EXISTS"] = {
		text = ns.addon..": "..L["Tag already exists."],
		button1 = OKAY,
		whileDead = 1,
	}
	StaticPopupDialogs[util.addonName.."DELETE_TAG"] = {
		text = ns.addon..": "..L["Are you sure you want to delete tag %s?"],
		button1 = DELETE,
		button2 = CANCEL,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = function(_, cb) cb() end,
	}

	self.filter = mounts.filters.tags
	self.defFilter = mounts.defFilters.tags
	self.mountTags = mounts.globalDB.mountTags
	self.sortedTags = {}
	self:setSortedTags()

	self.mountOptionsMenu = LibStub("LibSFDropDown-1.5"):SetMixin({})
	self.mountOptionsMenu:ddHideWhenButtonHidden(journal.bgFrame)
	self.mountOptionsMenu:ddSetInitFunc(function(...) self:mountOptionsMenu_Init(...) end)
	self.mountOptionsMenu:ddSetDisplayMode(addon)

	journal.scrollBox:RegisterCallback(journal.scrollBox.Event.OnDataRangeChanged, function()
		if self.doNotHideMenu then return end
		self.mountOptionsMenu:ddOnHide()
	end)
end


function tags:setSortedTags()
	local filterTags = self.filter.tags
	wipe(self.sortedTags)
	for tag in pairs(filterTags) do
		tinsert(self.sortedTags, tag)
	end
	sort(self.sortedTags, function(tag1, tag2) return filterTags[tag1][1] < filterTags[tag2][1] end)
	for i, tag in ipairs(self.sortedTags) do
		filterTags[tag][1] = i
	end
end


function tags:setAllFilterTags(enabled)
	for _, value in pairs(self.filter.tags) do
		value[2] = enabled
	end
end


function tags:hideDropDown(mouseBtn)
	if mouseBtn == "LeftButton" then
		self.mountOptionsMenu:ddCloseMenus()
	end
end


function tags:dragMount(spellID)
	if InCombatLockdown() then return end
	C_Spell.PickupSpell(spellID)
end


function tags:dragButtonClick(btn, mouseBtn)
	local parent = btn:GetParent()
	if mouseBtn ~= "LeftButton" then
		self:showMountDropdown(parent, btn, 0, 0)
	elseif IsModifiedClick("CHATLINK") then
		local spellID = parent.spellID
		if MacroFrame and MacroFrame:IsShown() then
			local spellName = ltl:GetSpellFullName(spellID)
			ChatEdit_InsertLink(spellName)
		else
			local spellLink = ltl:GetSpellLink(spellID)
			ChatEdit_InsertLink(spellLink)
		end
	elseif parent.spellID then
		self:dragMount(parent.spellID)
	end
end


do
	local lastMountClick = 0
	function tags:listItemClick(btn, anchorTo, mouseBtn)
		if mouseBtn ~= "LeftButton" then
			self:showMountDropdown(btn, anchorTo, 0, 0)
		elseif IsModifiedClick("CHATLINK") then
			local spellID = btn.spellID
			if MacroFrame and MacroFrame:IsShown() then
				local spellName = ltl:GetSpellFullName(spellID)
				ChatEdit_InsertLink(spellName)
			else
				local spellLink = ltl:GetSpellLink(spellID)
				ChatEdit_InsertLink(spellLink)
			end
		elseif self.selectFunc then
			self.selectFunc(btn.spellID)
		else
			local time = GetTime()
			if btn.mountID ~= journal.selectedMountID then
				journal:setSelectedMount(btn.mountID, btn.spellID)
			elseif time - lastMountClick < .4 and type(btn.mountID) == "number" then
				journal:useMount(btn.mountID)
			end
			lastMountClick = time
		end
	end
end


function tags:showMountDropdown(btn, anchorTo, offsetX, offsetY)
	self.menuMountID = btn.mountID
	self.menuSpellID = btn.spellID
	self.mountOptionsMenu:ddToggle(1, nil, anchorTo, offsetX, offsetY)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end


function tags:mountOptionsMenu_Init(btn, level, value)
	local info = {}

	if level == 1 then
		local _,_,_, active, isUsable, _, isFavorite, _,_,_, isCollected = util.getMountInfo(self.menuMountID)
		local isMount = type(self.menuMountID) == "number"
		local needsFanfare = isMount and C_MountJournal.NeedsFanfare(self.menuMountID)
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
				journal:setSelectedMount(self.menuMountID, self.menuSpellID)
			end
			journal:useMount(self.menuMountID)
		end

		btn:ddAddButton(info, level)

		if not needsFanfare then
			info.disabled = not ((isCollected or not isMount) and journal:isCanFavorite(self.menuMountID))
			info.text = isFavorite and BATTLE_PET_UNFAVORITE or BATTLE_PET_FAVORITE
			info.func = function() journal:setIsFavorite(self.menuMountID, not isFavorite) end
			btn:ddAddButton(info, level)

			if isCollected then
				info.text = nil
				info.disabled = nil
				info.customFrame = journal.percentSlider
				info.customFrame:setText(L["Chance of summoning"])
				info.customFrame:setMinMax(1, 100)
				info.OnLoad = function(frame)
					local mountsWeight = journal.mountsWeight
					frame.level = level + 1
					frame:setValue(mountsWeight[self.menuSpellID] or 100)
					frame.setFunc = function(value)
						if value == 100 then value = nil end
						if mountsWeight[self.menuSpellID] ~= value then
							mountsWeight[self.menuSpellID] = value
							local btn = journal:getMountButtonByMountID(self.menuMountID)
							if btn then
								journal:initMountButton(btn, btn:GetElementData())
							end
						end
					end
				end
				btn:ddAddButton(info, level)
				info.customFrame = nil
				info.OnLoad = nil
			end

			info.disabled = nil
			info.keepShownOnClick = true
			info.notCheckable = nil
			info.isNotRadio = true
			info.func = function(_,_, mType)
				journal:mountToggle(mType, self.menuSpellID, self.menuMountID)
			end

			info.text = L["SELECT_AS_TYPE_1"]
			info.arg2 = "fly"
			info.checked = journal.list and journal.list.fly[self.menuSpellID]
			btn:ddAddButton(info, level)

			info.text = L["SELECT_AS_TYPE_2"]
			info.arg2 = "ground"
			info.checked = journal.list and journal.list.ground[self.menuSpellID]
			btn:ddAddButton(info, level)

			info.text = L["SELECT_AS_TYPE_3"]
			info.arg2 = "swimming"
			info.checked = journal.list and journal.list.swimming[self.menuSpellID]
			btn:ddAddButton(info, level)

			info.isNotRadio = nil
			info.func = nil
			info.notCheckable = true
			info.hasArrow = true
			info.text = L["tags"]
			info.value = 1
			btn:ddAddButton(info, level)
		end
		--@do-not-package@
		if isMount then
			info.disabled = nil
			info.keepShownOnClick = true
			info.hasArrow = true
			info.text = L["Family"]
			info.value = 2
			btn:ddAddButton(info, level)
		end
		--@end-do-not-package@

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
				mounts.globalDB.hiddenMounts[self.menuSpellID] = true
			elseif mounts.globalDB.hiddenMounts then
				mounts.globalDB.hiddenMounts[self.menuSpellID] = nil
				if not next(mounts.globalDB.hiddenMounts) then
					mounts.globalDB.hiddenMounts = nil
				end
			end
			self.doNotHideMenu = true
			journal:updateMountsList()
			self.doNotHideMenu = nil
		end
		info.checked = journal:isMountHidden(self.menuSpellID)
		btn:ddAddButton(info, level)

		info.keepShownOnClick = nil
		info.func = nil
		info.isNotRadio = nil
		info.notCheckable = true
		info.text = CANCEL
		btn:ddAddButton(info, level)
	elseif value == 1 then
		if #self.sortedTags == 0 then
			info.isNotRadio = true
			info.keepShownOnClick = true
			info.notCheckable = true
			info.disabled = true
			info.text = EMPTY
			btn:ddAddButton(info, level)
		else
			info.list = {}

			local func = function(btn, _,_, value)
				if value then
					self:addMountTag(self.menuSpellID, btn.value)
				else
					self:removeMountTag(self.menuSpellID, btn.value, true)
				end
			end
			local checked = function(btn) return self:getTagInMount(self.menuSpellID, btn.value) end

			for i, tag in ipairs(self.sortedTags) do
				info.list[i] = {
					isNotRadio = true,
					keepShownOnClick = true,
					text = tag,
					value = tag,
					func = func,
					checked = checked,
				}
			end
			btn:ddAddButton(info, level)
		end
	--@do-not-package@
	else
		local mountDB = mountsDB[self.menuMountID]

		local function isChecked(familyID)
			local ids = mountDB[2]
			if type(ids) == "number" then
				return ids == familyID
			else
				for i, id in ipairs(ids) do
					if id == familyID then return true end
				end
			end
		end

		local function setFamilyID(familyID, enabled)
			local ids = mountDB[2]
			if enabled then
				if type(ids) == "table" then
					if tInsertUnique(ids, familyID) then
						sort(ids)
					end
				elseif ids == 0 then
					mountDB[2] = familyID
				else
					mountDB[2] = {ids, familyID}
					sort(mountDB[2])
				end
			else
				if type(ids) == "table" then
					tDeleteItem(ids, familyID)
					if #ids == 1 then mountDB[2] = ids[1] end
				else
					mountDB[2] = 0
				end
			end
		end

		local check = function(button)
			return isChecked(button.value)
		end

		if value == 2 then
			local sortedNames = {}
			for k in next, familyDB do
				sortedNames[#sortedNames + 1] = {k, L[k]}
			end
			sort(sortedNames, function(a, b)
				return b[1] == "rest" or a[1] ~= "rest" and strcmputf8i(a[2], b[2]) < 0
			end)

			local func = function(button, _,_, checked)
				setFamilyID(button.value, checked)
				btn:ddRefresh(level)
			end

			local subFunc = function(button, _,_, checked)
				for k, v in next, familyDB[button.value] do
					setFamilyID(v, checked)
				end
				btn:ddRefresh(level + 1)
			end
			local subCheck = function(btn)
				local i, j = 0, 0
				for k, v in next, familyDB[btn.value] do
					i = i + 1
					if isChecked(v) then j = j + 1 end
				end
				return i == j and 1 or j > 0 and 2
			end

			local list = {}
			for i, name in ipairs(sortedNames) do
				local subInfo = {}
				subInfo.keepShownOnClick = true
				subInfo.isNotRadio = true
				subInfo.text = name[2]

				if type(familyDB[name[1]]) == "number" then
					subInfo.disabled = name[1] == "rest"
					subInfo.icon = ns.familyDBIcons[name[1]]
					subInfo.value = familyDB[name[1]]
					subInfo.func = func
					subInfo.checked = check
				else
					subInfo.hasArrow = true
					subInfo.icon = ns.familyDBIcons[name[1]][0]
					subInfo.value = name[1]
					subInfo.func = subFunc
					subInfo.checked = subCheck
				end

				list[i] = subInfo
			end

			info.search = function(str, text, _, btnInfo)
				if #str == 0 then
					searchStr = nil
					return true
				end
				searchStr = str
				if type(btnInfo.value) == "number" then
					return text:lower():find(str, 1, true)
				else
					if text:lower():find(str, 1, true) then return true end
					for name in next, familyDB[btnInfo.value] do
						if L[name]:lower():find(str, 1, true) then return true end
					end
				end
			end

			info.listMaxSize = 30
			info.list = list
			btn:ddAddButton(info, level)
		else
			info.keepShownOnClick = true
			info.isNotRadio = true

			local sortedNames = {}
			for k in next, familyDB[value] do
				sortedNames[#sortedNames + 1] = {k, L[k]}
			end
			sort(sortedNames, function(a, b)
				return b[1] == "Others" or a[1] ~= "Others" and strcmputf8i(a[2], b[2]) < 0
			end)
			if searchStr then
				for i, name in ipairs(sortedNames) do
					local start, stop = name[2]:lower():find(searchStr, 1, true)
					if start and stop then
						name[2] = ("%s|cffffd200%s|r%s"):format(name[2]:sub(0, start-1), name[2]:sub(start, stop), name[2]:sub(stop+1, #name[2]))
					end
				end
			end

			info.func = function(button, _,_, checked)
				setFamilyID(button.value, checked)
				btn:ddRefresh(level - 1)
			end
			info.checked = check

			for i, name in ipairs(sortedNames) do
				info.text = name[2]
				info.icon = ns.familyDBIcons[value][name[1]]
				info.value = familyDB[value][name[1]]
				btn:ddAddButton(info, level)
			end
		end
	--@end-do-not-package@
	end
end


function tags:addTag()
	StaticPopup_Show(util.addonName.."ADD_TAG", nil, nil, function(popup, text)
		if self.filter.tags[text] ~= nil then
			popup:Hide()
			StaticPopup_Show(util.addonName.."TAG_EXISTS")
			return
		end
		self.filter.tags[text] = {#self.sortedTags + 1, true}
		tinsert(self.sortedTags, text)
		journal:updateMountsList()
	end)
end


function tags:deleteTag(tag)
	StaticPopup_Show(util.addonName.."DELETE_TAG", NORMAL_FONT_COLOR_CODE..tag..FONT_COLOR_CODE_CLOSE, nil, function()
		for spellID in pairs(self.mountTags) do
			self:removeMountTag(spellID, tag)
		end
		self.filter.tags[tag] = nil
		self.defFilter.tags[tag] = nil
		self:setSortedTags()
		journal:updateMountsList()
	end)
end


function tags:setOrderTag(tag, step)
	local pos = self.filter.tags[tag][1]
	local nextPos = pos + step
	if nextPos > 0 and nextPos <= #self.sortedTags then
		local secondTag = self.sortedTags[nextPos]
		self.filter.tags[tag][1] = nextPos
		self.filter.tags[secondTag][1] = pos
		self.sortedTags[pos] = secondTag
		self.sortedTags[nextPos] = tag
	end
end


function tags:getTagInMount(spellID, tag)
	local mountTags = self.mountTags[spellID]
	if mountTags then return mountTags[tag] end
end


function tags:addMountTag(spellID, tag)
	if not self.mountTags[spellID] then
		self.mountTags[spellID] = {}
	end
	self.mountTags[spellID][tag] = true
	self.doNotHideMenu = true
	journal:updateMountsList()
	self.doNotHideMenu = nil
end


function tags:removeMountTag(spellID, tag, needUpdate)
	local mountTags = self.mountTags[spellID]
	if mountTags then
		mountTags[tag] = nil
		if next(mountTags) == nil then self.mountTags[spellID] = nil end
	end
	if needUpdate then
		self.doNotHideMenu = true
		journal:updateMountsList()
		self.doNotHideMenu = nil
	end
end


function tags:find(spellID, text)
	local mountTags = self.mountTags[spellID]
	if mountTags then
		local str = ""
		for tag in next, mountTags do
			str = str..tag:lower().."\0"
		end

		for word in text:gmatch("%S+") do
			if not str:find(word, 1, true) then return end
		end
		return true
	end
end


function tags:getFilterMount(spellID)
	local mountTags = self.mountTags[spellID]
	if not mountTags then return self.filter.noTag end
	local filterTags = self.filter.tags

	if self.filter.withAllTags then
		local i = 0
		for tag, value in next, filterTags do
			if value[2] then
				if not mountTags[tag] then return false end
				i = i + 1
			end
		end
		return i > 0
	else
		for tag in next, mountTags do
			if filterTags[tag][2] then return true end
		end
		return false
	end
end