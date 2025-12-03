local addon, ns = ...
local L, mounts, util = ns.L, ns.mounts, ns.util


-- PANEL
local panel = CreateFrame("FRAME", nil, UIParent)
mounts.summonPanel = panel
panel.BTN_SIZE = 45
panel.speed = UIParent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
panel:SetFrameLevel(1000)
panel:SetMovable(true)
panel:SetScript("OnEvent", function(self)
	if InCombatLockdown() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	else
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		self:setPosition()
	end
end)

panel:SetClampedToScreen(true)
panel:EnableMouse(true)
panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart", function(self)
	if self:isLocked() then return end
	self.isDrag = true
	GameTooltip:Hide()
	self:StartMoving()
end)
panel:SetScript("OnDragStop", function(self)
	if self.isDrag then
		self.isDrag = nil
		self:StopMovingOrSizing()
		self:savePosition()
	end
end)

local function fade(self, elapsed)
	self.timer = self.timer - elapsed
	if self.timer <= 0 then
		self:SetScript("OnUpdate", nil)
		self:SetAlpha(self.config.fade)
	else
		self:SetAlpha(self.config.fade - self.deltaAlpha * self.timer)
	end
end
panel:SetScript("OnEnter", function(self)
	self:SetAlpha(1)
	self:SetScript("OnUpdate", nil)
end)
panel:SetScript("OnLeave", function(self)
	if self.config.fade < 1 then
		self.timer = 1
		self.deltaAlpha = (self.config.fade - 1) * self.timer
		self:SetScript("OnUpdate", fade)
	end
end)


-- PANEL METHODS
function panel:setStrata(strata)
	if InCombatLockdown() then return end
	if strata then self.config.frameStrata = strata end

	if self.config.frameStrata == 3 then
		strata = "FULLSCREEN"
	elseif self.config.frameStrata == 2 then
		strata = "DIALOG"
	elseif self.config.frameStrata == 1 then
		strata = "HIGH"
	else
		strata = "MEDIUM"
	end

	self:SetFrameStrata(strata)
end


function panel:savePosition()
	local scale = self:GetEffectiveScale()
	local x, y = self:GetCenter()
	self.config.x = x * scale
	self.config.y = y * scale
	self:setPosition()
end


function panel:setPosition()
	if InCombatLockdown() or not self:IsShown() then return end
	self:ClearAllPoints()
	local scale = self:GetEffectiveScale()
	self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", self.config.x / scale, self.config.y / scale)
end


function panel:setShown(show)
	if InCombatLockdown() then return end
	self.config.isShown = show
	self:SetShown(show)
	if show then
		self:setPosition()
	else
		self:setLocked(false)
	end
end


function panel:setLocked(lock)
	self.config.isLocked = lock
end


function panel:isLocked()
	return self.config.isLocked
end


function panel:setSize(kSize)
	if InCombatLockdown() then return end
	if kSize then self.config.kSize = kSize end
	local kSize = self.config.kSize
	local padding = 2

	self.summon1:SetScale(kSize)
	self.summon1:SetPoint("TOPLEFT")
	self.summon2:SetScale(kSize)
	self.summon2:SetPoint("TOPLEFT", self.BTN_SIZE + padding / kSize, 0)

	local width = (self.BTN_SIZE * kSize + padding) * 2 - padding
	local height = self.BTN_SIZE * kSize
	self:SetSize(width, height)
end


function panel:startDrag()
	if InCombatLockdown() or self:isLocked() then return end
	self.config.x, self.config.y = GetCursorPosition()
	self:setShown(true)
	self:GetScript("OnDragStart")(self)
end


function panel:stopDrag()
	self:GetScript("OnDragStop")(self)
end


function panel:setFade(value)
	self.config.fade = value
	self:SetAlpha(value)
end


function panel:setSpeed(pos)
	self.config.speedPos = pos

	if pos then
		self.speed:SetShown(mounts.mountAuraInstanceID ~= nil)
		mounts:on("MOUNTED_UPDATE.summonPanel", function(_, isMounted)
			self.speed:SetShown(isMounted)
		end)
		      :on("MOUNT_SPEED_UPDATE.summonPanel", function(_, ...)
			self.speed:SetText(util.getFormattedSpeed(...))
		end)
	else
		self.speed:Hide()
		mounts:off("MOUNTED_UPDATE.summonPanel")
		      :off("MOUNT_SPEED_UPDATE.summonPanel")
	end

	self.speed:ClearAllPoints()
	if pos == 1 then
		self.speed:SetPoint("BOTTOM", self, "TOP", 0, 2)
	elseif pos == 2 then
		self.speed:SetPoint("TOP", self, "BOTTOM", 0, -2)
	elseif pos == 3 then
		self.speed:SetPoint("RIGHT", self, "LEFT", -2, 0)
	else
		self.speed:SetPoint("LEFT", self, "RIGHT", 2, 0)
	end
