local addon, ns = ...
local panel, L = ns.mounts.summonPanel, ns.L


ns.journal:on("MODULES_INIT", function(journal)
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
		panel:setSize(value / panel.BTN_SIZE)
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
			info.func = function() panel:setLocked(not panel:isLocked()) end
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
				frame:setValue(math.floor(panel.BTN_SIZE * panel.config.kSize + .5))
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
