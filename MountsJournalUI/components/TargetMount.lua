local addon, ns = ...
local L, util = ns.L, ns.util


ns.journal:on("MODULES_INIT", function(journal)
	local tooltip = CreateFrame("GameTooltip", addon.."Tooltip", UIParent, "GameTooltipTemplate")
	tooltip:Hide()
	tooltip:SetScript("OnUpdate", GameTooltip_OnUpdate)
	local tm = journal.bgFrame.targetMount
	tm:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	tm.checkedTexture:SetShown(ns.mounts.config.autoTargetMount)

	function tm:setMount(spellID, mountID)
		self.spellID = spellID
		self.mountID = mountID

		local _, icon
		if type(mountID) == "number" then
			_,_, icon = C_MountJournal.GetMountInfoByID(mountID)
		else
			icon = self.mountID.icon
		end
		self.icon:SetDesaturated()
		self.icon:SetTexture(icon)

		if self.isHover then
			self:GetScript("OnEnter")(self)
		end

		if ns.mounts.config.autoTargetMount then
			journal:setSelectedMount(self.mountID)
		end
	end

	tm:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

	function tm:PLAYER_TARGET_CHANGED()
		if util.isMidnight and GetRestrictedActionStatus(Enum.RestrictedActionType.SecretAuras) then return end
		local spellID, mountID = util.getUnitMount("target")
		if spellID then self:setMount(spellID, mountID or ns.additionalMounts[spellID]) end
	end

	function tm:UNIT_SPELLCAST_START(_,_, spellID)
		if util.isMidnight and issecretvalue(spellID) then return end
		if ns.additionalMounts[spellID] then
			self:setMount(spellID, ns.additionalMounts[spellID])
		else
			local mountID = C_MountJournal.GetMountFromSpell(spellID)
			if mountID then self:setMount(spellID, mountID) end
		end
	end
	tm.UNIT_SPELLCAST_SUCCEEDED = tm.UNIT_SPELLCAST_START

	tm:SetScript("OnShow", function(self)
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterUnitEvent("UNIT_SPELLCAST_START", "target")
		self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "target")
		self:PLAYER_TARGET_CHANGED()
	end)

	tm:SetScript("OnHide", function(self)
		self:UnregisterEvent("PLAYER_TARGET_CHANGED")
		self:UnregisterEvent("UNIT_SPELLCAST_START")
		self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	end)

	local function addLines()
		tooltip:AddLine(L["Target Mount"], HIGHLIGHT_FONT_COLOR:GetRGB())
		tooltip:AddLine(L["Shows the mount of current target"])
		tooltip:AddLine("\n|A:newplayertutorial-icon-mouse-leftbutton:0:0|a "..L["Select mount"])
		tooltip:AddLine("|A:newplayertutorial-icon-mouse-rightbutton:0:0|a "..L["Auto select Mount"])
		tooltip:Show()
	end

	hooksecurefunc(tooltip, "RefreshData", function(tooltip, event)
		tooltip:AddLine(" ")
		addLines()
	end)

	tm:SetScript("OnEnter", function(self)
		self.isHover = true
		tooltip:SetOwner(self, "ANCHOR_RIGHT")

		if type(self.mountID) == "number" then
			tooltip:SetMountBySpellID(self.spellID)
			tooltip:AddLine(" ")
		elseif self.spellID then
			tooltip:SetSpellByID(self.spellID)
			tooltip:AddLine(" ")
		end

		addLines()
	end)

	tm:SetScript("OnLeave", function(self)
		self.isHover = nil
		tooltip:Hide()
	end)

	tm:SetScript("OnClick", function(self, button)
		if button == "RightButton" then
			ns.mounts.config.autoTargetMount = not ns.mounts.config.autoTargetMount
			self.checkedTexture:SetShown(ns.mounts.config.autoTargetMount)

			if self.mountID and ns.mounts.config.autoTargetMount then
				journal:setSelectedMount(self.mountID)
			end
		elseif self.mountID then
			journal:setSelectedMount(self.mountID)
		end

		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	tm:Show()
end)