local addon, ns = ...
local util = ns.util


local MJMapCanvasMixin = util.createFromEventsMixin()
ns.MJMapCanvasMixin = MJMapCanvasMixin


function MJMapCanvasMixin:onLoad()
	self.navBar = self:GetParent().navBar
	self.child = self.ScrollContainer.Child
	self.highlight = self.child.HighlightTexture
	self.name = self.ScrollContainer.label.name
	self.name:SetFontHeight(22)
	self.description = self.ScrollContainer.label.description
	self.description:SetFontHeight(16)
	self.detailLayerPool = CreateFramePool("FRAME", self.child, "MapCanvasDetailLayerTemplate")
	self.explorationLayerPool = CreateTexturePool(self.child, "ARTWORK", 1)
	self.highlightRectPool = CreateTexturePool(self.child, "ARTWORK", 1)
	self.pinPools = {}
	self.navigation = LibStub("LibSFDropDown-1.5"):CreateModernButtonOriginal(self)
	self.navigation:SetFrameLevel(self:GetFrameLevel() + 10)
	self.navigation:SetPoint("TOPLEFT", 4, -4)
	self.navigation:ddSetDisplayMode(addon)
	self.navigation:ddSetInitFunc(function(...) self:dropDownInit(...) end)
end


function MJMapCanvasMixin:setLabel(name, description, dirty)
	if self.isLabelDirty then return end
	self.name:SetText(name)
	self.description:SetText(description)
	self.isLabelDirty = dirty
end


function MJMapCanvasMixin:clearLabel(force)
	if force then self.isLabelDirty = nil end
	self:setLabel()
end


function MJMapCanvasMixin:setAcceleration(deltaX, deltaY, elapsed)
	local initialAcceleration = .5
	self.accX = deltaX / elapsed * initialAcceleration
	self.accY = deltaY / elapsed * initialAcceleration
end


local function getDeltaAcceleration(curAcc, elapsed)
	local kAcc = -5
	local decay = math.exp(kAcc * elapsed)
	local delta = curAcc * (decay - 1) / kAcc
	local newAcc = curAcc * decay

	if newAcc < 5 and newAcc > -5 then return end
	return delta, newAcc
end


function MJMapCanvasMixin:updateAcceleration(elapsed)
	if self.accX then
		local deltaX, accX = getDeltaAcceleration(self.accX, elapsed)
		self.accX = accX
		if deltaX then self:setPanX(deltaX) end
	end

	if self.accY then
		local deltaY, accY = getDeltaAcceleration(self.accY, elapsed)
		self.accY = accY
		if deltaY then self:setPanY(deltaY) end
	end
end


function MJMapCanvasMixin:onUpdate(elapsed)
	-- MAP HIGHLIGHT
	local cursorX, cursorY = self:getCursorPosition()
	local fileDataID, atlasID, texPercentageX, texPercentageY, textureX, textureY, scrollChildX, scrollChildY = C_Map.GetMapHighlightInfoAtPosition(self.mapID, cursorX, cursorY)

	if fileDataID and fileDataID > 0 or atlasID then
		self.highlight:SetTexCoord(0, texPercentageX, 0, texPercentageY)
		local width = self.child:GetWidth()
		local height = self.child:GetHeight()
		self.highlight:ClearAllPoints()
		if atlasID then
			self.highlight:SetAtlas(atlasID, true, "TRILINEAR")
			scrollChildX = (scrollChildX + .5 * textureX - .5) * width
			scrollChildY = -(scrollChildY + .5 * textureY - .5) * height
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

	-- HIGHTLIGHT RECT
	local highlightIndex
	-- first find if any have the mouse over
	for highlightRect in self.highlightRectPool:EnumerateActive() do
		if highlightRect:IsMouseOver() then
			highlightIndex = highlightRect.index
			break
		end
	end
	-- now show all who match the same index
	for highlightRect in self.highlightRectPool:EnumerateActive() do
		highlightRect.texture:SetShown(highlightRect.index == highlightIndex)
	end

	-- LABEL
	self:clearLabel()
	local positionMapInfo = C_Map.GetMapInfoAtPosition(self.mapID, cursorX, cursorY)
	if positionMapInfo and positionMapInfo.mapID ~= self.mapID then
		self:setLabel(positionMapInfo.name)
	end

	-- ACCSELERATION
	if self:canPan() then
		local x, y = GetCursorDelta()
		local scale = self.child:GetEffectiveScale()
		x, y = x / scale, y / scale
		self:setPanX(-x)
		self:setPanY(y)
		self:setAcceleration(-x, y, elapsed)
	elseif self.accX or self.accY then
		self:updateAcceleration(elapsed)
	end

	-- DRAGGED
	if self.isPanning and not self.isDragged then
		local curX, curY = GetCursorPosition()
		local deltaX = curX - self.curX
		local deltaY = curY - self.curY
		if deltaX * deltaX + deltaY * deltaY > 3 then
			self.isDragged = true
		end
	end
