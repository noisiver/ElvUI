local E, L, V, P, G = unpack(select(2, ...))
local TT = E:GetModule('Tooltip')
local AB = E:GetModule('ActionBars')
local Skins = E:GetModule('Skins')
local B = E:GetModule('Bags')
local LSM = E.Libs.LSM
local LCS = E.Libs.LCS

--Lua functions
local _G = _G
local unpack, select, ipairs = unpack, select, ipairs
local wipe, next, tinsert, tconcat = wipe, next, tinsert, table.concat
local floor, tonumber, strlower = floor, tonumber, strlower
local strfind, format, strmatch, gmatch, gsub = strfind, format, strmatch, gmatch, gsub
--WoW API / Variables
local CreateFrame = CreateFrame
local GetTime = GetTime
local UnitGUID = UnitGUID
local InCombatLockdown = InCombatLockdown
local IsShiftKeyDown = IsShiftKeyDown
local IsControlKeyDown = IsControlKeyDown
local IsAltKeyDown = IsAltKeyDown
local GetInventoryItemLink = GetInventoryItemLink
local GetInventorySlotInfo = GetInventorySlotInfo
local UnitExists = UnitExists
local CanInspect = CanInspect
local NotifyInspect = NotifyInspect
local GetMouseFocus = GetMouseFocus
local UnitLevel = UnitLevel
local UnitIsPlayer = UnitIsPlayer
local UnitClass = UnitClass
local UnitName = UnitName
local GetGuildInfo = GetGuildInfo
local UnitPVPName = UnitPVPName
local UnitIsAFK = UnitIsAFK
local UnitIsDND = UnitIsDND
local GetQuestDifficultyColor = GetQuestDifficultyColor
local UnitRace = UnitRace
local UnitIsTapped = UnitIsTapped
local UnitIsTappedByPlayer = UnitIsTappedByPlayer
local UnitReaction = UnitReaction
local UnitClassification = UnitClassification
local UnitCreatureType = UnitCreatureType
local UnitIsPVP = UnitIsPVP
local UnitHasVehicleUI = UnitHasVehicleUI
local GetNumPartyMembers = GetNumPartyMembers
local GetNumRaidMembers = GetNumRaidMembers
local UnitIsUnit = UnitIsUnit
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local GetItemCount = GetItemCount
local UnitAura = UnitAura
local SetTooltipMoney = SetTooltipMoney
local GameTooltip_ClearMoney = GameTooltip_ClearMoney
local TARGET = TARGET
local DEAD = DEAD
local FOREIGN_SERVER_LABEL = FOREIGN_SERVER_LABEL
local PVP = PVP
local FACTION_ALLIANCE = FACTION_ALLIANCE
local FACTION_HORDE = FACTION_HORDE
local LEVEL = LEVEL
local FACTION_BAR_COLORS = FACTION_BAR_COLORS
local ID = ID
local GetSpecialization = LCS.GetSpecialization
local GetSpecializationInfo = LCS.GetSpecializationInfo
local GetSpecializationRole = LCS.GetSpecializationRole
local GetInspectSpecialization = LCS.GetInspectSpecialization
local GetSpecializationInfoByID = LCS.GetSpecializationInfoByID

local PRIEST_COLOR = RAID_CLASS_COLORS.PRIEST
local UNKNOWN = UNKNOWN

local GameTooltip, GameTooltipStatusBar = GameTooltip, GameTooltipStatusBar
-- Custom to find LEVEL string on tooltip
local LEVEL1 = strlower(TOOLTIP_UNIT_LEVEL:gsub('%s?%%s%s?%-?',''))
local LEVEL2 = strlower(TOOLTIP_UNIT_LEVEL_CLASS:gsub('^%%2$s%s?(.-)%s?%%1$s','%1'):gsub('^%-?г?о?%s?',''):gsub('%s?%%s%s?%-?',''))
local IDLine = '|cFFCA3C3C%s|r %d'
local targetList, TAPPED_COLOR = {}, { r=0.6, g=0.6, b=0.6 }
local AFK_LABEL = ' |cffFFFFFF[|r|cffFF9900'..L["AFK"]..'|r|cffFFFFFF]|r'
local DND_LABEL = ' |cffFFFFFF[|r|cffFF3333'..L["DND"]..'|r|cffFFFFFF]|r'
local genderTable = { UNKNOWN..' ', MALE..' ', FEMALE..' ' }
local blanchyFix = '|n%s*|n' -- thanks blizz -x- lol
local whiteRGB = { r = 1, g = 1, b = 1 }

function TT:IsModKeyDown(db)
	local k = db or TT.db.modifierID -- defaulted to 'HIDE' unless otherwise specified
	return k == 'SHOW' or ((k == 'SHIFT' and IsShiftKeyDown()) or (k == 'CTRL' and IsControlKeyDown()) or (k == 'ALT' and IsAltKeyDown()))
end

