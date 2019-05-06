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
if interface >= 80200 then mounts:RegisterEvent("MOUNT_EQUIPMENT_APPLY_RESULT") end


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

		mounts.defMountsListID = 946
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

		if interface >= 80200 then mounts:MOUNT_EQUIPMENT_APPLY_RESULT() end
		mounts:setModifier(mounts.config.modifier)
		mounts:setHandleWaterJump(mounts.config.waterJump)
		mounts:init()
	end
end


function mounts:MOUNT_EQUIPMENT_APPLY_RESULT()
	mounts.waterWalkEquipment = C_MountJournal.GetAppliedMountEquipmentID() == 168416 -- Водные долгоноги рыболова
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
	mounts.flags = nil
	while mapInfo do
		local list = zoneMounts[mapInfo.mapID]
		if list then
			if not mounts.flags then mounts.flags = list.flags end
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
	local ground, fly = false, false

	if IsSpellKnown(33388) -- Верховая езда (ученик)
	or IsSpellKnown(33391) -- Верховая езда (подмастерье)
	then
		ground = true
	end

	if IsSpellKnown(34090) -- Верховая езда (умелец)
	or IsSpellKnown(34091) -- Верховая езда (искусник)
	or IsSpellKnown(90265) -- Мастер верховой езды
	then
		ground, fly = true, true
	end

	return ground, fly
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
	if mounts.config.useHerbMounts then
		local prof1, prof2 = GetProfessions()
		if (prof1 and select(7, GetProfessionInfo(prof1)) == 182
		or prof2 and select(7, GetProfessionInfo(prof2)) == 182)
		and mounts:summon(mounts.herbalismMounts) then -- herbalism
			return true
		end
	end

	if (not mounts.config.waterWalkAll or flyable)
	and mounts.config.useMagicBroom
	and GetItemCount(37011) ~= 0 then
		mounts.lastUseTime = GetTime()
		return true -- magic broom
	end
	
	return mounts:summon(ids)
end


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


function mounts:isWaterWalkLocation(instance)
	if mounts.config.waterWalkInstance and mounts.config.waterWalkList[instance]
	or mounts.config.waterWalkExpedition and mounts.config.waterWalkExpeditionList[instance]
	or mounts.flags and mounts.flags.waterWalkOnly then
		return true
	end

	return false
end


function mounts:errorSummon()
	UIErrorsFrame:AddMessage(InCombatLockdown() and SPELL_FAILED_AFFECTING_COMBAT or ERR_MOUNT_NO_FAVORITES, 1, .1, .1, 1)
end


function mounts:init()
	SLASH_MOUNTSJOURNAL1 = "/mount"
	SlashCmdList["MOUNTSJOURNAL"] = function()
		if IsMounted() then
			if not mounts.lastUseTime or GetTime() - mounts.lastUseTime > 0.5 then
				Dismount()
			end
		else
			local isGroundSpell, isFlySpell = mounts:getSpellKnown()
			if not isGroundSpell then
				if not mounts:summon(mounts.lowLevel) then mounts:errorSummon() end
			-- swimming
			elseif mounts:isFloating()
				or mounts.modifier()
				or not IsSubmerged()
				or not (mounts.mapVashjir[C_Map.GetBestMapForUnit("player")] and mounts:summon(mounts.swimmingVashjir))
				and not mounts:summon(mounts.list.swimming) then
				-- fly
				local instance = select(8, GetInstanceInfo())
				local isFlyableLocation = isFlySpell and IsFlyableArea() and mounts:isFlyLocation(instance) and not (mounts.flags and mounts.flags.groundOnly)
				if (not isFlyableLocation
					or mounts.modifier() and not IsSubmerged()
					or not mounts:summonListOr(mounts.list.fly, true))
				-- water walk
				and not ((mounts.config.waterWalkAll
						or mounts:isFloating()
						or not isFlyableLocation and mounts.modifier()
						or mounts:isWaterWalkLocation(instance))
					and not mounts.waterWalkEquipment
					and mounts:summon(mounts.waterWalk))
				-- ground
				and not mounts:summonListOr(mounts.list.ground)
				and not mounts:summon(mounts.waterWalk)
				and not mounts:summon(mounts.list.fly)
				and not mounts:summon(mounts.lowLevel) then
					mounts:errorSummon()
				end
			end
		end
	end
end