local E, L, V, P, G = unpack(select(2, ...))
local LCS = E.Libs.LCS

local _G = _G
local select, wipe, date = select, wipe, date
local time, floor, format, math, select, type, ipairs, pairs = time, floor, format, math, select, type, ipairs, pairs
local strmatch, strfind, strlen, strsub, tonumber, tostring = strmatch, strfind, strlen, strsub, tonumber, tostring
local tinsert, tremove = table.insert, table.remove

local CreateFrame = CreateFrame
local CalendarGetDate = CalendarGetDate
local GetBattlefieldArenaFaction = GetBattlefieldArenaFaction
local GetExpansionLevel = GetExpansionLevel
local GetInventorySlotInfo = GetInventorySlotInfo
local GetItemQualityColor = GetItemQualityColor
local GetInventoryItemTexture = GetInventoryItemTexture
local GetInventoryItemLink = GetInventoryItemLink
local GetInstanceInfo = GetInstanceInfo
local GetNumPartyMembers = GetNumPartyMembers
local GetNumRaidMembers = GetNumRaidMembers
local GetItemInfo = GetItemInfo
local GetTalentInfo = GetTalentInfo
local HideUIPanel = HideUIPanel
local InCombatLockdown = InCombatLockdown
local GetActiveTalentGroup = GetActiveTalentGroup
local GetCVarBool = GetCVarBool
local GetFunctionCPUUsage = GetFunctionCPUUsage
local GetTalentTabInfo = GetTalentTabInfo
local IsAddOnLoaded = IsAddOnLoaded
local IsXPUserDisabled = IsXPUserDisabled
local RequestBattlefieldScoreData = RequestBattlefieldScoreData
local SetCVar = SetCVar
local UnitFactionGroup = UnitFactionGroup
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitHasVehicleUI = UnitHasVehicleUI
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid
local UnitIsUnit = UnitIsUnit

local GetSpecialization = LCS.GetSpecialization
local GetSpecializationRole = LCS.GetSpecializationRole

local MAX_TALENT_TABS = MAX_TALENT_TABS
local NONE = NONE

local ERR_NOT_IN_COMBAT = ERR_NOT_IN_COMBAT
local PLAYER_FACTION_GROUP = PLAYER_FACTION_GROUP
local FACTION_HORDE = FACTION_HORDE
local FACTION_ALLIANCE = FACTION_ALLIANCE
local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE
local LOCALIZED_CLASS_NAMES_FEMALE = LOCALIZED_CLASS_NAMES_FEMALE
local CUSTOM_CLASS_COLORS = CUSTOM_CLASS_COLORS
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local MAX_PLAYER_LEVEL_TABLE = MAX_PLAYER_LEVEL_TABLE

local GameMenuButtonRatings = GameMenuButtonRatings
local GameMenuButtonLogout = GameMenuButtonLogout
local GameMenuFrame = GameMenuFrame

function E:ClassColor(class, usePriestColor)
	if not class then return end

	local color = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class]) or RAID_CLASS_COLORS[class]
	if type(color) ~= "table" then return end

	if not color.colorStr then
		color.colorStr = E:RGBToHex(color.r, color.g, color.b, "ff")
	elseif strlen(color.colorStr) == 6 then
		color.colorStr = "ff"..color.colorStr
	end

	if (usePriestColor and class == "PRIEST") and tonumber(color.colorStr, 16) > tonumber(E.PriestColors.colorStr, 16) then
		return E.PriestColors
	else
		return color
	end
end

do -- other non-english locales require this
	E.UnlocalizedClasses = {}
	for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do E.UnlocalizedClasses[v] = k end
	for k, v in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do E.UnlocalizedClasses[v] = k end

	function E:UnlocalizedClassName(className)
		return (className and className ~= "") and E.UnlocalizedClasses[className]
	end
end

function E:IsFoolsDay()
	return strfind(date(), "04/01/") and not E.global.aprilFools
end

function E:ScanTooltipTextures(clean, grabTextures)
	local textures
	for i = 1, 10 do
		local tex = _G["ElvUI_ScanTooltipTexture"..i]
		local texture = tex and tex:GetTexture()
		if texture then
			if grabTextures then
				if not textures then textures = {} end
				textures[i] = texture
			end
			if clean then
				tex:SetTexture()
			end
		end
	end

	return textures
