if not DressUpFrame then return end
local addon, ns = ...
local mjBtn, curMountID = CreateFrame("BUTTON", nil, DressUpFrame)
DressUpFrame.mjBtn = mjBtn
mjBtn:SetFrameLevel(511)
mjBtn:SetSize(24, 24)
mjBtn:SetPoint("TOPLEFT", 60, 0)
mjBtn:SetNormalAtlas("RedButton-Expand")
mjBtn:GetNormalTexture():SetTexCoord(1, 0, 0, 1)
mjBtn:SetPushedAtlas("RedButton-Expand-Pressed")
mjBtn:GetPushedTexture():SetTexCoord(1, 0, 0, 1)
mjBtn:SetHighlightAtlas("RedButton-Highlight")
mjBtn:GetHighlightTexture():SetTexCoord(1, 0, 0, 1)

mjBtn:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(addon)
	GameTooltip:Show()
end)
mjBtn:SetScript("OnLeave", GameTooltip_Hide)
mjBtn:SetScript("OnClick", function()
	if InCombatLockdown() or not curMountID then return end
	ns.util.openJournalTab(3)
	ns.journal:setSelectedMount(curMountID)
end)

hooksecurefunc(DressUpFrame, "SetMode", function(self, mode)
	mjBtn:SetShown(mode == "mount")
end)

hooksecurefunc("DressUpMount", function(mountID)
	curMountID = mountID
end)
