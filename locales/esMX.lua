if GetLocale() ~= "esMX" then
	return
end

local _, L = ...

L["author"] = "Autor"
L["%s Configuration"] = "%s Configuración"
L["ConfigPanelTitle"] = "Configuración global"
L["Class settings"] = "Configuración por clase"
-- L["Modifier"] = ""
-- L["Normal mount summon"] = ""
-- L["SecondMountTooltipTitle"] = ""
-- L["SecondMountTooltipDescription"] = ""
-- L["ThirdMountTooltipDescription"] = ""
-- L["ZoneSettingsTooltip"] = ""
-- L["ZoneSettingsTooltipDescription"] = ""
L["ButtonsSelectedTooltipDescription"] = "Los botones laterales seleccionan montajes por tipo para convocar en las condiciones adecuadas. Los favoritos no afectan a los montajes de invocación con %s."
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
-- L["Random available mount"] = ""
-- L["UseHallowsEndMounts"] = ""
-- L["UseHallowsEndMountsDescription"] = ""
-- L["Use %s"] = ""
-- L["Use automatically"] = ""
-- L["UseUnderlightAnglerDescription"] = ""
L["A macro named \"%s\" already exists, overwrite it?"] = "Ya existe una macro llamada \"%s\", ¿Sobrescribirla?"
L["CreateMacro"] = "Crear macro"
-- L["CreateMacroTooltip"] = ""
-- L["or key bind"] = ""
L["Collected:"] = "Reunido"
-- L["Settings"] = ""
-- L["Shown:"] = ""
-- L["With multiple models"] = ""
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
-- L["transform"] = ""
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
L["Chance of summoning"] = "Posibilidad de convocatoria"
L["Any"] = "Cualquiera"
L["> (more than)"] = "> (más que)"
L["< (less than)"] = "< (menos que)"
L["= (equal to)"] = "= (igual a)"
-- L["sorting"] = ""
-- L["Reverse Sort"] = ""
-- L["Favorites First"] = ""
-- L["Additional First"] = ""
-- L["Dragonriding First"] = ""
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
-- L["Map / Model"] = ""
-- L["Dungeons and Raids"] = ""
-- L["Current Location"] = ""
-- L["Enable Flags"] = ""
-- L["Regular Flying Mounts Only"] = ""
-- L["Ground Mounts Only"] = ""
-- L["Water Walking"] = ""
-- L["WaterWalkFlagDescription"] = ""
-- L["ListMountsFromZone"] = ""
-- L["No relation"] = ""
-- L["Zones with list"] = ""
-- L["Zones with relation"] = ""
-- L["Zones with flags"] = ""
L["CHARACTER_CLASS_DESCRIPTION"] = "(la configuración de caracteres anula la configuración de clase)"
-- L["HELP_MACRO_MOVE_FALL"] = ""
-- L["HELP_MACRO_COMBAT"] = ""
L["CLASS_USEWHENCHARACTERFALLS"] = "Usar el %s cuando el carácter cae"
L["CLASS_USEWATERWALKINGSPELL"] = "Utilice el %s al invocar terrestre"
L["CLASS_USEONLYWATERWALKLOCATION"] = "Usar solo en zonas acuáticas"
-- L["DRUID_USELASTDRUIDFORM"] = ""
-- L["DRUID_USEDRUIDFORMSPECIALIZATION"] = ""
-- L["DRUID_USEMACROALWAYS"] = ""
-- L["DRUID_USEIFNOTDRAGONRIDABLE"] = ""
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
L["About"] = "Acerca de"
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
L["Are you sure you want to delete animation %s?"] = "¿Está seguro de que desea eliminar la animación \"%s\"?"
-- PROFILES
-- L["Profiles"] = ""
-- L["New profile"] = ""
L["Create"] = "Crear"
L["Copy current"] = "Copia Actual"
L["A profile with the same name exists."] = "Existe un perfil con el mismo nombre."
L["By Specialization"] = "Por Especialización"
L["Areans and Battlegrounds"] = "Arenas y campos de batalla"
-- L["Profile settings"] = ""
-- L["Pet binding from default profile"] = ""
-- L["Zones settings from default profile"] = ""
L["Auto add new mounts to selected"] = "Agregar automáticamente nuevos montajes a los seleccionados"
-- L["Select all filtered mounts by type in the selected zone"] = ""
-- L["Unselect all filtered mounts in the selected zone"] = ""
-- L["Select all favorite mounts by type in the selected zone"] = ""
-- L["Select all mounts by type in selected zone"] = ""
-- L["Unselect all mounts in selected zone"] = ""
L["Are you sure you want to delete profile %s?"] = "¿Está seguro de que desea eliminar el perfil \"%s\"?"
L["Are you sure you want %s?"] = "¿Estás seguro de que quieres \"%s\"?"
-- TAGS
-- L["tags"] = ""
-- L["No tag"] = ""
-- L["With all tags"] = ""
L["Add tag"] = "Agregar etiqueta"
-- L["Tag already exists."] = ""
L["Are you sure you want to delete tag %s?"] = "¿Está seguro de que desea eliminar la etiqueta \"%s\"?"