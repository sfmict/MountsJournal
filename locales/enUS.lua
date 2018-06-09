local _, L = ...

L["%s Configuration"] = "%s Configuration"
L["ConfigPanelTitle %s."] = "This panel can be used to configure %s."
L["Modifier"] = "Modifier"
L["ModifierDescription"] = "If the modifier pressed and you are in water then will be called non-waterfowl mount. If you are on land and you can fly then will be called ground mount."
L["Water Walking in Eye of Azchara"] = "Water Walking in \"Eye of Azchara\""
L["Water Walking"] = "Water Walking"
L["WaterWalkingDescription"] = "Instead of the selected land mounts, the \"Water Strider\" is used, if available."
L["Water Walking Always"] = "Water Walker Always"
L["CreateMacroBtn"] = "Create Macro: \"/mount\""
L["CreateMacro"] = "Create Macro"
L["CreateMacroTooltip"] = "The created macro is used to call the selected mounts."
L["Settings"] = "Settings"
L["Character Specific Mount List"] = "Character Specific Mount List"
L["Shown:"] = "Shown:"
L["types"] = "Types"
L["selected"] = "Selected"
L["sources"] = "Sources"
L["MOUNT_TYPE_1"] = "Flying"
L["MOUNT_TYPE_2"] = "Ground"
L["MOUNT_TYPE_3"] = "Underwater"

setmetatable(L, {__index = function(self, key)
	self[key] = key or ""
	return key
end})