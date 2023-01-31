local E, L, V, P, G = unpack(select(2, ...))
local M = E:GetModule("Minimap")
local LSM = E.Libs.LSM

local _G = _G
local mod = mod
local next = next
local sort = sort
local floor = floor
local tinsert = tinsert
local unpack = unpack
local hooksecurefunc = hooksecurefunc
local utf8sub = string.utf8sub

local CloseAllWindows = CloseAllWindows
local CloseMenus = CloseMenus
local CreateFrame = CreateFrame
local GetMinimapZoneText = GetMinimapZoneText
local GetTime = GetTime
local GetZonePVPInfo = GetZonePVPInfo
local HideUIPanel = HideUIPanel
local InCombatLockdown = InCombatLockdown
local IsShiftKeyDown = IsShiftKeyDown
local PlaySound = PlaySound
local ShowUIPanel = ShowUIPanel
local ToggleFrame = ToggleFrame
local MainMenuMicroButton_SetNormal = MainMenuMicroButton_SetNormal
local MinimapCluster = MinimapCluster
local Minimap = Minimap

local menuFrame = CreateFrame("Frame", "MinimapRightClickMenu", E.UIParent)
local menuList = {
	{ text = CHARACTER_BUTTON, func = function() ToggleCharacter("PaperDollFrame") end },
	{ text = SPELLBOOK_ABILITIES_BUTTON, func = function() ToggleFrame(SpellBookFrame) end },
	{ text = TIMEMANAGER_TITLE, func = ToggleTimeManager },
	{ text = CHAT_CHANNELS, func = function() ToggleFriendsFrame(4) end },
	{ text = SOCIAL_BUTTON, func = function() ToggleFriendsFrame(1) end },
	{ text = TALENTS_BUTTON, func = ToggleTalentFrame },
	{ text = GUILD, func = function() ToggleFriendsFrame(3) end },
	{ text = LFG_TITLE, func = function() ToggleFrame(LFDParentFrame) end },
	{ text = PLAYER_V_PLAYER, func = function() ToggleFrame(PVPParentFrame) end },
	{ text = ACHIEVEMENT_BUTTON, func = ToggleAchievementFrame },
	{ text = QUESTLOG_BUTTON, func = function() ToggleFrame(QuestLogFrame) end },
	{ text = L["Calendar"], func = function() GameTimeFrame:Click() end },
	{ text = BATTLEFIELD_MINIMAP, func = ToggleBattlefieldMinimap },
	{ text = LOOKING_FOR_RAID, func = function() ToggleFrame(LFRParentFrame) end },
	{ text = HELP_BUTTON, bottom = true, func = ToggleHelpFrame }
}

sort(menuList, function(a, b) if a and b and a.text and b.text then return a.text < b.text end end)

tinsert(menuList, { text = MAINMENU_BUTTON,
	func = function()
		if not GameMenuFrame:IsShown() then
			if VideoOptionsFrame:IsShown() then
				VideoOptionsFrameCancel:Click()
			elseif AudioOptionsFrame:IsShown() then
				AudioOptionsFrameCancel:Click()
			elseif InterfaceOptionsFrame:IsShown() then
				InterfaceOptionsFrameCancel:Click()
			end

			CloseMenus()
			CloseAllWindows()
			PlaySound(850) --IG_MAINMENU_OPEN
			ShowUIPanel(GameMenuFrame)
		else
			PlaySound(854) --IG_MAINMENU_QUIT
			HideUIPanel(GameMenuFrame)
			MainMenuMicroButton_SetNormal()
		end
	end
})

M.RightClickMenu = menuFrame
M.RightClickMenuList = menuList

function M:SetScale(frame, scale)
	frame:SetScale(scale)
end

