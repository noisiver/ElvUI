local E, L, V, P, G = unpack(select(2, ...)) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local DT = E:GetModule("DataTexts")
local TT = E:GetModule("Tooltip")

local join = string.join
local displayNumberString = ""

local function OnEvent(self)
    self.text:SetFormattedText(displayNumberString, L["Item Level"], TT:GetItemLvL("player"))
end

local function ValueColorUpdate(hex)
    displayNumberString = join("", "%s: ", hex, "%d|r")

	if lastPanel ~= nil then
		OnEvent(lastPanel, "ELVUI_COLOR_UPDATE")
	end
end
E.valueColorUpdateFuncs[ValueColorUpdate] = true

DT:RegisterDatatext("Item Level", {"PLAYER_ENTERING_WORLD", "PLAYER_EQUIPMENT_CHANGED"}, OnEvent, nil, OnClick, nil, nil, L["Item Level"])