end


function MJMapCanvasMixin:dropDownInit(dd, level)
	local mapGroupID = C_Map.GetMapGroupID(self.mapID)
	if not mapGroupID then return end

	local mapGroupMembersInfo = C_Map.GetMapGroupMembersInfo(mapGroupID)
	if not mapGroupMembersInfo then return end

	local info = {}
	info.func = function(btn)
		self.navBar:setMapID(btn.value)
	end

	for _, mapInfo in ipairs(mapGroupMembersInfo) do
		info.text = mapInfo.name
		info.value = mapInfo.mapID
		info.checked = self.mapID == mapInfo.mapID
		dd:ddAddButton(info, level)
	end
end


function MJMapCanvasMixin:refresh()
	self:refreshLayers()

	local mapGroupID = C_Map.GetMapGroupID(self.mapID)
	if mapGroupID then
		local mapGroupInfo = C_Map.GetMapGroupMembersInfo(mapGroupID)
		if mapGroupInfo then
			for _, mapInfo in ipairs(mapGroupInfo) do
				if mapInfo.mapID == self.mapID then
					self.navigation:ddSetSelectedText(mapInfo.name)
					self.navigation:Show()
					return
				end
			end
		end
	end
	self.navigation:Hide()
end


function MJMapCanvasMixin:onShow()
	self:refresh()
	self:on("MAP_CHANGE", self.refresh)
	self:on("JOURNAL_RESIZED", self.refresh)
end


function MJMapCanvasMixin:onHide()
	self:off("MAP_CHANGE", self.refresh)
	self:off("JOURNAL_RESIZED", self.refresh)
end


-- Needs for MapCanvasDetailLayerTemplate (MapCanvasDetailLayerMixin)
MJMapCanvasMixin.AddMaskableTexture = nop


function MJMapCanvasMixin:refreshLayers()
	self.mapID = self.navBar.mapID
	self.detailLayerPool:ReleaseAll()

	local layers = C_Map.GetMapArtLayers(self.mapID)
	if not layers then
		self:setCanvasSize(1, 1)
		return
	end
	self:setCanvasSize(layers[1].layerWidth, layers[1].layerHeight)

	for index, layerInfo in ipairs(layers) do
		local detailLayer = self.detailLayerPool:Acquire()
		detailLayer:SetAllPoints()
		detailLayer:SetMapAndLayer(self.mapID, index, self)
		detailLayer:SetGlobalAlpha(1)
		detailLayer:Show()
	end

	self.explorationLayerPool:ReleaseAll()
	self.highlightRectPool:ReleaseAll()
	local exploredMapTextures = C_MapExplorationInfo.GetExploredMapTextures(self.mapID)
	if exploredMapTextures then
		local tileWidth = layers[1].tileWidth
		local tileHeight = layers[1].tileHeight

		for i, exploredTextureInfo in ipairs(exploredMapTextures) do
			local numTexturesWide = ceil(exploredTextureInfo.textureWidth/tileWidth)
			local numTexturesTall = ceil(exploredTextureInfo.textureHeight/tileHeight)
			local texturePixelWidth, textureFileWidth, texturePixelHeight, textureFileHeight
			local textureSubLevel = exploredTextureInfo.isDrawOnTopLayer and 2 or 1
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

					if exploredTextureInfo.isShownByMouseOver then
						texture:SetDrawLayer("ARTWORK", textureSubLevel + 1)
						texture:Hide()
						local highlightRect = self.highlightRectPool:Acquire()
						highlightRect:SetSize(exploredTextureInfo.hitRect.right - exploredTextureInfo.hitRect.left, exploredTextureInfo.hitRect.bottom - exploredTextureInfo.hitRect.top)
						highlightRect:SetPoint("TOPLEFT", exploredTextureInfo.hitRect.left, -exploredTextureInfo.hitRect.top)
						highlightRect.index = i
						highlightRect.texture = texture
					else
						texture:SetDrawLayer("ARTWORK", textureSubLevel)
						texture:Show()
					end
				end
			end
		end
	end
