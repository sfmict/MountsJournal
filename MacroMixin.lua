MJMacroMixin = {}


function MJMacroMixin:onEvent(event, ...)
	if self[event] then
		self[event](self, ...)
	end
end


function MJMacroMixin:onLoad()
	self.mounts = MountsJournal
	self.sFlags = self.mounts.sFlags
	self.macrosConfig = self.mounts.config.macrosConfig
	self.charMacrosConfig = MountsJournalChar.macrosConfig
	self.class = select(2, UnitClass("player"))
	self.broomName = GetItemInfo(37011)
	if not self.broomName then
		self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
	end
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:refresh()
end


function MJMacroMixin:refresh()
	self.classConfig = self.charMacrosConfig.enable and self.charMacrosConfig or self.macrosConfig[self.class]
	self.macro = nil
	self.combatMacro = nil
	self.useMacroAlways = nil
	if self.classConfig then
		if self.classConfig.macroEnable then
			self.macro = self.classConfig.macro or self:getClassMacro()
			self.useMacroAlways = self.classConfig.useMacroAlways
		end
		if self.classConfig.combatMacroEnable then
			self.combatMacro = self.classConfig.combatMacro or self:getClassMacro()
		end
	end
end


function MJMacroMixin:addLine(text, line)
	if type(text) == "string" and strlen(text) > 0 then
		return strjoin("\n", text, line)
	else
		return line
	end
end


do
	local spellIDtoName = {}
	function MJMacroMixin:getSpellName(spellID)
		if not spellIDtoName[spellID] then
			spellIDtoName[spellID] = GetSpellInfo(spellID)
		end

		return spellIDtoName[spellID]
	end
end


function MJMacroMixin:getDefMacro()
	local macro

	if self.class == "DEATHKNIGHT"
	and self.classConfig.usePathOfFrost
	and not self.sFlags.inVehicle
	and not self.sFlags.isMounted
	and not self.sFlags.swimming
	and not self.sFlags.fly then
		macro = self:addLine(macro, "/cast "..sefl:getSpellName(3714)) -- Path of Frost
	end

	if self.class == "SHAMAN"
	and self.classConfig.useWaterWalking
	and not self.sFlags.inVehicle
	and not self.sFlags.isMounted
	and not self.sFlags.swimming
	and not self.sFlags.fly then
		macro = self:addLine(macro, "/cast "..self:getSpellName(546)) -- Water Walking
	end

	if self.class == "DRUID" then
		local shapeshiftIndex = GetShapeshiftForm()
		if shapeshiftIndex > 0 then
			local _,_,_,spellID = GetShapeshiftFormInfo(shapeshiftIndex)
			if spellID == 768 -- Cat Form
			or spellID == 5487 then -- Bear Form
				macro = self:addLine(macro, "/cancelform")
			end
		end
	end

	if self.magicBroom then
		macro = self:addLine(macro, "/use "..self.broomName) -- MAGIC BROOM
		self.mounts.lastUseTime = GetTime()
	else
		macro = self:addLine(macro, "/mount")
	end

	return macro
end


do
	local function classDefFunc(spellName)
		if spellName then
			return "/cast "..spellName
		end
	end


	local classFunc = {
		PRIEST = function(self) return classDefFunc(self:getSpellName(1706)) end, -- Levitation
		SHAMAN = function(self) return classDefFunc(self:getSpellName(2645)) end, -- Ghost Wolf
		MAGE = function(self) return classDefFunc(self:getSpellName(130)) end, -- Slow Fall
		MONK = function(self) return classDefFunc(self:getSpellName(125883)) end, --Zen Flight
		DRUID = function(self)
			local catForm = self:getSpellName(768)
			local travelForm = self:getSpellName(783)

			if catForm and travelForm then
				return "/cast [indoors,noswimming]"..catForm..";"..travelForm
			end
		end,
	}


	function MJMacroMixin:getClassMacro(class)
		local macro = "/leavevehicle [vehicleui]"
		macro = self:addLine(macro, "/dismount [mounted]")

		local classFunc = classFunc[class or self.class]
		if type(classFunc) == "function" then
			local text = classFunc(self)
			if type(text) == "string" and strlen(text) > 0 then
				macro = self:addLine(macro, text)
			end
		end

		return macro
	end
end


function MJMacroMixin:preClick()
	if not InCombatLockdown() then
		self.mounts:setFlags()
		local macro

		-- MAGIC BROOM IS USABLE
		self.magicBroom = self.mounts.config.useMagicBroom
								and GetItemCount(37011) > 0
								and not self.useMacroAlways
								and not self.sFlags.inVehicle
								and not self.sFlags.isMounted
								and self.sFlags.groundSpellKnown
								and not self.sFlags.herb
								and not self.sFlags.swimming
								and not IsIndoors()
								and (self.sFlags.fly or not self.sFlags.waterWalk)
								and self.broomName

		if not self.magicBroom
		and (self.useMacroAlways
			  or self.macro
			  and (IsIndoors()
					 or GetUnitSpeed("player") > 0
					 or IsFalling())) then
			macro = self.macro
		else
			macro = self:getDefMacro()
		end

		self:SetAttribute("macrotext", macro or "")
	end
end


function MJMacroMixin:PLAYER_REGEN_DISABLED()
	if self.combatMacro then
		self:SetAttribute("macrotext", self.combatMacro)
	end
end


function MJMacroMixin:GET_ITEM_INFO_RECEIVED(itemID)
	if itemID == 37011 then
		self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
		self.broomName = GetItemInfo(37011)
	end
end