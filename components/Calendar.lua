local _, ns = ...
local mounts, util = ns.mounts, ns.util
local C_Calendar, pairs, sort = C_Calendar, pairs, sort
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
	local backup = calendar.filterBackup
	backup.calendarShowHolidays = GetCVarBool("calendarShowHolidays")
	backup.calendarShowDarkmoon = GetCVarBool("calendarShowDarkmoon")
	backup.calendarShowLockouts = GetCVarBool("calendarShowLockouts")
	backup.calendarShowWeeklyHolidays = GetCVarBool("calendarShowWeeklyHolidays")
	backup.calendarShowBattlegrounds = GetCVarBool("calendarShowBattlegrounds")

	if not backup.calendarShowHolidays then SetCVar("calendarShowHolidays", "1") end
	if not backup.calendarShowDarkmoon then SetCVar("calendarShowDarkmoon", "1") end
	if backup.calendarShowLockouts then SetCVar("calendarShowLockouts", "0") end
	if backup.calendarShowWeeklyHolidays then SetCVar("calendarShowWeeklyHolidays", "0") end
	if backup.calendarShowBattlegrounds then SetCVar("calendarShowBattlegrounds", "0") end

	self.dateBackup = C_Calendar.GetMonthInfo()
	if CalendarFrame then
		CalendarFrame:UnregisterEvent("CALENDAR_UPDATE_EVENT_LIST")
		CalendarEventPickerFrame:UnregisterEvent("CALENDAR_UPDATE_EVENT_LIST")
	end
end


function calendar:restoreBackup()
	local backup = calendar.filterBackup
	if not backup.calendarShowHolidays then SetCVar("calendarShowHolidays", "0") end
	if not backup.calendarShowDarkmoon then SetCVar("calendarShowDarkmoon", "0") end
	if backup.calendarShowLockouts then SetCVar("calendarShowLockouts", "1") end
	if backup.calendarShowWeeklyHolidays then SetCVar("calendarShowWeeklyHolidays", "1") end
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


function calendar:sortHolidays(list)
	sort(list, function(e1, e2)
		if e1.name ~= e2.name then return e1.name < e2.name end
		return e1.eventID < e2.eventID
	end)
end


function calendar:getHolidayList()
	local holidays, addedIDs = {}, {}

	self:setBackup()

	C_Calendar.SetAbsMonth(self.date.month, self.date.year)
	local monthInfo = C_Calendar.GetMonthInfo()

	for day = 1, monthInfo.numDays do
		local numEvents = C_Calendar.GetNumDayEvents(0, day)
		for i = 1, numEvents do
			local e = C_Calendar.GetDayEvent(0, day, i)
			if not addedIDs[e.eventID] then
				holidays[#holidays + 1] = {
					eventID = e.eventID,
					name = e.title,
					isActive = self.activeHolidays[e.eventID],
				}
				addedIDs[e.eventID] = true
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
	self.holidayNames[eventID] = name
end


do
	local function getRemove(self, eventID)
		for _, ruleSet in ipairs(self.ruleSets) do
			for _, rules in ipairs(ruleSet) do
				for _, rule in ipairs(rules) do
					for _, cond in ipairs(rule) do
						if cond[2] == "holiday" and cond[3] == eventID then return end
					end
				end
			end
		end
		return true
	end

	function calendar:checkHolidayNames()
		for lang, holidayNames in next, mounts.globalDB.holidayNames do
			for eventID in next, holidayNames do
				if getRemove(self, eventID) then
					holidayNames[eventID] = nil
				end
			end
		end
	end
end


function calendar:updateTodayEvents()
	local date = C_DateAndTime.GetCurrentCalendarTime()
	local secondsToUpdate = ((24 - date.hour) * 60 + 1 - date.minute) * 60
	self.activeHolidays = {}

	self:setBackup()

	C_Calendar.SetAbsMonth(date.month, date.year)
	local numEvents = C_Calendar.GetNumDayEvents(0, date.monthDay)
	for i = 1, numEvents do
		local e = C_Calendar.GetDayEvent(0, date.monthDay, i)

		if e.sequenceType == "START" then
			local secondsToEvent = ((e.startTime.hour - date.hour) * 60 + e.startTime.minute - date.minute) * 60
			if secondsToEvent <= 0 then
				self.activeHolidays[e.eventID] = true
			elseif secondsToEvent < secondsToUpdate then
				secondsToUpdate = secondsToEvent
			end
		elseif e.sequenceType == "END" then
			local secondsToEvent = ((e.endTime.hour - date.hour) * 60 + e.endTime.minute - date.minute) * 60
			if secondsToEvent > 0 then
				self.activeHolidays[e.eventID] = true
				if secondsToEvent < secondsToUpdate then
					secondsToUpdate = secondsToEvent
				end
			end
		else
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