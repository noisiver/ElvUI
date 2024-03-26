local E, L, V, P, G = unpack(select(2, ...)) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local DT = E:GetModule("DataTexts")

local join = string.join
local displayNumberString = ""

local ItemTypes = {
    ["INVTYPE_RELIC"] = { ["SlotMOD"] = 0.3164, ["ItemSlot"] = 18, ["Enchantable"] = false},
    ["INVTYPE_TRINKET"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 33, ["Enchantable"] = false },
    ["INVTYPE_2HWEAPON"] = { ["SlotMOD"] = 2.000, ["ItemSlot"] = 16, ["Enchantable"] = true },
    ["INVTYPE_WEAPONMAINHAND"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 16, ["Enchantable"] = true },
    ["INVTYPE_WEAPONOFFHAND"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 17, ["Enchantable"] = true },
    ["INVTYPE_RANGED"] = { ["SlotMOD"] = 0.3164, ["ItemSlot"] = 18, ["Enchantable"] = true },
    ["INVTYPE_THROWN"] = { ["SlotMOD"] = 0.3164, ["ItemSlot"] = 18, ["Enchantable"] = false },
    ["INVTYPE_RANGEDRIGHT"] = { ["SlotMOD"] = 0.3164, ["ItemSlot"] = 18, ["Enchantable"] = false },
    ["INVTYPE_SHIELD"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 17, ["Enchantable"] = true },
    ["INVTYPE_WEAPON"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 36, ["Enchantable"] = true },
    ["INVTYPE_HOLDABLE"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 17, ["Enchantable"] = false },
    ["INVTYPE_HEAD"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 1, ["Enchantable"] = true },
    ["INVTYPE_NECK"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 2, ["Enchantable"] = false },
    ["INVTYPE_SHOULDER"] = { ["SlotMOD"] = 0.7500, ["ItemSlot"] = 3, ["Enchantable"] = true },
    ["INVTYPE_CHEST"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 5, ["Enchantable"] = true },
    ["INVTYPE_ROBE"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 5, ["Enchantable"] = true },
    ["INVTYPE_WAIST"] = { ["SlotMOD"] = 0.7500, ["ItemSlot"] = 6, ["Enchantable"] = false },
    ["INVTYPE_LEGS"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 7, ["Enchantable"] = true },
    ["INVTYPE_FEET"] = { ["SlotMOD"] = 0.75, ["ItemSlot"] = 8, ["Enchantable"] = true },
    ["INVTYPE_WRIST"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 9, ["Enchantable"] = true },
    ["INVTYPE_HAND"] = { ["SlotMOD"] = 0.7500, ["ItemSlot"] = 10, ["Enchantable"] = true },
    ["INVTYPE_FINGER"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 31, ["Enchantable"] = false },
    ["INVTYPE_CLOAK"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 15, ["Enchantable"] = true },
    
    --Lol Shirt
    ["INVTYPE_BODY"] = { ["SlotMOD"] = 0, ["ItemSlot"] = 4, ["Enchantable"] = false },
}

local Formula = {
    ["A"] = {
        [4] = { ["A"] = 91.4500, ["B"] = 0.6500 },
        [3] = { ["A"] = 81.3750, ["B"] = 0.8125 },
        [2] = { ["A"] = 73.0000, ["B"] = 1.0000 }
    },
    ["B"] = {
        [4] = { ["A"] = 26.0000, ["B"] = 1.2000 },
        [3] = { ["A"] = 0.7500, ["B"] = 1.8000 },
        [2] = { ["A"] = 8.0000, ["B"] = 2.0000 },
        [1] = { ["A"] = 0.0000, ["B"] = 2.2500 }
    }
}

