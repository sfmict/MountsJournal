MJMapCanvasMixin = {}


function MJMapCanvasMixin:onLoad()
	self.navBar = self:GetParent().navBar
	self.child = self.ScrollContainer.Child
	self.highlight = self.child.HighlightTexture
	self.detailLayerPool = CreateFramePool("FRAME", self.child, "MapCanvasDetailLayerTemplate")
	self.explorationLayerPool = CreateTexturePool(self.child.Exploration, "ARTWORK", 0)
	self.navBar:on("MAP_CHANGE", function() self:refresh() end)
end


function MJMapCanvasMixin:onUpdate()
	-- MAP HIGHLIGHT
	local fileDataID, atlasID, texPercentageX, texPercentageY, textureX, textureY, scrollChildX, scrollChildY = C_Map.GetMapHighlightInfoAtPosition(self.mapID, self:getCursorPosition())

	if fileDataID and fileDataID > 0 or atlasID then
		self.highlight:SetTexCoord(0, texPercentageX, 0, texPercentageY)
		local width = self.child:GetWidth()
		local height = self.child:GetHeight()
		self.highlight:ClearAllPoints()
		if atlasID then
			self.highlight:SetAtlas(atlasID, true, "TRILINEAR")
			scrollChildX = (scrollChildX + 0.5 * textureX - 0.5) * width
			scrollChildY = -(scrollChildY + 0.5 * textureY - 0.5) * height
			self.highlight:SetPoint("CENTER", scrollChildX, scrollChildY)
		else
			self.highlight:SetTexture(fileDataID, nil, nil, "TRILINEAR")
			textureX = textureX * width
			textureY = textureY * height
			scrollChildX = scrollChildX * width
			scrollChildY = -scrollChildY * height
			if textureX > 0 and textureY > 0 then
				self.highlight:SetWidth(textureX)
				self.highlight:SetHeight(textureY)
				self.highlight:SetPoint("TOPLEFT", scrollChildX, scrollChildY)
			end
		end
		self.highlight:Show()
	else
		self.highlight:Hide()
	end
end


function MJMapCanvasMixin:GetMapID()
	return self.mapID
end


function MJMapCanvasMixin:SetMapID(mapID)
	self.navBar:setMapID(mapID)
end


function MJMapCanvasMixin:onClick(btn)
	if btn == "LeftButton" then
		local mapInfo = C_Map.GetMapInfoAtPosition(self.mapID, self:getCursorPosition())
		if mapInfo and mapInfo.mapID ~= self.mapID then
			self:SetMapID(mapInfo.mapID)
		end
	else
		local mapInfo = C_Map.GetMapInfo(self.mapID)
		if mapInfo.parentMapID > 0 then
			self:SetMapID(mapInfo.parentMapID)
		elseif mapInfo.mapID ~= self.navBar.defMapID then
			self.navBar:setDefMap()
		end
	end
end


function MJMapCanvasMixin:refresh()
	if self:IsShown() then
		self:refreshLayers()
		self.navigation:Refresh()
	end
end


function MJMapCanvasMixin:onShow()
	self:refresh()
end


function MJMapCanvasMixin:refreshLayers()
	if self.mapID == self.navBar.mapID then return end
	self.mapID = self.navBar.mapID
	self.detailLayerPool:ReleaseAll()

	local layers = C_Map.GetMapArtLayers(self.mapID)
	self:setCanvasSize(layers[1].layerWidth, layers[1].layerHeight)
	for index, layerInfo in ipairs(layers) do
		local detailLayer = self.detailLayerPool:Acquire()
		detailLayer:SetAllPoints(self.child)
		detailLayer:SetMapAndLayer(self.mapID, index)
		detailLayer:SetGlobalAlpha(1)
		detailLayer:Show()
	end

	self.explorationLayerPool:ReleaseAll()
	local exploredMapTextures = C_MapExplorationInfo.GetExploredMapTextures(self.mapID)
	if exploredMapTextures then
		local tileWidth = layers[1].tileWidth
		local tileHeight = layers[1].tileHeight

		for i, exploredTextureInfo in ipairs(exploredMapTextures) do
			local numTexturesWide = ceil(exploredTextureInfo.textureWidth/tileWidth)
			local numTexturesTall = ceil(exploredTextureInfo.textureHeight/tileHeight)
			local texturePixelWidth, textureFileWidth, texturePixelHeight, textureFileHeight
			for j = 1, numTexturesTall do
				if j < numTexturesTall then
					texturePixelHeight = tileHeight
					textureFileHeight = tileHeight
				else
					texturePixelHeight = mod(exploredTextureInfo.textureHeight, tileHeight)
					if texturePixelHeight == 0 then
						texturePixelHeight = tileHeight
					end
					textureFileHeight = 16
					while(textureFileHeight < texturePixelHeight) do
						textureFileHeight = textureFileHeight * 2
					end
				end
				for k = 1, numTexturesWide do
					local texture = self.explorationLayerPool:Acquire()
					if k < numTexturesWide then
						texturePixelWidth = tileWidth
						textureFileWidth = tileWidth
					else
						texturePixelWidth = mod(exploredTextureInfo.textureWidth, tileWidth)
						if texturePixelWidth == 0 then
							texturePixelWidth = tileWidth
						end
						textureFileWidth = 16
						while(textureFileWidth < texturePixelWidth) do
							textureFileWidth = textureFileWidth * 2
						end
					end
					texture:SetWidth(texturePixelWidth)
					texture:SetHeight(texturePixelHeight)
					texture:SetTexCoord(0, texturePixelWidth/textureFileWidth, 0, texturePixelHeight/textureFileHeight)
					texture:SetPoint("TOPLEFT", exploredTextureInfo.offsetX + (tileWidth * (k-1)), -(exploredTextureInfo.offsetY + (tileHeight * (j - 1))))
					texture:SetTexture(exploredTextureInfo.fileDataIDs[((j - 1) * numTexturesWide) + k], nil, nil, "TRILINEAR")

					if not exploredTextureInfo.isShownByMouseOver then
						texture:SetDrawLayer("ARTWORK", 0)
						texture:Show()
					end
				end
			end
		end
	end
