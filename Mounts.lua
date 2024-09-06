local addon, ns = ...
local L, util = ns.L, ns.util
local C_MountJournal, C_Map, C_Spell, MapUtil, next, wipe, random, IsPlayerSpell, GetTime, IsFlyableArea, IsSubmerged, GetInstanceInfo, IsIndoors, UnitInVehicle, IsMounted, InCombatLockdown, GetSpellCooldown, SecureCmdOptionParse, C_Scenario, BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS, C_Container = C_MountJournal, C_Map, C_Spell, MapUtil, next, wipe, random, IsPlayerSpell, GetTime, IsFlyableArea, IsSubmerged, GetInstanceInfo, IsIndoors, UnitInVehicle, IsMounted, InCombatLockdown, GetSpellCooldown, SecureCmdOptionParse, C_Scenario, BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS, C_Container
local mounts = CreateFrame("Frame", "MountsJournal")
ns.mounts = mounts
util.setEventsMixin(mounts)


mounts:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
mounts:RegisterEvent("ADDON_LOADED")
mounts:RegisterEvent("PLAYER_LOGIN")
mounts:RegisterEvent("UPDATE_INVENTORY_DURABILITY")


function mounts:ADDON_LOADED(addonName)
	if addonName == addon then
		self:UnregisterEvent("ADDON_LOADED")
		self.ADDON_LOADED = nil

		local mapInfo = MapUtil.GetMapParentInfo(C_Map.GetFallbackWorldMapID(), Enum.UIMapType.Cosmic, true)
		self.defMountsListID = mapInfo and mapInfo.mapID or 946 -- WORLD

		MountsJournalDB = MountsJournalDB or {}
		self.globalDB = MountsJournalDB
		self.globalDB.mountTags = self.globalDB.mountTags or {}
		self.globalDB.additionalFavorites = self.globalDB.additionalFavorites or {}
		self.globalDB.filters = self.globalDB.filters or {}
		self.globalDB.defFilters = self.globalDB.defFilters or {}
		self.globalDB.config = self.globalDB.config or {}
		self.globalDB.summonPanelConfig = self.globalDB.summonPanelConfig or {}
		self.globalDB.mountAnimations = self.globalDB.mountAnimations or {}
		self.globalDB.defProfile = self.globalDB.defProfile or {}
		self.globalDB.mountsProfiles = self.globalDB.mountsProfiles or {}
		self.globalDB.holidayNames = self.globalDB.holidayNames or {}
		self.globalDB.help = self.globalDB.help or {}
		self.globalDB.ruleSets = self.globalDB.ruleSets or {
			{name = DEFAULT, isDefault = true}
		}
		for i = 1, #self.globalDB.ruleSets do
			self:checkRuleSet(self.globalDB.ruleSets[i])
		end

		self.defProfile = self.globalDB.defProfile
		self:checkProfile(self.defProfile)
		self.profiles = self.globalDB.mountsProfiles
		for name, profile in next, self.profiles do
			self:checkProfile(profile)
		end
		self.additionalFavorites = self.globalDB.additionalFavorites
		self.filters = self.globalDB.filters
		self.defFilters = self.globalDB.defFilters
		self.help = self.globalDB.help
		self.config = self.globalDB.config
		self.config.wowheadLinkLang = self.config.wowheadLinkLang or "en"
		if self.config.mountDescriptionToggle == nil then
			self.config.mountDescriptionToggle = true
		end
		if self.config.coloredMountNames == nil then
			self.config.coloredMountNames = true
		end
		if self.config.arrowButtonsBrowse == nil then
			self.config.arrowButtonsBrowse = true
		end
		if self.config.openHyperlinks == nil then
			self.config.openHyperlinks = true
		end
		if self.config.showWowheadLink == nil then
			self.config.showWowheadLink = true
		end
		self.config.useRepairMountsDurability = self.config.useRepairMountsDurability or 41
		self.config.useRepairFlyableDurability = self.config.useRepairFlyableDurability or 31
		self.config.useRepairFreeSlotsNum = self.config.useRepairFreeSlotsNum or 1
		self.config.summonPetEveryN = self.config.summonPetEveryN or 5
		self.config.macrosConfig = self.config.macrosConfig or {}
		for i = 1, GetNumClasses() do
			local _, className = GetClassInfo(i)
			self.config.macrosConfig[className] = self.config.macrosConfig[className] or {}
		end
		self.config.camera = self.config.camera or {}
		self.cameraConfig = self.config.camera
		if self.cameraConfig.xAccelerationEnabled == nil then
			self.cameraConfig.xAccelerationEnabled = true
		end
		self.cameraConfig.xInitialAcceleration = self.cameraConfig.xInitialAcceleration or .5
		self.cameraConfig.xAcceleration = self.cameraConfig.xAcceleration or -1
		self.cameraConfig.xMinAcceleration = nil
		self.cameraConfig.xMinSpeed = self.cameraConfig.xMinSpeed or 0
		if self.cameraConfig.yAccelerationEnabled == nil then
			self.cameraConfig.yAccelerationEnabled = true
		end
		self.cameraConfig.yInitialAcceleration = self.cameraConfig.yInitialAcceleration or .5
		self.cameraConfig.yAcceleration = self.cameraConfig.yAcceleration or -1
		self.cameraConfig.yMinAcceleration = nil
		self.cameraConfig.yMinSpeed = self.cameraConfig.yMinSpeed or 0

		MountsJournalChar = MountsJournalChar or {}
		self.charDB = MountsJournalChar
		self.charDB.macrosConfig = self.charDB.macrosConfig or {}

		-- Списки
		self.swimmingVashjir = {
			[75207] = true, -- Вайш'ирский морской конек
		}
		self.lowLevel = {
			[179244] = true, -- Механоцикл с шофером
			[179245] = true, -- Анжинерский чоппер с водителем
		}
		self.herbalismMounts = {
			[134359] = true, -- Небесный голем
			[223814] = true, -- Механизированный хвататель разностей
		}

		self.sFlags = {}
		self.priorityProfiles = {}
		self.list = {}
		self.empty = {}

		self.mapVashjir = {
			[201] = true, -- Лес Келп’тар
			[203] = true, -- Вайш'ир
			[204] = true, -- Бездонные глубины
			[205] = true, -- Мерцающий простор
		}

		self.usableRepairMounts = {}
		self.usableIDs = {}
		self.magicBrooms = {
			{itemID = 37011},
			{mountID = 1799},
		}
	end
