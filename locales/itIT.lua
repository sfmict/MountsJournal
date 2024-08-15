if GetLocale() ~= "itIT" then
	return
end

local _, ns = ...
local L = ns.L

-- L["author"] = ""
-- L["Main"] = ""
-- L["ConfigPanelTitle"] = ""
-- L["Class settings"] = ""
-- L["Modifier"] = ""
-- L["Normal mount summon"] = ""
-- L["SecondMountTooltipTitle"] = ""
-- L["SecondMountTooltipDescription"] = ""
-- L["Drag to create a summon panel"] = ""
-- L["UseBindingTooltip"] = ""
-- L["Left-button to drag"] = ""
-- L["Right-button to open context menu"] = ""
-- L["Strata of panel"] = ""
-- L["Reset size"] = ""
-- L["ZoneSettingsTooltip"] = ""
-- L["ZoneSettingsTooltipDescription"] = ""
-- L["ButtonsSelectedTooltipDescription"] = ""
-- L["ProfilesTooltipDescription"] = ""
-- L["SettingsTooltipDescription"] = ""
-- L["Handle a jump in water"] = ""
-- L["WaterJumpDescription"] = ""
-- L["UseHerbMounts"] = ""
-- L["UseHerbMountsDescription"] = ""
-- L["UseHerbMountsOnZones"] = ""
-- L["Herb Gathering"] = ""
-- L["HerbGatheringFlagDescription"] = ""
-- L["If item durability is less than"] = ""
-- L["In flyable zones"] = ""
-- L["UseRepairMountsDescription"] = ""
-- L["If the number of free slots in bags is less"] = ""
-- L["Random available mount"] = ""
-- L["UseHallowsEndMounts"] = ""
-- L["UseHallowsEndMountsDescription"] = ""
-- L["Use %s"] = ""
-- L["Use automatically"] = ""
-- L["UseUnderlightAnglerDescription"] = ""
-- L["A macro named \"%s\" already exists, overwrite it?"] = ""
-- L["CreateMacro"] = ""
-- L["CreateMacroTooltip"] = ""
-- L["or key bind"] = ""
-- L["ERR_MOUNT_NO_SELECTED"] = ""
-- L["Collected:"] = ""
-- L["Shown:"] = ""
-- L["hidden for character"] = ""
-- L["only hidden"] = ""
-- L["Hidden by player"] = ""
-- L["Only new"] = ""
-- L["types"] = ""
-- L["selected"] = ""
-- L["MOUNT_TYPE_1"] = ""
-- L["MOUNT_TYPE_2"] = ""
-- L["MOUNT_TYPE_3"] = ""
-- L["MOUNT_TYPE_4"] = ""
-- L["Specific"] = ""
-- L["repair"] = ""
-- L["passenger"] = ""
-- L["Ride Along"] = ""
-- L["transform"] = ""
-- L["Multiple Models"] = ""
-- L["additional"] = ""
-- L["rest"] = ""
-- L["factions"] = ""
-- L["MOUNT_FACTION_1"] = ""
-- L["MOUNT_FACTION_2"] = ""
-- L["MOUNT_FACTION_3"] = ""
-- L["sources"] = ""
-- L["PET_1"] = ""
-- L["PET_2"] = ""
-- L["PET_3"] = ""
-- L["PET_4"] = ""
-- L["expansions"] = ""
-- L["Rarity"] = ""
-- L["Chance of summoning"] = ""
-- L["Any"] = ""
-- L["> (more than)"] = ""
-- L["< (less than)"] = ""
-- L["= (equal to)"] = ""
-- L["sorting"] = ""
-- L["Reverse Sort"] = ""
-- L["Collected First"] = ""
-- L["Favorites First"] = ""
-- L["Additional First"] = ""
-- L["Set current filters as default"] = ""
-- L["Restore default filters"] = ""
-- L["Enable Acceleration around the X-axis"] = ""
-- L["Initial x-axis accseleration"] = ""
-- L["X-axis accseleration"] = ""
-- L["Minimum x-axis speed"] = ""
-- L["Enable Acceleration around the Y-axis"] = ""
-- L["Initial y-axis accseleration"] = ""
-- L["Y-axis accseleration"] = ""
-- L["Minimum y-axis speed"] = ""
-- L["Model"] = ""
-- L["Map"] = ""
-- L["Settings"] = ""
-- L["Dungeons and Raids"] = ""
-- L["Current Location"] = ""
-- L["Enable Flags"] = ""
-- L["Ground Mounts Only"] = ""
-- L["Water Walking"] = ""
-- L["WaterWalkFlagDescription"] = ""
-- L["ListMountsFromZone"] = ""
-- L["No relation"] = ""
-- L["Zones with list"] = ""
-- L["Zones with relation"] = ""
-- L["Zones with flags"] = ""
-- L["CHARACTER_CLASS_DESCRIPTION"] = ""
-- L["HELP_MACRO_MOVE_FALL"] = ""
-- L["HELP_MACRO_COMBAT"] = ""
-- L["CLASS_USEWHENCHARACTERFALLS"] = ""
-- L["CLASS_USEWATERWALKINGSPELL"] = ""
-- L["CLASS_USEONLYWATERWALKLOCATION"] = ""
-- L["DRUID_USELASTDRUIDFORM"] = ""
-- L["DRUID_USEDRUIDFORMSPECIALIZATION"] = ""
-- L["DRUID_USEMACROALWAYS"] = ""
-- L["Collected by %s of players"] = ""
-- L["Summonable Battle Pet"] = ""
-- L["Summon Random Battle Pet"] = ""
-- L["No Battle Pet"] = ""
-- L["Summon a pet every"] = ""
-- L["min"] = ""
-- L["Summon only favorites"] = ""
-- L["NoPetInRaid"] = ""
-- L["NoPetInGroup"] = ""
-- L["CopyMountTarget"] = ""
-- L["Colored mount names by rarity"] = ""
-- L["Enable arrow buttons to browse mounts"] = ""
-- L["Open links in %s"] = ""
-- L["Click opens in"] = ""
-- L["Show wowhead link in mount preview"] = ""
-- L["About"] = ""
-- L["Help with translation of %s. Thanks."] = ""
-- L["Localization Translators:"] = ""
-- ANIMATIONS
-- L["Default"] = ""
-- L["Mount special"] = ""
-- L["Walk"] = ""
-- L["Walk backwards"] = ""
-- L["Run"] = ""
-- L["Swim idle"] = ""
-- L["Swim"] = ""
-- L["Swim backwards"] = ""
-- L["Fly stand"] = ""
-- L["Fly"] = ""
-- L["Fly backwards"] = ""
-- L["Loop"] = ""
-- L["Are you sure you want to delete animation %s?"] = ""
-- PROFILES
-- L["Profiles"] = ""
-- L["New profile"] = ""
-- L["Create"] = ""
-- L["Copy current"] = ""
-- L["A profile with the same name exists."] = ""
-- L["By Specialization"] = ""
-- L["Areans and Battlegrounds"] = ""
-- L["Profile settings"] = ""
-- L["Pet binding from default profile"] = ""
-- L["Zones settings from default profile"] = ""
-- L["Auto add new mounts to selected"] = ""
-- L["Select all filtered mounts by type in the selected zone"] = ""
-- L["Unselect all filtered mounts in the selected zone"] = ""
-- L["Select all favorite mounts by type in the selected zone"] = ""
-- L["Select all mounts by type in selected zone"] = ""
-- L["Unselect all mounts in selected zone"] = ""
-- L["Are you sure you want to delete profile %s?"] = ""
-- L["Are you sure you want %s?"] = ""
-- TAGS
-- L["tags"] = ""
-- L["No tag"] = ""
-- L["With all tags"] = ""
-- L["Add tag"] = ""
-- L["Tag already exists."] = ""
-- L["Are you sure you want to delete tag %s?"] = ""
-- FAMILY
-- L["Family"] = ""
-- L["Airplanes"] = ""
-- L["Airships"] = ""
-- L["Albatross"] = ""
-- L["Alpacas"] = ""
-- L["Amphibian"] = ""
-- L["Animite"] = ""
-- L["Aqir Flyers"] = ""
-- L["Arachnids"] = ""
-- L["Armoredon"] = ""
-- L["Assault Wagons"] = ""
-- L["Basilisks"] = ""
-- L["Bats"] = ""
-- L["Bears"] = ""
-- L["Bees"] = ""
-- L["Beetle"] = ""
-- L["Bipedal Cat"] = ""
-- L["Birds"] = ""
-- L["Blood Ticks"] = ""
-- L["Boars"] = ""
-- L["Book"] = ""
-- L["Bovids"] = ""
-- L["Broom"] = ""
-- L["Brutosaurs"] = ""
-- L["Camels"] = ""
-- L["Carnivorans"] = ""
-- L["Carpets"] = ""
-- L["Cats"] = ""
-- L["Cervid"] = ""
-- L["Chargers"] = ""
-- L["Chickens"] = ""
-- L["Clefthooves"] = ""
-- L["Cloud Serpents"] = ""
-- L["Core Hounds"] = ""
-- L["Crabs"] = ""
-- L["Cranes"] = ""
-- L["Crawgs"] = ""
L["Crocolisks"] = "Crocolisco"
-- L["Crows"] = ""
-- L["Demonic Hounds"] = ""
-- L["Demonic Steeds"] = ""
-- L["Demons"] = ""
-- L["Devourer"] = ""
-- L["Dinosaurs"] = ""
-- L["Dire Wolves"] = ""
-- L["Direhorns"] = ""
-- L["Discs"] = ""
-- L["Dragonhawks"] = ""
-- L["Drakes"] = ""
-- L["Dread Ravens"] = ""
-- L["Dreamsaber"] = ""
-- L["Eagle"] = ""
-- L["Elekks"] = ""
-- L["Elementals"] = ""
-- L["Falcosaurs"] = ""
-- L["Fathom Rays"] = ""
-- L["Feathermanes"] = ""
-- L["Felsabers"] = ""
-- L["Fish"] = ""
-- L["Flies"] = ""
-- L["Flying Steeds"] = ""
-- L["Foxes"] = ""
-- L["Gargon"] = ""
-- L["Gargoyle"] = ""
-- L["Goats"] = ""
-- L["Gorger"] = ""
-- L["Gorm"] = ""
-- L["Grand Drakes"] = ""
-- L["Gronnlings"] = ""
-- L["Gryphons"] = ""
-- L["Gyrocopters"] = ""
-- L["Hands"] = ""
-- L["Hawkstriders"] = ""
-- L["Hippogryphs"] = ""
-- L["Horned Steeds"] = ""
-- L["Horses"] = ""
-- L["Hounds"] = ""
-- L["Hovercraft"] = ""
-- L["Humanoids"] = ""
-- L["Hyenas"] = ""
-- L["Infernals"] = ""
-- L["Insects"] = ""
-- L["Jellyfish"] = ""
-- L["Jet Aerial Units"] = ""
-- L["Kites"] = ""
-- L["Kodos"] = ""
-- L["Krolusks"] = ""
-- L["Larion"] = ""
-- L["Lions"] = ""
-- L["Lupine"] = ""
-- L["Lynx"] = ""
-- L["Mammoths"] = ""
-- L["Mana Rays"] = ""
-- L["Manasabers"] = ""
-- L["Mauler"] = ""
-- L["Mechanical Animals"] = ""
-- L["Mechanical Birds"] = ""
-- L["Mechanical Cats"] = ""
-- L["Mechanical Steeds"] = ""
-- L["Mechanostriders"] = ""
-- L["Mecha-suits"] = ""
-- L["Mollusc"] = ""
-- L["Moose"] = ""
-- L["Moth"] = ""
-- L["Motorcycles"] = ""
-- L["Mountain Horses"] = ""
-- L["Mudnose"] = ""
-- L["Murloc"] = ""
-- L["Mushan"] = ""
-- L["Nether Drakes"] = ""
-- L["Nether Rays"] = ""
-- L["N'Zoth Serpents"] = ""
-- L["Others"] = ""
-- L["Ottuk"] = ""
-- L["Owl"] = ""
-- L["Owlbear"] = ""
-- L["Ox"] = ""
-- L["Pandaren Phoenixes"] = ""
-- L["Parrots"] = ""
-- L["Peafowl"] = ""
-- L["Phoenixes"] = ""
-- L["Proto-Drakes"] = ""
-- L["Pterrordaxes"] = ""
-- L["Quilen"] = ""
-- L["Rabbit"] = ""
-- L["Rams"] = ""
-- L["Raptora"] = ""
-- L["Raptors"] = ""
-- L["Rats"] = ""
-- L["Rays"] = ""
-- L["Razorwing"] = ""
-- L["Reptiles"] = ""
-- L["Rhinos"] = ""
-- L["Riverbeasts"] = ""
-- L["Roc"] = ""
-- L["Rockets"] = ""
-- L["Rodent"] = ""
-- L["Ruinstriders"] = ""
-- L["Rylaks"] = ""
-- L["Sabers"] = ""
-- L["Scorpions"] = ""
-- L["Sea Serpents"] = ""
-- L["Seahorses"] = ""
-- L["Seat"] = ""
-- L["Shardhides"] = ""
-- L["Silithids"] = ""
-- L["Skyflayer"] = ""
-- L["Skyrazor"] = ""
-- L["Slug"] = ""
-- L["Snail"] = ""
-- L["Snapdragons"] = ""
-- L["Spider Tanks"] = ""
-- L["Spiders"] = ""
-- L["Sporebat"] = ""
-- L["Stag"] = ""
-- L["Steeds"] = ""
-- L["Stingrays"] = ""
-- L["Stone Cats"] = ""
-- L["Stone Drakes"] = ""
-- L["Surfboard"] = ""
-- L["Talbuks"] = ""
-- L["Tallstriders"] = ""
-- L["Talonbirds"] = ""
-- L["Tauralus"] = ""
-- L["Thunder Lizard"] = ""
-- L["Tigers"] = ""
-- L["Toads"] = ""
-- L["Turtles"] = ""
-- L["Undead Drakes"] = ""
-- L["Undead Steeds"] = ""
-- L["Undead Wolves"] = ""
-- L["Undercrawlers"] = ""
-- L["Ungulates"] = ""
-- L["Ur'zul"] = ""
-- L["Vehicles"] = ""
-- L["Vombata"] = ""
-- L["Vulpin"] = ""
-- L["Vultures"] = ""
-- L["War Wolves"] = ""
-- L["Wasp"] = ""
-- L["Water Striders"] = ""
-- L["Wilderlings"] = ""
-- L["Wind Drakes"] = ""
-- L["Wolfhawks"] = ""
-- L["Wolves"] = ""
-- L["Wyverns"] = ""
-- L["Yaks"] = ""
-- L["Yetis"] = ""