end

function E:GetThreatStatusColor(status, nothreat)
	local color = ElvUF.colors.threat[status]
	if color then
		return color.r, color.g, color.b, color.a or 1
	elseif nothreat then
		if status == -1 then -- how or why?
			return 1, 1, 1, 1
		else
			return .7, .7, .7, 1
		end
	end
end

function E:GetPlayerRole()
	local role = UnitGroupRolesAssigned("player") or "NONE"
	return (role == "NONE" and E.myspec and GetSpecializationRole(E.myspec)) or role
end

function E:GetTalentSpecInfo(isInspect)
	local talantGroup = GetActiveTalentGroup(isInspect)
	local maxPoints, specIdx, specName, specIcon = 0, 0

	for i = 1, MAX_TALENT_TABS do
		local name, icon, pointsSpent = GetTalentTabInfo(i, isInspect, nil, talantGroup)
		if maxPoints < pointsSpent then
			maxPoints = pointsSpent
			specIdx = i
			specName = name
			specIcon = icon
		end
	end

	if not specName then
		specName = NONE
	end
	if not specIcon then
		specIcon = "Interface\\Icons\\INV_Misc_QuestionMark"
	end

	return specIdx, specName, specIcon
end

function E:CheckRole()
	E.myspec = GetSpecialization()
	E.myrole = E:GetPlayerRole()
end

function E:IsDispellableByMe(debuffType)
	if not self.DispelClasses[self.myclass] then return end

	if self.DispelClasses[self.myclass][debuffType] then return true end
end

do
	local Masque = E.Libs.Masque
	local MasqueGroupState = {}
	local MasqueGroupToTableElement = {
		["ActionBars"] = {"actionbar", "actionbars"},
		["Pet Bar"] = {"actionbar", "petBar"},
		["Stance Bar"] = {"actionbar", "stanceBar"},
		["Buffs"] = {"auras", "buffs"},
		["Debuffs"] = {"auras", "debuffs"},
	}

	function E:MasqueCallback(Group, _, _, _, _, Disabled)
		if not E.private then return end
		local element = MasqueGroupToTableElement[Group]
		if element then
			if Disabled then
				if E.private[element[1]].masque[element[2]] and MasqueGroupState[Group] == "enabled" then
					E.private[element[1]].masque[element[2]] = false
					E:StaticPopup_Show("CONFIG_RL")
				end
				MasqueGroupState[Group] = "disabled"
			else
				MasqueGroupState[Group] = "enabled"
			end
		end
	end

	if Masque then
		Masque:Register("ElvUI", E.MasqueCallback)
	end
end

