if GetLocale() ~= "ruRU" then
	return
end

local _, ns = ...
local L = ns.L

L["author"] = "Автор"
L["Main"] = "Основные"
L["ConfigPanelTitle"] = "Глобальные настройки"
L["Class settings"] = "Настройки классов"
L["Modifier"] = "Модификатор"
L["Normal mount summon"] = "Обычный призыв средства передвижения."
L["SecondMountTooltipTitle"] = "Если зажат модификатор или использован \"%s 2\":"
L["SecondMountTooltipDescription"] = "Eсли вы находитесь в воде призывается не водоплавающее средство передвижения.\n\nEсли вы на суше и можете летать, то призывается наземное средство передвижения."
L["Drag to create a summon panel"] = "Перетащите чтобы создать панель призыва"
L["UseBindingTooltip"] = "Используйте настройки для привязки клавиш"
L["Summon panel"] = "Панель призыва"
L["Left-button to drag"] = "Левая кнопка чтобы перетащить"
L["Right-button to open context menu"] = "Правая кнопка чтобы открыть контекстное меню"
L["Fade out (opacity)"] = "Исчезновение (прозрачность)"
L["Button size"] = "Размер кнопки"
L["Strata of panel"] = "Слой панели"
L["Reset size"] = "Сбросить размер"
L["ZoneSettingsTooltip"] = "Возможности настройки зоны"
L["ZoneSettingsTooltipDescription"] = "Создание списка маунтов для зоны.\n\nНастройка флагов зоны.\n\nНастройка связей для использования одного списка маунтов в разных зонах."
L["ButtonsSelectedTooltipDescription"] = "Кнопки сбоку выбирают маунтов по типу для вызова в соответствующих условиях.\n\nИзбранные не влияют на вызов маунтов при помощи %s."
L["ProfilesTooltipDescription"] = "Настройки профилей, профиль управляет списками выбранных маунтов, настройками зон и питомцев."
L["SettingsTooltipDescription"] = "Ознакомьтесь с настройками, а так же создайте макрос или привяжите клавиши для использования %s."
L["Handle a jump in water"] = "Отслеживать прыжки в воде"
L["WaterJumpDescription"] = "После прыжка в воде будет призываться не подводный маунт."
L["UseHerbMounts"] = "Использовать маунта для сбора травы"
L["UseHerbMountsDescription"] = "Если изучено травничество, то используется подходящее средство передвижения, если оно доступно."
L["UseHerbMountsOnZones"] = "Только в зонах со сбором трав"
L["Herb Gathering"] = "Сбор трав"
L["HerbGatheringFlagDescription"] = "Используется при использовании маунта для сбора травы."
L["If item durability is less than"] = "Если прочность вещи меньше"
L["In flyable zones"] = "В полетных зонах"
L["UseRepairMountsDescription"] = "Если прочность хотя бы одного предмета меньше указанного процента, будет вызвано выбранное средство передвижения."
L["If the number of free slots in bags is less"] = "Если число свободных слотов в сумках меньше"
L["Random available mount"] = "Случайный доступный маунт"
L["UseHallowsEndMounts"] = "Использовать маунтов \"Тыквовина\""
L["UseHallowsEndMountsDescription"] = "Во время празднования \"Тыквовина\", если у вас есть его маунты, то будут использоваться они."
L["Use %s"] = "Использовать %s"
L["Use automatically"] = "Использовать автоматически"
L["UseUnderlightAnglerDescription"] = "Использовать Удочку Темносвета вместо подводных маунтов."
L["A macro named \"%s\" already exists, overwrite it?"] = "Макрос с именем \"%s\" уже существует, перезаписать его?"
L["CreateMacro"] = "Создать макрос"
L["CreateMacroTooltip"] = "Созданный макрос используется для призыва выбранных средств передвижения."
L["or key bind"] = "или назначить клавишу"
L["ERR_MOUNT_NO_SELECTED"] = "У вас нет выбранного средства передвижения, подходящего для езды по этой зоне."
L["Collected:"] = "Собрано:"
L["Shown:"] = "Показано:"
L["hidden for character"] = "Скрытые для персонажа"
L["only hidden"] = "Только скрытые"
L["Hidden by player"] = "Скрытые игроком"
L["Only new"] = "Только новые"
L["types"] = "Типы"
L["selected"] = "Выбранные"
L["MOUNT_TYPE_1"] = "Летающие"
L["MOUNT_TYPE_2"] = "Наземные"
L["MOUNT_TYPE_3"] = "Подводные"
L["MOUNT_TYPE_4"] = "Не выбранные"
L["Specific"] = "Специфичные"
L["repair"] = "С починкой"
L["passenger"] = "Пассажирские"
L["Ride Along"] = "С совместной поездкой"
L["transform"] = "Трасформирующие"
L["Multiple Models"] = "Несколько моделей"
L["additional"] = "Дополнительные"
L["rest"] = "Остальные"
L["factions"] = "Фракции"
L["MOUNT_FACTION_1"] = "Орда"
L["MOUNT_FACTION_2"] = "Альянс"
L["MOUNT_FACTION_3"] = "Обе"
L["sources"] = "Источники"
L["PET_1"] = "Со случайным избранным питомцем"
L["PET_2"] = "Со случайным питомцем"
L["PET_3"] = "С питомцем"
L["PET_4"] = "Без питомца"
L["expansions"] = "Дополнения"
L["Rarity"] = "Редкость"
L["Chance of summoning"] = "Шанс призыва"
L["Any"] = "Любой"
L["> (more than)"] = "> (больше чем)"
L["< (less than)"] = "< (меньше чем)"
L["= (equal to)"] = "= (равен)"
L["sorting"] = "Сортировка"
L["Reverse Sort"] = "Обратная сортировка"
L["Collected First"] = "Полученные вначале"
L["Favorites First"] = "Избранные вначале"
L["Additional First"] = "Допоплнительные вначале"
L["Set current filters as default"] = "Установить текущие фильтры по умолчанию"
L["Restore default filters"] = "Восстановить фильтры по умолчанию"
L["Enable Acceleration around the X-axis"] = "Включить акселерацию вокруг оси X"
L["Initial x-axis accseleration"] = "Начальная акселерация по оси X"
L["X-axis accseleration"] = "Акселерация по оси X"
L["Minimum x-axis speed"] = "Минимальная скорость по оси X"
L["Enable Acceleration around the Y-axis"] = "Включить акселерацию вокруг оси Y"
L["Initial y-axis accseleration"] = "Начальная акселерация по оси Y"
L["Y-axis accseleration"] = "Акселерация по оси Y"
L["Minimum y-axis speed"] = "Минимальная скорость по оси Y"
L["Model"] = "Модель"
L["Map"] = "Карта"
L["Map flags"] = "Флаги карты"
L["Settings"] = "Настройки"
L["Dungeons and Raids"] = "Подземелья и рейды"
L["Current Location"] = "Текущее местоположение"
L["Enable Flags"] = "Включить флаги"
L["Ground Mounts Only"] = "Только наземные средства передвижения"
L["Water Walking"] = "Хождение по воде"
L["WaterWalkFlagDescription"] = "Используется для настройки некоторых классов."
L["ListMountsFromZone"] = "Использовать список маунтов из зоны"
L["No relation"] = "Нет связи"
L["Zones with list"] = "Зоны со списком"
L["Zones with relation"] = "Зоны со связью"
L["Zones with flags"] = "Зоны со флагами"
L["CHARACTER_CLASS_DESCRIPTION"] = "(настройки персонажа перекрывают настройки класса)"
L["HELP_MACRO_MOVE_FALL"] = "Этот макрос используется, если вы находитесь в помещении или двигаетесь, и у вас нет волшебной метлы, или она выключена."
L["HELP_MACRO_COMBAT"] = "Этот макрос используется, если вы находитесь в бою."
L["CLASS_USEWHENCHARACTERFALLS"] = "Использовать %s когда персонаж падает"
L["CLASS_USEWATERWALKINGSPELL"] = "Использовать %s при вызове наземного средства передвижения"
L["CLASS_USEONLYWATERWALKLOCATION"] = "Использовать только в зонах с хождением по воде"
L["DRUID_USELASTDRUIDFORM"] = "Вернуть последнюю форму при спешивании"
L["DRUID_USEDRUIDFORMSPECIALIZATION"] = "Вернуть форму специализации"
L["DRUID_USEMACROALWAYS"] = "Использовать этот макрос вместо средств передвижения"
L["Collected by %s of players"] = "Есть у %s игроков"
L["Summonable Battle Pet"] = "Призываемый питомец"
L["Summon Random Battle Pet"] = "Призвать случайного питомца"
L["No Battle Pet"] = "Нет питомца"
L["Summon a pet every"] = "Призывать питомца каждые"
L["min"] = "мин"
L["Summon only favorites"] = "Призывать только избранных"
L["NoPetInRaid"] = "Не призывать питомца если вы находитесь в рейдовой группе"
L["NoPetInGroup"] = "Не призывать питомца если вы находитесь в группе"
L["CopyMountTarget"] = "Попытаться скопировать маунта цели"
L["Colored mount names by rarity"] = "Цветные названия маунтов по редкости"
L["Enable arrow buttons to browse mounts"] = "Включить кнопки со стрелками для перемещения по маунтам"
L["Open links in %s"] = "Открывать ссылки в %s"
L["Click opens in"] = "Клик открывает в"
L["Show wowhead link in mount preview"] = "Показывать ссылку на wowhead в предпросмотре средств передвижения"
L["Rule Sets"] = "Наборы правил"
L["New rule set"] = "Новый набор правил"
L["A rule set with the same name exists."] = "Набор правил с таким именем уже существует."
L["Are you sure you want to delete rule set %s?"] = "Вы действительно хотите удалить набор правил %s?"
L["Set as default"] = "Установить по умолчанию"
L["Rules"] = "Правила"
L["RULES_TITLE"] = "Правила призыва маунтов. Правила проверяются по порядку, и первое правило в котором все условия совпадут выполнит действие."
L["Add Rule"] = "Добавить правило"
L["Reset Rules"] = "Сбросить правила"
L["Remove Rule %d"] = "Удалить правило %d"
L["NOT_CONDITION"] = "Не"
L["Conditions"] = "Условия"
L["Action"] = "Действие"
L["Edit Rule"] = "Редактировать правило"
L["ANY_MODIFIER"] = "Любой"
L["Macro condition"] = "Условие макроса"
L["Mouse button"] = "Кнопка мыши"
L["Zone type"] = "Тип зоны"
L["Nameless holiday"] = "Безымянный праздник"
L["Flight style"] = "Стиль полета"
L["Steady Flight"] = "Спокойный полет"
L["Flyable area"] = "Полетная зона"
L["Have item"] = "Есть предмет"
L["Item is ready"] = "Предмет готов"
L["Spell is known"] = "Заклинание известно"
L["Spell is ready"] = "Заклинание готово"
L["Zone Name/Subzone Name"] = "Название зоны/Название подзоны"
L["The player has a buff"] = "Игрок имеет бафф"
L["The player has a debuff"] = "Игрок имеет дебафф"
L["The player is falling"] = "Игрок падает"
L["The player is moving"] = "Игрок двигается"
L["The player is indoors"] = "Игрок в помещении"
L["The player is swimming"] = "Игрок плывет"
L["The player is mounted"] = "Игрок на маунте"
L["The player is within an vehicle"] = "Игрок в транспорте"
L["The player is dead"] = "Игрок мертв"
L["Sex"] = "Пол"
L["Talent loadout"] = "Макет талантов"
L["Get State"] = "Получить состояние"
L["Get a state that can be set in actions using \"Set State\""] = "Получить состояние, которое можно установить в действиях с помощью \"Установить состояние\""
L["Set State"] = "Установить состояние"
L["Set a state that can be read in conditions using \"Get State\""] = "Установить состояние, которое можно считать в условиях с помощью \"Получить состояние\""
L["Random Mount"] = "Случайный маунт"
L["Selected profile"] = "Выбранный профиль"
L["Random Mount by Rarity"] = "Случайный маунт по редкости"
L["The lower the rarity, the higher the chance"] = "Ниже редкость, выше шанс"
L["Mount"] = "Маунт"
L["Use Item"] = "Использовать предмет"
L["Use Inventory Item"] = "Использовать предмет инвентаря"
L["Cast Spell"] = "Прочитать заклинание"
L["Use macro before mounting"] = "Использовать макрос перед маунтом"
L["PMACRO_DESCRIPTION"] = "Регистрирует макрос для использования перед маунтом"
L["About"] = "О аддоне"
L["Help with translation of %s. Thanks."] = "Помогите с переводом %s. Спасибо."
L["Localization Translators:"] = "Переводчики локализаций:"
-- ANIMATIONS
L["Default"] = "По умолчанию"
L["Mount special"] = "Особая"
L["Walk"] = "Идти"
L["Walk backwards"] = "Идти назад"
L["Run"] = "Бежать"
L["Swim idle"] = "Плавать на месте"
L["Swim"] = "Плыть"
L["Swim backwards"] = "Плыть назад"
L["Fly stand"] = "Полет на месте"
L["Fly"] = "Полет"
L["Fly backwards"] = "Полет назад"
L["Loop"] = "Повтор"
L["Are you sure you want to delete animation %s?"] = "Вы уверены, что хотите удалить анимацию \"%s\"?"
-- PROFILES
L["Profiles"] = "Профили"
L["New profile"] = "Новый профиль"
L["Create"] = "Создать"
L["Copy current"] = "Копировать текущий"
L["A profile with the same name exists."] = "Профиль с таким именем уже существует."
L["Profile settings"] = "Настройки профиля"
L["Pet binding from default profile"] = "Привязка питомцев из профиля по умолчанию"
L["Zones settings from default profile"] = "Настройки зон из профиля по умолчанию"
L["Auto add new mounts to selected"] = "Автоматически добавлять новых маунтов в выбранные"
L["Select all filtered mounts by type in the selected zone"] = "Выбрать всех отфильтрованных маунтов по типу в выбранной зоне"
L["Unselect all filtered mounts in the selected zone"] = "Отменить выбор всех отфильтрованных маунтов в выбранной зоне"
L["Select all favorite mounts by type in the selected zone"] = "Выбрать всех избранных маунтов по типу в выбранной зоне"
L["Select all mounts by type in selected zone"] = "Выбрать всех маунтов по типу в выбранной зоне"
L["Unselect all mounts in selected zone"] = "Отменить выбор всех маунтов в выбранной зоне"
L["Are you sure you want to delete profile %s?"] = "Вы уверены, что хотите удалить профиль \"%s\"?"
L["Are you sure you want %s?"] = "Вы уверены, что хотите \"%s\"?"
-- TAGS
L["tags"] = "Теги"
L["No tag"] = "Без тегов"
L["With all tags"] = "Со всеми тегами"
L["Add tag"] = "Добавить тег"
L["Tag already exists."] = "Тег уже существует."
L["Are you sure you want to delete tag %s?"] = "Вы уверены, что хотите удалить тег \"%s\"?"
-- FAMILY
L["Family"] = "Семейства"
L["Airplanes"] = "Самолеты"
L["Airships"] = "Воздушные Судна"
L["Albatross"] = "Альбатросы"
L["Alpacas"] = "Альпаки"
L["Amphibian"] = "Амфибии"
L["Animite"] = "Анимаклещи"
L["Aqir Flyers"] = "Акиры Летуны"
L["Arachnids"] = "Арахниды"
L["Armoredon"] = "Бронедоны"
L["Assault Wagons"] = "Штурмовые Повозки"
L["Basilisks"] = "Василиски"
L["Bats"] = "Летучие мыши"
L["Bears"] = "Медведи"
L["Bees"] = "Пчелы"
L["Beetle"] = "Жуки"
L["Bipedal Cat"] = "Ящеры из Сна"
L["Birds"] = "Птицы"
L["Blood Ticks"] = "Кровяной Клещ"
L["Boars"] = "Кабаны"
L["Book"] = "Книги"
L["Bovids"] = "Полорогие"
L["Broom"] = "Метлы"
L["Brutosaurs"] = "Брутозавры"
L["Camels"] = "Верблюды"
L["Carnivorans"] = "Плотоядные"
L["Carpets"] = "Ковры"
L["Cats"] = "Кошки"
L["Cervid"] = "Сервиды"
L["Chargers"] = "Боевые"
L["Chickens"] = "Курицы"
L["Clefthooves"] = "Копытни"
L["Cloud Serpents"] = "Облачные Змеи"
L["Core Hounds"] = "Гончие Недр"
L["Crabs"] = "Крабы"
L["Cranes"] = "Журавли"
L["Crawgs"] = "Кроги"
L["Crocolisks"] = "Кроколиски"
L["Crows"] = "Вороны"
L["Demonic Hounds"] = "Демонические Гончие"
L["Demonic Steeds"] = "Демонические Скакуны"
L["Demons"] = "Демонические"
L["Devourer"] = "Пожиратели"
L["Dinosaurs"] = "Динозавры"
L["Dire Wolves"] = "Лютоволки"
L["Direhorns"] = "Дикороги"
L["Discs"] = "Диски"
L["Dragonhawks"] = "Дракондоры"
L["Drakes"] = "Драконы"
L["Dread Ravens"] = "Грозные вороны"
L["Dreamsaber"] = "Саблезубы из Сна"
L["Eagle"] = "Орлы"
L["Elekks"] = "Элекки"
L["Elementals"] = "Элементали"
L["Falcosaurs"] = "Грифозавры"
L["Fathom Rays"] = "Глубинные Скаты"
L["Feathermanes"] = "Пернатые"
L["Felsabers"] = "Саблезубы"
L["Fish"] = "Рыбы"
L["Flies"] = "Мухи"
L["Flying Steeds"] = "Летающие Скакуны"
L["Foxes"] = "Лисы"
L["Gargon"] = "Гаргоны"
L["Gargoyle"] = "Гаргульи"
L["Goats"] = "Козлы"
L["Gorger"] = "Поглотители"
L["Gorm"] = "Гормы"
L["Grand Drakes"] = "Великие Драконы"
L["Gronnlings"] = "Малые гронны"
L["Gryphons"] = "Грифоны"
L["Gyrocopters"] = "Гирокоптеры"
L["Hands"] = "Руки"
L["Hawkstriders"] = "Крылобеги"
L["Hippogryphs"] = "Гиппогрифы"
L["Horned Steeds"] = "Рогатые Скакуны"
L["Horses"] = "Скакуны"
L["Hounds"] = "Гончие"
L["Hovercraft"] = "Везделеты"
L["Humanoids"] = "Гуманоиды"
L["Hyenas"] = "Гиены"
L["Infernals"] = "Инферналы"
L["Insects"] = "Насекомые"
L["Jellyfish"] = "Медузы"
L["Jet Aerial Units"] = "Реактивные Воздушные"
L["Kites"] = "Воздушные Змеи"
L["Kodos"] = "Кодо"
L["Krolusks"] = "Кролуски"
L["Larion"] = "Ларионы"
L["Lions"] = "Львы"
L["Lupine"] = "Люпины"
L["Lynx"] = "Рыси"
L["Mammoths"] = "Мамонты"
L["Mana Rays"] = "Манаскаты"
L["Manasabers"] = "Манапарды"
L["Mauler"] = "Терзатели"
L["Mechanical Animals"] = "Механические Животные"
L["Mechanical Birds"] = "Механические Птицы"
L["Mechanical Cats"] = "Механические Кошки"
L["Mechanical Steeds"] = "Механические Скакуны"
L["Mechanostriders"] = "Механодолгоноги"
L["Mecha-suits"] = "Мехакостюмы"
L["Mollusc"] = "Моллюски"
L["Moose"] = "Лоси"
L["Moth"] = "Мотыльки"
L["Motorcycles"] = "Мотоциклы"
L["Mountain Horses"] = "Горные Скакуны"
L["Mudnose"] = "Грязеносы"
L["Murloc"] = "Мурлоки"
L["Mushan"] = "Мушаны"
L["Nether Drakes"] = "Драконы Пустоты"
L["Nether Rays"] = "Скаты Пустоты"
L["N'Zoth Serpents"] = "Черви Н'Зота"
L["Others"] = "Прочие"
L["Ottuk"] = "Выдреки"
L["Owl"] = "Совы"
L["Owlbear"] = "Совомедведи"
L["Ox"] = "Волы"
L["Pandaren Phoenixes"] = "Пандаренские Фениксы"
L["Parrots"] = "Попугаи"
L["Peafowl"] = "Павлины"
L["Phoenixes"] = "Фениксы"
L["Proto-Drakes"] = "Протодраконы"
L["Pterrordaxes"] = "Терродактили"
L["Quilen"] = "Цийлини"
L["Rabbit"] = "Кролики"
L["Rams"] = "Бараны"
L["Raptora"] = "Рапторы"
L["Raptors"] = "Ящеры"
L["Rats"] = "Крысы"
L["Rays"] = "Скаты"
L["Razorwing"] = "Острокрылы"
L["Reptiles"] = "Рептилии"
L["Rhinos"] = "Носороги"
L["Riverbeasts"] = "Речные чудовища"
L["Roc"] = "Рухи"
L["Rockets"] = "Ракеты"
L["Rodent"] = "Грызуны"
L["Ruinstriders"] = "Скитальцы"
L["Rylaks"] = "Рилаки"
L["Sabers"] = "Саблезубы"
L["Scorpions"] = "Скорпионы"
L["Sea Serpents"] = "Морские Змеи"
L["Seahorses"] = "Морские коньки"
L["Seat"] = "Повозки"
L["Shardhides"] = "Кристаллошкуры"
L["Silithids"] = "Силитиды"
L["Skyflayer"] = "Неборезы"
L["Skyrazor"] = "Рассекатели небес"
L["Slug"] = "Слизняки"
L["Snail"] = "Улитки"
L["Snapdragons"] = "Вараны"
L["Spider Tanks"] = "Механопауки"
L["Spiders"] = "Пауки"
L["Sporebat"] = "Спороскат"
L["Stag"] = "Олени"
L["Steeds"] = "Кони"
L["Stingrays"] = "Жалохвосты"
L["Stone Cats"] = "Каменные Кошки"
L["Stone Drakes"] = "Каменные Драконы"
L["Surfboard"] = "Доски для серфинга"
L["Talbuks"] = "Талбуки"
L["Tallstriders"] = "Долгоноги"
L["Talonbirds"] = "Когти"
L["Tauralus"] = "Тауралы"
L["Thunder Lizard"] = "Громоспины"
L["Tigers"] = "Тигры"
L["Toads"] = "Жабы"
L["Turtles"] = "Черепахи"
L["Undead Drakes"] = "Драконы Нежить"
L["Undead Steeds"] = "Скакуны Нежить"
L["Undead Wolves"] = "Волки Нежить"
L["Undercrawlers"] = "Подземные ползуны"
L["Underlights"] = "Удильщики"
L["Ungulates"] = "Копытные"
L["Ur'zul"] = "Ур'зул"
L["Vehicles"] = "Транспортные средства"
L["Vombata"] = "Вомбаты"
L["Vulpin"] = "Лисохвосты"
L["Vultures"] = "Падальщики"
L["War Wolves"] = "Боевые Волки"
L["Wasp"] = "Осы"
L["Water Striders"] = "Водные долгоноги"
L["Wilderlings"] = "Чащобники"
L["Wind Drakes"] = "Драконы Ветра"
L["Wolfhawks"] = "Звероястребы"
L["Wolves"] = "Волки"
L["Wyverns"] = "Виверны"
L["Yaks"] = "Яки"
L["Yetis"] = "Йети"