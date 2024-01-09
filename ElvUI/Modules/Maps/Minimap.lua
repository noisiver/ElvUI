local E, L, V, P, G = unpack(ElvUI)
local M = E:GetModule('Minimap')
local AB = E:GetModule('ActionBars')
local LSM = E.Libs.LSM

local _G = _G
local mod, floor = mod, math.floor
local next = next
local sort = sort
local ipairs = ipairs
local unpack = unpack
local tinsert = tinsert
local hooksecurefunc = hooksecurefunc
local utf8sub = string.utf8sub

local CloseAllWindows = CloseAllWindows
local CloseMenus = CloseMenus
local CreateFrame = CreateFrame
local GetMinimapZoneText = GetMinimapZoneText
local GetZonePVPInfo = GetZonePVPInfo
local GetTime = GetTime
local HideUIPanel = HideUIPanel
local InCombatLockdown = InCombatLockdown
local IsShiftKeyDown = IsShiftKeyDown
local PlaySound = PlaySound
local ShowUIPanel = ShowUIPanel
local ToggleFrame = ToggleFrame
local UIParent = UIParent
local EasyMenu = EasyMenu

local MainMenuMicroButton_SetNormal = MainMenuMicroButton_SetNormal

local WorldMapFrame = _G.WorldMapFrame
local MinimapCluster = _G.MinimapCluster
local Minimap = _G.Minimap
-- GLOBALS: GetMinimapShape

--Create the minimap micro menu
local menuFrame = CreateFrame('Frame', 'MinimapRightClickMenu', E.UIParent, 'UIDropDownMenuTemplate')
local menuList = {
	{ text = _G.CHARACTER_BUTTON, microOffset = 'CharacterMicroButton', func = function() _G.ToggleCharacter('PaperDollFrame') end },
	{ text = _G.SPELLBOOK_ABILITIES_BUTTON, microOffset = 'SpellbookMicroButton', func = function() ToggleFrame(_G.SpellBookFrame) end },
	{ text = _G.TIMEMANAGER_TITLE, func = _G.ToggleTimeManager, icon = [[Interface\ICONS\INV_Misc_PocketWatch_01]], cropIcon = 1 },
	{ text = _G.CHAT_CHANNELS, func = function() _G.ToggleFriendsFrame(4) end, icon = [[Interface\ICONS\UI_Chat]], cropIcon = 1 },
	{ text = _G.SOCIAL_BUTTON, func = function() _G.ToggleFriendsFrame(1) end, icon = [[Interface\FriendsFrame\Battlenet-BattlenetIcon]], cropIcon = 10 },
	{ text = _G.TALENTS_BUTTON, microOffset = 'TalentMicroButton', func = _G.ToggleTalentFrame },
	{ text = _G.GUILD, microOffset = 'GuildMicroButton', func = function() _G.ToggleFriendsFrame(3) end },
	{ text = _G.ACHIEVEMENT_BUTTON, microOffset = 'AchievementMicroButton', func = _G.ToggleAchievementFrame, icon = E.Media.Textures.GoldCoins },
	{ text = _G.LFG_TITLE, microOffset = 'LFDMicroButton', func = function() ToggleFrame(_G.LFDParentFrame) end },
	{ text = L["Calendar"], func = function() _G.GameTimeFrame:Click() end, icon = [[Interface\Calendar\MeetingIcon]], cropIcon = 1 },
	{ text = _G.BATTLEFIELD_MINIMAP, func = _G.ToggleBattlefieldMinimap },
	{ text = _G.LOOKING_FOR_RAID, func = function() ToggleFrame(_G.LFRParentFrame) end },
	{ text = _G.QUESTLOG_BUTTON, microOffset = 'QuestLogMicroButton', func = function() ToggleFrame(_G.QuestLogFrame) end },
	{ text = _G.HELP_BUTTON, bottom = true, func = _G.ToggleHelpFrame }
}

if E.mylevel >= _G.SHOW_PVP_LEVEL then
	tinsert(menuList, { text = _G.PLAYER_V_PLAYER, microOffset = 'PVPMicroButton', func = function() _G.TogglePVPFrame() end })
end

sort(menuList, function(a, b) if a and b and a.text and b.text then return a.text < b.text end end)