end


-- Needs for DelveEntrancePinTemplate (AreaPOIPinMixin)
MJMapCanvasMixin.GetBountyInfo = nop


-- Needs for pins (MapCanvasPinMixin)
function MJMapCanvasMixin:GetMapID()
	return self.mapID
end


function MJMapCanvasMixin:SetPinPosition(pin, x, y)
	pin:ClearAllPoints()
	if x and y then
		local scale = .8 / self.curScale
		local canvas = pin:GetParent()
		x = canvas:GetWidth() * x / scale
		y = canvas:GetHeight() * y / scale
		pin:SetScale(scale)
		pin:SetPoint("CENTER", canvas, "TOPLEFT", x, -y)
	end
end


do
	local function onPinMouseDown(pin)
		pin:AdjustPointsOffset(1, -1)
	end

	local function onPinMouseUp(pin, button, upInside)
		pin:AdjustPointsOffset(-1, 1)
		local owner = pin:GetOwningMap()
		if button ~= "LeftButton" then
			owner:onMouseUp(button)
		elseif upInside then
			owner.navBar:setMapID(pin:GetPoiInfo().linkedUiMapID)
		end
	end

	local function onPinMouseEnter(pin)
		local info = pin:GetPoiInfo()
		pin:GetOwningMap():setLabel(info.name, info.description, true)
	end

	local function onPinMouseLeave(pin)
		pin:GetOwningMap():clearLabel(true)
	end

	function MJMapCanvasMixin:acquirePin(pinTemplate, info)
		if not self.pinPools[pinTemplate] then
			self.pinPools[pinTemplate] = CreateFramePool("FRAME", self.child, pinTemplate)
		end
		local pin, newPin = self.pinPools[pinTemplate]:Acquire()

		if newPin then
			pin:SetOwningMap(self)
			pin:OnLoad()
			pin:SetScript("OnMouseDown", onPinMouseDown)
			pin:SetScript("OnMouseUp", onPinMouseUp)
			pin:SetScript("OnEnter", onPinMouseEnter)
			pin:SetScript("OnLeave", onPinMouseLeave)
		end

		pin:Show()
		pin:OnAcquired(info)
	end
end


function MJMapCanvasMixin:refreshPins()
	for _, pool in next, self.pinPools do
		pool:ReleaseAll()
	end

	local dungeonEntrances = C_EncounterJournal.GetDungeonEntrancesForMap(self.mapID)
	for i, dungeonEntranceInfo in ipairs(dungeonEntrances) do
		dungeonEntranceInfo.linkedUiMapID = ns.mapIDByJInstanceID[dungeonEntranceInfo.journalInstanceID]
		if dungeonEntranceInfo.linkedUiMapID then
			self:acquirePin("DungeonEntrancePinTemplate", dungeonEntranceInfo)
		end
	end

	local mapLinks = C_Map.GetMapLinksForMap(self.mapID)
	for i, mapLink in ipairs(mapLinks) do
		if mapLink.linkedUiMapID then
			self:acquirePin("MapLinkPinTemplate", mapLink)
		end
	end

	local areaPOIs = C_AreaPoiInfo.GetDelvesForMap(self.mapID)
	for i, arePoiID in ipairs(areaPOIs) do
		local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(self.mapID, arePoiID)
		if poiInfo and poiInfo.linkedUiMapID then
			poiInfo.dataProvider = self
			self:acquirePin("DelveEntrancePinTemplate", poiInfo)
		end
	end
