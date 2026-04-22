local _, ns = ...
local macroFrame = ns.macroFrame
local actions = {}
ns.actions = actions


---------------------------------------------------
-- rmount RANDOM MOUNT
actions.rmount = {}
actions.rmount.condText = "profileLoad ~= 2"

function actions.rmount:getFuncText(value)
	if value == 0 then
		return [[
			self.mounts:setMountsList(self.mounts.sp)
			profileLoad = 1
		]]
	elseif value == 1 then
		return [[
			self.mounts:setMountsList(self.mounts.defProfile)
			profileLoad = 1
		]]
	else
		return ([[
			local profile = self.mounts.profiles['%s']
			self.mounts:setMountsList(profile)
			profileLoad = 1
		]]):format(value:gsub("[\\']", "\\%1"))
	end
end


---------------------------------------------------
-- rmountt RANDOM MOUNT OF SELECTED TYPE
actions.rmountt = {}
actions.rmountt.condText = "(not profileLoad or profileLoad == true)"

function actions.rmountt:getFuncText(value)
	local mType, profile = (":"):split(value, 2)

	if mType == "1" then
		mType = "fly"
	elseif mType == "2" then
		mType = "ground"
	else
		mType = "swimming"
	end

	local str = ("profileLoad = 2\nself.summonMType = '%s'\n"):format(mType)
	if profile == "0" then
		return str.."self.mounts:setMountsList(self.mounts.sp)"
	elseif profile == "1" then
		return str.."self.mounts:setMountsList(self.mounts.defProfile)"
	else
		return ("%sself.mounts:setMountsList(self.mounts.profiles['%s'])"):format(str, profile:gsub("[\\']", "\\%1"))
	end
end


---------------------------------------------------
-- rmountr RANDOM MOUNT BY RARITY
actions.rmountr = {}
actions.rmountr.condText = actions.rmount.condText

function actions.rmountr:getFuncText(value)
	if value == 0 then
		return [[
			self.mounts:setMountsList(self.mounts.sp, self.mounts.rarityWeight)
			profileLoad = 1
		]]
	elseif value == 1 then
		return [[
			self.mounts:setMountsList(self.mounts.defProfile, self.mounts.rarityWeight)
			profileLoad = 1
		]]
	else
		return ([[
			local profile = self.mounts.profiles['%s']
			self.mounts:setMountsList(profile, self.mounts.rarityWeight)
			profileLoad = 1
		]]):format(value:gsub("[\\']", "\\%1"))
	end
end


---------------------------------------------------
-- rmounttr RANDOM MOUNT OF SELECTED TYPE BY RARITY
actions.rmounttr = {}
actions.rmounttr.condText = actions.rmountt.condText

function actions.rmounttr:getFuncText(value)
	local mType, profile = (":"):split(value, 2)

	if mType == "1" then
		mType = "fly"
	elseif mType == "2" then
		mType = "ground"
	else
		mType = "swimming"
	end

	local str = ("profileLoad = 2\nself.summonMType = '%s'\n"):format(mType)
	if profile == "0" then
		return str.."self.mounts:setMountsList(self.mounts.sp, self.mounts.rarityWeight)"
	elseif profile == "1" then
		return str.."self.mounts:setMountsList(self.mounts.defProfile, self.mounts.rarityWeight)"
	else
		return ("%sself.mounts:setMountsList(self.mounts.profiles['%s'], self.mounts.rarityWeight)"):format(str, profile:gsub("[\\']", "\\%1"))
	end
end


---------------------------------------------------
-- rmountc RANDOM MOUNT BY SUMMON COUNTER
actions.rmountc = {}
actions.rmountc.condText = actions.rmount.condText

function actions.rmountc:getFuncText(value)
	if value == 0 then
		return [[
			self.mounts:setMountsList(self.mounts.sp, self.mounts.counterWeight)
			profileLoad = 1
		]]
	elseif value == 1 then
		return [[
			self.mounts:setMountsList(self.mounts.defProfile, self.mounts.counterWeight)
			profileLoad = 1
		]]
	else
		return ([[
			local profile = self.mounts.profiles['%s']
			self.mounts:setMountsList(profile, self.mounts.counterWeight)
			profileLoad = 1
		]]):format(value:gsub("[\\']", "\\%1"))
	end
end


---------------------------------------------------
-- rmounttc RANDOM MOUNT OF SELECTED TYPE BY SUMMON COUNTER
actions.rmounttc = {}
actions.rmounttc.condText = actions.rmountt.condText