end


function MJMapCanvasMixin:setCanvasSize(width, height)
	local child = self.child
	local scroll = self.ScrollContainer
	child:SetSize(width, height)
	
	self.currentScale = min(scroll:GetWidth() / child:GetWidth(), scroll:GetHeight() / child:GetHeight())
	child:SetScale(self.currentScale)
end


function MJMapCanvasMixin:normalizeHorizontalSize(size)
	return size / self.child:GetWidth()
end


function MJMapCanvasMixin:normalizeVerticalSize(size)
	return size / self.child:GetHeight()
end


function MJMapCanvasMixin:getCursorPosition()
	local x, y = GetCursorPosition()
	local effectiveScale = UIParent:GetEffectiveScale()
	x, y = x / effectiveScale, y / effectiveScale
	return Saturate(self:normalizeHorizontalSize(x / self.currentScale - self.child:GetLeft())), Saturate(self:normalizeVerticalSize(self.child:GetTop() - y / self.currentScale))
end


-- =======================================================================
-- DUNGEON AND RAID MIXIN
MJDungeonRaidMixin = {}


function MJDungeonRaidMixin:onLoad()
	self.list = {
		{
			name = DUNGEONS,
			list = {},
		},
		{
			name = RAIDS,
			list = {},
		}
	}

	local currentTier = EJ_GetCurrentTier()
	local mapExclude = {
		[379] = true, -- Вершина Кун-Лай
		[543] = true, -- Горгронд
		[929] = true, -- Точка массированного вторжения: госпожа Фолнуна
	}
	for i = 1, EJ_GetNumTiers() do
		EJ_SelectTier(i)
		for _,v in ipairs(self.list) do
			v.list[i] = {
				name = _G["EXPANSION_NAME"..(i - 1)],
				list = {},
			}
			local showRaid = v.name == RAIDS
			local index = 1
			local instanceID, instanceName = EJ_GetInstanceByIndex(index, showRaid)
			while instanceID do
				EJ_SelectInstance(instanceID)
				local _,_,_,_,_,_,mapID = EJ_GetInstanceInfo()
				if mapID and mapID > 0 and not mapExclude[mapID] then
					tinsert(v.list[i].list, {name = instanceName, mapID = mapID})
				end
				index = index + 1
				instanceID, instanceName = EJ_GetInstanceByIndex(index, showRaid)
			end
		end
	end
	EJ_SelectTier(currentTier)

	UIDropDownMenu_Initialize(self.optionsMenu, self.menuInit, "MENU")
end


function MJDungeonRaidMixin:menuInit(level)
	local btn = self:GetParent()
	local info = UIDropDownMenu_CreateInfo()
	local list = UIDROPDOWNMENU_MENU_VALUE or btn.list
	info.isNotRadio = true
	info.notCheckable = true

	for _,v in ipairs(list) do
		info.text = v.name
		if v.list then
			info.keepShownOnClick = true
			info.hasArrow = true
			info.value = v.list
		else
			info.func = function()
				btn.click(v.mapID)
				UIDropDownMenu_OnHide(self)
			end
		end
		UIDropDownMenu_AddButton(info, level)
	end
end


function MJDungeonRaidMixin:onClick()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	ToggleDropDownMenu(1, nil, self.optionsMenu, self, 111, 15)
end