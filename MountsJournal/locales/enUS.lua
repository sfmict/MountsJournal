local _, L = ...

L["%s Configuration"] = "%s Configuration"
L["ConfigPanelTitle %s."] = "This panel can be used to configure %s."
L["Modifier"] = "Modifier"
L["ModifierDescription"] = "If the modifier is pressed, then if you are in water is called non waterfowl mount, if you are on land and if you can fly is called ground mount."
L["CreateMacroBtn"] = "Create Macro: \"/mount\""
L["CreateMacro"] = "Create Macro"
L["CreateMacroTooltip"] = "The created macro is used to call the selected mounts."
L["Settings"] = "Settings"

setmetatable(L, {__index = function(self, key)
  self[key] = key or ""
  return key
end})