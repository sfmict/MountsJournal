local _, L = ...


MJSetPetMixin = {}


function MJSetPetMixin:onLoad()
	self.journal = MountsJournalFrame
	self.journal.profilesMenu:on("SET_PROFILE", function() self:refresh() end)
	_,_, self.randomIcon = GetSpellInfo(243819)

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
end


function MJSetPetMixin:refresh()
	if not self.refreshEnabled then return end

	local selectedSpellID = MountJournal.selectedSpellID
	local petID = self.journal.db.petForMount[selectedSpellID]
	self.id = petID

	if not petID then
		self.infoFrame:Hide()
	elseif type(petID) == "number" then
		self.infoFrame.icon:SetTexture(self.randomIcon)
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
			self.journal.db.petForMount[selectedSpellID] = nil
			self.infoFrame:Hide()
			self.id = nil
		end
	end
	self.journal:updateMountsList()
	MountJournal_UpdateMountList()
end


MJCompanionsPanelMixin = {}


function MJCompanionsPanelMixin:onEvent(event, ...)
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

	local petTypesTextures = {
		"Interface/Icons/Icon_PetFamily_Humanoid",
		"Interface/Icons/Icon_PetFamily_Dragon",
		"Interface/Icons/Icon_PetFamily_Flying",
		"Interface/Icons/Icon_PetFamily_Undead",
		"Interface/Icons/Icon_PetFamily_Critter",
		"Interface/Icons/Icon_PetFamily_Magical",
		"Interface/Icons/Icon_PetFamily_Elemental",
		"Interface/Icons/Icon_PetFamily_Beast",
		"Interface/Icons/Icon_PetFamily_Water",
		"Interface/Icons/Icon_PetFamily_Mechanical",
	}
	self.filtersPanel.buttons = {}
	self.typeFilter = {}
	for i, texture in ipairs(petTypesTextures) do
		local btn = CreateFrame("CheckButton", nil, self.filtersPanel, "MJFilterButtonSquareTemplate")
		btn:SetSize(22, 22)
		btn.icon:SetTexture(texture)
		btn.icon:SetSize(20, 20)
		if i == 1 then
			btn:SetPoint("LEFT", 3, 0)
		else
			btn:SetPoint("LEFT", self.filtersPanel.buttons[i - 1], "RIGHT")
		end
		btn:SetScript("OnClick", function()
			self:updateTypeFilter()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		end)
		self.filtersPanel.buttons[i] = btn
		self.typeFilter[i] = true
	end
	self.clearFilters:SetScript("OnClick", function()
		self:ClearTypeFilter()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

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

	self.listScroll.update = function() self:refresh() end
	self.listScroll.scrollBar.doNotHide = true
	HybridScrollFrame_CreateButtons(self.listScroll, "MJPetListButton")

	self:RegisterEvent("PET_JOURNAL_LIST_UPDATE")
end


function MJCompanionsPanelMixin:onShow()
	self:SetScript("OnShow", function(self)
		self:petListSort()
	end)
	C_Timer.After(0, function() self:petListUpdate(true) end)
end


function MJCompanionsPanelMixin:selectButtonClick(id)
	self.journal.db.petForMount[MountJournal.selectedSpellID] = id
	self:GetParent():refresh()
	self:Hide()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end


function MJCompanionsPanelMixin:refresh()
	local scrollFrame = self.listScroll
	local offset = HybridScrollFrame_GetOffset(scrollFrame)
	local numPets = #self.petFiltredList
	local selectedPetID = self.journal.db.petForMount[MountJournal.selectedSpellID]

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
			self:SetScript("OnShow", self.onShow)
			return
		end
	end

	self.owned = owned
	self:setPetJournalFiltersBackup()

	wipe(self.petList)
	for i = 1, owned do
		local petID = C_PetJournal.GetPetInfoByIndex(i)
		if petID then
			tinsert(self.petList, petID)
		end
	end

	self:restorePetJournalFilters()
	self:petListSort()
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

	self:updateFilters()
end


function MJCompanionsPanelMixin:updateFilters()
	local text = self.searchBox:GetText():lower():gsub("[%(%)%.%%%+%-%*%?%[%^%$]", function(char) return "%"..char end)
	local GetPetInfoByPetID = C_PetJournal.GetPetInfoByPetID

	wipe(self.petFiltredList)
	for _, petID in ipairs(self.petList) do
		local _, customName, _,_,_,_,_, name, _, petType = GetPetInfoByPetID(petID)
		if self.typeFilter[petType]
		and (text:len() == 0
			  or (name:lower():find(text)
					or customName and customName:lower():find(text))) then
			tinsert(self.petFiltredList, petID)
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