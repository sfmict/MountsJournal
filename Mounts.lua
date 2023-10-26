local addon = ...
local C_MountJournal, C_Map, MapUtil, next, wipe, random, IsSpellKnown, GetTime, IsFlyableArea, IsSubmerged, GetInstanceInfo, IsIndoors, UnitInVehicle, IsMounted, InCombatLockdown, GetSpellCooldown, UnitBuff, IsUsableSpell, SecureCmdOptionParse = C_MountJournal, C_Map, MapUtil, next, wipe, random, IsSpellKnown, GetTime, IsFlyableArea, IsSubmerged, GetInstanceInfo, IsIndoors, UnitInVehicle, IsMounted, InCombatLockdown, GetSpellCooldown, UnitBuff, IsUsableSpell, SecureCmdOptionParse
local util = MountsJournalUtil
local mounts = CreateFrame("Frame", "MountsJournal")
util.setEventsMixin(mounts)


mounts:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
mounts:RegisterEvent("ADDON_LOADED")
mounts:RegisterEvent("PLAYER_LOGIN")
mounts:RegisterEvent("UPDATE_INVENTORY_DURABILITY")


function mounts:ADDON_LOADED(addonName)
	if addonName == addon then
		self:UnregisterEvent("ADDON_LOADED")

		local mapInfo = MapUtil.GetMapParentInfo(C_Map.GetFallbackWorldMapID(), Enum.UIMapType.Cosmic, true)
		self.defMountsListID = mapInfo and mapInfo.mapID or 946 -- WORLD

		MountsJournalDB = MountsJournalDB or {}
		self.globalDB = MountsJournalDB
		self.globalDB.mountTags = self.globalDB.mountTags or {}
		self.globalDB.filters = self.globalDB.filters or {}
		self.globalDB.defFilters = self.globalDB.defFilters or {}
		self.globalDB.config = self.globalDB.config or {}
		self.globalDB.mountAnimations = self.globalDB.mountAnimations or {}
		self.globalDB.defProfile = self.globalDB.defProfile or {}
		self.globalDB.mountsProfiles = self.globalDB.mountsProfiles or {}
		self.globalDB.holidayNames = self.globalDB.holidayNames or {}
		self.globalDB.help = self.globalDB.help or {}

		self.defProfile = self.globalDB.defProfile
		self:checkProfile(self.defProfile)
		self.profiles = self.globalDB.mountsProfiles
		for name, profile in next, self.profiles do
			self:checkProfile(profile)
		end
		self.filters = self.globalDB.filters
		self.defFilters = self.globalDB.defFilters
		self.help = self.globalDB.help
		self.config = self.globalDB.config
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
		self.charDB.profileBySpecialization = self.charDB.profileBySpecialization or {}
		self.charDB.profileBySpecializationPVP = self.charDB.profileBySpecializationPVP or {}
		self.charDB.holidayProfiles = self.charDB.holidayProfiles or {}

		-- Рудименты
		self:setOldChanges()

		-- Списки
		self.swimmingVashjir = {
			[373] = true, -- Вайш'ирский морской конек
		}
		self.lowLevel = {
			[678] = true, -- Механоцикл с шофером
			[679] = true, -- Анжинерский чоппер с водителем
		}
		self.herbalismMounts = {
			[522] = true, -- Небесный голем
			[845] = true, -- Механизированный хвататель разностей
		}

		self.sFlags = {}
		self.priorityProfiles = {}
		self.list = {}
		self.continentsGround = {
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
			[1876] = true, -- Фронт: Арати (Орда)
			[1943] = true, -- Фронт: Арати (Альянс)
			[2105] = true, -- Фронт: Темные берега (Альянс)
			[2111] = true, -- Фронт: Темные берега (Орда)

			[2291] = true, -- Та Сторона
		}
		-- 1170, -- Горгронд - сценарий маг'харов

		self.mapVashjir = {
			[201] = true, -- Лес Келп’тар
			[203] = true, -- Вайш'ир
			[204] = true, -- Бездонные глубины
			[205] = true, -- Мерцающий простор
		}

		self.repairMounts = {
			280,
			284,
			460,
			1039,
		}
		self.usableRepairMounts = {}
		self.usableIDs = {}
		self.weight = 0
		self:setUsableRepairMounts()
	end