function M:HandleQueueButton(actionbarMode)
	local queueButton = M:GetQueueStatusButton()
	if not queueButton then return end

	queueButton:SetParent(MinimapBackdrop)
	queueButton:ClearAllPoints()

	local queueDisplay = M.QueueStatusDisplay
	if queueDisplay then
		local db = E.db.general.minimap.icons.queueStatus
		local _, position, xOffset, yOffset = M:GetIconSettings('queueStatus')
		queueDisplay.text:ClearAllPoints()
		queueDisplay.text:Point(position, Minimap, xOffset, yOffset)
		queueDisplay.text:FontTemplate(LSM:Fetch('font', db.font), db.fontSize, db.fontOutline)

		if not db.enable and queueDisplay.title then
			M:ClearQueueStatus()
		end
	end

	if actionbarMode then
		queueButton:Point('BOTTOMLEFT', Minimap, 10, -10)
		M:SetScale(queueButton, 1)
	else
		local scale, position, xOffset, yOffset = M:GetIconSettings('lfgEye')
		queueButton:Point(position, Minimap, xOffset, yOffset)
		M:SetScale(queueButton, scale)
	end
end

function M:HandleTrackingButton()
	local tracking = MiniMapTracking
	if not tracking then return end

	if E.private.general.minimap.hideTracking then
		tracking:SetParent(E.HiddenFrame)
	else
		local scale, position, xOffset, yOffset = M:GetIconSettings('tracking')

		tracking:ClearAllPoints()
		tracking:Point(position, Minimap, xOffset, yOffset)
		M:SetScale(tracking, scale)

		if MiniMapTrackingButtonBorder then
			MiniMapTrackingButtonBorder:Hide()
		end

		if MiniMapTrackingBackground then
			MiniMapTrackingBackground:Hide()
		end

		if MiniMapTrackingIcon then
			MiniMapTrackingIcon:SetDrawLayer('ARTWORK')
			MiniMapTrackingIcon:SetTexCoord(unpack(E.TexCoords))
			MiniMapTrackingIcon:SetInside()
		end
	end
end

function M:ADDON_LOADED(_, addon)
	if addon == "Blizzard_TimeManager" then
		-- self:UnregisterEvent(event)
		TimeManagerClockButton:Kill()

		TimeManagerClockTicker:FontTemplate(LSM:Fetch('font', E.db.general.minimap.timeFont), E.db.general.minimap.timeFontSize, E.db.general.minimap.timeFontOutline)

		if E.db.general.minimap.clusterDisable then
			TimeManagerClockButton:Kill()
		else
			TimeManagerClockButton.Show = nil
			TimeManagerClockButton:SetParent(MinimapCluster)
			TimeManagerClockButton:Show()
		end
	end
end

function M:Minimap_OnMouseUp(btn)
	local position = self:GetPoint()
	if btn == "MiddleButton" or (btn == "RightButton" and IsShiftKeyDown()) then
		if strmatch(position, "LEFT") then
			EasyMenu(menuList, menuFrame, "cursor", 0, 0, "MENU", 2)
		else
			EasyMenu(menuList, menuFrame, "cursor", -160, 0, "MENU", 2)
		end
	elseif btn == "RightButton" then
		ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, "cursor")
	else
		Minimap_OnClick(self)
	end
end

function M:CreateMinimapTrackingDropdown()
	local dropdown = CreateFrame('Frame', 'ElvUIMiniMapTrackingDropDown', UIParent, 'UIDropDownMenuTemplate')
	dropdown:SetID(1)
	dropdown:SetClampedToScreen(true)
	dropdown:Hide()

	UIDropDownMenu_Initialize(dropdown, MiniMapTrackingDropDown_Initialize, 'MENU')
	dropdown.noResize = true

	return dropdown
end

