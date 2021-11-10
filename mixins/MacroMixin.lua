local type, pairs, rawget, GetItemCount, GetUnitSpeed, IsFalling, InCombatLockdown, GetTime, C_Item, GetInventoryItemID, GetInventoryItemLink, EquipItemByName, IsMounted, IsSubmerged = type, pairs, rawget, GetItemCount, GetUnitSpeed, IsFalling, InCombatLockdown, GetTime, C_Item, GetInventoryItemID, GetInventoryItemLink, EquipItemByName, IsMounted, IsSubmerged
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
	self.class = select(2, UnitClass("player"))
	self.fishingRodID = 133755
	self.broomID = 37011
	self.itemName = setmetatable({}, {__index = function(self, itemID)
		if C_Item.DoesItemExistByID(itemID) then
			local item = Item:CreateFromItemID(itemID)
			if item:IsItemDataCached() then
				self[itemID] = item:GetItemName()
			else
				item:ContinueOnItemLoad(function()
					self[itemID] = item:GetItemName()
				end)
			end
			return rawget(self, itemID)
		end
	end})

	local function loadFunc(name, funcStr)
		local loadedFunc, err = loadstring(funcStr)
		if err then
			geterrorhandler()(err)
		else
			self[name] = loadedFunc()
		end
	end

	local classOptionMacro = ""
	local defMacro = ""

	if self.class == "PRIEST" or self.class == "MAGE" then
		classOptionMacro = classOptionMacro..[[
			local IsFalling, GetTime = IsFalling, GetTime
		]]
	elseif self.class == "MONK" then
		classOptionMacro = classOptionMacro..[[
			local IsFalling, GetTime, GetUnitSpeed = IsFalling, GetTime, GetUnitSpeed
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
				if GetTime() - (self.lastUseClassSpellTime or 0) < .5 then return "" end
				local i = 1
				repeat
					local _,_,_,_,_,_,_,_,_, spellID = UnitBuff("player", i)
					if spellID == 111759 then
						return "/cancelaura "..self:getSpellName(111759)
					end
					i = i + 1
				until not spellID
				self.lastUseClassSpellTime = GetTime()
				return "/cast [@player]"..self:getSpellName(111759)
			end
		]]
	elseif self.class == "DEATHKNIGHT" then
		defMacro = defMacro..[[
			if self.classConfig.usePathOfFrost
			and (not self.classConfig.useOnlyInWaterWalkLocation or self.sFlags.waterWalk)
			and not self.sFlags.swimming
			and not self.sFlags.fly then
				macro = self:addLine(macro, "/cast "..self:getSpellName(3714)) -- Path of Frost
			end
		]]
	elseif self.class == "SHAMAN" then
		defMacro = defMacro..[[
			if self.classConfig.useWaterWalking
			and (not self.classConfig.useOnlyInWaterWalkLocation or self.sFlags.waterWalk)
			and not self.sFlags.swimming
			and not self.sFlags.fly then
				macro = self:addLine(macro, "/cast [@player]"..self:getSpellName(546)) -- Water Walking
			end
		]]
	elseif self.class == "MAGE" then
		classOptionMacro = classOptionMacro..[[
			-- 130 - Slow Fall
			if self.classConfig.useSlowFall and not self.magicBroom and IsFalling() then
				if GetTime() - (self.lastUseClassSpellTime or 0) < .5 then return "" end
				local i = 1
				repeat
					local _,_,_,_,_,_,_,_,_, spellID = UnitBuff("player", i)
					if spellID == 130 then
						return "/cancelaura "..self:getSpellName(130)
					end
					i = i + 1
				until not spellID
				self.lastUseClassSpellTime = GetTime()
				return "/cast [@player]"..self:getSpellName(130)
			end
		]]
	elseif self.class == "MONK" then
		classOptionMacro = classOptionMacro..[[
			-- 125883 - Zen Flight
			if self.classConfig.useZenFlight and not self.magicBroom then
				if IsFalling() then
					self.lastUseClassSpellTime = GetTime()
					return "/cast "..self:getSpellName(125883)
				end

				local i, isBuffed = 1
				repeat
					local _,_,_,_,_,_,_,_,_, spellID = UnitBuff("player", i)
					if spellID == 125883 then
						isBuffed = true
						break
					end
					i = i + 1
				until not spellID

				if isBuffed then
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
					self.lastDruidFormSpellID = specializationSpellIDs[GetSpecialization()]
				end

				if self.lastDruidFormSpellID
				and spellID ~= 24858
				and (self.sFlags.isMounted
					  or self.sFlags.inVehicle
					  or spellID == 783
					  or self.sFlags.isIndoors and spellID == 768) then
					return self:addLine(self:getDismountMacro(), "/cast "..self:getSpellName(self.lastDruidFormSpellID))
				end

				if not self.classConfig.useDruidFormSpecialization then
					if spellID and spellID ~= 783 then
						self.lastDruidFormSpellID = spellID
						self.lastDruidFormTime = GetTime()
					elseif not spellID and GetTime() - (self.lastDruidFormTime or 0) > 1 then
						self.lastDruidFormSpellID = nil
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
				macro = self:addLine(macro, "/use "..self.itemName[self.broomID]) -- MAGIC BROOM
				self.lastUseTime = GetTime()
			else
				macro = self:addLine(macro, "/mount doNotSetFlags")
			end
			return macro
		end
	]]

	loadFunc("getClassOptionMacro", classOptionMacro)
	loadFunc("getDefMacro", defMacro)

	self:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
	self:RegisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")

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
			local shield = self:getSpellName(17, ...) -- Power Word: Shield
			local feather = self:getSpellName(121536, ...) -- Angelic Feather

			if shield and feather then
				return "/cast [spec:1,talent:2/3,@player][spec:2,talent:2/3,@player]"..feather..";[@player]"..shield
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


