local mounts = CreateFrame("Frame", "MountsJournal")


mounts:SetScript("OnEvent", function(self, event, ...)
	if mounts[event] then
		mounts[event](self, ...)
	end
end)
mounts:RegisterEvent("ADDON_LOADED")


function mounts:ADDON_LOADED(addonName)
	if addonName == "MountsJournal" then
		self:UnregisterEvent("ADDON_LOADED")

		MountsJournalDB = MountsJournalDB or {}
		MountsJournalDB.fly = MountsJournalDB.fly or {}
		MountsJournalDB.ground = MountsJournalDB.ground or {}
		MountsJournalDB.swimming = MountsJournalDB.swimming or {}
		MountsJournalDB.config = MountsJournalDB.config or {}
		mounts.config = MountsJournalDB.config
		if mounts.config.waterWalkInstance == nil then
			mounts.config.waterWalkInstance = true
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

		mounts.continensGround = {
			1463, -- Внешняя область Хельхейма
			1514, -- Скитающийся остров
		}

		mounts:setModifier(mounts.config.modifier)

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
		["swimming"]= mounts.perChar and MountsJournalChar.swimming or MountsJournalDB.swimming
	}
end


function mounts:summon(ids)
	local usableIDs = {}
	for index, mountID in pairs(ids) do
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


function mounts:isFlyLocation()
	local instance = select(8, GetInstanceInfo())

	if mounts:inTable(mounts.continensGround, instance)
	-- Дренор
	or mounts:inTable({1116, 1152, 1330, 1153, 1154, 1158, 1331, 1159, 1160}, instance) and not IsSpellKnown(191645)
	-- Расколотые острова
	or instance == 1220 and not IsSpellKnown(233368) then return false end

	return true
end


function mounts:isWaterWalkLocation()
	local instance = select(8, GetInstanceInfo())
	local locations = {
		1456, -- Око Азшары
	}

	if mounts:inTable(locations, instance) then return true end
	return false
end


function mounts:init()
	SLASH_MOUNTSJOURNAL1 = "/mount"
	SlashCmdList["MOUNTSJOURNAL"] = function()
		if IsMounted() then
			Dismount()
		else
			local isGroundSpell, isFlySpell = mounts:getSpellKnown()
			if not isGroundSpell then
				if not mounts:summon(mounts.lowLevel) then C_MountJournal.SummonByID(0) end
			elseif IsSwimming() and not mounts.modifier() then
				if not mounts:summon(mounts.swimmingVashjir) and not mounts:summon(mounts.list.swimming) then
					C_MountJournal.SummonByID(0)
				end
			elseif isFlySpell and IsFlyableArea() and (IsSwimming() or not mounts.modifier()) and mounts:isFlyLocation() then
				if not mounts:summon(mounts.list.fly) then C_MountJournal.SummonByID(0) end
			else
				if not ((mounts.config.waterWalkAll or mounts.modifier() and IsSwimming() or mounts.config.waterWalkInstance and mounts:isWaterWalkLocation()) and mounts:summon(mounts.waterWalk)) and not mounts:summon(mounts.list.ground) then
					C_MountJournal.SummonByID(0)
				end
			end
		end
	end
end