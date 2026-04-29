local _, ns = ...
local journal, mounts = ns.journal, ns.mounts
local next = next


function journal:getTFromProfile(profile)
	local mapID = self.navBar.mapID ~= self.navBar.defMapID and self.navBar.mapID or nil
	local zoneMounts, list, currentList = profile.zoneMountsFromProfile and mounts.defProfile.zoneMounts or profile.zoneMounts

	if mapID == nil then
		currentList = profile
		list = currentList
	else
		currentList = zoneMounts[mapID]
		list = currentList

		while list and list.listFromID do
			if list.listFromID == self.navBar.defMapID then
				mapID = nil
				list = profile
			else
				mapID = list.listFromID
				list = zoneMounts[mapID]
			end
		end
	end

	return list, zoneMounts, currentList, mapID
end


function journal:setEditMountsList()
	self.db = mounts.charDB.currentProfileName and mounts.profiles[mounts.charDB.currentProfileName] or mounts.defProfile
	self.list, self.zoneMounts, self.currentList, self.listMapID = self:getTFromProfile(self.db)
	self.petForMount = self.db.petListFromProfile and mounts.defProfile.petForMount or self.db.petForMount
	self.mountsWeight = self.db.mountsWeight
end


function journal:createMountList(mapID, zoneMounts)
	local list = {
		fly = {},
		ground = {},
		swimming = {},
		flags = {},
	}
	(zoneMounts or self.zoneMounts)[mapID] = list
	self:setEditMountsList()
	return list
end


function journal:getRemoveMountList(mapID, zoneMounts)
	if not mapID then return end
	zoneMounts = zoneMounts or self.zoneMounts
	local list = zoneMounts[mapID]

	local flags
	for _, value in next, list.flags do
		if value then
			flags = true
			break
		end
	end

	if not (next(list.fly) or next(list.ground) or next(list.swimming))
	and not flags
	and not list.listFromID then
		zoneMounts[mapID] = nil
		self:setEditMountsList()
	end
end


function journal:setFlag(flag, enable)
	if self.navBar.mapID == self.navBar.defMapID then return end

	if enable and not (self.currentList and self.currentList.flags) then
		self:createMountList(self.navBar.mapID)
	end
	self.currentList.flags[flag] = enable
	if not enable then
		self:getRemoveMountList(self.navBar.mapID)
	end

	-- mounts:setMountsList()
	self.existingLists:refresh()
end