local classification = {
	worldboss = format("|cffAF5050 %s|r", BOSS),
	rareelite = format("|cffAF5050 %s %s|r", ELITE, ITEM_QUALITY3_DESC),
	elite = format("|cffAF5050 %s|r", ELITE),
	rare = format("|cffAF5050 %s|r", ITEM_QUALITY3_DESC)
}

local inventorySlots = {
	"HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "WristSlot",
	"HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot",
	"Trinket0Slot", "Trinket1Slot", "MainHandSlot", "SecondaryHandSlot", "RangedSlot"
}

local updateUnitModifiers = {
	["LSHIFT"] = true,
	["RSHIFT"] = true,
	["LCTRL"] = true,
	["RCTRL"] = true,
	["LALT"] = true,
	["RALT"] = true,
}

function TT:GameTooltip_SetDefaultAnchor(tt, parent)
	if not E.private.tooltip.enable or not TT.db.visibility or tt:GetAnchorType() ~= 'ANCHOR_NONE' then
		return
	elseif InCombatLockdown() and not TT:IsModKeyDown(TT.db.visibility.combatOverride) then
		tt:Hide()
		return
	elseif not AB.KeyBinder.active and not TT:IsModKeyDown(TT.db.visibility.actionbars) then
		local owner = tt:GetOwner()
		local ownerName = owner and owner.GetName and owner:GetName()
		if ownerName and (strfind(ownerName, 'ElvUI_Bar') or strfind(ownerName, 'ElvUI_StanceBar') or strfind(ownerName, 'PetAction')) then
			tt:Hide()
			return
		end
	end

	local statusBar = tt.StatusBar
	if statusBar then
		local spacing = E.Spacing * 3
		local position = TT.db.healthBar.statusPosition
		statusBar:SetAlpha(position == 'DISABLED' and 0 or 1)

		if position == 'BOTTOM' and statusBar.anchoredToTop then
			statusBar:ClearAllPoints()
			statusBar:Point('TOPLEFT', tt, 'BOTTOMLEFT', E.Border, -spacing)
			statusBar:Point('TOPRIGHT', tt, 'BOTTOMRIGHT', -E.Border, -spacing)
			statusBar.anchoredToTop = nil
		elseif position == 'TOP' and not statusBar.anchoredToTop then
			statusBar:ClearAllPoints()
			statusBar:Point('BOTTOMLEFT', tt, 'TOPLEFT', E.Border, spacing)
			statusBar:Point('BOTTOMRIGHT', tt, 'TOPRIGHT', -E.Border, spacing)
			statusBar.anchoredToTop = true
		end
	end

	if parent then
		if TT.db.cursorAnchor then
			tt:SetOwner(parent, TT.db.cursorAnchorType, TT.db.cursorAnchorX, TT.db.cursorAnchorY)
			return
		else
			tt:SetOwner(parent, 'ANCHOR_NONE')
		end
	end

	local RightChatPanel = RightChatPanel
	local TooltipMover = TooltipMover
	local _, anchor = tt:GetPoint()

	if anchor == nil or anchor == B.BagFrame or anchor == RightChatPanel or anchor == TooltipMover or anchor == UIParent or anchor == E.UIParent then
		tt:ClearAllPoints()

		if not E:HasMoverBeenMoved('TooltipMover') then
			if B.BagFrame and B.BagFrame:IsShown() then
				tt:Point('BOTTOMRIGHT', B.BagFrame, 'TOPRIGHT', 0, 18)
			elseif RightChatPanel:GetAlpha() == 1 and RightChatPanel:IsShown() then
				tt:Point('BOTTOMRIGHT', RightChatPanel, 'TOPRIGHT', 0, 18)
			else
				tt:Point('BOTTOMRIGHT', RightChatPanel, 'BOTTOMRIGHT', 0, 18)
			end
		else
			local point = E:GetScreenQuadrant(TooltipMover)
			if point == 'TOPLEFT' then
				tt:Point('TOPLEFT', TooltipMover, 'BOTTOMLEFT', 1, -4)
			elseif point == 'TOPRIGHT' then
				tt:Point('TOPRIGHT', TooltipMover, 'BOTTOMRIGHT', -1, -4)
			elseif point == 'BOTTOMLEFT' or point == 'LEFT' then
				tt:Point('BOTTOMLEFT', TooltipMover, 'TOPLEFT', 1, 18)
			else
				tt:Point('BOTTOMRIGHT', TooltipMover, 'TOPRIGHT', -1, 18)
			end
		end
	end
end

function TT:GetItemLvL(unit)
	local total, items = 0, 0
	for i = 1, #inventorySlots do
		local itemLink = GetInventoryItemLink(unit, GetInventorySlotInfo(inventorySlots[i]))

		if itemLink then
			local iLvl = select(4, GetItemInfo(itemLink))
			if iLvl and iLvl > 0 then
				items = items + 1
				total = total + iLvl
			end
		end
	end

	if items == 0 then
		return 0
	end

	return E:Round(total / items, 2)
