local E, L, V, P, G = unpack(select(2, ...))
local S = E:GetModule("Skins")
local TT = E:GetModule("Tooltip")

--Lua functions
--WoW API / Variables

function S:StyleTooltips()
	if not (E.private.skins.blizzard.enable and E.private.skins.blizzard.tooltip) then return end

	for _, tt in pairs({
		GameTooltip,
		ItemRefTooltip,
		ItemRefShoppingTooltip1,
		ItemRefShoppingTooltip2,
		ItemRefShoppingTooltip3,
		AutoCompleteBox,
		FriendsTooltip,
		ConsolidatedBuffsTooltip,
		ShoppingTooltip1,
		ShoppingTooltip2,
		ShoppingTooltip3,
		WorldMapTooltip,
		WorldMapCompareTooltip1,
		WorldMapCompareTooltip2,
		WorldMapCompareTooltip3,
		DataTextTooltip,
		-- ours
		ElvUIConfigTooltip,
	}) do
		TT:SecureHookScript(tt, "OnShow", "SetStyle")
	end
end

S:AddCallback("Skin_Tooltip", function()
	if not (E.private.skins.blizzard.enable and E.private.skins.blizzard.tooltip) then return end

	S:StyleTooltips()
	S:HandleCloseButton(ItemRefCloseButton)

	-- Skin GameTooltip Status Bar
	GameTooltipStatusBar:SetStatusBarTexture(E.media.normTex)
	GameTooltipStatusBar:CreateBackdrop('Transparent')
	GameTooltipStatusBar:ClearAllPoints()
	GameTooltipStatusBar:Point('TOPLEFT', GameTooltip, 'BOTTOMLEFT', E.Border, -(E.Spacing * 3))
	GameTooltipStatusBar:Point('TOPRIGHT', GameTooltip, 'BOTTOMRIGHT', -E.Border, -(E.Spacing * 3))
	E:RegisterStatusBar(GameTooltipStatusBar)

	-- Tooltip Styling
	TT:SecureHook("GameTooltip_ShowStatusBar", "GameTooltip_ShowStatusBar")

	TT:SecureHookScript(GameTooltip, "OnSizeChanged", "CheckBackdropColor")
	TT:SecureHookScript(GameTooltip, "OnUpdate", "CheckBackdropColor")
end)