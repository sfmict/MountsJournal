local addon, ns = ...
local L, util = ns.L, ns.util
local strcmputf8i = strcmputf8i


ns.journal:on("MODULES_INIT", function(journal)
	local defProfile = ns.mounts.defProfile
	local profiles = ns.mounts.profiles
	local charDB = ns.mounts.charDB
	local lsfdd = LibStub("LibSFDropDown-1.5")
	local dd = lsfdd:CreateStretchButtonOriginal(journal.bgFrame, 130, 22)
	dd:SetPoint("LEFT", journal.summonButton, "RIGHT", 4, -.5)
	journal.bgFrame.profilesMenu = util.setEventsMixin(dd)

	-- POPUP
	StaticPopupDialogs[util.addonName.."NEW_PROFILE"] = {
		text = ns.addon..": "..L["New profile"],
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = 1,
		maxLetters = 48,
		editBoxWidth = 350,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = function(popup, data)
			local editBox = popup.editBox or popup.EditBox
			local text = editBox:GetText()
			if text and text ~= "" then
				if profiles[text] ~= nil then
					popup:Hide()
					dd.lastProfileName = text
					StaticPopup_Show(util.addonName.."PROFILE_EXISTS", nil, nil, data)
					return
				end
				profiles[text] = data and util:copyTable(data) or {}
				ns.mounts:checkProfile(profiles[text])
				dd:setProfile(text)
			end
		end,
		EditBoxOnEnterPressed = function(self)
			StaticPopup_OnClick(self:GetParent(), 1)
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		OnShow = function(self)
			local editBox = self.editBox or self.EditBox
			editBox:SetText(UnitName("player").." - "..GetRealmName())
			editBox:HighlightText()
		end,
	}
	local function profileExistsAccept(popup, data)
		if not popup then return end
		popup:Hide()
		if not dd.lastProfileName then return end
		local dialog = StaticPopup_Show(util.addonName.."NEW_PROFILE", nil, nil, data)
		if dialog and dd.lastProfileName then
			local editBox = dialog.editBox or dialog.EditBox
			editBox:SetText(dd.lastProfileName)
			editBox:HighlightText()
			dd.lastProfileName = nil
		end
	end
	StaticPopupDialogs[util.addonName.."PROFILE_EXISTS"] = {
		text = ns.addon..": "..L["A profile with the same name exists."],
		button1 = OKAY,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = profileExistsAccept,
		OnCancel = profileExistsAccept,
	}
	StaticPopupDialogs[util.addonName.."DELETE_PROFILE"] = {
		text = ns.addon..": "..L["Are you sure you want to delete profile %s?"],
		button1 = DELETE,
		button2 = CANCEL,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = function(_, cb) cb() end,
	}
	StaticPopupDialogs[util.addonName.."YOU_WANT"] = {
		text = ns.addon..": "..L["Are you sure you want %s?"],
		button1 = OKAY,
		button2 = CANCEL,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = function(_, cb) cb() end,
	}

	-- METHODS
	function dd:createProfile(copy)
		local currentProfile = copy and journal.db or nil
		StaticPopup_Show(util.addonName.."NEW_PROFILE", nil, nil, currentProfile)
	end

	function dd:deleteProfile(profileName)
		StaticPopup_Show(util.addonName.."DELETE_PROFILE", NORMAL_FONT_COLOR:WrapTextInColorCode(profileName), nil, function()
			profiles[profileName] = nil
			if charDB.currentProfileName == profileName then
				self:setProfile()
			end
		end)
	end

	function dd:setProfile(profileName)
		if profileName == nil or profiles[profileName] then
			charDB.currentProfileName = profileName
			self:SetText(profileName or DEFAULT)
			self:event("UPDATE_PROFILE", true)
		end
	end

	function dd:setAllMountsFor(actionText, mountList, enabled, onlyFavorites)
		StaticPopup_Show(util.addonName.."YOU_WANT", NORMAL_FONT_COLOR:WrapTextInColorCode(actionText), nil, function()
			if not journal.list then
				journal:createMountList(journal.listMapID)
			end

			for i, data in ipairs(mountList) do
				local _, spellID, _,_,_,_, isFavorite, _,_,_, isCollected = util.getMountInfo(type(data) == "table" and data.mountID or data)
				if not onlyFavorites or isFavorite then
					if enabled then
						if isCollected then
							ns.mounts:addMountToList(journal.list, spellID)
						end
					else
						journal.list.fly[spellID] = nil
						journal.list.ground[spellID] = nil
						journal.list.swimming[spellID] = nil
					end
				end
			end

			journal:getRemoveMountList(journal.listMapID)
			self:event("UPDATE_PROFILE")
		end)
	end

	function dd:setAllFiltredMounts(actionText, enabled)
		self:setAllMountsFor(actionText, journal.dataProvider:GetCollection(), enabled)
	end

	function dd:setAllMounts(actionText, enabled, onlyFavorites)
		self:setAllMountsFor(actionText, journal.mountIDs, enabled, onlyFavorites)
	end

	function dd:export(profile)
		ns.dataDialog:open({
			type = "export",
			data = {type = "profile", data = profile}
		})
	end

	function dd:saveImportedProfile(profile, name)
		if profiles[name] ~= nil then
			self.lastProfileName = nil
			StaticPopup_Show(util.addonName.."PROFILE_EXISTS")
			return
		end
		util.openJournalTab(3)
		profiles[name] = profile
		ns.mounts:checkProfile(profiles[name])
		self:setProfile(name)
		return true
	end

	function dd:import()
		ns.dataDialog:open({
			type = "import",
			defName = UnitName("player").." - "..GetRealmName(),
			valid = function(data) return data.type == "profile" and type(data.data) == "table" end,
			save = function(data, name) return self:saveImportedProfile(data.data, name) end,
		})
	end

	function dd:dataImport(data, pName, characterName)
		ns.dataDialog:open({
			type = "dataImport",
			defName = pName == "" and UnitName("player").." - "..GetRealmName() or pName,
			typeLang = L["Profile"],
			id = pName == "" and DEFAULT or pName,
			fromName = characterName,
			data = data,
			save = function(data, name) return self:saveImportedProfile(data, name) end,
		})
	end

	-- DROPDOWN
	dd:SetText(charDB.currentProfileName or DEFAULT)
	dd:ddSetDisplayMode(addon)
	dd:ddSetInitFunc(function(self, level, value)
		local info = {}

		if level == 1 then -- MENU
			info.notCheckable = true
			info.isTitle = true
			info.text = L["Profiles"]
			self:ddAddButton(info, level)

			self:ddAddSeparator(level)

			info.notCheckable = nil
			info.isTitle = nil

			local function OnTooltipShow(btn, tooltip)
				tooltip:SetOwner(btn, "ANCHOR_RIGHT", 0, 12)
				tooltip:AddLine(L["Shift-click to create a chat link"])
			end

			local list = {}
			for name, profile in next, profiles do
				tinsert(list, {
					hasArrow = true,
					text = name,
					value = {name, profile},
					checked = function(btn) return charDB.currentProfileName == btn.text end,
					func = function(btn)
						if IsShiftKeyDown() then
							util.insertChatLink("Profile", btn.text)
						else
							self:setProfile(btn.text)
						end
					end,
					remove = function(btn) self:deleteProfile(btn.text) end,
					OnTooltipShow = OnTooltipShow,
				})
			end
			sort(list, function(a, b) return strcmputf8i(a.text, b.text) < 0 end)
			tinsert(list, 1, {
				hasArrow = true,
				text = DEFAULT,
				value = defProfile,
				checked = function() return charDB.currentProfileName == nil end,
				func = function()
					if IsShiftKeyDown() then
						util.insertChatLink("Profile", "")
					else
						self:setProfile()
					end
				end,
				OnTooltipShow = OnTooltipShow,
			})

			info.list = list
			self:ddAddButton(info, level)
			info.list = nil

			self:ddAddSeparator(level)

			info.keepShownOnClick = true
			info.notCheckable = true
			info.hasArrow = true

			info.text = L["New profile"]
			info.value = "new"
			self:ddAddButton(info, level)

			info.keepShownOnClick = nil
			info.hasArrow = nil

			info.text = L["Import"]
			info.func = function() self:import() end
			self:ddAddButton(info, level)

		elseif type(value) == "table" then -- PROFILE SETTINGS
			local name = value[1] or DEFAULT
			local profile = value[2] or value

			info.notCheckable = true
			info.isTitle = true
			info.text = L["Profile settings"].." - "..name
			self:ddAddButton(info, level)

			info.notCheckable = nil
			info.isTitle = nil
			info.isNotRadio = true
			info.keepShownOnClick = true

			if name ~= DEFAULT then
				info.text = L["Pet binding from default profile"]
				info.checked = profile.petListFromProfile
				info.func = function(_,_,_, checked)
					profile.petListFromProfile = checked or nil
					self:event("UPDATE_PROFILE")
				end
				self:ddAddButton(info, level)

				info.text = L["Zones settings from default profile"]
				info.checked = profile.zoneMountsFromProfile
				info.func = function(_,_,_, checked)
					profile.zoneMountsFromProfile = checked or nil
					self:event("UPDATE_PROFILE")
				end
				self:ddAddButton(info, level)
			end

			info.text = L["Auto add new mounts to selected"]
			info.checked = profile.autoAddNewMount
			info.func = function(_,_,_, checked)
				profile.autoAddNewMount = checked or nil
			end
			self:ddAddButton(info, level)

			self:ddAddSeparator(level)

			info.keepShownOnClick = nil
			info.isNotRadio = nil
			info.notCheckable = true
			info.text = L["Export"]
			info.func = function() self:export(profile) end
			self:ddAddButton(info, level)

		elseif value == "new" then -- NEW PROFLE
			info.notCheckable = true

			info.text = L["Create"]
			info.func = function() self:createProfile() end
			self:ddAddButton(info, level)

			info.text = L["Copy current"]
			info.func = function() self:createProfile(true) end
			self:ddAddButton(info, level)
		end
	end)
end)