function M:Minimap_OnMouseDown(btn)
	menuFrame:Hide()

	if M.TrackingDropdown then
		HideDropDownMenu(1, nil, M.TrackingDropdown)
	end

	local position = self:GetPoint()
	if btn == 'MiddleButton' or (btn == 'RightButton' and IsShiftKeyDown()) then
		if InCombatLockdown() then UIErrorsFrame:AddMessage(E.InfoColor..ERR_NOT_IN_COMBAT) return end
		if position:match('LEFT') then
			E:DropDown(menuList, menuFrame)
		else
			E:DropDown(menuList, menuFrame, -160, 0)
		end
	elseif btn == 'RightButton' and M.TrackingDropdown then
		ToggleDropDownMenu(1, nil, M.TrackingDropdown, 'cursor')
	else
		Minimap_OnClick(self)
	end
end

function M:Minimap_OnMouseWheel(d)
	local zoomIn = MinimapZoomIn
	local zoomOut = MinimapZoomOut

	if d > 0 then
		zoomIn:Click()
	elseif d < 0 then
		zoomOut:Click()
	end
end

function M:GetLocTextColor()
	local pvpType = GetZonePVPInfo()
	if pvpType == 'arena' then
		return 0.84, 0.03, 0.03
	elseif pvpType == 'friendly' then
		return 0.05, 0.85, 0.03
	elseif pvpType == 'contested' then
		return 0.9, 0.85, 0.05
	elseif pvpType == 'hostile' then
		return 0.84, 0.03, 0.03
	elseif pvpType == 'sanctuary' then
		return 0.035, 0.58, 0.84
	elseif pvpType == 'combat' then
		return 0.84, 0.03, 0.03
	else
		return 0.9, 0.85, 0.05
	end
end

function M:Update_ZoneText()
	if E.db.general.minimap.locationText == 'HIDE' then return end

	Minimap.location:SetText(utf8sub(GetMinimapZoneText(), 1, 46))
	Minimap.location:SetTextColor(M:GetLocTextColor())
end

do
	local isResetting
	local function ResetZoom()
		Minimap:SetZoom(0)

		local zoomIn = MinimapZoomIn
		local zoomOut = MinimapZoomOut

		zoomIn:Enable() -- Reset enabled state of buttons
		zoomOut:Disable()

		isResetting = false
	end

	local function SetupZoomReset()
		if E.db.general.minimap.resetZoom.enable and not isResetting then
			isResetting = true

			E:Delay(E.db.general.minimap.resetZoom.time, ResetZoom)
		end
	end

	hooksecurefunc(Minimap, 'SetZoom', SetupZoomReset)
end

function M:GetIconSettings(button)
	local defaults = P.general.minimap.icons[button]
	local profile = E.db.general.minimap.icons[button]

	return profile.scale or defaults.scale, profile.position or defaults.position, profile.xOffset or defaults.xOffset, profile.yOffset or defaults.yOffset
end

function M:GetQueueStatusButton()
	return MiniMapLFGFrame
end

