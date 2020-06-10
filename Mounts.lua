local addon = ...
local C_MountJournal, C_Map, MapUtil, next, tinsert, random, C_PetJournal = C_MountJournal, C_Map, MapUtil, next, tinsert, random, C_PetJournal
local util = MountsJournalUtil
local mounts = CreateFrame("Frame", "MountsJournal")


mounts:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
mounts:RegisterEvent("ADDON_LOADED")
mounts:RegisterEvent("PLAYER_LOGIN")


function mounts:ADDON_LOADED(addonName)
	if addonName == addon then
		self:UnregisterEvent("ADDON_LOADED")

		local mapInfo = MapUtil.GetMapParentInfo(C_Map.GetFallbackWorldMapID(), Enum.UIMapType.Cosmic, true)
		self.defMountsListID = mapInfo and mapInfo.mapID or 946 -- WORLD

		MountsJournalDB = MountsJournalDB or {}
		self.globalDB = MountsJournalDB
		self.globalDB.fly = self.globalDB.fly or {}
		self.globalDB.ground = self.globalDB.ground or {}
		self.globalDB.swimming = self.globalDB.swimming or {}
		self.globalDB.zoneMounts = self.globalDB.zoneMounts or {}
		self.globalDB.petForMount = self.globalDB.petForMount or {}
		self.globalDB.mountTags = self.globalDB.mountTags or {}
		self.globalDB.filters = self.globalDB.filters or {}
		self.globalDB.config = self.globalDB.config or {}
		self.globalDB.mountAnimations = self.globalDB.mountAnimations or {}
		self.globalDB.mountsProfiles = self.globalDB.mountsProfiles or {}
		self.filters = self.globalDB.filters
		self.profiles = self.globalDB.mountsProfiles
		self.config = self.globalDB.config
		if self.config.mountDescriptionToggle == nil then
			self.config.mountDescriptionToggle = true
		end
		self.config.macrosConfig = self.config.macrosConfig or {}
		for i = 1, GetNumClasses() do
			local _, className = GetClassInfo(i)
			self.config.macrosConfig[className] = self.config.macrosConfig[className] or {}
		end

		MountsJournalChar = MountsJournalChar or {}
		self.charDB = MountsJournalChar
		self.charDB.macrosConfig = self.charDB.macrosConfig or {}
		self.charDB.profileBySpecialization = self.charDB.profileBySpecialization or {}

		-- Рудименты
		self:setOldChanges()

		-- Списки
		self.swimmingVashjir = {
			373, -- Вайш'ирский морской конек
		}
		self.lowLevel = {
			678, -- Механоцикл с шофером
			679, -- Анжинерский чоппер с водителем
		}
		self.herbalismMounts = {
			522, -- Небесный голем
		}

		self.sFlags = {}
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
		}
		-- 1170, -- Горгронд - сценарий маг'харов

		self.mapVashjir = {
			[201] = true, -- Лес Келп’тар
			[203] = true, -- Вайш'ир
			[204] = true, -- Бездонные глубины
			[205] = true, -- Мерцающий простор
		}
	end
end


