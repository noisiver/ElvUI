local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule("DataTexts")

local strjoin = strjoin

local GetSpellHitModifier = GetSpellHitModifier
local GetCombatRatingBonus = GetCombatRatingBonus
local STAT_CATEGORY_ENHANCEMENTS = STAT_CATEGORY_ENHANCEMENTS
local CR_HIT_SPELL = CR_HIT_SPELL

local displayString = ""

local function OnEvent(self)
	self.text:SetFormattedText(displayString, GetCombatRatingBonus(CR_HIT_SPELL))
end

local function ApplySettings(_, hex)
	displayString = strjoin("", L["Spell Hit"], ": ", hex, "%.2f%%|r")
end

DT:RegisterDatatext("Spell Hit", STAT_CATEGORY_ENHANCEMENTS, { "UNIT_STATS", "UNIT_AURA" }, OnEvent, nil, nil, nil, nil, L["Spell Hit"], nil, ApplySettings)