end

function TT:RemoveTrashLines(tt)
	for i = 3, tt:NumLines() do
		local tiptext = _G['GameTooltipTextLeft'..i]
		local linetext = tiptext and tiptext:GetText()

		if not linetext then
			break
		elseif linetext == PVP or linetext == FACTION_ALLIANCE or linetext == FACTION_HORDE then
			tiptext:SetText('')
			tiptext:Hide()
		end
	end
end

function TT:GetLevelLine(tt, offset, guildName)
	if guildName then
		offset = 3
	end

	for i = offset, tt:NumLines() do
		local tipLine = _G['GameTooltipTextLeft'..i]
		local tipText = tipLine and tipLine:GetText()
		local tipLower = tipText and strlower(tipText)
		if tipLower and (strfind(tipLower, LEVEL1) or strfind(tipLower, LEVEL2)) then
			return tipLine
		end
	end
end

function TT:SetUnitText(tt, unit, isPlayerUnit)
	local name, realm = UnitName(unit)

	if isPlayerUnit then
		local localeClass, class = UnitClass(unit)
		if not localeClass or not class then return end

		local nameRealm = (realm and realm ~= '' and format('%s-%s', name, realm)) or name
		local guildName, guildRankName = GetGuildInfo(unit)
		local pvpName, gender = UnitPVPName(unit), UnitSex(unit)
		local level = UnitLevel(unit)
		local isShiftKeyDown = IsShiftKeyDown()

		local nameColor = E:ClassColor(class) or PRIEST_COLOR

		if TT.db.playerTitles and pvpName then
			name = pvpName
		end

		if realm and realm ~= "" then
			if isShiftKeyDown or TT.db.alwaysShowRealm then
				name = name.."-"..realm
			else
				name = name..FOREIGN_SERVER_LABEL
			end
		end

		local awayText = UnitIsAFK(unit) and AFK_LABEL or UnitIsDND(unit) and DND_LABEL or ''
		GameTooltipTextLeft1:SetFormattedText('|c%s%s%s|r', nameColor.colorStr, name or UNKNOWN, awayText)

		local levelLine = TT:GetLevelLine(tt, 2, guildName)
		if guildName then
			local text = TT.db.guildRanks and format('<|cff00ff10%s|r> [|cff00ff10%s|r]', guildName, guildRankName) or format('<|cff00ff10%s|r>', guildName)
			if levelLine == GameTooltipTextLeft2 then
				tt:AddLine(text, 1, 1, 1)
			else
				GameTooltipTextLeft2:SetText(text)
			end
		end

		if levelLine then
			local diffColor = GetQuestDifficultyColor(level)
			local race = UnitRace(unit)
			local hexColor = E:RGBToHex(diffColor.r, diffColor.g, diffColor.b)
			local unitGender = TT.db.gender and genderTable[gender]
			levelLine:SetFormattedText('%s%s|r %s%s |c%s%s|r', hexColor, level > 0 and level or '??', unitGender or '', race or '', nameColor.colorStr, localeClass)
		end

		if TT.db.showElvUIUsers then
			local addonUser = E.UserList[nameRealm]
			if addonUser then
				local same = addonUser == E.version
				tt:AddDoubleLine(L["ElvUI Version:"], format('%.2f', addonUser), nil, nil, nil, same and 0.2 or 1, same and 1 or 0.2, 0.2)
			end
		end

		return nameColor
	else
		local levelLine = TT:GetLevelLine(tt, 2)
		if levelLine then
			local level = UnitLevel(unit)
			local creatureClassification = UnitClassification(unit)
			local creatureType = UnitCreatureType(unit)
			local pvpFlag = ""
			local diffColor = GetQuestDifficultyColor(level)

			if UnitIsPVP(unit) then
				pvpFlag = format(" (%s)", PVP)
			end

			levelLine:SetFormattedText("|cff%02x%02x%02x%s|r%s %s%s", diffColor.r * 255, diffColor.g * 255, diffColor.b * 255, level > 0 and level or "??", classification[creatureClassification] or "", creatureType or "", pvpFlag)
		end
	end

	local unitReaction = UnitReaction(unit, 'player')
	local nameColor = unitReaction and ((TT.db.useCustomFactionColors and TT.db.factionColors[unitReaction]) or FACTION_BAR_COLORS[unitReaction]) or PRIEST_COLOR

	return (UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) and TAPPED_COLOR) or nameColor
end

local inspectGUIDCache = {}
local inspectColorFallback = {1,1,1}
function TT:PopulateInspectGUIDCache(unitGUID, itemLevel)
	local specName = TT:GetSpecializationInfo('mouseover')
	if specName and itemLevel then
		local inspectCache = inspectGUIDCache[unitGUID]
		if inspectCache then
			inspectCache.time = GetTime()
			inspectCache.itemLevel = itemLevel
			inspectCache.specName = specName
		end

		GameTooltip:AddDoubleLine(L["Specialization"]..':', specName, nil, nil, nil, unpack((inspectCache and inspectCache.unitColor) or inspectColorFallback))
		GameTooltip:AddDoubleLine(L["Item Level:"], itemLevel, nil, nil, nil, 1, 1, 1)
		GameTooltip:Show()
	end
