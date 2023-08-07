local function typeClick(btn) MountsJournalFrame:mountToggle(btn) end
local function mouseDown(btn, mouse) MountsJournalFrame.tags:hideDropDown(mouse) end
local function dragClick(btn, mouse) MountsJournalFrame.tags:dragButtonClick(btn, mouse) end
local function click(btn, mouse) MountsJournalFrame.tags:listItemClick(btn, mouse) end
local function drag(btn) MountsJournalFrame.tags:dragMount(btn:GetParent().mountID) end


MJDefaultMountListMixin = {
	onMouseDown = mouseDown,
	onClick = click,
}


function MJDefaultMountListMixin:onLoad()
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	self.dragButton:SetScript("OnMouseDown", mouseDown)
	self.dragButton:SetScript("OnClick", dragClick)
	self.dragButton:SetScript("OnDragStart", drag)
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
	self.fly:SetScript("OnClick", typeClick)
	self.ground:SetScript("OnClick", typeClick)
	self.swimming:SetScript("OnClick", typeClick)
end


function MJGrid3MountListMixin:onEnter()
	self.highlight:Show()
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	if self.spellID then
		GameTooltip:SetMountBySpellID(self.spellID)
	end
end


function MJGrid3MountListMixin:onLeave()
	self.highlight:Hide()
	GameTooltip:Hide()
end


function MJGrid3MountListMixin:onDragStart()
	MountsJournalFrame.tags:dragMount(self.mountID)
end