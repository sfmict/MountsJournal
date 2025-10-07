local _, ns = ...
local mounts, util = ns.mounts, ns.util
local C_Calendar, ipairs, sort = C_Calendar, ipairs, sort
local calendar = util.createFromEventsMixin()
ns.calendar = calendar
calendar.filterBackup = {}


local CALENDAR_MONTH_NAMES = {
	MONTH_JANUARY,
	MONTH_FEBRUARY,
	MONTH_MARCH,
	MONTH_APRIL,
	MONTH_MAY,
	MONTH_JUNE,
	MONTH_JULY,
	MONTH_AUGUST,
	MONTH_SEPTEMBER,
	MONTH_OCTOBER,
	MONTH_NOVEMBER,
	MONTH_DECEMBER,
}


function calendar:setBackup()
	local backup = self.filterBackup
	backup.calendarShowHolidays = GetCVarBool("calendarShowHolidays")
	backup.calendarShowDarkmoon = GetCVarBool("calendarShowDarkmoon")
	backup.calendarShowLockouts = GetCVarBool("calendarShowLockouts")
	backup.calendarShowWeeklyHolidays = GetCVarBool("calendarShowWeeklyHolidays")
	backup.calendarShowBattlegrounds = GetCVarBool("calendarShowBattlegrounds")

	self.dateBackup = C_Calendar.GetMonthInfo()
	if CalendarFrame then
		CalendarFrame:UnregisterEvent("CALENDAR_UPDATE_EVENT_LIST")
		CalendarEventPickerFrame:UnregisterEvent("CALENDAR_UPDATE_EVENT_LIST")
	end

	if not backup.calendarShowHolidays then SetCVar("calendarShowHolidays", "1") end
	if not backup.calendarShowDarkmoon then SetCVar("calendarShowDarkmoon", "1") end
	if not backup.calendarShowWeeklyHolidays then SetCVar("calendarShowWeeklyHolidays", "1") end
	if backup.calendarShowLockouts then SetCVar("calendarShowLockouts", "0") end
	if backup.calendarShowBattlegrounds then SetCVar("calendarShowBattlegrounds", "0") end
end


function calendar:restoreBackup()
	local backup = self.filterBackup
	if not backup.calendarShowHolidays then SetCVar("calendarShowHolidays", "0") end
	if not backup.calendarShowDarkmoon then SetCVar("calendarShowDarkmoon", "0") end
	if not backup.calendarShowWeeklyHolidays then SetCVar("calendarShowWeeklyHolidays", "0") end
	if backup.calendarShowLockouts then SetCVar("calendarShowLockouts", "1") end
	if backup.calendarShowBattlegrounds then SetCVar("calendarShowBattlegrounds", "1") end

	C_Calendar.SetAbsMonth(self.dateBackup.month, self.dateBackup.year)
	if CalendarFrame then
		CalendarFrame:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST")
		CalendarEventPickerFrame:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST")
	end
end


function calendar:setPreviousMonth()
	self.date.month = self.date.month - 1
	if self.date.month < 1 then
		self.date.year = self.date.year - 1
		self.date.month = 12
	end
end


function calendar:setNextMonth()
	self.date.month = self.date.month + 1
	if self.date.month > 12 then
		self.date.year = self.date.year + 1
		self.date.month = 1
	end
end


function calendar:setCurrentDate()
	self.date = C_DateAndTime.GetCurrentCalendarTime()
end


function calendar:getSelectedDate()
	return self.date.year, CALENDAR_MONTH_NAMES[self.date.month]
end


function calendar:getEventKey(e)
	local st = e.startTime
	return ("%d:%d%.2d%.2d"):format(e.eventID, st.year, st.month, st.monthDay)
end


function calendar:sortHolidays(list)
	sort(list, function(e1, e2)
		if e1.name ~= e2.name then return e1.name < e2.name end
		if e1.eventID ~= e2.eventID then return e1.eventID < e2.eventID end
		if e1.st.month ~= e2.st.month then return e1.st.month < e2.st.month end
		return e1.st.monthDay < e2.st.monthDay
	end)
end


