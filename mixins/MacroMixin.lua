local type, pairs, rawget, GetItemCount, GetUnitSpeed, IsFalling, InCombatLockdown, GetTime, C_Item, GetInventoryItemID, GetInventoryItemLink, EquipItemByName, IsMounted, IsSubmerged, C_UnitAuras = type, pairs, rawget, GetItemCount, GetUnitSpeed, IsFalling, InCombatLockdown, GetTime, C_Item, GetInventoryItemID, GetInventoryItemLink, EquipItemByName, IsMounted, IsSubmerged, C_UnitAuras
local macroFrame = CreateFrame("FRAME")


macroFrame:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)
macroFrame:RegisterEvent("PLAYER_LOGIN")


function macroFrame:PLAYER_LOGIN()
	self.PLAYER_LOGIN = nil
	self.mounts = MountsJournal
	self.config = self.mounts.config
	self.sFlags = self.mounts.sFlags
	self.macrosConfig = self.config.macrosConfig
	self.charMacrosConfig = self.mounts.charDB.macrosConfig
	-- remove outdated items
	self.charMacrosConfig.itemSlot16 = nil
	self.charMacrosConfig.itemSlot17 = nil
	-- ---------------------
	self.class = select(2, UnitClass("player"))
	self.fishingRodID = 133755
	local _,_, raceID = UnitRace("player")

	local function loadFunc(funcStr)
		local loadedFunc, err = loadstring(funcStr)
		if err then
			geterrorhandler()(err)
		else
			return loadedFunc()
		end
	end

	local classOptionMacro = ""
	local defMacro = ""

	if raceID == 22 then
		defMacro = defMacro..[[
			local IsSpellKnown, IsUsableSpell, random = IsSpellKnown, IsUsableSpell, random
		]]
	end

	if self.class == "PRIEST" or self.class == "MAGE" then
		classOptionMacro = classOptionMacro..[[
			local IsFalling, GetTime, C_UnitAuras = IsFalling, GetTime, C_UnitAuras
		]]
	elseif self.class == "MONK" then
		classOptionMacro = classOptionMacro..[[
			local IsFalling, GetTime, GetUnitSpeed, C_UnitAuras = IsFalling, GetTime, GetUnitSpeed, C_UnitAuras
		]]
	elseif self.class == "DRUID" then
		classOptionMacro = classOptionMacro..[[
			local GetShapeshiftForm, GetShapeshiftFormInfo, GetSpecialization, GetTime = GetShapeshiftForm, GetShapeshiftFormInfo, GetSpecialization, GetTime

			local function getFormSpellID()
				local shapeshiftIndex = GetShapeshiftForm()
				if shapeshiftIndex > 0 then
					local _,_,_, spellID = GetShapeshiftFormInfo(shapeshiftIndex)
					return spellID
				end
			end

			local specializationSpellIDs = {
				24858, -- moonkin
				768, -- cat
				5487, -- bear
			}
		]]
		defMacro = defMacro..[[
			local GetShapeshiftFormID = GetShapeshiftFormID
		]]
	end

	classOptionMacro = classOptionMacro..[[
		return function(self)
	]]
	defMacro = defMacro..[[
		return function(self)
			local macro
	]]

	if self.class == "PRIEST" then
		classOptionMacro = classOptionMacro..[[
			-- 111759 - Levitation
			if self.classConfig.useLevitation and not self.magicBroom and IsFalling() then
				if GetTime() - (self.lastUseClassSpellTime or 0) < .5 then
					return ""
				elseif C_UnitAuras.GetPlayerAuraBySpellID(111759) then
					return "/cancelaura "..self:getSpellName(111759)
				else
					self.lastUseClassSpellTime = GetTime()
					return "/cast [@player]"..self:getSpellName(111759)
				end
			end
		]]
	elseif self.class == "DEATHKNIGHT" then
		defMacro = defMacro..[[
			if self.classConfig.usePathOfFrost
			and (not self.classConfig.useOnlyInWaterWalkLocation or self.sFlags.waterWalk)
			and not self.sFlags.swimming
			and not self.sFlags.fly
			and not self.sFlags.isDragonridable
			then
				macro = self:addLine(macro, "/cast "..self:getSpellName(3714)) -- Path of Frost
			end
		]]
	elseif self.class == "SHAMAN" then
		defMacro = defMacro..[[
			if self.classConfig.useWaterWalking
			and (not self.classConfig.useOnlyInWaterWalkLocation or self.sFlags.waterWalk)
			and not self.sFlags.swimming
			and not self.sFlags.fly
			and not self.sFlags.isDragonridable
			then
				macro = self:addLine(macro, "/cast [@player]"..self:getSpellName(546)) -- Water Walking
			end
		]]
	elseif self.class == "MAGE" then
		classOptionMacro = classOptionMacro..[[
			-- 130 - Slow Fall
			if self.classConfig.useSlowFall and not self.magicBroom and IsFalling() then
				if GetTime() - (self.lastUseClassSpellTime or 0) < .5 then
					return ""
				elseif C_UnitAuras.GetPlayerAuraBySpellID(130) then
					return "/cancelaura "..self:getSpellName(130)
				else
					self.lastUseClassSpellTime = GetTime()
					return "/cast [@player]"..self:getSpellName(130)
				end
			end
		]]
	elseif self.class == "MONK" then
		classOptionMacro = classOptionMacro..[[
			-- 125883 - Zen Flight
			if self.classConfig.useZenFlight and not self.magicBroom then
				if IsFalling() then
					self.lastUseClassSpellTime = GetTime()
					return "/cast "..self:getSpellName(125883)
				elseif C_UnitAuras.GetPlayerAuraBySpellID(125883) then
					return GetTime() - (self.lastUseClassSpellTime or 0) < .5 and "" or GetUnitSpeed("player") > 0 and "/cancelaura "..self:getSpellName(125883)
				end
			end
		]]
	elseif self.class == "DRUID" then
		classOptionMacro = classOptionMacro..[[
			-- DRUID LAST FORM
			-- 768 - cat form
			-- 783 - travel form
			-- 24858 - moonkin form
			if self.classConfig.useLastDruidForm then
				local spellID = getFormSpellID()

				if self.classConfig.useDruidFormSpecialization then
					self.charMacrosConfig.lastDruidFormSpellID = specializationSpellIDs[GetSpecialization()]
				end

				if self.charMacrosConfig.lastDruidFormSpellID
				and spellID ~= 24858
				and (self.sFlags.isMounted
					  or self.sFlags.inVehicle
					  or spellID == 783
					  or self.sFlags.isIndoors and spellID == 768) then
					return self:addLine(self:getDismountMacro(), "/cast "..self:getSpellName(self.charMacrosConfig.lastDruidFormSpellID))
				end

				if not self.classConfig.useDruidFormSpecialization then
					if spellID and spellID ~= 783 then
						self.charMacrosConfig.lastDruidFormSpellID = spellID
						self.lastDruidFormTime = GetTime()
					elseif not spellID and GetTime() - (self.lastDruidFormTime or 0) > 1 then
						self.charMacrosConfig.lastDruidFormSpellID = nil
					end
				end
			end
		]]
		defMacro = defMacro..[[
			local curFormID = GetShapeshiftFormID()
			-- 1:CAT, 3:STAG, 5:BEAR, 36:TREANT
			if curFormID == 1 or curFormID == 3 or curFormID == 5 or curFormID == 36 then
				macro = self:addLine(macro, "/cancelform")
			end
		]]
	end

	classOptionMacro = classOptionMacro..[[
		end
	]]
	defMacro = defMacro..[[
			if self.magicBroom then
				if self.magicBroom.itemID then
					macro = self:addLine(macro, "/use item:"..self.magicBroom.itemID) -- USE ITEM BROOM
				elseif self.magicBroom.mountID then
					local name = C_MountJournal.GetMountInfoByID(self.magicBroom.mountID)
					macro = self:addLine(macro, "/use "..name) -- USE MOUNT BROOM
				end
				self.lastUseTime = GetTime()
			else
				self.mounts:setSummonList()
	]]
	if raceID == 22 then
		defMacro = defMacro..[[
				if self.classConfig.useRunningWild
				and IsSpellKnown(87840)
				and IsUsableSpell(87840)
				and (self.mounts.summonList == self.mounts.list.ground and random(self.mounts.weight + (self.classConfig.runningWildsummoningChance or 100)) > self.mounts.weight
					or self.mounts.summonList == self.mounts.lowLevel
					or not self.sFlags.fly and self.mounts.summonList == self.mounts.list.fly)
				then
					macro = self:addLine(macro, "/cast "..self:getSpellName(87840))
				else
					macro = self:addLine(macro, "/run MountsJournal:summon()")
				end
		]]
	else
		defMacro = defMacro..[[
				macro = self:addLine(macro, "/run MountsJournal:summon()")
		]]
	end
	defMacro = defMacro..[[
			end
			return macro
		end
	]]

	self.getClassOptionMacro = loadFunc(classOptionMacro)
	self.getDefMacro = loadFunc(defMacro)

	self:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
	self:RegisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")

	self:refresh()
	self:getClassMacro(self.class, function() self:refresh() end)
