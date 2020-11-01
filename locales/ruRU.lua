if GetLocale() ~= "ruRU" then
	return
end

local _, L = ...

L["author"] = "Автор"
L["%s Configuration"] = "Конфигурация %s"
L["ConfigPanelTitle"] = "Глобальные настройки"
L["Class settings"] = "Настройки классов"
L["Modifier"] = "Модификатор"
L["SecondMountTooltipTitle"] = "Если зажат модификатор или использован \"%s 2\":"
L["SecondMountTooltipDescription"] = "\nEсли вы находитесь в воде призывается не водоплавающее средство передвижения.\n\nEсли вы на суше и можете летать, то призывается наземное средство передвижения."
L["ZoneSettingsTooltip"] = "Возможности настройки зоны"
L["ZoneSettingsTooltipDescription"] = "\nСоздание списка маунтов для зоны.\n\nНастройка флагов зоны.\n\nНастройка связей для использования одного списка маунтов в разных зонах."
L["Handle a jump in water"] = "Отслеживать прыжки в воде"
L["WaterJumpDescription"] = "После прыжка в воде будет призываться не подводный маунт."
L["UseHerbMounts"] = "Использовать маунта для сбора травы"
L["UseHerbMountsDescription"] = "Если изучено травничество, то используется подходящее средство передвижения, если оно доступно."
L["UseHerbMountsOnZones"] = "Только в зонах со сбором трав"
L["Herb Gathering"] = "Сбор трав"
L["HerbGatheringFlagDescription"] = "Используется при использовании маунта для сбора травы."
L["UseMagicBroom"] = "Использовать %s"
L["UseMagicBroomTitle"] = "Использовать волшебную метлу"
L["UseMagicBroomDescription"] = "Во время празднования \"Тыквовина\", если у вас есть \"Волшебная метла\", то она будет использоваться вместо воздушных и наземных средств передвижения."
L["CreateMacro"] = "Создать макрос"
L["CreateMacroTooltip"] = "Созданный макрос используется для призыва выбранных средств передвижения."
L["or key bind"] = "или назначить клавишу"
L["Collected:"] = "Собрано:"
L["Settings"] = "Настройки"
L["Shown:"] = "Показано:"
L["hidden for character"] = "Скрытые для персонажа"
L["types"] = "Типы"
L["selected"] = "Выбранные"
L["MOUNT_TYPE_1"] = "Летающие"
L["MOUNT_TYPE_2"] = "Наземные"
L["MOUNT_TYPE_3"] = "Подводные"
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
L["sorting"] = "Сортировка"
L["Reverse Sort"] = "Обратная сортировка"
L["Favorites First"] = "Избранные вначале"
L["Map / Model"] = "Карта / Модель"
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
L["DEATHKNIGHT_USEPATHOFFROST"] = "Использовать %s при вызове наземного средства передвижения"
L["DEATHKNIGHT_USEONLYINWATERWALKLOCATION"] = "Использовать только в зонах с хождением по воде"
L["SHAMAN_USEWATERWALKING"] = "Использовать %s при вызове наземного средства передвижения"
L["SHAMAN_USEONLYINWATERWALKLOCATION"] = "Использовать только в зонах с хождением по воде"
L["DRUID_USELASTDRUIDFORM"] = "Вернуть последнюю форму при спешивании"
L["DRUID_USEDRUIDFORMSPECIALIZATION"] = "Вернуть форму специализации"
L["DRUID_USEMACROALWAYS"] = "Использовать этот макрос вместо средств передвижения"
L["Summonable Battle Pet"] = "Призываемый питомец"
L["Summon Random Battle Pet"] = "Призвать случайного питомца"
L["No Battle Pet"] = "Нет питомца"
L["NoPetInRaid"] = "Не призывать питомца если вы находитесь в рейдовой группе"
L["NoPetInGroup"] = "Не призывать питомца если вы находитесь в группе"
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
L["By Specialization"] = "По специализации"
L["Profile settings"] = "Настройки профиля"
L["Pet binding from default profile"] = "Привязка питомцев из профиля по умолчанию"
L["Zones settings from default profile"] = "Настройки зон из профиля по умолчанию"
L["Select all mounts by type in selected zone"] = "Выбрать всех маунтов по типу в выбранной зоне"
L["Unselect all mounts in selected zone"] = "Отменить выбор всех маунтов в выбранной зоне"
L["Are you sure you want to delete profile %s?"] = "Вы уверены, что хотите удалить профиль \"%s\"?"
L["Are you sure you want %s?"] = "Вы уверен, что хотите \"%s\"?"
-- TAGS
L["tags"] = "Теги"
L["No tag"] = "Без тегов"
L["With all tags"] = "Со всеми тегами"
L["Add tag"] = "Добавить тег"
L["Tag already exists."] = "Тег уже существует."
L["Are you sure you want to delete tag %s?"] = "Вы уверены, что хотите удалить тег \"%s\"?"