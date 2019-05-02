local addon, L = ...
local mounts = MountsJournal
local config = MountsJournalConfig
local atlas = CreateFrame("Frame", "MountsJournalConfigAtlas", InterfaceOptionsFramePanelContainer)
atlas.name = L["By Zone"]
atlas.parent = config.name


atlas:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		self[event](self, ...)
	end
end)
atlas:RegisterEvent("PLAYER_ENTERING_WORLD")
-- 

-- self.NavBar = self:AddOverlayFrame("WorldMapNavBarTemplate", "FRAME");
-- self.NavBar:SetPoint("TOPLEFT", self.TitleCanvasSpacerFrame, "TOPLEFT", 64, -25);
-- self.NavBar:SetPoint("BOTTOMRIGHT", self.TitleCanvasSpacerFrame, "BOTTOMRIGHT", -4, 9);


function atlas:addOverlayFrame()


end



-- 
atlas:SetScript("OnShow", function(self)
	self.navbar = CreateFrame("FRAME", nil, self, "MJNavBarTemplate")
	local navbar = self.navbar
	navbar:SetPoint("TOPLEFT", self, "TOPLEFT", 7, -4)
	navbar:SetPoint("TOPRIGHT", self, "TOPRIGHT", -7, 0)
	navbar:SetWidth(609)

	-- for i = 1, 3000 do
	-- 	local mapInfo = C_Map.GetMapInfo(i)
	-- 	if mapInfo then
	-- 		if string.find("Нагорье Арати", string.gsub(mapInfo.name, "-", "%%-")) then
	-- 			fprint(i, mapInfo.mapType, C_Map.GetMapArtID(i))
	-- 		end
	-- 	end
	-- end

	local function refresh()
		local mapInfo = C_Map.GetMapInfo(navbar.mapID)
		local hierarchy = {}
		while mapInfo and mapInfo.parentMapID > 0 do
			local buttonData = {
				name = mapInfo.name,
				id = mapInfo.mapID,
				OnClick = function(btn)
					btn:GetParent().mapID = btn.id
					refresh()
				end,
			}
			if self:isMapValidForNavBarDropDown(mapInfo.mapType) then
				buttonData.listFunc = self.getDropDownList
			end
			tinsert(hierarchy, 1, buttonData)
			mapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
		end

		NavBar_Reset(navbar)
		for i, buttonData in ipairs(hierarchy) do
			NavBar_AddButton(navbar, buttonData)
		end
	end

	local homeData = {
		name = WORLD,
		OnClick = function(btn)
			-- fprint("dump", btn)
			btn:GetParent().mapID = C_Map.GetBestMapForUnit("player") or C_Map.GetFallbackWorldMapID()
			refresh()
		end,
	}
	NavBar_Initialize(navbar, "NavButtonTemplate", homeData, navbar.home, navbar.overflow)
	navbar.mapID = C_Map.GetBestMapForUnit("player") or C_Map.GetFallbackWorldMapID()

	self:SetScript("OnShow", refresh)
	refresh()
end)


local mapValidTypes = {
	[Enum.UIMapType.World] = true,
	[Enum.UIMapType.Continent] = true,
	[Enum.UIMapType.Zone] = true,
}
function atlas:isMapValidForNavBarDropDown(mapType)
	return mapValidTypes[mapType]
end


function atlas:getDropDownList()
	local list = {}
	local mapInfo = C_Map.GetMapInfo(self.data.id)
	if mapInfo then
		local children = C_Map.GetMapChildrenInfo(mapInfo.parentMapID)
		if children then
			for i, childInfo in ipairs(children) do
				if atlas:isMapValidForNavBarDropDown(childInfo.mapType) then
					local data = {
						text = childInfo.name,
						id = childInfo.mapID,
						func = function(btn, mapID) fprint(mapID) end,
					}
					tinsert(list, data)
				else
					fprint(childInfo.name, childInfo.mapType)
				end
			end
			table.sort(list, function(a, b) return a.text < b.text end)
		end
	end
	return list
end


atlas.refresh = function(...)
	-- fprint("dump", "refresh", ...)
end


InterfaceOptions_AddCategory(atlas)


function atlas:openConfig()
	if InterfaceOptionsFrameAddOns:IsVisible() and self:IsVisible() then
		InterfaceOptionsFrame:Hide()
		self:cancel()
	else
		InterfaceOptionsFrame_OpenToCategory(atlas.name)
		if not InterfaceOptionsFrameAddOns:IsVisible() then
			InterfaceOptionsFrame_OpenToCategory(atlas.name)
		end
	end
end


function atlas:PLAYER_ENTERING_WORLD()
	self:openConfig()
end