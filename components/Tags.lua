local addon, L = ...
local pairs, ipairs, next, select, tinsert, wipe = pairs, ipairs, next, select, tinsert, wipe
local util, mounts, journal, tags = MountsJournalUtil, MountsJournal, MountsJournalFrame, {}
journal.tags = tags
journal:on("MODULES_INIT", function() tags:init() end)


function tags:init()
	self.init = nil

	StaticPopupDialogs[util.addonName.."ADD_TAG"] = {
		text = addon..": "..L["Add tag"],
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = 1,
		maxLetters = 48,
		editBoxWidth = 200,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = function(popup, cb)
			local text = popup.editBox:GetText()
			if text and text ~= "" then cb(popup, text) end
		end,
		EditBoxOnEnterPressed = function(self)
			StaticPopup_OnClick(self:GetParent(), 1)
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		OnShow = function(self)
			self.editBox:SetFocus()
		end,
	}
	StaticPopupDialogs[util.addonName.."TAG_EXISTS"] = {
		text = addon..": "..L["Tag already exists."],
		button1 = OKAY,
		whileDead = 1,
	}
	StaticPopupDialogs[util.addonName.."DELETE_TAG"] = {
		text = addon..": "..L["Are you sure you want to delete tag %s?"],
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

	self.mountOptionsMenu = LibStub("LibSFDropDown-1.4"):SetMixin({})
	self.mountOptionsMenu:ddHideWhenButtonHidden(journal.bgFrame)
	self.mountOptionsMenu:ddSetInitFunc(function(...) self:mountOptionsMenu_Init(...) end)
	self.mountOptionsMenu:ddSetDisplayMode(addon)

	journal.scrollBox:RegisterCallback("OnDataRangeChanged", function()
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


function tags:dragMount(mountID)
	if InCombatLockdown() then return end
	local index = journal.indexByMountID[mountID]
	if index then C_MountJournal.Pickup(index) end
end


function tags:dragButtonClick(btn, mouseBtn)
	local parent = btn:GetParent()
	if mouseBtn ~= "LeftButton" then
		self:showMountDropdown(parent, btn, 0, 0)
	elseif IsModifiedClick("CHATLINK") then
		local id = parent.spellID
		if MacroFrame and MacroFrame:IsShown() then
			local spellName = GetSpellInfo(id)
			ChatEdit_InsertLink(spellName)
		else
			local spellLink = GetSpellLink(id)
			ChatEdit_InsertLink(spellLink)
		end
	else
		self:dragMount(parent.mountID)
	end
end


do
	local lastMountClick = 0
	function tags:listItemClick(btn, mouseBtn)
		if mouseBtn ~= "LeftButton" then
			self:showMountDropdown(btn, btn, 0, 0)
		elseif IsModifiedClick("CHATLINK") then
			local id = btn.spellID
			if MacroFrame and MacroFrame:IsShown() then
				local spellName = GetSpellInfo(id)
				ChatEdit_InsertLink(spellName)
			else
				local spellLink = GetSpellLink(id)
				ChatEdit_InsertLink(spellLink)
			end
		else
			local time = GetTime()
			if btn.mountID ~= journal.selectedMountID then
				journal:setSelectedMount(btn.mountID, btn.spellID)
			elseif time - lastMountClick < .4 then
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


function tags:mountOptionsMenu_Init(btn, level)
	local info = {}
	local realIndex = journal.indexByMountID[self.menuMountID]

	if level == 1 then
		local _,_,_, active, isUsable ,_, isFavorite, _,_,_, isCollected = C_MountJournal.GetMountInfoByID(self.menuMountID)
		local needsFanfare = C_MountJournal.NeedsFanfare(self.menuMountID)
		info.notCheckable = true

		if needsFanfare then
			info.text = UNWRAP
		elseif active then
			info.text = BINDING_NAME_DISMOUNT
		else
			info.text = MOUNT
			info.disabled = not isUsable
		end

		info.func = function()
			if needsFanfare then
				journal:setSelectedMount(self.menuMountID, self.menuSpellID)
			end
			journal:useMount(self.menuMountID)
		end

		btn:ddAddButton(info, level)

		if not needsFanfare then
			if isCollected then
				info.text = nil
				info.disabled = nil
				info.customFrame = journal.weightFrame
				info.OnLoad = function(frame)
					local mountsWeight = journal.mountsWeight
					frame.level = level + 1
					frame:setValue(mountsWeight[self.menuMountID] or 100)
					frame.setFunc = function(value)
						if value == 100 then value = nil end
						if mountsWeight[self.menuMountID] ~= value then
							mountsWeight[self.menuMountID] = value
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

			local canFavorite = realIndex and select(2, C_MountJournal.GetIsFavorite(realIndex))
			info.disabled = not (isCollected and canFavorite)

			if isFavorite then
				info.text = BATTLE_PET_UNFAVORITE
				info.func = function()
					if realIndex then
						C_MountJournal.SetIsFavorite(realIndex, false)
					end
				end
			else
				info.text = BATTLE_PET_FAVORITE
				info.func = function()
					if realIndex then
						C_MountJournal.SetIsFavorite(realIndex, true)
					end
				end
			end
			btn:ddAddButton(info, level)

			info.disabled = nil
			info.keepShownOnClick = true
			info.hasArrow = true
			info.func = nil
			info.text = L["tags"]
			btn:ddAddButton(info, level)
		end

		info.disabled = nil
		info.hasArrow = nil
		info.notCheckable = nil
		info.isNotRadio = true
		info.text = HIDE
		info.func = function(_,_,_, checked)
			if checked then
				mounts.globalDB.hiddenMounts = mounts.globalDB.hiddenMounts or {}
				mounts.globalDB.hiddenMounts[self.menuMountID] = true
			elseif mounts.globalDB.hiddenMounts then
				mounts.globalDB.hiddenMounts[self.menuMountID] = nil
				if not next(mounts.globalDB.hiddenMounts) then
					mounts.globalDB.hiddenMounts = nil
				end
			end
			journal:updateMountsList()
		end
		info.checked = journal:isMountHidden(self.menuMountID)
		btn:ddAddButton(info, level)

		info.keepShownOnClick = nil
		info.func = nil
		info.isNotRadio = nil
		info.notCheckable = true
		info.text = CANCEL
		btn:ddAddButton(info, level)
	else
		if #self.sortedTags == 0 then
			info.isNotRadio = true
			info.keepShownOnClick = true
			info.notCheckable = true
			info.disabled = true
			info.text = EMPTY
			btn:ddAddButton(info, level)
		else
			info.list = {}
			for i, tag in ipairs(self.sortedTags) do
				info.list[i] = {
					isNotRadio = true,
					keepShownOnClick = true,
					text = tag,
					func = function(_,_,_, value)
						if value then
							self:addMountTag(self.menuMountID, tag)
						else
							self:removeMountTag(self.menuMountID, tag, true)
						end
					end,
					checked = function() return self:getTagInMount(self.menuMountID, tag) end,
				}
			end
			btn:ddAddButton(info, level)
		end
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
		for mountID in pairs(self.mountTags) do
			self:removeMountTag(mountID, tag)
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


function tags:getTagInMount(mountID, tag)
	local mountTags = self.mountTags[mountID]
	if mountTags then return mountTags[tag] end
end


function tags:addMountTag(mountID, tag)
	if not self.mountTags[mountID] then
		self.mountTags[mountID] = {}
	end
	self.mountTags[mountID][tag] = true
	journal:updateMountsList()
end


function tags:removeMountTag(mountID, tag, needUpdate)
	local mountTags = self.mountTags[mountID]
	if mountTags then
		mountTags[tag] = nil
		if next(mountTags) == nil then self.mountTags[mountID] = nil end
	end
	if needUpdate then journal:updateMountsList() end
end


function tags:find(mountID, text)
	local mountTags = self.mountTags[mountID]
	if mountTags then
		local str = ""
		for tag in next, mountTags do
			str = str..tag:lower().."\n"
		end

		text = {(" "):split(text)}
		for i = 1, #text do
			if not str:find(text[i], 1, true) then return end
		end
		return true
	end
end


function tags:getFilterMount(mountID)
	local mountTags = self.mountTags[mountID]
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