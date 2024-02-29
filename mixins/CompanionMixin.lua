local addon, L = ...
local util = MountsJournalUtil
local petRandomIcon = "Interface/Icons/INV_Pet_Achievement_CaptureAPetFromEachFamily_Battle" -- select(3, GetSpellInfo(243819))


MJSetPetMixin = util.createFromEventsMixin()


function MJSetPetMixin:onLoad()
	self.mounts = MountsJournal
	self.journal = MountsJournalFrame

	self:SetScript("OnEnter", function(self)
		self.highlight:Show()
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["Summonable Battle Pet"])
		local description
		if self.id then
			if type(self.id) == "number" then
				description = self.id == 1 and PET_JOURNAL_SUMMON_RANDOM_FAVORITE_PET or L["Summon Random Battle Pet"]
			else
				description = self.name
				MJTooltipModel.model:SetDisplayInfo(self.displayID)
				MJTooltipModel.model:SetDoBlend(false)
				MJTooltipModel.model:SetAnimation(742, 0)
				MJTooltipModel:Show()
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
		MJTooltipModel:Hide()
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
		local _,_, level, _,_, displayID, favorite, name, icon, _,_,_,_,_, canBattle = C_PetJournal.GetPetInfoByPetID(petID)

		if icon then
			local health, _,_,_, rarity = C_PetJournal.GetPetStats(petID)

			self.name = name
			self.displayID = displayID
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

	self.petList = MountsJournal.pets.list

	self.searchBox:SetScript("OnTextChanged", function(searchBox)
		SearchBoxTemplate_OnTextChanged(searchBox)
		self:updateFilters()
	end)

	self.view = CreateScrollBoxListLinearView()
	self.view:SetElementInitializer("MJPetListButton", function(...)
		self:initButton(...)
	end)
	self.scrollBox = self.petListFrame.scrollBox
	ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.petListFrame.scrollBar, self.view)

	self.companionOptionsMenu = LibStub("LibSFDropDown-1.4"):SetMixin({})
	self.companionOptionsMenu:ddHideWhenButtonHidden(self)
	self.companionOptionsMenu:ddSetInitFunc(function(...) self:companionOptionsMenu_Init(...) end)
	self.companionOptionsMenu:ddSetDisplayMode(addon)

	self.scrollBox:RegisterCallback("OnDataRangeChanged", function()
		self.companionOptionsMenu:ddOnHide()
	end)

	self:on("MOUNT_SELECT", self.Hide)
end


function MJCompanionsPanelMixin:onShow()
	self:SetScript("OnShow", nil)
	C_Timer.After(0, function()
		self:SetScript("OnShow", function(self)
			if self.needSort then
				self:petListSort()
			else
				self:updateScrollPetList()
			end
			self:scrollToSelectedPet()
			self:on("UPDATE_PROFILE", self.updateScrollPetList)
		end)
		self:petListUpdate(true)
		self:scrollToSelectedPet()
		self:on("UPDATE_PROFILE", self.updateScrollPetList)
		self:on("PET_LIST_UPDATE", self.petListUpdate)
	end)
end


function MJCompanionsPanelMixin:onHide()
	self:off("UPDATE_PROFILE", self.updateScrollPetList)
	self:Hide()
end


function MJCompanionsPanelMixin:showCompanionOptionsMenu(btn)
	if not btn.id or type(btn.id) == "number" then
		self.companionOptionsMenu:ddCloseMenus()
	else
		self.companionOptionsMenu:ddToggle(1, btn.id, btn, 37, 0)
	end
end


function MJCompanionsPanelMixin:companionOptionsMenu_Init(btn, level, petID)
	local speciesID ,_,_,_,_,_, isFavorite = C_PetJournal.GetPetInfoByPetID(petID)
	local isRevoked = C_PetJournal.PetIsRevoked(petID)
	local isLockedForConvert = C_PetJournal.PetIsLockedForConvert(petID)
	local info = {}
	info.notCheckable = true

	if not (isRevoked or isLockedForConvert) then
		info.disabled = not C_PetJournal.PetIsSummonable(petID)
		if petID == C_PetJournal.GetSummonedPetGUID() then
			info.text = PET_DISMISS
		else
			info.text = BATTLE_PET_SUMMON
		end
		info.func = function() C_PetJournal.SummonPetByGUID(petID) end
		btn:ddAddButton(info, level)

		info.disabled = nil

		if isFavorite then
			info.text = BATTLE_PET_UNFAVORITE
			info.func = function()
				C_PetJournal.SetFavorite(petID, 0)
				self:GetParent():refresh()
			end
		else
			info.text = BATTLE_PET_FAVORITE
			info.func = function()
				C_PetJournal.SetFavorite(petID, 1)
				self:GetParent():refresh()
			end
		end
		btn:ddAddButton(info, level)
	end

	info.func = nil
	info.text = CANCEL
	btn:ddAddButton(info, level)
end


function MJCompanionsPanelMixin:scrollToSelectedPet()
	local selectedPetID = self.journal.petForMount[self.journal.selectedSpellID]
	self.scrollBox:ScrollToElementDataByPredicate(function(data)
		return data.petID == selectedPetID
	end)
end


function MJCompanionsPanelMixin:selectButtonClick(id)
	self.journal.petForMount[self.journal.selectedSpellID] = id
	self.journal:updateMountsList()
	self:GetParent():refresh()
	self:Hide()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end


function MJCompanionsPanelMixin:initButton(btn, data)
	local selectedPetID = self.journal.petForMount[self.journal.selectedSpellID]
	local _, customName, level, _,_, displayID, favorite, name, icon, petType, _,_,_,_, canBattle = C_PetJournal.GetPetInfoByPetID(data.petID)
	local health, _,_,_, rarity = C_PetJournal.GetPetStats(data.petID)
	local petQualityColor = ITEM_QUALITY_COLORS[rarity - 1].color

	btn.id = data.petID
	btn.displayID = displayID
	btn.petTypeIcon:SetTexture(GetPetTypeTexture(petType))
	btn.name:SetTextColor(petQualityColor:GetRGB())
	btn.selectedTexture:SetShown(data.petID == selectedPetID)

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
end


function MJCompanionsPanelMixin:petListUpdate()
	self.needSort = true
	if self:IsVisible() then
		self:petListSort()
	end
end


function MJCompanionsPanelMixin:petListSort()
	local GetPetInfoByPetID, GetPetStats = C_PetJournal.GetPetInfoByPetID, C_PetJournal.GetPetStats
	sort(self.petList, function(p1, p2)
		if p1 == p2 then return false end
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


function MJCompanionsPanelMixin:updateScrollPetList()
	self.scrollBox:SetDataProvider(self.dataProvider, ScrollBoxConstants.RetainScrollPosition)
end


function MJCompanionsPanelMixin:updateFilters()
	local text = self.util.cleanText(self.searchBox:GetText())
	local GetPetInfoByPetID = C_PetJournal.GetPetInfoByPetID
	local numPets = 0
	self.dataProvider = CreateDataProvider()

	for i = 1, #self.petList do
		local petID = self.petList[i]
		local _, customName, _,_,_,_,_, name, _, petType, _, sourceText = GetPetInfoByPetID(petID)
		if self.typeFilter[petType]
		and (#text == 0
			or name:lower():find(text, 1, true)
			or sourceText:lower():find(text, 1, true)
			or customName and customName:lower():find(text, 1, true)) then
			numPets = numPets + 1
			self.dataProvider:Insert({index = numPets, petID = petID})
		end
	end

	self:updateScrollPetList()
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