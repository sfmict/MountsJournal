local addon, ns = ...
local mounts = ns.mounts


ns.journal:on("MODULES_INIT", function(journal)
	local inspectFrame = CreateFrame("FRAME", nil, journal.bgFrame, "DefaultPanelTemplate,MJEscHideTemplate")
	journal.inspectFrame = inspectFrame
	inspectFrame:SetFrameLevel(journal.bgFrame:GetFrameLevel() + 1000)
	inspectFrame:SetClampedToScreen(true)
	inspectFrame:EnableMouse(true)
	inspectFrame:SetMovable(true)
	inspectFrame:SetResizable(true)
	inspectFrame:RegisterForDrag("LeftButton")

	inspectFrame:SetScript("OnDragStart", inspectFrame.StartMoving)
	inspectFrame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local x, y = self:GetCenter()
		local scale = self:GetEffectiveScale()
		mounts.config.inspectX = x * scale
		mounts.config.inspectY = y * scale
		mounts.config.inspectWidth, mounts.config.inspectHeight = self:GetSize()
	end)
	inspectFrame:HookScript("OnShow", function(self)
		self:ClearAllPoints()
		if mounts.config.inspectX and mounts.config.inspectY then
			local scale = self:GetEffectiveScale()
			self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", mounts.config.inspectX / scale, mounts.config.inspectY / scale)
		else
			self:SetPoint("TOP", 0, -60)
		end

		local width, height = mounts.config.inspectWidth, mounts.config.inspectHeight
		if not (width and height) then
			height = journal.bgFrame:GetHeight() - 86
			width = height * .85
		end
		self:SetSize(width, height)

		journal.mountDisplay:SetParent(self)
		journal.mountDisplay:ClearAllPoints()
		journal.mountDisplay:SetPoint("TOPLEFT", 8, -22)
		journal.mountDisplay:SetPoint("BOTTOMRIGHT", -4, 5)
		journal.mountDisplay:Show()
	end)
	inspectFrame:HookScript("OnHide", function(self)
		self:Hide()
		journal.mountDisplay:SetParent(journal.bgFrame)
		journal.mountDisplay:ClearAllPoints()
		journal.mountDisplay:SetPoint("TOPLEFT", journal.rightInset, 3, -3)
		journal.mountDisplay:SetPoint("BOTTOMRIGHT", journal.rightInset, -3, 3)
		journal.mountDisplay:Hide()
	end)

	inspectFrame.close = CreateFrame("BUTTON", nil, inspectFrame, "UIPanelCloseButtonNoScripts")
	inspectFrame.close:SetSize(22, 22)
	inspectFrame.close:SetPoint("TOPRIGHT", 0, 0)
	inspectFrame.close:SetFrameLevel(inspectFrame:GetFrameLevel() + 1)
	inspectFrame.close:SetScript("OnClick", function(btn)
		btn:GetParent():Hide()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	inspectFrame.resize = CreateFrame("BUTTON", nil, inspectFrame, "MJResizeButtonTemplate")
	inspectFrame.resize:SetScript("OnDragStart", function(btn)
		local parent = btn:GetParent()
		local minWidth, minHeight = 442, 520
		local maxWidth = UIParent:GetWidth() - parent:GetLeft() - 10
		local maxHeight = parent:GetTop() - 10
		parent:SetResizeBounds(minWidth, minHeight, maxWidth, maxHeight)
		parent:StartSizing("BOTTOMRIGHT", true)
	end)
	inspectFrame.resize:SetScript("OnDragStop", function(btn)
		local parent = btn:GetParent()
		parent:GetScript("OnDragStop")(parent)
	end)

	local settings = CreateFrame("BUTTON", nil, inspectFrame, "MJSettingsButtonTemplate")
	inspectFrame.settings = settings
	settings:SetPoint("TOPRIGHT", -25, -3)

	LibStub("LibSFDropDown-1.5"):SetMixin(settings)
	settings:ddSetDisplayMode(addon)
	settings:ddHideWhenButtonHidden()
	settings:ddSetNoGlobalMouseEvent(true)

	settings:ddSetInitFunc(function(dd, level)
		local info = {}

		info.notCheckable = true
		info.text = RESET
		info.func = function()
			mounts.config.inspectWidth = nil
			mounts.config.inspectHeight = nil
			mounts.config.inspectX = nil
			mounts.config.inspectY = nil
			inspectFrame:GetScript("OnShow")(inspectFrame)
		end
		dd:ddAddButton(info, level)
	end)

	settings:SetScript("OnClick", function(btn)
		btn:ddToggle(1, nil, btn)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)
end)
