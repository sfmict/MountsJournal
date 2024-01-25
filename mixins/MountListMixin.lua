local function typeClick(btn) MountsJournalFrame:mountToggle(btn) end
local function mouseDown(btn, mouse) MountsJournalFrame.tags:hideDropDown(mouse) end
local function dragClick(btn, mouse) MountsJournalFrame.tags:dragButtonClick(btn, mouse) end
local function click(btn, mouse) MountsJournalFrame.tags:listItemClick(btn, mouse) end
local function drag(btn) MountsJournalFrame.tags:dragMount(btn:GetParent().spellID) end


MJDefaultMountListMixin = {
	onMouseDown = mouseDown,
	onClick = click,
}


function MJDefaultMountListMixin:onLoad()
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	self.dragButton:SetScript("OnMouseDown", mouseDown)
	self.dragButton:SetScript("OnClick", dragClick)
	self.dragButton:SetScript("OnDragStart", drag)
	self.dragonriding:SetScript("OnClick", typeClick)
	self.fly:SetScript("OnClick", typeClick)
	self.ground:SetScript("OnClick", typeClick)
	self.swimming:SetScript("OnClick", typeClick)
end


MJGrid3MountListMixin = {
	onMouseDown = mouseDown,
	onClick = click,
}


function MJGrid3MountListMixin:onLoad()
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	self:RegisterForDrag("LeftButton")
	self.dragonriding:SetScript("OnClick", typeClick)
	self.fly:SetScript("OnClick", typeClick)
	self.ground:SetScript("OnClick", typeClick)
	self.swimming:SetScript("OnClick", typeClick)
end


function MJGrid3MountListMixin:onEnter()
	self.highlight:Show()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	if type(self.mountID) == "number" then
		GameTooltip:SetMountBySpellID(self.spellID)
	elseif self.spellID then
		GameTooltip:SetSpellByID(self.spellID)
	end
end


function MJGrid3MountListMixin:onLeave()
	self.highlight:Hide()
	GameTooltip:Hide()
end


function MJGrid3MountListMixin:onDragStart()
	MountsJournalFrame.tags:dragMount(self.spellID)
end