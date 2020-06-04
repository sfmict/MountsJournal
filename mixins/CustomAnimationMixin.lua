local addon, L = ...


MJCustomAnimationMixin = {}


function MJCustomAnimationMixin:onLoad()
	self.journal = MountsJournalFrame
	self.modelScene = self.journal.modelScene
	self.animations = MountsJournal.customAnimations
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
	self.isKit:SetScript("Onclick", function(btn)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self.loop:SetEnabled(btn:GetChecked())
		self:play()
	end)

	self.loop.Text:SetText(L["Loop"])
	self.loop:Disable()
	self.loop:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self:play()
	end)

	self.save:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self:saveAnamtion()
	end)
end


function MJCustomAnimationMixin:previousAnimation()
	if self.animations.current > 0 then
		self:setAnimation(self.animations.current - 1)
	end
end


function MJCustomAnimationMixin:nextAnimation()
	if self.animations.current < 10000 then
		self:setAnimation(self.animations.current + 1)
	end
end


function MJCustomAnimationMixin:setAnimation(n)
	self.animations.current = n
	self.animationNum:SetText(n)
	self:play()
end


function MJCustomAnimationMixin:playAnimation(animation, isKit, loop)
	self:stop()
	local actor = self.modelScene:GetActorByTag("unwrapped")
	if isKit then
		actor:PlayAnimationKit(animation, loop)
	else
		actor:SetAnimation(animation, 0)
	end
end


function MJCustomAnimationMixin:play()
	self:playAnimation(self.animations.current, self.isKit:GetChecked(), self.loop:GetChecked())
end


function MJCustomAnimationMixin:stop()
	local actor = self.modelScene:GetActorByTag("unwrapped")
	actor:StopAnimationKit()
	actor:SetAnimation(0)
end


function MJCustomAnimationMixin:saveAnamtion()
	tinsert(self.animations, {
		name = self.nameBox:GetText(),
		animation = tonumber(self.animationNum:GetText()) or 0,
		isKit = self.isKit:GetChecked(),
		loop = self.loop:GetChecked(),
	})
	-- self.nameBox:SetText("")
end