tinsert(menuList, {
	text = _G.MAINMENU_BUTTON,
	microOffset = 'MainMenuMicroButton',
	func = function()
		if not _G.GameMenuFrame:IsShown() then
			if _G.VideoOptionsFrame:IsShown() then
				_G.VideoOptionsFrameCancel:Click()
			elseif _G.AudioOptionsFrame:IsShown() then
				_G.AudioOptionsFrameCancel:Click()
			elseif _G.InterfaceOptionsFrame:IsShown() then
				_G.InterfaceOptionsFrameCancel:Click()
			end

			CloseMenus()
			CloseAllWindows()
			PlaySound(850) -- IG_MAINMENU_OPEN
			ShowUIPanel(_G.GameMenuFrame)
		else
			PlaySound(854) -- IG_MAINMENU_QUIT
			HideUIPanel(_G.GameMenuFrame)

			MainMenuMicroButton_SetNormal()
		end
	end
})

tinsert(menuList, { text = _G.HELP_BUTTON, microOffset = 'HelpMicroButton', bottom = true, func = function() _G.ToggleHelpFrame() end, icon = [[Interface/Helpframe/Openticketicon]], cropIcon = 8 })

for _, menu in ipairs(menuList) do
	menu.notCheckable = true
end

M.RightClickMenu = menuFrame
M.RightClickMenuList = menuList

function M:HandleTrackingButton()
	local tracking = _G.MiniMapTracking
	if not tracking then return end

	if E.private.general.minimap.hideTracking then
		tracking:SetParent(E.HiddenFrame)
	else
		local scale, position, xOffset, yOffset = M:GetIconSettings('tracking')

		tracking:ClearAllPoints()
		tracking:Point(position, Minimap, xOffset, yOffset)
		tracking:SetScale(scale)

		if _G.MiniMapTrackingButtonBorder then
			_G.MiniMapTrackingButtonBorder:Hide()
		end

		if _G.MiniMapTrackingBorder then
			_G.MiniMapTrackingBorder:Hide()
		end

		if _G.MiniMapTrackingBackground then
			_G.MiniMapTrackingBackground:Hide()
		end

		if _G.MiniMapTrackingIcon then
			_G.MiniMapTrackingIcon:SetDrawLayer('ARTWORK')
			_G.MiniMapTrackingIcon:SetTexCoord(unpack(E.TexCoords))
			_G.MiniMapTrackingIcon:SetInside()
		end
	end
end

function M:HideNonInstancePanels()
	if InCombatLockdown() or not WorldMapFrame:IsShown() then return end

	HideUIPanel(WorldMapFrame)
end

function M:ADDON_LOADED(event, addon)
	if addon == 'Blizzard_TimeManager' then
		M:UnregisterEvent(event)
		_G.TimeManagerClockButton:Kill()
	end
end

function M:CreateMinimapTrackingDropdown()
	local dropdown = CreateFrame('Frame', 'ElvUIMiniMapTrackingDropDown', UIParent, 'UIDropDownMenuTemplate')
	dropdown:SetID(1)
	dropdown:SetClampedToScreen(true)
	dropdown:Hide()

	_G.UIDropDownMenu_Initialize(dropdown, _G.MiniMapTrackingDropDown_Initialize, 'MENU')
	dropdown.noResize = true

	return dropdown
end

function M:Minimap_OnMouseDown(btn)
	menuFrame:Hide()

	if M.TrackingDropdown then
		_G.HideDropDownMenu(1, nil, M.TrackingDropdown)
	end

	local position = M.MapHolder.mover:GetPoint()
	if btn == 'MiddleButton' or (btn == 'RightButton' and IsShiftKeyDown()) then
		if not E:AlertCombat() then
			EasyMenu(menuList, menuFrame, 'cursor', position:match('LEFT') and 0 or -160, 0, 'MENU')
		end
	elseif btn == 'RightButton' and M.TrackingDropdown then
		_G.ToggleDropDownMenu(1, nil, M.TrackingDropdown, 'cursor')
	else
		_G.Minimap_OnClick(self)
	end
end

