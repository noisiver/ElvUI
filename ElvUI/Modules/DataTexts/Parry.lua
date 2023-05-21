local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule("DataTexts")

local strjoin = strjoin

local GetParryChance = GetParryChance

local PARRY = PARRY

local displayString = ""

local function OnEvent(self)
	self.text:SetFormattedText(displayString, PARRY, GetParryChance())
end

local function ApplySettings(_, hex)
	displayString = strjoin("", "%s: ", hex, "%.f|r")
end

DT:RegisterDatatext("Parry", L["Defence"], { "UNIT_STATS", "UNIT_AURA", "SKILL_LINES_CHANGED" }, OnEvent, nil, nil, nil, nil, PARRY, nil, ApplySettings)

