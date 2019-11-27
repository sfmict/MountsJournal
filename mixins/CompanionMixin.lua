local _, L = ...


MJSetPetMixin = {}


function MJSetPetMixin:onLoad()
	self.journal = MountsJournalFrame
	self.journal.profilesMenu:on("SET_PROFILE", function() self:refresh() end)
	_,_, self.randomIcon = GetSpellInfo(243819)

	hooksecurefunc(C_MountJournal, "SummonByID", function(mountID)
		local petID = self.journal.db.petForMount[mountID]
		if petID then
			if type(petID) == "number" then
				C_PetJournal.SummonRandomPet(petID == -1)
			elseif C_PetJournal.PetIsSummonable(petID) and C_PetJournal.GetSummonedPetGUID() ~= petID then
				C_PetJournal.SummonPetByGUID(petID)
			end
		end
	end)

	self.petSelectionList = CreateFrame("FRAME", nil, self, "MJCompanionsPanel")
end


function MJSetPetMixin:onShow()
	C_Timer.After(0, function()
		self.refreshEnabled = true
		self:refresh()
	end)
end


function MJSetPetMixin:onClick()
	self.petSelectionList:SetShown(not self.petSelectionList:IsShown())
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	-- PlaySound(SOUNDKIT.UI_TOYBOX_TABS)
end


function MJSetPetMixin:refresh()
	if not self.refreshEnabled then return end

	local selectedMountID = MountJournal.selectedMountID
	local petID = self.journal.db.petForMount[selectedMountID]
	fprint("set button refresh", petID)

	if not petID then
		self.infoFrame:Hide()
	elseif type(petID) == "number" then
		self.infoFrame.icon:SetTexture(self.randomIcon)
		self.infoFrame.qualityBorder:Hide()
		self.infoFrame.isDead:Hide()
		self.infoFrame.levelBG:Hide()
		self.infoFrame.level:Hide()
		self.infoFrame.favorite:SetShown(petID == -1)
		self.infoFrame:Show()
	else
		local speciesID, customName, level, xp, maxXp, displayID, favorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, tradable, unique, obtainable = C_PetJournal.GetPetInfoByPetID(petID)

		fprint("icon", icon, C_PetJournal.PetIsSummonable(petID))
		if icon then
			local health, _,_,_, rarity = C_PetJournal.GetPetStats(petID)

			self.infoFrame.icon:SetTexture(icon)
			self.infoFrame.qualityBorder:Show()
			self.infoFrame.qualityBorder:SetVertexColor(ITEM_QUALITY_COLORS[rarity-1].color:GetRGB())
			self.infoFrame.isDead:SetShown(health <= 0)
			self.infoFrame.levelBG:SetShown(canBattle)
			self.infoFrame.level:SetShown(canBattle)
			self.infoFrame.level:SetText(level)
			self.infoFrame.favorite:SetShown(favorite)
			self.infoFrame:Show()
		else
			self.journal.db.petForMount[selectedMountID] = nil
			self.infoFrame:Hide()
		end
	end
end


MJCompanionsPanelMixin = {}


function MJCompanionsPanelMixin:onEvent(event, ...)
	fprint(event)
	if self[event] then
		self[event](self, ...)
	end
end


function MJCompanionsPanelMixin:onLoad()
	self.journal = MountsJournalFrame
	self.journal.profilesMenu:on("SET_PROFILE", function() self:refresh() end)

	self:SetWidth(250)
	self:SetPoint("TOPLEFT", MountJournal, "TOPRIGHT")
	self:SetPoint("BOTTOMLEFT", MountJournal, "BOTTOMRIGHT")

	local _,_, spellIcon = GetSpellInfo(243819)
	self.randomFavoritePet.infoFrame.favorite:Show()
	self.randomFavoritePet.infoFrame.icon:SetTexture(spellIcon)
	self.randomFavoritePet.infoFrame.qualityBorder:Hide()
	self.randomFavoritePet.name:SetWidth(180)
	self.randomFavoritePet.name:SetText(PET_JOURNAL_SUMMON_RANDOM_FAVORITE_PET)
	self.randomPet.infoFrame.icon:SetTexture(spellIcon)
	self.randomPet.infoFrame.qualityBorder:Hide()
	self.randomPet.name:SetWidth(180)
	self.randomPet.name:SetText(L["Summon Random Battle Pet"])
	self.noPet.infoFrame.icon:SetTexture("Interface/PaperDoll/UI-Backpack-EmptySlot")
	self.noPet.infoFrame.qualityBorder:Hide()
	self.noPet.name:SetWidth(180)
	self.noPet.name:SetText(L["No Battle Pet"])

	self.petJournalFiltersBackup = {
		types = {},
		sources = {},
	}
	self.petList = {}
	self.petFiltredList = {}

	self.searchBox:SetScript("OnTextChanged", function(searchBox)
		SearchBoxTemplate_OnTextChanged(searchBox)
		self:updateFilters()
	end)
	self.searchBox:SetScript("OnHide", function(self) self:SetText("") end)

	self.listScroll.update = function() self:refresh() end
	self.listScroll.scrollBar.doNotHide = true
	HybridScrollFrame_CreateButtons(self.listScroll, "MJPetListButton")

	self:RegisterEvent("PET_JOURNAL_LIST_UPDATE")