function M:Minimap_OnMouseWheel(d)
	local zoomIn = _G.MinimapZoomIn
	local zoomOut = _G.MinimapZoomOut

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

		local zoomIn = _G.MinimapZoomIn
		local zoomOut = _G.MinimapZoomOut

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

	local panel, holder = _G.MinimapPanel, M.MapHolder
	panel:SetShown(E.db.datatexts.panels.MinimapPanel.enable)
	panel:SetScale(1)

	local mmOffset = E.PixelMode and 1 or 3
	local mmScale = E.db.general.minimap.scale
	Minimap:ClearAllPoints()
	Minimap:Point('TOPRIGHT', holder, -mmOffset/mmScale, -mmOffset/mmScale)
	Minimap:Size(E.MinimapSize)

	local mWidth, mHeight = Minimap:GetSize()
	local bWidth, bHeight = E:Scale(E.PixelMode and 2 or 6), E:Scale(E.PixelMode and 2 or 8)
	local panelSize, joinPanel = (panel:IsShown() and panel:GetHeight()) or E:Scale(E.PixelMode and 1 or -1), E:Scale(1)
	local HEIGHT, WIDTH = (mHeight * mmScale) + (panelSize - joinPanel), mWidth * mmScale
	holder:SetSize(WIDTH + bWidth, HEIGHT + bHeight)

	local locationFont, locaitonSize, locationOutline = LSM:Fetch('font', E.db.general.minimap.locationFont), E.db.general.minimap.locationFontSize, E.db.general.minimap.locationFontOutline
	if Minimap.location then
		Minimap.location:Width(E.MinimapSize)
		Minimap.location:FontTemplate(locationFont, locaitonSize, locationOutline)
		Minimap.location:SetShown(E.db.general.minimap.locationText == 'SHOW' and noCluster)
	end

	-- MiniMapMailIcon:SetTexture(E.Media.MailIcons[E.db.general.minimap.icons.mail.texture] or E.Media.MailIcons.Mail3)
	_G.MiniMapMailIcon:SetTexture(E.Media.Textures.Mail)
	_G.MiniMapMailIcon:Size(20)

	MinimapCluster:SetScale(mmScale)

	local mcWidth = MinimapCluster:GetWidth()
	local height, width = 20 * mmScale, (mcWidth - 30) * mmScale
	M.ClusterHolder:SetSize(width, height)
	M.ClusterBackdrop:SetSize(width, height)
	M.ClusterBackdrop:SetShown(E.db.general.minimap.clusterBackdrop and not noCluster)

	_G.MinimapZoneText:FontTemplate(locationFont, locaitonSize, locationOutline)

	if _G.TimeManagerClockTicker then
		_G.TimeManagerClockTicker:FontTemplate(LSM:Fetch('font', E.db.general.minimap.timeFont), E.db.general.minimap.timeFontSize, E.db.general.minimap.timeFontOutline)
	end

	if noCluster and _G.TimeManagerClockButton then
		_G.TimeManagerClockButton:Kill()
	elseif _G.TimeManagerClockButton then
		_G.TimeManagerClockButton.Show = nil
		_G.TimeManagerClockButton:SetParent(MinimapCluster)
		_G.TimeManagerClockButton:Show()
	end


	local instance = _G.MiniMapInstanceDifficulty
	if M.ClusterHolder then
		E:DisableMover(M.ClusterHolder.mover.name)
	end

	if instance then instance:SetParent(Minimap) end

	M.HandleTrackingButton()

	local gameTime = _G.GameTimeFrame
	if gameTime then
		if E.private.general.minimap.hideCalendar then
			gameTime:Hide()
		else
			local scale, position, xOffset, yOffset = M:GetIconSettings('calendar')
			gameTime:ClearAllPoints()
			gameTime:Point(position, Minimap, xOffset, yOffset)
			gameTime:SetParent(Minimap)
			gameTime:SetFrameLevel(_G.MinimapBackdrop:GetFrameLevel() + 2)
			gameTime:Show()
			gameTime:SetScale(scale)
		end
	end

	local mailFrame = _G.MiniMapMailFrame
	if mailFrame then
		local scale, position, xOffset, yOffset = M:GetIconSettings('mail')
		mailFrame:ClearAllPoints()
		mailFrame:Point(position, Minimap, xOffset, yOffset)
		mailFrame:SetScale(scale)
	end

	local battlefieldFrame = _G.MiniMapBattlefieldFrame
	if battlefieldFrame then
		local scale, position, xOffset, yOffset = M:GetIconSettings('battlefield')
		battlefieldFrame:ClearAllPoints()
		battlefieldFrame:Point(position, Minimap, xOffset, yOffset)
		battlefieldFrame:SetScale(scale)

		if _G.BattlegroundShine then _G.BattlegroundShine:Hide() end
		if _G.MiniMapBattlefieldBorder then _G.MiniMapBattlefieldBorder:Hide() end
		if _G.MiniMapBattlefieldIcon then _G.MiniMapBattlefieldIcon:SetTexCoord(unpack(E.TexCoords)) end
	end

	if instance then
		local scale, position, xOffset, yOffset = M:GetIconSettings('difficulty')
		instance:ClearAllPoints()
		instance:Point(position, Minimap, xOffset, yOffset)
		instance:SetScale(scale)
	end
