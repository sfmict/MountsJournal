local addon, ns = ...
local L, util, mounts, journal = ns.L, ns.util, ns.mounts, ns.journal


journal:on("MODULES_INIT", function(self)
	util.showHelpJournal()
	self.leftInset:HookScript("OnShow", util.showHelpJournal)
end)


local function nextTip(t)
	mounts.help.journal = t
	util.showHelpJournal()
end


function util.showHelpJournal()
	local step = type(mounts.help.journal) == "number" and mounts.help.journal or 0
	HelpTip:HideAll(journal.leftInset)
	HelpTip:HideAll(journal.bgFrame)
	if step == 0 then
		local helpTipInfo = {
			text = L["ButtonsSelectedTooltipDescription"]:format(ns.addon),
			buttonStyle = HelpTip.ButtonStyle.Next,
			targetPoint = HelpTip.Point.RightEdgeTop,
			alignment = HelpTip.Alignment.Top,
			offsetX = -4,
			offsetY = -23,
			callbackArg = 1,
			onAcknowledgeCallback = nextTip,
		}
		HelpTip:Show(journal.leftInset, helpTipInfo, journal.scrollBox)
	elseif step == 1 then
		local helpTipInfo = {
			text = L["ProfilesTooltipDescription"],
			buttonStyle = HelpTip.ButtonStyle.Next,
			targetPoint = HelpTip.Point.TopEdgeCenter,
			alignment = HelpTip.Alignment.Right,
			offsetY = -4,
			callbackArg = 2,
			onAcknowledgeCallback = nextTip,
		}
		HelpTip:Show(journal.leftInset, helpTipInfo, journal.bgFrame.profilesMenu)
	elseif step == 2 then
		local helpTipInfo = {
			text = L["ZoneSettingsTooltipDescription"],
			buttonStyle = HelpTip.ButtonStyle.Next,
			targetPoint = HelpTip.Point.TopEdgeCenter,
			offsetY = -4,
			callbackArg = 3,
			onAcknowledgeCallback = nextTip,
		}
		HelpTip:Show(journal.bgFrame, helpTipInfo, journal.bgFrame.mapTab)
	elseif step == 3 then
		local helpTipInfo = {
			text = L["SettingsTooltipDescription"]:format(ns.addon),
			buttonStyle = HelpTip.ButtonStyle.GotIt,
			targetPoint = HelpTip.Point.TopEdgeCenter,
			alignment = HelpTip.Alignment.Right,
			offsetY = -4,
			callbackArg = 4,
			onAcknowledgeCallback = nextTip,
		}
		HelpTip:Show(journal.bgFrame, helpTipInfo, journal.bgFrame.settingsTab)
	end
end