end


function macroFrame:setMacro()
	self.macro = nil
	if self.classConfig.macroEnable then
		self.macro = self.classConfig.macro or self:getClassMacro()
	end
end


function macroFrame:setCombatMacro()
	self.combatMacro = nil
	if self.classConfig.combatMacroEnable then
		self.combatMacro = self.classConfig.combatMacro or self:getClassMacro()
	end
end


function macroFrame:refresh()
	self.classConfig = self.charMacrosConfig.enable and self.charMacrosConfig or self.macrosConfig[self.class]
	self:setMacro()
	self:setCombatMacro()
end


function macroFrame:addLine(text, line)
	if text ~= nil and #text > 0 then
		return text.."\n"..line
	else
		return line
	end
end


do
	local spellCache = {}
	function macroFrame:getSpellName(spellID, cb)
		if spellCache[spellID] then
			return spellCache[spellID]
		else
			local name = GetSpellInfo(spellID)
			if C_Spell.IsSpellDataCached(spellID) then
				local subText = GetSpellSubtext(spellID)
				if #subText > 0 then
					name = name.."("..subText..")"
				end
				spellCache[spellID] = name
			elseif cb then
				SpellEventListener:AddCallback(spellID, cb)
			end
			return name
		end
	end
end


function macroFrame:getDismountMacro()
	return self:addLine("/leavevehicle [vehicleui]", "/dismount [mounted]")
