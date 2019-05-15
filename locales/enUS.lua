local _, L = ...

L["author"] = "Author"
L["%s Configuration"] = "%s Configuration"
L["ConfigPanelTitle"] = "Global settings"
L["Class settings"] = "Class settings"
L["Modifier"] = "Modifier"
L["ModifierDescription"] = "If the modifier hold and you are in water then will be summoned non-waterfowl mount. If you are on land and you can fly then will be summoned ground mount."
L["Handle a jump in water"] = "Handle a jump in water"
L["WaterJumpDescription"] = "After you jump in water will be summoned non underwater mount."
L["Water Walking in dungeons"] = "Water Walking in Dungeons"
L["Water Walking in expeditions"] = "Water Walking in Expeditions"
L["Water Walking"] = "Water Walking"
L["WaterWalkingDescription"] = "Instead of the selected land mounts, the \"Water Strider\" is used, if available."
L["Water Walking Always"] = "Water Walker Always"
L["UseHerbMounts"] = "Use Mount for Herbalism"
L["UseHerbMountsDescription"] = "If Herbalism is learned, then the \"Sky Golem\" is used, if available."
L["UseMagicBroom"] = "Use %s"
L["UseMagicBroomTitle"] = "Use Magic Broom"
L["UseMagicBroomDescription"] = "When \"Hallow's End\" event is active, if you have a \"Magic Broom\", it is used."
L["CreateMacro"] = "Create Macro"
L["CreateMacroTooltip"] = "The created macro is used to summon the selected mounts."
L["or key bind"] = "or key bind"
L["Collected:"] = "Collected:"
L["Settings"] = "Settings"
L["Character Specific Mount List"] = "Character Specific Mount List"
L["Shown:"] = "Shown:"
L["types"] = "Types"
L["selected"] = "Selected"
L["sources"] = "Sources"
L["MOUNT_TYPE_1"] = "Flying"
L["MOUNT_TYPE_2"] = "Ground"
L["MOUNT_TYPE_3"] = "Underwater"
L["factions"] = "Factions"
L["MOUNT_FACTION_1"] = "Horde"
L["MOUNT_FACTION_2"] = "Alliance"
L["MOUNT_FACTION_3"] = "Both"
L["expansions"] = "Expansions"
L["Map / Model"] = "Map / Model"
L["Dungeons and Raids"] = "Dungeons and Raids"
L["Current Location"] = "Current Location"
L["Ground Mounts Only"] = "Ground Mounts Only"
L["Water Walk Mounts Only"] = "Water Walk Mounts Only"
L["CHARACTER_CLASS_DESCRIPTION"] = "(character settings override class settings)"
L["HELP_MACRO_MOVE_FALL"] = "This macro will be run, if you are indoors or are moving, and you do not have a magic broom or it is turned off."
L["HELP_MACRO_COMBAT"] = "This macro will be run, if you are in combat."
L["DEATHKNIGHT_USEPATHOFFROST"] = "Use the %s when summoning ground mount"
L["DEATHKNIGHT_USEONLYINWATERWALKLOCATION"] = "Use only in water walk zones"
L["SHAMAN_USEWATERWALKING"] = "Use the %s when summoning ground mount"
L["SHAMAN_USEONLYINWATERWALKLOCATION"] = "Use only in water walk zones"
L["DRUID_USEMACROALWAYS"] = "Use this macros instead of mounts"

setmetatable(L, {__index = function(self, key)
	self[key] = key or ""
	return key
end})