end

local function MinimapPostDrag()
	_G.MinimapBackdrop:ClearAllPoints()
	_G.MinimapBackdrop:SetAllPoints(Minimap)
end

function M:SetGetMinimapShape()
	_G.GetMinimapShape = M.GetMinimapShape

	Minimap:Size(E.db.general.minimap.size)
end

function M:QueueStatusTimeFormat(seconds)
	local hours = floor(mod(seconds, 86400) / 3600)
	if hours > 0 then return M.QueueStatusDisplay.text:SetFormattedText('%dh', hours) end

	local mins = floor(mod(seconds, 3600) / 60)
	if mins > 0 then return M.QueueStatusDisplay.text:SetFormattedText('%dm', mins) end

	local secs = mod(seconds, 60)
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

function M:GetMinimapShape()
	return 'SQUARE'
end

function M:SetGetMinimapShape()
	_G.GetMinimapShape = M.GetMinimapShape

	Minimap:Size(E.db.general.minimap.size)
end

function M:ClusterSize(width, height)
	local holder = M.ClusterHolder
	if holder and (width ~= holder.savedWidth or height ~= holder.savedHeight) then
		self:SetSize(holder.savedWidth, holder.savedHeight)
	end
end

function M:ClusterPoint(_, anchor)
	local noCluster = E.db.general.minimap.clusterDisable
	local frame = (noCluster and UIParent) or M.ClusterHolder

	if anchor ~= frame then
		MinimapCluster:ClearAllPoints()
		MinimapCluster:Point('TOPRIGHT', frame, 0, noCluster and 0 or 1)
	end
end

