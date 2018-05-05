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

		mounts.fly = MountsJournalDB.fly
		mounts.ground = MountsJournalDB.ground
		mounts.swimming = MountsJournalDB.swimming
		mounts.swimmingVashjir = {
			373, -- Вайш'ирский морской конек
		}
		mounts.lowLevel = {
			678, -- Механоцикл с шофером
			679, -- Анжинерский чоппер с водителем
		}

		mounts.continensGround = {
			1463, -- Внешняя область Хельхейма
			1514, -- Скитающийся остров
		}

		mounts.config = MountsJournalDB.config
		mounts.config.modifier = mounts.config.modifier or "ALT"
		mounts:setModifier(mounts.config.modifier)

		mounts:init()
	end
end


function mounts:setModifier(modifier)
	if mounts:inTable({"ALT", "CTRL", "SHIFT"}, modifier) then
		mounts.config.modifier = modifier
		mounts.modifier = modifier == "ALT" and IsAltKeyDown or modifier == "CTRL" and IsControlKeyDown or IsShiftKeyDown
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
	local continent = select(8, GetInstanceInfo())
	if mounts:inTable(mounts.continensGround, continent) then return false end

	-- Дренор
	if mounts:inTable({1116, 1152, 1330, 1153, 1154, 1158, 1331, 1159, 1160}, continent) and not IsSpellKnown(191645)
	-- Расколотые острова
	or continent == 1220 and not IsSpellKnown(233368) then return false end

	return true
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
				if not mounts:summon(mounts.swimmingVashjir) and not mounts:summon(mounts.swimming) then
					C_MountJournal.SummonByID(0)
				end
			elseif isFlySpell and IsFlyableArea() and (IsSwimming() or not mounts.modifier()) and mounts:isFlyLocation() then
				if not mounts:summon(mounts.fly) then C_MountJournal.SummonByID(0) end
			else
				if not mounts:summon(mounts.ground) then C_MountJournal.SummonByID(0) end
			end
		end
	end
end