end

function TT:INSPECT_TALENT_READY(event, unit)
	if UnitExists('mouseover') and UnitGUID('mouseover') == unitGUID then
		local itemLevel, retryUnit, retryTable, iLevelDB = E:GetUnitItemLevel('mouseover')
		if itemLevel == 'tooSoon' then
			E:Delay(0.05, function()
				local canUpdate = true
				for _, x in ipairs(retryTable) do
					local slotInfo = E:GetGearSlotInfo(retryUnit, x)
					if slotInfo == 'tooSoon' then
						canUpdate = false
					else
						iLevelDB[x] = slotInfo.iLvl
					end
				end

				if canUpdate then
					local calculateItemLevel = E:CalculateAverageItemLevel(iLevelDB, retryUnit)
					TT:PopulateInspectGUIDCache(unitGUID, calculateItemLevel)
				end
			end)
		else
			TT:PopulateInspectGUIDCache(unitGUID, itemLevel)
		end
	end

	if event then
		TT:UnregisterEvent(event)
	end
end

function TT:GetSpecializationInfo(unit, isPlayer)
	local spec = (isPlayer and GetSpecialization()) or (unit and GetInspectSpecialization(unit))
	if spec and spec > 0 then
		if isPlayer then
			return select(2, GetSpecializationInfo(spec))
		else
			return select(2, GetSpecializationInfoByID(spec))
		end
	end
end

local lastGUID
function TT:AddInspectInfo(tooltip, unit, numTries, r, g, b)
	if (not unit) or (numTries > 3) or not CanInspect(unit) then return end

	local unitGUID = UnitGUID(unit)
	if not unitGUID then return end
	local cache = inspectGUIDCache[unitGUID]

	if unitGUID == E.myguid then
		tooltip:AddDoubleLine(L["Specialization"]..':', TT:GetSpecializationInfo(unit, true), nil, nil, nil, r, g, b)
		tooltip:AddDoubleLine(L["Item Level:"], E:GetUnitItemLevel(unit), nil, nil, nil, 1, 1, 1)
	elseif cache and cache.time then
		local specName, itemLevel = cache.specName, cache.itemLevel
		if not (specName and itemLevel) or (GetTime() - cache.time > 120) then
			cache.time, cache.specName, cache.itemLevel = nil, nil, nil
			return E:Delay(0.33, TT.AddInspectInfo, TT, tooltip, unit, numTries + 1, r, g, b)
		end

		tooltip:AddDoubleLine(L["Specialization"]..':', specName, nil, nil, nil, r, g, b)
		tooltip:AddDoubleLine(L["Item Level:"], itemLevel, nil, nil, nil, 1, 1, 1)
	elseif unitGUID then
		if not inspectGUIDCache[unitGUID] then
			inspectGUIDCache[unitGUID] = { unitColor = {r, g, b} }
		end

		if lastGUID ~= unitGUID then
			lastGUID = unitGUID
			NotifyInspect(unit)
			TT:RegisterEvent('INSPECT_READY')
		else
			TT:INSPECT_READY(nil, unitGUID)
		end
	end
end

function TT:AddTargetInfo(tt, unit)
	local unitTarget = unit..'target'
	if unit ~= 'player' and UnitExists(unitTarget) then
		local targetColor
		if UnitIsPlayer(unitTarget) and not UnitHasVehicleUI(unitTarget) then
			local _, class = UnitClass(unitTarget)
			targetColor = E:ClassColor(class) or PRIEST_COLOR
		else
			local reaction = UnitReaction(unitTarget, 'player')
			targetColor = (TT.db.useCustomFactionColors and TT.db.factionColors[reaction]) or FACTION_BAR_COLORS[reaction] or PRIEST_COLOR
		end

		tt:AddDoubleLine(format('%s:', TARGET), format('|cff%02x%02x%02x%s|r', targetColor.r * 255, targetColor.g * 255, targetColor.b * 255, UnitName(unitTarget)))
	end

	if GetNumPartyMembers() > 0 then
		local isInRaid = GetNumRaidMembers > 1
		for i = 1, GetNumPartyMembers() do
			local groupUnit = (isInRaid and 'raid' or 'party')..i
			if UnitIsUnit(groupUnit..'target', unit) and not UnitIsUnit(groupUnit,'player') then
				local _, class = UnitClass(groupUnit)
				local classColor = E:ClassColor(class) or PRIEST_COLOR
				tinsert(targetList, format('|c%s%s|r', classColor.colorStr, UnitName(groupUnit)))
			end
		end

		local numList = #targetList
		if numList > 0 then
			tt:AddLine(format('%s (|cffffffff%d|r): %s', L["Targeted By:"], numList, tconcat(targetList, ', ')), nil, nil, nil, true)
			wipe(targetList)
		end
	end