end


function mounts:checkProfile(profile)
	profile.dragonriding = profile.dragonriding or {}
	profile.fly = profile.fly or {}
	profile.ground = profile.ground or {}
	profile.swimming = profile.swimming or {}
	profile.zoneMounts = profile.zoneMounts or {}
	profile.petForMount = profile.petForMount or {}
	profile.mountsWeight = profile.mountsWeight or {}
end


local function compareVersion(v1, v2)
	v1 = v1:gsub("%D*([%d%.]+).*", "%1")
	v2 = v2:gsub("%D*([%d%.]+).*", "%1")
	v1 = {("."):split(v1)}
	v2 = {("."):split(v2)}
	for i = 1, min(#v1, #v2) do
		v1[i] = tonumber(v1[i]) or 0
		v2[i] = tonumber(v2[i]) or 0
		if v1[i] > v2[i] then return true end
		if v1[i] < v2[i] then return false end
	end
	return #v1 > #v2
end


function mounts:setOldChanges()
	self.setOldChanges = nil

	local currentVersion = C_AddOns.GetAddOnMetadata(addon, "Version")
	--@do-not-package@
	if currentVersion == "@project-version@" then currentVersion = "10.1.18" end
	--@end-do-not-package@

	--IF < 8.3.2 GLOBAL
	if compareVersion("8.3.2", self.globalDB.lastAddonVersion or "") then
		self.config.waterWalkAll = nil
		self.config.waterWalkList = nil
		self.config.waterWalkInstance = nil
		self.config.waterWalkExpedition = nil
		self.config.waterWalkExpeditionList = nil

		local function setMounts(tbl)
			if tbl and #tbl > 0 then
				local newTbl = {}
				for i = 1, #tbl do
					newTbl[tbl[i]] = true
				end
				return newTbl
			end
			return tbl
		end

		self.globalDB.fly = setMounts(self.globalDB.fly)
		self.globalDB.ground = setMounts(self.globalDB.ground)
		self.globalDB.swimming = setMounts(self.globalDB.swimming)
		if self.globalDB.zoneMounts then
			for _, list in next, self.globalDB.zoneMounts do
				list.fly = setMounts(list.fly)
				list.ground = setMounts(list.ground)
				list.swimming = setMounts(list.swimming)
			end
		end

		for _, profile in next, self.globalDB.mountsProfiles do
			profile.fly = setMounts(profile.fly or {})
			profile.ground = setMounts(profile.ground or {})
			profile.swimming = setMounts(profile.swimming or {})
			profile.zoneMounts = profile.zoneMounts or {}
			profile.petForMount = profile.petForMount or {}

			for _, list in next, profile.zoneMounts do
				list.fly = setMounts(list.fly)
				list.ground = setMounts(list.ground)
				list.swimming = setMounts(list.swimming)
			end
		end
	end

	--IF < 9.0.8 GLOBAL
	if compareVersion("9.0.8", self.globalDB.lastAddonVersion or "") then
		local function updateTable(to, from)
			for k, v in next, from do
				if type(v) ~= "table" then
					to[k] = v
				elseif type(to[k]) ~= "table" then
					to[k] = util:copyTable(v)
				else
					updateTable(to[k], v)
				end
			end
		end

		if type(self.globalDB.fly) == "table" then
			updateTable(self.defProfile.fly, self.globalDB.fly)
			self.globalDB.fly = nil
		end
		if type(self.globalDB.ground) == "table" then
			updateTable(self.defProfile.ground, self.globalDB.ground)
			self.globalDB.ground = nil
		end
		if type(self.globalDB.swimming) == "table" then
			updateTable(self.defProfile.swimming, self.globalDB.swimming)
			self.globalDB.swimming = nil
		end
		if type(self.globalDB.zoneMounts) == "table" then
			updateTable(self.defProfile.zoneMounts, self.globalDB.zoneMounts)
			self.globalDB.zoneMounts = nil
		end
		if type(self.globalDB.petForMount) == "table" then
			updateTable(self.defProfile.petForMount, self.globalDB.petForMount)
			self.globalDB.petForMount = nil
		end
	end

	-- IF < 10.1.18 GLOBAL
	if compareVersion("10.1.18", self.globalDB.lastAddonVersion or "") then
		local function listToDragonriding(dragonriding, list)
			for mountID in next, list do
				local _,_,_,_,_,_,_,_,_,_,_,_, isForDragonriding = C_MountJournal.GetMountInfoByID(mountID)
				if isForDragonriding then
					list[mountID] = nil
					dragonriding[mountID] = true
				end
			end
		end

		local function allToDragonriding(profile)
			listToDragonriding(profile.dragonriding, profile.fly)
			listToDragonriding(profile.dragonriding, profile.ground)
			listToDragonriding(profile.dragonriding, profile.swimming)

			for mapID, data in next, profile.zoneMounts do
				data.dragonriding = data.dragonriding or {}
				listToDragonriding(data.dragonriding, data.fly)
				listToDragonriding(data.dragonriding, data.ground)
				listToDragonriding(data.dragonriding, data.swimming)
			end
		end

		C_Timer.After(0, function()
			allToDragonriding(self.defProfile)
			for name, data in next, self.profiles do
				allToDragonriding(data)
			end
		end)
	end

	-- SET LAST GLOBAL VERSION
	self.globalDB.lastAddonVersion = currentVersion

	-- IF < 8.3.2 CHAR
	if compareVersion("8.3.2", self.charDB.lastAddonVersion or "") then
		local function setMounts(tbl)
			if #tbl > 0 then
				local newTbl = {}
				for i = 1, #tbl do
					newTbl[tbl[i]] = true
				end
				return newTbl
			end
			return tbl
		end

		if type(self.charDB.fly) == "table" and #self.charDB.fly > 0
		or type(self.charDB.ground) == "table" and #self.charDB.ground > 0
		or type(self.charDB.swimming) == "table" and #self.charDB.swimming > 0
		or type(self.charDB.zoneMounts) == "table" and next(self.charDB.zoneMounts) ~= nil then
			local name = UnitName("player").." - "..GetRealmName()
			if not self.profiles[name] then
				self.profiles[name] = {
					fly = setMounts(self.charDB.fly or {}),
					ground = setMounts(self.charDB.ground or {}),
					swimming = setMounts(self.charDB.swimming or {}),
					zoneMounts = self.charDB.zoneMounts or {},
					petForMount = {},
				}
				if self.charDB.enable then
					self.charDB.currentProfileName = name
				end
				for _, list in next, self.profiles[name].zoneMounts do
					list.fly = setMounts(list.fly)
					list.ground = setMounts(list.ground)
					list.swimming = setMounts(list.swimming)
				end
			end
		end

		self.charDB.fly = nil
		self.charDB.ground = nil
		self.charDB.swimming = nil
		self.charDB.zoneMounts = nil
		self.charDB.enable = nil
	end

	-- SET LAST CHAR VERSION
	self.charDB.lastAddonVersion = currentVersion
end


function mounts:PLAYER_LOGIN()
	-- INIT
	self:setModifier(self.config.modifier)
	self:setHandleWaterJump(self.config.waterJump)
	self:setHerbMount()
	self:init()
	self.pets:setSummonEvery()
	self.calendar:init()

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

	-- SPEC CHANGED
	self:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")

	-- PET USABLE
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")

	-- CALENDAR
	self:on("CALENDAR_UPDATE_EVENT_LIST", self.setDB)
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
		for i = 1, #self.repairMounts do
			local mountID = self.repairMounts[i]
			local _,_,_,_,_,_,_,_,_, shouldHideOnChar, isCollected = C_MountJournal.GetMountInfoByID(mountID)
			if isCollected and not shouldHideOnChar then
				self.usableRepairMounts[mountID] = true
			end
		end
	else
		local _,_,_,_,_,_,_,_,_, shouldHideOnChar = C_MountJournal.GetMountInfoByID(self.config.repairSelectedMount)
		if shouldHideOnChar then
			self.config.repairSelectedMount = self.config.repairSelectedMount == 280 and 284 or 280
		end
		self.usableRepairMounts[self.config.repairSelectedMount] = true
	end
end


function mounts:PLAYER_ENTERING_WORLD()
	local _, instanceType, _,_,_,_,_, instanceID = GetInstanceInfo()
	self.instanceID = instanceID
	local pvp = instanceType == "arena" or instanceType == "pvp"
	if self.pvp ~= pvp then
		self.pvp = pvp
		self:setDB()
	end
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
			mounts.pets:summonRandomPet(petID == 1)
		else
			mounts.pets:summon(petID)
		end
	end


	local timer
	function mounts:UNIT_SPELLCAST_START(_,_, spellID)
		local petID
		for i = 1, #self.priorityProfiles do
			petID = self.priorityProfiles[i].petForMount[spellID]
			if petID then break end
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

			local start, duration = GetSpellCooldown(61304)

			if duration == 0 then
				summonPet(petID)
			else
				timer = C_Timer.NewTicker(start + duration - GetTime(), function() summonPet(petID) end, 1)
			end
		end
	end
end


function mounts:NEW_MOUNT_ADDED(mountID)
	self:autoAddNewMount(mountID)
	if self.herbalismMounts[mountID] then self:setHerbMount() end
end


do
	local function addMount(list, mountType, mountID)
		if mountType == 1 then
			mountType = "fly"
		elseif mountType == 2 then
			mountType = "ground"
		elseif mountType == 3 then
			mountType = "swimming"
		else
			mountType = "dragonriding"
		end

		list[mountType][mountID] = true
	end


	function mounts:addMountToList(list, mountID)
		local _,_,_,_, mountTypeExtra = C_MountJournal.GetMountInfoExtraByID(mountID)
		local mountType = util.mountTypes[mountTypeExtra]

		if type(mountType) == "table" then
			for i = 1, #mountType do
				addMount(list, mountType[i], mountID)
			end
		else
			addMount(list, mountType, mountID)
		end
	end
end


function mounts:autoAddNewMount(mountID)
	if self.defProfile.autoAddNewMount then
		self:addMountToList(self.defProfile, mountID)
	end

	for _, profile in next, self.profiles do
		if profile.autoAddNewMount then
			self:addMountToList(profile, mountID)
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


function mounts:setMountsList()
	self.mapInfo = C_Map.GetMapInfo(MapUtil.GetDisplayableMapForPlayer())
	self.mapFlags = nil
	wipe(self.list)

	local mapInfo = self.mapInfo
	while mapInfo do
		for i = 1, #self.priorityProfiles do
			local profile, list = self.priorityProfiles[i]

			if mapInfo.mapID == self.defMountsListID then
				list = profile
			else
				local zoneMounts = profile.zoneMountsFromProfile and self.defProfile.zoneMounts or profile.zoneMounts
				list = zoneMounts[mapInfo.mapID]

				if list and not self.mapFlags and list.flags.enableFlags then
					self.mapFlags = list.flags
				end
			end

			if list then
				if not (self.list.dragonriding and self.list.fly and self.list.ground and self.list.swimming) then
					while list and list.listFromID do
						if list.listFromID == self.defMountsListID then
							list = profile
						else
							list = zoneMounts[list.listFromID]
						end
					end
					if list then
						if not self.list.dragonriding and next(list.dragonriding) then
							self.list.dragonriding = list.dragonriding
							self.list.dragonridingWeight = profile.mountsWeight
						end
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
				elseif self.mapFlags then return end
			end
		end
		mapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
	end

	local empty = {}
	if not self.list.dragonriding then self.list.dragonriding = empty end
	if not self.list.fly then self.list.fly = empty end
	if not self.list.ground then self.list.ground = empty end
	if not self.list.swimming then self.list.swimming = empty end
end
-- mounts.NEW_WMO_CHUNK = mounts.setMountsList
-- mounts.ZONE_CHANGED = mounts.setMountsList
-- mounts.ZONE_CHANGED_INDOORS = mounts.setMountsList
-- mounts.ZONE_CHANGED_NEW_AREA = mounts.setMountsList


function mounts:setDB()
	for i = 1, GetNumSpecializations() do
		local profileName = self.charDB.profileBySpecialization[i]
		if profileName and not self.profiles[profileName] then
			self.charDB.profileBySpecialization[i] = nil
		end
		profileName = self.charDB.profileBySpecializationPVP[i]
		if profileName and not self.profiles[profileName] then
			self.charDB.profileBySpecializationPVP[i] = nil
		end
	end

	if self.charDB.currentProfileName and not self.profiles[self.charDB.currentProfileName] then
		self.charDB.currentProfileName = nil
	end

	local profileName
	wipe(self.priorityProfiles)

	if self.pvp and self.charDB.profileBySpecializationPVP.enable then
		profileName = self.charDB.profileBySpecializationPVP[GetSpecialization()]
		self.priorityProfiles[1] = self.profiles[profileName] or self.defProfile
	end

	local holidayProfiles = self.calendar:getHolidayProfileNames()
	for i = 1, #holidayProfiles do
		self.priorityProfiles[#self.priorityProfiles + 1] = self.profiles[holidayProfiles[i].profileName] or self.defProfile
	end

	if self.charDB.profileBySpecialization.enable then
		profileName = self.charDB.profileBySpecialization[GetSpecialization()]
		self.priorityProfiles[#self.priorityProfiles + 1] = self.profiles[profileName] or self.defProfile
	end

	profileName = self.charDB.currentProfileName
	self.db = self.profiles[profileName] or self.defProfile
	self.priorityProfiles[#self.priorityProfiles + 1] = self.db
end
mounts.PLAYER_SPECIALIZATION_CHANGED = mounts.setDB


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
		local i = 1
		repeat
			local _,_,_,_,_,_,_,_,_, spellID = UnitBuff("target", i)
			if spellID then
				local mountID = C_MountJournal.GetMountFromSpell(spellID)
				if mountID then
					local _,_,_,_, isUsable = C_MountJournal.GetMountInfoByID(mountID)
					return isUsable and IsUsableSpell(spellID) and mountID
				end
				i = i + 1
			end
		until not spellID
	end
end


function mounts:summon()
	if self.weight > 0 then
		for i = random(self.weight), self.weight do
			if self.usableIDs[i] then
				C_MountJournal.SummonByID(self.usableIDs[i])
				break
			end
		end
	end
end


function mounts:summonDragonridable()
	self.weight = 0
	wipe(self.usableIDs)

	for mountID in next, self.list.dragonriding do
		local _,_,_,_,_,_,_,_,_,_,_,_, isForDragonriding = C_MountJournal.GetMountInfoByID(mountID)
		if isForDragonriding then
			self.weight = self.weight + (self.list.dragonridingWeight[mountID] or 100)
			self.usableIDs[self.weight] = mountID
		end
	end

	return self.weight > 0
end


function mounts:setUsableIDs(ids, mountsWeight)
	self.summonList = ids
	self.weight = 0
	wipe(self.usableIDs)

	for mountID in next, ids do
		local _,_,_,_, isUsable, _,_,_,_,_,_,_, isForDragonriding = C_MountJournal.GetMountInfoByID(mountID)
		if isUsable and not isForDragonriding then
			self.weight = self.weight + (mountsWeight[mountID] or 100)
			self.usableIDs[self.weight] = mountID
		end
	end

	return self.weight > 0
end


function mounts:getSpellKnown()
	if IsSpellKnown(90265) -- Мастер верховой езды
	or IsSpellKnown(34091) -- Верховая езда (искусник)
	or IsSpellKnown(34090) -- Верховая езда (умелец)
	then
		return true, true
	end

	if IsSpellKnown(33391) -- Верховая езда (подмастерье)
	or IsSpellKnown(33388) -- Верховая езда (ученик)
	then
		return true, false
	end

	-- 34091 and 34090 not detected
	-- return false, false
	return true, true
end


function mounts:setHerbMount()
	if self.config.useHerbMounts then
		local prof1, prof2 = GetProfessions()
		if prof1 and select(7, GetProfessionInfo(prof1)) == 182 or prof2 and select(7, GetProfessionInfo(prof2)) == 182 then
			for mountID in next, self.herbalismMounts do
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
	local bfaLocations = {
		[1642] = true, -- Зандалар
		[1643] = true, -- Кул-Тирас
		[1718] = true, -- Назжатар
	}
	function mounts:isFlyLocation(instanceID)
		if self.continentsGround[instanceID]
		-- Битва за Азерот
		or bfaLocations[instanceID] and not IsSpellKnown(278833)
		then return false end

		return true
	end
end


function mounts:isWaterWalkLocation()
	return self.mapFlags and self.mapFlags.waterWalkOnly or false
end


function mounts:isDragonridable()
	self.dragonridingMounts = C_MountJournal.GetCollectedDragonridingMounts()
	if #self.dragonridingMounts > 0 then
		local _, spellID, _,_, isUsable = C_MountJournal.GetMountInfoByID(self.dragonridingMounts[1])
		return isUsable and IsUsableSpell(spellID)
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
	}
	function mounts:setFlags()
		self:setMountsList()
		local flags = self.sFlags
		local groundSpellKnown, flySpellKnown = self:getSpellKnown()
		local modifier = self.modifier() or flags.forceModifier
		local isFloating = self:isFloating()
		local isFlyableLocation = flySpellKnown
		                          and (IsFlyableArea() or isFlyableOverride[self.instanceID])
		                          and self:isFlyLocation(self.instanceID)
		                          and not (self.mapFlags and self.mapFlags.groundOnly)

		flags.isSubmerged = IsSubmerged()
		flags.isIndoors = IsIndoors()
		flags.inVehicle = UnitInVehicle("player")
		flags.isMounted = IsMounted()
		flags.groundSpellKnown = groundSpellKnown
		flags.swimming = flags.isSubmerged
		                 and not (modifier or isFloating)
		flags.isVashjir = self.mapVashjir[self.mapInfo.mapID]
		flags.isDragonridable = self:isDragonridable()
		                        and (not modifier or flags.isSubmerged)
		flags.fly = isFlyableLocation
		            and (not modifier or flags.isSubmerged)
		flags.waterWalk = isFloating
		                  or not isFlyableLocation and modifier
		                  or self:isWaterWalkLocation()
		flags.herb = self.herbMount and (not self.config.herbMountsOnZones
		                                 or self.mapFlags and self.mapFlags.herbGathering)
		flags.targetMount = self:getTargetMount()
	end
end


function mounts:errorSummon()
	UIErrorsFrame:AddMessage(InCombatLockdown() and SPELL_FAILED_AFFECTING_COMBAT or ERR_MOUNT_NO_FAVORITES, 1, .1, .1, 1)
end


function mounts:setSummonList()
	self.summonList = nil
	local flags = self.sFlags
	if flags.inVehicle then
		VehicleExit()
	elseif flags.isMounted then
		Dismount()
	elseif not flags.groundSpellKnown then
		if not (flags.swimming and self:setUsableIDs(self.list.swimming, self.list.swimmingWeight) or self:setUsableIDs(self.lowLevel, self.db.mountsWeight)) then
			self:errorSummon()
		end
	-- repair mounts
	elseif not ((flags.repair and not flags.fly or flags.flyableRepair and flags.fly) and self:setUsableIDs(self.usableRepairMounts, self.db.mountsWeight))
	-- target's mount
	and not (flags.targetMount and (C_MountJournal.SummonByID(flags.targetMount) or true))
	-- swimming
	and not (flags.swimming
		and (flags.isVashjir
			and self:setUsableIDs(self.swimmingVashjir, self.db.mountsWeight)
			or self:setUsableIDs(self.list.swimming, self.list.swimmingWeight)))
	-- herbMount
	and not (flags.herb and self:setUsableIDs(self.herbalismMounts, self.db.mountsWeight))
	-- dragonridable
	and not (flags.isDragonridable and self:summonDragonridable())
	-- fly
	and not (flags.fly and self:setUsableIDs(self.list.fly, self.list.flyWeight))
	-- ground
	and not self:setUsableIDs(self.list.ground, self.list.groundWeight)
	and not self:setUsableIDs(self.list.fly, self.list.flyWeight)
	and not self:setUsableIDs(self.lowLevel, self.db.mountsWeight) then
		self:errorSummon()
	end
end


function mounts:init()
	SLASH_MOUNTSJOURNAL1 = "/mount"
	SlashCmdList["MOUNTSJOURNAL"] = function(msg)
		if not SecureCmdOptionParse(msg) then return end
		self.sFlags.forceModifier = nil
		self:setFlags()
		self:setSummonList()
		self:summon()
	end
end