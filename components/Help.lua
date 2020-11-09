local addon, L = ...
local util, mounts, journal = MountsJournalUtil, MountsJournal, MountsJournalFrame


local function nextTip(t)
	mounts.help.journal[t] = 1
	util.showHelpJournal()
end


function util.showHelpJournal()
	if not journal.MountJournal:IsShown() then return end
	HelpTip:HideAll(journal.MountJournal)
	if not mounts.help.journal[1] then
		local helpTipInfo = {
			text = L["ButtonsSelectedTooltipDescription"]:format(addon),
			buttonStyle = HelpTip.ButtonStyle.Next,
			targetPoint = HelpTip.Point.RightEdgeTop,
			alignment = HelpTip.Alignment.Top,
			callbackArg = 1,
			offsetX = -4,
			offsetY = -23,
			onAcknowledgeCallback = nextTip,
		}
		HelpTip:Show(journal.MountJournal, helpTipInfo, journal.scrollFrame)
	elseif not mounts.help.journal[2] then
		local helpTipInfo = {
			text = L["ZoneSettingsTooltipDescription"]:gsub("\n*(.*)", "%1"),
			buttonStyle = HelpTip.ButtonStyle.Next,
			targetPoint = HelpTip.Point.RightEdgeCenter,
			alignment = HelpTip.Alignment.Top,
			callbackArg = 2,
			offsetX = -4,
			onAcknowledgeCallback = nextTip,
		}
		HelpTip:Show(journal.MountJournal, helpTipInfo, journal.navBarBtn)
	elseif not mounts.help.journal[3] then
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
	elseif not mounts.help.journal[4] then
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