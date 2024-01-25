if GetLocale() ~= "zhTW" then
	return
end

local _, L = ...

L["author"] = "作者"
L["%s Configuration"] = "%s 配置"
L["ConfigPanelTitle"] = "全局設定"
L["Class settings"] = "職業設定"
L["Modifier"] = "快捷鍵"
L["Normal mount summon"] = "普通坐騎召喚."
-- L["SecondMountTooltipTitle"] = ""
-- L["SecondMountTooltipDescription"] = ""
-- L["ThirdMountTooltipDescription"] = ""
L["ZoneSettingsTooltip"] = "區域設置功能"
L["ZoneSettingsTooltipDescription"] = "為該區創建一個坐騎列表.\n配置區域標志.\n設置關聯以在不同的區使用一個坐騎列表."
L["ButtonsSelectedTooltipDescription"] = "側面的按鈕按類型選擇坐騎, 在適當的條件下召喚.\n偏好不影響使用%s召喚坐騎."
-- L["ProfilesTooltipDescription"] = ""
-- L["SettingsTooltipDescription"] = ""
L["Handle a jump in water"] = "處理水中的跳躍"
-- L["WaterJumpDescription"] = ""
-- L["UseHerbMounts"] = ""
-- L["UseHerbMountsDescription"] = ""
-- L["UseHerbMountsOnZones"] = ""
L["Herb Gathering"] = "草藥採集"
L["HerbGatheringFlagDescription"] = "用於設置草藥學使用的坐騎。"
L["If item durability is less than"] = "如果物品耐久度低於"
L["In flyable zones"] = "在可飛行區域"
-- L["UseRepairMountsDescription"] = ""
L["Random available mount"] = "隨機可用坐騎"
-- L["UseHallowsEndMounts"] = ""
-- L["UseHallowsEndMountsDescription"] = ""
-- L["Use %s"] = ""
-- L["Use automatically"] = ""
-- L["UseUnderlightAnglerDescription"] = ""
L["A macro named \"%s\" already exists, overwrite it?"] = "一個名為\"%s\"的巨集已經存在, 將其覆蓋？"
L["CreateMacro"] = "建立巨集"
L["CreateMacroTooltip"] = "創建的巨集用於召喚選定的坐騎。"
L["or key bind"] = "或綁定按鍵"
L["Collected:"] = "已收藏"
L["Settings"] = "設定"
L["Shown:"] = "顯示:"
-- L["With multiple models"] = ""
L["hidden for character"] = "隱藏角色"
L["only hidden"] = "僅隱藏"
L["Hidden by player"] = "被玩家隱藏"
L["Only new"] = "僅限新的"
L["types"] = "類型"
L["selected"] = "選定"
L["MOUNT_TYPE_1"] = "飛行"
L["MOUNT_TYPE_2"] = "陸地"
L["MOUNT_TYPE_3"] = "水下"
-- L["MOUNT_TYPE_4"] = ""
L["factions"] = "陣營"
L["MOUNT_FACTION_1"] = "部落"
L["MOUNT_FACTION_2"] = "聯盟"
L["MOUNT_FACTION_3"] = "兩者皆有"
L["sources"] = "來源"
L["PET_1"] = "與隨機最愛的寵物"
L["PET_2"] = "與隨機的寵物"
L["PET_3"] = "以及寵物"
L["PET_4"] = "不要寵物"
L["expansions"] = "資料片"
-- L["Rarity"] = ""
L["Chance of summoning"] = "召喚幾率"
L["Any"] = "任何"
L["> (more than)"] = "> (大於)"
L["< (less than)"] = "< (小於)"
L["= (equal to)"] = "= (等於)"
-- L["sorting"] = ""
L["Reverse Sort"] = "反向排序"
L["Favorites First"] = "偏好優先"
-- L["Dragonriding First"] = ""
-- L["Set current filters as default"] = ""
L["Restore default filters"] = "恢復默認過濾"
-- L["Enable Acceleration around the X-axis"] = ""
-- L["Initial x-axis accseleration"] = ""
-- L["X-axis accseleration"] = ""
-- L["Minimum x-axis speed"] = ""
-- L["Enable Acceleration around the Y-axis"] = ""
-- L["Initial y-axis accseleration"] = ""
-- L["Y-axis accseleration"] = ""
-- L["Minimum y-axis speed"] = ""
L["Map / Model"] = "地圖 / 模組"
L["Dungeons and Raids"] = "地下城與團隊"
L["Current Location"] = "當前位置"
L["Enable Flags"] = "啟用標記"
-- L["Regular Flying Mounts Only"] = ""
L["Ground Mounts Only"] = "僅限陸地坐騎"
L["Water Walking"] = "水上行走"
-- L["WaterWalkFlagDescription"] = ""
L["ListMountsFromZone"] = "使用區域中的坐騎列表"
L["No relation"] = "無關聯"
L["Zones with list"] = "區域與表列"
L["Zones with relation"] = "區域與陣營"
L["Zones with flags"] = "區域與旗幟"
L["CHARACTER_CLASS_DESCRIPTION"] = "(角色設定覆蓋職業設定)"
L["HELP_MACRO_MOVE_FALL"] = "如果您在室內或正在移動，並且沒有魔術掃帚或將其關閉，則將運行此巨集。"
L["HELP_MACRO_COMBAT"] = "如果您在戰鬥中，將運行此巨集。"
L["CLASS_USEWHENCHARACTERFALLS"] = "當角色掉落時使用%s"
L["CLASS_USEWATERWALKINGSPELL"] = "召喚地面坐騎時使用％s"
L["CLASS_USEONLYWATERWALKLOCATION"] = "僅在水上行走區使用"
L["DRUID_USELASTDRUIDFORM"] = "當解除坐騎時返回上一個"
L["DRUID_USEDRUIDFORMSPECIALIZATION"] = "返回一個專精從"
L["DRUID_USEMACROALWAYS"] = "使用此巨集而不是坐騎"
-- L["DRUID_USEIFNOTDRAGONRIDABLE"] = ""
-- L["Collected by %s of players"] = ""
L["Summonable Battle Pet"] = "可召喚戰鬥寵物"
L["Summon Random Battle Pet"] = "召喚隨機戰鬥寵物"
L["No Battle Pet"] = "非戰鬥寵物"
-- L["Summon a pet every"] = ""
-- L["min"] = ""
-- L["Summon only favorites"] = ""
L["NoPetInRaid"] = "團隊中不要召喚戰鬥寵物"
L["NoPetInGroup"] = "隊伍中不要召喚戰鬥寵物"
L["CopyMountTarget"] = "嘗試複製目標的坐騎"
-- L["Colored mount names by rarity"] = ""
L["Enable arrow buttons to browse mounts"] = "啟用箭頭按鈕來瀏覽坐騎"
L["Open links in %s"] = "在%s中打開鏈接"
L["Click opens in"] = "點擊打開到"
-- L["Show wowhead link in mount preview"] = ""
L["About"] = "關於"
L["Help with translation of %s. Thanks."] = "幫助翻譯了%s。感謝！"
L["Localization Translators:"] = "本地化翻譯者:"
-- ANIMATIONS
L["Default"] = "預設"
L["Mount special"] = "坐騎特殊動作"
L["Walk"] = "行走"
L["Walk backwards"] = "向後走"
L["Run"] = "奔跑"
L["Swim idle"] = "游泳閒置"
L["Swim"] = "游泳"
L["Swim backwards"] = "向後游"
L["Fly stand"] = "飛行狀態"
L["Fly"] = "飛行"
L["Fly backwards"] = "向後飛"
L["Loop"] = "循環"
L["Are you sure you want to delete animation %s?"] = "你確定要刪除動畫\"%s\"嗎？"
-- PROFILES
L["Profiles"] = "設定檔"
L["New profile"] = "新設定檔"
L["Create"] = "建立"
L["Copy current"] = "複製當前"
L["A profile with the same name exists."] = "具有相同名稱的設定檔已存在。"
L["By Specialization"] = "依據專精"
L["Areans and Battlegrounds"] = "競技場和戰場"
-- L["Profile settings"] = ""
L["Pet binding from default profile"] = "默認配置下的寵物綁定"
-- L["Zones settings from default profile"] = ""
L["Auto add new mounts to selected"] = "自動添加新坐騎到已選擇"
-- L["Select all favorite mounts by type in the selected zone"] = ""
-- L["Select all mounts by type in selected zone"] = ""
-- L["Unselect all mounts in selected zone"] = ""
L["Are you sure you want to delete profile %s?"] = "你確定要刪除配置\"%s\"嗎？"
L["Are you sure you want %s?"] = "你確定你想要\"%s\"嗎？"
-- TAGS
L["tags"] = "標籤"
L["No tag"] = "無標籤"
L["With all tags"] = "包含所有標籤"
L["Add tag"] = "新增標籤"
L["Tag already exists."] = "標籤已存在。"
L["Are you sure you want to delete tag %s?"] = "確定您想要刪除標籤%s嗎？"