end


function MJMapCanvasMixin:setCanvasScale(scale)
	local width, height = self.child:GetSize()
	local sWidth, sHeight = self.ScrollContainer:GetSize()
	self.curScale = scale
	self.offsetX = (width - sWidth / scale) * .5
	self.offsetY = (height - sHeight / scale) * .5
	self.ScrollContainer:SetHorizontalScroll(self.offsetX)
	self.ScrollContainer:SetVerticalScroll(self.offsetY)
	self.child:SetScale(scale)
	self.accX = nil
	self.accY = nil
	self:refreshPins()
end


function MJMapCanvasMixin:setCanvasSize(width, height)
	local sWidth, sHeight = self.ScrollContainer:GetSize()
	self.baseScale = min(sWidth / width, sHeight / height)
	self.zoom = 0
	self.child:SetSize(width, height)
	self:setCanvasScale(self.baseScale)
end


function MJMapCanvasMixin:getCursorPosition()
	local x, y = GetCursorPosition()
	local scale = self.child:GetEffectiveScale()
	local width, height = self.child:GetSize()
	return Saturate((x / scale - self.child:GetLeft()) / width),
	       Saturate((self.child:GetTop() - y / scale) / height)
end


function MJMapCanvasMixin:setPanX(deltaX)
	local sx = self.ScrollContainer:GetHorizontalScroll()
	self.ScrollContainer:SetHorizontalScroll(Clamp(sx + deltaX, self.minX, self.maxX))
end


function MJMapCanvasMixin:setPanY(deltaY)
	local sy = self.ScrollContainer:GetVerticalScroll()
	self.ScrollContainer:SetVerticalScroll(Clamp(sy + deltaY, self.minY, self.maxY))
end


function MJMapCanvasMixin:onMouseWheel(delta)
	local oldCurX, oldCurY = self:getCursorPosition()
	local width, height = self.child:GetSize()

	self.zoom = Clamp(self.zoom + delta, 0, 7)
	local zoomScale = self.baseScale * (1 + .3 * self.zoom)
	self:setCanvasScale(zoomScale)

	local deltaX = (width - width * self.baseScale / zoomScale) * .5
	local deltaY = (height - height * self.baseScale / zoomScale) * .5
	self.minX = self.offsetX - deltaX
	self.maxX = self.offsetX + deltaX
	self.minY = self.offsetY - deltaY
	self.maxY = self.offsetY + deltaY

	local curX, curY = self:getCursorPosition()
	self:setPanX((oldCurX - curX) * width)
	self:setPanY((oldCurY - curY) * height)
end


function MJMapCanvasMixin:canPan()
	return self.isPanning and self.curScale > self.baseScale
end


function MJMapCanvasMixin:onMouseDown(btn)
	if btn == "LeftButton" then
		self.isPanning = true
		self.isDragged = false
		self.curX, self.curY = GetCursorPosition()
	end
end


function MJMapCanvasMixin:onMouseUp(btn)
	if btn == "LeftButton" then
		self.isPanning = false
		if not self.isDragged then
			local mapInfo = C_Map.GetMapInfoAtPosition(self.mapID, self:getCursorPosition())
			if mapInfo and mapInfo.mapID ~= self.mapID then
				self.navBar:setMapID(mapInfo.mapID)
			end
		end
	else
		local mapInfo = C_Map.GetMapInfo(self.mapID)
		if mapInfo.parentMapID > 0 then
			self.navBar:setMapID(mapInfo.parentMapID)
		elseif mapInfo.mapID ~= self.navBar.defMapID then
			self.navBar:setDefMap()
		end
	end
end