do
	local CPU_USAGE = {}
	local function CompareCPUDiff(showall, minCalls)
		local greatestUsage, greatestCalls, greatestName, newName, newFunc
		local greatestDiff, lastModule, mod, usage, calls, diff = 0

		for name, oldUsage in pairs(CPU_USAGE) do
			newName, newFunc = strmatch(name, "^([^:]+):(.+)$")
			if not newFunc then
				E:Print("CPU_USAGE:", name, newFunc)
			else
				if newName ~= lastModule then
					mod = E:GetModule(newName, true) or E
					lastModule = newName
				end
				usage, calls = GetFunctionCPUUsage(mod[newFunc], true)
				diff = usage - oldUsage
				if showall and (calls > minCalls) then
					E:Print("Name("..name..") Calls("..calls..") Diff("..(diff > 0 and format("%.3f", diff) or 0)..")")
				end
				if (diff > greatestDiff) and calls > minCalls then
					greatestName, greatestUsage, greatestCalls, greatestDiff = name, usage, calls, diff
				end
			end
		end

		if greatestName then
			E:Print(greatestName.." had the CPU usage of: "..(greatestUsage > 0 and format("%.3f", greatestUsage) or 0).."ms. And has been called "..greatestCalls.." times.")
		else
			E:Print("CPU Usage: No CPU Usage differences found.")
		end

		wipe(CPU_USAGE)
	end

	function E:GetTopCPUFunc(msg)
		if not GetCVarBool("scriptProfile") then
			E:Print("For `/cpuusage` to work, you need to enable script profiling via: `/console scriptProfile 1` then reload. Disable after testing by setting it back to 0.")
			return
		end

		local module, showall, delay, minCalls = strmatch(msg, "^(%S+)%s*(%S*)%s*(%S*)%s*(.*)$")
		local checkCore, mod = (not module or module == "") and "E"

		showall = (showall == "true" and true) or false
		delay = (delay == "nil" and nil) or tonumber(delay) or 5
		minCalls = (minCalls == "nil" and nil) or tonumber(minCalls) or 15

		wipe(CPU_USAGE)
		if module == "all" then
			for moduName, modu in pairs(self.modules) do
				for funcName, func in pairs(modu) do
					if (funcName ~= "GetModule") and (type(func) == "function") then
						CPU_USAGE[moduName..":"..funcName] = GetFunctionCPUUsage(func, true)
					end
				end
			end
		else
			if not checkCore then
				mod = self:GetModule(module, true)
				if not mod then
					self:Print(module.." not found, falling back to checking core.")
					mod, checkCore = self, "E"
				end
			else
				mod = self
			end
			for name, func in pairs(mod) do
				if (name ~= "GetModule") and type(func) == "function" then
					CPU_USAGE[(checkCore or module)..":"..name] = GetFunctionCPUUsage(func, true)
				end
			end
		end

		self:Delay(delay, CompareCPUDiff, showall, minCalls)
		self:Print("Calculating CPU Usage differences (module: "..(checkCore or module)..", showall: "..tostring(showall)..", minCalls: "..tostring(minCalls)..", delay: "..tostring(delay)..")")
	end
end

function E:RegisterObjectForVehicleLock(object, originalParent)
	if not object or not originalParent then
		E:Print("Error. Usage: RegisterObjectForVehicleLock(object, originalParent)")
		return
	end

	object = _G[object] or object
	--Entering/Exiting vehicles will often happen in combat.
	--For this reason we cannot allow protected objects.
	if object.IsProtected and object:IsProtected() then
		E:Print("Error. Object is protected and cannot be changed in combat.")
		return
	end

	--Check if we are already in a vehicles
	if UnitHasVehicleUI("player") then
		object:SetParent(E.HiddenFrame)
	end

	--Add object to table
	E.VehicleLocks[object] = originalParent
end

function E:UnregisterObjectForVehicleLock(object)
	if not object then
		E:Print("Error. Usage: UnregisterObjectForVehicleLock(object)")
		return
	end

	object = _G[object] or object
	--Check if object was registered to begin with
	if not E.VehicleLocks[object] then return end

	--Change parent of object back to original parent
	local originalParent = E.VehicleLocks[object]
	if originalParent then
		object:SetParent(originalParent)
	end

	--Remove object from table
	E.VehicleLocks[object] = nil
end

function E:EnterVehicleHideFrames(_, unit)
	if unit ~= "player" then return end

	for object in pairs(E.VehicleLocks) do
		object:SetParent(E.HiddenFrame)
	end
end

function E:ExitVehicleShowFrames(_, unit)
	if unit ~= "player" then return end

	for object, originalParent in pairs(E.VehicleLocks) do
		object:SetParent(originalParent)
	end
end

E.CreatedSpinnerFrames = {}

