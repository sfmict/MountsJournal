local _, ns = ...
local L, journal = ns.L, ns.journal


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

	if not (self:GetParent().modelScene or journal.mountDisplay:IsShown()) then
		local _,_,_, creatureID, _,_, isSelfMount, _, modelSceneID, animID, spellVisualKitID, disablePlayerMountPreview = journal:getMountInfoExtra(f.mountID)
		if not creatureID then
			creatureID = journal:getMountFirstCreatureDisplayID(f.mountID)
		end
		MJTooltipModel.model:SetFromModelSceneID(modelSceneID)
		journal:setMountToModelScene(MJTooltipModel.model, creatureID, isSelfMount, animID, disablePlayerMountPreview, spellVisualKitID)
		MJTooltipModel:ClearAllPoints()
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		MJTooltipModel:SetPoint("BOTTOMLEFT", self, "TOPLEFT")
		GameTooltip:SetPoint("BOTTOMLEFT", MJTooltipModel, "BOTTOMRIGHT", -2, 0)
		MJTooltipModel:Show()
	else
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
	end

	if type(f.mountID) == "number" then
		GameTooltip:SetMountBySpellID(f.spellID)
	elseif f.spellID then
		GameTooltip:SetSpellByID(f.spellID)
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

local model_OnEnter, model_OnLeave do
	local inspect = CreateFrame("BUTTON", nil, nil, "MJMotionPropagateTemplate")
	inspect:Hide()
	inspect:SetSize(20, 20)
	inspect:SetAlpha(.5)
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
		journal.inspectFrame:Show()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	local hint = CreateFrame("Frame", nil, nil, "MJHelpPlate,MJMotionPropagateTemplate")
	hint:Hide()
	hint:SetScale(.7)
	hint:SetAlpha(.5)
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
	local frame = actor:GetParent():GetParent()
	frame.loading:Hide()
	journal:event("MOUNT_MODEL_LOADED", frame)
end

local function AcquireAndInitializeActor(self, actorInfo)
	if actorInfo.scriptTag == "unwrapped" then
		self:GetActorByTag("unwrapped"):SetOnSizeChangedCallback(modelLoaded)
	end
end

local function SetActiveCamera(self)
	journal:event("SET_ACTIVE_CAMERA", self.activeCamera, true)
end

function MJMountListButton_OnLoad(self)
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	if self.modelScene then
		self:SetBackdrop(ns.util.modelScenebackdrop)
		self:SetBackdropColor(.1, .1, .1, .9)
		self:SetBackdropBorderColor(.3, .3, .3)
		self:SetScript("OnMouseDown", click)
		self:SetScript("OnEnter", model_OnEnter)
		self:SetScript("OnLeave", model_OnLeave)
		self.rarity:SetScript("OnEnter", rarity_OnEnter)
		self.rarity:SetScript("OnLeave", GameTooltip_Hide)
		self.rarity:SetMouseClickEnabled(false)
		self.modelScene:SetScript("OnMouseWheel", nil)
		hooksecurefunc(self.modelScene, "AcquireAndInitializeActor", AcquireAndInitializeActor)
		hooksecurefunc(self.modelScene, "SetActiveCamera", SetActiveCamera)
	else
		self:SetScript("OnMouseDown", mouseDown)
		self:SetScript("OnClick", click)
	end

	if self.dragButton then
		self.dragButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		self.dragButton:RegisterForDrag("LeftButton")
		self.dragButton:SetScript("OnMouseDown", mouseDown)
		self.dragButton:SetScript("OnClick", dragClick)
		self.dragButton:SetScript("OnDragStart", drag)
		self.dragButton:SetScript("OnEnter", onEnter)
		self.dragButton:SetScript("OnLeave", onLeave)
	else
		self:RegisterForDrag("LeftButton")
		self:SetScript("OnDragStart", drag)
		self:SetScript("OnEnter", onEnter)
		self:SetScript("OnLeave", onLeave)
	end

	if self.fly then
		self.fly:SetScript("OnClick", typeClick)
		self.ground:SetScript("OnClick", typeClick)
		self.swimming:SetScript("OnClick", typeClick)
	end
end