end

function TT:AddRoleInfo(tt, unit)
	local r, g, b, role = 1, 1, 1, UnitGroupRolesAssigned(unit)
	if GetNumPartyMembers() > 0 and (UnitInParty(unit) or UnitInRaid(unit)) and (role ~= 'NONE') then
		if role == 'HEALER' then
			role, r, g, b = L["Healer"], 0, 1, .59
		elseif role == 'TANK' then
			role, r, g, b = TANK, .16, .31, .61
		elseif role == 'DAMAGER' then
			role, r, g, b = L["DPS"], .77, .12, .24
		end

		tt:AddDoubleLine(format('%s:', ROLE), role, nil, nil, nil, r, g, b)
	end
end

function TT:ShowInspectInfo(tt, unit, r, g, b)
	local canInspect = CanInspect(unit)
	if not canInspect then return end

	local GUID = UnitGUID(unit)
	if GUID == E.myguid then
		local _, specName = E:GetTalentSpecInfo()

		tt:AddDoubleLine(L["Talent Specialization:"], specName, nil, nil, nil, r, g, b)
		tt:AddDoubleLine(L["Item Level:"], self:GetItemLvL("player"), nil, nil, nil, 1, 1, 1)
		return
	elseif inspectCache[GUID] then
		local specName = inspectCache[GUID].specName
		local itemLevel = inspectCache[GUID].itemLevel

		if (GetTime() - inspectCache[GUID].time) < 900 and specName and itemLevel then
			tt:AddDoubleLine(L["Talent Specialization:"], specName, nil, nil, nil, r, g, b)
			tt:AddDoubleLine(L["Item Level:"], itemLevel, nil, nil, nil, 1, 1, 1)
			return
		else
			inspectCache[GUID] = nil
		end
	end

	if InspectFrame and InspectFrame.unit then
		if UnitIsUnit(InspectFrame.unit, unit) then
			self.lastGUID = GUID
			self:INSPECT_TALENT_READY(nil, unit)
		end
	else
		self.lastGUID = GUID
		NotifyInspect(unit)
		self:RegisterEvent("INSPECT_TALENT_READY")
	end
end

function TT:GameTooltip_OnTooltipSetUnit(data)
	if self ~= GameTooltip or not TT.db.visibility then return end

	local _, unit = self:GetUnit()
	local isPlayerUnit = UnitIsPlayer(unit)
	if self:GetOwner() ~= UIParent and not TT:IsModKeyDown(TT.db.visibility.unitFrames) then
		self:Hide()
		return
	end

	if not unit then
		local GMF = GetMouseFocus()
		local focusUnit = GMF and GMF.GetAttribute and GMF:GetAttribute('unit')
		if focusUnit then unit = focusUnit end
		if not unit or not UnitExists(unit) then
			return
		end
	end

	TT:RemoveTrashLines(self) --keep an eye on this may be buggy

	local isShiftKeyDown = IsShiftKeyDown()
	local isControlKeyDown = IsControlKeyDown()
	local color = TT:SetUnitText(self, unit, isPlayerUnit)

	if TT.db.targetInfo and not isShiftKeyDown and not isControlKeyDown then
		TT:AddTargetInfo(self, unit)
	end

	if TT.db.role then
		TT:AddRoleInfo(self, unit)
	end

	if not InCombatLockdown() then
		if isShiftKeyDown and color and TT.db.inspectDataEnable then
			TT:AddInspectInfo(self, unit, 0, color.r, color.g, color.b)
		end
	end

	if unit and not isPlayerUnit and TT:IsModKeyDown() then
		local guid = (data and data.guid) or UnitGUID(unit) or ''
		local id = tonumber(strmatch(guid, '%-(%d-)%-%x-$'), 10)
		if id then -- NPC ID's
			self:AddLine(format(IDLine, ID, id))
		end
	end

	local statusBar = self.StatusBar
	if color then
		statusBar:SetStatusBarColor(color.r, color.g, color.b)
	else
		statusBar:SetStatusBarColor(0.6, 0.6, 0.6)
	end

	if statusBar.text then
		local textWidth = statusBar.text:GetStringWidth()
		if textWidth then
			self:SetMinimumWidth(textWidth)
		end
	end
end

function TT:GameTooltipStatusBar_OnValueChanged(tt, value)
	if not value or not tt.text or not TT.db.healthBar.text then return end

	-- try to get ahold of the unit token
	local _, unit = tt:GetParent():GetUnit()
	if not unit then
		local frame = GetMouseFocus()
		if frame and frame.GetAttribute then
			unit = frame:GetAttribute('unit')
		end
	end

	-- check if dead
	if value == 0 or (unit and UnitIsDeadOrGhost(unit)) then
		tt.text:SetText(DEAD)
	else
		local MAX, _
		if unit then -- try to get the real health values if possible
			value, MAX = UnitHealth(unit), UnitHealthMax(unit)
		else
			_, MAX = tt:GetMinMaxValues()
		end

		-- return what we got
		if value > 0 and MAX == 1 then
			tt.text:SetFormattedText('%d%%', floor(value * 100))
		else
			tt.text:SetText(E:ShortValue(value)..' / '..E:ShortValue(MAX))
		end
	end
