local addon, ns = ...
local L, tags, searchStr = ns.L, ns.journal.tags


function tags.mountMenu.family(dd, level, subFamily)
	local info = {}
	local mountDB, familyDB = ns.mountsDB[tags.menuMountID], ns.familyDB

	local function isChecked(familyID)
		local ids = mountDB[2]
		if type(ids) == "number" then
			return ids == familyID
		else
			for i, id in ipairs(ids) do
				if id == familyID then return true end
			end
		end
	end

	local function setFamilyID(familyID, enabled)
		local ids = mountDB[2]
		if enabled then
			if type(ids) == "table" then
				if tInsertUnique(ids, familyID) then
					sort(ids)
				end
			elseif ids == 0 then
				mountDB[2] = familyID
			else
				mountDB[2] = {ids, familyID}
				sort(mountDB[2])
			end
		else
			if type(ids) == "table" then
				tDeleteItem(ids, familyID)
				if #ids == 1 then mountDB[2] = ids[1] end
			else
				mountDB[2] = 0
			end
		end
	end

	local check = function(button)
		return isChecked(button.value)
	end

	if subFamily then
		info.keepShownOnClick = true
		info.isNotRadio = true

		local sortedNames = {}
		for k in next, familyDB[subFamily] do
			sortedNames[#sortedNames + 1] = {k, L[k]}
		end
		sort(sortedNames, function(a, b)
			return b[1] == "Others" or a[1] ~= "Others" and strcmputf8i(a[2], b[2]) < 0
		end)
		if searchStr then
			for i, name in ipairs(sortedNames) do
				local start, stop = name[2]:lower():find(searchStr, 1, true)
				if start and stop then
					name[2] = ("%s|cffffd200%s|r%s"):format(name[2]:sub(0, start-1), name[2]:sub(start, stop), name[2]:sub(stop+1, #name[2]))
				end
			end
		end

		info.func = function(button, _,_, checked)
			setFamilyID(button.value, checked)
			dd:ddRefresh(level - 1)
		end
		info.checked = check

		for i, name in ipairs(sortedNames) do
			info.text = name[2]
			info.icon = ns.familyDBIcons[subFamily][name[1]]
			info.value = familyDB[subFamily][name[1]]
			dd:ddAddButton(info, level)
		end
	else
		local sortedNames = {}
		for k in next, familyDB do
			sortedNames[#sortedNames + 1] = {k, L[k]}
		end
		sort(sortedNames, function(a, b)
			return b[1] == "rest" or a[1] ~= "rest" and strcmputf8i(a[2], b[2]) < 0
		end)

		local func = function(button, _,_, checked)
			setFamilyID(button.value, checked)
			dd:ddRefresh(level)
		end

		local subFunc = function(button, _,_, checked)
			for k, v in next, familyDB[button.value[2]] do
				setFamilyID(v, checked)
			end
			dd:ddRefresh(level)
			dd:ddRefresh(level + 1)
		end
		local subCheck = function(btn)
			local i, j = 0, 0
			for k, v in next, familyDB[btn.value[2]] do
				i = i + 1
				if isChecked(v) then j = j + 1 end
			end
			return i == j and 1 or j > 0 and 2
		end

		local list = {}
		for i, name in ipairs(sortedNames) do
			local subInfo = {}
			subInfo.keepShownOnClick = true
			subInfo.isNotRadio = true
			subInfo.text = name[2]

			if type(familyDB[name[1]]) == "number" then
				subInfo.disabled = name[1] == "rest"
				subInfo.icon = ns.familyDBIcons[name[1]]
				subInfo.value = familyDB[name[1]]
				subInfo.func = func
				subInfo.checked = check
			else
				subInfo.hasArrow = true
				subInfo.icon = ns.familyDBIcons[name[1]][0]
				subInfo.value = {"family", name[1]}
				subInfo.func = subFunc
				subInfo.checked = subCheck
			end

			list[i] = subInfo
		end

		info.search = function(str, text, _, btnInfo)
			if #str == 0 then
				searchStr = nil
				return true
			end
			searchStr = str

			local start, stop = text:lower():find(str, 1, true)
			if start and stop then
				return true, ("%s|cffffd200%s|r%s"):format(text:sub(0, start-1), text:sub(start, stop), text:sub(stop+1))
			end

			if type(btnInfo.value) ~= "number" then
				for name in next, familyDB[btnInfo.value[2]] do
					if L[name]:lower():find(str, 1, true) then return true end
				end
			end
		end

		info.listMaxSize = 30
		info.list = list
		dd:ddAddButton(info, level)
	end
end