end


function mounts:getDefaultRule()
	return {
		{false, "btn", 1},
		action = {"rmount", 0},
	}
end


function mounts:checkRuleSet(ruleSet)
	for i = 1, 2 do
		ruleSet[i] = ruleSet[i] or {self:getDefaultRule()}
	end
end


function mounts:checkProfile(profile)
	profile.fly = profile.fly or {}
	profile.ground = profile.ground or {}
	profile.swimming = profile.swimming or {}
	profile.zoneMounts = profile.zoneMounts or {}
	profile.petForMount = profile.petForMount or {}
	profile.mountsWeight = profile.mountsWeight or {}
end


function mounts:PLAYER_LOGIN()
	self.PLAYER_LOGIN = nil
	self:setOldChanges()

	-- INIT
	self:setSelectedProfile()
	self:setUsableRepairMounts()
	self:setModifier(self.config.modifier)
	self:setHandleWaterJump(self.config.waterJump)
	self:setHerbMount()
	self:init()
	self:event("ADDON_INIT"):off("ADDON_INIT")

	-- MAP CHANGED
	-- self:RegisterEvent("NEW_WMO_CHUNK")
	-- self:RegisterEvent("ZONE_CHANGED")
	-- self:RegisterEvent("ZONE_CHANGED_INDOORS")
	-- self:RegisterEvent("ZONE_CHANGED_NEW_AREA")

	-- INSTANCE INFO UPDATE
	self:RegisterEvent("PLAYER_ENTERING_WORLD")

	-- PROFESSION CHANGED OR MOUNT ADDED
	self:RegisterEvent("SKILL_LINES_CHANGED")
	self:RegisterEvent("NEW_MOUNT_ADDED")

	-- PET USABLE
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")

	-- PRFILE CHANGED
	self:on("UPDATE_PROFILE", self.setSelectedProfile)
end


