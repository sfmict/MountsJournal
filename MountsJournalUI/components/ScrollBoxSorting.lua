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
		local elementData = delegate.sourceElementData
		local template, initializer = delegate.cursorFactory(elementData)
		local frame, new = list[template], false

		if not frame then
			local templateInfo = C_XMLUtil.GetTemplateInfo(template)
			frame = CreateFrame(templateInfo.type, nil, UIParent, template)
			frame:SetAlpha(.5)
			list[template] = frame
			new = true
		end

		delegate:GetParent():OnViewAcquiredFrame(frame, elementData, new)
		if initializer then initializer(frame, sourceFrame, elementData) end

		cursorCover:SetAllPoints(frame)
		cursorCover:Show()

		frame:SetFrameStrata("DIALOG")
		frame:Show()
		return frame
	end
end


local function onUpdate(delegate)
	local cursorFrame = delegate.cursorFrame
	local cx, cy = InputUtil.GetCursorPosition(delegate:GetParent())
	cursorFrame:SetPoint("BOTTOMLEFT", cx - delegate.dx, cy - delegate.dy)

	delegate.dropElementData = nil
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
	delegate.onDropEnter(false)
end


local function onMouseDown(self)
	local delegate = self.__delegate
	delegate.canDrag = not delegate.isCanDrag or delegate.isCanDrag()
	if delegate.canDrag then
		delegate.dx, delegate.dy = InputUtil.GetCursorPosition(delegate:GetParent())
	end
end


local function onDragStart(self, ...)
	local delegate = self.__delegate
	if not delegate.canDrag then
		if self.__onDragStart then self:__onDragStart(...) end
		return
	end

	if not self:InterceptStartDrag(delegate) then return end

	delegate.sourceElementData = self:GetElementData()
	delegate.cursorFrame = getCursorFrame(delegate, self)
	delegate.dx = delegate.dx - self:GetLeft()
	delegate.dy = delegate.dy - self:GetBottom()

	cover:setCover(self)
	delegate:Show()
end


local function onDragStop(delegate)
	if not delegate:IsShown() then return end

	if delegate.dropElementData then
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
	delegate.cursorFactory = ScrollUtil.GenerateCursorFactory(scrollBox)
	delegate.view = scrollBox:GetView()
	scrollBox:RegisterCallback(scrollBox.Event.OnAcquiredFrame, onAcquiredFrame, delegate)
	scrollBox:RegisterCallback(scrollBox.Event.OnInitializedFrame, onInitializedFrame, delegate)
end
