local addon, ns = ...
local L, util, macroFrame, mounts = ns.L, ns.util, ns.macroFrame, ns.mounts
local IndentationLib = IndentationLib
local codeEdit = CreateFrame("FRAME", "MountsJournalCodeEdit", ns.ruleConfig, "MJDarkPanelTemplate,MJEscHideTemplate")
ns.codeEdit = codeEdit
codeEdit:Hide()


local escOnShow = codeEdit:GetScript("OnShow")
codeEdit:SetScript("OnShow", function(self)
	self:EnableMouse(true)
	self:SetFrameLevel(1600)
	self:SetPoint("TOPLEFT", ns.journal.bgFrame, 0, -18)
	self:SetPoint("BOTTOMRIGHT", ns.snippets)
	self:SetBackdropColor(.1, .1, .1, .9)
	local font = "Interface\\Addons\\MountsJournal\\Fonts\\FiraCode-Regular.ttf"

	self:SetScript("OnShow", escOnShow)
	self:HookScript("OnHide", function(self)
		if not self:IsShown() then
			self.history = nil
			self.historyPos = nil
		end
	end)

	StaticPopupDialogs[util.addonName.."SAVE_CODE"] = {
		text = addon..": "..L["Do you want to save changes?"],
		button1 = YES,
		button2 = NO,
		button3 = CANCEL,
		whileDead = 1,
		selectCallbackByIndex = true,
		OnButton1 = function(self, cb) self:Hide() cb() end,
		OnButton2 = function(self) self:Hide() codeEdit:Hide() end,
		OnButton3 = function(self) self:Hide() end,
	}

	self:SetScript("OnKeyDown", function(self, key)
		if key == GetBindingKey("TOGGLEGAMEMENU") then
			StaticPopup_Show(util.addonName.."SAVE_CODE", nil, nil, function()
				self.completeBtn:Click()
			end)
			self:SetPropagateKeyboardInput(false)
		else
			self:SetPropagateKeyboardInput(true)
		end
	end)
	escOnShow(self)

	-- EDITOR THEMES
	local editorThemes= {
		["Standard"] = {
			["Table"] = "|c00ff3333",
			["Arithmetic"] = "|c00ff3333",
			["Relational"] = "|c00ff3333",
			["Logical"] = "|c004444ff",
			["Special"] = "|c00ff3333",
			["Keyword"] = "|c004444ff",
			["Comment"] = "|c0000aa00",
			["Number"] = "|c00ff9900",
			["String"] = "|c00999999"
		},
		["Monokai"] = {
			["Table"] = "|c00ffffff",
			["Arithmetic"] = "|c00f92672",
			["Relational"] = "|c00ff3333",
			["Logical"] = "|c00f92672",
			["Special"] = "|c0066d9ef",
			["Keyword"] = "|c00f92672",
			["Comment"] = "|c0075715e",
			["Number"] = "|c00ae81ff",
			["String"] = "|c00e6db74"
		},
		["Obsidian"] = {
			["Table"] = "|c00AFC0E5",
			["Arithmetic"] = "|c00E0E2E4",
			["Relational"] = "|c00B3B689",
			["Logical"] = "|c0093C763",
			["Special"] = "|c00AFC0E5",
			["Keyword"] = "|c0093C763",
			["Comment"] = "|c0066747B",
			["Number"] = "|c00FFCD22",
			["String"] = "|c00EC7600"
		},
		["Twilight"] = {
			["Table"] = "|c00FFFFFF",
			["Arithmetic"] = "|c00CDA869",
			["Relational"] = "|c00CDA869",
			["Logical"] = "|c00CDA869",
			["Special"] = "|c00FFFFFF",
			["Keyword"] = "|c00CDA869",
			["Comment"] = "|c00605A60",
			["Number"] = "|c00CF6137",
			["String"] = "|c008F9D6A",
			["Global"] = "|c00F9EE98",
			["Orange"] = "|c00CF6137",
			["Text"] = CreateColorFromHexString("FF92a7cd"),
		},
	}

	-- default
	mounts.globalDB.editorTheme = mounts.globalDB.editorTheme or "Twilight"
	mounts.globalDB.editorTabSpaces = mounts.globalDB.editorTabSpaces or 4
	mounts.globalDB.editorFontSize = mounts.globalDB.editorFontSize or 12

	local colorScheme = {[0] = "|r"}
	local function setScheme()
		local theme = editorThemes[mounts.globalDB.editorTheme]
		colorScheme[IndentationLib.tokens.TOKEN_SPECIAL] = theme["Special"]
		colorScheme[IndentationLib.tokens.TOKEN_KEYWORD] = theme["Keyword"]
		colorScheme[IndentationLib.tokens.TOKEN_COMMENT_SHORT] = theme["Comment"]
		colorScheme[IndentationLib.tokens.TOKEN_COMMENT_LONG] = theme["Comment"]
		colorScheme[IndentationLib.tokens.TOKEN_NUMBER] = theme["Number"]
		colorScheme[IndentationLib.tokens.TOKEN_STRING] = theme["String"]

		colorScheme["..."] = theme["Table"]
		colorScheme["{"] = theme["Table"]
		colorScheme["}"] = theme["Table"]
		colorScheme["["] = theme["Table"]
		colorScheme["]"] = theme["Table"]

		colorScheme["+"] = theme["Arithmetic"]
		colorScheme["-"] = theme["Arithmetic"]
		colorScheme["/"] = theme["Arithmetic"]
		colorScheme["*"] = theme["Arithmetic"]
		colorScheme[".."] = theme["Arithmetic"]

		colorScheme["=="] = theme["Relational"]
		colorScheme["<"] = theme["Relational"]
		colorScheme["<="] = theme["Relational"]
		colorScheme[">"] = theme["Relational"]
		colorScheme[">="] = theme["Relational"]
		colorScheme["~="] = theme["Relational"]

		colorScheme["and"] = theme["Logical"]
		colorScheme["or"] = theme["Logical"]
		colorScheme["not"] = theme["Logical"]

		colorScheme["math"] = theme["Orange"] or theme["Keyword"]
		colorScheme["true"] = theme["Orange"] or theme["Keyword"]
		colorScheme["false"] = theme["Orange"] or theme["Keyword"]
		colorScheme["nil"] = theme["Orange"] or theme["Keyword"]
		colorScheme["table"] = theme["Orange"] or theme["Keyword"]
		colorScheme["string"] = theme["Orange"] or theme["Keyword"]

		colorScheme["local"] = theme["Global"] or theme["Keyword"]
		colorScheme["pairs"] = theme["Global"] or theme["Keyword"]
		colorScheme["iparis"] = theme["Global"] or theme["Keyword"]
		colorScheme["next"] = theme["Global"] or theme["Keyword"]

		self.editBox:SetTextColor((theme["Text"] or HIGHLIGHT_FONT_COLOR):GetRGB())
	end

	-- NAME
	self.nameEdit = CreateFrame("EditBox", nil, self, "InputBoxTemplate")
	self.nameEdit:SetSize(300, 22)
	self.nameEdit:SetPoint("TOPLEFT", 40, -30)
	self.nameEdit:SetAutoFocus(false)
	self.nameEdit:SetScript("OnEnterPressed", EditBox_ClearFocus)

	-- LINE
	self.lineText = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	self.lineText:SetPoint("LEFT", self.nameEdit, "RIGHT", 40, 0)
	self.lineText:SetText(L["Line"])

	self.line = CreateFrame("Editbox", nil, self, "InputBoxTemplate")
	self.line:SetSize(30, 22)
	self.line:SetPoint("LEFT", self.lineText, "RIGHT", 8, 0)
	self.line:SetAutoFocus(false)
	self.line:SetJustifyH("RIGHT")
	self.line:SetTextInsets(0, 5, 0, 0)
	self.line:SetNumeric(true)

	self.line:SetScript("OnEnterPressed", function(editBox)
		local text = editBox.GetText(self.editBox)
		local line = editBox:GetNumber()
		local pos = 0
		while line > 1 and pos do
			pos = text:find("\n", pos + 1, true)
			line = line - 1
		end
		if pos then
			self.editBox:SetCursorPosition(pos)
			self.editBox:SetFocus()
		end
	end)

	-- SETTINGS
	local lsfdd = LibStub("LibSFDropDown-1.5")
	self.settings = lsfdd:CreateStretchButtonOriginal(self, 150, 22)
	self.settings:SetPoint("TOPRIGHT", -35, -30)
	self.settings:SetText(SETTINGS)
	self.settings:ddSetDisplayMode(addon)

	self.settings:ddSetInitFunc(function(dd, level, value)
		local info = {}
		info.keepShownOnClick = true

		if level == 1 then
			local check = function(btn) return mounts.globalDB.editorTheme == btn.value end
			local func = function(btn)
				mounts.globalDB.editorTheme = btn.value
				setScheme()
				self.editBox:SetText(self.editBox:GetText():trim())
				dd:ddRefresh(level)
			end

			for name in next, editorThemes do
				info.text = name
				info.value = name
				info.checked = check
				info.func = func
				dd:ddAddButton(info, level)
			end

			dd:ddAddSeparator(level)

			info.checked = nil
			info.func = nil

			info.notCheckable = true
			info.hasArrow = true
			info.text = L["Tab Size"]
			info.value = "tab"
			dd:ddAddButton(info, level)

			info.text = FONT_SIZE
			info.value = "font"
			dd:ddAddButton(info, level)
		elseif value == "tab" then
			local check = function(btn) return btn.value == mounts.globalDB.editorTabSpaces end
			local func = function(btn)
				mounts.globalDB.editorTabSpaces = btn.value
				IndentationLib.enable(self.editBox, colorScheme, mounts.globalDB.editorTabSpaces)
				self.editBox:SetText(self.editBox:GetText():trim())
				IndentationLib.indentEditbox(self.editBox)
				dd:ddRefresh(level)
			end

			for i = 2, 4 do
				info.text = i
				info.value = i
				info.checked = check
				info.func = func
				dd:ddAddButton(info, level)
			end
		elseif value == "font" then
			local check = function(btn) return btn.value == mounts.globalDB.editorFontSize end
			local func = function(btn)
				mounts.globalDB.editorFontSize = btn.value
				self.editBox:SetFont(font, mounts.globalDB.editorFontSize, "")
				dd:ddRefresh(level)
			end

			for i = 10, 16 do
				info.text = i
				info.value = i
				info.checked = check
				info.func = func
				dd:ddAddButton(info, level)
			end
		end
	end)

	-- EXAMPLES
	self.examples = lsfdd:CreateStretchButtonOriginal(self, 150, 22)
	self.examples:SetPoint("RIGHT", self.settings, "LEFT", -50, 0)
	self.examples:SetText(L["Examples"])
	self.examples:ddSetDisplayMode(addon)

	self.condExample = [[
if true then
	-- some code
  return true
end
return false -- true / false
	]]

	self.actionExample = [[
-- some code
return "" -- macro text (255 symbols) / nil
	]]

	self.examples:ddSetInitFunc(function(dd)
		local info = {}
		info.notCheckable = true

		info.func = function(btn)
			self.editBox:SetText(btn.value)
		end

		info.text = L["Conditions"]
		info.value = self.condExample
		dd:ddAddButton(info)

		info.text = L["Action"]
		info.value = self.actionExample
		dd:ddAddButton(info)
	end)

	-- CONTROL BTNS
	self.cancelBtn = CreateFrame("BUTTON", nil, self, "UIPanelButtonTemplate")
	self.cancelBtn:SetPoint("BOTTOMRIGHT", -35, 20)
	self.cancelBtn:SetText(CANCEL)
	self.cancelBtn:SetScript("OnClick", function(btn)
		btn:GetParent():Hide()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	self.completeBtn = CreateFrame("BUTTON", nil, self, "UIPanelButtonTemplate")
	self.completeBtn:SetPoint("RIGHT", self.cancelBtn, "LEFt", -20, 0)
	self.completeBtn:SetText(COMPLETE)
	self.completeBtn:SetScript("OnClick", function(btn)
		local p = btn:GetParent()
		if p.cb(p.name, p.nameEdit:GetText():trim(), p.editBox:GetText():trim()) then p:Hide() end
	end)

	local width = math.max(self.cancelBtn:GetFontString():GetStringWidth(), self.completeBtn:GetFontString():GetStringWidth()) + 40
	self.cancelBtn:SetWidth(width)
	self.completeBtn:SetWidth(width)

	-- CODE
	self.codeBtn = CreateFrame("BUTTON", nil, self, "BackdropTemplate")
	self.codeBtn:SetPoint("TOPLEFT", self.nameEdit, "BOTTOMLEFT", -8, -20)
	self.codeBtn:SetPoint("BOTTOMRIGHT", self.cancelBtn, "TOPRIGHT", 0, 20)
	self.codeBtn:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileEdge = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	self.codeBtn:SetBackdropColor(.05, .05, .05)
	self.codeBtn:SetBackdropBorderColor(FRIENDS_GRAY_COLOR:GetRGB())
	self.codeBtn:SetScript("OnClick", function(btn) btn:GetParent().editBox:SetFocus() end)

	self.codeBtn.funcText = self.codeBtn:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	self.codeBtn.funcText:SetPoint("BOTTOMLEFT", self.codeBtn, "TOPLEFT", 2, 0)
	self.codeBtn.funcText:SetText("function(state)")

	self.codeBtn.endText = self.codeBtn:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	self.codeBtn.endText:SetPoint("TOPLEFT", self.codeBtn, "BOTTOMLEFT", 2, 0)
	self.codeBtn.endText:SetText("end")

	self.scrollBar = CreateFrame("EventFrame", nil, self, "WowTrimScrollBar")
	self.scrollBar:SetPoint("TOPRIGHT", self.codeBtn, -4, -5)
	self.scrollBar:SetPoint("BOTTOMRIGHT", self.codeBtn, -4, 4)

	self.editFrame = CreateFrame("FRAME", nil, self, "ScrollingEditBoxTemplate")
	self.editBox = self.editFrame:GetEditBox()

	self.editBox:HookScript("OnKeyDown", function(editBox, key)
		if not IsControlKeyDown() then return end

		if key == "S" then
			self.completeBtn:Click()
		elseif key == "Z" then
			self.skipAddHistory = true
			if IsShiftKeyDown() then
				self:setHistory(-1)
			else
				self:setHistory(1)
			end
		elseif key == "Y" then
			self.skipAddHistory = true
			self:setHistory(-1)
		end
	end)

	self.editBox:HookScript("OnCursorChanged", function(editBox)
		local text = self.line.GetText(editBox)
		local pos = editBox:GetCursorPosition()
		local next = -1
		local line = 0
		while next and pos >= next do
			next = text:find("[\n]", next + 1)
			line = line + 1
		end
		self.line:SetNumber(line)
	end)

	self.editBox:HookScript("OnTextChanged", function(editBox, userInput)
		local str = editBox:GetText()
		if not str or str:trim() == "" then
			self.errText:SetText("")
		else
			local func, err = macroFrame.loadSnippet(str)
			self.errText:SetText(err or "")
		end
		if userInput then
			if self.skipAddHistory == true then
				self.skipAddHistory = false
				return
			end
			self.updateDelay = .2
			self:SetScript("OnUpdate", self.updateHistory)
		end
	end)

	setScheme()
	IndentationLib.enable(self.editBox, colorScheme, mounts.globalDB.editorTabSpaces)
	self.editBox:SetFont(font, mounts.globalDB.editorFontSize, "")

	local anchorsToFrame = {
		CreateAnchor("TOPLEFT", self.codeBtn, "TOPLEFT", 8, -8),
		CreateAnchor("BOTTOMRIGHT", self.codeBtn, "BOTTOMRIGHT", -8, 8),
	}
	local anchorsToBar = {
		anchorsToFrame[1],
		CreateAnchor("BOTTOMRIGHT", self.scrollBar, "BOTTOMLEFT", -3, 4),
	}
	local scrollBox = self.editFrame:GetScrollBox()
	ScrollUtil.RegisterScrollBoxWithScrollBar(scrollBox, self.scrollBar)
	ScrollUtil.AddManagedScrollBarVisibilityBehavior(scrollBox, self.scrollBar, anchorsToBar, anchorsToFrame)

	-- ERROR TEXT
	self.errText = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	self.errText:SetPoint("TOPLEFT", self.codeBtn, "BOTTOMLEFT", 40, -10)
	self.errText:SetPoint("RIGHT", self.cancelBtn, "LEFt", -10, 0)
	self.errText:SetPoint("BOTTOM", 0, 10)
	self.errText:SetTextColor(1, 0, 0)
	self.errText:SetJustifyH("LEFT")
	self.errText:SetJustifyV("TOP")
end)


function codeEdit:open(name, code, cb)
	self:Show()
	self.history = {}
	self.historyPos = 1
	self.name = name
	self.cb = cb
	self.nameEdit:SetText(name)
	self.nameEdit:SetCursorPosition(0)
	self.editBox:SetText(code or self.condExample)
	self.editBox:SetCursorPosition(0)
	IndentationLib.indentEditbox(self.editBox)
end


function codeEdit:nameFocus()
	self.nameEdit:SetFocus()
	self.nameEdit:HighlightText()
end


function codeEdit:codeFocus()
	self.editBox:SetFocus()
end


function codeEdit:updateHistory(elapsed)
	self.updateDelay = self.updateDelay - elapsed
	if self.updateDelay <= 0 then
		self:SetScript("OnUpdate", nil)
		self:addHistory()
	end
end


function codeEdit:addHistory()
	local cursorPos, success = self.editBox:GetCursorPosition()
	local text = self.line.GetText(self.editBox):trim()

	success, text, cursorPos = pcall(IndentationLib.stripWowColorsWithPos, text, cursorPos)
	if not success or self.history[self.historyPos] and self.history[self.historyPos][1] == text then return end
	-- remove history before position
	for i = 2, self.historyPos do table.remove(self.history, 1) end
	-- insert new
	table.insert(self.history, 1, {text, cursorPos - 1})
	-- remove overlimit (50)
	for i = 51, #self.history do self.history[i] = nil end
	self.historyPos = 1
end


function codeEdit:setHistory(delta)
	if self.updateDelay > 0 then
		self:SetScript("OnUpdate", nil)
		self:addHistory()
	end

	if self.history[self.historyPos + delta] then
		self.historyPos = self.historyPos + delta
		self.line.SetText(self.editBox, self.history[self.historyPos][1])
		self.editBox:SetCursorPosition(self.history[self.historyPos][2])
	end
end