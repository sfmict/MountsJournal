local _, ns = ...
local L = setmetatable({}, {__index = function(self, key)
	self[key] = "[PH]"..key
	return self[key]
end})
ns.L = L

L.auctioneer = MINIMAP_TRACKING_AUCTIONEER
L.spells = SPELLS
L.items = ITEMS