end


do
	local function getClassDefFunc(spellID)
		return function(self, ...)
			local spellName = self:getSpellName(spellID, ...)
			if spellName then
				return "/cast "..spellName
			end
		end
	end


	local classFunc = {
		WARRIOR = function(self, ...)
			local spellName = self:getSpellName(6544, ...) -- Heroic Leap
			if spellName then
				return "/cast [@cursor]"..spellName
			end
		end,
		PALADIN = getClassDefFunc(190784), -- Devine Steed
		HUNTER = getClassDefFunc(186257), -- Aspect of the Cheetah
		ROGUE = getClassDefFunc(2983), -- Sprint
		PRIEST = function(self, ...)
			local spellName = self:getSpellName(121536, ...) -- Angelic Feather
			if spellName then
				return "/cast [@player]"..spellName
			end
		end,
		DEATHKNIGHT = getClassDefFunc(218999), -- Wraith Walk
		SHAMAN = getClassDefFunc(2645), -- Ghost Wolf
		MAGE = getClassDefFunc(1953), -- Blink
		WARLOCK = getClassDefFunc(111400), -- Burning Rush
		MONK = getClassDefFunc(109132), -- Roll
		DRUID = function(self, ...)
			local catForm = self:getSpellName(768, ...)
			local travelForm = self:getSpellName(783, ...)

			if catForm and travelForm then
				return "/cast [indoors,noswimming]"..catForm..";"..travelForm
			end
		end,
		DEMONHUNTER = getClassDefFunc(192611), -- Fel Rush
	}


	function macroFrame:getClassMacro(class, ...)
		local macro = self:getDismountMacro()

		local classFunc = classFunc[class or self.class]
		if type(classFunc) == "function" then
			local text = classFunc(self, ...)
			if type(text) == "string" and #text > 0 then
				macro = self:addLine(macro, text)
			end
		end

		return macro
	end
end


function macroFrame:PLAYER_REGEN_ENABLED()
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	EquipItemByName(self.fishingRodID)
end


function macroFrame:ITEM_UNLOCKED(bag, slot)
	if slot
	and not GetInventoryItemID("player", 28)
	and C_Container.GetContainerItemID(bag, slot) == self.fishingRodID
	then
		if InCombatLockdown() then
			self:RegisterEvent("PLAYER_REGEN_ENABLED")
		else
			EquipItemByName(self.fishingRodID)
		end
	elseif bag == 28
	and GetInventoryItemID("player", 28)
	then
		self:UnregisterEvent("ITEM_UNLOCKED")
	end
end


local function isNotFishingBuff()
	return not C_UnitAuras.GetPlayerAuraBySpellID(394009)
end


function macroFrame:getFishingRodMacro()
	if self.fishingSlotID == self.fishingRodID then
		if self.charMacrosConfig.itemSlot28 then
			EquipItemByName(self.charMacrosConfig.itemSlot28)
			self.charMacrosConfig.itemSlot28 = nil
		elseif isNotFishingBuff() then
			local action = EquipmentManager_UnequipItemInSlot(28)
			if action and EquipmentManager_RunAction(action) then
				self:RegisterEvent("ITEM_UNLOCKED")
			end
		end
	else
		self.charMacrosConfig.itemSlot28 = GetInventoryItemLink("player", 28)
		EquipItemByName(self.fishingRodID)
	end

	return ""
end