do
	local durabilitySlots = {
		INVSLOT_HEAD,
		INVSLOT_SHOULDER,
		INVSLOT_CHEST,
		INVSLOT_WRIST,
		INVSLOT_HAND,
		INVSLOT_WAIST,
		INVSLOT_LEGS,
		INVSLOT_FEET,
		INVSLOT_MAINHAND,
		INVSLOT_OFFHAND,
	}

	function mounts:UPDATE_INVENTORY_DURABILITY()
		local percent = (tonumber(self.config.useRepairMountsDurability) or 0) / 100
		local flyablePercent = (tonumber(self.config.useRepairFlyableDurability) or 0) / 100
		self.sFlags.repair = false
		self.sFlags.flyableRepair = false
		if self.config.useRepairMounts then
			for i = 1, #durabilitySlots do
				local durCur, durMax = GetInventoryItemDurability(durabilitySlots[i])
				if durCur and durMax then
					local itemPercent = durCur / durMax
					if itemPercent < percent then
						self.sFlags.repair = true
					end
					if itemPercent < flyablePercent then
						self.sFlags.flyableRepair = true
					end
				end
			end
			if not self.config.useRepairFlyable then
				self.sFlags.flyableRepair = self.sFlags.repair
			end
		end
	end
end


function mounts:setUsableRepairMounts()
	wipe(self.usableRepairMounts)
	if not self.config.repairSelectedMount then
		for spellID in pairs(ns.specificDB.repair) do
			local mountID = C_MountJournal.GetMountFromSpell(spellID)
			local _,_,_,_,_,_,_,_,_, shouldHideOnChar, isCollected = C_MountJournal.GetMountInfoByID(mountID)
			if isCollected and not shouldHideOnChar then
				self.usableRepairMounts[spellID] = true
			end
		end
	else
		local _,_,_,_,_,_,_,_,_, shouldHideOnChar = C_MountJournal.GetMountInfoByID(self.config.repairSelectedMount)
		if shouldHideOnChar then
			self.config.repairSelectedMount = self.config.repairSelectedMount == 61425 and 61447 or 61425
		end
		self.usableRepairMounts[self.config.repairSelectedMount] = true
	end
end


function mounts:notEnoughFreeSlots()
	if self.config.useRepairFreeSlots then
		local totalFree, freeSlots, bagFamily = 0
		for i = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
			freeSlots, bagFamily = C_Container.GetContainerNumFreeSlots(i)
			if bagFamily == 0 then totalFree = totalFree + freeSlots end
		end
		return totalFree < self.config.useRepairFreeSlotsNum
	end
end


function mounts:PLAYER_ENTERING_WORLD()
	local _, instanceType, _,_,_,_,_, instanceID = GetInstanceInfo()
	self.instanceID = instanceID
	self.instanceType = instanceType
end


function mounts:PLAYER_REGEN_DISABLED()
	self:UnregisterEvent("UNIT_SPELLCAST_START")
end


function mounts:PLAYER_REGEN_ENABLED()
	self:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
end


do
	local function summonPet(petID)
		if InCombatLockdown() then return end
		if type(petID) == "number" then
			ns.pets:summonRandomPet(petID == 1)
		else
			ns.pets:summon(petID)
		end
	end


	local timer
	function mounts:UNIT_SPELLCAST_START(_,_, spellID)
		local petID
		if self.fromPriority then
			for i = 1, #self.priorityProfiles do
				petID = self.priorityProfiles[i].petForMount[spellID]
				if petID then break end
			end
			self.fromPriority = nil
		else
			local profile = self.profiles[self.charDB.currentProfileName] or self.defProfile
			petID = profile.petForMount[spellID]
		end

		if petID then
			local groupType = util.getGroupType()
			if self.config.noPetInRaid and groupType == "raid"
			or self.config.noPetInGroup and groupType == "group"
			then return end

			if timer and not timer:IsCancelled() then
				timer:Cancel()
				timer = nil
			end

			local cdInfo = C_Spell.GetSpellCooldown(61304)

			if cdInfo.duration == 0 then
				summonPet(petID)
			else
				timer = C_Timer.NewTicker(cdInfo.startTime + cdInfo.duration - GetTime(), function() summonPet(petID) end, 1)
			end
		end
	end
end


function mounts:NEW_MOUNT_ADDED(mountID)
	local _, spellID = C_MountJournal.GetMountInfoByID(mountID)
	self:autoAddNewMount(spellID)
	if self.herbalismMounts[spellID] then self:setHerbMount() end
end


