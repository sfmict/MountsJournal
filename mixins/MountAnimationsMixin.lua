local addon, L = ...
local util = MountsJournalUtil


MJMountAnimationPanelMixin = {}


function MJMountAnimationPanelMixin:onLoad()
	StaticPopupDialogs[util.addonName.."DELETE_MOUNT_ANIMATION"] = {
		text = addon..": "..L["Are you sure you want to delete animation %s?"],
		button1 = DELETE,
		button2 = CANCEL,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = function(_, cb) cb() end,
	}

	self.journal = MountsJournalFrame
	self.modelScene = self.journal.modelScene
	self.animations = MountsJournal.globalDB.mountAnimations
	self.animationsList = {
		{
			name = L["Default"],
			animation = 0,
		},
		{
			name = L["Mount special"],
			animation = 1371,
			isKit = true,
		},
		{
			name = L["Walk"],
			animation = 4,
			type = 2,
		},
		{
			name = L["Walk backwards"],
			animation = 13,
			type = 2,
		},
		{
			name = L["Run"],
			animation = 5,
			type = 2,
		},
		{
			name = L["Swim idle"],
			animation = 532,
			type = 3,
		},
		{
			name = L["Swim"],
			animation = 540,
			type = 3,
		},
		{
			name = L["Swim backwards"],
			animation = 534,
			type = 3,
		},
		{
			name = L["Fly stand"],
			animation = 548,
			type = 1,
		},
		{
			name = L["Fly"],
			animation = 558,
			type = 1,
		},
		{
			name = L["Fly backwards"],
			animation = 562,
			type = 1,
		},
	}

	self.customAnimationPanel = CreateFrame("FRAME", nil, self, "MJMountCustomAnimationPanel")
	self.customAnimationPanel:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 2)

	self.journal:on("MOUNT_SELECT", function(_, mountID)
		if mountID then
			local _,_,_,_, mountType = C_MountJournal.GetMountInfoExtraByID(mountID)
			self.currentMountType = mountType == 231 and 2 or self.journal.mountTypes[mountType]
			self:replayAnimation()
		end
	end)
end


function MJMountAnimationPanelMixin:replayAnimation()
	if self.selectedValue == "custom" or self.selectedValue and (self.selectedValue.type == nil	or self.selectedValue.type >= self.currentMountType) then
		if self.selectedValue.animation ~= 0 then
			self:SetScript("OnUpdate", self.onUpdate)
		end
	else
		self.modelScene:GetActorByTag("unwrapped"):StopAnimationKit()
		self:ddSetSelectedValue(self.animationsList[1])
		self:ddSetSelectedText(self.animationsList[1].name)
	end
end


function MJMountAnimationPanelMixin:onUpdate()
	local actor = self.modelScene:GetActorByTag("unwrapped")
	if not actor:IsLoaded() then return end
	self:SetScript("OnUpdate", nil)

	C_Timer.After(0, function()
		if self.selectedValue == "custom" then
			self.customAnimationPanel:play()
		else
			self:playAnimation(self.selectedValue.animation, self.selectedValue.isKit, self.selectedValue.loop)
		end
	end)
end


function MJMountAnimationPanelMixin:initialize(level)
	local info = {}
	local mountType = self.currentMountType or 1

	info.list = {}
	for _, v in ipairs(self.animationsList) do
		if v.type == nil or v.type >= mountType then
			tinsert(info.list, {
				text = ("%s|cff808080.%d%s|r"):format(v.name, v.animation, v.isKit and ".k" or ""),
				searchText = ("%s.%d%s"):format(v.name, v.animation, v.isKit and ".k" or ""),
				value = v,
				checked = function(btn) return self.selectedValue == btn.value end,
				func = function(btn)
					self.customAnimationPanel:Hide()
					self:playAnimation(btn.value.animation, btn.value.isKit)
					self:ddSetSelectedValue(btn.value, level)
					self:ddSetSelectedText(btn.value.name)
				end,
			})
		end
	end
	for i, v in ipairs(self.animations) do
		tinsert(info.list, {
			text = ("%s|cff808080.%d%s|r"):format(v.name, v.animation, v.isKit and ".k" or ""),
			searchText = ("%s.%d%s"):format(v.name, v.animation, v.isKit and ".k" or ""),
			value = v,
			arg1 = i,
			checked = function(btn) return self.selectedValue == btn.value end,
			func = function(btn)
				self.customAnimationPanel:Hide()
				self:playAnimation(btn.value.animation, btn.value.isKit, btn.value.loop)
				self:ddSetSelectedValue(btn.value, level)
				self:ddSetSelectedText(btn.value.name)
			end,
			remove = function(btn) self:deleteAnimation(btn.arg1) end,
		})
	end
	tinsert(info.list, {
		text = CUSTOM,
		value = "custom",
		checked = function(btn) return self.selectedValue == btn.value end,
		func = function(btn)
			self.customAnimationPanel:Show()
			self.customAnimationPanel:play()
			self:ddSetSelectedValue(btn.value, level)
		end,
	})
	self:ddAddButton(info, level)