function E:CreateSpinnerFrame()
	local frame = CreateFrame("Frame")
	frame:EnableMouse(true)
	frame:Hide()

	frame.Background = frame:CreateTexture(nil, "BACKGROUND")
	frame.Background:SetTexture(0, 0, 0, 0.5)
	frame.Background:SetAllPoints()

	frame.Framing = frame:CreateTexture()
	frame.Framing:Size(48)
	frame.Framing:SetTexture(E.Media.Textures.StreamFrame)
	frame.Framing:SetPoint("CENTER")

	frame.Circle = frame:CreateTexture(nil, "BORDER")
	frame.Circle:Size(48)
	frame.Circle:SetTexture(E.Media.Textures.StreamCircle)
	frame.Circle:SetVertexColor(1, .82, 0)
	frame.Circle:SetPoint("CENTER")

	frame.Circle.Anim = frame.Circle:CreateAnimationGroup()
	frame.Circle.Anim:SetLooping("REPEAT")
	frame.Circle.Anim.Rotation = frame.Circle.Anim:CreateAnimation("Rotation")
	frame.Circle.Anim.Rotation:SetDuration(1)
	frame.Circle.Anim.Rotation:SetDegrees(-360)

	frame.Spark = frame:CreateTexture(nil, "OVERLAY")
	frame.Spark:Size(48)
	frame.Spark:SetTexture(E.Media.Textures.StreamSpark)
	frame.Spark:SetPoint("CENTER")

	frame.Spark.Anim = frame.Spark:CreateAnimationGroup()
	frame.Spark.Anim:SetLooping("REPEAT")
	frame.Spark.Anim.Rotation = frame.Spark.Anim:CreateAnimation("Rotation")
	frame.Spark.Anim.Rotation:SetDuration(1)
	frame.Spark.Anim.Rotation:SetDegrees(-360)

	return frame
end

function E:StartSpinnerFrame(parent, left, top, right, bottom)
	if parent.SpinnerFrame then return end

	local frame = #self.CreatedSpinnerFrames > 0 and tremove(self.CreatedSpinnerFrames) or self:CreateSpinnerFrame()

	frame:SetParent(parent)
	frame:SetFrameLevel(parent:GetFrameLevel() + 10)
	frame:ClearAllPoints()
	if top or bottom or left or right then
		frame:Point("TOPLEFT", left or 0, -top or 0)
		frame:Point("BOTTOMRIGHT", -right or 0, bottom or 0)
	else
		frame:SetAllPoints()
	end

	frame:Show()
	frame.Circle.Anim.Rotation:Play()
	frame.Spark.Anim.Rotation:Play()

	parent.SpinnerFrame = frame
end

function E:StopSpinnerFrame(parent)
	if not parent.SpinnerFrame then return end

	local frame = parent.SpinnerFrame
	frame:Hide()
	frame.Circle.Anim:Stop()
	frame.Spark.Anim:Stop()

	parent.SpinnerFrame = nil
	tinsert(self.CreatedSpinnerFrames, frame)
end

function E:RequestBGInfo()
	RequestBattlefieldScoreData()
end

function E:PLAYER_ENTERING_WORLD()
	E:CheckRole()

	if not ElvDB.DisabledAddOns then
		ElvDB.DisabledAddOns = {}
	end

	E:CheckIncompatible()

	if not E.MediaUpdated then
		E:UpdateMedia()
		E.MediaUpdated = true
	end

	-- Blizzard will set this value to int(60/CVar cameraDistanceMax)+1 at logout if it is manually set higher than that
	if E.db.general.lockCameraDistanceMax then
		SetCVar("cameraDistanceMax", E.db.general.cameraDistanceMax)
	end

	local _, instanceType = GetInstanceInfo()
	if instanceType == "pvp" then
		E.BGTimer = E:ScheduleRepeatingTimer("RequestBGInfo", 5)
		E:RequestBGInfo()
	elseif E.BGTimer then
		E:CancelTimer(E.BGTimer)
		E.BGTimer = nil
	end
end

function E:PLAYER_REGEN_ENABLED()
	if E.ShowOptions then
		E:ToggleOptionsUI()

		E.ShowOptions = nil
	end
end

function E:PLAYER_REGEN_DISABLED()
	local err

	if IsAddOnLoaded("ElvUI_OptionsUI") then
		local ACD = E.Libs.AceConfigDialog
		if ACD and ACD.OpenFrames and ACD.OpenFrames.ElvUI then
			ACD:Close("ElvUI")
			err = true
		end
	end

	if E.CreatedMovers then
		for name in pairs(E.CreatedMovers) do
			local mover = _G[name]
			if mover and mover:IsShown() then
				mover:Hide()
				err = true
			end
		end
	end

	if err then
		E:Print(ERR_NOT_IN_COMBAT)
	end
end

function E:XPIsUserDisabled()
	return IsXPUserDisabled()
end

