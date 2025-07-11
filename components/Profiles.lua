local addon, ns = ...
local L, util = ns.L, ns.util
local strcmputf8i = strcmputf8i


ns.journal:on("MODULES_INIT", function(journal)
	local profiles = ns.mounts.profiles
	local charDB = ns.mounts.charDB
	local profileNames = {}
	local lsfdd = LibStub("LibSFDropDown-1.5")
	local dd = lsfdd:CreateStretchButtonOriginal(journal.bgFrame, 130, 22)
	dd:SetPoint("LEFT", journal.summonButton, "RIGHT", 4, -.5)
	util.setEventsMixin(dd)
	journal.bgFrame.profilesMenu = dd

	-- POPUP
	StaticPopupDialogs[util.addonName.."NEW_PROFILE"] = {
		text = addon..": "..L["New profile"],
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
		text = addon..": "..L["A profile with the same name exists."],
		button1 = OKAY,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = profileExistsAccept,
		OnCancel = profileExistsAccept,
	}
	StaticPopupDialogs[util.addonName.."DELETE_PROFILE"] = {
		text = addon..": "..L["Are you sure you want to delete profile %s?"],
		button1 = DELETE,
		button2 = CANCEL,
		hideOnEscape = 1,
		whileDead = 1,
		OnAccept = function(_, cb) cb() end,
	}
	StaticPopupDialogs[util.addonName.."YOU_WANT"] = {
		text = addon..": "..L["Are you sure you want %s?"],
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

	function dd:setAllFiltredMounts(actionText, enabled)
		StaticPopup_Show(util.addonName.."YOU_WANT", NORMAL_FONT_COLOR:WrapTextInColorCode(actionText), nil, function()
			if not journal.list then
				journal:createMountList(journal.listMapID)
			end

			for i, data in ipairs(journal.dataProvider:GetCollection()) do
				local _, spellID, _,_,_,_,_,_,_,_, isCollected = journal:getMountInfo(data.mountID)
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

			journal:getRemoveMountList(journal.listMapID)
			self:event("UPDATE_PROFILE")
		end)
	end

	function dd:selectAllMounts(actionText, onlyFavorites)
		StaticPopup_Show(util.addonName.."YOU_WANT", NORMAL_FONT_COLOR:WrapTextInColorCode(actionText), nil, function()
			if not journal.list then
				journal:createMountList(journal.listMapID)
			end

			for _, mountID in ipairs(journal.mountIDs) do
				local _, spellID, _,_,_,_, isFavorite, _,_,_, isCollected = journal:getMountInfo(mountID)
				if isCollected and (not onlyFavorites or isFavorite) then
					ns.mounts:addMountToList(journal.list, spellID)
				end
			end

			journal:getRemoveMountList(journal.listMapID)
			self:event("UPDATE_PROFILE")
		end)
	end

	function dd:unselectAllMounts()
		StaticPopup_Show(util.addonName.."YOU_WANT", NORMAL_FONT_COLOR:WrapTextInColorCode(L["Unselect all mounts in selected zone"]), nil, function()
			if journal.list then
				wipe(journal.list.fly)
				wipe(journal.list.ground)
				wipe(journal.list.swimming)
				journal:getRemoveMountList(journal.listMapID)
				self:event("UPDATE_PROFILE")
			end
		end)
	end

	function dd:export()
		local profile = charDB.currentProfileName and profiles[charDB.currentProfileName] or ns.mounts.defProfile
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
			save = function(data, name)return self:saveImportedProfile(data.data, name) end,
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
				tooltip:AddLine(L["Shift-click to create a chat link"])
			end

			info.list = {
				{
					text = DEFAULT,
					checked = function() return charDB.currentProfileName == nil end,
					func = function()
						if IsShiftKeyDown() then
							util.insertChatLink("Profile", "")
						else
							self:setProfile()
						end
					end,
					OnTooltipShow = OnTooltipShow,
				},
			}
			for _, profileName in ipairs(profileNames) do
				tinsert(info.list, {
					text = profileName,
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

			info.keepShownOnClick = nil
			info.hasArrow = nil

			info.text = L["Export"]
			info.func = function() self:export() end
			self:ddAddButton(info, level)

			info.text = L["Import"]
			info.func = function() self:import() end
			self:ddAddButton(info, level)

		elseif value == "settings" then -- PROFILE SETTINGS
			info.notCheckable = true
			info.isTitle = true
			info.text = charDB.currentProfileName or DEFAULT
			self:ddAddButton(info, level)

			self:ddAddSeparator(level)

			info.notCheckable = nil
			info.isTitle = nil
			info.isNotRadio = true
			info.keepShownOnClick = true

			if charDB.currentProfileName ~= nil then
				info.text = L["Pet binding from default profile"]
				info.checked = function() return journal.db.petListFromProfile end
				info.func = function(_,_,_, checked)
					journal.db.petListFromProfile = checked and true or nil
					self:event("UPDATE_PROFILE")
				end
				self:ddAddButton(info, level)

				info.text = L["Zones settings from default profile"]
				info.checked = function() return journal.db.zoneMountsFromProfile end
				info.func = function(_,_,_, checked)
					journal.db.zoneMountsFromProfile = checked and true or nil
					self:event("UPDATE_PROFILE")
				end
				self:ddAddButton(info, level)
			end

			info.text = L["Auto add new mounts to selected"]
			info.checked = function() return journal.db.autoAddNewMount end
			info.func = function(_,_,_, checked)
				journal.db.autoAddNewMount = checked and true or nil
			end
			self:ddAddButton(info, level)

			self:ddAddSpace(level)

			info.notCheckable = true
			info.keepShownOnClick = nil

			info.text = L["Select all filtered mounts by type in the selected zone"]
			info.func = function(btn) self:setAllFiltredMounts(btn.text, true) end
			self:ddAddButton(info, level)

			info.text = L["Unselect all filtered mounts in the selected zone"]
			info.func = function(btn) self:setAllFiltredMounts(btn.text, false) end
			self:ddAddButton(info, level)

			self:ddAddSpace(level)

			info.text = L["Select all favorite mounts by type in the selected zone"]
			info.func = function(btn) self:selectAllMounts(btn.text, true) end
			self:ddAddButton(info, level)

			info.text = L["Select all mounts by type in selected zone"]
			info.func = function(btn) self:selectAllMounts(btn.text) end
			self:ddAddButton(info, level)

			info.text = L["Unselect all mounts in selected zone"]
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
		end
	end)

	dd:SetScript("OnClick", function(self)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		wipe(profileNames)
		for k in pairs(profiles) do tinsert(profileNames, k) end
		sort(profileNames, function(a, b) return strcmputf8i(a, b) < 0 end)
		self:ddToggle(1, nil, self, 117, 13)
	end)
end)