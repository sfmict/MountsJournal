local addon, ns = ...


local function compareVersion(v1, v2)
	v1 = v1:gsub("%D*([%d%.]+).*", "%1")
	v2 = (v2 or ""):gsub("%D*([%d%.]+).*", "%1")
	v1 = {("."):split(v1)}
	v2 = {("."):split(v2)}
	for i = 1, min(#v1, #v2) do
		v1[i] = tonumber(v1[i]) or 0
		v2[i] = tonumber(v2[i]) or 0
		if v1[i] > v2[i] then return true end
		if v1[i] < v2[i] then return false end
	end
	return #v1 > #v2
end


local function updateGlobal(self)
	--IF < 8.3.2 GLOBAL
	if compareVersion("8.3.2", self.globalDB.lastAddonVersion) then
		self.config.waterWalkAll = nil
		self.config.waterWalkList = nil
		self.config.waterWalkInstance = nil
		self.config.waterWalkExpedition = nil
		self.config.waterWalkExpeditionList = nil

		local function setMounts(tbl)
			if tbl and #tbl > 0 then
				local newTbl = {}
				for i = 1, #tbl do
					newTbl[tbl[i]] = true
				end
				return newTbl
			end
			return tbl
		end

		self.globalDB.fly = setMounts(self.globalDB.fly)
		self.globalDB.ground = setMounts(self.globalDB.ground)
		self.globalDB.swimming = setMounts(self.globalDB.swimming)
		if self.globalDB.zoneMounts then
			for _, list in next, self.globalDB.zoneMounts do
				list.fly = setMounts(list.fly)
				list.ground = setMounts(list.ground)
				list.swimming = setMounts(list.swimming)
			end
		end

		for _, profile in next, self.globalDB.mountsProfiles do
			profile.fly = setMounts(profile.fly or {})
			profile.ground = setMounts(profile.ground or {})
			profile.swimming = setMounts(profile.swimming or {})
			profile.zoneMounts = profile.zoneMounts or {}
			profile.petForMount = profile.petForMount or {}

			for _, list in next, profile.zoneMounts do
				list.fly = setMounts(list.fly)
				list.ground = setMounts(list.ground)
				list.swimming = setMounts(list.swimming)
			end
		end
	end

	--IF < 9.0.8 GLOBAL
	if compareVersion("9.0.8", self.globalDB.lastAddonVersion) then
		local function updateTable(to, from)
			for k, v in next, from do
				if type(v) ~= "table" then
					to[k] = v
				elseif type(to[k]) ~= "table" then
					to[k] = util:copyTable(v)
				else
					updateTable(to[k], v)
				end
			end
		end

		if type(self.globalDB.fly) == "table" then
			updateTable(self.defProfile.fly, self.globalDB.fly)
			self.globalDB.fly = nil
		end
		if type(self.globalDB.ground) == "table" then
			updateTable(self.defProfile.ground, self.globalDB.ground)
			self.globalDB.ground = nil
		end
		if type(self.globalDB.swimming) == "table" then
			updateTable(self.defProfile.swimming, self.globalDB.swimming)
			self.globalDB.swimming = nil
		end
		if type(self.globalDB.zoneMounts) == "table" then
			updateTable(self.defProfile.zoneMounts, self.globalDB.zoneMounts)
			self.globalDB.zoneMounts = nil
		end
		if type(self.globalDB.petForMount) == "table" then
			updateTable(self.defProfile.petForMount, self.globalDB.petForMount)
			self.globalDB.petForMount = nil
		end
	end

	-- IF < 10.1.18 GLOBAL
	if compareVersion("10.1.18", self.globalDB.lastAddonVersion) then
		local function listToDragonriding(dragonriding, list)
			for mountID in next, list do
				local _,_,_,_,_,_,_,_,_,_,_,_, isForDragonriding = C_MountJournal.GetMountInfoByID(mountID)
				if isForDragonriding then
					list[mountID] = nil
					dragonriding[mountID] = true
				end
			end
		end

		local function allToDragonriding(profile)
			profile.dragonriding = profile.dragonriding or {}
			listToDragonriding(profile.dragonriding, profile.fly)
			listToDragonriding(profile.dragonriding, profile.ground)
			listToDragonriding(profile.dragonriding, profile.swimming)

			for mapID, data in next, profile.zoneMounts do
				data.dragonriding = data.dragonriding or {}
				listToDragonriding(data.dragonriding, data.fly)
				listToDragonriding(data.dragonriding, data.ground)
				listToDragonriding(data.dragonriding, data.swimming)
			end
		end

		allToDragonriding(self.defProfile)
		for name, data in next, self.profiles do
			allToDragonriding(data)
		end
	end

	-- IF < 10.2.15 GLOBAL
	if compareVersion("10.2.15", self.globalDB.lastAddonVersion) then
		for i = 1, GetNumClasses() do
			local _, className = GetClassInfo(i)
			self.config.macrosConfig[className].useRunningWild = nil
			self.config.macrosConfig[className].runningWildsummoningChance = nil
			self.config.macrosConfig[className].useRunningWild = nil
			self.config.macrosConfig[className].soarSummoningChance = nil
		end

		local function mountToSpell(list)
			local newList = {}
			for mountID, v in next, list do
				local _, spellID = C_MountJournal.GetMountInfoByID(mountID)
				if spellID and spellID > 0 then
					newList[spellID] = v
				end
			end
			return newList
		end

		local function profileToSpell(profile)
			profile.mountsWeight = mountToSpell(profile.mountsWeight)
			profile.dragonriding = mountToSpell(profile.dragonriding)
			profile.fly = mountToSpell(profile.fly)
			profile.ground = mountToSpell(profile.ground)
			profile.swimming = mountToSpell(profile.swimming)

			local zoneMounts = profile.zoneMounts
			for mapID, data in next, zoneMounts do
				data.dragonriding = mountToSpell(data.dragonriding)
				data.fly = mountToSpell(data.fly)
				data.ground = mountToSpell(data.ground)
				data.swimming = mountToSpell(data.swimming)
			end
		end

		if self.config.repairSelectedMount then
			local _, spellID = C_MountJournal.GetMountInfoByID(self.config.repairSelectedMount)
			self.config.repairSelectedMount = spellID
		end
		if self.globalDB.hiddenMounts then
			self.globalDB.hiddenMounts = mountToSpell(self.globalDB.hiddenMounts)
		end
		self.globalDB.mountTags = mountToSpell(self.globalDB.mountTags)
		profileToSpell(self.defProfile)
		for name, data in next, self.profiles do
			profileToSpell(data)
		end
	end

	-- IF < 10.2.41 GLOBAL
	if compareVersion("10.2.41", self.globalDB.lastAddonVersion) then
		if self.filters.family then wipe(self.filters.family) end
		if self.defFilters.family then wipe(self.defFilters.family) end
	end

	-- IF < 11.0.0 GLOBAL
	if compareVersion("11.0.0", self.globalDB.lastAddonVersion) then
		if self.filters.types then self.filters.types[4] = nil end
		if self.filters.selected then self.filters.selected[5] = nil end
		if self.filters.sorting then self.filters.sorting.dragonridingFirst = nil end
		if self.defFilters.types then self.defFilters.types[4] = nil end
		if self.defFilters.selected then self.defFilters.selected[5] = nil end

		local function dragonridingToFly(list)
			if list.dragonriding then
				for k, v in next, list.dragonriding do
					list.fly[k] = v
				end
				list.dragonriding = nil
			end
		end

		local function removeDragonriding(profile)
			dragonridingToFly(profile)
			for mapID, mapSettings in next, profile.zoneMounts do
				mapSettings.flags.regularFlyOnly = nil
				dragonridingToFly(mapSettings)
			end
		end

		removeDragonriding(self.defProfile)
		for name, profile in next, self.profiles do
			removeDragonriding(profile)
		end
	end

	-- IF < 11.0.7 GLOBAL
	if compareVersion("11.0.7", self.globalDB.lastAddonVersion) then
		self.filters.multipleModels = nil
		self.defFilters.multipleModels = nil
	end

	-- IF < 11.0.19 GLOBAL
	if compareVersion("11.0.19", self.globalDB.lastAddonVersion) then
		if self.globalDB.ruleConfig then
			for i, summon in ipairs(self.globalDB.ruleConfig) do
				for j, rule in ipairs(summon) do
					if rule.action[1] == "rmount" and not rule.action[2] then rule.action[2] = 0 end
				end
			end
		end
	end

	-- IF < 11.0.25 GLOBAL
	if compareVersion("11.0.25", self.globalDB.lastAddonVersion) then
		if self.globalDB.ruleConfig then
			for i, rules in ipairs(self.globalDB.ruleConfig) do
				self.globalDB.ruleSets[1][i] = rules
			end
			self.globalDB.ruleConfig = nil
		end
	end

	-- IF < 11.1.16 GLOBAL
	if compareVersion("11.1.16", self.globalDB.lastAddonVersion) then
		for i, v in ipairs({"filters", "defFilters"}) do
			if self[v].family then
				self[v].family[1904] = nil
				self[v].family[2506] = nil
			end
		end
	end

	-- IF < 11.1.17 GLOBAL
	if compareVersion("11.1.17", self.globalDB.lastAddonVersion) then
		if type(self.config.gridToggle) == "boolean" then
			self.config.gridToggle = self.config.gridToggle and 2 or 1
		end
	end
end


local function updateChar(self)
	-- IF < 8.3.2 CHAR
	if compareVersion("8.3.2", self.charDB.lastAddonVersion) then
		local function setMounts(tbl)
			if #tbl > 0 then
				local newTbl = {}
				for i = 1, #tbl do
					newTbl[tbl[i]] = true
				end
				return newTbl
			end
			return tbl
		end

		if type(self.charDB.fly) == "table" and #self.charDB.fly > 0
		or type(self.charDB.ground) == "table" and #self.charDB.ground > 0
		or type(self.charDB.swimming) == "table" and #self.charDB.swimming > 0
		or type(self.charDB.zoneMounts) == "table" and next(self.charDB.zoneMounts) ~= nil then
			local name = UnitName("player").." - "..GetRealmName()
			if not self.profiles[name] then
				self.profiles[name] = {
					fly = setMounts(self.charDB.fly or {}),
					ground = setMounts(self.charDB.ground or {}),
					swimming = setMounts(self.charDB.swimming or {}),
					zoneMounts = self.charDB.zoneMounts or {},
					petForMount = {},
				}
				if self.charDB.enable then
					self.charDB.currentProfileName = name
				end
				for _, list in next, self.profiles[name].zoneMounts do
					list.fly = setMounts(list.fly)
					list.ground = setMounts(list.ground)
					list.swimming = setMounts(list.swimming)
				end
			end
		end

		self.charDB.fly = nil
		self.charDB.ground = nil
		self.charDB.swimming = nil
		self.charDB.zoneMounts = nil
		self.charDB.enable = nil
	end

	-- IF < 10.2.15 CHAR
	if compareVersion("10.2.15", self.charDB.lastAddonVersion) then
		self.charDB.macrosConfig.useRunningWild = nil
		self.charDB.macrosConfig.runningWildsummoningChance = nil
		self.charDB.macrosConfig.useRunningWild = nil
		self.charDB.macrosConfig.soarSummoningChance = nil
	end

	-- IF < 11.0.18 CHAR
	if compareVersion("11.0.18", self.charDB.lastAddonVersion) then
		self.charDB.macrosConfig.itemSlot16 = nil
		self.charDB.macrosConfig.itemSlot17 = nil
		self.charDB.macrosConfig.useIfNotDragonridable = nil

		local rules = self.globalDB.ruleConfig and self.globalDB.ruleConfig[1] or self.globalDB.ruleSets[1][1]

		if self.charDB.profileBySpecialization then
			if self.charDB.profileBySpecialization.enable then
				for i = 1, GetNumSpecializations() do
					local profileName = self.charDB.profileBySpecialization[i] or 1
					local specID = C_SpecializationInfo.GetSpecializationInfo(i)
					local rule = {
						{false, "spec", specID},
						action = {"rmount", profileName},
					}
					tinsert(rules, 1, rule)
				end
			end
			self.charDB.profileBySpecialization = nil
		end

		if self.charDB.holidayProfiles then
			local holidays = {}
			for eventID, data in next, self.charDB.holidayProfiles do
				if data.enabled then
					holidays[#holidays + 1] = {eventID, data.profileName or 1, data.order}
				end
			end
			sort(holidays, function(a, b) return a[3] > b[3] end)
			for i, data in ipairs(holidays) do
				local rule = {
					{false, "holiday", data[1]},
					action = {"rmount", data[2]},
				}
				tinsert(rules, 1, rule)
			end
			self.charDB.holidayProfiles = nil
		end

		if self.charDB.profileBySpecializationPVP then
			if self.charDB.profileBySpecializationPVP.enable then
				for i = 1, GetNumSpecializations() do
					local profileName = self.charDB.profileBySpecializationPVP[i] or 1
					local specID = C_SpecializationInfo.GetSpecializationInfo(i)
					local rule1 = {
						{false, "spec", specID},
						{false, "zt", "arena"},
						action = {"rmount", profileName},
					}
					local rule2 = {
						{false, "spec", specID},
						{false, "zt", "pvp"},
						action = {"rmount", profileName},
					}
					tinsert(rules, 1, rule1)
					tinsert(rules, 1, rule2)
				end
			end
			self.charDB.profileBySpecializationPVP = nil
		end
	end
end


function ns.mounts:setOldChanges()
	self.setOldChanges = nil

	local currentVersion = C_AddOns.GetAddOnMetadata(addon, "Version")
	--@do-not-package@
	if currentVersion == "@project-version@" then currentVersion = "v11.1.17" end
	--@end-do-not-package@

	if not self.charDB.lastAddonVersion then self.charDB.lastAddonVersion = currentVersion end
	if not self.globalDB.lastAddonVersion then self.globalDB.lastAddonVersion = currentVersion end

	if compareVersion(currentVersion, self.charDB.lastAddonVersion) then
		updateChar(self)
		self.charDB.lastAddonVersion = currentVersion
	end
	if compareVersion(currentVersion, self.globalDB.lastAddonVersion) then
		updateGlobal(self)
		self.globalDB.lastAddonVersion = currentVersion
	end

	-- UPDATE PET FOR PROFILE
	local curRegion = GetCurrentRegion()
	local function updatePetProfile(profile)
		if profile.oldPetForMount then
			local petForMount = profile.petForMount[curRegion]
			if not petForMount then
				petForMount = {}
				for k, v in next, profile.oldPetForMount do
					petForMount[k] = v
				end
				profile.petForMount[curRegion] = petForMount
			end
		else
			local k, v = next(profile.petForMount)
			if v ~= nil and type(v) ~= "table" then
				profile.oldPetForMount = profile.petForMount
				local petForMount = {}
				for k, v in next, profile.oldPetForMount do
					petForMount[k] = v
				end
				profile.petForMount = {[curRegion] = petForMount}
			end
		end
	end

	updatePetProfile(self.defProfile)
	for name, profile in next, self.profiles do
		updatePetProfile(profile)
	end
end