local Quality = {
    [6000] = {
        ["Red"] = { ["A"] = 0.94, ["B"] = 5000, ["C"] = 0.00006, ["D"] = 1 },
        ["Green"] = { ["A"] = 0.47, ["B"] = 5000, ["C"] = 0.00047, ["D"] = -1 },
        ["Blue"] = { ["A"] = 0, ["B"] = 0, ["C"] = 0, ["D"] = 0 },
        ["Description"] = "Legendary"
    },
    [5000] = {
        ["Red"] = { ["A"] = 0.69, ["B"] = 4000, ["C"] = 0.00025, ["D"] = 1 },
        ["Green"] = { ["A"] = 0.28, ["B"] = 4000, ["C"] = 0.00019, ["D"] = 1 },
        ["Blue"] = { ["A"] = 0.97, ["B"] = 4000, ["C"] = 0.00096, ["D"] = -1 },
        ["Description"] = "Epic"
    },
    [4000] = {
        ["Red"] = { ["A"] = 0.0, ["B"] = 3000, ["C"] = 0.00069, ["D"] = 1 },
        ["Green"] = { ["A"] = 0.5, ["B"] = 3000, ["C"] = 0.00022, ["D"] = -1 },
        ["Blue"] = { ["A"] = 1, ["B"] = 3000, ["C"] = 0.00003, ["D"] = -1 },
        ["Description"] = "Superior"
    },
    [3000] = {
        ["Red"] = { ["A"] = 0.12, ["B"] = 2000, ["C"] = 0.00012, ["D"] = -1 },
        ["Green"] = { ["A"] = 1, ["B"] = 2000, ["C"] = 0.00050, ["D"] = -1 },
        ["Blue"] = { ["A"] = 0, ["B"] = 2000, ["C"] = 0.001, ["D"] = 1 },
        ["Description"] = "Uncommon"
    },
    [2000] = {
        ["Red"] = { ["A"] = 1, ["B"] = 1000, ["C"] = 0.00088, ["D"] = -1 },
        ["Green"] = { ["A"] = 1, ["B"] = 000, ["C"] = 0.00000, ["D"] = 0 },
        ["Blue"] = { ["A"] = 1, ["B"] = 1000, ["C"] = 0.001, ["D"] = -1 },
        ["Description"] = "Common"
    },
    [1000] = {
        ["Red"] = { ["A"] = 0.55, ["B"] = 0, ["C"] = 0.00045, ["D"] = 1 },
        ["Green"] = { ["A"] = 0.55, ["B"] = 0, ["C"] = 0.00045, ["D"] = 1 },
        ["Blue"] = { ["A"] = 0.55, ["B"] = 0, ["C"] = 0.00045, ["D"] = 1 },
        ["Description"] = "Trash"
    },
}

local function GetQuality(ItemScore)
    if (ItemScore > 5999) then
        ItemScore = 5999
    end

    local Red, Blue, Green = 0.1, 0.1, 0.1
    local QualityDescription = "Legendary"

       if not (ItemScore) then
        return 0, 0, 0, "Trash"
    end

    for i = 0,6 do
        if (ItemScore > i * 1000) and (ItemScore <= ((i+1) * 1000)) then
            local Red = Quality[(i + 1) * 1000].Red["A"] + (((ItemScore - Quality[(i + 1) * 1000].Red["B"])*Quality[(i + 1) * 1000].Red["C"])*Quality[(i + 1) * 1000].Red["D"])
            local Blue = Quality[(i + 1) * 1000].Green["A"] + (((ItemScore - Quality[(i + 1) * 1000].Green["B"])*Quality[(i + 1) * 1000].Green["C"])*Quality[(i + 1) * 1000].Green["D"])
            local Green = Quality[(i + 1) * 1000].Blue["A"] + (((ItemScore - Quality[(i + 1) * 1000].Blue["B"])*Quality[(i + 1) * 1000].Blue["C"])*Quality[(i + 1) * 1000].Blue["D"])

            return Red, Green, Blue, Quality[(i + 1) * 1000].Description
        end
    end

    return 0.1, 0.1, 0.1
end

local function GetEnchantInfo(ItemLink, ItemEquipLoc)
    local found, _, ItemSubString = string.find(ItemLink, "^|c%x+|H(.+)|h%[.*%]")
    local ItemSubStringTable = {}

    for v in string.gmatch(ItemSubString, "[^:]+") do
        tinsert(ItemSubStringTable, v)
    end

    ItemSubString = ItemSubStringTable[2]..":"..ItemSubStringTable[3], ItemSubStringTable[2]

    local StringStart, StringEnd = string.find(ItemSubString, ":")

    ItemSubString = string.sub(ItemSubString, StringStart + 1)

    if (ItemSubString == "0") and (ItemTypes[ItemEquipLoc]["Enchantable"]) then
         local percent = (floor((-2 * (ItemTypes[ItemEquipLoc]["SlotMOD"])) * 100) / 100)

         return(1 + (percent/100))
    else
        return 1
    end
end

