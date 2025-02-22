local addon, ns = ...
local L, util, journal, mounts = ns.L, ns.util, ns.journal, ns.mounts


TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
	if not InCombatLockdown() and mounts.config.tooltipMount and data.lines then
		for i = 1, #data.lines do
			local unit = data.lines[i].unitToken
			if unit then
				local spellID, mountID = util.getUnitMount(unit)
				if spellID then
					local name, _, icon = journal:getMountInfo(mountID or ns.additionalMounts[spellID])
					tooltip:AddLine(" ")
					if mountID then
						tooltip:AddDoubleLine(("|T%s:16:16|t %s"):format(icon, name), ns.mountsDB[mountID][3].."%", util.getRarityColor(mountID):GetRGB())
					else
						tooltip:AddLine(("|T%s:16:16|t %s"):format(icon, name))
					end
				end
				break
			end
		end
	end
end)