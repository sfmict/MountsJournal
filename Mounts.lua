local addon = ...
local mounts = CreateFrame("Frame", "MountsJournal")
local interface = select(4, GetBuildInfo())


mounts:SetScript("OnEvent", function(self, event, ...)
	if mounts[event] then
		mounts[event](self, ...)
	else
		mounts:setMountsList()
	end
end)
mounts:RegisterEvent("ADDON_LOADED")


function mounts:ADDON_LOADED(addonName)
	if addonName == addon then
		self:UnregisterEvent("ADDON_LOADED")

		MountsJournalDB = MountsJournalDB or {}
		MountsJournalDB.fly = MountsJournalDB.fly or {}
		MountsJournalDB.ground = MountsJournalDB.ground or {}
		MountsJournalDB.swimming = MountsJournalDB.swimming or {}
		MountsJournalDB.zoneMounts = MountsJournalDB.zoneMounts or {}
		MountsJournalDB.config = MountsJournalDB.config or {}
		MountsJournalDB.filters = MountsJournalDB.filters or {}
		mounts.config = MountsJournalDB.config
		mounts.filters = MountsJournalDB.filters
		if mounts.config.waterWalkInstance == nil then
			mounts.config.waterWalkInstance = true
		end
		if mounts.config.waterWalkList == nil or type(mounts.config.waterWalkList) ~= "table" then
			mounts.config.waterWalkList = {
				[1456] = true, -- Око Азшары
				[1771] = true, -- Тол Дагор
			}
		end
		if mounts.config.waterWalkExpeditionList == nil or type(mounts.config.waterWalkExpeditionList) ~= "table" then
			mounts.config.waterWalkExpeditionList = {}
		end

		MountsJournalChar = MountsJournalChar or {}
		MountsJournalChar.fly =  MountsJournalChar.fly or {}
		MountsJournalChar.ground = MountsJournalChar.ground or {}
		MountsJournalChar.swimming = MountsJournalChar.swimming or {}
		MountsJournalChar.zoneMounts = MountsJournalChar.zoneMounts or {}

		mounts.macroTable = {
			SHAMAN = {
				macroEnable = true,
				macroAlways = false,
				-- macro = "/cast Призрачный волк",
			},
			DRUID = {
				macroEnable = true,
				macroAlways = false,
				-- macro = "/cast [indoors,noswimming]Облик кошки(Смена облика);Походный облик(Смена облика)",
			},
		}

		mounts.sFlags = {}
		mounts.defMountsListID = MapUtil.GetMapParentInfo(MapUtil.GetDisplayableMapForPlayer(), Enum.UIMapType.Cosmic, true).mapID
		mounts:setMountsListPerChar()
		mounts.swimmingVashjir = {
			373, -- Вайш'ирский морской конек
		}
		mounts.lowLevel = {
			678, -- Механоцикл с шофером
			679, -- Анжинерский чоппер с водителем
		}
		mounts.waterWalk = {
			488, -- Багровый водный долгоног
			449, -- Лазурный водный долгоног
		}
		mounts.herbalismMounts = {
			522, -- Небесный голем
		}

		mounts.expeditions = {
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
		mounts.continentsGround = {
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

		mounts.mapVashjir = {
			[201] = true, -- Лес Келп’тар
			[203] = true, -- Вайш'ир
			[204] = true, -- Бездонные глубины
			[205] = true, -- Мерцающий простор
		}

		self:RegisterEvent("ZONE_CHANGED")
		self:RegisterEvent("ZONE_CHANGED_INDOORS")
		self:RegisterEvent("ZONE_CHANGED_NEW_AREA")

		mounts:setModifier(mounts.config.modifier)
		mounts:setHandleWaterJump(mounts.config.waterJump)
		mounts:init()
	end
end


function mounts:inTable(table, item)
	for key, value in pairs(table) do
		if value == item then
			return key
		end
	end
	return false
end


function mounts:setModifier(modifier)
	if mounts:inTable({"ALT", "CTRL", "SHIFT"}, modifier) then
		mounts.config.modifier = modifier
		mounts.modifier = modifier == "ALT" and IsAltKeyDown or modifier == "CTRL" and IsControlKeyDown or IsShiftKeyDown
		return
	end
	mounts.config.modifier = "ALT"
	mounts.modifier = IsAltKeyDown
end


function mounts:setMountsList()
	local mapInfo = C_Map.GetMapInfo(MapUtil.GetDisplayableMapForPlayer())
	local zoneMounts = mounts.db.zoneMounts
	mounts.mapFlags = nil
	while mapInfo do
		local list = zoneMounts[mapInfo.mapID]
		if list then
			if not mounts.mapFlags then mounts.mapFlags = list.flags end
			if #list.fly + #list.ground + #list.swimming ~= 0 then
				mounts.list = zoneMounts[mapInfo.mapID]
				return
			end
		end
		mapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
	end
	mounts.list = {
		fly = mounts.db.fly,
		ground = mounts.db.ground,
		swimming = mounts.db.swimming,
	}
end


function mounts:setMountsListPerChar(perChar)
	if perChar ~= nil then
		MountsJournalChar.enable = perChar
		mounts.perChar = perChar
	elseif MountsJournalChar and MountsJournalChar.enable then
		mounts.perChar = true
	end

	mounts.db = mounts.perChar and MountsJournalChar or MountsJournalDB
	mounts:setMountsList()
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
	for _, mountID in pairs(ids) do
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
	if mounts.config.useHerbMounts then
		local prof1, prof2 = GetProfessions()
		if (prof1 and select(7, GetProfessionInfo(prof1)) == 182 or prof2 and select(7, GetProfessionInfo(prof2)) == 182) then
			for _, mountID in pairs(mounts.herbalismMounts) do
				if select(5, C_MountJournal.GetMountInfoByID(mountID)) then
					return true
				end
			end
		end
	end
	return false
end


function mounts:waterWalkMountsExists()
	if mounts.config.waterWalkAll or mounts:isWaterWalkLocation(select(8, GetInstanceInfo())) then
		for _, mountID in pairs(mounts.waterWalk) do
			if select(5, C_MountJournal.GetMountInfoByID(mountID)) then
				return true
			end
		end
	end
	return false
end


function mounts:summonListOr(ids, flyable)
	if mounts.sFlags.herb and mounts:summon(mounts.herbalismMounts) then -- herbMount
		return true
	end

	return mounts:summon(ids)
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
		if mounts.continentsGround[instance]
			or mounts.expeditions[instance]
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
	if mounts.config.waterWalkInstance and mounts.config.waterWalkList[instance]
	or mounts.config.waterWalkExpedition and mounts.config.waterWalkExpeditionList[instance]
	or mounts.mapFlags and mounts.mapFlags.waterWalkOnly then
		return true
	end

	return false
end


function mounts:setFlags()
	local groundSpellKnown, flySpellKnown = mounts:getSpellKnown()
	local modifier = mounts:modifier()
	local isSubmerged = IsSubmerged()
	local isFloating = mounts:isFloating()
	local instance = select(8, GetInstanceInfo())
	local isFlyableLocation = flySpellKnown and IsFlyableArea() and mounts:isFlyLocation(instance) and not (mounts.mapFlags and mounts.mapFlags.groundOnly)
	
	local flags = mounts.sFlags
	flags.inVehicle = UnitInVehicle("player")
	flags.IsMounted = IsMounted()
	flags.groundSpellKnown = groundSpellKnown
	flags.swimming = isSubmerged
						  and not modifier
						  and not isFloating
	flags.fly = isFlyableLocation
					and (not modifier or isSubmerged)
	flags.waterWalk = mounts.config.waterWalkAll
							or isFloating
							or not isFlyableLocation and modifier
							or mounts:isWaterWalkLocation(instance)
	flags.herb = mounts:herbMountsExists()
end


function mounts:errorSummon()
	UIErrorsFrame:AddMessage(InCombatLockdown() and SPELL_FAILED_AFFECTING_COMBAT or ERR_MOUNT_NO_FAVORITES, 1, .1, .1, 1)
end


function mounts:init()
	SLASH_MOUNTSJOURNAL1 = "/mount"
	SlashCmdList["MOUNTSJOURNAL"] = function()
		local flags = mounts.sFlags
		if flags.inVehicle then
			VehicleExit()
		elseif flags.IsMounted then
			if not mounts.lastUseTime or GetTime() - mounts.lastUseTime > 0.5 then
				Dismount()
			end
		elseif not flags.groundSpellKnown then
			if not mounts:summon(mounts.lowLevel) then mounts:errorSummon() end
		-- swimming
		elseif not (flags.swimming
			and (mounts.mapVashjir[C_Map.GetBestMapForUnit("player")]
				and mounts:summon(mounts.swimmingVashjir)
				or mounts:summon(mounts.list.swimming)))
		-- fly
		and not (flags.fly and mounts:summonListOr(mounts.list.fly, true))
		-- water walk
		and not (flags.waterWalk and mounts:summon(mounts.waterWalk))
		-- ground
		and not mounts:summonListOr(mounts.list.ground)
		and not mounts:summon(mounts.list.fly)
		and not mounts:summon(mounts.waterWalk)
		and not mounts:summon(mounts.lowLevel) then
			mounts:errorSummon()
		end
	end
end