local mapValidTypes = {
	[Enum.UIMapType.World] = true,
	[Enum.UIMapType.Continent] = true,
	[Enum.UIMapType.Zone] = true,
}
local function isMapValidForNavBarDropDown(mapType)
	return mapValidTypes[mapType]
end


MJNavBarMixin = {}


function MJNavBarMixin:onLoad()
	self.journal = MountsJournalFrame
	local homeData = {
		name = WORLD,
		OnClick = function() self:setDefMap() end,
	}
	NavBar_Initialize(self, "MJNavButtonTemplate", homeData, self.home, self.overflow)
	self:setDefMap()
end


function MJNavBarMixin:refresh()
	local hierarchy = {}
	local mapInfo = C_Map.GetMapInfo(self.mapID)
	while mapInfo and mapInfo.parentMapID > 0 do
		local btnData = {
			name = mapInfo.name,
			id = mapInfo.mapID,
			OnClick = function(self) self:GetParent():setMapID(self.data.id) end,
		}
		if isMapValidForNavBarDropDown(mapInfo.mapType) then
			btnData.listFunc = self.getDropDownList
		end
		tinsert(hierarchy, 1, btnData)
		mapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
	end

	NavBar_Reset(self)
	for _,btnData in ipairs(hierarchy) do
		NavBar_AddButton(self, btnData)
	end
end


function MJNavBarMixin:getDropDownList()
	local list = {}
	local mapInfo = C_Map.GetMapInfo(self.data.id)
	if mapInfo then
		local children = C_Map.GetMapChildrenInfo(mapInfo.parentMapID)
		if children then
			for i, childInfo in ipairs(children) do
				if isMapValidForNavBarDropDown(childInfo.mapType) then
					local data = {
						text = childInfo.name,
						id = childInfo.mapID,
						func = function(btn, mapID) self:GetParent():setMapID(mapID) end,
					}
					tinsert(list, data)
				end
			end
			table.sort(list, function(a, b) return a.text < b.text end)
		end
	end
	return list
end


function MJNavBarMixin:setMapID(mapID)
	self.mapID = mapID
	if self.journal.worldMap then self.journal.worldMap:setMapID(mapID) end
	if type(self.click) == "function" then self.click() end
	self:refresh()
end


function MJNavBarMixin:setDefMap()
	self:setMapID(MapUtil.GetMapParentInfo(MapUtil.GetDisplayableMapForPlayer(), Enum.UIMapType.Cosmic, true).mapID)
end


function MJNavBarMixin:setCurrentMap()
	self:setMapID(MapUtil.GetDisplayableMapForPlayer())
end