function M:Initialize()
	if E.private.general.minimap.enable then
		Minimap:SetMaskTexture([[interface\chatframe\chatframebackground]])
	else
		Minimap:SetMaskTexture([[textures\minimapmask]])

		return
	end

	for _, menu in ipairs(menuList) do
		menu.notCheckable = true

		if menu.cropIcon then
			local left = 0.02 * menu.cropIcon
			local right = 1 - left
			menu.tCoordLeft, menu.tCoordRight, menu.tCoordTop, menu.tCoordBottom = left, right, left, right
			menu.cropIcon = nil
		end

		if menu.microOffset then
			local left, right, top, bottom = AB:GetMicroCoords(menu.microOffset, true)
			menu.tCoordLeft, menu.tCoordRight, menu.tCoordTop, menu.tCoordBottom = left, right, top, bottom
			menu.icon = menu.microOffset == 'PVPMicroButton' and ((E.myfaction == 'Horde' and E.Media.Textures.PVPHorde) or E.Media.Textures.PVPAlliance) or E.Media.Textures.MicroBar
			menu.microOffset = nil
		end
	end

	M.Initialized = true

	menuFrame:SetTemplate('Transparent')

	local mapHolder = CreateFrame('Frame', 'ElvUI_MinimapHolder', Minimap)
	mapHolder:Point('TOPRIGHT', E.UIParent, -3, -3)
	mapHolder:Size(Minimap:GetSize())
	E:CreateMover(mapHolder, 'MinimapMover', L["Minimap"], nil, nil, MinimapPostDrag, nil, nil, 'maps,minimap')
	M.MapHolder = mapHolder
	mapHolder:SetScale(1)

	local clusterHolder = CreateFrame('Frame', 'ElvUI_MinimapClusterHolder', MinimapCluster)
	clusterHolder.savedWidth, clusterHolder.savedHeight = MinimapCluster:GetSize()
	clusterHolder:Point('TOPRIGHT', E.UIParent, -3, -3)
	clusterHolder:SetSize(clusterHolder.savedWidth, clusterHolder.savedHeight)
	clusterHolder:SetFrameLevel(10) -- over minimap mover
	E:CreateMover(clusterHolder, 'MinimapClusterMover', L["Minimap Cluster"], nil, nil, nil, nil, nil, 'maps,minimap')
	M.ClusterHolder = clusterHolder

	local clusterBackdrop = CreateFrame('Frame', 'ElvUI_MinimapClusterBackdrop', MinimapCluster)
	clusterBackdrop:Point('TOPRIGHT', 0, -1)
	clusterBackdrop:SetTemplate()
	clusterBackdrop:SetScale(1)
	M.ClusterBackdrop = clusterBackdrop

	M:ClusterPoint()
	MinimapCluster:EnableMouse(false)
	MinimapCluster:SetFrameLevel(20) -- set before minimap itself
	hooksecurefunc(MinimapCluster, 'SetPoint', M.ClusterPoint)
	hooksecurefunc(MinimapCluster, 'SetSize', M.ClusterSize)

	Minimap:EnableMouseWheel(true)
	Minimap:SetFrameLevel(10)
	Minimap:SetFrameStrata('LOW')
	Minimap:CreateBackdrop()

	if Minimap.backdrop then -- level to hybrid maps fixed values
		Minimap.backdrop:SetFrameLevel(99)
		Minimap.backdrop:SetFrameStrata('BACKGROUND')
		Minimap.backdrop:SetScale(1)
	end

	Minimap:SetScript('OnMouseWheel', M.Minimap_OnMouseWheel)
	Minimap:SetScript('OnMouseDown', M.Minimap_OnMouseDown)
	Minimap:SetScript('OnMouseUp', E.noop)

	Minimap:HookScript('OnEnter', function(mm) if E.db.general.minimap.locationText == 'MOUSEOVER' and E.db.general.minimap.clusterDisable then mm.location:Show() end end)
	Minimap:HookScript('OnLeave', function(mm) if E.db.general.minimap.locationText == 'MOUSEOVER' and E.db.general.minimap.clusterDisable then mm.location:Hide() end end)

	Minimap.location = Minimap:CreateFontString(nil, 'OVERLAY')
	Minimap.location:Point('TOP', Minimap, 0, -2)
	Minimap.location:SetJustifyH('CENTER')
	Minimap.location:SetJustifyV('MIDDLE')
	Minimap.location:Hide()

	M:RegisterEvent('PLAYER_ENTERING_WORLD', 'Update_ZoneText')
	M:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdateSettings')
	M:RegisterEvent('ZONE_CHANGED_NEW_AREA', 'Update_ZoneText')
	M:RegisterEvent('ZONE_CHANGED_INDOORS', 'Update_ZoneText')
	M:RegisterEvent('ZONE_CHANGED', 'Update_ZoneText')

	local killFrames = {
		_G.MinimapBorder,
		_G.MinimapBorderTop,
		_G.MinimapCompassTexture,
		_G.MiniMapMailBorder,
		_G.MinimapNorthTag,
		_G.MiniMapWorldMapButton,
		_G.MinimapZoneTextButton,
		_G.MinimapZoomIn,
		_G.MinimapZoomOut,
		_G.MiniMapTracking
	}

	--Create the new minimap tracking dropdown frame and initialize it
	M.TrackingDropdown = M:CreateMinimapTrackingDropdown()

	if _G.TimeManagerClockButton then
		tinsert(killFrames, _G.TimeManagerClockButton)
	end

	for _, frame in next, killFrames do
		frame:Kill()
	end

	if _G.MiniMapLFGFrame then
		_G.MiniMapLFGFrameBorder:Hide()
	end

	M:RegisterEvent('ADDON_LOADED')
	M:UpdateSettings()
end

local function InitializeCallback()
	M:Initialize()
end

E:RegisterModule(M:GetName(), InitializeCallback)
