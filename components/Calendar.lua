local C_Calendar, pairs, sort = C_Calendar, pairs, sort
local mounts = MountsJournal
local calendar = MountsJournalUtil.createFromEventsMixin()
mounts.calendar = calendar
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


function calendar:setFilterBackup()
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
end


function calendar:restoreFilterBackup()
	local backup = calendar.filterBackup
	if not backup.calendarShowHolidays then SetCVar("calendarShowHolidays", "0") end
	if not backup.calendarShowDarkmoon then SetCVar("calendarShowDarkmoon", "0") end
	if backup.calendarShowLockouts then SetCVar("calendarShowLockouts", "1") end
	if backup.calendarShowWeeklyHolidays then SetCVar("calendarShowWeeklyHolidays", "1") end
	if backup.calendarShowBattlegrounds then SetCVar("calendarShowBattlegrounds", "1") end
end


function calendar:setDateBackup()
	self.dateBackup = C_Calendar.GetMonthInfo()
	if CalendarFrame then
		CalendarFrame:UnregisterEvent("CALENDAR_UPDATE_EVENT_LIST")
		CalendarEventPickerFrame:UnregisterEvent("CALENDAR_UPDATE_EVENT_LIST")
	end
end


function calendar:restoreDateBackup()
	C_Calendar.SetAbsMonth(self.dateBackup.month, self.dateBackup.year)
	if CalendarFrame then
		CalendarFrame:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST")
		CalendarEventPickerFrame:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST")
	end
end


function calendar:getSelectedMonthInfo()
	self:setDateBackup()
	C_Calendar.SetAbsMonth(self.date.month, self.date.year)
	local monthInfo = C_Calendar.GetMonthInfo()
	self:restoreDateBackup()
	return monthInfo
end


function calendar:setPreviousMonth()
	self.date.month = self.date.month - 1
	if self.date.month < 1 then
		self.date.year = self.date.year - 1
		self.date.month = 12
	end

	if self.date.monthDay > 28 then
		local monthInfo = self:getSelectedMonthInfo()
		if self.date.monthDay > monthInfo.numDays then
			self.date.monthDay = monthInfo.numDays
		end
	end
end


function calendar:setNextMonth()
	self.date.month = self.date.month + 1
	if self.date.month > 12 then
		self.date.year = self.date.year + 1
		self.date.month = 1
	end

	if self.date.monthDay > 28 then
		local monthInfo = self:getSelectedMonthInfo()
		if self.date.monthDay > monthInfo.numDays then
			self.date.monthDay = monthInfo.numDays
		end
	end
end


function calendar:setPreviousDay()
	self.date.monthDay = self.date.monthDay - 1
	if self.date.monthDay < 1 then
		self.date.monthDay = 31
		calendar:setPreviousMonth()
	end
end


function calendar:setNextDay()
	self.date.monthDay = self.date.monthDay + 1

	if self.date.monthDay > 28 then
		local monthInfo = self:getSelectedMonthInfo()
		if self.date.monthDay > monthInfo.numDays then
			self.date.monthDay = 1
			calendar:setNextMonth()
		end
	end
end


function calendar:setCurrentDate()
	self.date = C_DateAndTime.GetCurrentCalendarTime()
end


function calendar:getSelectedDate()
	return self.date, CALENDAR_MONTH_NAMES[self.date.month]
end


function calendar:sortHolidays(list)
	sort(list, function(e1, e2)
		if not e1.profile and e2.profile then return true
		elseif e1.profile and not e2.profile then return false
		elseif e1.profile and e2.profile then
			return e1.profile.order < e2.profile.order
		end

		if e1.name and e2.name then return e1.name < e2.name
		elseif e1.name and not e2.name then return true
		elseif not e1.name and e2.name then return false end

		return e1.eventID < e2.eventID
	end)
end


function calendar:getHolidayList()
	local holidays = {}

	self:setFilterBackup()
	self:setDateBackup()

	C_Calendar.SetAbsMonth(self.date.month, self.date.year)
	local numEvents = C_Calendar.GetNumDayEvents(0, self.date.monthDay)

	for i = 1, numEvents do
		local e = C_Calendar.GetDayEvent(0, self.date.monthDay, i)
		if not self.holidayProfiles[e.eventID] then
			holidays[#holidays + 1] = {
				eventID = e.eventID,
				name = e.title,
				isActive = self:isEventActive(e.eventID)
			}
		end
	end

	self:restoreDateBackup()
	self:restoreFilterBackup()

	for eventID, data in pairs(self.holidayProfiles) do
		holidays[#holidays + 1] = {
			eventID = eventID,
			name = self.holidayNames[eventID],
			isActive = self:isEventActive(eventID),
			profile = data,
		}
	end

	self:sortHolidays(holidays)
	return holidays
end


function calendar:createEventProfile(eventID, enabled, profileName)
	self.numHolidayProfiles = self.numHolidayProfiles + 1
	self.holidayProfiles[eventID] = {
		enabled = enabled,
		profileName = profileName,
		order = self.numHolidayProfiles,
	}
	self:sortTodayEvents()
end


function calendar:removeEventProfile(eventID)
	local order = self.holidayProfiles[eventID].order
	self.holidayProfiles[eventID] = nil
	self.numHolidayProfiles = self.numHolidayProfiles - 1

	for eventID, data in pairs(self.holidayProfiles) do
		if data.order > order then
			data.order = data.order - 1
		end
	end

	for lang, holidayNames in pairs(mounts.globalDB.holidayNames) do
		holidayNames[eventID] = nil
	end

	self:sortTodayEvents()
