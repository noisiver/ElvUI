local E, L, V, P, G = unpack(ElvUI)
local LC = E.Libs.Compat

local _G = _G
local pi = math.pi
local utf8sub = string.utf8sub
local tonumber, format = tonumber, format
local tinsert, strmatch = tinsert, strmatch
local next, max, wipe, gsub = next, max, wipe, gsub

local GetCVarBool = GetCVarBool
local GetItemInfo = GetItemInfo
local GetInventoryItemLink = GetInventoryItemLink
local GetInventoryItemTexture = GetInventoryItemTexture
local UnitIsUnit = UnitIsUnit

local GetInspectSpecialization = LC.GetInspectSpecialization
local GetAverageItemLevel = LC.GetAverageItemLevel

local RETRIEVING_ITEM_INFO = RETRIEVING_ITEM_INFO

local MATCH_ITEM_LEVEL = ITEM_LEVEL:gsub('%%d', '(%%d+)')
local MATCH_SOCKET = ITEM_SOCKET_BONUS:gsub('%%s', '(.+)')
local X2_INVTYPES, X2_EXCEPTIONS, ARMOR_SLOTS = {
	INVTYPE_2HWEAPON = true,
	INVTYPE_RANGEDRIGHT = true,
	INVTYPE_RANGED = true,
}, {
	[2] = 19, -- wands, use INVTYPE_RANGEDRIGHT, but are 1H
}, {1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}

function E:InspectGearSlot(line, lineText, slotInfo)
	local socket = strmatch(lineText, MATCH_SOCKET)
	if socket then
		local color1, color2 = strmatch(socket, '(|cn.-:).-(|r)')
		local text = gsub(gsub(socket, '%s?|A.-|a', ''), '|cn.-:(.-)|r', '%1')
		slotInfo.socketText = format('%s%s%s', color1 or '', text, color2 or '')
		slotInfo.socketTextShort = format('%s%s%s', color1 or '', utf8sub(text, 1, 18), color2 or '')
		slotInfo.socketTextReal = socket -- unchanged, contains Atlas and color

		local r, g, b = line:GetTextColor()
		slotInfo.socketColors[1] = r
		slotInfo.socketColors[2] = g
		slotInfo.socketColors[3] = b
	end

	local itemLevel = lineText and strmatch(lineText, MATCH_ITEM_LEVEL)
	if itemLevel then
		slotInfo.iLvl = tonumber(itemLevel)

		local r, g, b = _G.ElvUI_ScanTooltipTextLeft1:GetTextColor()
		slotInfo.itemLevelColors[1] = r
		slotInfo.itemLevelColors[2] = g
		slotInfo.itemLevelColors[3] = b
	end
end

function E:GetGearSlotInfo(unit, slot, deepScan)
	local tt = E.ScanTooltip
	tt:SetOwner(UIParent, 'ANCHOR_NONE')
	local hasItem = tt:SetInventoryItem(unit, slot)
	tt:Show()

	local info = hasItem and tt:GetTooltipData()
	if not tt.slotInfo then tt.slotInfo = {} else wipe(tt.slotInfo) end
	local slotInfo = tt.slotInfo

	if deepScan then
		slotInfo.gems = E:ScanTooltipTextures()

		if not tt.socketColors then tt.socketColors = {} else wipe(tt.socketColors) end
		if not tt.itemLevelColors then tt.itemLevelColors = {} else wipe(tt.itemLevelColors) end
		slotInfo.socketColors = tt.socketColors
		slotInfo.itemLevelColors = tt.itemLevelColors

		if info then
			for i, line in next, info.lines do
				local text = line and line.leftText
				if i == 1 and text == RETRIEVING_ITEM_INFO then
					return 'tooSoon'
				else
					E:InspectGearSlot(_G['ElvUI_ScanTooltipTextLeft'..i], text, slotInfo)
				end
			end
		end
	elseif info then
		local firstLine = info.lines[1]
		local firstText = firstLine and firstLine.leftText
		if firstText == RETRIEVING_ITEM_INFO then
			return 'tooSoon'
		end

		local colorblind = GetCVarBool('colorblindmode') and 4 or 3
		for x = 2, colorblind do
			local line = info.lines[x]
			if line then
				local text = line.leftText
				local itemLevel = strmatch(text, MATCH_ITEM_LEVEL)
				if itemLevel then
					slotInfo.iLvl = tonumber(itemLevel)
				end
			end
		end
	end

	tt:Hide()

	return slotInfo
end

--Credit ls & Acidweb
function E:CalculateAverageItemLevel(iLevelDB, unit)
	local spec = GetInspectSpecialization(unit)
	local isOK, total, link = true, 0

	if not spec or spec == 0 then
		isOK = false
	end

	-- Armor
	for _, id in next, ARMOR_SLOTS do
		link = GetInventoryItemLink(unit, id)
		if link then
			local cur = iLevelDB[id]
			if cur and cur > 0 then
				total = total + cur
			end
		elseif GetInventoryItemTexture(unit, id) then
			isOK = false
		end
	end

	-- Main hand
	local mainItemLevel, mainQuality, mainEquipLoc, mainItemClass, mainItemSubClass, _ = 0
	link = GetInventoryItemLink(unit, 16)
	if link then
		mainItemLevel = iLevelDB[16]
		_, _, mainQuality, _, _, mainItemClass, mainItemSubClass, _, mainEquipLoc = GetItemInfo(link)
	elseif GetInventoryItemTexture(unit, 16) then
		isOK = false
	end

	-- Off hand
	local offItemLevel, offEquipLoc = 0
	link = GetInventoryItemLink(unit, 17)
	if link then
		offItemLevel = iLevelDB[17]
		_, _, _, _, _, _, _, _, offEquipLoc = GetItemInfo(link)
	elseif GetInventoryItemTexture(unit, 17) then
		isOK = false
	end

	if mainItemLevel and offItemLevel then
		if mainQuality == 6 or (not offEquipLoc and X2_INVTYPES[mainEquipLoc] and X2_EXCEPTIONS[mainItemClass] ~= mainItemSubClass and spec ~= 72) then
			mainItemLevel = max(mainItemLevel, offItemLevel)
			total = total + mainItemLevel * 2
		else
			total = total + mainItemLevel + offItemLevel
		end
	end

	-- at the beginning of an arena match no info might be available,
	-- so despite having equipped gear a person may appear naked
	if total == 0 then
		isOK = false
	end

	return isOK and E:Round(total / 16, 2)
end

function E:ColorizeItemLevel(num)
	if num >= 0 then
		return .1, 1, .1
	else
		return E:ColorGradient(-(pi/num), 1, .1, .1, 1, 1, .1, .1, 1, .1)
	end
end

function E:GetPlayerItemLevel()
	local average, equipped = GetAverageItemLevel()
	return E:Round(average, 2), E:Round(equipped, 2)
end

do
	local iLevelDB, tryAgain = {}, {}
	function E:GetUnitItemLevel(unit)
		if UnitIsUnit(unit, 'player') then
			return E:GetPlayerItemLevel()
		end

		if next(iLevelDB) then wipe(iLevelDB) end
		if next(tryAgain) then wipe(tryAgain) end

		for i = 1, 17 do
			if i ~= 4 then
				local slotInfo = E:GetGearSlotInfo(unit, i)
				if slotInfo == 'tooSoon' then
					tinsert(tryAgain, i)
				else
					iLevelDB[i] = slotInfo.iLvl
				end
			end
		end

		if next(tryAgain) then
			return 'tooSoon', unit, tryAgain, iLevelDB
		end

		return E:CalculateAverageItemLevel(iLevelDB, unit)
	end
end
