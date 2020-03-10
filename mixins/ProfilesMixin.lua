local addon, L = ...
local util = MountsJournalUtil


MJProfilesMixin = util.createFromEventsMixin()


function MJProfilesMixin:onLoad()
	self.addonName = format("%s_ADDON_", strupper(addon))
	StaticPopupDialogs[self.addonName.."NEW_PROFILE"] = {
		text = addon..": "..L["New profile"],
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = 1,
		maxLetters = 48,
		editBoxWidth = 350,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = function(popup, data)
			local text = popup.editBox:GetText()
			if text and text ~= "" then
				if self.profiles[text] ~= nil then
					self.lastProfileName = text
					StaticPopup_Show(self.addonName.."PROFILE_EXISTS", nil, nil, data)
					return
				end
				self.profiles[text] = data and util:copyTable(data) or {
					fly = {},
					ground = {},
					swimming = {},
					zoneMounts = {},
					petForMount = {},
				}
				self:setProfile(text)
			end
		end,
		EditBoxOnEnterPressed = function(self)
			StaticPopup_OnClick(self:GetParent(), 1)
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		OnShow = function(self)
			self.editBox:SetText(UnitName("player").." - "..GetRealmName())
			self.editBox:HighlightText()
		end,
	}
	local function profileExistsAccept(popup, data)
		if not popup then return end
		local dialog = StaticPopup_Show(self.addonName.."NEW_PROFILE", nil, nil, data)
		if dialog and self.lastProfileName then
			dialog.editBox:SetText(self.lastProfileName)
			dialog.editBox:HighlightText()
			self.lastProfileName = nil
		end
	end
	StaticPopupDialogs[self.addonName.."PROFILE_EXISTS"] = {
		text = addon..": "..L["A profile with the same name exists."],
		button1 = OKAY,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = profileExistsAccept,
		OnCancel = profileExistsAccept,
	}
	StaticPopupDialogs[self.addonName.."DELETE_PROFILE"] = {
		text = addon..": "..CONFIRM_COMPACT_UNIT_FRAME_PROFILE_DELETION,
		button1 = DELETE,
		button2 = CANCEL,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = function(_, cb) cb() end,
	}

	self.mounts = MountsJournal
	self.journal = MountsJournalFrame
	self.profiles = self.mounts.profiles
	self.charDB = self.mounts.charDB
	self.profileNames = {}
	self:SetText(self.charDB.currentProfileName or DEFAULT)
	UIDropDownMenu_Initialize(self.optionsMenu, self.menuInit, "MENU")
end


function MJProfilesMixin:createProfile(copy)
	CloseDropDownMenus()
	local currentProfile
	if copy then
		if self.charDB.currentProfileName and self.profiles[self.charDB.currentProfileName] then
			currentProfile = self.profiles[self.charDB.currentProfileName]
		else
			currentProfile = {
				fly = self.journal.db.fly,
				ground = self.journal.db.ground,
				swimming = self.journal.db.swimming,
				zoneMounts = self.journal.db.zoneMounts,
				petForMount = self.journal.db.petForMount,
			}
		end
	end
	StaticPopup_Show(self.addonName.."NEW_PROFILE", nil, nil, currentProfile)
end


function MJProfilesMixin:deleteProfile(profileName)
	StaticPopup_Show(self.addonName.."DELETE_PROFILE", NORMAL_FONT_COLOR_CODE..profileName..FONT_COLOR_CODE_CLOSE, nil, function()
		self.profiles[profileName] = nil
		if self.charDB.currentProfileName == profileName then
			self:setProfile()
		else
			self.mounts:setDB()
		end
	end)
end


function MJProfilesMixin:setProfile(profileName)
	if profileName == nil or self.profiles[profileName] then
		self.charDB.currentProfileName = profileName
		self:SetText(profileName or DEFAULT)
		self:event("SET_PROFILE")
	end
end


