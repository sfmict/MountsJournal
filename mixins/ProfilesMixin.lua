local addon, L = ...
local util = MountsJournalUtil


MJProfilesMixin = util.createFromEventsMixin()


function MJProfilesMixin:onLoad()
	self.addonName = ("%s_ADDON_"):format(addon:upper())
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
					popup:Hide()
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
		popup:Hide()
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
		text = addon..": "..L["Are you sure you want to delete profile %s?"],
		button1 = DELETE,
		button2 = CANCEL,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = function(_, cb) cb() end,
	}
	StaticPopupDialogs[self.addonName.."YOU_WANT"] = {
		text = addon..": "..L["Are you sure you want \"%s\"?"],
		button1 = OKAY,
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
	self:ddSetInit(self.initialize, "menu")
end


function MJProfilesMixin:createProfile(copy)
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
		self:event("UPDATE_PROFILE", true)
	end
end


function MJProfilesMixin:selectAllMounts()
	local profile = self.journal.db
	StaticPopup_Show(self.addonName.."YOU_WANT", NORMAL_FONT_COLOR_CODE..L["Select all mounts by type"]..FONT_COLOR_CODE_CLOSE, nil, function()
		for _, mountID in ipairs(self.journal.mountIDs) do
			local _,_,_,_,_,_,_,_,_,_, isCollected = C_MountJournal.GetMountInfoByID(mountID)
			if isCollected then
				local _,_,_,_, mountType = C_MountJournal.GetMountInfoExtraByID(mountID)
				mountType = self.journal.mountTypes[mountType]
				if mountType then
					if mountType == 1 then
						mountType = "fly"
					elseif mountType == 2 then
						mountType = "ground"
					else
						mountType = "swimming"
					end

					profile[mountType][mountID] = true
				end
			end
		end
		self.journal:updateMountsList()
	end)
end


function MJProfilesMixin:unselectAllMounts()
	local profile = self.journal.db
	StaticPopup_Show(self.addonName.."YOU_WANT", NORMAL_FONT_COLOR_CODE..L["Unselect all mounts"]..FONT_COLOR_CODE_CLOSE, nil, function()
		wipe(profile.fly)
		wipe(profile.ground)
		wipe(profile.swimming)
		self.journal:updateMountsList()
	end)
end


function MJProfilesMixin:initialize(level, value)
	local info = {}

	if value == "settings" then -- PROFILE SETTINGS
		if self.charDB.currentProfileName ~= nil then
			info.isNotRadio = true
			info.keepShownOnClick = true

			info.text = L["Pet binding from default profile"]
			info.checked = function() return self.journal.db.petListFromProfile end
			info.func = function(_,_,_, checked)
				self.journal.db.petListFromProfile = checked and true or nil
				self:event("UPDATE_PROFILE")
			end
			self:ddAddButton(info, level)

			info.text = L["Zones settings from default profile"]
			info.checked = function() return self.journal.db.zoneMountsFromProfile end
			info.func = function(_,_,_, checked)
				self.journal.db.zoneMountsFromProfile = checked and true or nil
				self:event("UPDATE_PROFILE")
			end
			self:ddAddButton(info, level)
		end

		info.notCheckable = true
		info.keepShownOnClick = nil

		info.text = L["Select all mounts by type"]
		info.func = function() self:selectAllMounts() end
		self:ddAddButton(info, level)

		info.text = L["Unselect all mounts"]
		info.func = function() self:unselectAllMounts() end
		self:ddAddButton(info, level)

	elseif value == "new" then -- NEW PROFLE
		info.notCheckable = true

		info.text = L["Create"]
		info.func = function() self:createProfile() end
		self:ddAddButton(info, level)

		info.text = L["Copy current"]
		info.func = function() self:createProfile(true) end
		self:ddAddButton(info, level)

	elseif value == "specialization" then -- SPECS
		info.notCheckable = true
		info.hasArrow = true
		info.keepShownOnClick = true

		for i = 1, GetNumSpecializations() do
			info.text = select(2, GetSpecializationInfo(i))
			info.value = i
			self:ddAddButton(info, level)
		end

	elseif type(value) == "number" then -- PROFILE BY SPEC
		info.list = {
			{
				keepShownOnClick = true,
				arg1 = value,
				text = DEFAULT,
				checked = function(btn)
					return self.charDB.profileBySpecialization[btn.arg1] == nil
				end,
				func = function(_, arg1)
					self.charDB.profileBySpecialization[arg1] = nil
					self.mounts:setDB()
					self:ddRefresh(level)
				end,
			}
		}
		for _, profileName in ipairs(self.profileNames) do
			tinsert(info.list, {
				keepShownOnClick = true,
				arg1 = value,
				text = profileName,
				checked = function(btn)
					return self.charDB.profileBySpecialization[btn.arg1] == btn.text
				end,
				func = function(btn, arg1)
					self.charDB.profileBySpecialization[arg1] = btn.text
					self.mounts:setDB()
					self:ddRefresh(level)
				end,
			})
		end
		self:ddAddButton(info, level)

	else -- MENU
		info.notCheckable = true
		info.isTitle = true

		info.text = L["Profiles"]
		self:ddAddButton(info, level)

		self:ddAddSeparator(level)

		info.notCheckable = nil
		info.isTitle = nil

		info.list = {
			{
				text = DEFAULT,
				checked = function() return self.charDB.currentProfileName == nil end,
				func = function() self:setProfile() end,
			},
		}
		for _, profileName in ipairs(self.profileNames) do
			tinsert(info.list, {
				text = profileName,
				checked = function(btn) return self.charDB.currentProfileName == btn.text end,
				func = function(btn) self:setProfile(btn.text) end,
				remove = function(btn) self:deleteProfile(btn.text) end,
			})
		end
		self:ddAddButton(info, level)
		info.list = nil

		self:ddAddSeparator(level)

		info.keepShownOnClick = true
		info.notCheckable = true
		info.hasArrow = true

		info.text = L["Profile settings"]
		info.value = "settings"
		self:ddAddButton(info, level)

		info.text = L["New profile"]
		info.value = "new"
		self:ddAddButton(info, level)

		self:ddAddSeparator(level)

		info.notCheckable = nil
		info.isNotRadio = true
		info.text = L["By Specialization"]
		info.value = "specialization"
		info.checked = function() return self.charDB.profileBySpecialization.enable end
		info.func = function(_,_,_, checked)
			self.charDB.profileBySpecialization.enable = checked
			self.mounts:setDB()
		end
		self:ddAddButton(info, level)
	end
end


function MJProfilesMixin:onClick()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	wipe(self.profileNames)
	for k in pairs(self.profiles) do tinsert(self.profileNames, k) end
	sort(self.profileNames, function(a, b) return a < b end)
	self:dropDownToggle(1, nil, self, 111, 15)
end