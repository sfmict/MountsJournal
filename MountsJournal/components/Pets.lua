local _, ns = ...
local mounts, util = ns.mounts, ns.util
local C_PetJournal, C_Spell, AuraUtil, C_Timer, C_Secrets = C_PetJournal, C_Spell, AuraUtil, C_Timer, C_Secrets
local random, wipe, InCombatLockdown, IsFlying, UnitHasVehicleUI, UnitCastingInfo, UnitChannelInfo, IsStealthed, UnitIsGhost, UnitIsAFK, issecretvalue = random, wipe, InCombatLockdown, IsFlying, UnitHasVehicleUI, UnitCastingInfo, UnitChannelInfo, IsStealthed, UnitIsGhost, UnitIsAFK, issecretvalue
local curRegion = GetCurrentRegion()
local pets = CreateFrame("FRAME")
ns.pets = util.setEventsMixin(pets)


pets.list = {}
pets.favoritesList = {}


hooksecurefunc(C_PetJournal, "SetFavorite", function(petID, value)
	pets:updateList(true)
end)


pets:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
pets:RegisterEvent("PET_JOURNAL_LIST_UPDATE")
pets:RegisterEvent("UI_ERROR_MESSAGE")


function pets:getPetForProfileList(profilePetForMount)
	return profilePetForMount[curRegion]
end


function pets:setPetForProfile(profilePetForMount, spellID, pet)
	local petForMount = profilePetForMount[curRegion]
	if pet then
		if not petForMount then
			petForMount = {}
			profilePetForMount[curRegion] = petForMount
		end
		petForMount[spellID] = pet
	elseif petForMount then
		petForMount[spellID] = nil
		if not next(petForMount) then
			profilePetForMount[curRegion] = nil
		end
	end
end


function pets:getPetForProfile(profilePetForMount, spellID)
	local petForMount = profilePetForMount[curRegion]
	return petForMount and petForMount[spellID]
end


function pets:dismiss()
	if InCombatLockdown() then return end
	local petID = C_PetJournal.GetSummonedPetGUID()
	--if petID then C_PetJournal.DismissSummonedPet(petID) end
	if petID then C_PetJournal.SummonPetByGUID(petID) end
end


function pets:summon(petID)
	if InCombatLockdown() then return end
	if C_PetJournal.PetIsSummonable(petID) and C_PetJournal.GetSummonedPetGUID() ~= petID then
		C_PetJournal.SummonPetByGUID(petID)
	end
end


function pets:summonRandomPet(isFavorite)
	if InCombatLockdown() then return end
	local list = isFavorite and self.favoritesList or self.list
	local num = #list

	if num < 1 then return
	elseif num == 1 then self:summon(list[1])
	else
		local currentPetID = C_PetJournal.GetSummonedPetGUID()
		if currentPetID and isFavorite then
			local _,_,_,_,_,_, favorite = C_PetJournal.GetPetInfoByPetID(currentPetID)
			if not favorite then currentPetID = nil end
		end

		local petID = list[random(currentPetID and num - 1 or num)]
		if petID == currentPetID then petID = list[num] end
		self:summon(petID)
	end
end


do
	local aurasList, aura = {
		[66] = true, -- Invisibility
		[3680] = true, -- Lesser Invisibility
		[11392] = true, -- Invisibility Potion
		[32612] = true, -- Invisibility
		[110960] = true, -- Greater Invisibility
		[168223] = true, -- Phantom Potion
		[175833] = true, -- Commander's Draenic Invisibility Potion and Draenic Invisibility Potion
		[188023] = true, -- Skaggldrynk
		[199483] = true, -- Camouflage
		[216805] = true, -- Potion of Trivial Invisibility
		[250873] = true, -- Demitri's Draught of Deception
		[307195] = true, -- Potion of the Hidden Spirit
		[371125] = true, -- Potion of the Hushed Zephyr 12 sec
		[371133] = true, -- Potion of the Hushed Zephyr 15 sec
		[371134] = true, -- Potion of the Hushed Zephyr 18 sec
		[431424] = true, -- Treading Lightly
		[1236551] = true, -- Shrouded in Void
	}

	local function checkAura(auraData)
		if not issecretvalue(auraData.spellId) and aurasList[auraData.spellId] then
			aura = true
			return true
		end
	end

	local function isAuraApplied()
		if C_Secrets.ShouldAurasBeSecret() then return true end
		aura = nil
		AuraUtil.ForEachAura("player", "HELPFUL", nil, checkAura, true)
		return aura
	end

	function pets:summonByTimer()
		local groupType = util.getGroupType()
		if mounts.config.noPetInRaid and groupType == "raid"
		or mounts.config.noPetInGroup and groupType == "group"
		then return end

		if InCombatLockdown() then
			self:stopTicker()
			self:UnregisterEvent("PLAYER_STARTED_MOVING")
			self:RegisterEvent("PLAYER_REGEN_ENABLED")
		elseif IsFlying()
			or UnitHasVehicleUI("player")
			or UnitCastingInfo("player")
			or UnitChannelInfo("player")
			or IsStealthed()
			or UnitIsGhost("player")
			or C_Spell.GetSpellCooldown(61304).startTime ~= 0
			or isAuraApplied()
		then
			self:stopTicker()
			self:UnregisterEvent("PLAYER_REGEN_ENABLED")
			self:RegisterEvent("PLAYER_STARTED_MOVING")
		else
			self:UnregisterEvent("PLAYER_STARTED_MOVING")
			self:UnregisterEvent("PLAYER_REGEN_ENABLED")
			if UnitIsAFK("player") then util.doEmote("STAND") end
			self:summonRandomPet(mounts.config.summonPetOnlyFavorites)
			if not self.ticker then self:setSummonEvery() end
		end
	end
	pets.PLAYER_STARTED_MOVING = pets.summonByTimer
	pets.PLAYER_REGEN_ENABLED = pets.summonByTimer