function actions.rmounttc:getFuncText(value)
	local mType, profile = (":"):split(value, 2)

	if mType == "1" then
		mType = "fly"
	elseif mType == "2" then
		mType = "ground"
	else
		mType = "swimming"
	end

	local str = ("profileLoad = 2\nself.summonMType = '%s'\n"):format(mType)
	if profile == "0" then
		return str.."self.mounts:setMountsList(self.mounts.sp, self.mounts.counterWeight)"
	elseif profile == "1" then
		return str.."self.mounts:setMountsList(self.mounts.defProfile, self.mounts.counterWeight)"
	else
		return ("%sself.mounts:setMountsList(self.mounts.profiles['%s'], self.mounts.counterWeight)"):format(str, profile:gsub("[\\']", "\\%1"))
	end
end


---------------------------------------------------
-- mount
actions.mount = {}
actions.mount.condText = "(not profileLoad or profileLoad == true) and not self.useMount"

function actions.mount:getFuncText(value, addKey)
	addKey("v.GetTime = GetTime")
	return ([[
		%s
		-- EXIT VEHICLE
		if self.sFlags.inVehicle then
			return "/leavevehicle"
		-- DISMOUNT
		elseif self.sFlags.isMounted then
			if not self.lastUseTime or v.GetTime() - self.lastUseTime > .5 then
				return "/dismount"
			end
			return ""
		-- MOUNT
		elseif not (noMacro and self.additionalMounts[%s]) then
			self.useMount = %s
		end
	]]):format(macroFrame.classDismount or "", value, value)
end


---------------------------------------------------
-- mount TARGET MOUNT
actions.tmount = {}
actions.tmount.condText = actions.mount.condText

function actions.tmount:getFuncText(_, addKey)
	addKey("v.GetTime = GetTime")
	return ([[
		%s
		-- EXIT VEHICLE
		if self.sFlags.inVehicle then
			return "/leavevehicle"
		-- DISMOUNT
		elseif self.sFlags.isMounted then
			if not self.lastUseTime or v.GetTime() - self.lastUseTime > .5 then
				return "/dismount"
			end
			return ""
		-- MOUNT
		elseif self.sFlags.targetMount and not (noMacro and self.sFlags.targetMountAdditional) then
			self.useMount = self.sFlags.targetMount
		end
	]]):format(macroFrame.classDismount or "")
end


---------------------------------------------------
-- dmount DISMOUNT
actions.dmount = {}

function actions.dmount:getFuncText(_, addKey)
	addKey("v.GetTime = GetTime")
	return ([[
		%s
		-- EXIT VEHICLE
		if self.sFlags.inVehicle then
			return "/leavevehicle"
		-- DISMOUNT
		elseif self.sFlags.isMounted then
			if not self.lastUseTime or v.GetTime() - self.lastUseTime > .5 then
				return "/dismount"
			end
			return ""
		end
	]]):format(macroFrame.classDismount or "")
end


---------------------------------------------------
-- item
actions.item = {}

function actions.item:getFuncText(value)
	return ("return '/use item:%s'"):format(value)
end


---------------------------------------------------
-- iitem INVENTORY ITEM
actions.iitem = {}

function actions.iitem:getFuncText(value)
	return ("return '/use %s'"):format(value)
end


---------------------------------------------------
-- spell
actions.spell = {}

function actions.spell:getFuncText(value)
	return ([[
		local spellName = self:getSpellName(%s)
		if spellName then
			return '/cast '..spellName
		end
	]]):format(value)
end


---------------------------------------------------
-- macro
actions.macro = {}

function actions.macro:getFuncText(value)
	return ("return '%s'"):format(value:gsub("['\n\\]", "\\%1"))
end


---------------------------------------------------
-- pmacro PRE MACRO
actions.pmacro = {}
actions.pmacro.condText = "not (profileLoad or self.useMount or self.preUseMacro)"

function actions.pmacro:getFuncText(value)
	return ("self.preUseMacro = '%s'"):format(value:gsub("['\n\\]", "\\%1"))
end


---------------------------------------------------
-- sstate SET STATE
actions.sstate = {}

function actions.sstate:getFuncText(value)
	return ("self.state['%s'] = true"):format(value:gsub("['\\]", "\\%1"))
end


---------------------------------------------------
-- snip SNIPPET
actions.snip = {}

function actions.snip:getFuncText(value, addKey)
	addKey("v.type = type")
	return ([[
		local text = self:callSnippet('%s')
		return v.type(text) == "string" and text or nil
	]]):format(value:gsub("['\\]", "\\%1"))
end


---------------------------------------------------
-- METHODS
function actions:getFuncText(action, addKey)
	return self[action[1]]:getFuncText(action[2], addKey)
end
