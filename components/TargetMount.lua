local addon, ns = ...
local L = ns.L


ns.journal:on("MODULES_INIT", function(journal)
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
		self.icon:SetTexture(icon)

		if self:IsMouseOver() then
			self:GetScript("OnEnter")(self)
		end

		if ns.mounts.config.autoTargetMount then
			journal:setSelectedMount(self.mountID)
		end
	end

	tm:SetScript("OnEvent", function(self, event, ...)
		if event == "PLAYER_TARGET_CHANGED" then
			local spellID, mountID = ns.util.getUnitMount("target")
			if spellID then self:setMount(spellID, mountID or ns.additionalMounts[spellID]) end
		else
			local _,_, spellID = ...
			if ns.additionalMounts[spellID] then
				self:setMount(spellID, ns.additionalMounts[spellID])
			else
				local mountID = C_MountJournal.GetMountFromSpell(spellID)
				if mountID then self:setMount(spellID, mountID) end
			end
		end
	end)

	tm:SetScript("OnShow", function(self)
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterUnitEvent("UNIT_SPELLCAST_START", "target")
		self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "target")
		self:GetScript("OnEvent")(self, "PLAYER_TARGET_CHANGED")
	end)

	tm:SetScript("OnHide", function(self)
		self:UnregisterEvent("PLAYER_TARGET_CHANGED")
		self:UnregisterEvent("UNIT_SPELLCAST_START")
		self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	end)

	local function addLines()
		GameTooltip:AddLine(L["Target Mount"], HIGHLIGHT_FONT_COLOR:GetRGB())
		GameTooltip:AddLine(L["Shows the mount of current target"])
		GameTooltip:AddLine("\n|A:newplayertutorial-icon-mouse-leftbutton:0:0|a "..L["Select mount"])
		GameTooltip:AddLine("|A:newplayertutorial-icon-mouse-rightbutton:0:0|a "..L["Auto select Mount"])
		GameTooltip:Show()
	end

	tm:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

		self.oldRefreshData = GameTooltip.RefreshData
		hooksecurefunc(GameTooltip, "RefreshData", function(GameTooltip, event)
			GameTooltip:AddLine(" ")
			addLines()
		end)

		if type(self.mountID) == "number" then
			GameTooltip:SetMountBySpellID(self.spellID)
			GameTooltip:AddLine(" ")
		elseif self.spellID then
			GameTooltip:SetSpellByID(self.spellID)
			GameTooltip:AddLine(" ")
		end

		addLines()
	end)

	tm:SetScript("OnLeave", function(self)
		GameTooltip.RefreshData = self.oldRefreshData
		GameTooltip:Hide()
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