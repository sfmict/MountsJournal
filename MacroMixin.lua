MJMacroMixin = {}


function MJMacroMixin:onEvent(event, ...)
	if self[event] then
		self[event](self, ...)
	end
end


function MJMacroMixin:onLoad()
	self.mounts = MountsJournal
	self.sFlags = self.mounts.sFlags
	self.macroTable = self.mounts.macroTable
	self.class = select(2, UnitClass("player"))
	self.broom = GetItemInfo(37011)
	if not self.broom then
		self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
	end
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:refresh()

	-- for i = 1, GetNumClasses() do
	-- 	local localized, className = GetClassInfo(i)
	-- 	fprint(dump, localized, className, i, C_ClassColor.GetClassColor(className))
	-- end
end


function MJMacroMixin:refresh()
	local classTable = self.macroTable[self.class]
	if classTable and classTable.macroEnable then
		self.classMacro = classTable.macro or self:getClassMacro()
		self.macroAlways = classTable.macroAlways
	else
		self.classMacro = nil
		self.macroAlways = nil
	end
end


function MJMacroMixin:addLine(text, line)
	if type(text) == "string" and strlen(text) > 0 then
		return strjoin("\n", text, line)
	else
		return line
	end
end


function MJMacroMixin:getDefMacro()
	local macro

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

	-- MAGIC BROOM
	if self.mounts.config.useMagicBroom
	and GetItemCount(37011) > 0
	and not self.sFlags.inVehicle
	and not self.sFlags.isMounted
	and self.sFlags.groundSpellKnown
	and not self.sFlags.herb
	and not self.sFlags.swimming
	and (self.sFlags.fly or not self.sFlags.waterWalk)
	and self.broom then
		macro = self:addLine(macro, "/use "..self.broom)
		self.mounts.lastUseTime = GetTime()
	else
		macro = self:addLine(macro, "/mount")
	end

	return macro
end


do
	local function classDefFunc(spellID)
		local spellName = GetSpellInfo(spellID)

		if spellName then
			return "/cast "..spellName
		end
	end


	local classFunc = {
		PRIEST = function() return classDefFunc(1706) end, -- Levitation
		SHAMAN = function() return classDefFunc(2645) end, -- Ghost Wolf
		MAGE = function() return classDefFunc(130) end, -- Slow Fall
		DRUID = function()
			local catForm = GetSpellInfo(768)
			local travelForm = GetSpellInfo(783)

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
			local text = classFunc()
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
		
		if self.macroAlways or self.classMacro and (IsIndoors() or GetUnitSpeed("player") > 0 or IsFalling()) then
			macro = self.classMacro
		else
			macro = self:getDefMacro()
		end

		fprint(macro)
		self:SetAttribute("macrotext", macro or "")
	end
end


function MJMacroMixin:PLAYER_REGEN_DISABLED()
	self:SetAttribute("macrotext", self.classMacro or self:getDefMacro() or "")
end


function MJMacroMixin:GET_ITEM_INFO_RECEIVED(itemID)
	if itemID == 37011 then
		self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
		self.broom = GetItemInfo(37011)
	end
end