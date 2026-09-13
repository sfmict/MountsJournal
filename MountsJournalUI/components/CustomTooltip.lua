local addon, ns = ...
local timer = .5
local margin = 10
local hSpacing, vSpacing = 40, 2
local minWidth, maxWidth = 250, 300
local ct, strPool = CreateFrame("FRAME", nil, UIParent, "SharedTooltipArtTemplate")
ns.journal.customTooltip = ct
ct:Hide()
ct:SetFrameStrata("TOOLTIP")
ct:EnableMouse(true)
ct.lines = {}
SharedTooltip_OnLoad(ct)
local underline = ct:CreateTexture(nil, "BACKGROUND")
underline:SetSize(1, 1)
GameTooltip:HookScript("OnShow", function() ct:Hide() end)


local function onHide(self)
	strPool:Release(self)
end
local function onEnter(self)
	if not self.func then return end
	underline:SetColorTexture(self:GetTextColor())
	underline:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
	underline:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT")
	underline:Show()
end
local function onLeave(self)
	underline:Hide()
end
local function onMouseUp(self, upInside)
	if upInside and self.func then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self.func(self.value)
	end
end
local function poolReset(pool, region, new)
	region:Hide()
	region:ClearAllPoints()
	if new then
		region:SetScript("OnHide", onHide)
		region:SetScript("OnEnter", onEnter)
		region:SetScript("OnLeave", onLeave)
		region:SetScript("OnMouseUp", onMouseUp)
	end
end
strPool = CreateFontStringPool(ct, "ARTWORK", 1, "GameTooltipText", poolReset)


local function onUpdate(self, elapsed)
	self:updateHeight()

	if self:IsMouseOver() or self.anchorFrame:IsMouseOver() then
		self.timer = timer
		return
	end

	self.timer = self.timer - elapsed
	if self.timer < 0 then
		self:Hide()
	end
end


ct:SetScript("OnShow", function(self)
	self:SetWidth(self.width + margin * 2)
	self:updateHeight()
	self:RegisterEvent("GLOBAL_MOUSE_DOWN")
	self.timer = timer
	self:SetScript("OnUpdate", onUpdate)
end)


ct:SetScript("OnHide", function(self)
	wipe(self.lines)
	self:SetScript("OnUpdate", nil)
	self:UnregisterEvent("GLOBAL_MOUSE_DOWN")
end)


ct:SetScript("OnEvent", function(self)
	if self:IsMouseOver() or self.anchorFrame:IsMouseOver() then return end
	self:Hide()
end)


function ct:updateHeight()
	local height = margin * 2 + (#self.lines - 1) * vSpacing
	for i = 1, #self.lines do
		height = height + self.lines[i]:GetHeight()
	end
	self:SetHeight(height)
end


function ct:point(point, anchorFrame, relativePoint, x, y)
	self.anchorFrame = anchorFrame
	self.width = 0
	self:Hide()
	self:ClearAllPoints()
	self:SetPoint(point, anchorFrame, relativePoint, x, y)
end


function ct:setTitle(text, wrap)
	local str = self.TextLeft1
	str:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
	str:SetText(text)
	str:SetWordWrap(wrap or false)
	str:SetPoint("TOPLEFT", margin, -margin)
	str:Show()
	if wrap then
		self.width = math.max(self.width, math.min(minWidth, str:GetUnboundedStringWidth()))
		str:SetPoint("RIGHT", -margin, 0)
	else
		self.width = math.max(self.width, str:GetStringWidth())
	end
	self.height = str:GetHeight()
	self.lines[1] = str
end


function ct:addString(prevString, text, func, value)
	local str = strPool:Acquire()
	str:SetTextColor(NIGHT_FAE_BLUE_COLOR:GetRGB())
	str:SetText(text)
	str:SetWordWrap(false)
	str:SetJustifyH("RIGHT")
	str:Show()
	if prevString then
		str:SetPoint("RIGHT", prevString, "LEFT")
	else
		str:SetPoint("RIGHT", -margin, 0)
	end
	str.func = func or nil
	str.value = value
	return str:GetStringWidth(), str
end


function ct:addLine(textLeft, info, func, value)
	local strLeft = strPool:Acquire()
	local infoType = type(info)
	local wrap = infoType == "boolean" and info or false
	strLeft:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
	strLeft:SetText(textLeft)
	strLeft:SetWordWrap(wrap)
	strLeft:SetJustifyH("LEFT")
	strLeft:Show()
	strLeft:SetPoint("TOPLEFT", self.lines[#self.lines], "BOTTOMLEFT", 0, -vSpacing)
	local width
	if wrap then
		width = math.min(minWidth, strLeft:GetUnboundedStringWidth())
		strLeft:SetPoint("RIGHT", -margin, 0)
	else
		width = strLeft:GetStringWidth()
	end
	strLeft.func = nil

	local rWidth, str
	if infoType == "string" or infoType == "number" then
		rWidth, str = self:addString(nil, info, func, value)
		width = width + hSpacing + rWidth
		str:SetPoint("TOP", strLeft)
	elseif infoType == "table" then
		local len, sepWidth, sepStr, curStr = #info
		width = width + hSpacing
		rWidth, str = self:addString(nil, info[1].text, func, info[1].value)
		str:SetPoint("TOP", strLeft)
		for i = 2, len do
			sepWidth, sepStr = self:addString(str, ", ")
			rWidth, curStr = self:addString(sepStr, info[i].text, func, info[i].value)
			width = width + sepWidth + rWidth
			if width > maxWidth then
				width = width - sepWidth
				sepStr:Hide()
				curStr:Hide()
				self:addLine(" ", {unpack(info, i)}, func)
				break
			end
			str = curStr
		end
	end

	self.width = math.max(self.width, width)
	self.lines[#self.lines+1] = strLeft
end
