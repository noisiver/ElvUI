local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule("DataTexts")

local strjoin = string.join
local IsFalling = IsFalling
local IsFlying = IsFlying
local IsSwimming = IsSwimming
local GetUnitSpeed = GetUnitSpeed

local displayString, db = ""
local beforeFalling, wasFlying

local delayed
local function DelayUpdate(self)
	local unitSpeed = GetUnitSpeed("player")
	local speed

	if IsSwimming() then
		speed = unitSpeed
		wasFlying = false
	elseif IsFlying() then
		speed = unitSpeed
		wasFlying = true
	else
		speed = unitSpeed
		wasFlying = false
	end

	if IsFalling() and wasFlying and beforeFalling then
		speed = beforeFalling
	else
		beforeFalling = speed
	end

	local percent = speed / 7 * 100
	if db.NoLabel then
		self.text:SetFormattedText(displayString, percent)
	else
		self.text:SetFormattedText(displayString, db.Label ~= "" and db.Label or L["Mov. Speed"], percent)
	end

	delayed = nil
end

local function OnEvent(self)
	if not delayed then
		delayed = E:ScheduleRepeatingTimer(DelayUpdate, 0.5, self)
	end
end

local function ApplySettings(self, hex)
	if not db then
		db = E.global.datatexts.settings[self.name]
	end

	displayString = strjoin("", db.NoLabel and "" or "%s: ", hex, "%."..db.decimalLength.."f%%|r")
end

DT:RegisterDatatext("MovementSpeed", L["Enhancements"], { "UNIT_STATS", "UNIT_AURA", "UNIT_SPELL_HASTE" }, OnEvent, nil, nil, nil, nil, L["Movement Speed"], nil, ApplySettings)