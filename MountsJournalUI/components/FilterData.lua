local _, ns = ...
local L, journal, util, mounts = ns.L, ns.journal, ns.util, ns.mounts
local newMounts, mountsDB, specificDB, classDB = ns.newMounts, ns.mountsDB, ns.specificDB, ns.classDB
local C_MountJournal, C_Timer, GetTime = C_MountJournal, C_Timer, GetTime
local next, pairs, ipairs, type, math, tonumber = next, pairs, ipairs, type, math, tonumber
local wipe, sort, select = wipe, table.sort, select


function journal:sortMounts()
	local fSort, db = mounts.filters.sorting, mountsDB
	local numNeedingFanfare = C_MountJournal.GetNumMountsNeedingFanfare()

	local function getByMountID(by, mount, data)
		if by == "type" then
			local _,_,_,_, mType = C_MountJournal.GetMountInfoExtraByID(mount)
			mType = util.mountTypes[mType]
			return type(mType) == "number" and mType or mType[1]
		elseif by == "family" then
			local family = db[mount][2]
			return type(family) == "number" and family or family[1]
		elseif by == "expansion" then
			return db[mount][1]
		elseif by == "rarity" then
			return db[mount][3]
		elseif by == "summons" then
			return mounts:getMountSummons(data.spellID)
		elseif by == "time" then
			return mounts:getMountTime(data.spellID)
		elseif by == "distance" then
			return mounts:getMountDistance(data.spellID)
		end
		return data.name
	end

	local function getByMount(by, mount, data)
		if by == "type" then
			local mType = util.mountTypes[mount.mountType]
			return type(mType) == "number" and mType or mType[1]
		elseif by == "family" then
			local family = mount.familyID
			return type(family) == "number" and family or family[1]
		elseif by == "expansion" then
			return mount.expansion
		elseif by == "rarity" then
			return 100
		elseif by == "summons" then
			return mounts:getMountSummons(data.spellID)
		elseif by == "time" then
			return mounts:getMountTime(data.spellID)
		elseif by == "distance" then
			return mounts:getMountDistance(data.spellID)
		end
		return data.name
	end

	local mCache = setmetatable({}, {__index = function(t, mount)
		local data = {}
		if type(mount) == "number" then
			local name, spellID, _,_,_,_, isFavorite, _,_,_, isCollected = C_MountJournal.GetMountInfoByID(mount)
			data.name = name
			data.isFavorite = isFavorite
			data.isCollected = isCollected
			data.spellID = spellID
			if numNeedingFanfare > 0 and C_MountJournal.NeedsFanfare(mount) then
				data.needFanfare = true
				numNeedingFanfare = numNeedingFanfare - 1
			end
			data.by = getByMountID(fSort.by, mount, data)
			data.by2 = fSort.by2 == fSort.by and data.by or getByMountID(fSort.by2, mount, data)
			if fSort.by3 == fSort.by then data.by3 = data.by
			elseif fSort.by3 == fSort.by2 then data.by3 = data.by2
			else data.by3 = getByMountID(fSort.by3, mount, data) end
		else
			data.name = mount.name
			data.isFavorite = mount:getIsFavorite()
			data.isCollected = mount:isCollected()
			data.spellID = mount.spellID
			data.additional = true
			data.by = getByMount(fSort.by, mount, data)
			data.by2 = fSort.by2 == fSort.by and data.by or getByMount(fSort.by2, mount, data)
			if fSort.by3 == fSort.by then data.by3 = data.by
			elseif fSort.by3 == fSort.by2 then data.by3 = data.by2
			else data.by3 = getByMount(fSort.by3, mount, data) end
		end
		t[mount] = data
		return data
	end})

	sort(self.mountIDs, function(a, b)
		if a == b then return false end
		local ma = mCache[a]
		local mb = mCache[b]

		-- FANFARE
		if ma.needFanfare ~= mb.needFanfare then return ma.needFanfare end
		-- COLLECTED
		if fSort.collectedFirst and ma.isCollected ~= mb.isCollected then return ma.isCollected end
		-- FAVORITES
		if fSort.favoritesFirst and ma.isFavorite ~= mb.isFavorite then return ma.isFavorite end
		-- ADDITIONAL
		if fSort.additionalFirst and ma.additional ~= mb.additional then return ma.additional end

		-- BY
		if ma.by < mb.by then return not fSort.reverse
		elseif ma.by > mb.by then return fSort.reverse end

		if ma.by2 < mb.by2 then return not fSort.reverse2
		elseif ma.by2 > mb.by2 then return fSort.reverse2 end

		if ma.by3 < mb.by3 then return not fSort.reverse3
		elseif ma.by3 > mb.by3 then return fSort.reverse3 end

		return ma.spellID < mb.spellID
	end)

	self:updateMountsList()