local function GetItemScore(ItemLink)
    local QualityScale, GearScore = 1, 0

    if not (ItemLink) then
        return 0, 0
    end

    local ItemName, ItemLink, ItemRarity, ItemLevel, ItemMinLevel, ItemType, ItemSubType, ItemStackCount, ItemEquipLoc, ItemTexture = GetItemInfo(ItemLink)
    local Table = {}
    local Scale = 1.8618

     if (ItemRarity == 5) then
        QualityScale = 1.3
        ItemRarity = 4
    elseif (ItemRarity == 1) then
        QualityScale = 0.005
        ItemRarity = 2
    elseif (ItemRarity == 0) then
        QualityScale = 0.005
        ItemRarity = 2
    end

    if (ItemRarity == 7) then
        ItemRarity = 3
        ItemLevel = 187.05
    end

    if (ItemTypes[ItemEquipLoc]) then
        if (ItemLevel > 120) then
            Table = Formula["A"]
        else
            Table = Formula["B"]
        end

        if (ItemRarity >= 2) and (ItemRarity <= 4) then
            local Red, Green, Blue = GetQuality((floor(((ItemLevel - Table[ItemRarity].A) / Table[ItemRarity].B) * 1 * Scale)) * 11.25)
            GearScore = floor(((ItemLevel - Table[ItemRarity].A) / Table[ItemRarity].B) * ItemTypes[ItemEquipLoc].SlotMOD * Scale * QualityScale)

            if (ItemLevel == 187.05) then
                ItemLevel = 0
            end

            if (GearScore < 0) then
                GearScore = 0
                Red, Green, Blue = GetQuality(1)
            end

            local percent = (GetEnchantInfo(ItemLink, ItemEquipLoc) or 1)
            GearScore = floor(GearScore * percent)

            return GearScore, ItemLevel, ItemTypes[ItemEquipLoc].ItemSlot, Red, Green, Blue, ItemEquipLoc, percent
        end
      end

      return -1, ItemLevel, 50, 1, 1, 1, ItemEquipLoc, 1
end

local function GetGearScore()
    local PlayerClass, PlayerEnglishClass = UnitClass("player")

    local GearScore, ItemCount, TitanGrip = 0, 0, 1
    local TempEquip = {}

    if (GetInventoryItemLink("player", 16)) and (GetInventoryItemLink("player", 17)) then
        local ItemName, ItemLink, ItemRarity, ItemLevel, ItemMinLevel, ItemType, ItemSubType, ItemStackCount, ItemEquipLoc, ItemTexture = GetItemInfo(GetInventoryItemLink("player", 16))
        if (ItemEquipLoc == "INVTYPE_2HWEAPON") then
            TitanGrip = 0.5
        end
    end

    if (GetInventoryItemLink("player", 17)) then
        local ItemName, ItemLink, ItemRarity, ItemLevel, ItemMinLevel, ItemType, ItemSubType, ItemStackCount, ItemEquipLoc, ItemTexture = GetItemInfo(GetInventoryItemLink("player", 17))
        if (ItemEquipLoc == "INVTYPE_2HWEAPON") then
            TitanGrip = 0.5
        end

        TempScore, ItemLevel = GetItemScore(GetInventoryItemLink("player", 17))

        if (PlayerEnglishClass == "HUNTER") then
            TempScore = TempScore * 0.3164
        end

        GearScore = GearScore + TempScore * TitanGrip
        ItemCount = ItemCount + 1
    end
    
    for i = 1, 18 do
        if (i ~= 4) and (i ~= 17) then
            ItemLink = GetInventoryItemLink("player", i)
            GS_ItemLinkTable = {}

            if (ItemLink) then
                local ItemName, ItemLink, ItemRarity, ItemLevel, ItemMinLevel, ItemType, ItemSubType, ItemStackCount, ItemEquipLoc, ItemTexture = GetItemInfo(ItemLink)
                TempScore = GetItemScore(ItemLink)

                if (i == 16) and (PlayerEnglishClass == "HUNTER") then
                    TempScore = TempScore * 0.3164
                end

                if (i == 18) and (PlayerEnglishClass == "HUNTER") then
                    TempScore = TempScore * 5.3224
                end

                if (i == 16) then
                    TempScore = TempScore * TitanGrip
                end

                GearScore = GearScore + TempScore
                ItemCount = ItemCount + 1
            end
        end
    end

    if (GearScore <= 0) then
        GearScore = 0
    end

    return floor(GearScore)
end

local function OnEvent(self)
    self.text:SetFormattedText(displayNumberString, L["GearScore"], GetGearScore())
end

local function ValueColorUpdate(hex)
    displayNumberString = join("", "%s: ", hex, "%d|r")

    if lastPanel ~= nil then
        OnEvent(lastPanel, "ELVUI_COLOR_UPDATE")
    end
end
E.valueColorUpdateFuncs[ValueColorUpdate] = true

DT:RegisterDatatext("GearScore", {"PLAYER_ENTERING_WORLD", "PLAYER_EQUIPMENT_CHANGED"}, OnEvent, nil, OnClick, nil, nil, L["GearScore"])