function E:XPIsLevelMax()
	return E.mylevel >= MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()] or E:XPIsUserDisabled()
end

function E:GetGroupUnit(unit)
	if UnitIsUnit(unit, "player") then return end
	if strfind(unit, "party") or strfind(unit, "raid") then
		return unit
	end

	-- returns the unit as raid# or party# when grouped
	if UnitInParty(unit) or UnitInRaid(unit) then
		local isInRaid = (GetNumRaidMembers() > 1)
		for i = 1, GetNumPartyMembers() do
			local groupUnit = (isInRaid and "raid" or "party")..i
			if UnitIsUnit(unit, groupUnit) then
				return groupUnit
			end
		end
	end
end

function E:GetUnitBattlefieldFaction(unit)
	local englishFaction, localizedFaction = UnitFactionGroup(unit)

	-- this might be a rated BG or wargame and if so the player's faction might be altered
	if unit == "player" then
		englishFaction = PLAYER_FACTION_GROUP[GetBattlefieldArenaFaction()]
		localizedFaction = (englishFaction == "Alliance" and FACTION_ALLIANCE) or FACTION_HORDE
	end

	return englishFaction, localizedFaction
end

local titanGrip
local qualityColors = {}

do
	for i = 0, 7 do
		qualityColors[i] = {GetItemQualityColor(i)}
	end

	if E.myclass == "WARRIOR" then
		local GetTalentInfo = GetTalentInfo

		local titanGripCheck = CreateFrame("Frame")
		titanGripCheck:RegisterEvent("PLAYER_ENTERING_WORLD")
		titanGripCheck:RegisterEvent("SPELL_UPDATE_USABLE")
		titanGripCheck:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
		titanGripCheck:RegisterEvent("CHARACTER_POINTS_CHANGED")
		titanGripCheck:SetScript("OnEvent", function(self, event, ...)
			titanGrip = select(5, GetTalentInfo(2, 27)) == 1

			if event == "PLAYER_ENTERING_WORLD" or event == "SPELL_UPDATE_USABLE" then
				self:UnregisterEvent(event)
			end
		end)
	end
end

function E:PositionGameMenuButton()
	GameMenuFrame:Height(GameMenuFrame:GetHeight() + GameMenuButtonLogout:GetHeight() - 4)

	local button = GameMenuFrame.ElvUI
	button:SetFormattedText("%s%s|r", E.media.hexvaluecolor, "ElvUI")

	local _, relTo, _, _, offY = GameMenuButtonLogout:GetPoint()
	if relTo ~= button then
		button:ClearAllPoints()
		button:Point("TOPLEFT", relTo, "BOTTOMLEFT", 0, -1)
		GameMenuButtonLogout:ClearAllPoints()
		GameMenuButtonLogout:Point("TOPLEFT", button, "BOTTOMLEFT", 0, offY)
	end
end

function E:PLAYER_LEVEL_UP(_, level)
	E.mylevel = level
end

function E:ClickGameMenu()
	E:ToggleOptionsUI() -- we already prevent it from opening in combat

	if not InCombatLockdown() then
		HideUIPanel(GameMenuFrame)
	end
end

function E:SetupGameMenu()
	local button = CreateFrame("Button", nil, GameMenuFrame, "GameMenuButtonTemplate")
	button:SetScript("OnClick", E.ClickGameMenu)
	GameMenuFrame.ElvUI = button

	E.PositionGameMenuButton()
end

function E:GetAverageItemLevel()
	local items = 16
	local ilvl = 0
	local colorCount, sumR, sumG, sumB = 0, 0, 0, 0

	for slotID = 1, 18 do
		if slotID ~= INVSLOT_BODY then
			local itemLink = GetInventoryItemLink("player", slotID)

			if itemLink then
				local _, _, quality, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)

				if itemLevel then
					ilvl = ilvl + itemLevel

					local color = qualityColors[quality]
					sumR = sumR + color[1]
					sumG = sumG + color[2]
					sumB = sumB + color[3]

					colorCount = colorCount + 1

					if slotID == INVSLOT_MAINHAND and (itemEquipLoc ~= "INVTYPE_2HWEAPON" or titanGrip) then
						items = 17
					end
				end
			end
		end
	end

	if colorCount == 0 then
		return ilvl / items, 1, 1, 1
	else
		return ilvl / items, sumR / colorCount, sumG / colorCount, sumB / colorCount
	end