end


function journal:saveDefaultFilters()
	local filters = mounts.filters
	local defFilters = mounts.defFilters

	defFilters.collected = filters.collected
	defFilters.notCollected = filters.notCollected
	defFilters.unusable = filters.unusable
	defFilters.hideOnChar = filters.hideOnChar
	defFilters.onlyHideOnChar = filters.onlyHideOnChar
	defFilters.hiddenByPlayer = filters.hiddenByPlayer
	defFilters.onlyHiddenByPlayer = filters.onlyHiddenByPlayer
	defFilters.onlyNew = filters.onlyNew
	defFilters.mountsRarity.sign = filters.mountsRarity.sign
	defFilters.mountsRarity.value = filters.mountsRarity.value
	defFilters.mountsWeight.sign = filters.mountsWeight.sign
	defFilters.mountsWeight.weight = filters.mountsWeight.weight
	defFilters.tags.noTag = filters.tags.noTag
	defFilters.tags.withAllTags = filters.tags.withAllTags
	defFilters.color.r = filters.color.r
	defFilters.color.g = filters.color.g
	defFilters.color.b = filters.color.b
	defFilters.color.threshold = filters.color.threshold

	for i = 1, #filters.types do
		defFilters.types[i] = filters.types[i]
	end
	for i = 1, #filters.selected do
		defFilters.selected[i] = filters.selected[i]
	end
	for i = 1, #filters.sources do
		defFilters.sources[i] = filters.sources[i]
	end
	for k, value in pairs(filters.specific) do
		defFilters.specific[k] = value
	end
	for k, value in pairs(filters.family) do
		defFilters.family[k] = value
	end
	for i = 1, #filters.expansions do
		defFilters.expansions[i] = filters.expansions[i]
	end
	for i = 1, #filters.factions do
		defFilters.factions[i] = filters.factions[i]
	end
	for i = 1, #filters.pet do
		defFilters.pet[i] = filters.pet[i]
	end
	for tag, value in pairs(filters.tags.tags) do
		defFilters.tags.tags[tag] = value[2]
	end

	self:setShownCountMounts()
end


function journal:restoreDefaultFilters()
	local defFilters = mounts.defFilters

	defFilters.collected = true
	defFilters.notCollected = true
	defFilters.unusable = true
	defFilters.hideOnChar = false
	defFilters.onlyHideOnChar = false
	defFilters.hiddenByPlayer = false
	defFilters.onlyHiddenByPlayer = false
	defFilters.onlyNew = false
	defFilters.mountsRarity.sign = nil
	defFilters.mountsRarity.value = 100
	defFilters.mountsWeight.sign = nil
	defFilters.mountsWeight.weight = 100
	defFilters.tags.noTag = true
	defFilters.tags.withAllTags = false
	defFilters.color = {threshold = 20}
	wipe(defFilters.types)
	wipe(defFilters.selected)
	wipe(defFilters.sources)
	wipe(defFilters.specific)
	wipe(defFilters.family)
	wipe(defFilters.expansions)
	wipe(defFilters.factions)
	wipe(defFilters.pet)
	wipe(defFilters.tags.tags)

	self:setShownCountMounts()
end