do
	local function addMount(list, mountType, spellID)
		if mountType == 1 then
			mountType = "fly"
		elseif mountType == 2 then
			mountType = "ground"
		else
			mountType = "swimming"
		end

		list[mountType][spellID] = true
	end


	function mounts:addMountToList(list, spellID)
		local mountType
		if ns.additionalMounts[spellID] then
			mountType = util.mountTypes[ns.additionalMounts[spellID].mountType]
		else
			local mountID = C_MountJournal.GetMountFromSpell(spellID)
			local _,_,_,_, mountTypeExtra = C_MountJournal.GetMountInfoExtraByID(mountID)
			mountType = util.mountTypes[mountTypeExtra]
		end

		if type(mountType) == "table" then
			for i = 1, #mountType do
				addMount(list, mountType[i], spellID)
			end
		else
			addMount(list, mountType, spellID)
		end
	end
end


function mounts:autoAddNewMount(spellID)
	if self.defProfile.autoAddNewMount then
		self:addMountToList(self.defProfile, spellID)
	end

	for _, profile in next, self.profiles do
		if profile.autoAddNewMount then
			self:addMountToList(profile, spellID)
		end
	end
end


function mounts:setModifier(modifier)
	if modifier == "NONE" then
		self.config.modifier = modifier
		self.modifier = function() return false end
	elseif modifier == "SHIFT" then
		self.config.modifier = modifier
		self.modifier = IsShiftKeyDown
	elseif modifier == "CTRL" then
		self.config.modifier = modifier
		self.modifier = IsControlKeyDown
	else
		self.config.modifier = "ALT"
		self.modifier = IsAltKeyDown
	end
end


function mounts:resetMountsList()
	self.mapFlags = nil
	wipe(self.list)
	wipe(self.priorityProfiles)
end


