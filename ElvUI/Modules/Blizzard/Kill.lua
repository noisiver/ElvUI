local E, L = unpack(ElvUI)
local B = E:GetModule("Blizzard")

--Lua functions
--WoW API / Variables

function B:KillBlizzard()
	VideoOptionsResolutionPanelUseUIScale:Kill()
	VideoOptionsResolutionPanelUIScaleSlider:Kill()
end