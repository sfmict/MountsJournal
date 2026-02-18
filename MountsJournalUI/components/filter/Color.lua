local _, ns = ...
local L, journal = ns.L, ns.journal


function journal.filters.color(dd, level)
	local info = {}
	info.customFrame = journal.bgFrame.mountColor
	dd:ddAddButton(info, level)
end


journal:on("MODULES_INIT", function()
	local mountColor, floor = journal.bgFrame.mountColor, math.floor

	local function getHexColor(r,g,b)
		return ("%.2X%.2X%.2X"):format(floor(r*255+.5), floor(g*255+.5), floor(b*255+.5))
	end

	local onColorSelect = function(colorPicker, r,g,b)
		colorPicker.wheelThumb:Show()
		colorPicker.valueThumb:Show()
		local parent = colorPicker:GetParent()
		parent.curColor:SetColorTexture(r,g,b)
		parent.hexBox:SetText(getHexColor(r,g,b))
		local color = ns.mounts.filters.color
		color.r = r
		color.g = g
		color.b = b
		journal:updateMountsList()
	end

	mountColor:SetScript("OnShow", function(self)
		local color = ns.mounts.filters.color
		if color.r then
			local r,g,b = color.r, color.g, color.b
			self.curColor:SetColorTexture(r,g,b)
			self.hexBox:SetText(getHexColor(r,g,b))
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
	end)
	mountColor:SetScript("OnHide", function(self)
		self.colorPicker:SetScript("OnColorSelect", nil)
	end)

	-- HEX
	mountColor.hexBox:SetJustifyH("LEFT")
	mountColor.hexBox:SetTextInsets(16, 0, 0, 0)
	mountColor.hexBox:SetScript("OnTextChanged", function(self)
		self:SetText(self:GetText():gsub("[^A-Fa-f0-9]", ""))
	end)
	mountColor.hexBox:SetScript("OnEnterPressed", function(self)
		local text = self:GetText()
		local length = #text
		if length == 0 then
			self:SetText("ffffff")
		elseif length < 6 then
			local startingText = text
			while length < 6 do
				for i = 1, #startingText do
					text = text..startingText:sub(i,i)
					length = length + 1
					if length == 6 then
						break
					end
				end
			end
			self:SetText(text)
		end

		local color = CreateColorFromRGBAHexString(self:GetText().."ff")
		self:GetParent().colorPicker:SetColorRGB(color:GetRGB())
	end)

	-- THRESHOLD
	mountColor.threshold:setText(L["Tolerance"])
	mountColor.threshold:setMinMax(0, 100)
	mountColor.threshold:setOnChanged(function(_, value)
		local color = ns.mounts.filters.color
		if color.threshold == value then return end
		color.threshold = value
		if color.r then journal:updateMountsList() end
	end)

	-- RESET
	mountColor.reset:SetWidth(mountColor.reset:GetFontString():GetStringWidth() + 20)
	mountColor.reset:SetScript("OnClick", function(self)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)

		local color = ns.mounts.filters.color
		color.r = nil
		color.g = nil
		color.b = nil
		color.threshold = ns.mounts.defFilters.color.threshold

		local parent = self:GetParent()
		parent:GetScript("OnHide")(parent)
		parent:GetScript("OnShow")(parent)

		journal:updateMountsList()
	end)
end)
