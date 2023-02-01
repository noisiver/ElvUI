local E, L, V, P, G = unpack(select(2, ...))
local DB = E:GetModule("DataBars")
local LSM = LibStub("LibSharedMedia-3.0")

--Lua functions
local _G = _G
local max = math.max
local format = string.format
--WoW API
local GetWatchedFactionInfo = GetWatchedFactionInfo
local ToggleCharacter = ToggleCharacter
-- WoW Variables
local FACTION_BAR_COLORS = FACTION_BAR_COLORS
local REPUTATION = REPUTATION
local STANDING = STANDING
local UNKNOWN = UNKNOWN

local function GetValues(curValue, minValue, maxValue)
	local maximum = maxValue - minValue
	local current, diff = curValue - minValue, maximum

	if diff == 0 then diff = 1 end -- prevent a division by zero

	if current == maximum then
		return 1, 1, 100, true
	else
		return current, maximum, current / diff * 100
	end
end

function DB:ReputationBar_Update()
	local bar = DB.StatusBars.Reputation
	DB:SetVisibility(bar)

	if not bar.db.enable or bar:ShouldHide() then return end

	local displayString, textFormat, label, _ = "", DB.db.reputation.textFormat
	local name, reaction, minValue, maxValue, curValue = GetWatchedFactionInfo()

	if not label then
		label = _G["FACTION_STANDING_LABEL"..reaction] or UNKNOWN
	end

	local customColors = DB.db.colors.useCustomFactionColors
	local color = customColors and DB.db.colors.factionColors[reaction] or FACTION_BAR_COLORS[reaction]
	local alpha = (customColors and color.a) or DB.db.colors.reputationAlpha

	bar:SetStatusBarColor(color.r or 1, color.g or 1, color.b or 1, alpha or 1)
	bar:SetMinMaxValues(minValue, maxValue)
	bar:SetValue(curValue)

	local current, maximum, percent, capped = GetValues(curValue, minValue, maxValue)
	if capped and textFormat ~= "NONE" then -- show only name and standing on exalted
		displayString = format("%s: [%s]", name, label)
	elseif textFormat == "PERCENT" then
		displayString = format("%s: %d%% [%s]", name, percent, label)
	elseif textFormat == "CURMAX" then
		displayString = format("%s: %s - %s [%s]", name, E:ShortValue(current), E:ShortValue(maximum), label)
	elseif textFormat == "CURPERC" then
		displayString = format("%s: %s - %d%% [%s]", name, E:ShortValue(current), percent, label)
	elseif textFormat == "CUR" then
		displayString = format("%s: %s [%s]", name, E:ShortValue(current), label)
	elseif textFormat == "REM" then
		displayString = format("%s: %s [%s]", name, E:ShortValue(maximum - current), label)
	elseif textFormat == "CURREM" then
		displayString = format("%s: %s - %s [%s]", name, E:ShortValue(current), E:ShortValue(maximum - current), label)
	elseif textFormat == "CURPERCREM" then
		displayString = format("%s: %s - %d%% (%s) [%s]", name, E:ShortValue(current), percent, E:ShortValue(maximum - current), label)
	end

	bar.text:SetText(displayString)
end

function DB:ReputationBar_OnEnter()
	if self.db.mouseover then
		E:UIFrameFadeIn(self, 0.4, self:GetAlpha(), 1)
	end

	local name, reaction, minValue, maxValue, curValue = GetWatchedFactionInfo()
	local standing = _G["FACTION_STANDING_LABEL"..reaction] or UNKNOWN

	if name then
		GameTooltip:ClearLines()
		GameTooltip:SetOwner(self, "ANCHOR_CURSOR", 0, -4)
		GameTooltip:AddLine(name)
		GameTooltip:AddLine(" ")

		GameTooltip:AddDoubleLine(STANDING..":", standing, 1, 1, 1)

		local current, maximum, percent = GetValues(curValue, minValue, maxValue)
		GameTooltip:AddDoubleLine(REPUTATION..":", format("%d / %d (%d%%)", current, maximum, percent), 1, 1, 1)

		GameTooltip:Show()
	end
end

function DB:ReputationBar_OnClick()
	ToggleCharacter("ReputationFrame")
end

function DB:ReputationBar_Toggle()
	local bar = DB.StatusBars.Reputation
	bar.db = DB.db.reputation

	if bar.db.enable then
		E:EnableMover(bar.holder.mover.name)

		DB:RegisterEvent("UPDATE_FACTION", "ReputationBar_Update")
		DB:RegisterEvent("COMBAT_TEXT_UPDATE", "ReputationBar_Update")
		DB:RegisterEvent("QUEST_FINISHED", "ReputationBar_Update")

		DB:ReputationBar_Update()
	else
		E:DisableMover(bar.holder.mover.name)

		DB:UnregisterEvent("UPDATE_FACTION")
		DB:UnregisterEvent("COMBAT_TEXT_UPDATE")
		DB:UnregisterEvent("QUEST_FINISHED")
	end
end

function DB:ReputationBar()
	local Reputation = DB:CreateBar("ElvUI_ReputationBar", "Reputation", DB.ReputationBar_Update, DB.ReputationBar_OnEnter, DB.ReputationBar_OnClick, {"TOPRIGHT", E.UIParent, "TOPRIGHT", -3, -264})
	DB:CreateBarBubbles(Reputation)

	Reputation.ShouldHide = function()
		return (DB.db.reputation.hideBelowMaxLevel and not E:XPIsLevelMax()) or not GetWatchedFactionInfo()
	end

	E:CreateMover(Reputation.holder, "ReputationBarMover", L["Reputation Bar"], nil, nil, nil, nil, nil, "databars,reputation")

	DB:ReputationBar_Toggle()
end