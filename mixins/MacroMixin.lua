local _, ns = ...
local util = ns.util
local type, pairs, rawget, GetUnitSpeed, IsFalling, InCombatLockdown, GetTime, C_Item, C_Spell, GetInventoryItemID, GetInventoryItemLink, EquipItemByName, IsMounted, IsSubmerged, C_UnitAuras = type, pairs, rawget, GetUnitSpeed, IsFalling, InCombatLockdown, GetTime, C_Item, C_Spell, GetInventoryItemID, GetInventoryItemLink, EquipItemByName, IsMounted, IsSubmerged, C_UnitAuras
local macroFrame = CreateFrame("FRAME")
ns.macroFrame = macroFrame
util.setEventsMixin(macroFrame)


macroFrame:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)


macroFrame:on("ADDON_INIT", function(self)
	self.additionalMounts = ns.additionalMounts
	self.calendar = ns.calendar
	self.mounts = ns.mounts
	self.config = self.mounts.config
	self.ruleSetConfig = self.mounts.globalDB.ruleSets
	self.sFlags = self.mounts.sFlags
	self.macrosConfig = self.config.macrosConfig
	self.charMacrosConfig = self.mounts.charDB.macrosConfig
	self.conditions = ns.conditions
	self.actions = ns.actions
	self.checkRules = {}
	self.class = select(2, UnitClass("player"))
	self.fishingRodID = 133755

	local classOptionMacro = ""
	local defMacro = ""

	if self.class == "PRIEST" or self.class == "MAGE" then
		classOptionMacro = classOptionMacro..[[
			local IsFalling, GetTime, C_UnitAuras = IsFalling, GetTime, C_UnitAuras
		]]
	elseif self.class == "MONK" then
		classOptionMacro = classOptionMacro..[[
			local IsFalling, GetTime, GetUnitSpeed, C_UnitAuras = IsFalling, GetTime, GetUnitSpeed, C_UnitAuras
		]]
	elseif self.class == "DRUID" then
		local GetShapeshiftForm, GetShapeshiftFormInfo = GetShapeshiftForm, GetShapeshiftFormInfo
		self.getFormSpellID = function()
			local shapeshiftIndex = GetShapeshiftForm()
			if shapeshiftIndex > 0 then
				local _,_,_, spellID = GetShapeshiftFormInfo(shapeshiftIndex)
				return spellID
			end
		end
		self.GetSpecialization = GetSpecialization
		self.specializationSpellIDs = {
			24858, -- moonkin
			768, -- cat
			5487, -- bear
		}

		classOptionMacro = classOptionMacro..[[
			local GetTime = GetTime
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
		self.classDismount = [[
			-- DRUID LAST FORM
			-- 768 - cat form
			-- 783 - travel form
			-- 24858 - moonkin form
			-- 210053 - mount form
			if self.classConfig.useLastDruidForm then
				local spellID = self.getFormSpellID()

				if self.classConfig.useDruidFormSpecialization then
					self.charMacrosConfig.lastDruidFormSpellID = self.specializationSpellIDs[self.GetSpecialization()]
				end

				if self.charMacrosConfig.lastDruidFormSpellID
				and spellID ~= 24858
				and (self.sFlags.isMounted
					  or self.sFlags.inVehicle
					  or spellID == 783
					  or spellID == 210053
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
		classOptionMacro = classOptionMacro..self.classDismount
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
			return macro
		end
	]]

	self.getClassOptionMacro = self:loadString(classOptionMacro)
	self.getDefMacro = self:loadString(defMacro)
	self:setRuleSet()

	self:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
	self:RegisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")

	self:refresh()
	self:getClassMacro(self.class, function() self:refresh() end)
end)


function macroFrame:setRuleSet(ruleSetName)
	if ruleSetName then
		self.mounts.charDB.currentRuleSetName = ruleSetName
	end
	local currentRuleSetName, currentRuleSet, default = self.mounts.charDB.currentRuleSetName

	for i = 1, #self.ruleSetConfig do
		local ruleSet = self.ruleSetConfig[i]
		if ruleSet.name == currentRuleSetName then
			currentRuleSet = ruleSet
		end
		if ruleSet.isDefault then
			default = ruleSet
		end
	end

	if not currentRuleSet then
		self.mounts.charDB.currentRuleSetName = nil
		currentRuleSet = default
	end

	self.currentRuleSet = currentRuleSet
	self:setRuleFuncs()
end


function macroFrame:loadString(funcStr)
	local loadedFunc, err = loadstring(funcStr)
	if err then
		geterrorhandler()(err)
	else
		return loadedFunc()
	end
end


function macroFrame:setRuleFuncs()
	local function addKeys(vars, keys)
		if not vars then return end
		for i = 1, #vars do
			keys[vars[i]] = true
		end
	end

	for i = 1, #self.currentRuleSet do
		local rules = self.currentRuleSet[i]
		local keys = {}
		local func = [[
return function(self, button, profileLoad)
	self.mounts:resetMountsList()
	self.preUseMacro = nil
		]]

		for j = 1, #rules do
			local rule = rules[j]
			local condText, condVars = self.conditions:getFuncText(rule)
			local actionText, actionVars = self.actions:getFuncText(rule.action)
			addKeys(condVars, keys)
			addKeys(actionVars, keys)
			func = ("%sif %sthen\n%s\nend\n"):format(func, condText, actionText)
		end

		if next(keys) then
			local vars = {}
			for k in next, keys do
				vars[#vars + 1] = k
			end
			local varsText = table.concat(vars, ", ")
			func = ("local %s = %s\n%s"):format(varsText, varsText, func)
		end

		func = func..[[
	self.mounts:updateFlagsWithMap()

	if self.useMount then
		local macro = self:getDefMacro()

		if self.preUseMacro then
			macro = self:addLine(macro, self.preUseMacro)
		end

		if self.additionalMounts[self.useMount] then
			macro = self:addLine(macro, self.additionalMounts[self.useMount].macro)
			self.useMount = false
		end
		return macro
	end

	self.mounts:setEmptyList()
	return self:getMacro()
end
		]]
		self.checkRules[i] = self:loadString(func)
	end
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
			local name = C_Spell.GetSpellName(spellID)
			if C_Spell.IsSpellDataCached(spellID) then
				local subText = C_Spell.GetSpellSubtext(spellID)
				if subText and #subText > 0 then
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
		EVOKER = getClassDefFunc(358267), -- Hover
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
	if self.config.useUnderlightAngler and self.config.autoUseUnderlightAngler and C_Item.GetItemCount(self.fishingRodID) > 0 and not InCombatLockdown() then
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
			local _, spellID, _,_, isUsable = C_MountJournal.GetMountInfoByID(data.mountID)
			return isUsable and C_Spell.IsSpellUsable(spellID)
		elseif data.itemID then
			return C_Item.GetItemCount(data.itemID) > 0
			       and (not macroFrame.sFlags.fly or C_Spell.GetSpellTexture(436854) == 5142726)
		end
	end


	function macroFrame:getBroomData()
		if not self.config.useMagicBroom
		or not ns.calendar:isHolidayActive(324) -- Hallow's End
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


function macroFrame:isMovingOrFalling()
	return GetUnitSpeed("player") > 0 or IsFalling()
end


function macroFrame:getMacro(id, button)
	-- UNDERLIGHT ANGLER
	if self.config.useUnderlightAngler and C_Item.GetItemCount(self.fishingRodID) > 0 then
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
		(self.class == "DRUID" and self.classConfig.useMacroAlways
		or not self.magicBroom and (self.sFlags.isIndoors or self:isMovingOrFalling()))
	then
		macro = self.macro
	-- MOUNT
	else
		macro = self:getDefMacro()

		if self.magicBroom then
			if self.magicBroom.itemID then
				macro = self:addLine(macro, "/use item:"..self.magicBroom.itemID) -- USE ITEM BROOM
			elseif self.magicBroom.mountID then
				local name = C_MountJournal.GetMountInfoByID(self.magicBroom.mountID)
				macro = self:addLine(macro, "/use "..name) -- USE MOUNT BROOM
			end
			self.lastUseTime = GetTime()
		else
			self.mounts:setSummonMount(true)

			local additionMount
			if self.sFlags.targetMount then
				additionMount = self.additionalMounts[self.sFlags.targetMount]
			else
				additionMount = self.additionalMounts[self.mounts.summonedSpellID]
			end

			if self.preUseMacro then
				macro = self:addLine(macro, self.preUseMacro)
			end

			if additionMount then
				macro = self:addLine(macro, additionMount.macro)
			elseif not self.useMount then
				self.useMount = true
			end
		end
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
		macro = self:addLine(macro, "/mount notNilModifier")
	end

	return macro
end


function util.getClassMacro(...)
	return macroFrame:getClassMacro(...)
end


function util.refreshMacro()
	macroFrame:refresh()
end


MJMacroMixin = {}


function MJMacroMixin:onLoad()
	self.mounts = ns.mounts
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
end


function MJMacroMixin:onEvent(event, ...)
	self:SetAttribute("macrotext", macroFrame:getCombatMacro())
end


function MJMacroMixin:preClick(button, down)
	self.mounts.sFlags.forceModifier = self.forceModifier
	self.notUsable = InCombatLockdown() or down ~= GetCVarBool("ActionButtonUseKeyDown")
	if self.notUsable then return end
	self.mounts:setFlags()
	macroFrame.useMount = false
	self:SetAttribute("macrotext", macroFrame.checkRules[self.id](macroFrame, button))
end


function MJMacroMixin:postClick(button, down)
	if self.notUsable then return end
	if macroFrame.useMount == true then
		self.mounts:summon()
	elseif macroFrame.useMount then
		self.mounts:summon(macroFrame.useMount)
	end
end