do
	local function onClick(btn)
		journal:resetFilterByInfo(btn.info)
	end


	function journal:updateFilterNavBar()
		local list = self.shownPanel.list
		local framePool = self.shownPanel.framePool
		local maxWidth = self.shownPanel.resetFilter:GetLeft() - self.shownPanel.count:GetRight() - 4
		local width = 0
		local index = 0

		framePool:ReleaseAll()
		for i = 1, #list do
			local f = framePool:Acquire()
			local text = list[i]
			f.info = list[text]
			f:SetScript("OnClick", onClick)
			f:SetPoint("LEFT", width, 0)
			f.text:SetText(list[i])
			f:Show()
			local textWidth = f.text:GetWidth()
			f:SetWidth(textWidth + 18)
			width = width + textWidth + 20
			if width > maxWidth then
				width = width - textWidth - 20
				index = i
				framePool:Release(f)
				break
			end
		end

		self.shownPanel.startIndex = index
		self.shownPanel.resetFilter:SetShown(index ~= 0)
		self.shownPanel.resetBar:SetWidth(width)
	end
end


do
	local function add(list, text, defFilters, filters, k)
		local info = list[text]
		if info then
			local info = list[text]
			local i = 4
			while info[i] do
				i = i + 3
			end
			info[i] = defFilters
			info[i + 1] = filters
			info[i + 2] = k
			return
		end
		list[text] = {defFilters, filters, k}
		list[#list + 1] = text
	end


	local function checkFilter(list, text, defFilters, filters, k, ...)
		if k then
			if (defFilters[k] or false) ~= (filters[k] or false) then add(list, text, defFilters, filters, k) end
			for i = 1, select("#", ...) do
				local k = select(i, ...)
				if (defFilters[k] or false) ~= (filters[k] or false) then add(list, text, defFilters, filters, k) end
			end
		else
			for k, v in next, filters do
				if defFilters[k] ~= v then add(list, text, defFilters, filters) break end
			end
		end
	end


	function journal:checkFiltersDefault()
		local filters = mounts.filters
		local defFilters = mounts.defFilters
		local list = wipe(self.shownPanel.list)

		if #self.searchBox:GetText() ~= 0 then list[1] = SEARCH end
		checkFilter(list, COLLECTED, defFilters, filters, "collected")
		checkFilter(list, NOT_COLLECTED, defFilters, filters, "notCollected")
		checkFilter(list, MOUNT_JOURNAL_FILTER_UNUSABLE, defFilters, filters, "unusable")
		checkFilter(list, L["hidden for character"], defFilters, filters, "hideOnChar", "onlyHideOnChar")
		checkFilter(list, L["Hidden by player"], defFilters, filters, "hiddenByPlayer", "onlyHiddenByPlayer")
		checkFilter(list, L["Only new"], defFilters, filters, "onlyNew")
		checkFilter(list, L["types"], defFilters.types, filters.types)
		checkFilter(list, L["selected"], defFilters.selected, filters.selected)
		checkFilter(list, SOURCES, defFilters.sources, filters.sources)
		checkFilter(list, L["Specific"], defFilters.specific, filters.specific)
		checkFilter(list, L["Family"], defFilters.family, filters.family)
		checkFilter(list, L["expansions"], defFilters.expansions, filters.expansions)
		checkFilter(list, COLOR, defFilters.color, filters.color, "r", "g", "b", "threshold")
		checkFilter(list, L["factions"], defFilters.factions, filters.factions)
		checkFilter(list, PET, defFilters.pet, filters.pet)
		checkFilter(list, L["Rarity"], defFilters.mountsRarity, filters.mountsRarity, "sign", "value")
		checkFilter(list, L["Chance of summoning"], defFilters.mountsWeight, filters.mountsWeight, "sign", "weight")
		checkFilter(list, L["tags"], defFilters.tags, filters.tags, "noTag", "withAllTags")
		for tag, value in pairs(filters.tags.tags) do
			if defFilters.tags.tags[tag] ~= value[2] then
				add(list, L["tags"], defFilters.tags.tags, filters.tags.tags)
				break
			end
		end

		return #list ~= 0
	end
end


function journal:resetFilterByInfo(info)
	if type(info) == "table" then
		local i = 1
		local defFilter = info[i]
		while defFilter do
			local filter = info[i + 1]
			local k = info[i + 2]
			if k then
				filter[k] = defFilter[k]
			else
				for k in next, filter do
					if type(filter[k]) == "table" then
						filter[k][2] = defFilter[k]
					else
						filter[k] = defFilter[k]
					end
				end
			end
			i = i + 3
			defFilter = info[i]
		end
	else
		self.searchBox:SetText("")
	end
	self:updateBtnFilters()
	self:updateMountsList()
	self:setCountMounts()
end


function journal:setAllFilters(typeFilter, enabled)
	local filter = mounts.filters[typeFilter]
	for k in pairs(filter) do
		filter[k] = enabled
	end
end


function journal:clearBtnFilters()
	self:setAllFilters("sources", true)
	self:setAllFilters("types", true)
	self:setAllFilters("selected", true)
	self:updateBtnFilters()
	self:updateMountsList()
end


function journal:resetToDefaultFilters()
	local filters = mounts.filters
	local defFilters = mounts.defFilters

	filters.collected = defFilters.collected
	filters.notCollected = defFilters.notCollected
	filters.unusable = defFilters.unusable
	filters.hideOnChar = defFilters.hideOnChar
	filters.onlyHideOnChar = defFilters.onlyHideOnChar
	filters.hiddenByPlayer = defFilters.hiddenByPlayer
	filters.onlyHiddenByPlayer = defFilters.onlyHiddenByPlayer
	filters.onlyNew = defFilters.onlyNew
	filters.mountsRarity.sign = defFilters.mountsRarity.sign
	filters.mountsRarity.value = defFilters.mountsRarity.value
	filters.mountsWeight.sign = defFilters.mountsWeight.sign
	filters.mountsWeight.weight = defFilters.mountsWeight.weight
	filters.tags.noTag = defFilters.tags.noTag
	filters.tags.withAllTags = defFilters.tags.withAllTags
	filters.color.r = defFilters.color.r
	filters.color.g = defFilters.color.g
	filters.color.b = defFilters.color.b
	filters.color.threshold = defFilters.color.threshold

	for i = 1, #filters.types do
		filters.types[i] = defFilters.types[i]
	end
	for i = 1, #filters.selected do
		filters.selected[i] = defFilters.selected[i]
	end
	for i = 1, #filters.sources do
		filters.sources[i] = defFilters.sources[i]
	end
	for k in pairs(filters.specific) do
		filters.specific[k] = defFilters.specific[k]
	end
	for k in pairs(filters.family) do
		filters.family[k] = defFilters.family[k]
	end
	for i = 1, #filters.expansions do
		filters.expansions[i] = defFilters.expansions[i]
	end
	for i = 1, #filters.factions do
		filters.factions[i] = defFilters.factions[i]
	end
	for i = 1, #filters.pet do
		filters.pet[i] = defFilters.pet[i]
	end
	for tag, value in pairs(filters.tags.tags) do
		value[2] = defFilters.tags.tags[tag]
	end

	self.searchBox:SetText("")
	self:updateBtnFilters()
	self:updateMountsList()
	self:setCountMounts()
end


function journal:setBtnFilters(tab)
	local i = 0
	local children = self.filtersBar[tab].childs
	local filters = mounts.filters[tab]

	for _, btn in ipairs(children) do
		local checked = btn:GetChecked()
		filters[btn.id] = checked
		if not checked then i = i + 1 end
	end

	if i == #children then
		self:setAllFilters(tab, true)
	end

	self:updateBtnFilters()
	self:updateMountsList()
end


function journal:updateBtnFilters()
	local filtersBar, clearShow = self.filtersBar, false

	for typeFilter, filter in pairs(mounts.filters) do
		-- SOURCES
		if typeFilter == "sources" then
			local i, n = 0, 0
			for k, v in pairs(filter) do
				if k ~= 0 then
					i = i + 1
					if v == true then n = n + 1 end
				end
			end

			if i == n then
				filter[0] = true
				for _, btn in ipairs(filtersBar.sources.childs) do
					btn:SetChecked(false)
					btn.icon:SetDesaturated()
				end
				filtersBar.sources:GetParent().filtred:Hide()
			else
				clearShow = true
				filter[0] = false
				for _, btn in ipairs(filtersBar.sources.childs) do
					local checked = filter[btn.id]
					btn:SetChecked(checked)
					btn.icon:SetDesaturated(not checked)
				end
				filtersBar.sources:GetParent().filtred:Show()
			end

		-- TYPES AND SELECTED
		elseif filtersBar[typeFilter] then
			local i = 0
			for _, v in ipairs(filter) do
				if v then i = i + 1 end
			end

			if i == #filter then
				for _, btn in ipairs(filtersBar[typeFilter].childs) do
					btn:SetChecked(false)
					if btn.id > 3 then
						btn.icon:SetDesaturated()
					else
						btn.icon:SetVertexColor(self.colors["mount"..btn.id]:GetRGB())
					end
				end
				filtersBar[typeFilter]:GetParent().filtred:Hide()
			else
				clearShow = true
				for _, btn in ipairs(filtersBar[typeFilter].childs) do
					local checked = filter[btn.id]
					btn:SetChecked(checked)
					if btn.id > 3 then
						btn.icon:SetDesaturated(not checked)
					else
						local color = checked and self.colors["mount"..btn.id] or self.colors.dark
						btn.icon:SetVertexColor(color:GetRGB())
					end
				end
				filtersBar[typeFilter]:GetParent().filtred:Show()
			end
		end
	end

	-- CLEAR BTN FILTERS
	filtersBar.clear:SetShown(clearShow)
end


function journal:isMountHidden(spellID)
	return mounts.globalDB.hiddenMounts and mounts.globalDB.hiddenMounts[spellID]
end


function journal:getFilterSelected(spellID)
	local filter = mounts.filters.selected
	local list = self.list
	if list then
		local i = 0
		if list.fly[spellID] then if filter[1] then return true end
		else i = i + 1 end
		if list.ground[spellID] then if filter[2] then return true end
		else i = i + 1 end
		if list.swimming[spellID] then if filter[3] then return true end
		else i = i + 1 end
		return i == 3 and filter[4]
	else
		return filter[4]
	end
end


function journal:getFilterSpecific(spellID, isSelfMount, mountType, mountID)
	local filter = mounts.filters.specific
	local i = 0
	if isSelfMount then if filter.transform then return true end
	else i = i + 1 end
	if ns.additionalMounts[spellID] then if filter.additional then return true end
	else i = i + 1 end
	if mountType == 402 or mountType == 445 then if filter.rideAlong then return true end
	else i = i + 1 end
	if self.mountsWithMultipleModels[mountID] then if filter.multipleModels then return true end
	else i = i + 1 end
	for k, t in pairs(specificDB) do
		if t[spellID] then if filter[k] then return true end
		else i = i + 1 end
	end
	local class = classDB[spellID]
	if class then if filter[class] then return true end
	else i = i + 1 end
	return i == 8 and filter.rest
end


function journal:getFilterFamily(familyID)
	local filter = mounts.filters.family
	if type(familyID) == "table" then
		for i = 1, #familyID do
			if filter[familyID[i]] then return true end
		end
	else
		return filter[familyID]
	end
end


function journal:getFilterRarity(rarity)
	local filter = mounts.filters.mountsRarity
	if not filter.sign then
		return true
	elseif filter.sign == ">" then
		return rarity > filter.value
	elseif filter.sign == "<" then
		return rarity < filter.value
	else
		return math.floor(rarity + .5) == filter.value
	end
end


function journal:getFilterWeight(spellID)
	local filter = mounts.filters.mountsWeight
	if not filter.sign then
		return true
	else
		local mountWeight = self.mountsWeight[spellID] or 100
		if filter.sign == ">" then
			return mountWeight > filter.weight
		elseif filter.sign == "<" then
			return mountWeight < filter.weight
		else
			return mountWeight == filter.weight
		end
	end
end


function journal:getFilterType(mountType)
	local types = mounts.filters.types
	local mType = util.mountTypes[mountType]
	if type(mType) == "table" then
		for i = 1, #mType do
			if types[mType[i]] then return true end
		end
	else
		return types[mType]
	end
end


function journal:getCustomSearchFilter(text, mountID, spellID, mountType)
	local id = text:match("^id:(%d+)")
	if id then return tonumber(id) == mountID end

	id = text:match("^spell:(%d+)")
	if id then return tonumber(id) == spellID end

	id = text:match("^type:(%d+)")
	if id then return tonumber(id) == mountType end
end


function journal:setShownCountMounts(numMounts)
	if numMounts then
		self.shownPanel.count:SetText(numMounts)
		self.shownNumMouns = numMounts
	end
	self.shownPanel:SetShown(self:checkFiltersDefault())
	self:updateFilterNavBar()
	-- self.leftInset:GetHeight()
end


function journal:updateScrollMountList()
	self.scrollBox:SetDataProvider(self.dataProvider, ScrollBoxConstants.RetainScrollPosition)
end


function journal:updateMountsList()
	if self.mountListUpdatePending then return end
	local utime = GetTime()
	local timeSinceLastUpdate = utime - self.lastMountListUpdate
	if timeSinceLastUpdate < .2 then
		self.mountListUpdatePending = true
		local doNotHideMenu = self.tags.doNotHideMenu
		C_Timer.After(.2 - timeSinceLastUpdate, function()
			self.mountListUpdatePending = false
			self.tags.doNotHideMenu = doNotHideMenu
			self:updateMountsList()
			self.tags.doNotHideMenu = nil
		end)
		return
	end
	self.lastMountListUpdate = utime

	local filters, newMounts, tags, pets, getMountInfo, getMountInfoExtra = mounts.filters, newMounts, self.tags, ns.pets, util.getMountInfo, util.getMountInfoExtra
	local sources, factions, pet, expansions, color = filters.sources, filters.factions, filters.pet, filters.expansions, filters.color
	local r,g,b, threshold = color.r, color.g, color.b, color.threshold
	local noColor = r == nil
	local CheckMountColor = ns.CheckMountColor
	local text = util.cleanText(self.searchBox:GetText())
	local numMounts = 0
	self.dataProvider = CreateDataProvider()

	for i = 1, #self.mountIDs do
		local mountID = self.mountIDs[i]
		local name, spellID, _,_, isUsable, sourceType, _,_, mountFaction, shouldHideOnChar, isCollected = getMountInfo(mountID)
		local expansion, familyID, rarity, _,_, sourceText, isSelfMount, mountType = getMountInfoExtra(mountID)
		local petID = pets:getPetForProfile(self.petForMount, spellID)
		local isMountHidden = self:isMountHidden(spellID)

		-- FAMILY
		if self:getFilterFamily(familyID)
		-- HIDDEN FOR CHARACTER
		and (not shouldHideOnChar or filters.hideOnChar)
		and (not (filters.hideOnChar and filters.onlyHideOnChar) or shouldHideOnChar)
		-- HIDDEN BY PLAYER
		and (not isMountHidden or filters.hiddenByPlayer)
		and (not (filters.hiddenByPlayer and filters.onlyHiddenByPlayer) or isMountHidden)
		-- COLLECTED
		and (isCollected and filters.collected or not isCollected and filters.notCollected)
		-- UNUSABLE
		and (isUsable or not isCollected or filters.unusable)
		-- EXPANSIONS
		and expansions[expansion]
		-- ONLY NEW
		and (not filters.onlyNew or newMounts[mountID])
		-- SOURCES
		and sources[sourceType]
		-- SEARCH
		and (#text == 0
			or name:lower():find(text, 1, true)
			or sourceText:lower():find(text, 1, true)
			or tags:find(spellID, text)
			or self:getCustomSearchFilter(text, mountID, spellID, mountType))
		-- TYPE
		and self:getFilterType(mountType)
		-- FACTION
		and factions[(mountFaction or 2) + 1]
		-- SELECTED
		and self:getFilterSelected(spellID)
		-- PET
		and pet[petID and (type(petID) == "number" and petID or 3) or 4]
		-- COLOR
		and (noColor or CheckMountColor(mountID, r,g,b, threshold))
		-- SPECIFIC
		and self:getFilterSpecific(spellID, isSelfMount, mountType, mountID)
		-- MOUNTS RARITY
		and self:getFilterRarity(rarity or 100)
		-- MOUNTS WEIGHT
		and self:getFilterWeight(spellID)
		-- TAGS
		and tags:getFilterMount(spellID) then
			numMounts = numMounts + 1
			self.dataProvider:Insert({mountID = mountID})
		end
	end

	self:updateScrollMountList()
	self:setShownCountMounts(numMounts)
end
