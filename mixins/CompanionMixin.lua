local _, L = ...
local util = MountsJournalUtil
local petRandomIcon = "Interface/Icons/INV_Pet_Achievement_CaptureAPetFromEachFamily_Battle" -- select(3, GetSpellInfo(243819))


MJSetPetMixin = util.createFromEventsMixin()


function MJSetPetMixin:onLoad()
	self.mounts = MountsJournal
	self.journal = MountsJournalFrame

	self:SetScript("OnEnter", function(self)
		self.highlight:Show()
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:SetText(L["Summonable Battle Pet"])
		local description
		if self.id then
			if type(self.id) == "number" then
				description = self.id == 1 and PET_JOURNAL_SUMMON_RANDOM_FAVORITE_PET or L["Summon Random Battle Pet"]
			else
				description = self.name
			end
		else
			description = L["No Battle Pet"]
		end
		GameTooltip:AddLine(description, 1, 1, 1)
		GameTooltip:Show()
	end)
	self:SetScript("OnLeave", function(self)
		self.highlight:Hide()
		GameTooltip:Hide()
	end)
end


function MJSetPetMixin:onEvent(event, ...) self[event](self, ...) end


function MJSetPetMixin:onShow()
	self:SetScript("OnShow", nil)
	C_Timer.After(0, function()
		self:SetScript("OnShow", self.refresh)
		self:updatePetForMount()
		self:refresh()
		self:on("MOUNT_SELECT", self.refresh)
		self:on("UPDATE_PROFILE", self.refresh)
		self:RegisterEvent("PET_JOURNAL_LIST_UPDATE")
	end)
end


function MJSetPetMixin:onClick()
	if not self.petSelectionList then
		self.petSelectionList = CreateFrame("FRAME", nil, self, "MJCompanionsPanel")
	end
	self.petSelectionList:SetShown(not self.petSelectionList:IsShown())
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end


function MJSetPetMixin:refresh()
	local spellID = self.journal.selectedSpellID
	local petID = self.journal.petForMount[spellID]
	self.id = petID

	if not petID then
		self.infoFrame:Hide()
	elseif type(petID) == "number" then
		self.infoFrame.icon:SetTexture(petRandomIcon)
		self.infoFrame.qualityBorder:Hide()
		self.infoFrame.isDead:Hide()
		self.infoFrame.levelBG:Hide()
		self.infoFrame.level:Hide()
		self.infoFrame.favorite:SetShown(petID == 1)
		self.infoFrame:Show()
	else
		-- speciesID, customName, level, xp, maxXp, displayID, favorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, tradable, unique, obtainable = C_PetJournal.GetPetInfoByPetID(petID)
		local _,_, level, _,_,_, favorite, name, icon, _,_,_,_,_, canBattle = C_PetJournal.GetPetInfoByPetID(petID)

		if icon then
			local health, _,_,_, rarity = C_PetJournal.GetPetStats(petID)

			self.name = name
			self.infoFrame.icon:SetTexture(icon)
			self.infoFrame.qualityBorder:Show()
			self.infoFrame.qualityBorder:SetVertexColor(ITEM_QUALITY_COLORS[rarity - 1].color:GetRGB())
			self.infoFrame.isDead:SetShown(health <= 0)
			self.infoFrame.levelBG:SetShown(canBattle)
			self.infoFrame.level:SetShown(canBattle)
			self.infoFrame.level:SetText(level)
			self.infoFrame.favorite:SetShown(favorite)
			self.infoFrame:Show()
		else
			self.journal.petForMount[spellID] = nil
			self.infoFrame:Hide()
			self.id = nil
		end
	end
end


function MJSetPetMixin:updatePetForMount()
	local _, owned = C_PetJournal.GetNumPets()
	if not self.owned or self.owned > owned then
		local petForMount, needUpdate = self.mounts.defProfile.petForMount

		for spellID, petID in pairs(petForMount) do
			if type(petID) == "string" and not C_PetJournal.GetPetInfoByPetID(petID) then
				needUpdate = true
				petForMount[spellID] = nil
			end
		end
		for _, profile in pairs(self.mounts.profiles) do
			for spellID, petID in pairs(profile.petForMount) do
				if type(petID) == "string" and not C_PetJournal.GetPetInfoByPetID(petID) then
					needUpdate = true
					profile.petForMount[spellID] = nil
				end
			end
		end

		if needUpdate then
			self.journal:updateMountsList()
		end
	end
	self.owned = owned