end


function MJMountAnimationPanelMixin:playAnimation(animation, isKit, loop)
	local actor = self.modelScene:GetActorByTag("unwrapped")
	actor:StopAnimationKit()
	actor:SetAnimation(0)
	if isKit then
		actor:PlayAnimationKit(animation, loop)
	else
		actor:SetAnimation(animation, 0)
	end
end


function MJMountAnimationPanelMixin:deleteAnimation(id)
	StaticPopup_Show(util.addonName.."DELETE_MOUNT_ANIMATION", NORMAL_FONT_COLOR_CODE..self.animations[id].name..FONT_COLOR_CODE_CLOSE, nil, function()
		if self.selectedValue == self.animations[id] then
			local value = self.animationsList[1]
			self:playAnimation(value.animation, value.isKit, value.loop)
			self:ddSetSelectedValue(value)
			self:ddSetSelectedText(value.name)
		end
		tremove(self.animations, id)
	end)
end


MJMountCustomAnimationMixin = {}


function MJMountCustomAnimationMixin:onLoad()
	self.journal = MountsJournalFrame
	self.modelScene = self.journal.modelScene
	self.animations = MountsJournal.globalDB.mountAnimations
	if type(self.animations.current) ~= "number" then
		self.animations.current = 0
	end

	self.animationNum:SetText(self.animations.current)
	self.animationNum:SetScript("OnEnterPressed", function(edit)
		self.animations.current = tonumber(edit:GetText()) or 0
		self:play()
		edit:ClearFocus()
	end)
	self.animationNum:SetScript("OnEscapePressed", function(edit)
		edit:SetText(self.animations.current)
		edit:ClearFocus()
	end)
	self.animationNum:SetScript("OnEditFocusLost", function(edit)
		self.animations.current = tonumber(edit:GetText()) or 0
	end)
	self.animationNum:SetScript("OnMouseWheel", function(_, delta)
		if delta > 0 then
			self:nextAnimation()
		else
			self:previousAnimation()
		end
	end)

	self.minus:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self:previousAnimation()
	end)

	self.plus:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self:nextAnimation()
	end)

	self.playButton:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self:play()
	end)
	self.playButton:HookScript("OnMouseDown", function(self)
		self.texture:SetPoint("CENTER", -1, -2)
	end)
	self.playButton:HookScript("OnMouseUp", function(self)
		self.texture:SetPoint("CENTER")
	end)

	self.stopButton:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self:stop()
	end)
	self.stopButton:HookScript("OnMouseDown", function(self)
		self.texture:SetPoint("CENTER", -1, -2)
	end)
	self.stopButton:HookScript("OnMouseUp", function(self)
		self.texture:SetPoint("CENTER")
	end)

	self.isKit.Text:SetText("IsKit")
	self.isKit:SetChecked(self.animations.isKit)
	self.isKit:SetScript("Onclick", function(btn)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		local checked = btn:GetChecked()
		self.animations.isKit = checked
		self.loop:SetEnabled(checked)
		self:play()
	end)

	self.loop.Text:SetText(L["Loop"])
	self.loop:SetChecked(self.animations.loop)
	self.loop:SetEnabled(self.animations.isKit)
	self.loop:SetScript("OnClick", function(btn)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self.animations.loop = btn:GetChecked()
		self:play()
	end)

	self.save:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self:saveAnimation()
	end)
end


function MJMountCustomAnimationMixin:previousAnimation()
	if self.animations.current > 0 then
		self:setAnimation(self.animations.current - 1)
	end
end


function MJMountCustomAnimationMixin:nextAnimation()
	if self.animations.current < 10000 then
		self:setAnimation(self.animations.current + 1)
	end
end


function MJMountCustomAnimationMixin:setAnimation(n)
	self.animations.current = n
	self.animationNum:SetText(n)
	self:play()
end


function MJMountCustomAnimationMixin:play()
	self:GetParent():playAnimation(self.animations.current, self.animations.isKit, self.animations.loop)
end


function MJMountCustomAnimationMixin:stop()
	local actor = self.modelScene:GetActorByTag("unwrapped")
	actor:StopAnimationKit()
	actor:SetAnimation(0)
end


function MJMountCustomAnimationMixin:saveAnimation()
	local name = self.nameBox:GetText()
	if name:len() > 0 then
		tinsert(self.animations, {
			name = name,
			animation = self.animations.current or 0,
			isKit = self.isKit:GetChecked(),
			loop = self.loop:GetChecked(),
		})
		self.nameBox:SetText("")
	end
end