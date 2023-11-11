if GetLocale() ~= "zhCN" then
	return
end

local _, L = ...

L["author"] = "作者"
L["%s Configuration"] = "%s 配置"
L["ConfigPanelTitle"] = "全局设置"
L["Class settings"] = "职业设置"
L["Modifier"] = "组合键"
L["Normal mount summon"] = "普通坐骑召唤."
L["SecondMountTooltipTitle"] = "如果组合键保持或\"%s 2\"被使用:"
L["SecondMountTooltipDescription"] = "如果你在水中那么将被召唤出非水下坐骑.\n\n如果你在陆地上并且你能飞那么将被召唤出地面坐骑."
-- L["ThirdMountTooltipDescription"] = ""
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
L["Random available mount"] = "随机可用坐骑"
L["UseHallowsEndMounts"] = "使用“万圣节”坐骑"
L["UseHallowsEndMountsDescription"] = "当“万圣节结束”事件处于活动状态时，如果你有它的坐骑，就会使用它们。"
L["Use %s"] = "使用%s"
L["Use automatically"] = "自动使用"
L["UseUnderlightAnglerDescription"] = "使用幽光鱼竿而不是水下坐骑."
L["A macro named \"%s\" already exists, overwrite it?"] = "一个名为\"%s\"的宏已经存在, 将其覆盖？"
L["CreateMacro"] = "创建宏"
L["CreateMacroTooltip"] = "所创建的宏用于召唤所选坐骑."
L["or key bind"] = "或按键绑定"
L["Collected:"] = "已收集"
L["Settings"] = "设置"
L["Shown:"] = "显示:"
L["With multiple models"] = "多种模式"
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
L["Rarity"] = "稀有"
L["Chance of summoning"] = "召唤几率"
L["Any"] = "任何"
L["> (more than)"] = "> (大于)"
L["< (less than)"] = "< (小于)"
L["= (equal to)"] = "= (等于)"
L["sorting"] = "排序"
L["Reverse Sort"] = "反向排序"
L["Favorites First"] = "偏好优先"
L["Dragonriding First"] = "Dragonriding First"
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
L["Map / Model"] = "地图/模组"
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
L["HELP_MACRO_MOVE_FALL"] = "如果你在室内或正在移动而你没有魔法扫帚或它被关闭, 这个宏将被运行."
L["HELP_MACRO_COMBAT"] = "如果你处于战斗状态, 这个宏将被运行."
L["WORGEN_USERUNNINGWILD"] = "使用%s作为地面坐骑"
L["CLASS_USEWHENCHARACTERFALLS"] = "当角色掉落时使用%s"
L["CLASS_USEWATERWALKINGSPELL"] = "召唤地面坐骑时使用%s"
L["CLASS_USEONLYWATERWALKLOCATION"] = "仅在水上行走区域使用"
L["DRUID_USELASTDRUIDFORM"] = "解除坐骑时返回之前形态"
L["DRUID_USEDRUIDFORMSPECIALIZATION"] = "返回专精形态"
L["DRUID_USEMACROALWAYS"] = "使用这个宏来代替坐骑"
L["DRUID_USEIFNOTDRAGONRIDABLE"] = "只有在不具备驭龙条件时"
L["Collected by %s of players"] = "由%s玩家收集"
L["Summonable Battle Pet"] = "可召唤的战斗宠物"
L["Summon Random Battle Pet"] = "召唤随机战斗宠物"
L["No Battle Pet"] = "无战斗宠物"
L["Summon a pet every"] = "召唤宠物每"
L["min"] = "分钟"
L["Summon only favorites"] = "仅召唤我喜欢的"
L["NoPetInRaid"] = "不要在团队中召唤战斗宠物"
L["NoPetInGroup"] = "不要在队伍中召唤战斗宠物"
L["CopyMountTarget"] = "尝试复制目标坐骑"
L["Colored mount names by rarity"] = "按稀有度排列的彩色坐骑名称"
L["Enable arrow buttons to browse mounts"] = "启用箭头按钮来浏览坐骑"
L["Open links in %s"] = "在%s中打开链接"
L["Click opens in"] = "点击打开到"
L["Show wowhead link in mount preview"] = "在坐骑预览中显示wowhead链接"
L["About"] = "关于"
L["Help with translation of %s. Thanks."] = "参与帮助翻译 %s. 谢谢"
L["Localization Translators:"] = "本地化翻译者:"
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
L["By Specialization"] = "按专精"
L["Areans and Battlegrounds"] = "竞技场和战场"
L["Profile settings"] = "配置设置"
L["Pet binding from default profile"] = "默认配置下的宠物绑定"
L["Zones settings from default profile"] = "默认配置中的区域设置"
L["Auto add new mounts to selected"] = "自动添加新坐骑到已选择"
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