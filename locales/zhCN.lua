if GetLocale() ~= "zhCN" then
	return
end

local _, ns = ...
local L = ns.L

L["author"] = "作者"
L["Main"] = "主要"
L["ConfigPanelTitle"] = "全局设置"
L["Class settings"] = "职业设置"
L["Modifier"] = "组合键"
L["Normal mount summon"] = "普通坐骑召唤."
L["SecondMountTooltipTitle"] = "如果组合键保持或\"%s 2\"被使用:"
L["SecondMountTooltipDescription"] = "如果你在水中那么将被召唤出非水下坐骑.\n\n如果你在陆地上并且你能飞那么将被召唤出地面坐骑."
L["Drag to create a summon panel"] = "拖动创建召唤面板"
L["UseBindingTooltip"] = "使用按键绑定设置"
L["Summon panel"] = "召唤面板"
L["Left-button to drag"] = "左键拖拽"
L["Right-button to open context menu"] = "右键打开上下文菜单"
L["Strata of panel"] = "面板层级"
L["Fade out (opacity)"] = "淡出（不透明度变化）"
L["Button size"] = "按钮尺寸"
L["Reset size"] = "重置尺寸"
L["ZoneSettingsTooltip"] = "区域设置功能"
L["ZoneSettingsTooltipDescription"] = "为该区创建一个坐骑列表.\n\n配置区域标志.\n\n设置关联以在不同的区使用一个坐骑列表."
L["ButtonsSelectedTooltipDescription"] = "侧面的按钮按类型选择坐骑, 在适当的条件下召唤.\n\n偏好不影响使用%s召唤坐骑."
L["ProfilesTooltipDescription"] = "配置设置, 配置管理着所选坐骑的列表, 区域和宠物的设置."
L["SettingsTooltipDescription"] = "检查设置, 创建宏或绑定按键来使用%s."
L["Handle a jump in water"] = "跳入水中"
L["WaterJumpDescription"] = "在你跳入水中后, 将被召唤出非水下坐骑."
L["UseHerbMounts"] = "为采药使用坐骑"
L["UseHerbMountsDescription"] = "如果学习了草药学且有合适的坐骑, 就可以使用."
L["UseHerbMountsOnZones"] = "仅在草药采集区"
L["Herb Gathering"] = "采药"
L["HerbGatheringFlagDescription"] = "用来设置草药学使用的坐骑."
L["If item durability is less than"] = "如果物品耐久度低于"
L["In flyable zones"] = "在可飞行区域"
L["UseRepairMountsDescription"] = "如果至少有一件物品的耐久度低于指定的百分比, 所选坐骑将被召唤出来."
L["If the number of free slots in bags is less"] = "如果背包中的空格数量较少"
L["Random available mount"] = "随机可用坐骑"
L["UseHallowsEndMounts"] = "使用“万圣节”坐骑"
L["UseHallowsEndMountsDescription"] = "当“万圣节”世界事件处于活动状态时，如果你有它的坐骑，就会使用它们。"
L["Use %s"] = "使用%s"
L["Use automatically"] = "自动使用"
L["UseUnderlightAnglerDescription"] = "使用幽光鱼竿而不是水下坐骑."
L["A macro named \"%s\" already exists, overwrite it?"] = "一个名为\"%s\"的宏已经存在，是否将其覆盖？"
L["CreateMacro"] = "创建宏"
L["CreateMacroTooltip"] = "创建的宏用于召唤选定的坐骑。"
L["or key bind"] = "或按键绑定"
L["ERR_MOUNT_NO_SELECTED"] = "你没有选择有效的坐骑。"
L["Collected:"] = "已收集"
L["Shown:"] = "显示:"
L["hidden for character"] = "隐藏角色"
L["only hidden"] = "仅隐藏"
L["Hidden by player"] = "被玩家隐藏"
L["Only new"] = "仅限新的"
L["types"] = "类型"
L["selected"] = "已选择"
L["MOUNT_TYPE_1"] = "飞行"
L["MOUNT_TYPE_2"] = "地面"
L["MOUNT_TYPE_3"] = "水下"
L["MOUNT_TYPE_4"] = "未选择"
L["Specific"] = "特定"
L["repair"] = "修复"
L["passenger"] = "乘客"
L["Ride Along"] = "一起骑行"
L["transform"] = "转换"
L["Multiple Models"] = "多种模式"
L["additional"] = "额外的"
L["rest"] = "休息"
L["factions"] = "阵营"
L["MOUNT_FACTION_1"] = "部落"
L["MOUNT_FACTION_2"] = "联盟"
L["MOUNT_FACTION_3"] = "两者都是"
L["sources"] = "来源"
L["PET_1"] = "与随机偏爱宠物"
L["PET_2"] = "与随机宠物"
L["PET_3"] = "与宠物"
L["PET_4"] = "不要宠物"
L["expansions"] = "资料片"
L["Rarity"] = "稀有度"
L["Travel time"] = "旅行时间"
L["Travel distance"] = "旅行距离"
L["Avg. speed"] = "平均速度"
L["Chance of summoning"] = "召唤几率"
L["Any"] = "任何"
L["> (more than)"] = "> (大于)"
L["< (less than)"] = "< (小于)"
L["= (equal to)"] = "= (等于)"
L["sorting"] = "排序"
L["Reverse Sort"] = "反向排序"
L["Collected First"] = "已收集优先"
L["Favorites First"] = "偏好优先"
L["Additional First"] = "额外优先"
L["Set current filters as default"] = "将当前的过滤设置为默认"
L["Restore default filters"] = "恢复默认过滤"
L["Enable Acceleration around the X-axis"] = "启用围绕X轴的加速功能"
L["Initial x-axis accseleration"] = "初始X轴加速"
L["X-axis accseleration"] = "X轴加速"
L["Minimum x-axis speed"] = "最小X轴速度"
L["Enable Acceleration around the Y-axis"] = "启用围绕Y轴的加速功能"
L["Initial y-axis accseleration"] = "初始Y轴加速"
L["Y-axis accseleration"] = "Y轴加速"
L["Minimum y-axis speed"] = "最小Y轴速度"
L["Model"] = "模组"
L["Map"] = "地图"
L["Map flags"] = "地图标记"
L["Settings"] = "设置"
L["Dungeons and Raids"] = "团队副本和地下城"
L["Current Location"] = "当前位置"
L["Enable Flags"] = "启用标记"
L["Ground Mounts Only"] = "仅地面坐骑"
L["Water Walking"] = "水上行走"
L["WaterWalkFlagDescription"] = "用来配置一些职业."
L["ListMountsFromZone"] = "使用区域中的坐骑列表"
L["No relation"] = "无关联"
L["Zones with list"] = "区域与列表"
L["Zones with relation"] = "区域与关联"
L["Zones with flags"] = "区域与标志"
L["CHARACTER_CLASS_DESCRIPTION"] = "(角色设置覆盖职业设置)"
L["HELP_MACRO_MOVE_FALL"] = "如果你在室内或正在移动，而你没有魔法扫帚或它被关闭，这个宏将被运行。"
L["HELP_MACRO_COMBAT"] = "如果你处于战斗状态，这个宏将被运行。"
L["CLASS_USEWHENCHARACTERFALLS"] = "当角色掉落时使用%s"
L["CLASS_USEWATERWALKINGSPELL"] = "召唤地面坐骑时使用%s"
L["CLASS_USEONLYWATERWALKLOCATION"] = "仅在水上行走区域使用"
L["DRUID_USELASTDRUIDFORM"] = "解除坐骑时返回之前形态"
L["DRUID_USEDRUIDFORMSPECIALIZATION"] = "返回专精形态"
L["DRUID_USEMACROALWAYS"] = "使用这个宏来代替坐骑"
L["Collected by %s of players"] = "被%s玩家收集"
L["Summonable Battle Pet"] = "可召唤的战斗宠物"
L["Summon Random Battle Pet"] = "召唤随机战斗宠物"
L["No Battle Pet"] = "无战斗宠物"
L["Summon a pet every"] = "召唤宠物每"
L["min"] = "分钟"
L["Summon only favorites"] = "仅召唤我喜欢的"
L["NoPetInRaid"] = "不要在团队中召唤战斗宠物"
L["NoPetInGroup"] = "不要在队伍中召唤战斗宠物"
L["CopyMountTarget"] = "尝试复制目标坐骑"
L["Colored mount names by rarity"] = "根据稀有度对坐骑名称着色"
L["Enable arrow buttons to browse mounts"] = "启用箭头按钮来浏览坐骑"
L["Open links in %s"] = "在%s中打开链接"
L["Click opens in"] = "点击打开到"
L["Show wowhead link in mount preview"] = "在坐骑预览中显示wowhead链接"
-- L["Enable statistics collection"] = ""
-- L["STATISTICS_DESCRIPTION"] = ""
L["Rule Sets"] = "规则集"
L["New rule set"] = "新建规则集"
L["A rule set with the same name exists."] = "存在一个同名的规则集。"
L["Are you sure you want to delete rule set %s?"] = "确定要删除规则集 %s 吗？"
L["Set as default"] = "设为默认"
L["Rules"] = "规则"
L["RULES_TITLE"] = "坐骑规则。按顺序检查规则，第一个符合所有条件的规则将执行操作。"
L["Add Rule"] = "添加规则"
L["Reset Rules"] = "重置规则"
L["Remove Rule %d"] = "删除规则 %d"
L["NOT_CONDITION"] = "非"
L["Conditions"] = "条件"
L["Action"] = "动作"
L["Edit Rule"] = "编辑规则"
L["ANY_MODIFIER"] = "任何"
L["Macro condition"] = "宏条件"
L["Mouse button"] = "鼠标按键"
L["Zone type"] = "区域类型"
L["Nameless holiday"] = "无名节日"
L["Flight style"] = "飞行模式"
L["Steady Flight"] = "稳定飞行"
L["Flyable area"] = "可飞行区域"
L["Have item"] = "拥有物品"
L["Item is ready"] = "物品已准备好"
L["Item is equipped"] = "物品已装备"
L["Spell is known"] = "法术未知"
L["Spell is ready"] = "法术已准备就绪"
L["Zone Name/Subzone Name"] = "区域名/子区域名"
L["The player has a buff"] = "玩家有增益效果"
L["The player has a debuff"] = "玩家有减益效果"
L["The player is falling"] = "玩家正在坠落"
L["The player is moving"] = "玩家正在移动"
L["The player is indoors"] = "玩家在室内"
L["The player is swimming"] = "玩家正在游泳"
L["The player is mounted"] = "玩家在坐骑上"
L["The player is within an vehicle"] = "玩家在载具内"
L["The player is dead"] = "玩家已死亡"
L["Sex"] = "性别"
L["Talent loadout"] = "天赋配置"
L["Get State"] = "获取状态"
L["Get a state that can be set in actions using \"Set State\""] = "使用“设置状态”获取可在操作中设置的状态"
L["Set State"] = "设置状态"
L["Set a state that can be read in conditions using \"Get State\""] = "设置可通过 “获取状态 ”读取的状态"
L["Random Mount"] = "随机坐骑"
L["Selected profile"] = "已选配置文件"
L["Random Mount by Rarity"] = "按稀有度随机坐骑"
L["The lower the rarity, the higher the chance"] = "稀有度越低，几率越高"
L["Mount"] = "坐骑"
L["Use Item"] = "使用物品"
L["Use Inventory Item"] = "使用库存物品"
L["Cast Spell"] = "施放法术"
L["Use macro before mounting"] = "上坐骑前使用宏"
L["PMACRO_DESCRIPTION"] = "注册上坐骑前要使用的宏"
-- L["Snippet"] = ""
-- L["Code Snippet"] = ""
-- L["Code Snippets"] = ""
-- L["Add Snippet"] = ""
-- L["A snippet with the same name exists."] = ""
-- L["Are you sure you want to delete snippet %s?"] = ""
-- L["Line"] = ""
-- L["Tab Size"] = ""
-- L["Do you want to save changes?"] = ""
L["About"] = "关于"
L["Help with translation of %s. Thanks."] = "参与帮助翻译 %s. 谢谢"
L["Localization Translators:"] = "本地化翻译者:"
L["ABBR_YARD"] = "码"
L["ABBR_MILE"] = "英里"
L["ABBR_METER"] = "米"
L["ABBR_KILOMETER"] = "千米"
L["ABBR_HOUR"] = "时"
-- ANIMATIONS
L["Default"] = "默认"
L["Mount special"] = "坐骑特殊动作"
L["Walk"] = "走"
L["Walk backwards"] = "向后走"
L["Run"] = "跑"
L["Swim idle"] = "游泳闲置"
L["Swim"] = "游泳"
L["Swim backwards"] = "向后游"
L["Fly stand"] = "飞行状态"
L["Fly"] = "飞行"
L["Fly backwards"] = "向后飞"
L["Loop"] = "循环"
L["Are you sure you want to delete animation %s?"] = "你确定要删除动画\"%s\"吗？"
-- PROFILES
L["Profiles"] = "配置"
L["New profile"] = "新配置"
L["Create"] = "创建"
L["Copy current"] = "复制当前"
L["A profile with the same name exists."] = "存在一个同名的配置."
L["Profile settings"] = "配置设置"
L["Pet binding from default profile"] = "默认配置下的宠物绑定"
L["Zones settings from default profile"] = "默认配置中的区域设置"
L["Auto add new mounts to selected"] = "自动添加新坐骑到已选择"
L["Select all filtered mounts by type in the selected zone"] = "按类型选择所选区域内所有过滤后的坐骑"
L["Unselect all filtered mounts in the selected zone"] = "取消选择所选区域内所有已过滤的坐骑"
L["Select all favorite mounts by type in the selected zone"] = "按类型选择所选区域内所有喜爱的坐骑"
L["Select all mounts by type in selected zone"] = "按类型选择所选区域内的所有坐骑"
L["Unselect all mounts in selected zone"] = "取消选择所选区域的所有坐骑"
L["Are you sure you want to delete profile %s?"] = "你确定要删除配置\"%s\"吗？"
L["Are you sure you want %s?"] = "你确定你想要\"%s\"吗？"
-- TAGS
L["tags"] = "标签"
L["No tag"] = "无标签"
L["With all tags"] = "包含所有标签"
L["Add tag"] = "添加标签"
L["Tag already exists."] = "标签已经存在."
L["Are you sure you want to delete tag %s?"] = "你确定要删除标签\"%s\"吗？"
-- FAMILY
L["Family"] = "系列"
L["Airplanes"] = "飞机"
L["Airships"] = "飞艇"
L["Albatross"] = "信天翁"
L["Alpacas"] = "羊驼"
L["Amphibian"] = "两栖"
L["Animite"] = "飞虫"
L["Aqir Flyers"] = "工蜂"
L["Arachnids"] = "蛛形"
L["Armoredon"] = "厚甲龙"
L["Assault Wagons"] = "攻城车"
L["Basilisks"] = "蜥蜴"
L["Bats"] = "蝙蝠"
L["Bears"] = "熊"
L["Bees"] = "蜜蜂"
L["Beetle"] = "甲虫"
L["Bipedal Cat"] = "梦爪獍"
L["Birds"] = "鸟"
L["Blood Ticks"] = "吮血蛛"
L["Boars"] = "野猪"
L["Book"] = "书"
L["Bovids"] = "牛"
L["Broom"] = "扫帚"
L["Brutosaurs"] = "雷龙"
L["Camels"] = "骆驼"
L["Carnivorans"] = "食肉"
L["Carpets"] = "飞毯"
L["Cats"] = "猫"
L["Cervid"] = "元鹿"
L["Chargers"] = "战马"
L["Chickens"] = "鸡"
L["Clefthooves"] = "裂蹄牛"
L["Cloud Serpents"] = "云端翔龙"
L["Core Hounds"] = "熔火犬"
L["Crabs"] = "螃蟹"
L["Cranes"] = "仙鹤"
L["Crawgs"] = "抱齿兽"
L["Crocolisks"] = "鳄鱼"
L["Crows"] = "乌鸦"
L["Demonic Hounds"] = "恶魔犬"
L["Demonic Steeds"] = "恶魔马"
L["Demons"] = "恶魔"
L["Devourer"] = "吞噬者"
L["Dinosaurs"] = "恐龙"
L["Dire Wolves"] = "恐狼"
L["Direhorns"] = "恐角龙"
L["Discs"] = "飞碟"
L["Dragonhawks"] = "龙鹰"
L["Drakes"] = "龙"
L["Dread Ravens"] = "恐鸦"
L["Dreamsaber"] = "梦刃豹"
L["Eagle"] = "雄鹰"
L["Elekks"] = "雷象"
L["Elementals"] = "元素"
L["Falcosaurs"] = "猎龙"
L["Fathom Rays"] = "海波鳐"
L["Feathermanes"] = "羽鬃"
L["Felsabers"] = "邪刃豹"
L["Fish"] = "鱼"
L["Flies"] = "苍蝇"
L["Flying Steeds"] = "天马"
L["Foxes"] = "狐"
L["Gargon"] = "加尔贡"
L["Gargoyle"] = "石像鬼"
L["Goats"] = "山羊"
L["Gorger"] = "饕餮者"
L["Gorm"] = "甲虫"
L["Grand Drakes"] = "大型龙"
L["Gronnlings"] = "小戈隆"
L["Gryphons"] = "狮鹫"
L["Gyrocopters"] = "旋翼"
L["Hands"] = "手"
L["Hawkstriders"] = "陆行鸟"
L["Hippogryphs"] = "角鹰"
L["Horned Steeds"] = "角马"
L["Horses"] = "马"
L["Hounds"] = "犬"
L["Hovercraft"] = "气垫船"
L["Humanoids"] = "人型"
L["Hyenas"] = "狼"
L["Infernals"] = "地狱火"
L["Insects"] = "昆虫"
L["Jellyfish"] = "水母"
L["Jet Aerial Units"] = "空中单位"
L["Kites"] = "风筝"
L["Kodos"] = "科多兽"
L["Krolusks"] = "三叶虫"
L["Larion"] = "羽鬃兽"
L["Lions"] = "狮"
-- L["Lizards"] = ""
L["Lupine"] = "元狼"
L["Lynx"] = "山猫"
L["Mammoths"] = "猛犸象"
L["Mana Rays"] = "法力鳐"
L["Manasabers"] = "魔刃豹"
L["Mauler"] = "重殴者"
L["Mechanical Animals"] = "机械生物"
L["Mechanical Birds"] = "机械鸟"
L["Mechanical Cats"] = "机械猫"
L["Mechanical Steeds"] = "机械马"
L["Mechanostriders"] = "机械陆行鸟"
L["Mecha-suits"] = "机甲"
-- L["Mice"] = ""
L["Mollusc"] = "软体动物"
L["Moose"] = "驼鹿"
L["Moth"] = "蛾"
L["Motorcycles"] = "摩托车"
L["Mountain Horses"] = "山地马"
L["Mudnose"] = "泥鼻鼹"
L["Murloc"] = "鱼人"
L["Mushan"] = "穆山兽"
L["Nether Drakes"] = "灵翼幼龙"
L["Nether Rays"] = "虚空鳐"
L["N'Zoth Serpents"] = "恩佐斯蛇"
L["Others"] = "其他"
L["Ottuk"] = "奥獭"
L["Owl"] = "猫头鹰"
L["Owlbear"] = "月兽"
L["Ox"] = "公牛"
L["Pandaren Phoenixes"] = "熊猫人凤凰"
L["Parrots"] = "鹦鹉"
L["Peafowl"] = "孔雀"
L["Phoenixes"] = "凤凰"
L["Proto-Drakes"] = "始祖幼龙"
L["Pterrordaxes"] = "啸天龙"
L["Quilen"] = "魁麟"
L["Rabbit"] = "兔子"
L["Rams"] = "公羊"
L["Raptora"] = "元鹰"
L["Raptors"] = "迅猛龙"
L["Rats"] = "鼠"
L["Rays"] = "鳐"
L["Razorwing"] = "刀翼兽"
L["Reptiles"] = "爬虫"
L["Rhinos"] = "犀牛"
L["Riverbeasts"] = "淡水兽"
L["Roc"] = "大鹏"
L["Rockets"] = "火箭"
L["Rodent"] = "啮齿动物"
L["Ruinstriders"] = "游荡者"
L["Rylaks"] = "魔龙"
L["Sabers"] = "刃豹"
L["Scorpions"] = "蝎子"
L["Sea Serpents"] = "海蛇"
L["Seahorses"] = "海马"
L["Seat"] = "摇篮"
L["Shardhides"] = "碎皮兽"
L["Silithids"] = "异种蝎"
L["Skyflayer"] = "剥天者"
L["Skyrazor"] = "剃天者"
L["Slug"] = "蛞蝓"
L["Snail"] = "蜗牛"
L["Snapdragons"] = "毒鳍龙"
L["Spider Tanks"] = "蜘蛛坦克"
L["Spiders"] = "蜘蛛"
L["Sporebat"] = "孢子蝠"
L["Stag"] = "牡鹿"
L["Steeds"] = "马"
L["Stingrays"] = "鳐鱼"
L["Stone Cats"] = "石猎豹"
L["Stone Drakes"] = "石幼龙"
L["Surfboard"] = "冲浪板"
L["Talbuks"] = "塔布羊"
L["Tallstriders"] = "蛇鸟"
L["Talonbirds"] = "鸦神"
L["Tauralus"] = "荒牛"
L["Thunder Lizard"] = "雷霆蜥蜴"
L["Tigers"] = "虎"
L["Toads"] = "蟾蜍"
L["Turtles"] = "龟"
L["Undead Drakes"] = "不死幼龙"
L["Undead Steeds"] = "不死战马"
L["Undead Wolves"] = "不死战狼"
L["Undercrawlers"] = "幽暗爬行者"
L["Underlights"] = "幽光"
L["Ungulates"] = "有蹄"
L["Ur'zul"] = "乌祖尔"
L["Vehicles"] = "载具"
L["Vombata"] = "元袋熊"
L["Vulpin"] = "烁裘"
L["Vultures"] = "秃鹫"
L["War Wolves"] = "战狼"
L["Wasp"] = "巨蜂"
L["Water Striders"] = "水黾"
L["Wilderlings"] = "荒蚺"
L["Wind Drakes"] = "风幼龙"
L["Wolfhawks"] = "狼鹰"
L["Wolves"] = "狼"
L["Wyverns"] = "双足飞龙"
L["Yaks"] = "牦牛"
L["Yetis"] = "雪人"