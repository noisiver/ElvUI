local E, L, V, P, G = unpack(select(2, ...)) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local DT = E:GetModule("DataTexts")

local join = string.join

local displayNumberString = ""

local function GetAverageItemLevel()
    local items = 16
    local ilvl = 0

    for slotID = 1, 18 do
        if slotID ~= INVSLOT_BODY then
            local itemLink = GetInventoryItemLink("player", slotID)

            if itemLink then
                local _, _, quality, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)

                if itemLevel then
                    ilvl = ilvl + itemLevel

                    if slotID == INVSLOT_MAINHAND and (itemEquipLoc ~= "INVTYPE_2HWEAPON" or titanGrip) then
                        items = 17
                    end
                end
            end
        end
    end

    return ilvl / items
end

local function OnEvent(self)
    self.text:SetFormattedText(displayNumberString, L["Item Level"], GetAverageItemLevel())
end

local function ValueColorUpdate(hex)
    displayNumberString = join("", "%s: ", hex, "%d|r")

	if lastPanel ~= nil then
		OnEvent(lastPanel, "ELVUI_COLOR_UPDATE")
	end
end
E.valueColorUpdateFuncs[ValueColorUpdate] = true

DT:RegisterDatatext("Item Level", {"PLAYER_ENTERING_WORLD", "PLAYER_EQUIPMENT_CHANGED"}, OnEvent, nil, OnClick, nil, nil, L["Item Level"])