end

function E:GetItemLevelColor(unit)
	if not unit then
		unit = "player"
	end

	local slots = {
		"HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "WristSlot",
		"HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot",
		"Trinket0Slot", "Trinket1Slot", "MainHandSlot", "SecondaryHandSlot"
	}

	local i, sumR, sumG, sumB = 0, 0, 0, 0

	for _, slotName in ipairs(slots) do
		local slotID = GetInventorySlotInfo(slotName)
		local texture = GetInventoryItemTexture(unit, slotID)
		if texture then
			local itemLink = GetInventoryItemLink(unit, slotID)
			if itemLink then
				local quality = select(3, GetItemInfo(itemLink))
				if quality then
					i = i + 1
					local r, g, b = GetItemQualityColor(quality)
					sumR = sumR + r
					sumG = sumG + g
					sumB = sumB + b
				end
			end
		end
	end

	if i > 0 then
		return sumR / i, sumG / i, sumB / i
	else
		return 1, 1, 1
	end
end

function E:BreakUpLargeNumbers(value, dobreak)
	-- Credits: bkader
	-- Source: https://github.com/bkader/Compat-WotLK/blob/main/Compat/elements/math.lua#L43

	local retString = ""
	if value < 1000 then
		if (value - floor(value)) == 0 then
			return value
		end
		local decimal = floor(value * 100)
		retString = strsub(decimal, 1, -3)
		retString = retString .. "."
		retString = retString .. strsub(decimal, -2)
		return retString
	end

	value = floor(value)
	local strLen = strlen(value)
	if dobreak then
		if (strLen > 6) then
			retString = strsub(value, 1, -7) .. ","
		end
		if (strLen > 3) then
			retString = retString .. strsub(value, -6, -4) .. ","
		end
		retString = retString .. strsub(value, -3, -1)
	else
		retString = value
	end

	return retString
end

function E:GetCurrentCalendarTime()
	local dateTable = {}
	local weekday, month, monthDay, year  = CalendarGetDate()
	dateTable.weekday = weekday
	dateTable.month = month
	dateTable.monthDay = monthDay
	dateTable.year = year

	local timeInSeconds = time()
	local timeInMinutes = math.floor(timeInSeconds / 60)
	local timeInHours = math.floor(timeInMinutes / 60)
	local timeInDays = math.floor(timeInHours / 24)
	dateTable.minute = timeInMinutes % 60
	dateTable.hour = timeInHours % 24

	return dateTable
end

function E:LoadAPI()
	E:RegisterEvent("PLAYER_LEVEL_UP")
	E:RegisterEvent("PLAYER_ENTERING_WORLD")
	E:RegisterEvent("PLAYER_REGEN_ENABLED")
	E:RegisterEvent("PLAYER_REGEN_DISABLED")
	E:RegisterEvent("SPELL_UPDATE_USABLE", "CheckRole")
	E:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "CheckRole")
	E:RegisterEvent("PLAYER_TALENT_UPDATE", "CheckRole")
	E:RegisterEvent("CHARACTER_POINTS_CHANGED", "CheckRole")
	E:RegisterEvent("UNIT_INVENTORY_CHANGED", "CheckRole")
	E:RegisterEvent("UPDATE_BONUS_ACTIONBAR", "CheckRole")
	E:RegisterEvent("UNIT_ENTERED_VEHICLE", "EnterVehicleHideFrames")
	E:RegisterEvent("UNIT_EXITED_VEHICLE", "ExitVehicleShowFrames")
	E:RegisterEvent("UI_SCALE_CHANGED", "PixelScaleChanged")

	E:SetupGameMenu()

	do -- setup cropIcon texCoords
		local opt = E.db.general.cropIcon
		local modifier = 0.04 * opt
		for i, v in ipairs(E.TexCoords) do
			if i % 2 == 0 then
				E.TexCoords[i] = v - modifier
			else
				E.TexCoords[i] = v + modifier
			end
		end
	end
end