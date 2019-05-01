local addon, L = ...
local mounts = MountsJournal
local config = MountsJournalConfig
local atlas = CreateFrame("Frame", "MountsJournalConfigAtlas", InterfaceOptionsFramePanelContainer)
atlas.name = L["By Zone"]
atlas.parent = config.name


atlas:SetScript("OnEvent", function(self, event, ...)
	if atlas[event] then
		atlas[event](self, ...)
	end
end)
atlas:RegisterEvent("PLAYER_ENTERING_WORLD")


atlas:SetScript("OnShow", function(...) fprint("dump", ...) end)


InterfaceOptions_AddCategory(atlas)


function atlas:openConfig()
	if InterfaceOptionsFrameAddOns:IsVisible() and atlas:IsVisible() then
		InterfaceOptionsFrame:Hide()
		atlas:cancel()
	else
		InterfaceOptionsFrame_OpenToCategory(atlas.name)
		if not InterfaceOptionsFrameAddOns:IsVisible() then
			InterfaceOptionsFrame_OpenToCategory(atlas.name)
		end
	end
end


function atlas:PLAYER_ENTERING_WORLD()
	atlas:openConfig()
end