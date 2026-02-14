local addon, ns = ...
local L = ns.L


local onColorSelect = function(colorPicker, r,g,b)
	colorPicker.wheelThumb:Show()
	colorPicker.valueThumb:Show()
	local parent = colorPicker:GetParent()
	parent.curColor:SetColorTexture(r,g,b)
	parent.hexBox:SetText(CreateColor(r,g,b):GenerateHexColorNoAlpha())
	local color = ns.mounts.filters.color
	color.r = r
	color.g = g
	color.b = b
	ns.mounts.filters.color = color
	ns.journal:updateMountsList()
end


MJMountColorMixin = {}


function MJMountColorMixin:onLoad()
	-- HEX
	self.hexBox:SetTextInsets(16, 0, 0, 0)
	self.hexBox:SetScript("OnTextChanged", function(hexBox)
		hexBox:SetText(hexBox:GetText():gsub("[^A-Fa-f0-9]", ""))
	end)
	self.hexBox:SetScript("OnEnterPressed", function(hexBox)
		local text = hexBox:GetText()
		local length = #text
		if length == 0 then
			hexBox:SetText("ffffff")
		elseif length < 6 then
			local startingText = text;
			while length < 6 do
				for i = 1, #startingText do
					local char = startingText:sub(i,i)
					text = text..char

					length = length + 1
					if length == 6 then
						break
					end
				end
		  end
		  hexBox:SetText(text)
		end

		local color = CreateColorFromRGBAHexString(hexBox:GetText().."ff")
		hexBox:GetParent().colorPicker:SetColorRGB(color:GetRGB())
	end)

	-- THRESHOLD
	self.threshold:setText(L["Threshold"])
	self.threshold:setMinMax(0, 100)
	self.threshold:setOnChanged(function(threshold, value)
		local color = ns.mounts.filters.color
		if color.threshold == value then return end
		color.threshold = value
		if color.r then ns.journal:updateMountsList() end
	end)

	-- RESET
	self.reset:SetWidth(self.reset:GetFontString():GetStringWidth() + 20)
	self.reset:SetScript("OnClick", function(reset)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)

		local color = ns.mounts.filters.color
		color.r = nil
		color.g = nil
		color.b = nil
		color.threshold = ns.mounts.defFilters.color.threshold

		local parent = reset:GetParent()
		parent:GetScript("OnHide")(parent)
		parent:GetScript("OnShow")(parent)

		ns.journal:updateMountsList()
	end)
end


function MJMountColorMixin:onShow()
	local color = ns.mounts.filters.color
	if color.r then
		local r,g,b = color.r, color.g, color.b
		self.curColor:SetColorTexture(r,g,b)
		self.hexBox:SetText(CreateColor(r,g,b):GenerateHexColorNoAlpha())
		self.colorPicker:SetColorRGB(r,g,b)
		self.colorPicker.wheelThumb:Show()
		self.colorPicker.valueThumb:Show()
	else
		self.curColor:SetColorTexture(1,1,1)
		self.colorPicker:SetColorRGB(1,1,1)
		self.hexBox:SetText("")
		self.colorPicker.wheelThumb:Hide()
		self.colorPicker.valueThumb:Hide()
	end
	self.colorPicker:SetScript("OnColorSelect", onColorSelect)
	self.threshold:setValue(color.threshold)
end


function MJMountColorMixin:onHide()
	self.colorPicker:SetScript("OnColorSelect", nil)
end
