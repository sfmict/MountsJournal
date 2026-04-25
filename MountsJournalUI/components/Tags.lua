local addon, ns = ...
local L, util, mounts, journal, tags = ns.L, ns.util, ns.mounts, ns.journal, {}
local pairs, ipairs, next, tinsert, wipe = pairs, ipairs, next, tinsert, wipe
local ltl = LibStub("LibThingsLoad-1.0")
journal.tags = tags
journal:on("MODULES_INIT", function() tags:init() end)


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
	ClearCursor()
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
	if level == 1 then
		self.mountMenu.main(btn, level)
	elseif self.mountMenu[value] then
		self.mountMenu[value](btn, level)
	else
		self.mountMenu[value[1]](btn, level, value[2])
	end
end


function tags:addTag(spellID)
	StaticPopup_Show(util.addonName.."ADD_TAG", nil, nil, function(popup, tag)
		if self.filter.tags[tag] ~= nil then
			popup:Hide()
			StaticPopup_Show(util.addonName.."TAG_EXISTS")
			return
		end
		self.filter.tags[tag] = {#self.sortedTags + 1, true}
		tinsert(self.sortedTags, tag)
		journal:updateMountsList()
		if spellID then self:addMountTag(spellID, tag) end
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