local addon, L = ...
local mounts, config = MountsJournal, MountsJournalConfig
local PANEL_WIDTH = 101
local PANEL_HEIGHT = 65


-- PANEL
local panel = CreateFrame("BUTTON", nil, UIParent, "TooltipBackdropTemplate")
mounts.summonPanel = panel
panel:SetFrameLevel(1000)
panel:SetMovable(true)
panel:RegisterForClicks("RightButtonUp")
panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart", function(self)
	if self.config.isLocked then return end
	self.NineSlice:Hide()
	self.resize:Hide()
	self:StartMoving()
	self.isDrag = true
end)
panel:SetScript("OnDragStop", function(self)
	if self.isDrag then
		self.isDrag = nil
		self.NineSlice:Show()
		self.resize:Show()
		self:StopMovingOrSizing()
		self:savePosition()
	end
end)
panel:SetScript("OnEvent", function(self)
	if InCombatLockdown() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	else
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		self:setPosition()
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
	local k = math.min(width / PANEL_WIDTH, height / PANEL_HEIGHT)
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


-- PANEL METHODS
function panel:setStrata(strata)
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
	if InCombatLockdown() then return end
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
	self:GetScript("OnDragStart")(self)
end


function panel:stopDrag()
	self:GetScript("OnDragStop")(self)
end


-- CONTEXT MENU
local contextMenu = LibStub("LibSFDropDown-1.5"):SetMixin({})
contextMenu:ddSetDisplayMode("menu")
contextMenu:ddHideWhenButtonHidden(panel)

contextMenu:ddSetInitFunc(function(self, level, value)
	local info = {}

	if level == 1 then
		info.notCheckable = true
		info.text = panel.config.isLocked and UNLOCK or LOCK
		info.func =  function() panel:setLocked(not panel.config.isLocked) end
		self:ddAddButton(info, level)

		info.hasArrow = true
		info.text = L["Strata of panel"]
		info.value = "strata"
		self:ddAddButton(info, level)

		info.hasArrow = nil
		info.text = L["Reset size"]
		info.func = function() panel:setSize(1) end
		self:ddAddButton(info, level)

		info.text = HIDE
		info.func = function() panel:setShown(false) end
		self:ddAddButton(info, level)
	elseif value == "strata" then
		local strata = {[0] = "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN"}

		local function func(btn)
			panel:setStrata(btn.value)
			self:ddRefresh(level)
		end

		local function checked(btn)
			return btn.value == panel.config.frameStrata
		end

		info.keepShownOnClick = true
		for i = 0, #strata do
			info.text = strata[i]
			info.value = i
			info.func = func
			info.checked = checked
			self:ddAddButton(info, level)
		end
	end
end)

panel:SetScript("OnClick", function(self)
	contextMenu:ddToggle(1, nil, "cursor")
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
	summon1:SetPoint("RIGHT", panel, "CENTER", -3, 0)
	summon1:SetNormalTexture(413588)
	summon1.icon = summon1:GetNormalTexture()
	summon1:SetAttribute("clickbutton", _G[config.secureButtonNameMount])
	summon1:SetScript("OnEnter", function(btn)
		GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
		GameTooltip_SetTitle(GameTooltip, addon.." \""..SUMMONS.." 1\"")
		GameTooltip:AddLine(L["Normal mount summon"])
		GameTooltip:AddLine("\n")
		if not panel.config.isLocked then
			GameTooltip_AddColoredLine(GameTooltip, leftIcon..L["Left-button to drag"], NIGHT_FAE_BLUE_COLOR, false)
		end
		GameTooltip_AddColoredLine(GameTooltip, rightIcon..L["Right-button to open context menu"], NIGHT_FAE_BLUE_COLOR, false)
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
	summon2:SetAttribute("clickbutton", _G[config.secureButtonNameSecondMount])
	summon2:SetScript("OnEnter", function(btn)
		GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
		GameTooltip_SetTitle(GameTooltip, addon.." \""..SUMMONS.." 2\"")
		GameTooltip_AddNormalLine(GameTooltip, L["SecondMountTooltipDescription"]:gsub("\n\n", "\n"))
		GameTooltip:AddLine("\n")
		if not panel.config.isLocked then
			GameTooltip_AddColoredLine(GameTooltip, leftIcon..L["Left-button to drag"], NIGHT_FAE_BLUE_COLOR, false)
		end
		GameTooltip_AddColoredLine(GameTooltip, rightIcon..L["Right-button to open context menu"], NIGHT_FAE_BLUE_COLOR, false)
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