function mounts:compareVersion(v1, v2)
	v1 = v1:gsub("^(.*)-.*$", "%1")
	v2 = v2:gsub("^(.*)-.*$", "%1")
	v1 = {strsplit(".", v1)}
	v2 = {strsplit(".", v2)}
	for i = 1, min(#v1, #v2) do
		v1[i] = tonumber(v1[i]) or 0
		v2[i] = tonumber(v2[i]) or 0
		if v1[i] > v2[i] then return true end
		if v1[i] < v2[i] then return false end
	end
	return #v1 > #v2
end


function mounts:setOldChanges()
	--@do-not-package@
	if self.globalDB.lastAddonVersion == "@project-version@" and self.charDB.lastAddonVersion == "@project-version@" then return end
	--@end-do-not-package@
	if self:compareVersion("8.3.2", self.globalDB.lastAddonVersion or "") then
		self.config.waterWalkAll = nil
		self.config.waterWalkList = nil
		self.config.waterWalkInstance = nil
		self.config.waterWalkExpedition = nil
		self.config.waterWalkExpeditionList = nil

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

		self.globalDB.fly = setMounts(self.globalDB.fly)
		self.globalDB.ground = setMounts(self.globalDB.ground)
		self.globalDB.swimming = setMounts(self.globalDB.swimming)
		for _, list in next, self.globalDB.zoneMounts do
			list.fly = setMounts(list.fly)
			list.ground = setMounts(list.ground)
			list.swimming = setMounts(list.swimming)
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
	self.globalDB.lastAddonVersion = GetAddOnMetadata(addon, "Version")

	if self:compareVersion("8.3.2", self.charDB.lastAddonVersion or "") then
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
					fly =  setMounts(self.charDB.fly or {}),
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
	self.charDB.lastAddonVersion = GetAddOnMetadata(addon, "Version")
end


function mounts:PLAYER_LOGIN()
	-- INIT
	self:setDB()
	self:setModifier(self.config.modifier)
	self:setHandleWaterJump(self.config.waterJump)
	self:setHerbMount()
	self:init()

	-- MAP CHANGED
	self:RegisterEvent("NEW_WMO_CHUNK")
	self:RegisterEvent("ZONE_CHANGED")
	self:RegisterEvent("ZONE_CHANGED_INDOORS")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")

	-- PROFESSION CHANGED OR MOUNT LEARNED
	self:RegisterEvent("SKILL_LINES_CHANGED")
	self:RegisterEvent("COMPANION_LEARNED")

	-- SPEC CHANGED
	self:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")

	-- PET USABLE
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
end


function mounts:PLAYER_REGEN_DISABLED()
	self:UnregisterEvent("UNIT_SPELLCAST_START")
end


function mounts:PLAYER_REGEN_ENABLED()
	self:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
end


function mounts:UNIT_SPELLCAST_START(_,_, spellID)
	local petID = self.petForMount[spellID]
	if petID then
		local groupType = util.getGroupType()
		if self.config.noPetInRaid and groupType == "raid"
		or self.config.noPetInGroup and groupType == "group" then
			return
		end

		if type(petID) == "number" then
			C_PetJournal.SummonRandomPet(petID == 1)
		elseif C_PetJournal.PetIsSummonable(petID) and C_PetJournal.GetSummonedPetGUID() ~= petID then
			C_PetJournal.SummonPetByGUID(petID)
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
	local mapInfo = C_Map.GetMapInfo(MapUtil.GetDisplayableMapForPlayer())
	local zoneMounts = self.zoneMounts
	self.mapFlags = nil

	while mapInfo and mapInfo.mapID ~= self.defMountsListID do
		local list = zoneMounts[mapInfo.mapID]
		if list then
			if not self.mapFlags then self.mapFlags = list.flags end
			while list and list.listFromID do
				list = zoneMounts[list.listFromID]
			end
			if list and #list.fly + #list.ground + #list.swimming ~= 0 then
				self.list = list
				return
			end
		end
		mapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
	end
	self.list = self.defList
end
mounts.NEW_WMO_CHUNK = mounts.setMountsList
mounts.ZONE_CHANGED = mounts.setMountsList
mounts.ZONE_CHANGED_INDOORS = mounts.setMountsList
mounts.ZONE_CHANGED_NEW_AREA = mounts.setMountsList


function mounts:setDB()
	for i = 1, GetNumSpecializations() do
		local profileName = self.charDB.profileBySpecialization[i]
		if profileName ~= nil and not self.profiles[profileName] then
			self.charDB.profileBySpecialization[i] = nil
		end
	end

	if self.charDB.currentProfileName and not self.profiles[self.charDB.currentProfileName] then
		self.charDB.currentProfileName = nil
	end

	local currentProfileName
	if self.charDB.profileBySpecialization.enable then
		currentProfileName = self.charDB.profileBySpecialization[GetSpecialization()]
	else
		currentProfileName = self.charDB.currentProfileName
	end

	self.db = currentProfileName and self.profiles[currentProfileName] or self.globalDB
	self.zoneMounts = self.db.zoneMountsFromProfile and self.globalDB.zoneMounts or self.db.zoneMounts
	self.defList = {
		fly = self.db.fly,
		ground = self.db.ground,
		swimming = self.db.swimming,
	}
	self.petForMount = self.db.petListFromProfile and self.globalDB.petForMount or self.db.petForMount

	self:setMountsList()
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


function mounts:summon(ids)
	local usableIDs = {}
	for mountID in next, ids do
		local _,_,_,_, isUsable = C_MountJournal.GetMountInfoByID(mountID)
		if isUsable then tinsert(usableIDs, mountID) end
	end
	if #usableIDs ~= 0 then
		C_MountJournal.SummonByID(usableIDs[random(#usableIDs)])
		return true
	else
		return false
	end
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

	return false, false
end


function mounts:setHerbMount()
	if self.config.useHerbMounts then
		local prof1, prof2 = GetProfessions()
		if (prof1 and select(7, GetProfessionInfo(prof1)) == 182 or prof2 and select(7, GetProfessionInfo(prof2)) == 182) then
			for _, mountID in ipairs(self.herbalismMounts) do
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
mounts.COMPANION_LEARNED = mounts.setHerbMount


function mounts:summonListOr(ids)
	return self.sFlags.herb and self:summon(self.herbalismMounts) or self:summon(ids)  -- herbMount
end


do
	local draenorLocations = {
		[1116] = true,
		[1152] = true,
		[1330] = true,
		[1153] = true,
		[1154] = true,
		[1158] = true,
		[1331] = true,
		[1159] = true,
		[1160] = true,
	}
	local bfaLocations = {
		[1642] = true, -- Зандалар
		[1643] = true, -- Кул-Тирас
		[1718] = true, -- Назжатар
	}
	function mounts:isFlyLocation(instance)
		if self.continentsGround[instance]
			-- Дренор
			or draenorLocations[instance] and not IsSpellKnown(191645)
			-- Расколотые острова
			or instance == 1220 and not IsSpellKnown(233368)
			-- Битва за Азерот
			or bfaLocations[instance] and not IsSpellKnown(278833)
		then return false end

		return true
	end
end


function mounts:isWaterWalkLocation()
	return self.mapFlags and self.mapFlags.waterWalkOnly or false
end


function mounts:setFlags()
	local flags = self.sFlags
	local groundSpellKnown, flySpellKnown = self:getSpellKnown()
	local modifier = self.modifier() or flags.forceModifier
	local isSubmerged = IsSubmerged()
	local isFloating = self:isFloating()
	local instance = select(8, GetInstanceInfo())
	local isFlyableLocation = flySpellKnown
									  and IsFlyableArea()
									  and self:isFlyLocation(instance)
									  and not (self.mapFlags and self.mapFlags.groundOnly)

	flags.isIndoors = IsIndoors()
	flags.inVehicle = UnitInVehicle("player")
	flags.isMounted = IsMounted()
	flags.groundSpellKnown = groundSpellKnown
	flags.swimming = isSubmerged
						  and not (modifier or isFloating)
	flags.fly = isFlyableLocation
					and (not modifier or isSubmerged)
	flags.waterWalk = isFloating
							or not isFlyableLocation and modifier
							or self:isWaterWalkLocation()
	flags.herb = self.herbMount and (not self.config.herbMountsOnZones
												or self.mapFlags and self.mapFlags.herbGathering)
end


function mounts:errorSummon()
	UIErrorsFrame:AddMessage(InCombatLockdown() and SPELL_FAILED_AFFECTING_COMBAT or ERR_MOUNT_NO_FAVORITES, 1, .1, .1, 1)
end


function mounts:init()
	SLASH_MOUNTSJOURNAL1 = "/mount"
	SlashCmdList["MOUNTSJOURNAL"] = function(msg)
		local flags = self.sFlags
		if msg ~= "doNotSetFlags" then
			flags.forceModifier = nil
			self:setFlags()
		end
		if flags.inVehicle then
			VehicleExit()
		elseif flags.isMounted then
			Dismount()
		elseif not flags.groundSpellKnown then
			if not (flags.swimming and self:summon(self.list.swimming)
					  or self:summon(self.lowLevel)) then
				self:errorSummon()
			end
		-- swimming
		elseif not (flags.swimming
						and (self.mapVashjir[C_Map.GetBestMapForUnit("player")]
							  and self:summon(self.swimmingVashjir)
							  or self:summon(self.list.swimming)))
		-- fly
		and not (flags.fly and self:summonListOr(self.list.fly))
		-- ground
		and not self:summonListOr(self.list.ground)
		and not self:summon(self.list.fly)
		and not self:summon(self.lowLevel) then
			self:errorSummon()
		end
	end
end