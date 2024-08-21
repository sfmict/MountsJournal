local addon, ns = ...
local L, mounts, util, journal = ns.L, ns.mounts, ns.util, ns.journal
local PANEL_WIDTH = 101
local PANEL_HEIGHT = 65


-- PANEL
local panel = CreateFrame("FRAME", nil, UIParent, "TooltipBackdropTemplate")
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

local drag = CreateFrame("FRAME", nil, panel)
panel.drag = drag
drag:SetFrameLevel(1000)
drag:EnableMouse(true)
drag:RegisterForDrag("LeftButton")
drag:SetScript("OnDragStart", function(self)
	local panel = self:GetParent()
	if panel.config.isLocked then return end
	panel.NineSlice:Hide()
	panel.resize:Hide()
	panel:StartMoving()
	panel.isDrag = true
end)
drag:SetScript("OnDragStop", function(self)
	local panel = self:GetParent()
	if panel.isDrag then
		panel.isDrag = nil
		panel.NineSlice:Show()
		panel.resize:Show()
		panel:StopMovingOrSizing()
		panel:savePosition()
	end
end)


-- RESIZE
local resize = CreateFrame("BUTTON", nil, panel)
panel.resize = resize
resize:SetNormalTexture("Interface/ChatFrame/UI-ChatIM-SizeGrabber-Up")
resize:SetHighlightTexture("Interface/ChatFrame/UI-ChatIM-SizeGrabber-Highlight")
resize:SetPushedTexture("Interface/ChatFrame/UI-ChatIM-SizeGrabber-Down")
resize:SetSize(16, 16)
resize:SetPoint("BOTTOMRIGHT")
resize:RegisterForDrag("LeftButton")

resize:SetScript("OnMouseDown", function(self)
	local x, y = GetCursorPosition()
	local scale = self:GetEffectiveScale()
	self.x = x / scale
	self.y = y / scale
	self.width, self.height = self:GetParent():GetSize()
end)

local function resizeOnUpdate(self)
	local x, y = GetCursorPosition()
	local scale = self:GetEffectiveScale()
	local width = self.width + x / scale - self.x
	local height = self.height + self.y - y / scale
	local k = math.max(width / PANEL_WIDTH, height / PANEL_HEIGHT)
	if k < .5 then k = .5
	elseif k > 3 then k = 3 end
	self:GetParent():setSize(k)
end

resize:SetScript("OnDragStart", function(self)
	self:SetScript("OnUpdate", resizeOnUpdate)
end)

resize:SetScript("OnDragStop", function(self)
	self:SetScript("OnUpdate", nil)
end)

resize:SetScript("OnEnter", function()
	if SetCursor then SetCursor("UI_RESIZE_CURSOR") end
end)

resize:SetScript("OnLeave", function()
	if SetCursor then SetCursor(nil) end
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
	self.config.x = self:GetLeft() * scale
	self.config.y = self:GetTop() * scale
	self:setPosition()
end


function panel:setPosition()
	if InCombatLockdown() or not self:IsShown() then return end
	self:ClearAllPoints()
	local scale = self:GetEffectiveScale()
	self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.config.x / scale,  self.config.y / scale)
end


function panel:setShown(show)
	if InCombatLockdown() then return end
	self.config.isShown = show
	self:SetShown(show)
	if show then
		self:setPosition()
	else
		self:setStrata(2)
		self:setLocked(false)
	end
end


function panel:setLocked(lock)
	self.config.isLocked = lock
	self.NineSlice:SetShown(not lock)
	self.resize:SetShown(not lock)
	self.drag:ClearAllPoints()
	if lock then
		self.drag:SetPoint("TOPLEFT", self.summon1.border)
		self.drag:SetPoint("BOTTOMRIGHT", self.summon2.border)
	else
		self.drag:SetAllPoints()
	end
end