function MJProfilesMixin:menuInit(level)
	if not level then return end

	local btn = self:GetParent()
	local info = UIDropDownMenu_CreateInfo()
	info.notCheckable = true

	if UIDROPDOWNMENU_MENU_VALUE == "new" then -- NEW PROFLE
		info.text = L["Create"]
		info.func = function() btn:createProfile() end
		UIDropDownMenu_AddButton(info, level)

		info.text = L["Copy current"]
		info.func = function() btn:createProfile(true) end
		UIDropDownMenu_AddButton(info, level)

	elseif UIDROPDOWNMENU_MENU_VALUE == "specialization" then -- SPECS
		info.hasArrow = true
		info.keepShownOnClick = true

		for i = 1, GetNumSpecializations() do
			info.text = select(2, GetSpecializationInfo(i))
			info.value = i
			UIDropDownMenu_AddButton(info, level)
		end

	elseif type(UIDROPDOWNMENU_MENU_VALUE) == "number" then -- PROFILE BY SPEC
		info.notCheckable = nil
		info.keepShownOnClick = true
		info.arg2 = UIDROPDOWNMENU_MENU_VALUE

		if #btn.profileNames > 20 then
			local searchFrame = util.getDropDownSearchFrame()

			info.text = DEFAULT
			info.checked = function(self)
				return btn.charDB.profileBySpecialization[self.arg2] == nil
			end
			info.func = function(_,_, arg2)
				btn.charDB.profileBySpecialization[arg2] = nil
				btn.mounts:setDB()
			end
			searchFrame:addButton(info)

			for _, profileName in ipairs(btn.profileNames) do
				info.text = profileName
				info.arg1 = profileName
				info.checked = function(self)
					return btn.charDB.profileBySpecialization[self.arg2] == self.arg1
				end
				info.func = function(_, arg1, arg2)
					btn.charDB.profileBySpecialization[arg2] = arg1
					btn.mounts:setDB()
				end
				searchFrame:addButton(info)
			end

			UIDropDownMenu_AddButton({customFrame = searchFrame}, level)
		else
			info.text = DEFAULT
			info.checked = function(self)
				return btn.charDB.profileBySpecialization[self.arg2] == nil
			end
			info.func = function(_,_, arg2)
				btn.charDB.profileBySpecialization[arg2] = nil
				btn.mounts:setDB()
				UIDropDownMenu_Refresh(btn.optionsMenu)
			end
			UIDropDownMenu_AddButton(info, level)

			for _, profileName in ipairs(btn.profileNames) do
				info.text = profileName
				info.arg1 = profileName
				info.checked = function(self)
					return btn.charDB.profileBySpecialization[self.arg2] == self.arg1
				end
				info.func = function(_, arg1, arg2)
					btn.charDB.profileBySpecialization[arg2] = arg1
					btn.mounts:setDB()
					UIDropDownMenu_Refresh(btn.optionsMenu)
				end
				UIDropDownMenu_AddButton(info, level)
			end
		end

	else -- MENU
		info.isTitle = true

		info.text = L["Profiles"]
		UIDropDownMenu_AddButton(info, level)

		UIDropDownMenu_AddSeparator(level)

		info.isTitle = nil
		info.notCheckable = nil
		info.disabled = nil

		if #btn.profileNames > 20 then
			local searchFrame = util.getDropDownSearchFrame()

			info.text = DEFAULT
			info.checked = function() return btn.charDB.currentProfileName == nil end
			info.func = function() btn:setProfile() end
			searchFrame:addButton(info)

			for _, profileName in ipairs(btn.profileNames) do
				info.text = profileName
				info.arg1 = profileName
				info.checked = function(self) return btn.charDB.currentProfileName == self.arg1 end
				info.func = function(_, arg1) btn:setProfile(arg1) end
				info.remove = function(_, arg1) btn:deleteProfile(arg1) end
				searchFrame:addButton(info)
			end

			UIDropDownMenu_AddButton({customFrame = searchFrame}, level)
		else
			info.text = DEFAULT
			info.checked = function() return btn.charDB.currentProfileName == nil end
			info.func = function() btn:setProfile() end
			UIDropDownMenu_AddButton(info, level)

			for _, profileName in ipairs(btn.profileNames) do
				local buttonFrame = util.getDropDownMenuButtonFrame()
				buttonFrame.text = profileName
				buttonFrame.arg1 = profileName
				buttonFrame.checked = function(self) return btn.charDB.currentProfileName == self.arg1 end
				buttonFrame.func = function(_, arg1) btn:setProfile(arg1) end
				buttonFrame.remove = function(_, arg1) btn:deleteProfile(arg1) end

				info.customFrame = buttonFrame
				UIDropDownMenu_AddButton(info, level)
			end

			info.customFrame = nil
		end

		UIDropDownMenu_AddSeparator(level)

		info.checked = nil
		info.func = nil
		info.arg1 = nil
		info.keepShownOnClick = true
		info.notCheckable = true
		info.hasArrow = true

		info.text = L["New profile"]
		info.value = "new"
		UIDropDownMenu_AddButton(info, level)

		UIDropDownMenu_AddSeparator(level)

		info.notCheckable = nil
		info.isNotRadio = true
		info.text = L["By Specialization"]
		info.value = "specialization"
		info.checked = function() return btn.charDB.profileBySpecialization.enable end
		info.func = function(_,_,_, checked)
			btn.charDB.profileBySpecialization.enable = checked
			btn.mounts:setDB()
		end
		UIDropDownMenu_AddButton(info, level)
	end
end


function MJProfilesMixin:onClick()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	wipe(self.profileNames)
	for k in pairs(self.profiles) do tinsert(self.profileNames, k) end
	sort(self.profileNames, function(a, b) return a < b end)
	ToggleDropDownMenu(1, nil, self.optionsMenu, self, 111, 15)
end