end


function MJCompanionsPanelMixin:onShow()
	self:SetScript("OnShow", function(self)
		self:petListSort()
		self:updateFilters()
	end)
	C_Timer.After(0, function() self:petListUpdate(true) end)
end


function MJCompanionsPanelMixin:selectButtonClick(id)
	self.journal.db.petForMount[MountJournal.selectedMountID] = id
	self:GetParent():refresh()
	self:Hide()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end


function MJCompanionsPanelMixin:refresh()
	local scrollFrame = self.listScroll
	local offset = HybridScrollFrame_GetOffset(scrollFrame)
	local numPets = #self.petFiltredList
	local selectedPetID = self.journal.db.petForMount[MountJournal.selectedMountID]

	fprint(#scrollFrame.buttons, numPets)
	for i, btn in ipairs(scrollFrame.buttons) do
		local index = i + offset
		
		if index <= numPets then
			local petID = self.petFiltredList[index]
			-- speciesID, customName, level, xp, maxXp, displayID, favorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, tradable, unique, obtainable = C_PetJournal.GetPetInfoByPetID(petID)
			local speciesID, customName, level, xp, maxXp, displayID, favorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, tradable, unique, obtainable = C_PetJournal.GetPetInfoByPetID(petID)
			local health, _,_,_, rarity = C_PetJournal.GetPetStats(petID)
			local petQualityColor = ITEM_QUALITY_COLORS[rarity - 1].color

			btn.id = petID
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

			btn:Show()
		else
			btn:Hide()
		end
	end

	HybridScrollFrame_Update(scrollFrame, numPets * 41, scrollFrame:GetHeight())
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
	C_PetJournal.SetSearchFilter(PetJournalSearchBox:GetText())
end


function MJCompanionsPanelMixin:petListUpdate(force)
	local _, owned = C_PetJournal.GetNumPets()

	if not force then
		if self.owned == owned then return end
		if not self:IsVisible() then
			fprint("not IsVisible")
			self:SetScript("OnShow", self.onShow)
			return
		end
	end

	self.owned = owned
	self:setPetJournalFiltersBackup()

	wipe(self.petList)
	for j = 1, 1 do
		for i = 1, owned do
			local petID = C_PetJournal.GetPetInfoByIndex(i)
			if petID then
				tinsert(self.petList, petID)
			end
		end
	end

	self:restorePetJournalFilters()
	fprint("petListUpdate", force)
	self:petListSort()
	self:updateFilters()
end
MJCompanionsPanelMixin.PET_JOURNAL_LIST_UPDATE = MJCompanionsPanelMixin.petListUpdate


function MJCompanionsPanelMixin:petListSort()
	local C_PetJournal = C_PetJournal
	sort(self.petList, function(p1, p2)
		local _,_, level1, _,_,_, favorite1, name1 = C_PetJournal.GetPetInfoByPetID(p1)
		local _,_, level2, _,_,_, favorite2, name2 = C_PetJournal.GetPetInfoByPetID(p2)

		if favorite1 and not favorite2
		or favorite1 == favorite2 and (level1 > level2
			or level1 == level2 and name1 < name2)
		then return true end
	end)
end


function MJCompanionsPanelMixin:updateFilters()
	local text = self.searchBox:GetText()

	wipe(self.petFiltredList)
	if text:len() > 0 then
		local C_PetJournal = C_PetJournal
		text = text:lower():gsub("[%(%)%.%%%+%-%*%?%[%^%$]", function(char) return "%"..char end)
		for _, petID in ipairs(self.petList) do
			local _, customName, _,_,_,_,_, name = C_PetJournal.GetPetInfoByPetID(petID)
			if name:lower():find(text) or customName and customName:lower():find(text) then
				tinsert(self.petFiltredList, petID)
			end
		end
	else
		for k, v in ipairs(self.petList) do
			self.petFiltredList[k] = v
		end
	end

	self:refresh()
end