end
MJSetPetMixin.PET_JOURNAL_LIST_UPDATE = MJSetPetMixin.updatePetForMount


MJCompanionsPanelMixin = util.createFromEventsMixin()


function MJCompanionsPanelMixin:onEvent(event, ...) self[event](self, ...) end


function MJCompanionsPanelMixin:onLoad()
	self.util = MountsJournalUtil
	self.journal = MountsJournalFrame

	self:SetWidth(250)
	self:SetPoint("TOPLEFT", self.journal.bgFrame, "TOPRIGHT")
	self:SetPoint("BOTTOMLEFT", self.journal.bgFrame, "BOTTOMRIGHT")

	self.filtersPanel.buttons = {}
	self.typeFilter = {}

	local typeFilterClick = function()
		self:updateTypeFilter()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end

	for i = 1, C_PetJournal.GetNumPetTypes() do
		local btn = CreateFrame("CheckButton", nil, self.filtersPanel, "MJFilterButtonSquareTemplate")
		btn:SetSize(22, 22)
		btn.icon:SetTexture("Interface/Icons/Icon_PetFamily_"..PET_TYPE_SUFFIX[i])
		btn.icon:SetSize(20, 20)
		if i == 1 then
			btn:SetPoint("LEFT", 3, 0)
		else
			btn:SetPoint("LEFT", self.filtersPanel.buttons[i - 1], "RIGHT")
		end
		btn:SetScript("OnClick", typeFilterClick)
		self.filtersPanel.buttons[i] = btn
		self.typeFilter[i] = true
	end
	self.clearFilters:SetScript("OnClick", function()
		self:ClearTypeFilter()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	self.randomFavoritePet.infoFrame.favorite:Show()
	self.randomFavoritePet.infoFrame.icon:SetTexture(petRandomIcon)
	self.randomFavoritePet.infoFrame.qualityBorder:Hide()
	self.randomFavoritePet.name:SetWidth(180)
	self.randomFavoritePet.name:SetText(PET_JOURNAL_SUMMON_RANDOM_FAVORITE_PET)
	self.randomPet.infoFrame.icon:SetTexture(petRandomIcon)
	self.randomPet.infoFrame.qualityBorder:Hide()
	self.randomPet.name:SetWidth(180)
	self.randomPet.name:SetText(L["Summon Random Battle Pet"])
	self.noPet.infoFrame.icon:SetTexture("Interface/PaperDoll/UI-Backpack-EmptySlot")
	self.noPet.infoFrame.qualityBorder:Hide()
	self.noPet.name:SetWidth(180)
	self.noPet.name:SetText(L["No Battle Pet"])

	self.owned = 0
	self.petJournalFiltersBackup = {
		types = {},
		sources = {},
		search = "",
	}
	self.petList = {}
	self.petFiltredList = {}

	hooksecurefunc(C_PetJournal, "SetSearchFilter", function(search)
		if not self.updatingList then
			self.petJournalFiltersBackup.search = search or ""
		end
	end)
	hooksecurefunc(C_PetJournal, "ClearSearchFilter", function()
		if not self.updatingList then
			self.petJournalFiltersBackup.search = ""
		end
	end)

	self.searchBox:SetScript("OnTextChanged", function(searchBox)
		SearchBoxTemplate_OnTextChanged(searchBox)
		self:updateFilters()
	end)

	self.listScroll.update = function() self:refresh() end
	self.listScroll.scrollBar.doNotHide = true
	HybridScrollFrame_CreateButtons(self.listScroll, "MJPetListButton")

	self:on("MOUNT_SELECT", self.Hide)
	self:RegisterEvent("PET_JOURNAL_LIST_UPDATE")
end


function MJCompanionsPanelMixin:onShow()
	self:SetScript("OnShow", nil)
	C_Timer.After(0, function()
		self:SetScript("OnShow", function(self)
			if self.force then
				self:petListUpdate(self.force)
			elseif self.needSort then
				self:petListSort()
			else
				self:refresh()
			end
			self:on("UPDATE_PROFILE", self.refresh)
		end)
		self:petListUpdate(true)
		self:on("UPDATE_PROFILE", self.refresh)
	end)
end


function MJCompanionsPanelMixin:onHide()
	self:off("UPDATE_PROFILE", self.refresh)
	self:Hide()
end


function MJCompanionsPanelMixin:selectButtonClick(id)
	self.journal.petForMount[self.journal.selectedSpellID] = id
	self.journal:updateMountsList()
	self:GetParent():refresh()
	self:Hide()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end


function MJCompanionsPanelMixin:refresh()
	local scrollFrame = self.listScroll
	local offset = HybridScrollFrame_GetOffset(scrollFrame)
	local numPets = #self.petFiltredList
	local selectedPetID = self.journal.petForMount[self.journal.selectedSpellID]

	for i, btn in ipairs(scrollFrame.buttons) do
		local index = i + offset

		if index <= numPets then
			local petID = self.petFiltredList[index]
			local _, customName, level, _,_, displayID, favorite, name, icon, petType, _,_,_,_, canBattle = C_PetJournal.GetPetInfoByPetID(petID)
			local health, _,_,_, rarity = C_PetJournal.GetPetStats(petID)
			local petQualityColor = ITEM_QUALITY_COLORS[rarity - 1].color

			btn.id = petID
			btn.displayID = displayID
			btn.petTypeIcon:SetTexture(GetPetTypeTexture(petType))
			btn.name:SetTextColor(petQualityColor:GetRGB())
			btn.selectedTexture:SetShown(petID == selectedPetID)

			if customName then
				btn.name:SetText(customName)
				btn.name:SetHeight(12)
				btn.subName:Show()
				btn.subName:SetText(name)
			else
				btn.name:SetText(name)
				btn.name:SetHeight(25)
				btn.subName:Hide()
			end

			btn.infoFrame.icon:SetTexture(icon)
			btn.infoFrame.qualityBorder:SetVertexColor(petQualityColor:GetRGB())
			btn.infoFrame.isDead:SetShown(health <= 0)
			btn.infoFrame.levelBG:SetShown(canBattle)
			btn.infoFrame.level:SetShown(canBattle)
			btn.infoFrame.level:SetText(level)
			btn.infoFrame.favorite:SetShown(favorite)

			if btn.showingTooltip then
				btn:GetScript("OnEnter")(btn)
			end

			btn:Show()
		else
			btn:Hide()
		end
	end

	HybridScrollFrame_Update(scrollFrame, scrollFrame.buttonHeight * numPets, scrollFrame:GetHeight())
end


function MJCompanionsPanelMixin:setPetJournalFiltersBackup()
	local backup = self.petJournalFiltersBackup
	backup.collected = C_PetJournal.IsFilterChecked(LE_PET_JOURNAL_FILTER_COLLECTED)
	backup.notCollected = C_PetJournal.IsFilterChecked(LE_PET_JOURNAL_FILTER_NOT_COLLECTED)
	for i = 1, C_PetJournal.GetNumPetTypes() do
		backup.types[i] = C_PetJournal.IsPetTypeChecked(i)
	end
	for i = 1, C_PetJournal.GetNumPetSources() do
		backup.sources[i] = C_PetJournal.IsPetSourceChecked(i)
	end
	C_PetJournal.ClearSearchFilter()
	C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_COLLECTED, true)
	C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_NOT_COLLECTED, true)
	C_PetJournal.SetAllPetTypesChecked(true)
	C_PetJournal.SetAllPetSourcesChecked(true)
