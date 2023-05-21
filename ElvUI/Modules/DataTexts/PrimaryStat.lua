local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')
local LCS = E.Libs.LCS


local _G = _G
local strjoin = strjoin

local UnitStat = UnitStat
local GetSpecialization = LCS.GetSpecialization

local PRIMARY_STAT = gsub(SPEC_FRAME_PRIMARY_STAT, '[:：%s]-%%s$', '')
local NOT_APPLICABLE = NOT_APPLICABLE

local displayString = ''

local function OnEvent(self)
	local Spec = GetSpecialization()
	local StatID = Spec and DT.SPECIALIZATION_CACHE[Spec] and DT.SPECIALIZATION_CACHE[Spec].statID

	local name = StatID and _G['SPELL_STAT'..StatID..'_NAME']
	if name then
		self.text:SetFormattedText(displayString, name..': ', UnitStat('player', StatID))
	else
		self.text:SetText(NOT_APPLICABLE)
	end
end

local function ApplySettings(_, hex)
	displayString = strjoin('', '%s', hex, '%.f|r')
end

DT:RegisterDatatext('Primary Stat', L["Attributes"], { 'UNIT_STATS', 'UNIT_AURA' }, OnEvent, nil, nil, nil, nil, PRIMARY_STAT, nil, ApplySettings)
