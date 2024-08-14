local _, ns = ...
local actions = {}
ns.actions = actions


actions.mount = function(spellID)
	return ([[
		if self.additionalMounts[%d] then
			return self.additionalMounts[%d].macro
		else
			return '/run MountsJournal:summon(%d)'
		end
	]]):format(spellID, spellID, spellID)
end


actions.item = function(itemID)
	return ("return '/use item:%d'\n"):format(itemID)
end


actions.spell = function(spellID)
	return ([[
		local spellName = self:getSpellName(%d)
		if spellName then
			return '/cast '..spellName
		end
	]]):format(spellID)
end


function actions:getText(action)
	return self[action[1]](action[2])
end