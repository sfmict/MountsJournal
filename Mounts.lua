local addon = ...
local C_MountJournal, C_Map, MapUtil, next, tinsert, wipe, random, C_PetJournal, IsSpellKnown, GetTime, IsFlyableArea, IsSubmerged, GetInstanceInfo, IsIndoors, UnitInVehicle, IsMounted, InCombatLockdown, GetSpellCooldown = C_MountJournal, C_Map, MapUtil, next, tinsert, wipe, random, C_PetJournal, IsSpellKnown, GetTime, IsFlyableArea, IsSubmerged, GetInstanceInfo, IsIndoors, UnitInVehicle, IsMounted, InCombatLockdown, GetSpellCooldown
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
		self.globalDB.mountTags = self.globalDB.mountTags or {}
		self.globalDB.filters = self.globalDB.filters or {}
		self.globalDB.config = self.globalDB.config or {}
		self.globalDB.mountAnimations = self.globalDB.mountAnimations or {}
		self.globalDB.defProfile = self.globalDB.defProfile or {}
		self.globalDB.mountsProfiles = self.globalDB.mountsProfiles or {}
		self.globalDB.help = self.globalDB.help or {}

		self.defProfile = self.globalDB.defProfile
		self.defProfile.fly = self.defProfile.fly or {}
		self.defProfile.ground = self.defProfile.ground or {}
		self.defProfile.swimming = self.defProfile.swimming or {}
		self.defProfile.zoneMounts = self.defProfile.zoneMounts or {}
		self.defProfile.petForMount = self.defProfile.petForMount or {}
		self.profiles = self.globalDB.mountsProfiles
		self.filters = self.globalDB.filters
		self.help = self.globalDB.help
		self.config = self.globalDB.config
		if self.config.mountDescriptionToggle == nil then
			self.config.mountDescriptionToggle = true
		end
		if self.config.arrowButtonsBrowse == nil then
			self.config.arrowButtonsBrowse = true
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
		self.charDB.profileBySpecializationPVP = self.charDB.profileBySpecializationPVP or {}

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
	end
end


function mounts:compareVersion(v1, v2)
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
	local currentVersion = GetAddOnMetadata(addon, "Version")
	--@do-not-package@
	if currentVersion == "@project-version@" then currentVersion = "9.0.8" end
	--@end-do-not-package@

	--IF < 8.3.2 GLOBAL
	if self:compareVersion("8.3.2", self.globalDB.lastAddonVersion or "") then
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
	if self:compareVersion("9.0.8", self.globalDB.lastAddonVersion or "") then
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

	-- SET LAST GLOBAL VERSION
	self.globalDB.lastAddonVersion = currentVersion

	-- IF < 8.3.2 CHAR
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

	-- MAP CHANGED
	-- self:RegisterEvent("NEW_WMO_CHUNK")
	-- self:RegisterEvent("ZONE_CHANGED")
	-- self:RegisterEvent("ZONE_CHANGED_INDOORS")
	-- self:RegisterEvent("ZONE_CHANGED_NEW_AREA")

	-- INSTANCE INFO UPDATE
	self:RegisterEvent("PLAYER_ENTERING_WORLD")

	-- PROFESSION CHANGED OR MOUNT LEARNED
	self:RegisterEvent("SKILL_LINES_CHANGED")
	self:RegisterEvent("COMPANION_LEARNED")

	-- SPEC CHANGED
	self:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")

	-- PET USABLE
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")

	-- AUTO ADD MOUNT
	self:RegisterEvent("NEW_MOUNT_ADDED")
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

		local start, duration = GetSpellCooldown(61304)
		if duration ~= 0 then duration = start + duration - GetTime() end

		C_Timer.After(duration, function()
			if type(petID) == "number" then
				C_PetJournal.SummonRandomPet(petID == 1)
			elseif C_PetJournal.PetIsSummonable(petID) and C_PetJournal.GetSummonedPetGUID() ~= petID then
				C_PetJournal.SummonPetByGUID(petID)
			end
		end)
	end
end