end


-- BUTTONS
mounts:on("ADDON_INIT", function()
	panel.config = mounts.globalDB.summonPanelConfig
	panel.config.frameStrata = panel.config.frameStrata or 2
	panel.config.kSize = panel.config.kSize or 1
	panel.config.fade = panel.config.fade or 1
	local leftIcon = "|A:newplayertutorial-icon-mouse-leftbutton:0:0|a "
	-- local rightIcon = "|A:newplayertutorial-icon-mouse-rightbutton:0:0|a "

	local dragStart = function(self, ...)
		local parent = self:GetParent()
		parent:GetScript("OnDragStart")(parent, ...)
	end
	local dragStop = function(self, ...)
		local parent = self:GetParent()
		parent:GetScript("OnDragStop")(parent, ...)
	end

	-- SUMMON 1
	local summon1Handler = _G[util.secureButtonNameMount]
	local summon1 = CreateFrame("BUTTON", nil, panel, "MJSecureBarButtonTemplate")
	panel.summon1 = summon1
	summon1.id = 1
	summon1:SetScript("OnDragStart", dragStart)
	summon1:SetScript("OnDragStop", dragStop)
	summon1.icon:SetTexture(mounts.config.summon1Icon)
	summon1:SetAttribute("clickbutton", summon1Handler)
	SecureHandlerWrapScript(summon1, "OnClick", summon1Handler, [[owner:SetAttribute("useOnKeyDown", false);return nil, "post"]], [[owner:SetAttribute("useOnKeyDown", nil)]])
	summon1:SetPropagateMouseMotion(true)
	summon1:SetScript("OnEnter", function(btn)
		if panel.isDrag then return end
		GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
		GameTooltip_SetTitle(GameTooltip, ("%s \"%s %d\""):format(addon, SUMMONS, btn.id))
		if ns.macroFrame.currentRuleSet[btn.id].altMode then
			GameTooltip_AddNormalLine(GameTooltip, L["SecondMountTooltipDescription"]:gsub("\n\n", "\n"))
		else
			GameTooltip:AddLine(L["Normal mount summon"])
		end
		if not panel:isLocked() then
			GameTooltip:AddLine("\n")
			GameTooltip_AddColoredLine(GameTooltip, leftIcon..L["Left-button to drag"], NIGHT_FAE_BLUE_COLOR, false)
		end
		-- GameTooltip_AddColoredLine(GameTooltip, rightIcon..L["Right-button to open context menu"], NIGHT_FAE_BLUE_COLOR, false)
		if InCombatLockdown() then
			GameTooltip_AddErrorLine(GameTooltip, SPELL_FAILED_AFFECTING_COMBAT)
		end
		GameTooltip:Show()
	end)

	summon1Handler:HookScript("OnMouseDown", function() summon1:GetPushedTexture():Show() end)
	summon1Handler:HookScript("OnMouseUp", function() summon1:GetPushedTexture():Hide() end)

	-- SUMMON 2
	local summon2Handler = _G[util.secureButtonNameSecondMount]
	local summon2 = CreateFrame("BUTTON", nil, panel, "MJSecureBarButtonTemplate")
	panel.summon2 = summon2
	summon2.id = 2
	summon2:SetScript("OnDragStart", dragStart)
	summon2:SetScript("OnDragStop", dragStop)
	summon2.icon:SetTexture(mounts.config.summon2Icon)
	summon2:SetAttribute("clickbutton", summon2Handler)
	SecureHandlerWrapScript(summon2, "OnClick", summon2Handler, [[owner:SetAttribute("useOnKeyDown", false);return nil, "post"]], [[owner:SetAttribute("useOnKeyDown", nil)]])
	summon2:SetPropagateMouseMotion(true)
	summon2:SetScript("OnEnter", summon1:GetScript("OnEnter"))

	summon2Handler:HookScript("OnMouseDown", function() summon2:GetPushedTexture():Show() end)
	summon2Handler:HookScript("OnMouseUp", function() summon2:GetPushedTexture():Hide() end)

	panel:setStrata()
	panel:setSize()
	panel:setShown(panel.config.isShown)
	panel:setSpeed(panel.config.speedPos)
	panel:GetScript("OnLeave")(panel)
	panel:RegisterEvent("UI_SCALE_CHANGED")
	hooksecurefunc(UIParent, "SetScale", function() panel:GetScript("OnEvent")(panel) end)
end)
