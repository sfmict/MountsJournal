local _, ns = ...
local journal = ns.journal


function journal.filters.color(dd, level)
	local info = {}
	info.customFrame = journal.bgFrame.mountColor
	dd:ddAddButton(info, level)
end
