local addon = ...
local util = MountsJournalUtil
local mounts = CreateFrame("Frame", "MountsJournal")


mounts:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		self[event](self, ...)
	else
		self:setMountsList()
	end
end)
mounts:RegisterEvent("ADDON_LOADED")


function mounts:ADDON_LOADED(addonName)
	if addonName == addon then
		self:UnregisterEvent("ADDON_LOADED")

		local mapInfo = MapUtil.GetMapParentInfo(C_Map.GetFallbackWorldMapID(), Enum.UIMapType.Cosmic, true)
		self.defMountsListID = mapInfo and mapInfo.mapID or 946 -- WORLD

		MountsJournalDB = MountsJournalDB or {}
		MountsJournalDB.fly = MountsJournalDB.fly or {}
		MountsJournalDB.ground = MountsJournalDB.ground or {}
		MountsJournalDB.swimming = MountsJournalDB.swimming or {}
		MountsJournalDB.zoneMounts = MountsJournalDB.zoneMounts or {}
		MountsJournalDB.zoneMounts[self.defMountsListID] = nil
		MountsJournalDB.filters = MountsJournalDB.filters or {}
		MountsJournalDB.config = MountsJournalDB.config or {}
		self.filters = MountsJournalDB.filters
		self.config = MountsJournalDB.config
		self.config.macrosConfig = self.config.macrosConfig or {}
		for i = 1, GetNumClasses() do
			local _,className = GetClassInfo(i)
			self.config.macrosConfig[className] = self.config.macrosConfig[className] or {}
		end

		MountsJournalChar = MountsJournalChar or {}
		MountsJournalChar.fly =  MountsJournalChar.fly or {}
		MountsJournalChar.ground = MountsJournalChar.ground or {}
		MountsJournalChar.swimming = MountsJournalChar.swimming or {}
		MountsJournalChar.zoneMounts = MountsJournalChar.zoneMounts or {}
		MountsJournalChar.zoneMounts[self.defMountsListID] = nil
		MountsJournalChar.macrosConfig = MountsJournalChar.macrosConfig or {}

		-- Рудименты
		self.config.waterWalkAll = nil
		self.config.waterWalkList = nil
		self.config.waterWalkInstance = nil
		self.config.waterWalkExpedition = nil
		self.config.waterWalkExpeditionList = nil
		self.waterWalk = nil

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
		self.expeditions = {
			[1813] = 981, -- Экспедиция: Руины Ун'гола
			[1814] = 1336, -- Экспедиция: Тихая Сень
			[1879] = 1337, -- Экспедиция: Йорундалль
			[1882] = 1034, -- Экспедиция: Зеленые дебри
			[1883] = 1037, -- Экспедиция: Шепчущий риф
			[1892] = 1033, -- Экспедиция: Гниющая трясина
			[1893] = 1036, -- Экспедиция: Оковы Ужаса
			[1897] = 1035, -- Экспедиция: Раскаленный остров
			[1898] = 1032, -- Экспедиция: Паучья лощина
		}
		self.continentsGround = {
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

		self:RegisterEvent("NEW_WMO_CHUNK")
		self:RegisterEvent("ZONE_CHANGED")
		self:RegisterEvent("ZONE_CHANGED_INDOORS")
		self:RegisterEvent("ZONE_CHANGED_NEW_AREA")

		self:setMountsListPerChar()
		self:setModifier(self.config.modifier)
		self:setHandleWaterJump(self.config.waterJump)
		self:init()
	end
end


function mounts:setModifier(modifier)
	if util.inTable({"ALT", "CTRL", "SHIFT"}, modifier) then
		self.config.modifier = modifier
		self.modifier = modifier == "ALT" and IsAltKeyDown or modifier == "CTRL" and IsControlKeyDown or IsShiftKeyDown
		return
	end
	self.config.modifier = "ALT"
	self.modifier = IsAltKeyDown
end


function mounts:setMountsList()
	local mapInfo = C_Map.GetMapInfo(MapUtil.GetDisplayableMapForPlayer())
	local zoneMounts = self.db.zoneMounts
	self.mapFlags = nil

	local function getMountsRelationList(mapID)
		local list = zoneMounts[mapID]
		if list and list.listFromID then
			return getMountsRelationList(list.listFromID)
		end
		return list
	end

	while mapInfo do
		local list = zoneMounts[mapInfo.mapID]
		if list then
			if not self.mapFlags then self.mapFlags = list.flags end
			local relationList = getMountsRelationList(mapInfo.mapID)
			if relationList then
				if #relationList.fly + #relationList.ground + #relationList.swimming ~= 0 then
					self.list = relationList
					return
				end
			end
		end
		mapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
	end
	self.list = {
		fly = self.db.fly,
		ground = self.db.ground,
		swimming = self.db.swimming,
	}
end


function mounts:setMountsListPerChar(perChar)
	if perChar ~= nil then
		MountsJournalChar.enable = perChar
		self.perChar = perChar
	elseif MountsJournalChar and MountsJournalChar.enable then
		self.perChar = true
	end

	self.db = self.perChar and MountsJournalChar or MountsJournalDB
	self:setMountsList()
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


function mounts:summon(ids)
	local usableIDs = {}
	for _,mountID in ipairs(ids) do
		if select(5, C_MountJournal.GetMountInfoByID(mountID)) then
			tinsert(usableIDs, mountID)
		end
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


function mounts:herbMountsExists()
	if self.config.useHerbMounts then
		local prof1, prof2 = GetProfessions()
		if (prof1 and select(7, GetProfessionInfo(prof1)) == 182 or prof2 and select(7, GetProfessionInfo(prof2)) == 182) then
			for _,mountID in ipairs(self.herbalismMounts) do
				if select(5, C_MountJournal.GetMountInfoByID(mountID)) then
					return true
				end
			end
		end
	end
	return false
end


function mounts:summonListOr(ids)
	if self.sFlags.herb and self:summon(self.herbalismMounts) then -- herbMount
		return true
	end

	return self:summon(ids)
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
	}
	function mounts:isFlyLocation(instance)
		if self.continentsGround[instance]
			or self.expeditions[instance]
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


function mounts:isWaterWalkLocation(instance)
	return self.mapFlags and self.mapFlags.waterWalkOnly or false
end


function mounts:setFlags()
	local groundSpellKnown, flySpellKnown = self:getSpellKnown()
	local modifier = self.modifier()
	local isSubmerged = IsSubmerged()
	local isFloating = self:isFloating()
	local instance = select(8, GetInstanceInfo())
	local isFlyableLocation = flySpellKnown 
									  and IsFlyableArea()
									  and self:isFlyLocation(instance)
									  and not (self.mapFlags and self.mapFlags.groundOnly)
	
	local flags = self.sFlags
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
							or self:isWaterWalkLocation(instance)
	flags.herb = self:herbMountsExists()
end


function mounts:errorSummon()
	UIErrorsFrame:AddMessage(InCombatLockdown() and SPELL_FAILED_AFFECTING_COMBAT or ERR_MOUNT_NO_FAVORITES, 1, .1, .1, 1)
end


function mounts:init()
	SLASH_MOUNTSJOURNAL1 = "/mount"
	SlashCmdList["MOUNTSJOURNAL"] = function(msg)
		if msg ~= "doNotSetFlags" then self:setFlags() end
		local flags = self.sFlags
		if flags.inVehicle then
			VehicleExit()
		elseif flags.isMounted then
			Dismount()
		elseif not flags.groundSpellKnown then
			if not self:summon(self.lowLevel) then self:errorSummon() end
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