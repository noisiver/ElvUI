local E, L, V, P, G = unpack(select(2, ...)) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local DT = E:GetModule("DataTexts")

local r, g, b, avg = 1, 1, 1, 0

local ITEMLEVEL = ITEMLEVEL

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

local function GetItemLevelColor(unit)
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

local function OnEvent(self)
    avg = GetAverageItemLevel()
    r, g, b = GetItemLevelColor()
    local hex = E:RGBToHex(r, g, b) or "|cFFFFFFFF"

    self.text:SetFormattedText("Item Level: %s%d|r", hex, math.floor(avg))
end

DT:RegisterDatatext("Item Level", {"PLAYER_ENTERING_WORLD", "PLAYER_EQUIPMENT_CHANGED"}, OnEvent, nil, OnClick, nil, nil, ITEMLEVEL)
