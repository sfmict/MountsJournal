MJMapCanvasMixin = {}


function MJMapCanvasMixin:onLoad()
	self.navBar = self:GetParent().navBar
	self.highlight = self:getCanvas().HighlightTexture
	self.detailLayerPool = CreateFramePool("Frame", self:getCanvas(), "MapCanvasDetailLayerTemplate")
end


function MJMapCanvasMixin:onUpdate()
	-- MAP HIGHLIGHT
	local fileDataID, atlasID, texPercentageX, texPercentageY, textureX, textureY, scrollChildX, scrollChildY = C_Map.GetMapHighlightInfoAtPosition(self.mapID, self:getCursorPosition())

	if fileDataID and fileDataID > 0 or atlasID then
		self.highlight:SetTexCoord(0, texPercentageX, 0, texPercentageY)
		local width = self:getCanvas():GetWidth()
		local height = self:getCanvas():GetHeight()
		self.highlight:ClearAllPoints()
		if atlasID then
			self.highlight:SetAtlas(atlasID, true, "TRILINEAR")
			scrollChildX = (scrollChildX + 0.5 * textureX - 0.5) * width
			scrollChildY = -(scrollChildY + 0.5 * textureY - 0.5) * height
			self.highlight:SetPoint("CENTER", scrollChildX, scrollChildY)
			self.highlight:Show()
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
				self.highlight:Show()
			end
		end
	else
		self.highlight:Hide()
	end
end


function MJMapCanvasMixin:onClick(btn)
	if btn == "LeftButton" then
		local mapInfo = C_Map.GetMapInfoAtPosition(self.mapID, self:getCursorPosition())
		if mapInfo and mapInfo.mapID ~= self.mapID then
			self.navBar:setMapID(mapInfo.mapID)
		end
	else
		local mapInfo = C_Map.GetMapInfo(self.mapID)
		if mapInfo.parentMapID > 0 then
			self.navBar:setMapID(mapInfo.parentMapID)
		end
	end
end


function MJMapCanvasMixin:setMapID(mapID)
	self.mapID = mapID
	if self:IsShown() then
		self:refreshDetailLayers()
	end
end


function MJMapCanvasMixin:getCanvas()
	return self.ScrollContainer.Child
end


function MJMapCanvasMixin:onShow()
	self.mapID = self.navBar.mapID
	self:refreshDetailLayers()
end

function MJMapCanvasMixin:refreshDetailLayers()
	self.detailLayerPool:ReleaseAll()

	local layers = C_Map.GetMapArtLayers(self.mapID)
	self:setCanvasSize(layers[1].layerWidth, layers[1].layerHeight)
	for index, layerInfo in ipairs(layers) do
		local detailLayer = self.detailLayerPool:Acquire()
		detailLayer:SetAllPoints(self:getCanvas())
		detailLayer:SetMapAndLayer(self.mapID, index)
		detailLayer:SetGlobalAlpha(1)
		detailLayer:Show()
	end
end


function MJMapCanvasMixin:setCanvasSize(width, height)
	local canvas = self:getCanvas()
	local scroll = self.ScrollContainer
	canvas:SetSize(width, height)
	
	self.currentScale = math.min(scroll:GetWidth() / canvas:GetWidth(), scroll:GetHeight() / canvas:GetHeight())
	canvas:SetScale(self.currentScale)
end


function MJMapCanvasMixin:normalizeHorizontalSize(size)
	return size / self:getCanvas():GetWidth()
end


function MJMapCanvasMixin:normalizeVerticalSize(size)
	return size / self:getCanvas():GetHeight()
end


function MJMapCanvasMixin:getCursorPosition()
	local x, y = GetCursorPosition()
	local effectiveScale = UIParent:GetEffectiveScale()
	x, y = x / effectiveScale, y / effectiveScale
	return Saturate(self:normalizeHorizontalSize(x / self.currentScale - self:getCanvas():GetLeft())), Saturate(self:normalizeVerticalSize(self:getCanvas():GetTop() - y / self.currentScale))
end