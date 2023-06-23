local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local _G = _G
local next, unpack = next, unpack
local format, strjoin = format, strjoin
local sort, tinsert = sort, tinsert
local date, utf8sub = date, string.utf8sub

local ToggleFrame = ToggleFrame
local GetDifficultyInfo = GetDifficultyInfo
local GetNumSavedInstances = GetNumSavedInstances
local GetSavedInstanceInfo = GetSavedInstanceInfo
local RequestRaidInfo = RequestRaidInfo
local SecondsToTime = SecondsToTime
local InCombatLockdown = InCombatLockdown

local TIMEMANAGER_TOOLTIP_LOCALTIME = TIMEMANAGER_TOOLTIP_LOCALTIME
local TIMEMANAGER_TOOLTIP_REALMTIME = TIMEMANAGER_TOOLTIP_REALMTIME

local APM = { TIMEMANAGER_PM, TIMEMANAGER_AM }
local ukDisplayFormat, europeDisplayFormat = '', ''
local europeDisplayFormat_nocolor = strjoin('', '%02d', ':|r%02d')
local ukDisplayFormat_nocolor = strjoin('', '', '%d', ':|r%02d', ' %s|r')
local lockoutInfoFormat = '%s%s %s |cffaaaaaa(%s, %s/%s)'
local lockoutInfoFormatNoEnc = '%s%s %s |cffaaaaaa(%s)'
local lockoutColorExtended, lockoutColorNormal = { r=0.3,g=1,b=0.3 }, { r=.8,g=.8,b=.8 }
local enteredFrame = false

local OnUpdate, db

local function ToTime(start, seconds)
	return SecondsToTime(start, not seconds, nil, 3)
end

local function ApplySettings(self, hex)
	if not db then
		db = E.global.datatexts.settings[self.name]
	end

	europeDisplayFormat = strjoin('', '%02d', hex, ':|r%02d')
	ukDisplayFormat = strjoin('', '', '%d', hex, ':|r%02d', hex, ' %s|r')

	OnUpdate(self, 20000)
end

local function ConvertTime(h, m)
	local AmPm
	if db.time24 == true then
		return h, m, -1
	else
		if h >= 12 then
			if h > 12 then h = h - 12 end
			AmPm = 1
		else
			if h == 0 then h = 12 end
			AmPm = 2
		end
	end

	return h, m, AmPm
end

local function CalculateTimeValues(tooltip)
	if (tooltip and db.localTime) or (not tooltip and not db.localTime) then
		local dateTable = E:GetCurrentCalendarTime()
		return ConvertTime(dateTable.hour, dateTable.minute)
	else
		local dateTable = date('*t')
		return ConvertTime(dateTable.hour, dateTable.min)
	end
end

local function OnClick(_, btn)
	if InCombatLockdown() then UIErrorsFrame:AddMessage(E.InfoColor..ERR_NOT_IN_COMBAT) return end

	if btn == 'RightButton' then
		ToggleFrame(TimeManagerFrame)
		GameTimeFrame:Click()
	end
end

local function OnLeave()
	enteredFrame = false
end

local krcntw = E.locale == 'koKR' or E.locale == 'zhCN' or E.locale == 'zhTW'
local difficultyTag = { -- RNormal, Heroic
	(krcntw and PLAYER_DIFFICULTY1) or utf8sub(PLAYER_DIFFICULTY1, 1, 1),	-- N
	(krcntw and PLAYER_DIFFICULTY2) or utf8sub(PLAYER_DIFFICULTY2, 1, 1),	-- H
}

local function sortFunc(a,b) return a[1] < b[1] end

