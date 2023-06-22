if GetLocale() ~= "frFR" then
	return
end

local _, L = ...

L["author"] = "Auteur"
L["%s Configuration"] = "%s Configuration"
L["ConfigPanelTitle"] = "Paramètres généraux"
L["Class settings"] = "Paramètres de Classe"
L["Modifier"] = "Modificateur"
L["Normal mount summon"] = "Invocation de la monture normale"
-- L["SecondMountTooltipTitle"] = ""
-- L["SecondMountTooltipDescription"] = ""
-- L["ZoneSettingsTooltip"] = ""
L["ZoneSettingsTooltipDescription"] = "Création d'une liste de montures pour la zone. Configuration des marqueurs de zone. Configuration des relations pour utiliser une liste de montures dans différentes zones."
L["ButtonsSelectedTooltipDescription"] = "Les boutons sur le côté sélectionnent les montures par type à invoquer suivant les conditions.\n\nLes favoris n'affectent pas les montures d'invocation utilisant %s."
-- L["ProfilesTooltipDescription"] = ""
-- L["SettingsTooltipDescription"] = ""
-- L["Handle a jump in water"] = ""
-- L["WaterJumpDescription"] = ""
-- L["UseHerbMounts"] = ""
-- L["UseHerbMountsDescription"] = ""
-- L["UseHerbMountsOnZones"] = ""
-- L["Herb Gathering"] = ""
-- L["HerbGatheringFlagDescription"] = ""
L["If item durability is less than"] = "Si la durabilité de l'objet est inférieure à"
L["In flyable zones"] = "En zone de vol"
L["UseRepairMountsDescription"] = "Si la durabilité d'au moins un objet est inférieure au pourcentage spécifié, la monture sélectionnée sera invoquée."
-- L["Random available mount"] = ""
L["Use %s"] = "Utiliser %s."
-- L["Use automatically"] = ""
L["UseMagicBroomTitle"] = "Utiliser le Balai Magique"
-- L["UseMagicBroomDescription"] = ""
-- L["UseUnderlightAnglerDescription"] = ""
L["A macro named \"%s\" already exists, overwrite it?"] = "Une macro nommée \"%s\" existe déjà, l'écraser?"
L["CreateMacro"] = "Créer macro"
L["CreateMacroTooltip"] = "La macro créée est utilisée pour invoquer la monture sélectionnée"
L["or key bind"] = "ou raccourcis"
L["Collected:"] = "Collecté"
L["Settings"] = "Réglages"
L["Shown:"] = "Montré:"
-- L["With multiple models"] = ""
-- L["hidden for character"] = ""
L["only hidden"] = "Uniquement caché"
L["Hidden by player"] = "Masqué par le joueur"
-- L["Only new"] = ""
L["types"] = "Types"
L["selected"] = "Sélectionné"
L["MOUNT_TYPE_1"] = "Volante"
L["MOUNT_TYPE_2"] = "Terrestre"
L["MOUNT_TYPE_3"] = "Nageuse"
L["MOUNT_TYPE_4"] = "Non sélectionné"
L["factions"] = "Factions"
L["MOUNT_FACTION_1"] = "Horde"
L["MOUNT_FACTION_2"] = "Alliance"
L["MOUNT_FACTION_3"] = "Les deux"
L["sources"] = "Sources"
-- L["PET_1"] = ""
-- L["PET_2"] = ""
-- L["PET_3"] = ""
-- L["PET_4"] = ""
L["expansions"] = "Extensions"
L["Chance of summoning"] = "Chance d'Invocation"
L["Any"] = "Tous"
L["> (more than)"] = "> (plus que)"
L["< (less than)"] = "< (moins que)"
L["= (equal to)"] = "= (égal à)"
L["sorting"] = "Trier"
-- L["Reverse Sort"] = ""
L["Favorites First"] = "Favoris d'abord"
L["Set current filters as default"] = "Utiliser le filtre actuel par défaut"
L["Restore default filters"] = "Restaurer tri par défaut"
L["Enable Acceleration around the X-axis"] = "Activer l'accélération autour de l'axe X"
L["Initial x-axis accseleration"] = "Accélération initiale sur l'axe X"
L["X-axis accseleration"] = "Accélération sur l'axe X"
L["Minimum x-axis speed"] = "Vitesse minimale axe X"
L["Enable Acceleration around the Y-axis"] = "Activer l'accélération autour de l'axe Y"
L["Initial y-axis accseleration"] = "Accélération initiale sur l'axe Y"
L["Y-axis accseleration"] = "Accélération sur l'axe Y"
L["Minimum y-axis speed"] = "Vitesse minimal axe Y"
L["Map / Model"] = "Carte / Modèle"
L["Dungeons and Raids"] = "Donjons et Raids"
L["Current Location"] = "Localisation actuelle"
L["Enable Flags"] = "Activer les drapeaux"
L["Ground Mounts Only"] = "Monture terrestre uniquement"
L["Water Walking"] = "Marche sur l'eau"
L["WaterWalkFlagDescription"] = "Utiliser pour configurer les classes"
L["ListMountsFromZone"] = "Utiliser la liste de montures de la zone"
L["No relation"] = "Pas de relation"
L["Zones with list"] = "Zones avec une liste"
-- L["Zones with relation"] = ""
-- L["Zones with flags"] = ""
L["CHARACTER_CLASS_DESCRIPTION"] = "(les paramètres du personnage remplacent les paramètres de classe)"
L["HELP_MACRO_MOVE_FALL"] = "Cette macro s'exécutera, en extérieur ou en mouvement, et que vous n'avez pas de balai magique ou qu'il est désactivé."
L["HELP_MACRO_COMBAT"] = "Cette macro s'exécutera, si vous êtes en combat"
-- L["WORGEN_USERUNNINGWILD"] = ""
L["CLASS_USEWHENCHARACTERFALLS"] = "Utiliser la monture %s quand le personnage tombe"
L["CLASS_USEWATERWALKINGSPELL"] = "Utiliser la monture %s lors de l'invocation d'une monture au sol"
L["CLASS_USEONLYWATERWALKLOCATION"] = "A n'utiliser que dans les zones aquatiques"
L["DRUID_USELASTDRUIDFORM"] = "Remettre la précédente forme en descendant de la monture"
-- L["DRUID_USEDRUIDFORMSPECIALIZATION"] = ""
L["DRUID_USEMACROALWAYS"] = "Utiliser cette macro au lieu des montures"
-- L["DRUID_USEIFNOTDRAGONRIDABLE"] = ""
L["Summonable Battle Pet"] = "Compagnons de bataille invocable"
L["Summon Random Battle Pet"] = "Invoquer un compagnon de bataille au hasard"
L["No Battle Pet"] = "Pas de compagnon de bataille"
-- L["Summon a pet every"] = ""
-- L["min"] = ""
-- L["Summon only favorites"] = ""
L["NoPetInRaid"] = "Ne pas invoquer de compagnon en groupe raid"
L["NoPetInGroup"] = "Ne pas invoquer de compagnon en groupe"
L["CopyMountTarget"] = "Essayez de copier la monture de la cible"
L["Enable arrow buttons to browse mounts"] = "Activer les flèches du clavier pour parcourir les montures"
L["Open links in %s"] = "Ouvrir les liens dans %s"
L["Click opens in"] = "Cliquer sur ouvrir dans"
L["About"] = "À propos de"
L["Help with translation of %s. Thanks."] = "Aide avec la translation de %s. Merci."
L["Localization Translators:"] = "Traducteurs:"
-- ANIMATIONS
L["Default"] = "Par défaut"
L["Mount special"] = "Monture spéciale"
L["Walk"] = "Marcher"
L["Walk backwards"] = "marcher en arrière"
L["Run"] = "Courir"
L["Swim idle"] = "Nager au ralenti"
L["Swim"] = "Nager"
L["Swim backwards"] = "Nager en arrière"
L["Fly stand"] = "Vol stationnaire"
L["Fly"] = "Voler"
L["Fly backwards"] = "Voler en arrière"
L["Loop"] = "Boucle"
L["Are you sure you want to delete animation %s?"] = "Etes vous sûr de vouloir supprimer l'animation \"%s\"?"
-- PROFILES
L["Profiles"] = "Profils"
L["New profile"] = "Nouveau profil"
L["Create"] = "Créer"
L["Copy current"] = "Copier des paramètres actuels"
L["A profile with the same name exists."] = "Il existe un profil du même nom."
L["By Specialization"] = "Par Spécialisation"
L["Areans and Battlegrounds"] = "Arènes et Champs de Bataille"
L["Profile settings"] = "Réglages du profil"
-- L["Pet binding from default profile"] = ""
-- L["Zones settings from default profile"] = ""
L["Auto add new mounts to selected"] = "Ajouter automatiquement vos nouvelles montures à la sélection"
-- L["Select all favorite mounts by type in the selected zone"] = ""
-- L["Select all mounts by type in selected zone"] = ""
L["Unselect all mounts in selected zone"] = "Déselectionne toutes les montures dans une zone sélectionné."
L["Are you sure you want to delete profile %s?"] = "Etes vous sûr de vouloir supprimer le profil \"%s\"?"
L["Are you sure you want %s?"] = "Etes vous sur de vouloir \"%s\"?"
-- TAGS
L["tags"] = "Mots clés"
L["No tag"] = "Pas de mot clé"
L["With all tags"] = "Avec tous les mots clés"
L["Add tag"] = "Ajouter un tag"
L["Tag already exists."] = "Mot clé déjà existant"
L["Are you sure you want to delete tag %s?"] = "Etes vous sûr de vouloir supprimer le tag \"%s\"?"