MJMountEquipmentMixin = {}


function MJMountEquipmentMixin:onLoad()
	self:SetAttribute("useOnKeyDown", false)
	self:SetAttribute("type", "click")
	self:SetAttribute("clickbutton", MountJournal.SlotButton)
	hooksecurefunc("MountJournal_SetPendingApply", function(_, item)
		self:setPendingApply(item)
	end)
	hooksecurefunc("MountJournal_ClearPendingAndUpdate", function()
		self:clearPendingApply()
	end)
	self.SetEnabled = function() end
	self:updateMountEquipment()
end


function MJMountEquipmentMixin:onShow()
	self:updateMountEquipment()
	self:SetPendingApply(self.pendingItem ~= nil)
	self.NewAlert:ValidateIsShown()
	self:validateCursorDragSource()
	self:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
	self:RegisterEvent("CURSOR_CHANGED")
end


function MJMountEquipmentMixin:onHide()
	self:UnregisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
	self:UnregisterEvent("CURSOR_CHANGED")
end


function MJMountEquipmentMixin:onEnter()
	self:ClearAlert()
	self:initEquipmentTooltip()
end


function MJMountEquipmentMixin:onEvent(event, ...) self[event](self, ...) end


function MJMountEquipmentMixin:initEquipmentTooltip()
	local item = self:getDisplayedMountEquipment()
	if item then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetItemByID(item:GetItemID())
		GameTooltip:Show()
	else
		GameTooltip_ShowSimpleTooltip(GameTooltip, MOUNT_EQUIPMENT_NOTICE, SimpleTooltipConstants.NoOverrideColor, SimpleTooltipConstants.DoNotWrapText, self, "ANCHOR_RIGHT")
	end
end


function MJMountEquipmentMixin:updateEquipmentPalette()
	self:DesaturateHierarchy((not C_PlayerInfo.CanPlayerUseMountEquipment() or C_MountJournal.AreMountEquipmentEffectsSuppressed()) and 1 or 0)
end
MJMountEquipmentMixin.PLAYER_MOUNT_DISPLAY_CHANGED = MJMountEquipmentMixin.updateEquipmentPalette


function MJMountEquipmentMixin:validateCursorDragSource()
	local itemLocation = C_Cursor.GetCursorItem()
	local canApply = MountJournal_CanApplyMountEquipment(itemLocation)
	self:SetDragTargetAnimationPlaying(canApply)
end
MJMountEquipmentMixin.CURSOR_CHANGED = MJMountEquipmentMixin.validateCursorDragSource


function MJMountEquipmentMixin:getDisplayedMountEquipment()
	return self.pendingItem or self.currentItem
end


function MJMountEquipmentMixin:initMountEquipment(item)
	item:ContinueOnItemLoad(function()
		self:Initialize(item)
		if item and GameTooltip:IsShown() and GameTooltip:GetOwner() == self then
			self:initEquipmentTooltip()
		end
	end)
end


function MJMountEquipmentMixin:updateMountEquipment()
	local isUnlocked = C_PlayerInfo.CanPlayerUseMountEquipment()
	if not (self:IsShown() or InCombatLockdown()) then
		self:SetShown(isUnlocked)
	end

	local itemID = C_MountJournal.GetAppliedMountEquipmentID()
	if not self.currentItem or self.currentItem:GetItemID() ~= itemID then
		self.currentItem = itemID and Item:CreateFromItemID(itemID)
	end

	if isUnlocked then
		local displayedItem = self:getDisplayedMountEquipment()
		if displayedItem then
			self:initMountEquipment(displayedItem)
		end
	end

	self:updateEquipmentPalette()
end


function MJMountEquipmentMixin:setPendingApply(item)
	if item then
		self.pendingItem = item
		self:SetPendingApply(true)
	end
	self:updateMountEquipment()
end


function MJMountEquipmentMixin:clearPendingApply()
	if self.pendingItem then
		self.pendingItem = nil
		self:SetPendingApply(false)
	end
	self:updateMountEquipment()
end