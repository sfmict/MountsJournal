local addon, L = ...
local util, mounts, journal, tags = MountsJournalUtil, MountsJournal, MountsJournalFrame, {}
journal.tags = tags


function tags:init()
	self.addonName = format("%s_ADDON_", strupper(addon))
	StaticPopupDialogs[self.addonName.."ADD_TAG"] = {
		text = addon..": "..L["Add tag"],
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = 1,
		maxLetters = 48,
		editBoxWidth = 200,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = function(popup, data)
			local text = popup.editBox:GetText()
			if text and text ~= "" then
				data(text)
			end
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
	StaticPopupDialogs[self.addonName.."TAG_EXISTS"] = {
		text = addon..": "..L["Tag already exists."],
		button1 = OKAY,
		whileDead = 1,
	}
	StaticPopupDialogs[self.addonName.."DELETE_TAG"] = {
		text = addon..": "..L["Are you sure you want to delete tag %s?"],
		button1 = DELETE,
		button2 = CANCEL,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = function(_, data) data() end,
	}

	self.filter = mounts.filters.tags
	self.mountTags = mounts.globalDB.mountTags
	self.sortedTags = {}
	self:setSortedTags()

	MountJournal.mountOptionsMenu.initialize = function(_, level) self:mountOptionsMenu_Init(level) end
end


function tags:setSortedTags()
	wipe(self.sortedTags)
	local filterTags = self.filter.tags
	for tag in pairs(filterTags) do
		tinsert(self.sortedTags, tag)
	end
	sort(self.sortedTags, function(tag1, tag2) return filterTags[tag1][1] < filterTags[tag2][1] end)
end


function tags:setAllFilterTags(enabled)
	for _, value in pairs(self.filter.tags) do
		value[2] = enabled
	end
end


function tags:resetFilter()
	self.filter.noTag = true
	self.filter.withAllTags = false
	self:setAllFilterTags(true)
end


function tags:mountOptionsMenu_Init(level)
	if not MountJournal.menuMountIndex then return end
	local info = UIDropDownMenu_CreateInfo()
	local mountIndex, mountID = MountJournal.menuMountIndex, MountJournal.menuMountID

	if level == 1 then
		local active = select(4, C_MountJournal.GetMountInfoByID(mountID))
		local needsFanfare = C_MountJournal.NeedsFanfare(mountID)
		info.notCheckable = true

		if needsFanfare then
			info.text = UNWRAP
		elseif active then
			info.text = BINDING_NAME_DISMOUNT
		else
			info.text = MOUNT
			info.disabled = not MountJournal.menuIsUsable
		end

		info.func = function()
			if needsFanfare then
				MountJournal_Select(mountIndex)
			end
			MountJournalMountButton_UseMount(mountID)
		end

		UIDropDownMenu_AddButton(info, level)

		if not needsFanfare then
			local isFavorite, canFavorite = C_MountJournal.GetIsFavorite(mountIndex)

			if isFavorite then
				info.text = BATTLE_PET_UNFAVORITE
				info.func = function()
					C_MountJournal.SetIsFavorite(mountIndex, false)
				end
			else
				info.text = BATTLE_PET_FAVORITE
				info.func = function()
					C_MountJournal.SetIsFavorite(mountIndex, true)
				end
			end

			if canFavorite then
				info.disabled = false
			else
				info.disabled = true
			end
			UIDropDownMenu_AddButton(info, level)

			info.disabled = false
			info.keepShownOnClick = true
			info.hasArrow = true
			info.func = nil
			info.text = L["tags"]
			UIDropDownMenu_AddButton(info, level)
		end

		info.disabled = false
		info.keepShownOnClick = nil
		info.hasArrow = nil
		info.func = nil
		info.text = CANCEL
		UIDropDownMenu_AddButton(info, level)
	else
		info.isNotRadio = true
		info.keepShownOnClick = true

		if #self.sortedTags > 20 then
			local searchFrame = util.getDropDownSearchFrame()

			for _, tag in ipairs(self.sortedTags) do
				info.text = tag
				info.func = function(_,_,_, value)
					if value then
						self:addMountTag(mountID, tag)
					else
						self:removeMountTag(mountID, tag)
					end
				end
				info.checked = function() return self:getTagInMount(mountID, tag) end
				searchFrame:addButton(info)
			end

			UIDropDownMenu_AddButton({customFrame = searchFrame}, level)
		else
			for _, tag in ipairs(self.sortedTags) do
				info.text = tag
				info.func = function(_,_,_, value)
					if value then
						self:addMountTag(mountID, tag)
					else
						self:removeMountTag(mountID, tag)
					end
					UIDropDownMenu_Refresh(MountJournalFilterDropDown, 1, 2)
				end
				info.checked = function() return self:getTagInMount(mountID, tag) end
				UIDropDownMenu_AddButton(info, level)
			end

			if #self.sortedTags == 0 then
				info.notCheckable = true
				info.disabled = true
				info.text = EMPTY
				UIDropDownMenu_AddButton(info, level)
			end
		end
	end
end


function tags:addTag()
	StaticPopup_Show(self.addonName.."ADD_TAG", nil, nil, function(text)
		if self.filter.tags[text] ~= nil then
			StaticPopup_Show(self.addonName.."TAG_EXISTS")
			return
		end
		self.filter.tags[text] = {#self.sortedTags + 1, true}
		self:setSortedTags()
		journal:mountsListFullUpdate()
	end)
end


function tags:deleteTag(tag)
	StaticPopup_Show(self.addonName.."DELETE_TAG", NORMAL_FONT_COLOR_CODE..tag..FONT_COLOR_CODE_CLOSE, nil, function()
		for mountID in pairs(self.mountTags) do
			self:removeMountTag(mountID, tag)
		end
		self.filter.tags[tag] = nil
		self:setSortedTags()
		journal:mountsListFullUpdate()
	end)
end


function tags:setOrderTag(tag, step)
	local pos = util.inTable(self.sortedTags, tag)
	local nextStep = pos + step
	if nextStep > 0 and nextStep <= #self.sortedTags then
		self.filter.tags[tag][1] = nextStep
		self.filter.tags[self.sortedTags[nextStep]][1] = pos
		self:setSortedTags()
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
end


function tags:removeMountTag(mountID, tag)
	local mountTags = self.mountTags[mountID]
	if mountTags then
		mountTags[tag] = nil
		if next(mountTags) == nil then self.mountTags[mountID] = nil end
	end
end


function tags:getFilterMount(mountID)
	local mountTags = self.mountTags[mountID]
	if not mountTags then return self.filter.noTag end
	local filterTags = self.filter.tags

	if self.filter.withAllTags then
		local i = 0
		for tag, value in pairs(filterTags) do
			if value[2] then
				i = i + 1
				if not mountTags[tag] then return false end
			end
		end
		return i > 0
	else
		for tag in pairs(mountTags) do
			if filterTags[tag][2] then return true end
		end
		return false
	end
end