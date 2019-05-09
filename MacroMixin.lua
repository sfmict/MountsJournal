MJMacroMixin = {}


function MJMacroMixin:onEvent(event, ...)
	if self[event] then
		self[event](self, ...)
	end
end


function MJMacroMixin:onLoad()
	self.mounts = MountsJournal
	self.flags = self.mounts.flags
	self.macroTable = self.mounts.macroTable
	self.class = select(3, UnitClass("player"))
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

	-- for i = 1, GetNumShapeshiftForms() do
	-- 	fprint(i)
	-- end

	-- local shapeshiftIndex = GetShapeshiftForm()
	-- fprint(shapeshiftIndex > 0 and GetShapeshiftFormInfo(shapeshiftIndex))
end


function MJMacroMixin:refresh()
	local classTable = self.macroTable[self.class]
	if classTable and classTable.macroEnable and classTable.macro then
		self.classMacro = classTable.macro
		self.macroAlways = classTable.macroAlways
	else
		self.classMacro = nil
		self.macroAlways = nil
	end
end


function MJMacroMixin:getDefMacro()
	local macro = "/"
	if not self.mounts.config.useMagicBroom or self.mounts:herbMountsExists() or self.mounts:waterWalkMountsExists() or not self.broom then
		macro = macro.."mount"
	else
		local modifier = self.mounts.config.modifier
		macro = macro.."use [nomounted,noswimming,nomod:"..modifier.."][nomounted,flyable,mod:"..modifier.."]"..self.broom.."\n/mount"
	end
	return macro
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

		-- fprint(macro)
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