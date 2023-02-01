local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule("DataTexts")

local floor, format, strjoin = floor, format, strjoin
local COMBAT = COMBAT

local displayString, lastPanel = ""
local timerText, timer = COMBAT, 0

local function UpdateText()
	return format(E.global.datatexts.settings.Combat.TimeFull and "%02d:%02d:%02d" or "%02d:%02d", floor(timer/60), timer % 60, (timer - floor(timer)) * 100)
end

local function OnUpdate(self, elapsed)
	timer = timer + elapsed
	if timer > 0 then return end
	self.text:SetFormattedText(displayString, timerText, UpdateText())
end

local function OnEvent(self, event)
	local noLabel = E.global.datatexts.settings.Combat.NoLabel and ""

	if event == "PLAYER_REGEN_ENABLED" then
		self:SetScript("OnUpdate", nil)
	elseif event == "PLAYER_REGEN_DISABLED" then
		timerText, timer = noLabel or timerText, 0
		self:SetScript("OnUpdate", OnUpdate)
	elseif not self.text:GetText() or event == "ELVUI_FORCE_UPDATE" then
		timerText = noLabel or timerText
		self.text:SetFormattedText(displayString, timerText, E.global.datatexts.settings.Combat.TimeFull and "00:00:00" or "00:00")
	end

	lastPanel = self
end

local function ValueColorUpdate(hex)
	local noLabel = E.global.datatexts.settings.Combat.NoLabel and ""
	displayString = strjoin("", "%s", noLabel or ": ", hex, "%s|r")

	if lastPanel then OnEvent(lastPanel) end
end
E.valueColorUpdateFuncs[ValueColorUpdate] = true

DT:RegisterDatatext("Combat", nil, {"PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED"}, OnEvent, nil, nil, nil, nil, L["Combat Time"], nil, ValueColorUpdate)