function mounts:setMountsList(profile)
	if not profile then return end
	self.priorityProfiles[#self.priorityProfiles + 1] = profile
	if self.mapFlags and self.list.fly and self.list.ground and self.list.swimming then return end

	local mapInfo = self.mapInfo
	while mapInfo do
		local zoneMounts, list = profile.zoneMountsFromProfile and self.defProfile.zoneMounts or profile.zoneMounts

		if mapInfo.mapID == self.defMountsListID then
			list = profile
		else
			list = zoneMounts[mapInfo.mapID]

			if list and not self.mapFlags and list.flags.enableFlags then
				self.mapFlags = list.flags
			end
		end

		if list then
			if not (self.list.fly and self.list.ground and self.list.swimming) then
				while list and list.listFromID do
					if list.listFromID == self.defMountsListID then
						list = profile
					else
						list = zoneMounts[list.listFromID]
					end
				end
				if list then
					if not self.list.fly and next(list.fly) then
						self.list.fly = list.fly
						self.list.flyWeight = profile.mountsWeight
					end
					if not self.list.ground and next(list.ground) then
						self.list.ground = list.ground
						self.list.groundWeight = profile.mountsWeight
					end
					if not self.list.swimming and next(list.swimming) then
						self.list.swimming = list.swimming
						self.list.swimmingWeight = profile.mountsWeight
					end
				end
			end
		end

		if mapInfo.parentMapID == 0 and mapInfo.mapID ~= self.defMountsListID then
			mapInfo = C_Map.GetMapInfo(self.defMountsListID)
		else
			mapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
		end
	end
end


function mounts:setEmptyList()
	if not self.list.fly then self.list.fly = self.empty end
	if not self.list.ground then self.list.ground = self.empty end
	if not self.list.swimming then self.list.swimming = self.empty end
end


function mounts:setSelectedProfile()
	if self.charDB.currentProfileName and not self.profiles[self.charDB.currentProfileName] then
		self.charDB.currentProfileName = nil
	end
	self.sp = self.profiles[self.charDB.currentProfileName] or self.defProfile
end


function mounts:setHandleWaterJump(enable)
	if type(enable) == "boolean" then
		self.config.waterJump = enable
		local registred = self:IsEventRegistered("MOUNT_JOURNAL_USABILITY_CHANGED")
		if enable then
			if not registred then
				self:RegisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")
			end
		else
			if registred then
				self:UnregisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")
			end
		end
	end
end


function mounts:MOUNT_JOURNAL_USABILITY_CHANGED()
	if not IsSubmerged() then
		self.lastJumpTime = GetTime()
	end
end


function mounts:isFloating()
	return self.config.waterJump and GetTime() - (self.lastJumpTime or 0) < 1
end


function mounts:getTargetMount()
	if self.config.copyMountTarget then
		local spellID, mountID = util.getUnitMount("target")
		if mountID then
			local _,_,_,_, isUsable = C_MountJournal.GetMountInfoByID(mountID)
			return isUsable and C_Spell.IsSpellUsable(spellID) and spellID
		elseif spellID then
			return ns.additionalMounts[spellID]:canUse() and spellID
		end
	end
end


function mounts:summon(spellID)
	self.summonedSpellID = spellID or self.summonedSpellID
	if self.summonedSpellID then
		local mountID = C_MountJournal.GetMountFromSpell(self.summonedSpellID)
		if mountID then
			C_MountJournal.SummonByID(mountID)
			return true
		end
	end
end


function mounts:setUsableID(ids, mountsWeight)
	local weight = 0
	wipe(self.usableIDs)

	for spellID in next, ids do
		local usable
		if ns.additionalMounts[spellID] then
			usable = self.withAdditional and ns.additionalMounts[spellID]:canUse()
		else
			local mountID = C_MountJournal.GetMountFromSpell(spellID)
			if mountID then
				local _,_,_,_, isUsable = C_MountJournal.GetMountInfoByID(mountID)
				usable = isUsable and C_Spell.IsSpellUsable(spellID)
			end
		end

		if usable then
			weight = weight + (mountsWeight[spellID] or 100)
			self.usableIDs[weight] = spellID
		end
	end

	if weight > 0 then
		for i = random(weight), weight do
			if self.usableIDs[i] then
				self.summonedSpellID = self.usableIDs[i]
				return true
			end
		end
	end
end


function mounts:getSpellKnown()
	if IsPlayerSpell(90265) -- Мастер верховой езды
	or IsPlayerSpell(34091) -- Верховая езда (искусник)
	or IsPlayerSpell(34090) -- Верховая езда (умелец)
	or C_MountJournal.IsDragonridingUnlocked()
	then
		return true, true
	end

	if IsPlayerSpell(33391) -- Верховая езда (подмастерье)
	or IsPlayerSpell(33388) -- Верховая езда (ученик)
	then
		return true, false
	end

	return false, false
end


function mounts:setHerbMount()
	if self.config.useHerbMounts then
		local prof1, prof2 = GetProfessions()
		if prof1 and select(7, GetProfessionInfo(prof1)) == 182 or prof2 and select(7, GetProfessionInfo(prof2)) == 182 then
			for spellID in next, self.herbalismMounts do
				local mountID = C_MountJournal.GetMountFromSpell(spellID)
				if select(11, C_MountJournal.GetMountInfoByID(mountID)) then
					self.herbMount = true
					return
				end
			end
		end
	end
	self.herbMount = false
end
mounts.SKILL_LINES_CHANGED = mounts.setHerbMount


do
	local continentsGround = {
		[1813] = true, -- Экспедиция: Руины Ун'гола
		[1814] = true, -- Экспедиция: Тихая Сень
		[1879] = true, -- Экспедиция: Йорундалль
		[1882] = true, -- Экспедиция: Зеленые дебри
		[1883] = true, -- Экспедиция: Шепчущий риф
		[1892] = true, -- Экспедиция: Гниющая трясина
		[1893] = true, -- Экспедиция: Оковы Ужаса
		[1897] = true, -- Экспедиция: Раскаленный остров
		[1898] = true, -- Экспедиция: Паучья лощина
		[1907] = true, -- Экспедиция: Цветущая Зима

		[1107] = true, -- Разлом Зловещего Шрама
		[1463] = true, -- Внешняя область Хельхейма
		[1514] = true, -- Скитающийся остров
		[1688] = true, -- Мертвые копи
		[1760] = true, -- Лордерон
		[1763] = true, -- Атал'Дазар
		-- [1876] = true, -- Фронт: Арати (Орда)
		-- [1943] = true, -- Фронт: Арати (Альянс)
		-- [2105] = true, -- Фронт: Темные берега (Альянс)
		-- [2111] = true, -- Фронт: Темные берега (Орда)

		[2291] = true, -- Та Сторона
	}
	-- 1170, -- Горгронд - сценарий маг'харов

	local LE_SCENARIO_TYPE_WARFRONT = LE_SCENARIO_TYPE_WARFRONT

	function mounts:isFlyLocation(instanceID)
		if C_Scenario.IsInScenario() then
			local _,_,_,_,_,_,_,_,_, scenarioType = C_Scenario.GetInfo()
			if scenarioType == LE_SCENARIO_TYPE_WARFRONT then return false end
		end

		return not continentsGround[instanceID]
	end
end


do
	local isFlyableOverride = {
		-- Draenor
		[1116] = true,
		[1152] = true,
		[1330] = true,
		[1153] = true,
		[1154] = true,
		[1158] = true,
		[1331] = true,
		[1159] = true,
		[1160] = true,
		[1464] = true,
		-- Legion
		[1220] = true,
		-- TWW
		[2552] = true,
		[2601] = true,
		[2662] = true,
	}

	function mounts:setFlags()
		self.mapInfo = C_Map.GetMapInfo(MapUtil.GetDisplayableMapForPlayer())
		local flags = self.sFlags
		local groundSpellKnown, flySpellKnown = self:getSpellKnown()
		local isFloating = self:isFloating()
		local isFlyableLocation = flySpellKnown
		                          and (IsFlyableArea() or isFlyableOverride[self.instanceID])
		                          and self:isFlyLocation(self.instanceID)

		flags.modifier = self.modifier() or flags.forceModifier
		flags.isSubmerged = IsSubmerged()
		flags.isIndoors = IsIndoors()
		flags.inVehicle = UnitInVehicle("player")
		flags.isMounted = IsMounted()
		flags.groundSpellKnown = groundSpellKnown
		flags.swimming = flags.isSubmerged
		                 and not (flags.modifier or isFloating)
		flags.isVashjir = self.mapVashjir[self.mapInfo.mapID]
		flags.fly = isFlyableLocation
		            and (not flags.modifier or flags.isSubmerged)
		flags.waterWalk = isFloating
		                  or not isFlyableLocation and flags.modifier
		flags.targetMount = self:getTargetMount()
	end
end


function mounts:updateFlagsWithMap()
	local flags = self.sFlags
	local groundOnly = self.mapFlags and self.mapFlags.groundOnly

	flags.fly = flags.fly and not groundOnly
	flags.waterWalk = flags.waterWalk
	                  or groundOnly and flags.modifier
	                  or self.mapFlags and self.mapFlags.waterWalkOnly
	flags.herb = self.herbMount and (not self.config.herbMountsOnZones
	                                 or self.mapFlags and self.mapFlags.herbGathering)
	flags.useRepair = flags.repair and not flags.fly
	                  or flags.flyableRepair and flags.fly
	                  or self:notEnoughFreeSlots()
end


function mounts:errorSummon()
	UIErrorsFrame:AddMessage(InCombatLockdown() and SPELL_FAILED_AFFECTING_COMBAT or L["ERR_MOUNT_NO_SELECTED"], 1, .1, .1, 1)
	self.fromPriority = nil
end


function mounts:setSummonMount(withAdditional)
	self.withAdditional = withAdditional
	self.summonedSpellID = nil
	self.fromPriority = true
	local flags = self.sFlags
	if not flags.groundSpellKnown then
		if not (flags.swimming and self:setUsableID(self.list.swimming, self.list.swimmingWeight) or self:setUsableID(self.lowLevel, self.sp.mountsWeight)) then
			self:errorSummon()
		end
	-- repair mounts
	elseif not (flags.useRepair and self:setUsableID(self.usableRepairMounts, self.sp.mountsWeight))
	-- target's mount
	and not (flags.targetMount and self:summon(flags.targetMount))
	-- swimming
	and not (flags.swimming and (
		flags.isVashjir and self:setUsableID(self.swimmingVashjir, self.sp.mountsWeight)
		or self:setUsableID(self.list.swimming, self.list.swimmingWeight)
	))
	-- herbMount
	and not (flags.herb and self:setUsableID(self.herbalismMounts, self.sp.mountsWeight))
	-- fly
	and not (flags.fly and self:setUsableID(self.list.fly, self.list.flyWeight))
	-- ground
	and not self:setUsableID(self.list.ground, self.list.groundWeight)
	and not self:setUsableID(self.list.fly, self.list.flyWeight)
	and not self:setUsableID(self.lowLevel, self.sp.mountsWeight) then
		self:errorSummon()
	end
end


function mounts:init()
	SLASH_MOUNTSJOURNAL1 = "/mount"
	SlashCmdList["MOUNTSJOURNAL"] = function(msg)
		if not SecureCmdOptionParse(msg) then return end
		self.sFlags.forceModifier = nil
		self:setFlags()
		local flags = self.sFlags
		if flags.inVehicle then
			VehicleExit()
		elseif flags.isMounted then
			Dismount()
		else
			ns.macroFrame.checkRules[1](ns.macroFrame, "LeftButton", true)
			self:setSummonMount()
			self:summon()
		end
	end
end