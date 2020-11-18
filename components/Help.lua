local addon, L = ...
local util, mounts, journal = MountsJournalUtil, MountsJournal, MountsJournalFrame


local function nextTip(t)
	mounts.help.journal = t
	util.showHelpJournal()
end


function util.showHelpJournal()
	if not journal.MountJournal:IsShown() then return end
	local step = type(mounts.help.journal) == "number" and mounts.help.journal or 0
	HelpTip:HideAll(journal.MountJournal)
	if step == 0 then
		local helpTipInfo = {
			text = L["ButtonsSelectedTooltipDescription"]:format(addon),
			buttonStyle = HelpTip.ButtonStyle.Next,
			targetPoint = HelpTip.Point.RightEdgeTop,
			alignment = HelpTip.Alignment.Top,
			offsetX = -4,
			offsetY = -23,
			callbackArg = 1,
			onAcknowledgeCallback = nextTip,
		}
		HelpTip:Show(journal.MountJournal, helpTipInfo, journal.scrollFrame)
	elseif step == 1 then
		local helpTipInfo = {
			text = L["ZoneSettingsTooltipDescription"]:gsub("\n*(.*)", "%1"),
			buttonStyle = HelpTip.ButtonStyle.Next,
			targetPoint = HelpTip.Point.RightEdgeCenter,
			alignment = HelpTip.Alignment.Top,
			offsetX = -4,
			callbackArg = 2,
			onAcknowledgeCallback = nextTip,
		}
		HelpTip:Show(journal.MountJournal, helpTipInfo, journal.navBarBtn)
	elseif step == 2 then
		local helpTipInfo = {
			text = L["ProfilesTooltipDescription"],
			buttonStyle = HelpTip.ButtonStyle.Next,
			targetPoint = HelpTip.Point.TopEdgeCenter,
			alignment = HelpTip.Alignment.Right,
			offsetY = -4,
			callbackArg = 3,
			onAcknowledgeCallback = nextTip,
		}
		HelpTip:Show(journal.MountJournal, helpTipInfo, journal.profilesMenu)
	elseif step == 3 then
		local helpTipInfo = {
			text = L["SettingsTooltipDescription"]:format(addon),
			buttonStyle = HelpTip.ButtonStyle.GotIt,
			targetPoint = HelpTip.Point.TopEdgeCenter,
			offsetY = -4,
			callbackArg = 4,
			onAcknowledgeCallback = nextTip,
		}
		HelpTip:Show(journal.MountJournal, helpTipInfo, journal.btnConfig)
	end
end