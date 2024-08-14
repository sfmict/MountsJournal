local addon, ns = ...
local mounts = ns.mounts


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

	-- IF < 11.0.0 CHAR
	if compareVersion("11.0.0", self.globalDB.lastAddonVersion) then
		self.charDB.macrosConfig.useIfNotDragonridable = nil
	end
end


function mounts:setOldChanges()
	self.setOldChanges = nil

	local currentVersion = C_AddOns.GetAddOnMetadata(addon, "Version")
	--@do-not-package@
	if currentVersion == "@project-version@" then currentVersion = "11.0.7" end
	--@end-do-not-package@

	if self.charDB.lastAddonVersion and compareVersion(currentVersion, self.charDB.lastAddonVersion) then
		updateChar(self)
		self.charDB.lastAddonVersion = currentVersion
	end

	if self.globalDB.lastAddonVersion and compareVersion(currentVersion, self.globalDB.lastAddonVersion) then
		updateGlobal(self)
		self.globalDB.lastAddonVersion = currentVersion
	end
end