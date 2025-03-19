if GetLocale() ~= "ptBR" then
	return
end

local _, ns = ...
local L = ns.L

L["author"] = "Autor"
-- L["Main"] = ""
L["ConfigPanelTitle"] = "Configurações globais"
L["Class settings"] = "Configurações por classe"
-- L["Modifier"] = ""
-- L["Normal mount summon"] = ""
-- L["SecondMountTooltipTitle"] = ""
-- L["SecondMountTooltipDescription"] = ""
L["Drag to create a summon panel"] = "Arraste para criar um painel de invocação"
-- L["UseBindingTooltip"] = ""
-- L["Summon panel"] = ""
-- L["Left-button to drag"] = ""
-- L["Right-button to open context menu"] = ""
-- L["Strata of panel"] = ""
L["Fade out (opacity)"] = "Opacidade"
L["Button size"] = "Tamanho do botão"
-- L["Reset size"] = ""
-- L["Target Mount"] = ""
-- L["Shows the mount of current target"] = ""
-- L["Select mount"] = ""
-- L["Auto select Mount"] = ""
-- L["ZoneSettingsTooltip"] = ""
-- L["ZoneSettingsTooltipDescription"] = ""
L["ButtonsSelectedTooltipDescription"] = "Favoritos não afetam invocações de montarias usando %s.\n\nPara as convocar, deve selecionar as montarias por tipo."
-- L["ProfilesTooltipDescription"] = ""
-- L["SettingsTooltipDescription"] = ""
-- L["Handle a jump in water"] = ""
L["WaterJumpDescription"] = "Depois de pular na água, uma montaria não submersa será invocada."
-- L["UseHerbMounts"] = ""
-- L["UseHerbMountsDescription"] = ""
-- L["UseHerbMountsOnZones"] = ""
-- L["Herb Gathering"] = ""
-- L["HerbGatheringFlagDescription"] = ""
L["If item durability is less than"] = "Se a durabilidade do item for menor que"
L["In flyable zones"] = "Em zonas de voo"
L["UseRepairMountsDescription"] = "Se a durabilidade de pelo menos um item for menor que a porcentagem especificada, a montaria selecionada será invocada."
L["If the number of free slots in bags is less"] = "Se o número de slots livres nas bolsas for menor"
L["Random available mount"] = "Montaria aleatória disponíveis"
-- L["UseHallowsEndMounts"] = ""
-- L["UseHallowsEndMountsDescription"] = ""
L["Use %s"] = "Usar %s"
-- L["Use automatically"] = ""
-- L["UseUnderlightAnglerDescription"] = ""
L["A macro named \"%s\" already exists, overwrite it?"] = "Já existe uma macro chamada \"%s\", substituir ?"
L["CreateMacro"] = "Criar Macro"
L["CreateMacroTooltip"] = "A macro criada é usada para evocar as montagens selecionadas."
-- L["or key bind"] = ""
L["ERR_MOUNT_NO_SELECTED"] = "Você não tem nenhuma montaria selecionada válida."
L["Collected:"] = "Coletada"
L["Shown:"] = "Mostrando:"
L["hidden for character"] = "Oculto para o personagem"
-- L["only hidden"] = ""
L["Hidden by player"] = "Oculto pelo jogador"
-- L["Only new"] = ""
L["types"] = "Tipos"
-- L["selected"] = ""
-- L["SELECT_AS_TYPE_1"] = ""
-- L["SELECT_AS_TYPE_2"] = ""
-- L["SELECT_AS_TYPE_3"] = ""
-- L["MOUNT_TYPE_1"] = ""
-- L["MOUNT_TYPE_2"] = ""
-- L["MOUNT_TYPE_3"] = ""
-- L["MOUNT_TYPE_4"] = ""
-- L["Specific"] = ""
-- L["repair"] = ""
-- L["passenger"] = ""
-- L["Ride Along"] = ""
-- L["transform"] = ""
L["Multiple Models"] = "Múltiplos Modelos"
L["additional"] = "Adicional"
-- L["rest"] = ""
L["factions"] = "Facções"
L["MOUNT_FACTION_1"] = "Horda"
L["MOUNT_FACTION_2"] = "Aliança"
-- L["MOUNT_FACTION_3"] = ""
-- L["sources"] = ""
-- L["PET_1"] = ""
-- L["PET_2"] = ""
-- L["PET_3"] = ""
-- L["PET_4"] = ""
L["expansions"] = "Expansões"
-- L["Rarity"] = ""
-- L["Receipt date"] = ""
-- L["Travel time"] = ""
-- L["Travel distance"] = ""
L["Avg. speed"] = "Velocidade média"
L["Chance of summoning"] = "Chance de evocar"
L["Any"] = "Qualquer"
L["> (more than)"] = "> (mais que)"
L["< (less than)"] = "< (menor que)"
L["= (equal to)"] = "= (igual a)"
L["sorting"] = "Organizar"
-- L["Then Sort By"] = ""
-- L["Reverse Sort"] = ""
L["Collected First"] = "Coletado Primeiro"
L["Favorites First"] = "Favoritos Primeiro"
-- L["Additional First"] = ""
-- L["Set current filters as default"] = ""
-- L["Restore default filters"] = ""
L["Enable Acceleration around the X-axis"] = "Habilitar a aceleração de acordo com o eixo X"
-- L["Initial x-axis accseleration"] = ""
-- L["X-axis accseleration"] = ""
-- L["Minimum x-axis speed"] = ""
L["Enable Acceleration around the Y-axis"] = "Habilitar a aceleração de acordo com o eixo Y"
-- L["Initial y-axis accseleration"] = ""
-- L["Y-axis accseleration"] = ""
-- L["Minimum y-axis speed"] = ""
L["Model"] = "Modelo"
L["Map"] = "Mapa"
-- L["Map flags"] = ""
-- L["Settings"] = ""
L["Dungeons and Raids"] = "Masmorras e Raides"
L["Current Location"] = "Local atual"
L["Enable Flags"] = "Habilitar Bandeiras"
L["Ground Mounts Only"] = "Somente Montaria Terrestre"
L["Water Walking"] = "Caminhando na água"
-- L["WaterWalkFlagDescription"] = ""
-- L["ListMountsFromZone"] = ""
-- L["No relation"] = ""
L["Zones with list"] = "Zona com lista"
-- L["Zones with relation"] = ""
-- L["Zones with flags"] = ""
L["CHARACTER_CLASS_DESCRIPTION"] = "(as configurações de personagem substituem as configurações de classe)"
L["HELP_MACRO_MOVE_FALL"] = "Esta macro será executada se você estiver em ambientes fechados ou em movimento e não tiver uma [Vassoura Mágica] ou ela estiver desligada."
L["HELP_MACRO_COMBAT"] = "Esta macro será executada se você estiver em combate."
L["CLASS_USEWHENCHARACTERFALLS"] = "Use o %s quando o personagem estiver em queda"
L["CLASS_USEWATERWALKINGSPELL"] = "Use o %s ao evocar montaria terrestre"
-- L["CLASS_USEONLYWATERWALKLOCATION"] = ""
L["DRUID_USELASTDRUIDFORM"] = "Volta o último forma ao desmontar"
-- L["DRUID_USEDRUIDFORMSPECIALIZATION"] = ""
L["DRUID_USEMACROALWAYS"] = "Use essas macros em vez de montarias"
L["Collected by %s of players"] = "Coletado por %s jogadores"
-- L["Summonable Battle Pet"] = ""
-- L["Summon Random Battle Pet"] = ""
L["No Battle Pet"] = "Sem Pet de Batalha"
-- L["Summon a pet every"] = ""
L["min"] = "min"
-- L["Summon only favorites"] = ""
-- L["NoPetInRaid"] = ""
-- L["NoPetInGroup"] = ""
L["Colored mount names by rarity"] = "Cor do nome da montaria por raridade"
L["Enable arrow buttons to browse mounts"] = "Ative os botões de seta para navegar pelas montarias"
-- L["Show mount type selection buttons"] = ""
L["CopyMountTarget"] = "Tente copiar a montaria do alvo"
-- L["Open links in %s"] = ""
-- L["Click opens in"] = ""
-- L["Show wowhead link in mount preview"] = ""
L["Enable statistics collection"] = "Habilitar coleta de estatísticas"
-- L["STATISTICS_DESCRIPTION"] = ""
-- L["Show mount in unit tooltip"] = ""
-- L["Rule Set"] = ""
-- L["Rule Sets"] = ""
-- L["New rule set"] = ""
L["A rule set with the same name exists."] = "Existe um conjunto de regras com o mesmo nome."
L["Are you sure you want to delete rule set %s?"] = "Tem certeza de que deseja excluir o conjunto de regras %s?"
-- L["Set as default"] = ""
-- L["Rule"] = ""
-- L["Rules"] = ""
-- L["RULES_TITLE"] = ""
L["Add Rule"] = "Adicionar regra"
-- L["Import Rule"] = ""
-- L["Reset Rules"] = ""
-- L["Remove Rule %d"] = ""
-- L["Alternative Mode"] = ""
-- L["NOT_CONDITION"] = ""
L["Conditions"] = "Condições"
L["Action"] = "Ação"
L["Edit Rule"] = "Editar regra"
-- L["ANY_MODIFIER"] = ""
-- L["Macro condition"] = ""
L["Mouse button"] = "Botão do Mouse"
-- L["Zone type"] = ""
-- L["Nameless holiday"] = ""
L["Flight style"] = "Estilo de Voo"
L["Steady Flight"] = "Voo Estável"
L["Flyable area"] = "Área que pode voar"
L["Have item"] = "Tem o item"
-- L["Item is ready"] = ""
L["Item is equipped"] = "O item está equipado"
-- L["Spell is known"] = ""
-- L["Spell is ready"] = ""
-- L["Have zone spell"] = ""
-- L["Zone Name/Subzone Name"] = ""
-- L["The player has a buff"] = ""
-- L["The player has a debuff"] = ""
-- L["The player is falling"] = ""
-- L["The player is moving"] = ""
-- L["The player is indoors"] = ""
-- L["The player is swimming"] = ""
-- L["The player is mounted"] = ""
-- L["The player is within an vehicle"] = ""
-- L["The player is dead"] = ""
-- L["Sex"] = ""
-- L["Talent loadout"] = ""
-- L["Get State"] = ""
-- L["Get a state that can be set in actions using \"Set State\""] = ""
-- L["Set State"] = ""
-- L["Set a state that can be read in conditions using \"Get State\""] = ""
L["Random Mount"] = "Montaria Aleatória"
-- L["Random Mount of Selected Type"] = ""
L["Random Mount by Rarity"] = "Montaria Aleatória por Raridade"
-- L["Random Mount of Selected Type by Rarity"] = ""
-- L["The lower the rarity, the higher the chance"] = ""
-- L["Selected profile"] = ""
L["Mount"] = "Montaria"
-- L["Use Item"] = ""
-- L["Use Inventory Item"] = ""
L["Cast Spell"] = "Lançar feitiço"
-- L["Use macro before mounting"] = ""
-- L["PMACRO_DESCRIPTION"] = ""
-- L["Snippet"] = ""
-- L["Code Snippet"] = ""
-- L["Code Snippets"] = ""
-- L["Add Snippet"] = ""
-- L["Import Snippet"] = ""
-- L["A snippet with the same name exists."] = ""
-- L["Are you sure you want to delete snippet %s?"] = ""
-- L["Line"] = ""
-- L["Examples"] = ""
-- L["Tab Size"] = ""
L["Do you want to save changes?"] = "Você quer salvas as mudanças?"
L["About"] = "Sobre"
L["Help with translation of %s. Thanks."] = "Ajudou com a tradução de %s. Obrigado."
-- L["Localization Translators:"] = ""
-- L["ABBR_YARD"] = ""
-- L["ABBR_MILE"] = ""
-- L["ABBR_METER"] = ""
-- L["ABBR_KILOMETER"] = ""
-- L["ABBR_HOUR"] = ""
-- L["Right-click for more options"] = ""
-- L["Shift-click to create a chat link"] = ""
-- L["Requesting data from %s ..."] = ""
-- L["Error not receiving data from %s ..."] = ""
-- L["Malformed link"] = ""
-- L["Transmission error"] = ""
-- L["Receiving data from %s"] = ""
-- L["Received from"] = ""
-- ANIMATIONS
L["Default"] = "Padrão"
L["Mount special"] = "Especial da Montaria"
L["Walk"] = "Andando"
L["Walk backwards"] = "Andar para trás"
-- L["Run"] = ""
-- L["Swim idle"] = ""
-- L["Swim"] = ""
-- L["Swim backwards"] = ""
L["Fly stand"] = "No ar parado"
L["Fly"] = "Voando"
L["Fly backwards"] = "Voando para trás"
-- L["Loop"] = ""
L["Are you sure you want to delete animation %s?"] = "Tem certeza de que deseja excluir a animação \"%s\" ?"
-- PROFILES
-- L["Profile"] = ""
L["Profiles"] = "Perfis"
L["New profile"] = "Novo perfil"
L["Create"] = "Criar"
L["Copy current"] = "Copiar atual"
-- L["Export"] = ""
-- L["Import"] = ""
L["A profile with the same name exists."] = "Existe um perfil com o mesmo nome."
-- L["Profile settings"] = ""
-- L["Pet binding from default profile"] = ""
-- L["Zones settings from default profile"] = ""
L["Auto add new mounts to selected"] = "Adicionar automaticamente novas montarias ao selecionado"
-- L["Select all filtered mounts by type in the selected zone"] = ""
-- L["Unselect all filtered mounts in the selected zone"] = ""
-- L["Select all favorite mounts by type in the selected zone"] = ""
-- L["Select all mounts by type in selected zone"] = ""
-- L["Unselect all mounts in selected zone"] = ""
L["Are you sure you want to delete profile %s?"] = "Tem certeza de que deseja excluir o perfil \"%s\" ?"
L["Are you sure you want %s?"] = "Tem certeza de que deseja \"%s\" ?"
-- TAGS
L["tags"] = "Marcadores"
L["No tag"] = "Sem marcardor"
L["With all tags"] = "Com todos os marcadores"
L["Add tag"] = "Adicionar marcador"
L["Tag already exists."] = "Marcador já existe."
L["Are you sure you want to delete tag %s?"] = "Tem certeza de que deseja excluir o marcador \"%s\" ?"
-- FAMILY
L["Family"] = "Família"
L["Airplanes"] = "Aviões"
L["Airships"] = "Dirigíveis"
L["Albatross"] = "Albatroz"
L["Alpacas"] = "Alpacas"
L["Amphibian"] = "Anfíbios"
L["Animite"] = "Animácaros"
L["Aqir Flyers"] = "Aqir Voadores"
L["Arachnids"] = "Aracnídeos"
L["Armoredon"] = "Armadurado"
L["Assault Wagons"] = "Carroças de Assalto"
L["Basilisks"] = "Basiliscos"
L["Bats"] = "Morcegos"
L["Bears"] = "Ursos"
L["Bees"] = "Abelhas"
L["Beetle"] = "Besouro"
L["Bipedal Cat"] = "Gato Bípede"
L["Birds"] = "Aves"
L["Blood Ticks"] = "Tiques Sangrentos"
L["Boars"] = "Javalis"
L["Book"] = "Livro"
L["Bovids"] = "Bovídeos"
L["Broom"] = "Vassoura"
L["Brutosaurs"] = "Brutossauros"
-- L["Butterflies"] = ""
L["Camels"] = "Camelos"
L["Carnivorans"] = "Carnívoros"
L["Carpets"] = "Tapetes"
L["Cats"] = "Gatos"
L["Cervid"] = "Cervídeo"
L["Chargers"] = "Corcéis"
L["Chickens"] = "Galinhas"
L["Clefthooves"] = "Fenocerontes"
L["Cloud Serpents"] = "Serpentes das Nuvens"
L["Core Hounds"] = "Cães-Magma"
L["Crabs"] = "Caranguejos"
L["Cranes"] = "Garças"
L["Crawgs"] = "Crorgs"
L["Crocolisks"] = "Crocoliscos"
L["Crows"] = "Corvos"
-- L["Darkmoon Chargers"] = ""
L["Demonic Hounds"] = "Cães Demoníacos"
L["Demonic Steeds"] = "Corcéis Demoníacos"
L["Demons"] = "Demônios"
L["Devourer"] = "Devorador"
L["Dinosaurs"] = "Dinossauros"
L["Dire Wolves"] = "Lobos Hediondos"
L["Direhorns"] = "Escornantes"
L["Discs"] = "Discos"
L["Dragonhawks"] = "Falcodragos"
L["Drakes"] = "Dracos"
L["Dread Ravens"] = "Corvos Medonhos"
L["Dreamsaber"] = "Sabre-do-sonho"
L["Eagle"] = "Águia"
-- L["Eels"] = ""
L["Elekks"] = "Elekks"
L["Elementals"] = "Elementais"
L["Falcosaurs"] = "Falcossauros"
L["Fathom Rays"] = "Raias-Profundas"
L["Feathermanes"] = "Aquifélix"
L["Felsabers"] = "Sabrevis"
L["Fish"] = "Peixe"
L["Flies"] = "Moscas"
L["Flying Steeds"] = "Corcéis Voadores"
L["Foxes"] = "Raposas"
L["Gargon"] = "Gargono"
L["Gargoyle"] = "Gárgula"
L["Goats"] = "Bodes"
L["Gorger"] = "Engolidor"
L["Gorm"] = "Gorm"
L["Grand Drakes"] = "Dracos Grandes"
L["Gronnlings"] = "Gronnídeos"
L["Gryphons"] = "Grifos"
L["Gyrocopters"] = "Girocóptero"
L["Hands"] = "Mãos"
L["Hawkstriders"] = "Falcostruzes"
L["Hippogryphs"] = "Hipogrifos"
L["Horned Steeds"] = "Corcéis com Chifres"
L["Horses"] = "Cavalos"
L["Hounds"] = "Cães"
L["Hovercraft"] = "Aerodeslizador"
L["Humanoids"] = "Humanoides"
L["Hyenas"] = "Hienas"
L["Infernals"] = "Infernais"
L["Insects"] = "Insetos"
L["Jellyfish"] = "Água-viva"
L["Jet Aerial Units"] = "Unidades Aéreas a Jato"
L["Kites"] = "Pipas"
L["Kodos"] = "Kodos"
L["Krolusks"] = "Croluscos"
L["Larion"] = "Larião"
L["Lions"] = "Leões"
-- L["Lizards"] = ""
L["Lupine"] = "Lupino"
-- L["Lynx"] = ""
L["Mammoths"] = "Mamutes"
L["Mana Rays"] = "Arraias de Mana"
L["Manasabers"] = "Manassabres"
L["Mauler"] = "Espancador"
L["Mechanical Animals"] = "Animais Mecânicos"
L["Mechanical Birds"] = "Pássaros Mecânicos"
L["Mechanical Cats"] = "Gatos Mecânicos"
L["Mechanical Steeds"] = "Corcéis Mecânicos"
L["Mechanostriders"] = "Mecanostruzes"
L["Mecha-suits"] = "Mecatrajes"
-- L["Meeksi"] = ""
-- L["Mice"] = ""
L["Mollusc"] = "Molusco"
L["Moose"] = "Alce"
L["Moth"] = "Mariposa"
L["Motorcycles"] = "Motocicletas"
L["Mountain Horses"] = "Cavalos da Montanha"
-- L["Mudnose"] = ""
L["Murloc"] = "Murloc"
L["Mushan"] = "Mushan"
L["Nether Drakes"] = "Dracos Etéreos"
L["Nether Rays"] = "Arraias Etéreas"
L["N'Zoth Serpents"] = "Serpentes de N'Zoth"
L["Others"] = "Outros"
L["Ottuk"] = "Lontruk"
L["Owl"] = "Coruja"
L["Owlbear"] = "Urso Coruja"
L["Ox"] = "Boi"
L["Pandaren Phoenixes"] = "Fênix Pandarênicas"
L["Parrots"] = "Papagaios"
L["Peafowl"] = "Pavão"
L["Phoenixes"] = "Fênix"
L["Proto-Drakes"] = "Protodracos"
L["Pterrordaxes"] = "Pterrordaxes"
L["Quilen"] = "Quílen"
L["Rabbit"] = "Coelho"
L["Rams"] = "Carneiros"
L["Raptora"] = "Raptora"
L["Raptors"] = "Raptores"
L["Rats"] = "Ratos"
L["Rays"] = "Arraias"
L["Razorwing"] = "Talhasa"
L["Reptiles"] = "Répteis"
L["Rhinos"] = "Rinocerontes"
L["Riverbeasts"] = "Feras-do-rio"
L["Roc"] = "Rocas"
L["Rockets"] = "Foguetes"
L["Rodent"] = "Roedor"
L["Ruinstriders"] = "Andarilho das Ruínas"
L["Rylaks"] = "Rylaks"
L["Sabers"] = "Sabres"
L["Scorpions"] = "Escorpiões"
L["Sea Serpents"] = "Serpente Marinha"
L["Seahorses"] = "Cavalos-marinhos"
L["Seat"] = "Assento"
-- L["Shardhides"] = ""
L["Silithids"] = "Silitídeos"
-- L["Skyflayer"] = ""
-- L["Skyrazor"] = ""
L["Slug"] = "Lesma"
L["Snail"] = "Caracol"
L["Snapdragons"] = "Dracoliscos"
L["Spider Tanks"] = "Tanques Aranha"
L["Spiders"] = "Aranhas"
L["Sporebat"] = "Quirósporo"
L["Stag"] = "Cervo"
L["Steeds"] = "Corcéis"
L["Stingrays"] = "Arraias Aguilhantes"
L["Stone Cats"] = "Gatos de Pedra"
L["Stone Drakes"] = "Dracos de Pedra"
-- L["Surfboard"] = ""
L["Talbuks"] = "Talbulques"
L["Tallstriders"] = "Moas"
L["Talonbirds"] = "Pássaros-garra"
L["Tauralus"] = "Tauralus"
L["Thunder Lizard"] = "Lagarto Trovejante"
L["Tigers"] = "Tigres"
L["Toads"] = "Sapos"
L["Turtles"] = "Tartarugas"
L["Undead Drakes"] = "Dracos Mortos-vivos"
L["Undead Steeds"] = "Corcéis Mortos-vivos"
L["Undead Wolves"] = "Lobos Mortos-vivos"
-- L["Undercrawlers"] = ""
-- L["Underlights"] = ""
L["Ungulates"] = "Ungulados"
L["Ur'zul"] = "Ur'zul"
L["Vehicles"] = "Veículos"
L["Vombata"] = "Vombate"
L["Vulpin"] = "Vulpino"
L["Vultures"] = "Abutres"
L["War Wolves"] = "Lobos de Guerra"
L["Wasp"] = "Vespa"
L["Water Striders"] = "Caminhante das Águas"
L["Wilderlings"] = "Silvestritos"
L["Wind Drakes"] = "Dracos do Vento"
L["Wolfhawks"] = "Falcolobos"
L["Wolves"] = "Lobos"
L["Wyverns"] = "Mantícoras"
L["Yaks"] = "Iaques"
L["Yetis"] = "Yetis"