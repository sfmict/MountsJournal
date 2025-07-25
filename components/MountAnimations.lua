local addon, ns = ...
local L, util = ns.L, ns.util


ns.journal:on("MODULES_INIT", function(journal)
	local lsfdd = LibStub("LibSFDropDown-1.5")
	local dd = lsfdd:CreateModernButtonOriginal(journal.modelScene)
	dd:ddSetDisplayMode(addon)
	dd:SetAlpha(0)
	dd:SetPoint("LEFT", journal.modelScene.modelControl, "RIGHT", 10, 0)
	journal.modelScene.animationsCombobox = dd

	dd:SetScript("OnEnter", function(self)
		local parent = self:GetParent()
		parent:GetScript("OnEnter")(parent)
		self:SetAlpha(1)
	end)
	dd:SetScript("OnLeave", function(self)
		local parent = self:GetParent()
		parent:GetScript("OnLeave")(parent)
	end)

	StaticPopupDialogs[util.addonName.."DELETE_MOUNT_ANIMATION"] = {
		text = addon..": "..L["Are you sure you want to delete animation %s?"],
		button1 = DELETE,
		button2 = CANCEL,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = function(_, cb) cb() end,
	}

	dd.animations = ns.mounts.globalDB.mountAnimations
	dd.animationList = {
		{
			name = L["Default"],
			animation = 0,
			selfAnimation = 618,
		},
		{
			name = L["Mount special"],
			animation = 1371,
			isKit = true,
			selfAnimation = 636,
		},
		{
			name = L["Walk"],
			animation = 4,
			selfAnimation = 620,
			type = 2,
		},
		{
			name = L["Walk backwards"],
			animation = 13,
			selfAnimation = 634,
			type = 2,
		},
		{
			name = L["Run"],
			animation = 5,
			selfAnimation = 622,
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
		{
			name = SUMMON,
			animation = 1496,
			type = 1,
		},
		{
			name = C_Spell.GetSpellName(372610), -- Skyward Ascent
			animation = 1726,
			type = 1,
		},
		{
			name = C_Spell.GetSpellName(372608), -- Surge Forward
			animation = 1680,
			type = 1,
		},
		{
			name = C_Spell.GetSpellName(361584), -- Whirling Surge
			animation = 1534,
			type = 1,
		},
	}

	dd.customAnimationPanel = CreateFrame("FRAME", nil, journal.modelScene, "MJMountCustomAnimationPanel")
	dd.customAnimationPanel:SetPoint("BOTTOMRIGHT", dd, "TOPRIGHT", 0, 2)

	journal:on("MOUNT_MODEL_LOADED", function(journal, frame)
		if frame then
			dd:playAnimationForGrid(journal.gridModelAnimation:ddGetSelectedValue(), frame)
		else
			local selectedValue = dd:ddGetSelectedValue()
			if selectedValue == "custom" then
				dd.customAnimationPanel:play()
			elseif selectedValue then
				dd:playAnimation(selectedValue)
			end
		end
	end)

	journal:on("MOUNT_MODEL_UPDATE", function(journal, mountType, isPlayer)
		if mountType then
			dd.isPlayer = isPlayer

			if mountType == 231 then
				dd.currentMountType = 2
			else
				mountType = journal.mountTypes[mountType]
				dd.currentMountType = type(mountType) == "table" and mountType[1] or mountType
			end

			if dd.currentMountType == 4 then
				dd.currentMountType = 0
			end

			local selectedValue = dd:ddGetSelectedValue()
			if not selectedValue or selectedValue ~= "custom" and selectedValue.type and dd.currentMountType > selectedValue.type then
				dd:ddSetSelectedValue(dd.animationList[1])
				dd:ddSetSelectedText(dd.animationList[1].name)
			end
		end
	end)

	dd:ddSetInitFunc(function(self, level)
		local info = {list = {}}
		local mountType = self.currentMountType or 1

		local function checked(btn) return self:ddGetSelectedValue() == btn.value end
		local function func(btn)
			self.customAnimationPanel:Hide()
			self:playAnimation(btn.value)
			self:ddSetSelectedValue(btn.value, level)
			self:ddSetSelectedText(btn.value.name)
		end
		local function remove(btn) self:deleteAnimation(btn.arg1) end

		self:addMountAnimationToList(info.list, mountType, checked, func, remove)
		tinsert(info.list, {
			text = CUSTOM,
			value = "custom",
			checked = checked,
			func = function(btn)
				self.customAnimationPanel:Show()
				self.customAnimationPanel:play()
				self:ddSetSelectedValue(btn.value, level)
			end,
		})
		self:ddAddButton(info, level)
	end)

	function dd:addMountAnimationToList(list, mountType, checked, func, remove)
		for i, v in ipairs(self.animationList) do
			if v.type == nil or v.type >= mountType then
				local animation, isKit
				if self.isPlayer then
					animation = v.selfAnimation or v.animation
					isKit = v.selfIsKit
				else
					animation = v.animation
					isKit = v.isKit
				end
				tinsert(list, {
					keepShownOnClick = true,
					text = v.name,
					rightText = ("|cff808080%s%d|r"):format(isKit and "k" or "", animation),
					rightFont = util.codeFont,
					value = v,
					checked = checked,
					func = func,
				})
			end
		end
		for i, v in ipairs(self.animations) do
			tinsert(list, {
				keepShownOnClick = true,
				text = v.name,
				rightText = ("|cff808080%s%d|r"):format(v.isKit and "k" or "", v.animation),
				rightFont = util.codeFont,
				value = v,
				checked = checked,
				func = func,
				remove = remove,
			})
		end
	end

	function dd:playAnimationScene(anim, isPlayer, modelScene)
		local animation, isKit
		if isPlayer then
			animation = anim.selfAnimation or anim.animation or anim.current
			if anim.current then
				isKit = anim.isKit
			else
				isKit = anim.selfIsKit
			end
		else
			animation = anim.animation or anim.current
			isKit = anim.isKit
		end

		local actor = modelScene:GetActorByTag("unwrapped")
		actor:SetAnimation(0, 0)
		actor:StopAnimationKit()
		--max animation 2^31 - 1
		if isKit then
			actor:PlayAnimationKit(animation, anim.loop)
		else
			actor:PlayAnimationKit(0)
			actor:StopAnimationKit()
			actor:SetAnimation(animation, 0)
		end
	end

	function dd:playAnimation(anim)
		self:playAnimationScene(anim, self.isPlayer, journal.modelScene)
	end

	function dd:playAnimationForGrid(anim, f)
		local mountType = f.mountType
		if mountType == 231 then
			mountType = 2
		else
			mountType = journal.mountTypes[mountType]
			if type(mountType) == "table" then mountType = mountType[1] end
		end
		if anim.type and mountType > anim.type then anim = dd.animationList[1] end
		self:playAnimationScene(anim, f.isSelfMount, f.modelScene)
	end

	function dd:deleteAnimation(id)
		local animation = self.animations[id]
		StaticPopup_Show(util.addonName.."DELETE_MOUNT_ANIMATION", NORMAL_FONT_COLOR_CODE..animation.name..FONT_COLOR_CODE_CLOSE, nil, function()
			if self:ddGetSelectedValue() == animation then
				local value = self.animationList[1]
				self:playAnimation(value)
				self:ddSetSelectedValue(value)
				self:ddSetSelectedText(value.name)
			end
			for i = 1, #self.animations do
				if self.animations[i] == animation then
					tremove(self.animations, i)
					break
				end
			end
		end)
	end

	-- GRID MODEL ANIMATION
	journal.gridModelAnimation = lsfdd:CreateModernButtonOriginal(journal.gridModelSettings, 150)
	journal.gridModelAnimation:SetPoint("LEFT", journal.gridModelSettings, "RIGHT", -182, 0)
	journal.gridModelAnimation:SetHeight(20)
	journal.gridModelAnimation.Arrow:SetPoint("RIGHT", 3, -3)
	journal.gridModelAnimation:ddSetDisplayMode(addon)
	journal.gridModelAnimation:ddSetSelectedValue(dd.animationList[1])
	journal.gridModelAnimation:ddSetSelectedText(dd.animationList[1].name)

	journal.gridModelAnimation:ddSetInitFunc(function(self, level)
		local info = {list = {}}

		local function checked(btn) return self:ddGetSelectedValue() == btn.value end
		local function func(btn)
			for i, f in ipairs(journal.view:GetFrames()) do
				dd:playAnimationForGrid(btn.value, f)
			end
			self:ddSetSelectedValue(btn.value, level)
			self:ddSetSelectedText(btn.value.name)
		end

		dd:addMountAnimationToList(info.list, 1, checked, func)
		self:ddAddButton(info, level)
	end)
end)


MJMountCustomAnimationMixin = {}


function MJMountCustomAnimationMixin:onLoad()
	self.journal = ns.journal
	self.animations = ns.mounts.globalDB.mountAnimations
	self.animationsCombobox = self:GetParent().animationsCombobox
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
		self:nextAnimation(delta)
	end)

	self.minus:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self:nextAnimation(-1)
	end)

	self.plus:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self:nextAnimation(1)
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


function MJMountCustomAnimationMixin:nextAnimation(delta)
	self:setAnimation(Wrap(self.animations.current + 1 + delta, 2^31) - 1)
end


function MJMountCustomAnimationMixin:setAnimation(n)
	self.animations.current = n
	self.animationNum:SetText(n)
	self:play()
end


function MJMountCustomAnimationMixin:play()
	self.animationsCombobox:playAnimation(self.animations)
end


function MJMountCustomAnimationMixin:stop()
	local actor = self.journal.modelScene:GetActorByTag("unwrapped")
	actor:StopAnimationKit()
	actor:SetAnimation(0)
end


function MJMountCustomAnimationMixin:saveAnimation()
	local name = self.nameBox:GetText()
	if #name > 0 then
		tinsert(self.animations, {
			name = name,
			animation = self.animations.current or 0,
			isKit = self.isKit:GetChecked(),
			loop = self.loop:GetChecked(),
		})
		sort(self.animations, function(a1, a2)
			if a1.name < a2.name then return true
			elseif a1.name > a2.name then return false end

			if not a1.isKit and a2.isKit then return true
			elseif a1.isKit and not a2.isKit then return false end

			return a1.animation < a2.animation
		end)
		self.nameBox:SetText("")
	end
end