local collectedInstanceImages = false
local function OnEnter()
	DT.tooltip:ClearLines()

	if not enteredFrame then
		enteredFrame = true
		RequestRaidInfo()
	end

	local lockedInstances = {raids = {}, dungeons = {}}

	for i = 1, GetNumSavedInstances() do
		local name, _, _, difficulty, locked, extended, _, isRaid = GetSavedInstanceInfo(i)
		if (locked or extended) and name then
			local isLFR, isHeroicOrMythicDungeon = (difficulty == 7 or difficulty == 17), (difficulty == 2 or difficulty == 23 or difficulty == 174)
			local _, _, isHeroic, _, displayHeroic, displayMythic = GetDifficultyInfo(difficulty)
			local sortName = name .. (displayMythic and 4 or (isHeroic or displayHeroic) and 3 or isLFR and 1 or 2)
			local difficultyLetter = (displayMythic and difficultyTag[4] or (isHeroic or displayHeroic) and difficultyTag[3] or isLFR and difficultyTag[1] or difficultyTag[2])
			local buttonImg = instanceIconByName[name] and format('|T%s:16:16:0:0:96:96:0:64:0:64|t ', instanceIconByName[name]) or ''

			if isRaid then
				tinsert(lockedInstances.raids, {sortName, difficultyLetter, buttonImg, {GetSavedInstanceInfo(i)}})
			elseif isHeroicOrMythicDungeon then
				tinsert(lockedInstances.dungeons, {sortName, difficultyLetter, buttonImg, {GetSavedInstanceInfo(i)}})
			end
		end
	end

	if next(lockedInstances.raids) then
		if DT.tooltip:NumLines() > 0 then
			DT.tooltip:AddLine(' ')
		end
		DT.tooltip:AddLine(L["Saved Raid(s)"])

		sort(lockedInstances.raids, sortFunc)

		for i = 1, #lockedInstances.raids do
			local difficultyLetter = lockedInstances.raids[i][2]
			local buttonImg = lockedInstances.raids[i][3]
			local name, _, reset, _, _, extended, _, _, maxPlayers, _, numEncounters, encounterProgress = unpack(lockedInstances.raids[i][4])

			local lockoutColor = extended and lockoutColorExtended or lockoutColorNormal
			if numEncounters and numEncounters > 0 and (encounterProgress and encounterProgress > 0) then
				DT.tooltip:AddDoubleLine(format(lockoutInfoFormat, buttonImg, maxPlayers, difficultyLetter, name, encounterProgress, numEncounters), ToTime(reset), 1, 1, 1, lockoutColor.r, lockoutColor.g, lockoutColor.b)
			else
				DT.tooltip:AddDoubleLine(format(lockoutInfoFormatNoEnc, buttonImg, maxPlayers, difficultyLetter, name), ToTime(reset), 1, 1, 1, lockoutColor.r, lockoutColor.g, lockoutColor.b)
			end
		end
	end

	if next(lockedInstances.dungeons) then
		if DT.tooltip:NumLines() > 0 then
			DT.tooltip:AddLine(' ')
		end
		DT.tooltip:AddLine(L["Saved Dungeon(s)"])

		sort(lockedInstances.dungeons, sortFunc)

		for i = 1,#lockedInstances.dungeons do
			local difficultyLetter = lockedInstances.dungeons[i][2]
			local buttonImg = lockedInstances.dungeons[i][3]
			local name, _, reset, _, _, extended, _, _, maxPlayers, _, numEncounters, encounterProgress = unpack(lockedInstances.dungeons[i][4])

			local lockoutColor = extended and lockoutColorExtended or lockoutColorNormal
			if numEncounters and numEncounters > 0 and (encounterProgress and encounterProgress > 0) then
				DT.tooltip:AddDoubleLine(format(lockoutInfoFormat, buttonImg, maxPlayers, difficultyLetter, name, encounterProgress, numEncounters), ToTime(reset), 1, 1, 1, lockoutColor.r, lockoutColor.g, lockoutColor.b)
			else
				DT.tooltip:AddDoubleLine(format(lockoutInfoFormatNoEnc, buttonImg, maxPlayers, difficultyLetter, name), ToTime(reset), 1, 1, 1, lockoutColor.r, lockoutColor.g, lockoutColor.b)
			end
		end
	end

	local Hr, Min, AmPm = CalculateTimeValues(true)
	if DT.tooltip:NumLines() > 0 then
		DT.tooltip:AddLine(' ')
	end

	if AmPm == -1 then
		DT.tooltip:AddDoubleLine(db.localTime and TIMEMANAGER_TOOLTIP_REALMTIME or TIMEMANAGER_TOOLTIP_LOCALTIME, format(europeDisplayFormat_nocolor, Hr, Min), 1, 1, 1, lockoutColorNormal.r, lockoutColorNormal.g, lockoutColorNormal.b)
	else
		DT.tooltip:AddDoubleLine(db.localTime and TIMEMANAGER_TOOLTIP_REALMTIME or TIMEMANAGER_TOOLTIP_LOCALTIME, format(ukDisplayFormat_nocolor, Hr, Min, APM[AmPm]), 1, 1, 1, lockoutColorNormal.r, lockoutColorNormal.g, lockoutColorNormal.b)
	end

	DT.tooltip:Show()
end

local function OnEvent(self, event)
	if event == 'LOADING_SCREEN_ENABLED' and enteredFrame then
		OnLeave()
	elseif event == 'UPDATE_INSTANCE_INFO' and enteredFrame then
		OnEnter(self)
	end
end

function OnUpdate(self, t)
	self.timeElapsed = (self.timeElapsed or 5) - t
	if self.timeElapsed > 0 then return end
	self.timeElapsed = 5

	if E.Retail then
		if db.flashInvite and GameTimeFrame.flashInvite then
			E:Flash(self, 0.53, true)
		else
			E:StopFlash(self)
		end
	end

	if enteredFrame then
		OnEnter(self)
	end

	local Hr, Min, AmPm = CalculateTimeValues()

	if AmPm == -1 then
		self.text:SetFormattedText(europeDisplayFormat, Hr, Min)
	else
		self.text:SetFormattedText(ukDisplayFormat, Hr, Min, APM[AmPm])
	end
end

DT:RegisterDatatext('Time', nil, { 'UPDATE_INSTANCE_INFO', 'LOADING_SCREEN_ENABLED' }, OnEvent, OnUpdate, OnClick, OnEnter, OnLeave, nil, nil, ApplySettings)