end


function MJCompanionsPanelMixin:restorePetJournalFilters()
	local backup = self.petJournalFiltersBackup
	C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_COLLECTED, backup.collected)
	C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_NOT_COLLECTED, backup.notCollected)
	for i = 1, C_PetJournal.GetNumPetTypes() do
		C_PetJournal.SetPetTypeFilter(i, backup.types[i])
	end
	for i = 1, C_PetJournal.GetNumPetSources() do
		C_PetJournal.SetPetSourceChecked(i, backup.sources[i])
	end
	C_PetJournal.SetSearchFilter(backup.search)
end


function MJCompanionsPanelMixin:petListUpdate(force)
	self.needSort = true
	local _, owned = C_PetJournal.GetNumPets()

	if not force then
		if self.owned == owned then return end
		self.owned = owned
		if not self:IsVisible() then
			self.force = true
			return
		end
	else
		self.owned = owned
		self.force = nil
	end

	self.updatingList = true
	self:setPetJournalFiltersBackup()

	local GetPetInfoByIndex = C_PetJournal.GetPetInfoByIndex
	wipe(self.petList)
	for i = 1, owned do
		local petID = GetPetInfoByIndex(i)
		if petID then
			self.petList[#self.petList + 1] = petID
		end
	end

	self:restorePetJournalFilters()
	self.updatingList = nil
	self:petListSort()
end
MJCompanionsPanelMixin.PET_JOURNAL_LIST_UPDATE = MJCompanionsPanelMixin.petListUpdate


function MJCompanionsPanelMixin:petListSort()
	local GetPetInfoByPetID, GetPetStats = C_PetJournal.GetPetInfoByPetID, C_PetJournal.GetPetStats
	sort(self.petList, function(p1, p2)
		local _,_, level1, _,_,_, favorite1, name1 = GetPetInfoByPetID(p1)
		local _,_, level2, _,_,_, favorite2, name2 = GetPetInfoByPetID(p2)

		if favorite1 and not favorite2 then return true
		elseif not favorite1 and favorite2 then return false end

		if level1 > level2 then return true
		elseif level1 < level2 then return false end

		if name1 < name2 then return true
		elseif name1 > name2 then return false end

		local _,_,_,_, rarity1 = GetPetStats(p1)
		local _,_,_,_, rarity2 = GetPetStats(p2)

		if rarity1 > rarity2 then return true
		elseif rarity1 < rarity2 then return false end

		return p1 < p2
	end)

	self.needSort = false
	self:updateFilters()
end


function MJCompanionsPanelMixin:updateFilters()
	local text = self.util.cleanText(self.searchBox:GetText())
	local GetPetInfoByPetID = C_PetJournal.GetPetInfoByPetID

	wipe(self.petFiltredList)
	for i = 1, #self.petList do
		local petID = self.petList[i]
		local _, customName, _,_,_,_,_, name, _, petType, _, sourceText = GetPetInfoByPetID(petID)
		if self.typeFilter[petType]
		and (#text == 0
			or name:lower():find(text, 1, true)
			or sourceText:lower():find(text, 1, true)
			or customName and customName:lower():find(text, 1, true)) then
			self.petFiltredList[#self.petFiltredList + 1] = petID
		end
	end

	self:refresh()
end


function MJCompanionsPanelMixin:ClearTypeFilter()
	for _, btn in ipairs(self.filtersPanel.buttons) do
		btn:SetChecked(false)
	end
	self:updateTypeFilter()
end


function MJCompanionsPanelMixin:updateTypeFilter()
	local buttons = self.filtersPanel.buttons
	local check, uncheck, btnCount = 0, 0, #buttons

	for i, btn in ipairs(buttons) do
		local checked = btn:GetChecked()
		self.typeFilter[i] = checked
		btn.icon:SetDesaturated(not checked)
		if checked then
			check = check + 1
		else
			uncheck = uncheck + 1
		end
	end

	if check == btnCount or uncheck == btnCount then
		for i, btn in ipairs(buttons) do
			btn:SetChecked(false)
			self.typeFilter[i] = true
			btn.icon:SetDesaturated()
		end
		self.clearFilters:Hide()
	else
		self.clearFilters:Show()
	end

	self:updateFilters()
end