end

function TT:GameTooltip_OnTooltipCleared(tt)
	if tt.qualityChanged then
		tt.qualityChanged = nil

		local r, g, b = 1, 1, 1
		if E.private.skins.blizzard.enable and E.private.skins.blizzard.tooltip then
			r, g, b = unpack(E.media.bordercolor)
		end

		tt:SetBackdropBorderColor(r, g, b)
	end

	if tt.ItemTooltip then
		tt.ItemTooltip:Hide()
	end
end

function TT:EmbeddedItemTooltip_ID(tt, id)
	if tt.Tooltip:IsShown() and TT:IsModKeyDown() then
		tt.Tooltip:AddLine(format(IDLine, ID, id))
		tt.Tooltip:Show()
	end
end

function TT:EmbeddedItemTooltip_QuestReward(tt)
	if tt.Tooltip:IsShown() and TT:IsModKeyDown() then
		tt.Tooltip:AddLine(format(IDLine, ID, tt.itemID or tt.spellID))
		tt.Tooltip:Show()
	end
end

function TT:GameTooltip_OnTooltipSetItem(data)
	if self ~= GameTooltip or not TT.db.visibility then return end

	local owner = self:GetOwner()
	local ownerName = owner and owner.GetName and owner:GetName()
	if ownerName and (strfind(ownerName, 'ElvUI_Container') or strfind(ownerName, 'ElvUI_BankContainer')) and not TT:IsModKeyDown(TT.db.visibility.bags) then
		self:Hide()
		return
	end

	local itemID, bagCount, bankCount
	local modKey = TT:IsModKeyDown()

	if self.GetItem then -- Some tooltips don't have this func. Example - compare tooltip
		local _, link = self:GetItem()
		if not link then return end

		if TT.db.itemQuality then
			local _, _, quality = GetItemInfo(link)

			if quality and quality > 1 then
				local r, g, b = GetItemQualityColor(quality)
				print(link, quality, r, g, b, self:GetName())
				self:SetBackdropBorderColor(r, g, b)

				self.qualityChanged = true
			end
		end

		if modKey then
			itemID = format('|cFFCA3C3C%s|r %s', ID, (data and data.id) or strmatch(link, ':(%w+)'))
		end

		if TT.db.itemCount ~= 'NONE' and (not TT.db.modifierCount or modKey) then
			local count = GetItemCount(link)
			local total = GetItemCount(link, true)
			if TT.db.itemCount == 'BAGS_ONLY' then
				bagCount = format(IDLine, L["Count"], count)
			elseif TT.db.itemCount == 'BANK_ONLY' then
				bankCount = format(IDLine, L["Bank"], total - count)
			elseif TT.db.itemCount == 'BOTH' then
				bagCount = format(IDLine, L["Count"], count)
				bankCount = format(IDLine, L["Bank"], total - count)
			end
		end
	elseif modKey then
		local id = data and data.id
		if id then
			itemID = format('|cFFCA3C3C%s|r %s', ID, id)
		end
	end

	if itemID or bagCount or bankCount then self:AddLine(' ') end
	if itemID or bagCount then self:AddDoubleLine(itemID or ' ', bagCount or ' ') end
	if bankCount then self:AddDoubleLine(' ', bankCount) end
end

function TT:GameTooltip_AddQuestRewardsToTooltip(tt, questID)
	if not (tt and questID and tt.progressBar) then return end

	local _, max = tt.progressBar:GetMinMaxValues()
	Skins:StatusBarColorGradient(tt.progressBar, tt.progressBar:GetValue(), max)
end

function TT:GameTooltip_ClearProgressBars(tt)
	tt.progressBar = nil
end

function TT:GameTooltip_ShowProgressBar(tt)
	if not tt or not tt.progressBarPool then return end

	local sb = tt.progressBarPool:GetNextActive()
	if not sb or not sb.Bar then return end

	tt.progressBar = sb.Bar

	if not sb.Bar.backdrop then
		sb.Bar:StripTextures()
		sb.Bar:CreateBackdrop('Transparent', nil, true)
		sb.Bar:SetStatusBarTexture(E.media.normTex)
	end
end

function TT:GameTooltip_ShowStatusBar(tt)
	if not tt then return end

	local sb = _G[tt:GetName().."StatusBar"..tt.shownStatusBars]
	if not sb or sb.backdrop then return end

	sb:StripTextures()
	sb:CreateBackdrop(nil, nil, true, true)
	sb:SetStatusBarTexture(E.media.normTex)