function calendar:getHolidayList()
	local holidays, addedIDs = {}, {}

	self:setBackup()

	C_Calendar.SetAbsMonth(self.date.month, self.date.year)
	local monthInfo = C_Calendar.GetMonthInfo()

	-- CALENDAR_CALENDARTYPE_TCOORDS Blizzard_calendar.lua
	local iconInfo = {
		tCoordLeft = 0,
		tCoordRight = .7109375,
		tCoordTop = 0,
		tCoordBottom = .7109375,
	}

	for day = 1, monthInfo.numDays do
		for i = 1, C_Calendar.GetNumDayEvents(0, day) do
			local e = C_Calendar.GetDayEvent(0, day, i)
			if e.calendarType == "HOLIDAY" then
				local k = self:getEventKey(e)
				if not addedIDs[k] then
					local eInfo = C_Calendar.GetHolidayInfo(0, day, i)
					local data = {
						eventID = e.eventID,
						sequenceType = e.sequenceType,
						icon = eInfo.texture,
						iconInfo = iconInfo,
						name = e.title,
						st = e.startTime,
						et = e.endTime,
						description = eInfo.description,
						isActive = self.activeHolidays[k],
					}
					holidays[#holidays + 1] = data
					addedIDs[k] = data
				elseif e.sequenceType and e.sequenceType ~= "ONGOING" and (not addedIDs[k].sequenceType or addedIDs[k].sequenceType == "ONGOING") then
					addedIDs[k].icon = C_Calendar.GetHolidayInfo(0, day, i).texture
				end
			end
		end
	end

	self:restoreBackup()

	self:sortHolidays(holidays)
	return holidays
end


function calendar:getHolidayName(eventID)
	return self.holidayNames[eventID]
end


function calendar:saveHolidayName(eventID, name)
	self.needToCheck = true
	self.holidayNames[eventID] = name
end


function calendar:checkHolidayNames()
	if not self.needToCheck then return end
	local holidayIDs = {}
	for _, ruleSet in ipairs(self.ruleSets) do
		for _, rules in ipairs(ruleSet) do
			for _, rule in ipairs(rules) do
				for _, cond in ipairs(rule) do
					if cond[2] == "holiday" then
						holidayIDs[cond[3]] = true
					end
				end
			end
		end
	end

	for lang, holidayNames in next, mounts.globalDB.holidayNames do
		for eventID in next, holidayNames do
			if not holidayIDs[eventID] then
				holidayNames[eventID] = nil
			end
		end
	end
end
calendar:on("LOGOUT", calendar.checkHolidayNames)


function calendar:updateTodayEvents()
	local date = C_DateAndTime.GetCurrentCalendarTime()
	local secondsToUpdate = ((24 - date.hour) * 60 + 1 - date.minute) * 60
	self.activeHolidays = {}

	self:setBackup()

	C_Calendar.SetAbsMonth(date.month, date.year)
	for i = 1, C_Calendar.GetNumDayEvents(0, date.monthDay) do
		local e = C_Calendar.GetDayEvent(0, date.monthDay, i)

		if e.sequenceType == "START" then
			local secondsToEvent = ((e.startTime.hour - date.hour) * 60 + e.startTime.minute - date.minute) * 60
			if secondsToEvent <= 0 then
				self.activeHolidays[self:getEventKey(e)] = true
				self.activeHolidays[e.eventID] = true
			elseif secondsToEvent < secondsToUpdate then
				secondsToUpdate = secondsToEvent
			end
		elseif e.sequenceType == "END" then
			local secondsToEvent = ((e.endTime.hour - date.hour) * 60 + e.endTime.minute - date.minute) * 60
			if secondsToEvent > 0 then
				self.activeHolidays[self:getEventKey(e)] = true
				self.activeHolidays[e.eventID] = true
				if secondsToEvent < secondsToUpdate then
					secondsToUpdate = secondsToEvent
				end
			end
		else
			self.activeHolidays[self:getEventKey(e)] = true
			self.activeHolidays[e.eventID] = true
		end
	end

	self:restoreBackup()

	C_Timer.After(secondsToUpdate - GetServerTime() % 60, function() self:updateTodayEvents() end)
end


function calendar:isHolidayActive(eventID)
	return self.activeHolidays[eventID]
end


calendar:on("ADDON_INIT", function(self)
	self:updateTodayEvents()

	self.ruleSets = mounts.globalDB.ruleSets
	self.holidayNames = mounts.globalDB.holidayNames[GetLocale()] or {}
	mounts.globalDB.holidayNames[GetLocale()] = self.holidayNames
	local names = self.holidayNames
	local numNoName = 0

	for _, ruleSet in ipairs(self.ruleSets) do
		for _, rules in ipairs(ruleSet) do
			for _, rule in ipairs(rules) do
				for _, cond in ipairs(rule) do
					if cond[2] == "holiday" and not names[cond[3]] then
						numNoName = numNoName + 1
						names[cond[3]] = false
					end
				end
			end
		end
	end

	if numNoName == 0 then return end

	self:setBackup()

	local date = C_DateAndTime.GetCurrentCalendarTime()
	local year = date.year - 2
	date.year = date.year + 1
	C_Calendar.SetAbsMonth(date.month, date.year)

	while numNoName ~= 0 and date.year > year do
		local numEvents = C_Calendar.GetNumDayEvents(0, date.monthDay)
		for i = 1, numEvents do
			local e = C_Calendar.GetDayEvent(0, date.monthDay, i)
			if names[e.eventID] == false then
				names[e.eventID] = e.title
				numNoName = numNoName - 1
			end
		end

		date.monthDay = date.monthDay - 1
		if date.monthDay < 1 then
			date.month = date.month - 1
			if date.month < 1 then
				date.month = 12
				date.year = date.year - 1
			end
			C_Calendar.SetAbsMonth(date.month, date.year)
			local monthInfo = C_Calendar.GetMonthInfo()
			date.monthDay = monthInfo.numDays
		end
	end

	self:restoreBackup()
end)