function M:UpdateSettings()
	if not M.Initialized then return end

	local noCluster = E.db.general.minimap.clusterDisable
	E.MinimapSize = E.db.general.minimap.size or Minimap:GetWidth()

	-- silly little hack to get the canvas to update
	if E.MinimapSize ~= M.NeedsCanvasUpdate then
		local zoom = Minimap:GetZoom()
		Minimap:SetZoom(zoom > 0 and 0 or 1)
		Minimap:SetZoom(zoom)
		M.NeedsCanvasUpdate = E.MinimapSize
	end

	local panel, holder = MinimapPanel, M.holder
	if panel then
		if E.db.datatexts.panels.MinimapPanel.enable then
			panel:Show()
		else
			panel:Hide()
		end
		M:SetScale(panel, 1)

		local mmOffset = E.PixelMode and 1 or 3
		local mmScale = E.db.general.minimap.scale
		Minimap:ClearAllPoints()
		Minimap:Point('TOPRIGHT', holder, 'TOPRIGHT', -mmOffset/mmScale, -mmOffset/mmScale)
		Minimap:Size(E.MinimapSize, E.MinimapSize)
		Minimap:SetScale(mmScale)

		if not noCluster then
			MinimapCluster:SetScale(mmScale)

			local mcWidth = MinimapCluster:GetWidth()
			local height, width = 20 * mmScale, (mcWidth - 30) * mmScale
			M.ClusterHolder:SetSize(width, height)
			M.ClusterBackdrop:SetSize(width, height)

			if E.db.general.minimap.clusterBackdrop and not noCluster then
				M.ClusterBackdrop:Show()
			else
				M.ClusterBackdrop:Hide()
			end
		else
			Minimap:SetScale(mmScale)
		end
	end

	local locationFont, locaitonSize, locationOutline = LSM:Fetch('font', E.db.general.minimap.locationFont), E.db.general.minimap.locationFontSize, E.db.general.minimap.locationFontOutline
	if Minimap.location then
		Minimap.location:Width(E.MinimapSize)
		Minimap.location:FontTemplate(locationFont, locaitonSize, locationOutline)
		if E.db.general.minimap.locationText == 'SHOW' and noCluster then
			Minimap.location:Show()
		else
			Minimap.location:Hide()
		end
	end

	MiniMapMailIcon:SetTexture(E.Media.Textures.Mail)
	MiniMapMailIcon:Size(20)

	MinimapZoneText:FontTemplate(locationFont, locaitonSize, locationOutline)

	M:HandleQueueButton()

	local instance = difficulty and difficulty.Instance or _G.MiniMapInstanceDifficulty
	if not noCluster then
		if M.ClusterHolder then
			E:EnableMover(M.ClusterHolder.mover.name)
		end

		if instance then instance:SetParent(Minimap) end
	else
		if M.ClusterHolder then
			E:DisableMover(M.ClusterHolder.mover.name)
		end

		if instance then instance:SetParent(Minimap) end

		M.HandleTrackingButton()

		local gameTime = GameTimeFrame
		if gameTime then
			if E.private.general.minimap.hideCalendar then
				gameTime:Hide()
			else
				local scale, position, xOffset, yOffset = M:GetIconSettings('calendar')
				gameTime:ClearAllPoints()
				gameTime:Point(position, Minimap, xOffset, yOffset)
				gameTime:SetParent(MinimapBackdrop)
				gameTime:Show()

				M:SetScale(gameTime, scale)
			end
		end

		local mailFrame = MiniMapMailFrame
		if mailFrame then
			local scale, position, xOffset, yOffset = M:GetIconSettings('mail')
			mailFrame:ClearAllPoints()
			mailFrame:Point(position, Minimap, xOffset, yOffset)
			M:SetScale(mailFrame, scale)
		end

		local battlefieldFrame = MiniMapBattlefieldFrame
		if battlefieldFrame then
			local scale, position, xOffset, yOffset = M:GetIconSettings('battlefield')
			battlefieldFrame:ClearAllPoints()
			battlefieldFrame:Point(position, Minimap, xOffset, yOffset)
			M:SetScale(battlefieldFrame, scale)

			if BattlegroundShine then BattlegroundShine:Hide() end
			if MiniMapBattlefieldBorder then MiniMapBattlefieldBorder:Hide() end
			if MiniMapBattlefieldIcon then MiniMapBattlefieldIcon:SetTexCoord(unpack(E.TexCoords)) end
		end

		if instance then
			local scale, position, xOffset, yOffset = M:GetIconSettings('difficulty')
			instance:ClearAllPoints()
			instance:Point(position, Minimap, xOffset, yOffset)
			M:SetScale(instance, scale)
		end

		if guild then
			local scale, position, xOffset, yOffset = M:GetIconSettings('difficulty')
			guild:ClearAllPoints()
			guild:Point(position, Minimap, xOffset, yOffset)
			M:SetScale(guild, scale)
		end
	end
end

local function MinimapPostDrag()
	MinimapBackdrop:ClearAllPoints()
	MinimapBackdrop:SetAllPoints(Minimap)