end


function pets:UI_ERROR_MESSAGE(errType, message)
	if errType == 56
	and message == SPELL_FAILED_NOT_STANDING
	and self.ticker
	and not self.ticker:IsCancelled()
	then
		self:stopTicker()
		self:RegisterEvent("PLAYER_STARTED_MOVING")
	end
end


function pets:stopTicker()
	if self.ticker and not self.ticker:IsCancelled() then
		self.ticker:Cancel()
		self.ticker = nil
	end
end


function pets:setSummonEvery()
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("PLAYER_STARTED_MOVING")

	if mounts.config.summonPetEvery then
		local timer = 60 * (tonumber(mounts.config.summonPetEveryN) or 1)
		if self.timer == timer and self.ticker then return end
		self.timer = timer
		self:stopTicker()
		self.ticker = C_Timer.NewTicker(timer, function() self:summonByTimer() end)
	else
		self:stopTicker()
	end
end
pets:on("ADDON_INIT", pets.setSummonEvery)


function pets:setPetJournalFiltersBackup()
	local backup = {
		collected = C_PetJournal.IsFilterChecked(LE_PET_JOURNAL_FILTER_COLLECTED),
		notCollected = C_PetJournal.IsFilterChecked(LE_PET_JOURNAL_FILTER_NOT_COLLECTED),
		battlePets = C_PetJournal.IsFilterChecked(LE_PET_JOURNAL_FILTER_TYPE_BATTLE_PETS),
		nonCombatPets = C_PetJournal.IsFilterChecked(LE_PET_JOURNAL_FILTER_TYPE_NON_COMBAT_PETS),
		search = C_PetJournal.GetSearchFilter(),
		types = {},
		sources = {},
	}
	for i = 1, C_PetJournal.GetNumPetTypes() do
		backup.types[i] = C_PetJournal.IsPetTypeChecked(i)
	end
	for i = 1, C_PetJournal.GetNumPetSources() do
		backup.sources[i] = C_PetJournal.IsPetSourceChecked(i)
	end
	self.petJournalFiltersBackup = backup

	C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_COLLECTED, true)
	C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_NOT_COLLECTED, false)
	C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_TYPE_BATTLE_PETS, true)
	C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_TYPE_NON_COMBAT_PETS, true)
	C_PetJournal.SetAllPetTypesChecked(true)
	C_PetJournal.SetAllPetSourcesChecked(true)
	C_PetJournal.ClearSearchFilter()
end


function pets:restorePetJournalFilters()
	local backup = self.petJournalFiltersBackup
	self.petJournalFiltersBackup = nil
	C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_COLLECTED, backup.collected)
	C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_NOT_COLLECTED, backup.notCollected)
	C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_TYPE_BATTLE_PETS, backup.battlePets)
	C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_TYPE_NON_COMBAT_PETS, backup.nonCombatPets)
	for i = 1, C_PetJournal.GetNumPetTypes() do
		C_PetJournal.SetPetTypeFilter(i, backup.types[i])
	end
	for i = 1, C_PetJournal.GetNumPetSources() do
		C_PetJournal.SetPetSourceChecked(i, backup.sources[i])
	end
	C_PetJournal.SetSearchFilter(backup.search)
end


function pets:updateList(force)
	if self.updatingList then return end
	local _, owned = C_PetJournal.GetNumPets()
	if #self.list ~= owned or force then
		self.updatingList = true
		self:setPetJournalFiltersBackup()

		local GetPetInfoByIndex = C_PetJournal.GetPetInfoByIndex
		wipe(self.list)
		wipe(self.favoritesList)
		for i = 1, owned do
			local petID, _,_,_,_, favorite = GetPetInfoByIndex(i)
			if petID then
				self.list[#self.list + 1] = petID
				if favorite then
					self.favoritesList[#self.favoritesList + 1] = petID
				end
			end
		end

		self:restorePetJournalFilters()
		self.updatingList = nil
	end

	self:event("PET_LIST_UPDATE")
end
pets.PET_JOURNAL_LIST_UPDATE = pets.updateList