end

function TT:CheckBackdropColor(tt)
	if tt:GetAnchorType() == "ANCHOR_CURSOR" then
		local r, g, b = unpack(E.media.backdropfadecolor, 1, 3)
		tt:SetBackdropColor(r, g, b, TT.db.colorAlpha)
	end
end

function TT:SetStyle(tt)
	if not tt.template or tt == E.ScanTooltip then
		tt:SetTemplate("Transparent")
	else
		tt:SetBackdropBorderColor(unpack(E.media.bordercolor, 1, 3))
	end

	local r, g, b = unpack(E.media.backdropfadecolor, 1, 3)
	tt:SetBackdropColor(r, g, b, self.db.colorAlpha)
end

function TT:MODIFIER_STATE_CHANGED(_, key)
	if updateUnitModifiers[key] then
		local owner = GameTooltip:GetOwner()
		local notOnAuras = not (owner and owner.UpdateTooltip)
		if notOnAuras and UnitExists("mouseover") then
			GameTooltip:SetUnit("mouseover")
		end
	end
end

function TT:SetUnitAura(tt, ...)
	local caster, _, _, id = select(8, UnitAura(...))
	if id and self.db.spellID then
		if caster then
			local name = UnitName(caster)
			local _, class = UnitClass(caster)
			local color = E:ClassColor(class) or PRIEST_COLOR
			tt:AddDoubleLine(format(IDLine, ID, id), format('|c%s%s|r', color.colorStr, name or UNKNOWN))
		else
			tt:AddLine(format(IDLine, ID, id))
		end

		tt:Show()
	end
end

function TT:GameTooltip_OnTooltipSetSpell(data)
	if (self ~= GameTooltip and self ~= ElvUISpellBookTooltip) or not TT:IsModKeyDown() then return end

	local id = (data and data.id) or select(3, self:GetSpell())
	if not id then return end

	local ID = format(IDLine, ID, id)
	for i = 3, self:NumLines() do
		local line = _G[format('GameTooltipTextLeft%d', i)]
		local text = line and line:GetText()
		if text and strfind(text, ID) then
			return -- this is called twice on talents for some reason?
		end
	end

	self:AddLine(ID)
	self:Show()
end

function TT:SetItemRef(link)
	if IsModifierKeyDown() or not (link and strfind(link, '^spell:')) then return end

	ItemRefTooltip:AddLine(format(IDLine, ID, strmatch(link, ':(%d+)')))
	ItemRefTooltip:Show()
end

function TT:SetHyperlink(refTooltip, link)
	if self.db.spellID and (find(link, "^spell:") or find(link, "^item:")) then
		refTooltip:AddLine(format("|cFFCA3C3C%s|r %d", ID, tonumber(match(link, "(%d+)"))))
		refTooltip:Show()
	end
end

function TT:SetTooltipFonts()
	local font, fontSize, fontOutline = LSM:Fetch('font', TT.db.font), TT.db.textFontSize, TT.db.fontOutline
	GameTooltipText:FontTemplate(font, fontSize, fontOutline)

	if GameTooltip.hasMoney then
		for i = 1, GameTooltip.numMoneyFrames do
			_G['GameTooltipMoneyFrame'..i..'PrefixText']:FontTemplate(font, fontSize, fontOutline)
			_G['GameTooltipMoneyFrame'..i..'SuffixText']:FontTemplate(font, fontSize, fontOutline)
			_G['GameTooltipMoneyFrame'..i..'GoldButtonText']:FontTemplate(font, fontSize, fontOutline)
			_G['GameTooltipMoneyFrame'..i..'SilverButtonText']:FontTemplate(font, fontSize, fontOutline)
			_G['GameTooltipMoneyFrame'..i..'CopperButtonText']:FontTemplate(font, fontSize, fontOutline)
		end
	end

	-- Header has its own font settings
	GameTooltipHeaderText:FontTemplate(LSM:Fetch('font', TT.db.headerFont), TT.db.headerFontSize, TT.db.headerFontOutline)

	-- Ignore header font size on DatatextTooltip
	if DatatextTooltip then
		DatatextTooltipTextLeft1:FontTemplate(font, fontSize, fontOutline)
		DatatextTooltipTextRight1:FontTemplate(font, fontSize, fontOutline)
	end

	-- Comparison Tooltips has its own size setting
	local smallSize = TT.db.smallTextFontSize
	GameTooltipTextSmall:FontTemplate(font, smallSize, fontOutline)

	for _, tt in ipairs(GameTooltip.shoppingTooltips) do
		for _, region in next, { tt:GetRegions() } do
			if region:IsObjectType('FontString') then
				region:FontTemplate(font, smallSize, fontOutline)
			end
		end
	end
end

function TT:GameTooltip_Hide()
	local statusBar = GameTooltip.StatusBar
	if statusBar and statusBar:IsShown() then
		statusBar:Hide()
	end
