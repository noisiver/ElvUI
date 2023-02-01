local E, L, V, P, G = unpack(select(2, ...))
local DT = E:GetModule("DataTexts")

--Lua functions
local select = select
local join = string.join
--WoW API / Variables
local GetBattlefieldScore = GetBattlefieldScore
local GetBattlefieldStatData = GetBattlefieldStatData
local GetBattlefieldStatInfo = GetBattlefieldStatInfo
local GetNumBattlefieldScores = GetNumBattlefieldScores
local GetNumBattlefieldStats = GetNumBattlefieldStats
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local displayString = ""
local LEFT, RIGHT = {}, {}
local holder = {
	LEFT = { data = LEFT, KILLS, KILLING_BLOWS, DEATHS },
	RIGHT = { data = RIGHT, DAMAGE, HEALS, HONOR }
}

DT.BattleStats = holder
function DT:UpdateBattlePanel(which)
	local info = which and holder[which]
	local panel = info and info.panel
	if not panel then return end

	for i, name in ipairs(info) do
		local dt = panel[i]
		if dt and dt.text then
			dt.text:SetFormattedText(displayString, name, info.data[i] or 0)
		end
	end
end

local myIndex
function DT:UPDATE_BATTLEFIELD_SCORE()
	myIndex = nil

	for i = 1, GetNumBattlefieldScores() do
		local name, kb, hks, deaths, honor, dmg, heals, _
		name, kb, hks, deaths, honor, _, _, _, _, _, dmg, heals = GetBattlefieldScore(i)

		if name == E.myname then
			LEFT[1], LEFT[2], LEFT[3] = E:ShortValue(hks), E:ShortValue(kb), E:ShortValue(deaths)
			RIGHT[1], RIGHT[2], RIGHT[3] = E:ShortValue(dmg), E:ShortValue(heals), E:ShortValue(honor)
			myIndex = i
			break
		end
	end

	if myIndex then
		DT:UpdateBattlePanel("LEFT")
		DT:UpdateBattlePanel("RIGHT")
	end
end

function DT:HoverBattleStats()
	DT.tooltip:ClearLines()

	local numStatInfo = GetNumBattlefieldStats()
	if numStatInfo and DT.ShowingBattleStats == "pvp" then
		for i = 1, GetNumBattlefieldScores() do
			local name = GetBattlefieldScore(i)
			if name and name == E.myname then
				local classColor = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[E.myclass]) or RAID_CLASS_COLORS[E.myclass]

				DT.tooltip:AddDoubleLine(L["Stats For:"], name, 1, 1, 1, classColor.r, classColor.g, classColor.b)
				DT.tooltip:AddLine(" ")

				-- Add extra statistics to watch based on what BG you are in.
				for j = 1, numStatInfo do
					DT.tooltip:AddDoubleLine(GetBattlefieldStatInfo(j), GetBattlefieldStatData(i, j), 1, 1, 1)
				end

				break
			end
		end
	end

	DT.tooltip:Show()
end

function DT:ToggleBattleStats()
	if DT.ForceHideBGStats then
		DT.ForceHideBGStats = nil
		E:Print(L["Battleground datatexts will now show again if you are inside a battleground."])
	else
		DT.ForceHideBGStats = true
		E:Print(L["Battleground datatexts temporarily hidden, to show type /bgstats"])
	end

	DT:UpdatePanelInfo("LeftChatDataPanel")
	DT:UpdatePanelInfo("RightChatDataPanel")

	if DT.ShowingBattleStats then
		DT:UpdateBattlePanel("LEFT")
		DT:UpdateBattlePanel("RIGHT")
	end
end

local function ValueColorUpdate(hex)
	displayString = strjoin("", "%s: ", hex, "%s|r")

	if DT.ShowingBattleStats then
		DT:UpdateBattlePanel("LEFT")
		DT:UpdateBattlePanel("RIGHT")
	end
end
E.valueColorUpdateFuncs[ValueColorUpdate] = true