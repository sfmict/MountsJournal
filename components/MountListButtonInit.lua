local _, ns = ...


ns.journal:on("MODULES_INIT", function(journal)
	local function typeClick(btn) journal:mountToggle(btn) end
	local function mouseDown(btn, mouse) journal.tags:hideDropDown(mouse) end
	local function dragClick(btn, mouse) journal.tags:dragButtonClick(btn, mouse) end
	local function click(btn, mouse) journal.tags:listItemClick(btn, mouse) end
	local function drag(btn) journal.tags:dragMount(btn.spellID or btn:GetParent().spellID) end

	local function onEnter(self)
		self.highlight:Show()
		local f = self.mountID and self or self:GetParent()
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		if type(f.mountID) == "number" then
			GameTooltip:SetMountBySpellID(f.spellID)
		elseif f.spellID then
			GameTooltip:SetSpellByID(f.spellID)
		end
	end

	local function onLeave(self)
		self.highlight:Hide()
		GameTooltip:Hide()
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
					btn.fly:SetScript("OnClick", typeClick)
					btn.ground:SetScript("OnClick", typeClick)
					btn.swimming:SetScript("OnClick", typeClick)
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
				frame.fly:SetScript("OnClick", typeClick)
				frame.ground:SetScript("OnClick", typeClick)
				frame.swimming:SetScript("OnClick", typeClick)
			end
		end
	end)
end)