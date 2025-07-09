local _, ns = ...
local L = ns.L


ns.journal:on("MODULES_INIT", function(journal)
	local function mouseDown(btn, mouse) journal.tags:hideDropDown(mouse) end
	local function dragClick(btn, mouse) journal.tags:dragButtonClick(btn, mouse) end
	local function click(btn, mouse) journal.tags:listItemClick(btn, btn.modelScene and "cursor" or btn, mouse) end
	local function drag(btn) journal.tags:dragMount(btn.spellID or btn:GetParent().spellID) end

	local function typeClick(btn)
		local parent = btn:GetParent()
		journal:mountToggle(btn.type, parent.spellID, parent.mountID)
	end

	local function onEnter(self)
		self.highlight:Show()
		local f = self.mountID and self or self:GetParent()
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		if type(f.mountID) == "number" then
			GameTooltip:SetMountBySpellID(f.spellID)
		elseif f.spellID then
			GameTooltip:SetSpellByID(f.spellID)
		end

		if not (self:GetParent().modelScene or journal.mountDisplay:IsShown()) then
			local _,_,_, creatureID, _,_, isSelfMount, _, modelSceneID, animID, spellVisualKitID, disablePlayerMountPreview = journal:getMountInfoExtra(f.mountID)
			if not creatureID then
				creatureID = journal:getMountFirstCreatureDisplayID(f.mountID)
			end
			MJTooltipModel.model:SetFromModelSceneID(modelSceneID)
			journal:setMountToModelScene(MJTooltipModel.model, creatureID, isSelfMount, animID, disablePlayerMountPreview, spellVisualKitID)

			MJTooltipModel:ClearAllPoints()
			MJTooltipModel:SetPoint("BOTTOMLEFT", GameTooltip, "BOTTOMRIGHT", -2, 0)
			MJTooltipModel:Show()
		end
	end

	local function onLeave(self)
		self.highlight:Hide()
		GameTooltip:Hide()
		MJTooltipModel:Hide()
	end

	local function rarity_OnEnter(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(L["Collected by %s of players"]:format(self:GetText()))
		GameTooltip:Show()
	end

	local backdrop = {
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileEdge = true,
		tileSize = 14,
		edgeSize = 14,
		insets = {left = 3, right = 3, top = 3, bottom = 3}
	}

	local model_OnEnter, model_OnLeave do
		local inspectFrame = CreateFrame("FRAME", nil, journal.bgFrame, "DefaultPanelTemplate,MJEscHideTemplate")
		journal.inspectFrame = inspectFrame
		inspectFrame:SetPoint("TOP", 0, -60)
		inspectFrame:SetFrameLevel(journal.bgFrame:GetFrameLevel() + 1000)
		inspectFrame:SetClampedToScreen(true)
		inspectFrame:EnableMouse(true)
		inspectFrame:SetMovable(true)
		inspectFrame:RegisterForDrag("LeftButton")
		inspectFrame:SetScript("OnDragStart", inspectFrame.StartMoving)
		inspectFrame:SetScript("OnDragStop", inspectFrame.StopMovingOrSizing)
		inspectFrame.close = CreateFrame("BUTTON", nil, inspectFrame, "UIPanelCloseButtonNoScripts")
		inspectFrame.close:SetSize(22, 22)
		inspectFrame.close:SetPoint("TOPRIGHT", 0, 0)
		inspectFrame.close:SetFrameLevel(inspectFrame:GetFrameLevel() + 1)
		inspectFrame.close:SetScript("OnClick", function(btn)
			btn:GetParent():Hide()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		end)
		inspectFrame:HookScript("OnShow", function(frame)
			local height = journal.bgFrame:GetHeight() - 86
			frame:SetSize(height * .85, height)
			journal.mountDisplay:SetParent(frame)
			journal.mountDisplay:ClearAllPoints()
			journal.mountDisplay:SetPoint("TOPLEFT", 8, -22)
			journal.mountDisplay:SetPoint("BOTTOMRIGHT", -4, 5)
			journal.mountDisplay:Show()
		end)
		inspectFrame:HookScript("OnHide", function(frame)
			frame:Hide()
			journal.mountDisplay:SetParent(journal.bgFrame)
			journal.mountDisplay:ClearAllPoints()
			journal.mountDisplay:SetPoint("TOPLEFT", journal.rightInset, 3, -3)
			journal.mountDisplay:SetPoint("BOTTOMRIGHT", journal.rightInset, -3, 3)
			journal.mountDisplay:Hide()
		end)

		local inspect = CreateFrame("BUTTON")
		inspect:Hide()
		inspect:SetSize(20, 20)
		inspect:SetAlpha(.5)
		inspect:SetPropagateMouseMotion(true)
		inspect.icon = inspect:CreateTexture(nil, "BACKGROUND")
		inspect.icon:SetTexture("interface/cursor/crosshair/inspect.blp")
		inspect.icon:SetPoint("CENTER")
		inspect.icon:SetSize(20, 20)
		inspect:SetScript("OnEnter", function(btn) btn:SetAlpha(1) end)
		inspect:SetScript("OnLeave", function(btn) btn:SetAlpha(.5) end)
		inspect:SetScript("OnMouseDown", function(btn) btn.icon:SetScale(.9) end)
		inspect:SetScript("OnMouseUp", function(btn) btn.icon:SetScale(1) end)
		inspect:SetScript("OnClick", function(btn)
			local parent = btn:GetParent()
			if parent.mountID ~= journal.selectedMountID then
				journal:setSelectedMount(parent.mountID, parent.spellID)
			end
			inspectFrame:Show()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		end)

		local hint = CreateFrame("Frame", nil, nil, "MJHelpPlate")
		hint:Hide()
		hint:SetScale(.7)
		hint:SetAlpha(.5)
		hint:SetPropagateMouseMotion(true)
		hint:SetPoint("BOTTOM", inspect, "TOP", 3 / .7, -10 / .7)
		hint:SetScript("OnEnter", function(hint)
			hint.highlight:Show()
			hint:SetAlpha(1)
			GameTooltip:SetOwner(hint, "ANCHOR_RIGHT", -14, -14)
			local parent = hint:GetParent()
			journal:setMountTooltip(parent.mountID, parent.spellID, true)
			GameTooltip:Show()
		end)
		hint:SetScript("OnLeave", function(hint)
			hint.highlight:Hide()
			hint:SetAlpha(.5)
			GameTooltip:Hide()
		end)

		function model_OnEnter(btn)
			btn:SetBackdropBorderColor(.6, .6, .6)
			inspect:SetParent(btn)
			inspect:SetPoint("BOTTOMRIGHT", -8, 4)
			inspect:Show()
			hint:SetParent(btn)
			hint:Show()
		end

		function model_OnLeave(btn)
			if btn.selected then
				btn:SetBackdropBorderColor(.8, .6, 0)
			else
				btn:SetBackdropBorderColor(.3, .3, .3)
			end
			hint:Hide()
			inspect:Hide()
		end
	end

	local function modelLoaded(actor)
		journal:event("MOUNT_MODEL_LOADED", actor:GetParent():GetParent())
	end

	local function AcquireAndInitializeActor(self, actorInfo)
		if actorInfo.scriptTag == "unwrapped" then
			self:GetActorByTag("unwrapped"):SetOnSizeChangedCallback(modelLoaded)
		end
	end

	local function SetActiveCamera(self)
		journal:event("SET_ACTIVE_CAMERA", self.activeCamera, true)
	end

	journal.view:RegisterCallback(journal.view.Event.OnAcquiredFrame, function(owner, frame, elementData, new)
		if new then
			frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

			if frame.modelScene then
				frame:SetBackdrop(ns.util.modelScenebackdrop)
				frame:SetBackdropColor(.1, .1, .1, .9)
				frame:SetBackdropBorderColor(.3, .3, .3)
				frame:SetScript("OnMouseDown", click)
				frame:SetScript("OnEnter", model_OnEnter)
				frame:SetScript("OnLeave", model_OnLeave)
				frame.rarity:SetScript("OnEnter", rarity_OnEnter)
				frame.rarity:SetScript("OnLeave", GameTooltip_Hide)
				frame.rarity:SetMouseClickEnabled(false)
				frame.modelScene:SetScript("OnMouseWheel", nil)
				hooksecurefunc(frame.modelScene, "AcquireAndInitializeActor", AcquireAndInitializeActor)
				hooksecurefunc(frame.modelScene, "SetActiveCamera", SetActiveCamera)
			else
				frame:SetScript("OnMouseDown", mouseDown)
				frame:SetScript("OnClick", click)
			end

			if frame.dragButton then
				frame.dragButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
				frame.dragButton:RegisterForDrag("LeftButton")
				frame.dragButton:SetScript("OnMouseDown", mouseDown)
				frame.dragButton:SetScript("OnClick", dragClick)
				frame.dragButton:SetScript("OnDragStart", drag)
				frame.dragButton:SetScript("OnEnter", onEnter)
				frame.dragButton:SetScript("OnLeave", onLeave)
			else
				frame:RegisterForDrag("LeftButton")
				frame:SetScript("OnDragStart", drag)
				frame:SetScript("OnEnter", onEnter)
				frame:SetScript("OnLeave", onLeave)
			end

			if frame.fly then
				frame.fly:SetScript("OnClick", typeClick)
				frame.ground:SetScript("OnClick", typeClick)
				frame.swimming:SetScript("OnClick", typeClick)
			end
		end
	end)
end)