end

function TT:WorldCursorTooltipUpdate(_, state)
	if TT.db.cursorAnchor then return end

	-- recall this, something called Show and stopped it (now with refade option)
	-- cursor anchor is always hidden right away regardless
	if state == 0 then
		if TT.db.fadeOut then
			GameTooltip:FadeOut()
		else
			GameTooltip:Hide()
		end
	end
end

--This changes the growth direction of the toast frame depending on position of the mover
local function PostBNToastMove(mover)
	local x, y = mover:GetCenter()
	local screenHeight = E.UIParent:GetTop()
	local screenWidth = E.UIParent:GetRight()

	local anchorPoint
	if y > (screenHeight / 2) then
		anchorPoint = (x > (screenWidth / 2)) and "TOPRIGHT" or "TOPLEFT"
	else
		anchorPoint = (x > (screenWidth / 2)) and "BOTTOMRIGHT" or "BOTTOMLEFT"
	end
	mover.anchorPoint = anchorPoint

	BNToastFrame:ClearAllPoints()
	BNToastFrame:Point(anchorPoint, mover)
end

function TT:RepositionBNET(frame, _, anchor)
	if anchor ~= BNETMover then
		frame:ClearAllPoints()
		frame:Point("TOPLEFT", BNETMover, "TOPLEFT")
	end
end

function TT:Initialize()
	TT.db = E.db.tooltip

	BNToastFrame:Point("TOPRIGHT", MinimapCluster, "BOTTOMRIGHT", 0, -10)
	E:CreateMover(BNToastFrame, "BNETMover", L["BNet Frame"], nil, nil, PostBNToastMove)
	self:SecureHook(BNToastFrame, "SetPoint", "RepositionBNET")

	if not E.private.tooltip.enable then return end
	TT.Initialized = true

	local statusBar = GameTooltipStatusBar
	statusBar:Height(TT.db.healthBar.height)
	statusBar:SetScript('OnValueChanged', nil) -- Do we need to unset this?
	GameTooltip.StatusBar = statusBar

	local statusText = statusBar:CreateFontString(nil, 'OVERLAY')
	statusText:FontTemplate(LSM:Fetch('font', TT.db.healthBar.font), TT.db.healthBar.fontSize, TT.db.healthBar.fontOutline)
	statusText:Point('CENTER', statusBar, 0, 0)
	statusBar.text = statusText

	--Tooltip Fonts
	if not GameTooltip.hasMoney then
		--Force creation of the money lines, so we can set font for it
		SetTooltipMoney(GameTooltip, 1, nil, '', '')
		SetTooltipMoney(GameTooltip, 1, nil, '', '')
		GameTooltip_ClearMoney(GameTooltip)
	end
	TT:SetTooltipFonts()

	local GameTooltipAnchor = CreateFrame("Frame", "GameTooltipAnchor", E.UIParent)
	GameTooltipAnchor:Point("BOTTOMRIGHT", RightChatToggleButton, "BOTTOMRIGHT")
	GameTooltipAnchor:Size(130, 20)
	GameTooltipAnchor:SetFrameLevel(GameTooltipAnchor:GetFrameLevel() + 400)
	E:CreateMover(GameTooltipAnchor, "TooltipMover", L["Tooltip"], nil, nil, nil, nil, nil, "tooltip,general")

	TT:SecureHook(GameTooltip, 'Hide', 'GameTooltip_Hide') -- dont use OnHide use Hide directly
	-- TT:SecureHook(ItemRefTooltip, "SetHyperlink")
	TT:SecureHook('SetItemRef')
	TT:SecureHook("GameTooltip_SetDefaultAnchor")
	TT:SecureHook(GameTooltip, 'SetUnitAura')
	TT:SecureHook(GameTooltip, 'SetUnitBuff', 'SetUnitAura')
	TT:SecureHook(GameTooltip, 'SetUnitDebuff', 'SetUnitAura')
	TT:HookScript(GameTooltip, "OnTooltipCleared", "GameTooltip_OnTooltipCleared")
	TT:HookScript(GameTooltip.StatusBar, "OnValueChanged", "GameTooltipStatusBar_OnValueChanged")

	TT:SecureHookScript(GameTooltip, 'OnTooltipSetSpell', TT.GameTooltip_OnTooltipSetSpell)
	TT:SecureHookScript(GameTooltip, 'OnTooltipSetItem', TT.GameTooltip_OnTooltipSetItem)
	TT:SecureHookScript(GameTooltip, 'OnTooltipSetUnit', TT.GameTooltip_OnTooltipSetUnit)
	-- TT:SecureHookScript(ElvUISpellBookTooltip, 'OnTooltipSetSpell', TT.GameTooltip_OnTooltipSetSpell)

	TT:RegisterEvent("MODIFIER_STATE_CHANGED")
end

local function InitializeCallback()
	TT:Initialize()
end

E:RegisterModule(TT:GetName(), InitializeCallback)