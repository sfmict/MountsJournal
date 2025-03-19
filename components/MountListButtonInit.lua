local _, ns = ...


ns.journal:on("MODULES_INIT", function(journal)
	local function mouseDown(btn, mouse) journal.tags:hideDropDown(mouse) end
	local function dragClick(btn, mouse) journal.tags:dragButtonClick(btn, mouse) end
	local function click(btn, mouse) journal.tags:listItemClick(btn, mouse) end
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

		if not journal.mountDisplay:IsShown() then
			local _,_,_, creatureID, _,_, isSelfMount, _, modelSceneID, animID, spellVisualKitID = journal:getMountInfoExtra(f.mountID)
			MJTooltipModel.model:SetFromModelSceneID(modelSceneID)
			local mountActor = MJTooltipModel.model:GetActorByTag("unwrapped")
			if not mountActor then return end

			if creatureID == "player" then
				MJTooltipModel.model:GetActorByTag("player-rider"):ClearModel()
				local sheathWeapons = true
				local autoDress = true
				local hideWeapons = false
				local usePlayerNativeForm = true
				if mountActor:SetModelByUnit("player", sheathWeapons, autoDress, hideWeapons, usePlayerNativeForm) then
					mountActor:SetAnimationBlendOperation(Enum.ModelBlendOperation.None)
					mountActor:SetAnimation(618)
				else
					mountActor:ClearModel()
				end
			else
				if not creatureID then
					local allCreatureDisplays = C_MountJournal.GetMountAllCreatureDisplayInfoByID(f.mountID)
					if allCreatureDisplays and #allCreatureDisplays > 0 then
						creatureID = allCreatureDisplays[1].creatureDisplayID
					end
				end
				if creatureID then
					mountActor:SetModelByCreatureDisplayID(creatureID, true)
					if isSelfMount then
						mountActor:SetAnimationBlendOperation(Enum.ModelBlendOperation.None)
						mountActor:SetAnimation(618)
					else
						mountActor:SetAnimationBlendOperation(Enum.ModelBlendOperation.Anim)
						mountActor:SetAnimation(0)
					end
					MJTooltipModel.model:AttachPlayerToMount(mountActor, animID, isSelfMount, disablePlayerMountPreview or not GetCVarBool("mountJournalShowPlayer"), spellVisualKitID, PlayerUtil.ShouldUseNativeFormInModelScene())
				end
			end
			if creatureID then
				MJTooltipModel:ClearAllPoints()
				MJTooltipModel:SetPoint("BOTTOMLEFT", GameTooltip, "BOTTOMRIGHT", -2, 0)
				MJTooltipModel:Show()
			end
		end
	end

	local function onLeave(self)
		self.highlight:Hide()
		GameTooltip:Hide()
		MJTooltipModel:Hide()
	end

	journal.view:RegisterCallback(journal.view.Event.OnAcquiredFrame, function(owner, frame, elementData, new)
		if new then
			if frame.mounts then
				for i = 1, #frame.mounts do
					local btn = frame.mounts[i]
					btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
					btn:RegisterForDrag("LeftButton")
					btn:SetScript("OnMouseDown", mouseDown)
					btn:SetScript("OnClick", click)
					btn:SetScript("OnDragStart", drag)
					btn:SetScript("OnEnter", onEnter)
					btn:SetScript("OnLeave", onLeave)
					if btn.fly then
						btn.fly:SetScript("OnClick", typeClick)
						btn.ground:SetScript("OnClick", typeClick)
						btn.swimming:SetScript("OnClick", typeClick)
					end
				end
			else
				frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
				frame:SetScript("OnMouseDown", mouseDown)
				frame:SetScript("OnClick", click)
				frame.dragButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
				frame.dragButton:RegisterForDrag("LeftButton")
				frame.dragButton:SetScript("OnMouseDown", mouseDown)
				frame.dragButton:SetScript("OnClick", dragClick)
				frame.dragButton:SetScript("OnDragStart", drag)
				frame.dragButton:SetScript("OnEnter", onEnter)
				frame.dragButton:SetScript("OnLeave", onLeave)
				if frame.fly then
					frame.fly:SetScript("OnClick", typeClick)
					frame.ground:SetScript("OnClick", typeClick)
					frame.swimming:SetScript("OnClick", typeClick)
				end
			end
		end
	end)
end)