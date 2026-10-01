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
end


local function updateChar(self)
end


function ns.mounts:setOldChanges()
	self.setOldChanges = nil

	local currentVersion = C_AddOns.GetAddOnMetadata(addon, "Version")
	--@do-not-package@
	if currentVersion == "@project-version@" then currentVersion = "fr1.60.0" end
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
end