function mounts:NEW_MOUNT_ADDED(mountID)
	local _,_,_,_, mountTypeExtra = C_MountJournal.GetMountInfoExtraByID(mountID)
	local mountType = util.mountTypes[mountTypeExtra]
	if mountType == 1 then
		mountType = "fly"
	elseif mountType == 2 then
		mountType = "ground"
	else
		mountType = "swimming"
	end

	if self.defProfile.autoAddNewMount then
		self.defProfile[mountType][mountID] = true
	end

	for _, profile in next, self.profiles do
		if profile.autoAddNewMount then
			profile[mountType][mountID] = true
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


function mounts:PLAYER_ENTERING_WORLD()
	local _, instanceType, _,_,_,_,_, instanceID = GetInstanceInfo()
	self.instanceID = instanceID
	local pvp = instanceType == "arena" or instanceType == "pvp"
	if self.pvp ~= pvp then
		self.pvp = pvp
		self:setDB()
	end
end


function mounts:setMountsList()
	local mapInfo = C_Map.GetMapInfo(MapUtil.GetDisplayableMapForPlayer())
	local zoneMounts = self.zoneMounts
	self.mapID = mapInfo.mapID
	self.mapFlags = nil
	self.list = nil

	while mapInfo and mapInfo.mapID ~= self.defMountsListID do
		local list = zoneMounts[mapInfo.mapID]
		if list then
			if not self.mapFlags and list.flags.enableFlags then
				self.mapFlags = list.flags
			end
			if not self.list then
				while list and list.listFromID do
					list = zoneMounts[list.listFromID]
				end
				if list and (next(list.fly) or next(list.ground) or next(list.swimming)) then
					self.list = list
				end
			end
			if self.list and self.mapFlags then return end
		end
		mapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
	end
	if not self.list then
		self.list = self.db
	end
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

	local currentProfileName
	if self.pvp and self.charDB.profileBySpecializationPVP.enable then
		currentProfileName = self.charDB.profileBySpecializationPVP[GetSpecialization()]
	elseif self.charDB.profileBySpecialization.enable then
		currentProfileName = self.charDB.profileBySpecialization[GetSpecialization()]
	else
		currentProfileName = self.charDB.currentProfileName
	end

	self.db = currentProfileName and self.profiles[currentProfileName] or self.defProfile
	self.zoneMounts = self.db.zoneMountsFromProfile and self.defProfile.zoneMounts or self.db.zoneMounts
	self.petForMount = self.db.petListFromProfile and self.defProfile.petForMount or self.db.petForMount

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


do
	local mountIDFromTarget, UnitBuff = {}, UnitBuff
	function mounts:summonTarget()
		if self.config.copyMountTarget then
			local i = 1
			repeat
				local _,_,_,_,_,_,_,_,_, spellID = UnitBuff("target", i)
				if spellID then
					local mountID = C_MountJournal.GetMountFromSpell(spellID)
					if mountID then
						mountIDFromTarget[mountID] = true
						local isSummoned = self:summon(mountIDFromTarget)
						mountIDFromTarget[mountID] = nil
						return isSummoned
					end
					i = i + 1
				end
			until not spellID
		end
	end
end


do
	local usableIDs = {}
	function mounts:summon(ids)
		wipe(usableIDs)
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
mounts.COMPANION_LEARNED = mounts.setHerbMount


function mounts:summonListOr(ids)
	return self.sFlags.herb and self:summon(self.herbalismMounts) or self:summon(ids) -- herbMount
end


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
		local flags = self.sFlags
		local groundSpellKnown, flySpellKnown = self:getSpellKnown()
		local modifier = self.modifier() or flags.forceModifier
		local isSubmerged = IsSubmerged()
		local isFloating = self:isFloating()
		local isFlyableLocation = flySpellKnown
										  and (IsFlyableArea() or isFlyableOverride[self.instanceID])
										  and self:isFlyLocation(self.instanceID)
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
end


function mounts:errorSummon()
	UIErrorsFrame:AddMessage(InCombatLockdown() and SPELL_FAILED_AFFECTING_COMBAT or ERR_MOUNT_NO_FAVORITES, 1, .1, .1, 1)
end


function mounts:init()
	SLASH_MOUNTSJOURNAL1 = "/mount"
	SlashCmdList["MOUNTSJOURNAL"] = function(msg)
		self:setMountsList()
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
		-- target's mount
		elseif not self:summonTarget()
		-- swimming
		and not (flags.swimming
						and (self.mapVashjir[self.mapID]
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