function macroFrame:PLAYER_EQUIPMENT_CHANGED(slot, isEmpty)
	if slot == 16 and self.fishingRodID ~= GetInventoryItemID("player", 16)
	or slot == 17 and not isEmpty then
		self.charMacrosConfig["itemSlot"..slot] = nil
	end
end


function macroFrame:getFishingRodMacro()
	local macro

	if self.weaponID == self.fishingRodID then
		local link = self.charMacrosConfig.itemSlot16
		if link then
			macro = "/equipslot 16 "..link:match("%[(.+)%]")
		end
		link = self.charMacrosConfig.itemSlot17
		if link then
			macro = self:addLine(macro, "/equipslot 17 "..link:match("%[(.+)%]"))
		end
	else
		macro = "/equipslot [swimming,nocombat]16 "..self.itemName[self.fishingRodID]
		self.charMacrosConfig.itemSlot16 = GetInventoryItemLink("player", 16)
		self.charMacrosConfig.itemSlot17 = GetInventoryItemLink("player", 17)
	end

	return macro or ""
end


function macroFrame:autoEquip()
	if self.config.useUnderlightAngler and self.config.autoUseUnderlightAngler and not InCombatLockdown() then
		local weaponID = GetInventoryItemID("player", 16)
		if IsSubmerged() then
			if weaponID ~= self.fishingRodID then
				self.charMacrosConfig.itemSlot16 = GetInventoryItemLink("player", 16)
				self.charMacrosConfig.itemSlot17 = GetInventoryItemLink("player", 17)
				EquipItemByName(self.fishingRodID, 16)
			end
		elseif IsMounted() and weaponID == self.fishingRodID then
			if self.charMacrosConfig.itemSlot16 then
				EquipItemByName(self.charMacrosConfig.itemSlot16, 16)
			end
			if self.charMacrosConfig.itemSlot17 then
				EquipItemByName(self.charMacrosConfig.itemSlot17, 17)
			end
		end
	end
end
macroFrame.PLAYER_MOUNT_DISPLAY_CHANGED = macroFrame.autoEquip
macroFrame.MOUNT_JOURNAL_USABILITY_CHANGED = macroFrame.autoEquip


function macroFrame:getMacro()
	self.mounts:setFlags()

	-- UNDERLIGHT ANGLER
	if self.config.useUnderlightAngler and GetItemCount(self.fishingRodID) > 0 then
		self.weaponID = GetInventoryItemID("player", 16)
		if self.sFlags.swimming and not self.sFlags.isVashjir and self.itemName[self.fishingRodID]
		or self.weaponID == self.fishingRodID and not self.sFlags.isSubmerged and GetUnitSpeed("player") > 0 and (self.charMacrosConfig.itemSlot16 or self.charMacrosConfig.itemSlot17)
		then
			return self:getFishingRodMacro()
		end
	end

	-- MAGIC BROOM IS USABLE
	self.magicBroom = self.config.useMagicBroom
	                  and GetItemCount(self.broomID) > 0
	                  and self.sFlags.groundSpellKnown
	                  and not self.sFlags.isIndoors
	                  and not self.sFlags.herb
	                  and not self.sFlags.swimming
	                  and self.itemName[self.broomID]

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
		(self.class == "DRUID" and self.classConfig.useMacroAlways
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

	if self.config.useUnderlightAngler and self.itemName[self.fishingRodID] then
		self.weaponID = GetInventoryItemID("player", 16)
		macro = self:getFishingRodMacro()
	end

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


function MJMacroMixin:preClick()
	self.mounts.sFlags.forceModifier = self.forceModifier
	if InCombatLockdown() then return end
	self:SetAttribute("macrotext", macroFrame:getMacro())
end


function MJMacroMixin:PLAYER_REGEN_DISABLED()
	self:SetAttribute("macrotext", macroFrame:getCombatMacro())
end