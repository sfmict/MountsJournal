local addon, L = ...


MJProfilesMixin = {}


function MJProfilesMixin:onLoad()
	StaticPopupDialogs["MJ_NEW_PROFILE"] = {
		text = addon..": "..L["New profile"],
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = 1,
		maxLetters = 24,
		hideOnEscape = 1,
		OnAccept = function(popup, data)
			local text = popup.editBox:GetText()
			if text and text ~= "" then
				if self.profiles[text] ~= nil then
					StaticPopup_Show("MJ_PROFILE_EXISTS")
					return
				end
				self.profiles[text] = data and MountsJournalUtil.copyTable(data) or {
					fly = {},
					ground = {},
					swimming = {},
					zoneMounts = {},
				}
				self:setProfile(text)
			end
		end,
		EditBoxOnEnterPressed = function (self)
			StaticPopup_OnClick(self:GetParent(), 1)
		end,
		EditBoxOnEscapePressed = function (self)
			self:GetParent():Hide()
		end,
	}

	StaticPopupDialogs["MJ_PROFILE_EXISTS"] = {
		text = L["A profile with the same name exists."],
		button1 = OKAY,
	}

	StaticPopupDialogs["MJ_DELETE_PROFILE"] = {
		text = addon..": "..CONFIRM_COMPACT_UNIT_FRAME_PROFILE_DELETION,
		button1 = DELETE,
		button2 = CANCEL,
		hideOnEscape = 1,
		OnAccept = function(popup) self.profiles[popup.text.text_arg1] = nil end,
	}

	self.mounts = MountsJournal
	self.journal = MountsJournalFrame
	self.profiles = self.mounts.profiles
	self.charDB = self.mounts.charDB
	self.profilesNames = {}
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
				fly = self.mounts.db.fly,
				ground = self.mounts.db.ground,
				swimming = self.mounts.db.swimming,
				zoneMounts = self.mounts.db.zoneMounts,
			}
		end
	end
	StaticPopup_Show("MJ_NEW_PROFILE", nil, nil, currentProfile)
end


function MJProfilesMixin:deleteProfile(profileName)
	CloseDropDownMenus()
	StaticPopup_Show("MJ_DELETE_PROFILE", profileName)
end


function MJProfilesMixin:setProfile(profileName)
	if profileName == nil or self.profiles[profileName] then
		self.charDB.currentProfileName = profileName
		self:SetText(profileName or DEFAULT)
		self.mounts:setDB()
		self.journal:setEditMountsList()
		self.journal:updateMountsList()
		MountJournal_UpdateMountList()
		self.journal:updateMapSettings()
		self.journal.existingsLists:refresh()
	end
end


function MJProfilesMixin:menuInit(level)
	local btn = self:GetParent()
	local info = UIDropDownMenu_CreateInfo()
	info.notCheckable = true

	if UIDROPDOWNMENU_MENU_VALUE == 1 then -- NEW PROFLE
		info.text = L["Create"]
		info.func = function() btn:createProfile() end
		UIDropDownMenu_AddButton(info, level)

		info.text = L["Copy current"]
		info.func = function() btn:createProfile(true) end
		UIDropDownMenu_AddButton(info, level)

	elseif UIDROPDOWNMENU_MENU_VALUE == 2 then -- DELETE RPFOLE
		local i = 0
		for _,profileName in ipairs(btn.profilesNames) do
			if profileName ~= btn.charDB.currentProfileName then
				info.text = profileName
				info.arg1 = profileName
				info.func = function(_,arg1) btn:deleteProfile(arg1) end
				UIDropDownMenu_AddButton(info, level)
				i = i + 1
			end
		end

		if i == 0 then
			info.disabled = true
			info.text = EMPTY
			UIDropDownMenu_AddButton(info, level)
		end

	else
		info.isTitle = true
		
		info.text = L["Profiles"]
		UIDropDownMenu_AddButton(info, level)

		UIDropDownMenu_AddSeparator(level)

		info.isTitle = nil
		info.notCheckable = nil
		info.disabled = nil
		
		info.text = DEFAULT
		info.checked = function() return btn.charDB.currentProfileName == nil end
		info.func = function() btn:setProfile() end
		UIDropDownMenu_AddButton(info, level)

		for _,profileName in ipairs(btn.profilesNames) do
			info.text = profileName
			info.arg1 = profileName
			info.checked = function(self) return btn.charDB.currentProfileName == self.arg1 end
			info.func = function(_,arg1) btn:setProfile(arg1) end
			UIDropDownMenu_AddButton(info, level)
		end

		UIDropDownMenu_AddSeparator(level)

		info.notCheckable = true
		info.hasArrow = true
		info.keepShownOnClick = true
		info.checked = nil
		info.func = nil

		info.text = L["New profile"]
		info.value = 1
		UIDropDownMenu_AddButton(info, level)

		info.text = L["Delete profile"]
		info.value = 2
		UIDropDownMenu_AddButton(info, level)
	end
end


function MJProfilesMixin:onClick()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	wipe(self.profilesNames)
	for k in pairs(self.profiles) do tinsert(self.profilesNames, k) end
	sort(self.profilesNames, function(a, b) return a < b end)
	ToggleDropDownMenu(1, nil, self.optionsMenu, self, 111, 15)
end