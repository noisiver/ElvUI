local E, L, V, P, G = unpack(select(2, ...))
local T = E:GetModule('TotemTracker')

local _G = _G
local next = next
local unpack = unpack

local CreateFrame = CreateFrame
local GetTotemInfo = GetTotemInfo
local MAX_TOTEMS = MAX_TOTEMS

local priority = E.myclass == 'SHAMAN' and { [1]=1, [2]=2, [3]=4, [4]=3 } or TOTEM_PRIORITIES


function T:UpdateButton(button, totem)
	if not (button and totem and totem.slot > 0) then return end

	local haveTotem, _, startTime, duration, icon = GetTotemInfo(totem.slot)

	if haveTotem and duration > 0 then
		button:Show()
	else
		button:Hide()
	end

	if haveTotem then
		button.iconTexture:SetTexture(icon)
		button.cooldown:SetCooldown(startTime, duration)

		if totem:GetParent() ~= button.holder then
			totem:ClearAllPoints()
			totem:SetParent(button.holder)
			totem:SetAllPoints(button.holder)
		end
	end
end

function T:Update()
		for i = 1, MAX_TOTEMS do
			T:UpdateButton(T.bar[priority[i]], _G['TotemFrameTotem'..i])
		end
end

function T:PositionAndSize()
	if not E.private.general.totemTracker then return end

	for i = 1, MAX_TOTEMS do
		local button = T.bar[i]
		local prevButton = T.bar[i-1]

		button:Size(T.db.size)
		button:ClearAllPoints()

		if T.db.growthDirection == 'HORIZONTAL' and T.db.sortDirection == 'ASCENDING' then
			if i == 1 then
				button:Point('LEFT', T.bar, 'LEFT', T.db.spacing, 0)
			elseif prevButton then
				button:Point('LEFT', prevButton, 'RIGHT', T.db.spacing, 0)
			end
		elseif T.db.growthDirection == 'VERTICAL' and T.db.sortDirection == 'ASCENDING' then
			if i == 1 then
				button:Point('TOP', T.bar, 'TOP', 0, -T.db.spacing)
			elseif prevButton then
				button:Point('TOP', prevButton, 'BOTTOM', 0, -T.db.spacing)
			end
		elseif T.db.growthDirection == 'HORIZONTAL' and T.db.sortDirection == 'DESCENDING' then
			if i == 1 then
				button:Point('RIGHT', T.bar, 'RIGHT', -T.db.spacing, 0)
			elseif prevButton then
				button:Point('RIGHT', prevButton, 'LEFT', -T.db.spacing, 0)
			end
		else
			if i == 1 then
				button:Point('BOTTOM', T.bar, 'BOTTOM', 0, T.db.spacing)
			elseif prevButton then
				button:Point('BOTTOM', prevButton, 'TOP', 0, T.db.spacing)
			end
		end
	end

	if T.db.growthDirection == 'HORIZONTAL' then
		T.bar:Width(T.db.size * MAX_TOTEMS + T.db.spacing * MAX_TOTEMS + T.db.spacing)
		T.bar:Height(T.db.size + T.db.spacing * 2)
	else
		T.bar:Height(T.db.size * MAX_TOTEMS + T.db.spacing * MAX_TOTEMS + T.db.spacing)
		T.bar:Width(T.db.size + T.db.spacing * 2)
	end

	if E.myclass == 'SHAMAN' then
		T:Update()
	end
end

function T:Initialize()
	T.Initialized = true

	if not E.private.general.totemTracker then return end

	local bar = CreateFrame('Frame', 'ElvUI_TotemTracker', E.UIParent)
	bar:Point('BOTTOMLEFT', E.UIParent, 'BOTTOMLEFT', 490, 4)

	T.bar = bar
	T.db = E.db.general.totems

	for i = 1, MAX_TOTEMS do
		local frame = CreateFrame('Button', bar:GetName()..'Totem'..i, bar)
		frame:SetID(i)
		frame:SetTemplate()
		frame:StyleButton()
		frame:Hide()

		frame.holder = CreateFrame('Frame', nil, frame)
		frame.holder:SetAlpha(0)
		frame.holder:SetAllPoints()

		frame.iconTexture = frame:CreateTexture(nil, 'ARTWORK')
		frame.iconTexture:SetTexCoord(unpack(E.TexCoords))
		frame.iconTexture:SetInside()

		frame.cooldown = CreateFrame('Cooldown', frame:GetName()..'Cooldown', frame, 'CooldownFrameTemplate')
		frame.cooldown:SetReverse(true)
		frame.cooldown:SetInside()

		E:RegisterCooldown(frame.cooldown)

		T.bar[i] = frame
	end

	T:PositionAndSize()

	T:RegisterEvent('PLAYER_TOTEM_UPDATE', 'Update')
	T:RegisterEvent('PLAYER_ENTERING_WORLD', 'Update')

	E:CreateMover(bar, 'TotemTrackerMover', L["Totem Tracker"], nil, nil, nil, nil, nil, 'general,totems')
end

local function InitializeCallback()
	T:Initialize()
end

E:RegisterModule(T:GetName(), InitializeCallback)
