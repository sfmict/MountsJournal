local addon, ns = ...
local L, mounts, util, journal = ns.L, ns.mounts, ns.util, ns.journal
local BTN_SIZE = 45


-- PANEL
local panel = CreateFrame("FRAME", nil, UIParent)
journal.summonPanel = panel
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
	self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", self.config.x / scale,  self.config.y / scale)
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
	self.summon2:SetPoint("TOPLEFT", BTN_SIZE + padding / kSize, 0)

	local width = (BTN_SIZE * kSize + padding) * 2 - padding
	local height = BTN_SIZE * kSize
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


journal:on("MODULES_INIT", function(journal)
	-- FADE OUT
	panel.fade = CreateFrame("FRAME", nil, nil, "MJSliderFrameTemplate")
	panel.fade:setOnChanged(function(frame, value)
		panel:setFade(value)
	end)
	panel.fade:setStep(.1)
	panel.fade:setMinMax(0, 1)
	panel.fade:setText(L["Fade out (opacity)"])

	-- RESIZE
	panel.resize = CreateFrame("FRAME", nil, nil, "MJSliderFrameTemplate")
	panel.resize:setOnChanged(function(frame, value)
		panel:setSize(value / BTN_SIZE)
	end)
	panel.resize:setStep(1)
	panel.resize:setMinMax(20, 90)
	panel.resize:setText(L["Button size"])

	-- CONTEXT MENU
	local dd = journal.bgFrame.summonPanelSettings
	LibStub("LibSFDropDown-1.5"):SetMixin(dd)
	dd:ddSetDisplayMode(addon)
	dd:ddHideWhenButtonHidden()
	dd:ddSetNoGlobalMouseEvent(true)
	dd:SetShown(panel.config.isShown)

	panel:HookScript("OnShow", function(self)
		dd:SetShown(journal.bgFrame.summon1:IsShown())
	end)
	panel:HookScript("OnHide", function()
		dd:Hide()
	end)

	dd:ddSetInitFunc(function(dd, level, value)
		local info = {}

		if level == 1 then
			info.notCheckable = true
			info.isTitle = true
			info.text = L["Summon panel"]
			dd:ddAddButton(info, level)

			dd:ddAddSeparator(level)

			info.isTitle = nil
			info.text = panel:isLocked() and UNLOCK or LOCK
			info.func =  function() panel:setLocked(not panel:isLocked()) end
			dd:ddAddButton(info, level)

			info.hasArrow = true
			info.text = L["Strata of panel"]
			info.value = "strata"
			dd:ddAddButton(info, level)

			info.customFrame = panel.fade
			info.OnLoad = function(frame)
				frame:setValue(panel.config.fade)
			end
			dd:ddAddButton(info)

			info.customFrame = panel.resize
			info.OnLoad = function(frame)
				frame:SetEnabled(not InCombatLockdown())
				frame:setValue(math.floor(BTN_SIZE * panel.config.kSize + .5))
			end
			dd:ddAddButton(info)

			info.customFrame = nil
			info.hasArrow = nil
			info.disabled = InCombatLockdown()
			info.text = L["Reset size"]
			info.func = function() panel:setSize(1) end
			dd:ddAddButton(info, level)

			info.text = HIDE
			info.func = function() panel:setShown(false) end
			dd:ddAddButton(info, level)
		elseif value == "strata" then
			local strata = {[0] = "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN"}

			local function func(btn)
				panel:setStrata(btn.value)
				dd:ddRefresh(level)
			end

			local function checked(btn)
				return btn.value == panel.config.frameStrata
			end

			info.disabled = InCombatLockdown()
			info.keepShownOnClick = true
			for i = 0, #strata do
				info.text = strata[i]
				info.value = i
				info.func = func
				info.checked = checked
				dd:ddAddButton(info, level)
			end
		end
	end)

	dd:SetScript("OnClick", function(dd)
		dd:ddToggle(1, nil, dd)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)
end)


-- BUTTONS
mounts:on("CREATE_BUTTONS", function()
	panel.config = mounts.globalDB.summonPanelConfig
	panel.config.frameStrata = panel.config.frameStrata or 2
	panel.config.kSize = panel.config.kSize or 1
	panel.config.fade = panel.config.fade or 1
	local leftIcon = "|A:newplayertutorial-icon-mouse-leftbutton:0:0|a "
	-- local rightIcon = "|A:newplayertutorial-icon-mouse-rightbutton:0:0|a "

	local summon1 = CreateFrame("BUTTON", nil, panel, "MJSecureBarButtonTemplate")
	panel.summon1 = summon1
	summon1:SetPropagateMouseClicks(true)
	summon1:SetPropagateMouseMotion(true)
	summon1.icon:SetTexture(mounts.config.summon1Icon)
	summon1:SetAttribute("clickbutton", _G[util.secureButtonNameMount])
	summon1:SetScript("OnEnter", function(btn)
		if panel.isDrag then return end
		GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
		GameTooltip_SetTitle(GameTooltip, addon.." \""..SUMMONS.." 1\"")
		GameTooltip:AddLine(L["Normal mount summon"])
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

	local summon2 = CreateFrame("BUTTON", nil, panel, "MJSecureBarButtonTemplate")
	panel.summon2 = summon2
	summon2:SetPropagateMouseClicks(true)
	summon2:SetPropagateMouseMotion(true)
	summon2.icon:SetTexture(mounts.config.summon2Icon)
	summon2:SetAttribute("clickbutton", _G[util.secureButtonNameSecondMount])
	summon2:SetScript("OnEnter", function(btn)
		if panel.isDrag then return end
		GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
		GameTooltip_SetTitle(GameTooltip, addon.." \""..SUMMONS.." 2\"")
		GameTooltip_AddNormalLine(GameTooltip, L["SecondMountTooltipDescription"]:gsub("\n\n", "\n"))
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

	panel:setStrata()
	panel:setSize()
	panel:setShown(panel.config.isShown)
	panel:GetScript("OnLeave")(panel)
	panel:RegisterEvent("UI_SCALE_CHANGED")
	hooksecurefunc(UIParent, "SetScale", function() panel:GetScript("OnEvent")(panel) end)
end)