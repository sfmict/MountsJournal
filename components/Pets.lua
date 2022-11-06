local random, C_PetJournal, UnitBuff, C_Timer, wipe, InCombatLockdown, IsFlying, UnitHasVehicleUI, UnitChannelInfo, IsStealthed, UnitIsGhost, GetSpellCooldown = random, C_PetJournal, UnitBuff, C_Timer, wipe, InCombatLockdown, IsFlying, UnitHasVehicleUI, UnitChannelInfo, IsStealthed, UnitIsGhost, GetSpellCooldown
local mounts, util = MountsJournal, MountsJournalUtil
local pets = CreateFrame("FRAME")
mounts.pets = pets
util.setEventsMixin(pets)


pets.owned = 0
pets.petJournalFiltersBackup = {
	types = {},
	sources = {},
	search = "",
}
pets.list = {}
pets.favoritesList = {}


hooksecurefunc(C_PetJournal, "SetSearchFilter", function(search)
	if not pets.updatingList then
		pets.petJournalFiltersBackup.search = search or ""
	end
end)
hooksecurefunc(C_PetJournal, "ClearSearchFilter", function()
	if not pets.updatingList then
		pets.petJournalFiltersBackup.search = ""
	end
end)
hooksecurefunc(C_PetJournal, "SetFavorite", function(petID, value)
	pets:updateList(true)
end)


pets:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
pets:RegisterEvent("PET_JOURNAL_LIST_UPDATE")


function pets:summon(petID)
	if C_PetJournal.PetIsSummonable(petID) and C_PetJournal.GetSummonedPetGUID() ~= petID then
		C_PetJournal.SummonPetByGUID(petID)
	end
end


function pets:summonRandomPet(isFavorite)
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
	local aurasList = {
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
	}

	local function isAuraApplied()
		for i = 1, 255 do
			local _,_,_,_,_,_,_,_,_, spellID = UnitBuff("player", i)
			if not spellID then return end
			if aurasList[spellID] then return true end
		end
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
			or UnitChannelInfo("player")
			or IsStealthed()
			or UnitIsGhost("player")
			or GetSpellCooldown(61304) ~= 0
			or isAuraApplied()
		then
			self:stopTicker()
			self:UnregisterEvent("PLAYER_STARTED_MOVING")
			self:RegisterEvent("PLAYER_STARTED_MOVING")
		else
			self:UnregisterEvent("PLAYER_STARTED_MOVING")
			self:UnregisterEvent("PLAYER_REGEN_ENABLED")
			self:summonRandomPet(mounts.config.summonPetOnlyFavorites)
			if not self.ticker then self:setSummonEvery() end
		end
	end
	pets.PLAYER_STARTED_MOVING = pets.summonByTimer
	pets.PLAYER_REGEN_ENABLED = pets.summonByTimer
end


function pets:stopTicker()
	if self.ticker and not self.ticker:IsCancelled() then
		self.ticker:Cancel()
		self.ticker = nil
	end
end


function pets:setSummonEvery()
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


function pets:setPetJournalFiltersBackup()
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


function pets:restorePetJournalFilters()
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


function pets:updateList(force)
	local _, owned = C_PetJournal.GetNumPets()
	if self.owned ~= owned or force then
		self.owned = owned

		self.updatingList = true
		self:setPetJournalFiltersBackup()

		local GetPetInfoByPetID = C_PetJournal.GetPetInfoByIndex
		wipe(self.list)
		wipe(self.favoritesList)
		for i = 1, owned do
			local petID, _,_,_,_, favorite = GetPetInfoByPetID(i)
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