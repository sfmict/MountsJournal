local _, ns = ...
local L = {}
ns.L = L

L.auctioneer = MINIMAP_TRACKING_AUCTIONEER
L.spells = SPELLS
L.items = ITEMS

L["author"] = "Author"
L["Main"] = "Main"
L["ConfigPanelTitle"] = "Global settings"
L["Class settings"] = "Class settings"
L["Modifier"] = "Modifier"
L["Normal mount summon"] = "Normal mount summon."
L["SecondMountTooltipTitle"] = "If the modifier is hold or “%s 2” is used:"
L["SecondMountTooltipDescription"] = "If you are in water then a non-waterfowl mount will be summoned.\n\nIf you are on land and you can fly then a ground mount will be summoned."
L["Drag to create a summon panel"] = "Drag to create a summon panel"
L["UseBindingTooltip"] = "Use settings for key bindings"
L["Summon panel"] = "Summon panel"
L["Left-button to drag"] = "Left-button to drag"
L["Right-button to open context menu"] = "Right-button to open context menu"
L["Strata of panel"] = "Strata of panel"
L["Fade out (opacity)"] = "Fade out (opacity)"
L["Button size"] = "Button size"
L["Reset size"] = "Reset size"
L["Target Mount"] = "Target Mount"
L["Shows the mount of current target"] = "Shows the mount of current target"
L["Select mount"] = "Select mount"
L["Auto select Mount"] = "Auto select mount"
L["ZoneSettingsTooltip"] = "Zone settings features"
L["ZoneSettingsTooltipDescription"] = "Creating a list of mounts for the zone.\n\nConfiguring zone flags.\n\nSetting up relations to use one list of mounts in different zones."
L["ButtonsSelectedTooltipDescription"] = "Favorites do not affect summons mounts using %s.\n\nYou should select mounts by type to summon under the appropriate conditions."
L["ProfilesTooltipDescription"] = "Profile settings, the profile manages the lists of the selected mounts, the settings of zones and pets."
L["SettingsTooltipDescription"] = "Check settings, create macros or bind keys to use %s."
L["Handle a jump in water"] = "Handle a jump in water"
L["WaterJumpDescription"] = "After you jump in water will be summoned non underwater mount."
L["UseHerbMounts"] = "Use Mount for Herbalism"
L["UseHerbMountsDescription"] = "If Herbalism is learned, a suitable mount is used if available."
L["UseHerbMountsOnZones"] = "Only in Herb Gathering Zones"
L["Herb Gathering"] = "Herb Gathering"
L["HerbGatheringFlagDescription"] = "Used to configure use of Mount to Herbalism."
L["If item durability is less than"] = "If item durability is less than"
L["In flyable zones"] = "In flyable zones"
L["UseRepairMountsDescription"] = "If the durability of at least one item is less than the specified percentage, the selected mount will be summoned."
L["If the number of free slots in bags is less"] = "If the number of free slots in bags is less"
L["Random available mount"] = "Random available mount"
L["UseHallowsEndMounts"] = "Use \"Hallow's End\" mounts"
L["UseHallowsEndMountsDescription"] = "When \"Hallow's End\" event is active, if you have its mounts, they are used."
L["Use %s"] = "Use %s"
L["Use automatically"] = "Use automatically"
L["UseUnderlightAnglerDescription"] = "Use Underlight Angler instead of underwater mounts."
L["A macro named \"%s\" already exists, overwrite it?"] = "A macro named \"%s\" already exists, overwrite it?"
L["CreateMacro"] = "Create Macro"
L["CreateMacroTooltip"] = "The created macro is used to summon the selected mounts."
L["or key bind"] = "or key bind"
L["ERR_MOUNT_NO_SELECTED"] = "You have no valid selected mounts."
L["Collected:"] = "Collected"
L["Shown:"] = "Shown:"
L["hidden for character"] = "Hidden For Character"
L["only hidden"] = "Only hidden"
L["Hidden by player"] = "Hidden by player"
L["Only new"] = "Only new"
L["types"] = "Types"
L["selected"] = "Selected"
L["SELECT_AS_TYPE_1"] = "Select as Flying"
L["SELECT_AS_TYPE_2"] = "Select as Ground"
L["SELECT_AS_TYPE_3"] = "Select as Underwater"
L["MOUNT_TYPE_1"] = "Flying"
L["MOUNT_TYPE_2"] = "Ground"
L["MOUNT_TYPE_3"] = "Underwater"
L["MOUNT_TYPE_4"] = "Not Selected"
L["Specific"] = "Specific"
L["repair"] = "Repair"
L["passenger"] = "Passenger"
L["Ride Along"] = "Ride Along"
L["transform"] = "Transform"
L["Multiple Models"] = "Multiple Models"
L["additional"] = "Additional"
L["rest"] = "Rest"
L["factions"] = "Factions"
L["MOUNT_FACTION_1"] = "Horde"
L["MOUNT_FACTION_2"] = "Alliance"
L["MOUNT_FACTION_3"] = "Both"
L["sources"] = "Sources"
L["PET_1"] = "With Random Favorite Pet"
L["PET_2"] = "With Random Pet"
L["PET_3"] = "With Pet"
L["PET_4"] = "Without Pet"
L["expansions"] = "Expansions"
L["Rarity"] = "Rarity"
L["Receipt date"] = "Receipt date"
L["Travel time"] = "Travel time"
L["Travel distance"] = "Travel distance"
L["Avg. speed"] = "Avg. speed"
L["Chance of summoning"] = "Chance of summoning"
L["Any"] = "Any"
L["> (more than)"] = "> (more than)"
L["< (less than)"] = "< (less than)"
L["= (equal to)"] = "= (equal to)"
L["sorting"] = "Sorting"
L["Then Sort By"] = "Then Sort By"
L["Reverse Sort"] = "Reverse Sort"
L["Collected First"] = "Collected First"
L["Favorites First"] = "Favorites First"
L["Additional First"] = "Additional First"
L["Set current filters as default"] = "Set current filters as default"
L["Restore default filters"] = "Restore default filters"
L["Enable Acceleration around the X-axis"] = "Enable Acceleration around the X-axis"
L["Initial x-axis accseleration"] = "Initial X-axis Accseleration"
L["X-axis accseleration"] = "X-axis Accseleration"
L["Minimum x-axis speed"] = "Minimum X-axis Speed"
L["Enable Acceleration around the Y-axis"] = "Enable Acceleration around the Y-axis"
L["Initial y-axis accseleration"] = "Initial Y-axis Accseleration"
L["Y-axis accseleration"] = "Y-axis Accseleration"
L["Minimum y-axis speed"] = "Minimum Y-axis Speed"
L["Model"] = "Model"
L["Map"] = "Map"
L["Map flags"] = "Map flags"
L["Settings"] = "Settings"
L["Dungeons and Raids"] = "Dungeons and Raids"
L["Current Location"] = "Current Location"
L["Enable Flags"] = "Enable Flags"
L["Ground Mounts Only"] = "Ground Mounts Only"
L["Water Walking"] = "Water Walking"
L["WaterWalkFlagDescription"] = "Used to configure some classes."
L["ListMountsFromZone"] = "Use list of mounts from zone"
L["No relation"] = "No relation"
L["Zones with list"] = "Zones with list"
L["Zones with relation"] = "Zones with relation"
L["Zones with flags"] = "Zones with flags"
L["CHARACTER_CLASS_DESCRIPTION"] = "(character settings override class settings)"
L["HELP_MACRO_MOVE_FALL"] = "This macro will be run, if you are indoors or are moving, and you do not have a magic broom or it is turned off."
L["HELP_MACRO_COMBAT"] = "This macro will be run, if you are in combat."
L["CLASS_USEWHENCHARACTERFALLS"] = "Use the %s when the character falls"
L["CLASS_USEWATERWALKINGSPELL"] = "Use the %s when summoning ground mount"
L["CLASS_USEONLYWATERWALKLOCATION"] = "Use only in water walk zones"
L["DRUID_USELASTDRUIDFORM"] = "Return last form when dismounting"
L["DRUID_USEDRUIDFORMSPECIALIZATION"] = "Return a specialization form"
L["DRUID_USEMACROALWAYS"] = "Use this macro instead of mounts"
L["Collected by %s of players"] = "Collected by %s of players"
L["Summonable Battle Pet"] = "Summonable Battle Pet"
L["Summon Random Battle Pet"] = "Summon Random Battle Pet"
L["No Battle Pet"] = "No Battle Pet"
L["Summon a pet every"] = "Summon a pet every"
L["min"] = "min"
L["Summon only favorites"] = "Summon only favorites"
L["NoPetInRaid"] = "Do not summon battle pet in raid group"
L["NoPetInGroup"] = "Do not summon battle pet in group"
L["Colored mount names by rarity"] = "Colored mount names by rarity"
L["Enable arrow buttons to browse mounts"] = "Enable arrow buttons to browse mounts"
L["Show mount type selection buttons"] = "Show mount type selection buttons"
L["CopyMountTarget"] = "Try to copy target's mount"
L["Open links in %s"] = "Open links in %s"
L["Click opens in"] = "Click opens in"
L["Show wowhead link in mount preview"] = "Show wowhead link in mount preview"
L["Enable statistics collection"] = "Enable statistics collection"
L["STATISTICS_DESCRIPTION"] = "Collects time and distance of mounts (CPU load, only when character is mounted)"
L["Show mount in unit tooltip"] = "Show mount in unit tooltip"
L["Rule Set"] = "Rule Set"
L["Rule Sets"] = "Rule Sets"
L["New rule set"] = "New rule set"
L["A rule set with the same name exists."] = "A rule set with the same name exists."
L["Are you sure you want to delete rule set %s?"] = "Are you sure you want to delete rule set %s?"
L["Set as default"] = "Set as default"
L["Rule"] = "Rule"
L["Rules"] = "Rules"
L["RULES_TITLE"] = "Rules for mounting. The rules are checked in order, and the first rule in which all conditions match executes the action."
L["Add Rule"] = "Add Rule"
L["Import Rule"] = "Import Rule"
L["Reset Rules"] = "Reset Rules"
L["Remove Rule %d"] = "Remove Rule %d"
L["Alternative Mode"] = "Alternative Mode"
L["NOT_CONDITION"] = "Not"
L["Conditions"] = "Conditions"
L["Action"] = "Action"
L["Edit Rule"] = "Edit Rule"
L["ANY_MODIFIER"] = "Any"
L["Macro condition"] = "Macro condition"
L["Mouse button"] = "Mouse button"
L["Zone type"] = "Zone type"
L["Nameless holiday"] = "Nameless holiday"
L["Flight style"] = "Flight style"
L["Steady Flight"] = "Steady Flight"
L["Flyable area"] = "Flyable area"
L["Have item"] = "Have item"
L["Item is ready"] = "Item is ready"
L["Item is equipped"] = "Item is equipped"
L["Spell is known"] = "Spell is known"
L["Spell is ready"] = "Spell is ready"
L["Have zone spell"] = "Have zone spell"
L["Zone Name/Subzone Name"] = "Zone Name/Subzone Name"
L["The player has a buff"] = "The player has a buff"
L["The player has a debuff"] = "The player has a debuff"
L["The player is falling"] = "The player is falling"
L["The player is moving"] = "The player is moving"
L["The player is indoors"] = "The player is indoors"
L["The player is swimming"] = "The player is swimming"
L["The player is mounted"] = "The player is mounted"
L["The player is within an vehicle"] = "The player is within an vehicle"
L["The player is dead"] = "The player is dead"
L["Sex"] = "Sex"
L["Talent loadout"] = "Talent loadout"
L["Get State"] = "Get State"
L["Get a state that can be set in actions using \"Set State\""] = "Get a state that can be set in actions using \"Set State\""
L["Set State"] = "Set State"
L["Set a state that can be read in conditions using \"Get State\""] = "Set a state that can be read in conditions using \"Get State\""
L["Random Mount"] = "Random Mount"
L["Random Mount of Selected Type"] = "Random Mount of Selected Type"
L["Random Mount by Rarity"] = "Random Mount by Rarity"
L["Random Mount of Selected Type by Rarity"] = "Random Mount of Selected Type by Rarity"
L["The lower the rarity, the higher the chance"] = "The lower the rarity, the higher the chance"
L["Selected profile"] = "Selected profile"
L["Mount"] = "Mount"
L["Use Item"] = "Use Item"
L["Use Inventory Item"] = "Use Inventory Item"
L["Cast Spell"] = "Cast Spell"
L["Use macro before mounting"] = "Use macro before mounting"
L["PMACRO_DESCRIPTION"] = "Register a macro to use before mounting"
L["Snippet"] = "Snippet"
L["Code Snippet"] = "Code Snippet"
L["Code Snippets"] = "Code Snippets"
L["Add Snippet"] = "Add Snippet"
L["Import Snippet"] = "Import Snippet"
L["A snippet with the same name exists."] = "A snippet with the same name exists."
L["Are you sure you want to delete snippet %s?"] = "Are you sure you want to delete snippet %s?"
L["Line"] = "Line"
L["Examples"] = "Examples"
L["Tab Size"] = "Tab Size"
L["Do you want to save changes?"] = "Do you want to save changes?"
L["About"] = "About"
L["Help with translation of %s. Thanks."] = "Help with translation of %s. Thanks."
L["Localization Translators:"] = "Localization Translators:"
L["ABBR_YARD"] = "yd"
L["ABBR_MILE"] = "mi"
L["ABBR_METER"] = "m"
L["ABBR_KILOMETER"] = "km"
L["ABBR_HOUR"] = "h"
L["Right-click for more options"] = "Right-click for more options"
L["Shift-click to create a chat link"] = "Shift-click to create a chat link"
L["Requesting data from %s ..."] = "Requesting data from %s ..."
L["Error not receiving data from %s ..."] = "Error not receiving data from %s ..."
L["Malformed link"] = "Malformed link"
L["Transmission error"] = "Transmission error"
L["Receiving data from %s"] = "Receiving data from %s"
L["Received from"] = "Received from"
-- ANIMATIONS
L["Default"] = "Default"
L["Mount special"] = "Mount special"
L["Walk"] = "Walk"
L["Walk backwards"] = "Walk backwards"
L["Run"] = "Run"
L["Swim idle"] = "Swim idle"
L["Swim"] = "Swim"
L["Swim backwards"] = "Swim backwards"
L["Fly stand"] = "Fly stand"
L["Fly"] = "Fly"
L["Fly backwards"] = "Fly backwards"
L["Loop"] = "Loop"
L["Are you sure you want to delete animation %s?"] = "Are you sure you want to delete animation \"%s\"?"
-- PROFILES
L["Profile"] = "Profile"
L["Profiles"] = "Profiles"
L["New profile"] = "New profile"
L["Create"] = "Create"
L["Copy current"] = "Copy current"
L["Export"] = "Export"
L["Import"] = "Import"
L["A profile with the same name exists."] = "A profile with the same name exists."
L["Profile settings"] = "Profile settings"
L["Pet binding from default profile"] = "Pet binding from default profile"
L["Zones settings from default profile"] = "Zones settings from default profile"
L["Auto add new mounts to selected"] = "Auto add new mounts to selected"
L["Select all filtered mounts by type in the selected zone"] = "Select all filtered mounts by type in the selected zone"
L["Unselect all filtered mounts in the selected zone"] = "Unselect all filtered mounts in the selected zone"
L["Select all favorite mounts by type in the selected zone"] = "Select all favorite mounts by type in the selected zone"
L["Select all mounts by type in selected zone"] = "Select all mounts by type in the selected zone"
L["Unselect all mounts in selected zone"] = "Unselect all mounts in the selected zone"
L["Are you sure you want to delete profile %s?"] = "Are you sure you want to delete profile \"%s\"?"
L["Are you sure you want %s?"] = "Are you sure you want to \"%s\"?"
-- TAGS
L["tags"] = "Tags"
L["No tag"] = "No Tag"
L["With all tags"] = "With All Tags"
L["Add tag"] = "Add Tag"
L["Tag already exists."] = "Tag already exists."
L["Are you sure you want to delete tag %s?"] = "Are you sure you want to delete tag \"%s\"?"
-- FAMILY
L["Family"] = "Family"
L["Airplanes"] = "Airplanes"
L["Airships"] = "Airships"
L["Albatross"] = "Albatross"
L["Alpacas"] = "Alpacas"
L["Amphibian"] = "Amphibian"
L["Animite"] = "Animite"
L["Aqir Flyers"] = "Aqir Flyers"
L["Arachnids"] = "Arachnids"
L["Armoredon"] = "Armoredon"
L["Assault Wagons"] = "Assault Wagons"
L["Basilisks"] = "Basilisks"
L["Bats"] = "Bats"
L["Bears"] = "Bears"
L["Bees"] = "Bees"
L["Beetle"] = "Beetle"
L["Bipedal Cat"] = "Bipedal Cat"
L["Birds"] = "Birds"
L["Blood Ticks"] = "Blood Ticks"
L["Boars"] = "Boars"
L["Book"] = "Book"
L["Bovids"] = "Bovids"
L["Broom"] = "Broom"
L["Brutosaurs"] = "Brutosaurs"
L["Butterflies"] = "Butterflies"
L["Camels"] = "Camels"
L["Carnivorans"] = "Carnivorans"
L["Carpets"] = "Carpets"
L["Cats"] = "Cats"
L["Cervid"] = "Cervid"
L["Chargers"] = "Chargers"
L["Chickens"] = "Chickens"
L["Clefthooves"] = "Clefthooves"
L["Cloud Serpents"] = "Cloud Serpents"
L["Core Hounds"] = "Core Hounds"
L["Crabs"] = "Crabs"
L["Cranes"] = "Cranes"
L["Crawgs"] = "Crawgs"
L["Crocolisks"] = "Crocolisks"
L["Crows"] = "Crows"
L["Darkmoon Chargers"] = "Darkmoon Chargers"
L["Demonic Hounds"] = "Demonic Hounds"
L["Demonic Steeds"] = "Demonic Steeds"
L["Demons"] = "Demons"
L["Devourer"] = "Devourer"
L["Dinosaurs"] = "Dinosaurs"
L["Dire Wolves"] = "Dire Wolves"
L["Direhorns"] = "Direhorns"
L["Discs"] = "Discs"
L["Dragonhawks"] = "Dragonhawks"
L["Drakes"] = "Drakes"
L["Dread Ravens"] = "Dread Ravens"
L["Dreamsaber"] = "Dreamsaber"
L["Eagle"] = "Eagle"
L["Eels"] = "Eels"
L["Elekks"] = "Elekks"
L["Elementals"] = "Elementals"
L["Falcosaurs"] = "Falcosaurs"
L["Fathom Rays"] = "Fathom Rays"
L["Feathermanes"] = "Feathermanes"
L["Felsabers"] = "Felsabers"
L["Fish"] = "Fish"
L["Flies"] = "Flies"
L["Flying Steeds"] = "Flying Steeds"
L["Foxes"] = "Foxes"
L["Gargon"] = "Gargon"
L["Gargoyle"] = "Gargoyle"
L["Goats"] = "Goats"
L["Gorger"] = "Gorger"
L["Gorm"] = "Gorm"
L["Grand Drakes"] = "Grand Drakes"
L["Gronnlings"] = "Gronnlings"
L["Gryphons"] = "Gryphons"
L["Gyrocopters"] = "Gyrocopters"
L["Hands"] = "Hands"
L["Hawkstriders"] = "Hawkstriders"
L["Hippogryphs"] = "Hippogryphs"
L["Horned Steeds"] = "Horned Steeds"
L["Horses"] = "Horses"
L["Hounds"] = "Hounds"
L["Hovercraft"] = "Hovercraft"
L["Humanoids"] = "Humanoids"
L["Hyenas"] = "Hyenas"
L["Infernals"] = "Infernals"
L["Insects"] = "Insects"
L["Jellyfish"] = "Jellyfish"
L["Jet Aerial Units"] = "Jet Aerial Units"
L["Kites"] = "Kites"
L["Kodos"] = "Kodos"
L["Krolusks"] = "Krolusks"
L["Larion"] = "Larion"
L["Lions"] = "Lions"
L["Lizards"] = "Lizards"
L["Lupine"] = "Lupine"
L["Lynx"] = "Lynx"
L["Mammoths"] = "Mammoths"
L["Mana Rays"] = "Mana Rays"
L["Manasabers"] = "Manasabers"
L["Mauler"] = "Mauler"
L["Mechanical Animals"] = "Mechanical Animals"
L["Mechanical Birds"] = "Mechanical Birds"
L["Mechanical Cats"] = "Mechanical Cats"
L["Mechanical Steeds"] = "Mechanical Steeds"
L["Mechanostriders"] = "Mechanostriders"
L["Mecha-suits"] = "Mecha-suits"
L["Meeksi"] = "Meeksi"
L["Mice"] = "Mice"
L["Mollusc"] = "Mollusc"
L["Moose"] = "Moose"
L["Moth"] = "Moth"
L["Motorcycles"] = "Motorcycles"
L["Mountain Horses"] = "Mountain Horses"
L["Mudnose"] = "Mudnose"
L["Murloc"] = "Murloc"
L["Mushan"] = "Mushan"
L["Nether Drakes"] = "Nether Drakes"
L["Nether Rays"] = "Nether Rays"
L["N'Zoth Serpents"] = "N'Zoth Serpents"
L["Others"] = "Others"
L["Ottuk"] = "Ottuk"
L["Owl"] = "Owl"
L["Owlbear"] = "Owlbear"
L["Ox"] = "Ox"
L["Pandaren Phoenixes"] = "Pandaren Phoenixes"
L["Parrots"] = "Parrots"
L["Peafowl"] = "Peafowl"
L["Phoenixes"] = "Phoenixes"
L["Proto-Drakes"] = "Proto-Drakes"
L["Pterrordaxes"] = "Pterrordaxes"
L["Quilen"] = "Quilen"
L["Rabbit"] = "Rabbit"
L["Rams"] = "Rams"
L["Raptora"] = "Raptora"
L["Raptors"] = "Raptors"
L["Rats"] = "Rats"
L["Rays"] = "Rays"
L["Razorwing"] = "Razorwing"
L["Reptiles"] = "Reptiles"
L["Rhinos"] = "Rhinos"
L["Riverbeasts"] = "Riverbeasts"
L["Roc"] = "Roc"
L["Rockets"] = "Rockets"
L["Rodent"] = "Rodent"
L["Ruinstriders"] = "Ruinstriders"
L["Rylaks"] = "Rylaks"
L["Sabers"] = "Sabers"
L["Scorpions"] = "Scorpions"
L["Sea Serpents"] = "Sea Serpents"
L["Seahorses"] = "Seahorses"
L["Seat"] = "Seat"
L["Shardhides"] = "Shardhides"
L["Silithids"] = "Silithids"
L["Skyflayer"] = "Skyflayer"
L["Skyrazor"] = "Skyrazor"
L["Slug"] = "Slug"
L["Snail"] = "Snail"
L["Snapdragons"] = "Snapdragons"
L["Spider Tanks"] = "Spider Tanks"
L["Spiders"] = "Spiders"
L["Sporebat"] = "Sporebat"
L["Stag"] = "Stag"
L["Steeds"] = "Steeds"
L["Stingrays"] = "Stingrays"
L["Stone Cats"] = "Stone Cats"
L["Stone Drakes"] = "Stone Drakes"
L["Surfboard"] = "Surfboard"
L["Talbuks"] = "Talbuks"
L["Tallstriders"] = "Tallstriders"
L["Talonbirds"] = "Talonbirds"
L["Tauralus"] = "Tauralus"
L["Thunder Lizard"] = "Thunder Lizard"
L["Tigers"] = "Tigers"
L["Toads"] = "Toads"
L["Turtles"] = "Turtles"
L["Undead Drakes"] = "Undead Drakes"
L["Undead Steeds"] = "Undead Steeds"
L["Undead Wolves"] = "Undead Wolves"
L["Undercrawlers"] = "Undercrawlers"
L["Underlights"] = "Underlights"
L["Ungulates"] = "Ungulates"
L["Ur'zul"] = "Ur'zul"
L["Vehicles"] = "Vehicles"
L["Vombata"] = "Vombata"
L["Vulpin"] = "Vulpin"
L["Vultures"] = "Vultures"
L["War Wolves"] = "War Wolves"
L["Wasp"] = "Wasp"
L["Water Striders"] = "Water Striders"
L["Wilderlings"] = "Wilderlings"
L["Wind Drakes"] = "Wind Drakes"
L["Wolfhawks"] = "Wolfhawks"
L["Wolves"] = "Wolves"
L["Wyverns"] = "Wyverns"
L["Yaks"] = "Yaks"
L["Yetis"] = "Yetis"

setmetatable(L, {__index = function(self, key)
	self[key] = key or ""
	return key
end})