end


function calendar:setEventProfileEnabled(eventID, enabled, eventName)
	if self.holidayProfiles[eventID] then
		self.holidayProfiles[eventID].enabled = enabled
		if not (enabled or self.holidayProfiles[eventID].profileName) then
			self:removeEventProfile(eventID)
		else
			self:event("CALENDAR_UPDATE_EVENT_LIST")
		end
	elseif enabled then
		self:createEventProfile(eventID, enabled)
		self.holidayNames[eventID] = eventName
	end
end


function calendar:setEventProfileName(eventID, name, eventName)
	if self.holidayProfiles[eventID] then
		self.holidayProfiles[eventID].profileName = name
		if not (name or self.holidayProfiles[eventID].enabled) then
			self:removeEventProfile(eventID)
		else
			self:event("CALENDAR_UPDATE_EVENT_LIST")
		end
	elseif name then
		self:createEventProfile(eventID, nil, name)
		self.holidayNames[eventID] = eventName
	end
end


function calendar:setEventProfileOrder(eventID, step)
	local curOrder = self.holidayProfiles[eventID].order
	local newOrder = curOrder + step
	if newOrder > 0 and newOrder <= self.numHolidayProfiles then
		for _, data in pairs(self.holidayProfiles) do
			if data.order == newOrder then
				data.order = curOrder
				break
			end
		end
		self.holidayProfiles[eventID].order = newOrder
	end
	self:sortTodayEvents()
end


function calendar:isEventActive(eventID)
	for i = 1, #self.todayHolidays do
		if eventID == self.todayHolidays[i] then return true end
	end
end


function calendar:sortTodayEvents()
	sort(self.todayHolidays, function(e1, e2)
		local data1 = self.holidayProfiles[e1]
		local data2 = self.holidayProfiles[e2]
		return data1 and not data2
			or data1 and data2 and data1.order < data2.order
			or data1 == data2 and e1 < e2
	end)
	self:event("CALENDAR_UPDATE_EVENT_LIST")
end


function calendar:updateTodayEvents()
	local date = C_DateAndTime.GetCurrentCalendarTime()
	local secondsToUpdate = ((24 - date.hour) * 60 + 1 - date.minute) * 60
	self.todayHolidays = {}

	self:setFilterBackup()
	self:setDateBackup()

	C_Calendar.SetAbsMonth(date.month, date.year)
	local numEvents = C_Calendar.GetNumDayEvents(0, date.monthDay)
	for i = 1, numEvents do
		local e = C_Calendar.GetDayEvent(0, date.monthDay, i)

		if e.sequenceType == "START" then
			local secondsToEvent = ((e.startTime.hour - date.hour) * 60 + e.startTime.minute - date.minute) * 60
			if secondsToEvent <= 0 then
				self.todayHolidays[#self.todayHolidays + 1] = e.eventID
			elseif secondsToEvent < secondsToUpdate then
				secondsToUpdate = secondsToEvent
			end
		elseif e.sequenceType == "END" then
			local secondsToEvent = ((e.endTime.hour - date.hour) * 60 + e.endTime.minute - date.minute) * 60
			if secondsToEvent > 0 then
				self.todayHolidays[#self.todayHolidays + 1] = e.eventID
				if secondsToEvent < secondsToUpdate then
					secondsToUpdate = secondsToEvent
				end
			end
		else
			self.todayHolidays[#self.todayHolidays + 1] = e.eventID
		end
	end

	self:restoreDateBackup()
	self:restoreFilterBackup()

	self:sortTodayEvents()
	C_Timer.After(secondsToUpdate, function() self:updateTodayEvents() end)
end


function calendar:getHolidayProfileName()
	for eventID, data in pairs(self.holidayProfiles) do
		if data.profileName and not self.profiles[data.profileName] then
			data.profileName = nil
			if not data.enabled then
				self:removeEventProfile(eventID)
			end
		end
	end

	for i = 1, #self.todayHolidays do
		local data = self.holidayProfiles[self.todayHolidays[i]]
		if data and data.enabled then
			return true, data.profileName
		elseif not data then
			break
		end
	end
	return false
end


function calendar:init()
	self.init = nil

	self.profiles = mounts.profiles
	self.holidayProfiles = mounts.charDB.holidayProfiles
	self.numHolidayProfiles = 0
	for eventID in pairs(self.holidayProfiles) do
		self.numHolidayProfiles = self.numHolidayProfiles + 1
	end
	self:updateTodayEvents()

	self.holidayNames = mounts.globalDB.holidayNames[GetLocale()] or {}
	mounts.globalDB.holidayNames[GetLocale()] = self.holidayNames
	local names = self.holidayNames

	local numNoName = 0
	for eventID, profile in pairs(self.holidayProfiles) do
		if not names[eventID] then
			numNoName = numNoName + 1
			names[eventID] = false
		end
	end

	if numNoName == 0 then return end

	self:setFilterBackup()
	self:setDateBackup()

	local date = C_DateAndTime.GetCurrentCalendarTime()
	local year = date.year - 2
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

	self:restoreDateBackup()
	self:restoreFilterBackup()
end