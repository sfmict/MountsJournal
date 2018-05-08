local _, L = ...

L["%s Configuration"] = "%s Configuration"
L["ConfigPanelTitle %s."] = "This panel can be used to configure %s."
L["Modifier"] = "Modifier"
L["ModifierDescription"] = "If the modifier pressed and you are in water then will be called non-waterfowl mount. If you are on land and you can fly then will be called ground mount."
L["CreateMacroBtn"] = "Create Macro: \"/mount\""
L["CreateMacro"] = "Create Macro"
L["CreateMacroTooltip"] = "The created macro is used to call the selected mounts."
L["Settings"] = "Settings"

setmetatable(L, {__index = function(self, key)
  self[key] = key or ""
  return key
end})