function panel:setSize(kSize)
	if InCombatLockdown() then return end
	if kSize then self.config.kSize = kSize end
	local kSize = self.config.kSize

	self:SetSize(PANEL_WIDTH * kSize, PANEL_HEIGHT * kSize)
	self.summon1:SetSize(33 * kSize, 33 * kSize)
	self.summon1.border:SetSize(35 * kSize, 35 * kSize)
	self.summon1:SetPoint("RIGHT", self, "CENTER", -2 * kSize, 0)
	self.summon2:SetSize(33 * kSize, 33 * kSize)
	self.summon2.border:SetSize(35 * kSize, 35 * kSize)
	self.summon2:SetPoint("LEFT", self, "CENTER", 2 * kSize, 0)
end


function panel:startDrag()
	if InCombatLockdown() or self.config.isLocked then return end
	local x, y = GetCursorPosition()
	local scale = self:GetEffectiveScale()
	local width, height = self:GetSize()
	self.config.x = x - width / 2 * scale
	self.config.y = y + height / 2 * scale
	self:setShown(true)
	self.drag:GetScript("OnDragStart")(self.drag)
end


function panel:stopDrag()
	self.drag:GetScript("OnDragStop")(self.drag)
end


journal:on("MODULES_INIT", function(journal)
	-- CONTEXT MENU
	local dd = journal.bgFrame.summonPanelSettings
	LibStub("LibSFDropDown-1.5"):SetMixin(dd)
	dd:ddSetDisplayMode("menu")
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
			info.text = panel.config.isLocked and UNLOCK or LOCK
			info.func =  function() panel:setLocked(not panel.config.isLocked) end
			dd:ddAddButton(info, level)

			info.hasArrow = true
			info.text = L["Strata of panel"]
			info.value = "strata"
			dd:ddAddButton(info, level)

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
	local leftIcon = "|A:newplayertutorial-icon-mouse-leftbutton:0:0|a "
	local rightIcon = "|A:newplayertutorial-icon-mouse-rightbutton:0:0|a "

	local summon1 = CreateFrame("BUTTON", nil, panel, "MJSecureMacroButtonTemplate")
	panel.summon1 = summon1
	summon1:SetPropagateMouseClicks(true)
	summon1:SetNormalTexture(413588)
	summon1.icon = summon1:GetNormalTexture()
	summon1:SetAttribute("clickbutton", _G[util.secureButtonNameMount])
	summon1:SetScript("OnEnter", function(btn)
		GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
		GameTooltip_SetTitle(GameTooltip, addon.." \""..SUMMONS.." 1\"")
		GameTooltip:AddLine(L["Normal mount summon"])
		GameTooltip:AddLine("\n")
		if not panel.config.isLocked then
			GameTooltip_AddColoredLine(GameTooltip, leftIcon..L["Left-button to drag"], NIGHT_FAE_BLUE_COLOR, false)
		end
		-- GameTooltip_AddColoredLine(GameTooltip, rightIcon..L["Right-button to open context menu"], NIGHT_FAE_BLUE_COLOR, false)
		if InCombatLockdown() then
			GameTooltip_AddErrorLine(GameTooltip, SPELL_FAILED_AFFECTING_COMBAT)
		end
		GameTooltip:Show()
	end)

	local summon2 = CreateFrame("BUTTON", nil, panel, "MJSecureMacroButtonTemplate")
	panel.summon2 = summon2
	summon2:SetPropagateMouseClicks(true)
	summon2:SetNormalTexture(631718)
	summon2.icon = summon2:GetNormalTexture()
	summon2:SetAttribute("clickbutton", _G[util.secureButtonNameSecondMount])
	summon2:SetScript("OnEnter", function(btn)
		GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
		GameTooltip_SetTitle(GameTooltip, addon.." \""..SUMMONS.." 2\"")
		GameTooltip_AddNormalLine(GameTooltip, L["SecondMountTooltipDescription"]:gsub("\n\n", "\n"))
		GameTooltip:AddLine("\n")
		if not panel.config.isLocked then
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
	panel:setLocked(panel.config.isLocked)
	panel:RegisterEvent("UI_SCALE_CHANGED")
	hooksecurefunc(UIParent, "SetScale", function() panel:GetScript("OnEvent")(panel) end)
end)