end

function M:SetGetMinimapShape()
	GetMinimapShape = M.GetMinimapShape

	Minimap:Size(E.db.general.minimap.size)
end

function M:QueueStatusTimeFormat(seconds)
	local hours = floor(mod(seconds,86400)/3600)
	if hours > 0 then return M.QueueStatusDisplay.text:SetFormattedText('%dh', hours) end

	local mins = floor(mod(seconds,3600)/60)
	if mins > 0 then return M.QueueStatusDisplay.text:SetFormattedText('%dm', mins) end

	local secs = mod(seconds,60)
	if secs > 0 then return M.QueueStatusDisplay.text:SetFormattedText('%ds', secs) end
end

function M:QueueStatusSetTime(seconds)
	local timeInQueue = GetTime() - seconds
	M:QueueStatusTimeFormat(timeInQueue)

	local wait = M.QueueStatusDisplay.averageWait
	local waitTime = wait and wait > 0 and (timeInQueue / wait)
	if not waitTime or waitTime >= 1 then
		M.QueueStatusDisplay.text:SetTextColor(1, 1, 1)
	else
		M.QueueStatusDisplay.text:SetTextColor(E:ColorGradient(waitTime, 1,.1,.1, 1,1,.1, .1,1,.1))
	end
end

function M:QueueStatusOnUpdate(elapsed)
	-- Replicate QueueStatusEntry_OnUpdate throttle
	self.updateThrottle = self.updateThrottle - elapsed
	if self.updateThrottle <= 0 then
		M:QueueStatusSetTime(self.queuedTime)
		self.updateThrottle = 0.1
	end
end

function M:SetFullQueueStatus(title, queuedTime, averageWait)
	local db = E.db.general.minimap.icons.queueStatus
	if not db or not db.enable then return end

	local display = M.QueueStatusDisplay
	if not display.title or display.title == title then
		if queuedTime then
			display.title = title
			display.updateThrottle = 0
			display.queuedTime = queuedTime
			display.averageWait = averageWait
			display:SetScript('OnUpdate', M.QueueStatusOnUpdate)
		else
			M:ClearQueueStatus()
		end
	end
end

function M:SetMinimalQueueStatus(title)
	if M.QueueStatusDisplay.title == title then
		M:ClearQueueStatus()
	end
end

function M:ClearQueueStatus()
	local display = M.QueueStatusDisplay
	display.text:SetText('')
	display.title = nil
	display.queuedTime = nil
	display.averageWait = nil
	display:SetScript('OnUpdate', nil)
end

function M:ClusterPoint(_, anchor)
	local noCluster = E.db.general.minimap.clusterDisable
	local holder = (noCluster and UIParent) or M.ClusterHolder

	if anchor ~= holder then
		MinimapCluster:ClearAllPoints()
		MinimapCluster:Point('TOPRIGHT', holder, 0, noCluster and 0 or 1)
	end
end

function M:GetMinimapShape()
	return 'SQUARE'
end