function macroFrame:autoEquip()
	if self.config.useUnderlightAngler and self.config.autoUseUnderlightAngler and GetItemCount(self.fishingRodID) > 0 and not InCombatLockdown() then
		local curFishingRod = GetInventoryItemID("player", 28)
		if IsSubmerged() then
			if curFishingRod ~= self.fishingRodID then
				self.charMacrosConfig.itemSlot28 = GetInventoryItemLink("player", 28)
				EquipItemByName(self.fishingRodID)
			elseif isNotFishingBuff() then
				local action = EquipmentManager_UnequipItemInSlot(28)
				if action and EquipmentManager_RunAction(action) then
					self:RegisterEvent("ITEM_UNLOCKED")
				end
			end
		elseif IsMounted() and curFishingRod == self.fishingRodID and self.charMacrosConfig.itemSlot28 then
			EquipItemByName(self.charMacrosConfig.itemSlot28)
			self.charMacrosConfig.itemSlot28 = nil
		end
	end
end
macroFrame.PLAYER_MOUNT_DISPLAY_CHANGED = macroFrame.autoEquip
macroFrame.MOUNT_JOURNAL_USABILITY_CHANGED = macroFrame.autoEquip


do
	local function isBroomUsable(data)
		if data.mountID then
			local _,_,_,_, isUsable = C_MountJournal.GetMountInfoByID(data.mountID)
			return isUsable
		elseif data.itemID then
			return GetItemCount(data.itemID) > 0
		end
	end


	function macroFrame:getBroomData()
		if not self.config.useMagicBroom
		or not self.mounts.calendar:isHolidayActive(324) -- Hallow's End
		or self.sFlags.isDragonridable
		or self.sFlags.targetMount
		or not self.sFlags.groundSpellKnown
		or self.sFlags.herb
		or self.sFlags.swimming
		then return end

		local data = self.config.broomSelectedMount
		if data then
			return isBroomUsable(data) and data
		else
			local usable = {}
			for i = 1, #self.mounts.magicBrooms do
				local data = self.mounts.magicBrooms[i]
				if isBroomUsable(data) then usable[#usable + 1] = data end
			end

			if #usable == 0 then return
			else return usable[random(#usable)] end
		end
	end
end


function macroFrame:getMacro()
	self.mounts:setFlags()

	-- UNDERLIGHT ANGLER
	if self.config.useUnderlightAngler and GetItemCount(self.fishingRodID) > 0 then
		self.fishingSlotID = GetInventoryItemID("player", 28)
		if self.sFlags.swimming
			and not self.sFlags.isVashjir
			and isNotFishingBuff()
		or self.fishingSlotID == self.fishingRodID
			and self.charMacrosConfig.itemSlot28
			and not self.sFlags.isSubmerged
			and GetUnitSpeed("player") > 0
		then
			return self:getFishingRodMacro()
		end
	end

	-- MAGIC BROOM IS USABLE
	self.magicBroom = self:getBroomData()

	-- CLASS OPTIONS
	local macro = self:getClassOptionMacro()
	if macro then return macro end

	-- EXIT VEHICLE
	if self.sFlags.inVehicle then
		macro = "/leavevehicle"
	-- DISMOUNT
	elseif self.sFlags.isMounted then
		if not self.lastUseTime or GetTime() - self.lastUseTime > .5 then
			macro = "/dismount"
		end
	-- CLASSMACRO
	elseif self.macro and
		(self.class == "DRUID" and self.classConfig.useMacroAlways and not (self.classConfig.useIfNotDragonridable and self.sFlags.isDragonridable)
		or not self.magicBroom and (self.sFlags.isIndoors or GetUnitSpeed("player") > 0 or IsFalling()))
	then
		macro = self.macro
	-- MOUNT
	else
		macro = self:getDefMacro()
	end

	return macro or ""
end


function macroFrame:getCombatMacro()
	local macro

	if self.combatMacro then
		macro = self:addLine(macro, self.combatMacro)
	elseif self.macro and self.class == "DRUID" and self.classConfig.useMacroAlways then
		macro = self:addLine(macro, self.macro)
	else
		macro = self:addLine(macro, "/mount")
	end

	return macro
end


function MountsJournalUtil.getClassMacro(...)
	return macroFrame:getClassMacro(...)
end


function MountsJournalUtil.refreshMacro()
	macroFrame:refresh()
end


MJMacroMixin = {}


function MJMacroMixin:onEvent(event, ...)
	self[event](self, ...)
end


function MJMacroMixin:onLoad()
	self.mounts = MountsJournal
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
end


function MJMacroMixin:preClick(button, down)
	self.mounts.sFlags.forceModifier = self.forceModifier
	self.mounts.sFlags.forceFly = self.forceFly
	if InCombatLockdown() or down ~= GetCVarBool("ActionButtonUseKeyDown") then return end
	self:SetAttribute("macrotext", macroFrame:getMacro())
end


function MJMacroMixin:PLAYER_REGEN_DISABLED()
	self:SetAttribute("macrotext", macroFrame:getCombatMacro())
end