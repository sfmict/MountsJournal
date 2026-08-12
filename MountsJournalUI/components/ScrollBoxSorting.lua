local addon, ns = ...
local util = ns.util

local cover = CreateFrame("FRAME")
cover:Hide()
cover.bg = cover:CreateTexture(nil, "BACKGROUND")
cover.bg:SetAllPoints()
cover.bg:SetColorTexture(.2, .2, .2, .6)
cover:SetScript("OnHide", function(self)
	self:SetParent()
	self:ClearAllPoints()
	self:Hide()
end)
function cover:setCover(frame)
	self:SetParent(frame)
	self:SetAllPoints(frame)
	self:SetFrameStrata("DIALOG")
	self:Show()
end

local cursorCover = CreateFrame("FRAME")
cursorCover:Hide()
cursorCover:EnableMouse(true)
cursorCover:SetFrameStrata("TOOLTIP")


local getCursorFrame do
	local list = {}
	function getCursorFrame(delegate, sourceFrame)
		local view, elementData = delegate.view, delegate.sourceElementData
		local template, initializer = view:GetFactoryDataFromElementData(elementData)
		local frame, new = list[template], false

		if not frame then
			local templateInfo = C_XMLUtil.GetTemplateInfo(template)
			frame = CreateFrame(templateInfo.type, nil, UIParent, template)
			list[template] = frame
			new = true
		end

		frame:SetSize(sourceFrame:GetSize())
		view:TriggerEvent(view.Event.OnAcquiredFrame, frame, elementData, new)
		if initializer then initializer(frame, elementData) end
		frame:SetAlpha(.5)

		cursorCover:SetAllPoints(frame)
		cursorCover:Show()

		frame:SetFrameStrata("DIALOG")
		frame:Show()
		return frame
	end
end


local function getPanFactor(elapsed, delta)
	local v = delta / (UIParent:GetHeight() * .046)
	return elapsed * math.max(.1, v*v)
end


local function tryVerticalEdgeScroll(scrollBox, elapsed, cy)
	local topDelta = cy - scrollBox:GetTop()
	if topDelta > 0 then
		scrollBox:ScrollDecrease(getPanFactor(elapsed, topDelta))
	else
		local bottomDelta = cy - scrollBox:GetBottom()
		if bottomDelta < 0 then
			scrollBox:ScrollIncrease(getPanFactor(elapsed, bottomDelta))
		end
	end
end


local function onUpdate(delegate, elapsed)
	local scrollBox = delegate:GetParent()
	local cx, cy = InputUtil.GetCursorPosition(scrollBox)
	delegate.cursorFrame:SetPoint("BOTTOMLEFT", cx - delegate.dx, cy - delegate.dy)
	delegate.dropElementData = nil

	if scrollBox:IsMouseOver() then
		for i, frame in ipairs(delegate.view:GetFrames()) do
			local data = frame:GetElementData()
			if delegate.sourceElementData ~= data and frame:IsMouseOver() then
				delegate.dropElementData = data
				local x = (cx - frame:GetLeft()) / frame:GetWidth()
				local y = (cy - frame:GetBottom()) / frame:GetHeight()
				delegate.onDropEnter(true, frame, delegate.sourceElementData, x, y)
				return
			end
		end
	else
		tryVerticalEdgeScroll(scrollBox, elapsed, cy)
	end

	delegate.onDropEnter(false)
end


local function onMouseDown(self)
	local delegate = self.__delegate
	delegate.canDrag = not delegate.isCanDrag or delegate.isCanDrag()
	if delegate.canDrag then
		local cx, cy = InputUtil.GetCursorPosition(delegate:GetParent())
		delegate.dx = cx - self:GetLeft()
		delegate.dy = cy - self:GetBottom()
	end
end


local function onDragStart(self, ...)
	local delegate = self.__delegate
	if not delegate.canDrag then
		if self.__onDragStart then self:__onDragStart(...) end
		return
	end

	if not self:InterceptStartDrag(delegate) then return end

	cover:setCover(self)
	delegate.sourceElementData = self:GetElementData()
	delegate.cursorFrame = getCursorFrame(delegate, self)
	delegate:Show()
end


local function onDragStop(delegate)
	if not delegate:IsShown() then return end

	if delegate.dropElementData and not IsMouseButtonDown("LeftButton") then
		xpcall(delegate.onSetPosition, CallErrorHandler, delegate.sourceElementData, delegate.dropElementData)
	end

	cover:Hide()
	cursorCover:Hide()
	delegate:Hide()
	delegate.cursorFrame:Hide()
	delegate.cursorFrame = nil
	delegate.sourceElementData = nil
	delegate.dropElementData = nil
	delegate.onDropEnter(false)
end


local function onAcquiredFrame(delegate, frame, data, new)
	if new then
		frame.__delegate = delegate
		frame.__onDragStart = frame:GetScript("OnDragStart")
		frame:RegisterForDrag("LeftButton")
		frame:HookScript("OnMouseDown", onMouseDown)
		frame:SetScript("OnDragStart", onDragStart)
	end
end


local function onInitializedFrame(delegate, frame)
	if delegate.sourceElementData == frame:GetElementData() then
		cover:setCover(frame)
	end
end


function util.setupDragSorting(scrollBox, onDropEnter, onSetPosition, isCanDrag)
	local delegate = scrollBox.DragDelegate
	delegate:Hide()
	delegate:SetScript("OnUpdate", onUpdate)
	delegate:SetScript("OnDragStop", onDragStop)
	delegate.onDropEnter = onDropEnter
	delegate.onSetPosition = onSetPosition
	delegate.isCanDrag = isCanDrag
	delegate.view = scrollBox:GetView()
	scrollBox:RegisterCallback(scrollBox.Event.OnAcquiredFrame, onAcquiredFrame, delegate)
	scrollBox:RegisterCallback(scrollBox.Event.OnInitializedFrame, onInitializedFrame, delegate)
end