function M:Initialize()
	if E.private.general.minimap.enable then
		Minimap:SetMaskTexture([[interface\chatframe\chatframebackground]])
	else
		Minimap:SetMaskTexture([[textures\minimapmask]])

		if E.private.actionbar.enable then
			M:HandleQueueButton(true)
		end

		return
	end

	M.Initialized = true

	menuFrame:SetTemplate('Transparent')

	local holder = CreateFrame('Frame', 'ElvUI_MinimapHolder', Minimap)
	holder:Point('TOPRIGHT', E.UIParent, 'TOPRIGHT', -3, -3)
	holder:Size(Minimap:GetSize())
	M.holder = holder
	E:CreateMover(holder, 'MinimapMover', L["Minimap"], nil, nil, MinimapPostDrag, nil, nil, 'maps,minimap')

	MinimapCluster:SetFrameLevel(20)

	Minimap:SetFrameStrata('LOW')
	Minimap:SetFrameLevel(10)
	Minimap:CreateBackdrop()

	if Minimap.backdrop then -- level to hybrid maps fixed values
		Minimap.backdrop:SetFrameLevel(99)
		Minimap.backdrop:SetFrameStrata('BACKGROUND')
		M:SetScale(Minimap.backdrop, 1)
	end

	local clusterHolder = CreateFrame('Frame', 'ElvUI_MinimapClusterHolder', MinimapCluster)
	clusterHolder:Point('TOPRIGHT', E.UIParent, 'TOPRIGHT', -3, -3)
	clusterHolder:Size(MinimapCluster:GetSize())

	M.ClusterHolder = clusterHolder
	E:CreateMover(clusterHolder, 'MinimapClusterMover', L["Minimap Cluster"], nil, nil, nil, nil, nil, 'maps,minimap')

	local clusterBackdrop = CreateFrame('Frame', 'ElvUI_MinimapClusterBackdrop', MinimapCluster)
	clusterBackdrop:Point('TOPRIGHT', 0, -1)
	clusterBackdrop:SetTemplate()
	M:SetScale(clusterBackdrop, 1)
	M.ClusterBackdrop = clusterBackdrop

	M:ClusterPoint()
	hooksecurefunc(MinimapCluster, 'SetPoint', M.ClusterPoint)

	Minimap:HookScript('OnEnter', function(mm) if E.db.general.minimap.locationText == 'MOUSEOVER' and E.db.general.minimap.clusterDisable then mm.location:Show() end end)
	Minimap:HookScript('OnLeave', function(mm) if E.db.general.minimap.locationText == 'MOUSEOVER' and E.db.general.minimap.clusterDisable then mm.location:Hide() end end)

	Minimap.location = Minimap:CreateFontString(nil, 'OVERLAY')
	Minimap.location:Point('TOP', Minimap, 'TOP', 0, -2)
	Minimap.location:SetJustifyH('CENTER')
	Minimap.location:SetJustifyV('MIDDLE')
	-- M:SetScale(Minimap.location, 1)
	Minimap.location:Hide() -- Fixes blizzard's font rendering issue, keep after M:SetScale

	M:RegisterEvent('PLAYER_ENTERING_WORLD', 'Update_ZoneText')
	M:RegisterEvent('ZONE_CHANGED_NEW_AREA', 'Update_ZoneText')
	M:RegisterEvent('ZONE_CHANGED_INDOORS', 'Update_ZoneText')
	M:RegisterEvent('ZONE_CHANGED', 'Update_ZoneText')

	local killFrames = {
		MinimapBorder,
		MinimapBorderTop,
		MinimapZoomIn,
		MinimapZoomOut,
		MinimapNorthTag,
		MinimapZoneTextButton,
		MiniMapWorldMapButton,
		MiniMapMailBorder,
		MinimapToggleButton,
		MinimapCompassTexture,
	}

	if TimeManagerClockButton then
		tinsert(killFrames, TimeManagerClockButton)
	end

	for _, frame in next, killFrames do
		frame:Kill()
	end

	--Create the new minimap tracking dropdown frame and initialize it
	M.TrackingDropdown = M:CreateMinimapTrackingDropdown()

	if MiniMapLFGFrame then
		MiniMapLFGFrameBorder:Hide()
	end

	MinimapCluster:EnableMouse(false)
	Minimap:EnableMouseWheel(true)
	Minimap:SetScript('OnMouseWheel', M.Minimap_OnMouseWheel)
	Minimap:SetScript('OnMouseDown', M.Minimap_OnMouseDown)
	-- Minimap:SetScript('OnMouseUp', M.Minimap_OnMouseUp)

	M:RegisterEvent('ADDON_LOADED')
	M:UpdateSettings()
end

local function InitializeCallback()
	M:Initialize()
end

E:RegisterModule(M:GetName(), InitializeCallback)
