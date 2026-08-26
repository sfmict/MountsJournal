local _, ns = ...


local MJDynamicFlightModeButtonMixin = {}
ns.MJDynamicFlightModeButtonMixin = MJDynamicFlightModeButtonMixin


function MJDynamicFlightModeButtonMixin:onLoad()
	self.spellID = C_MountJournal.GetDynamicFlightModeSpellID()
	self:SetAttribute("useOnKeyDown", false)
	self:SetAttribute("type", "spell")
	self:SetAttribute("spell", self.spellID)
	self:RegisterForDrag("LeftButton")
	self.NormalTexture:SetDrawLayer("OVERLAY")
	self.PushedTexture:SetDrawLayer("OVERLAY")
end


function MJDynamicFlightModeButtonMixin:updateIcon()
	local spellIcon = C_Spell.GetSpellTexture(self.spellID)
	self.texture:SetTexture(spellIcon)
end


function MJDynamicFlightModeButtonMixin:updateCooldown()
	local cooldownInfo = C_Spell.GetSpellCooldown(61304)
	if cooldownInfo then
		CooldownFrame_Set(self.cooldown, cooldownInfo.startTime, cooldownInfo.duration, cooldownInfo.isEnabled)
	else
		CooldownFrame_Clear(self.cooldown)
	end
end


function MJDynamicFlightModeButtonMixin:onShow()
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	self:updateIcon()
	self:updateCooldown()
end


function MJDynamicFlightModeButtonMixin:onHide()
	self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
end


function MJDynamicFlightModeButtonMixin:onEvent(event)
	if event == "SPELL_UPDATE_COOLDOWN" then
		self:updateCooldown()
	else
		self:updateIcon()
		if GameTooltip:GetOwner() == self then
			self:displayTooltip()
		end
	end
end


function MJDynamicFlightModeButtonMixin:onDragStart()
	if InCombatLockdown() then return end
	C_MountJournal.PickupDynamicFlightMode()
end


function MJDynamicFlightModeButtonMixin:displayTooltip()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetSpellByID(self.spellID)
	GameTooltip_AddBlankLineToTooltip(GameTooltip)
	GameTooltip_AddColoredLine(GameTooltip, FLIGHT_MODE_TOGGLE_TOOLTIP_SUBTEXT, GREEN_FONT_COLOR)
	if InCombatLockdown() then
		GameTooltip_AddErrorLine(GameTooltip, SPELL_FAILED_AFFECTING_COMBAT)
	end
	GameTooltip:Show()
end


function MJDynamicFlightModeButtonMixin:onEnter()
	self:displayTooltip()
end


local MJDynamicFlightSkillTreeButtonMixin = {}
ns.MJDynamicFlightSkillTreeButtonMixin = MJDynamicFlightSkillTreeButtonMixin


function MJDynamicFlightSkillTreeButtonMixin:onLoad()
	self.NormalTexture:SetDrawLayer("OVERLAY")
	self.PushedTexture:SetDrawLayer("OVERLAY")
end


function MJDynamicFlightSkillTreeButtonMixin:onClick()
	GenericTraitUI_LoadUI()
	GenericTraitFrame:SetConfigIDBySystemID(Constants.MountDynamicFlightConsts.TRAIT_SYSTEM_ID)
	GenericTraitFrame:SetTreeID(Constants.MountDynamicFlightConsts.TREE_ID)
	ToggleFrame(GenericTraitFrame)
end


function MJDynamicFlightSkillTreeButtonMixin:onEnter()
	GameTooltip_ShowSimpleTooltip(GetAppropriateTooltip(), OPEN_DYNAMIC_FLIGHT_TREE_TOOLTIP, SimpleTooltipConstants.NoOverrideColor, SimpleTooltipConstants.DoNotWrapText, self, "ANCHOR_RIGHT")
end


function MJDynamicFlightSkillTreeButtonMixin:onLeave()
	GetAppropriateTooltip():Hide()
end


function MJDynamicFlightSkillTreeButtonMixin:updateUnspentGlyphsAnimation()
	local canSpendDragonridingGlyphs = DragonridingUtil.CanSpendDragonridingGlyphs()
	if canSpendDragonridingGlyphs == self.canSpendDragonridingGlyphs then return end
	self.canSpendDragonridingGlyphs = canSpendDragonridingGlyphs
	self.UnspentGlyphsAnim:SetPlaying(self.canSpendDragonridingGlyphs)
end


function MJDynamicFlightSkillTreeButtonMixin:onShow()
	self:RegisterEvent("TRAIT_TREE_CURRENCY_INFO_UPDATED")
	self:updateUnspentGlyphsAnimation()
end


function MJDynamicFlightSkillTreeButtonMixin:onHide()
	self:UnregisterEvent("TRAIT_TREE_CURRENCY_INFO_UPDATED")
end


function MJDynamicFlightSkillTreeButtonMixin:onEvent(_, treeID)
	if treeID == Constants.MountDynamicFlightConsts.TREE_ID then
		self:updateUnspentGlyphsAnimation()
	end
end