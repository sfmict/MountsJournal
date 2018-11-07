local addon = ...
local mounts = CreateFrame("Frame", "MountsJournal")


mounts:SetScript("OnEvent", function(self, event, ...)
	if mounts[event] then
		mounts[event](self, ...)
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

		mounts:setMountsList()
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

		mounts.continensGround = {
			[1107] = true, -- Разлом Зловещего Шрама
			[1463] = true, -- Внешняя область Хельхейма
			[1514] = true, -- Скитающийся остров
			[1688] = true, -- Мертвые копи
			[1760] = true, -- Лордерон
			[1763] = true, -- Атал'Дазар
			[1813] = true, -- Экспедиция: Руины Ун'гола
			[1876] = true, -- Фронт Арати (Орда)
			[1882] = true, -- Экспедиция: Зеленые дебри
			[1883] = true, -- Экспедиция: Шепчущий риф
			[1892] = true, -- Экспедиция: Гниющая трясина
			[1893] = true, -- Экспедиция: Оковы Ужаса
			[1897] = true, -- Экспедиция: Раскаленный остров
			[1898] = true, -- Экспедиция: Паучья лощина
		}
		mounts.mapVashjir = {
			[201] = true, -- Лес Келп’тар
			[203] = true, -- Вайш'ир
			[204] = true, -- Бездонные глубины
			[205] = true, -- Мерцающий простор
		}
		-- 1170, -- Горгронд - сценарий маг'харов

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


function mounts:setMountsList(perChar)
	if perChar ~= nil then
		MountsJournalChar.enable = perChar
		mounts.perChar = perChar
	elseif MountsJournalChar and MountsJournalChar.enable then
		mounts.perChar = true
	end

	mounts.list = {
		["fly"] = mounts.perChar and MountsJournalChar.fly or MountsJournalDB.fly,
		["ground"] = mounts.perChar and MountsJournalChar.ground or MountsJournalDB.ground,
		["swimming"] = mounts.perChar and MountsJournalChar.swimming or MountsJournalDB.swimming
	}
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


function mounts:summonListOr(ids)
	if mounts.config.useHerbMounts then
		local prof1, prof2 = GetProfessions()
		if (prof1 and select(7, GetProfessionInfo(prof1)) == 182 or prof2 and select(7, GetProfessionInfo(prof2)) == 182) and mounts:summon(mounts.herbalismMounts) then -- herbalism
			return true
		end
	end

	if not mounts.config.waterWalkAll and mounts.config.useMagicBroom and GetItemCount(37011) ~= 0 then
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
function mounts:isFlyLocation(instance)
	if mounts.continensGround[instance]
	-- Дренор
	or draenorLocations[instance] and not IsSpellKnown(191645)
	-- Расколотые острова
	or instance == 1220 and not IsSpellKnown(233368) then return false end

	return true
end


function mounts:isWaterWalkLocation(instance)
	if mounts.config.waterWalkInstance and mounts.config.waterWalkList[instance]
	or mounts.config.waterWalkExpedition and mounts.config.waterWalkExpeditionList[instance] then
		return true
	end

	return false
end


function mounts:errorNoFavorites()
	UIErrorsFrame:AddMessage(format("|cffff0000%s|r", ERR_MOUNT_NO_FAVORITES))
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
				if not mounts:summon(mounts.lowLevel) then mounts:errorNoFavorites() end
			elseif mounts:isFloating() or mounts.modifier() or not IsSubmerged() or not (mounts.mapVashjir[C_Map.GetBestMapForUnit("player")] and mounts:summon(mounts.swimmingVashjir)) and not mounts:summon(mounts.list.swimming) then -- swimming
				local instance = select(8, GetInstanceInfo())
				local isFlyableLocation = isFlySpell and IsFlyableArea() and mounts:isFlyLocation(instance)
				if (not isFlyableLocation or mounts.modifier() and not IsSubmerged() or not mounts:summonListOr(mounts.list.fly)) -- fly
				and not ((mounts.config.waterWalkAll or mounts:isFloating() or not isFlyableLocation and mounts.modifier() or mounts:isWaterWalkLocation(instance)) and mounts:summon(mounts.waterWalk)) -- water walk
				and not mounts:summonListOr(mounts.list.ground) and not mounts:summon(mounts.list.fly) and not mounts:summon(mounts.lowLevel) then -- ground
					mounts:errorNoFavorites()
				end
			end
		end
	end
end