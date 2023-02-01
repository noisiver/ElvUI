local E, L, V, P, G = unpack(select(2, ...))
local LSM = E.Libs.LSM

local _G = _G
local strmatch = strmatch
local SetCVar = SetCVar

local function SetFont(obj, font, size, style, sr, sg, sb, sa, sox, soy, r, g, b)
	if not obj then return end

	-- convert because of bad values between versions
	if (style == "" or not style) then
		style = "NONE"
	end

	obj:SetFont(font, size, style)

	if sr and sg and sb then
		obj:SetShadowColor(sr, sg, sb, sa)
	end

	if sox and soy then
		obj:SetShadowOffset(sox, soy)
	end

	if r and g and b then
		obj:SetTextColor(r, g, b)
	elseif r then
		obj:SetAlpha(r)
	end
end

local lastFont = {}
local chatFontHeights = {6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20}
function E:UpdateBlizzardFonts()
	local db			= E.private.general
	local NORMAL		= E.media.normFont
	local NUMBER		= E.media.normFont
	local NAMEFONT		= LSM:Fetch("font", db.namefont)

	-- set an invisible font for xp, honor kill, etc
	local COMBAT		= (E.eyefinity or E.ultrawide) and E.Media.Fonts.Invisible or LSM:Fetch("font", db.dmgfont)

	CHAT_FONT_HEIGHTS = chatFontHeights

	if db.replaceNameFont then UNIT_NAME_FONT = NAMEFONT end
	if db.replaceCombatFont then DAMAGE_TEXT_FONT = COMBAT end
	if db.replaceCombatText then -- Blizzard_CombatText
		SetFont(CombatTextFont, COMBAT, 120, nil, nil, nil, nil, nil, 1, -1)
	end

	if E.eyefinity then
		InterfaceOptionsCombatTextPanelTargetDamage:Hide()
		InterfaceOptionsCombatTextPanelPeriodicDamage:Hide()
		InterfaceOptionsCombatTextPanelPetDamage:Hide()
		InterfaceOptionsCombatTextPanelHealing:Hide()
		SetCVar("CombatLogPeriodicSpells", 0)
		SetCVar("PetMeleeDamage", 0)
		SetCVar("CombatDamage", 0)
		SetCVar("CombatHealing", 0)
	end

	if db.replaceBlizzFonts then
		local size, style, stock = E.db.general.fontSize, E.db.general.fontStyle, not db.unifiedBlizzFonts
		if lastFont.font == NORMAL and lastFont.size == size and lastFont.style == style and lastFont.stock == stock then
			return -- only execute this when needed as it"s excessive to reset all of these
		end

		UNIT_NAME_FONT		= NAMEFONT
		NAMEPLATE_FONT		= NAMEFONT
		DAMAGE_TEXT_FONT	= COMBAT
		STANDARD_TEXT_FONT	= NORMAL

		lastFont.font = NORMAL
		lastFont.size = size
		lastFont.style = style
		lastFont.stock = stock

		local enormous	= size * 1.9
		-- local mega		= size * 1.7
		local huge		= size * 1.5
		local large		= size * 1.3
		local medium	= size * 1.1
		local small		= size * 0.9
		local tiny		= size * 0.8

		SetFont(AchievementFont_Small,				NORMAL, stock and small or size)	-- 10  Achiev dates
		SetFont(BossEmoteNormalHuge,				NORMAL, 24)							-- Talent Title
		SetFont(FriendsFont_Large,					NORMAL, stock and large or size)	-- 14
		SetFont(FriendsFont_Normal,					NORMAL, size)						-- 12
		SetFont(FriendsFont_Small,					NORMAL, stock and small or size)	-- 10
		SetFont(FriendsFont_UserText,				NORMAL, size)						-- 11 Used at the install steps
		SetFont(GameFontHighlightMedium,			NORMAL, stock and medium or 15)		-- 14 Fix QuestLog Title mouseover
		SetFont(GameFontHighlightSmall,				NORMAL, stock and small or size)	-- 11  Skill or Recipe description on TradeSkill frame ???
		SetFont(GameFontNormalLarge,				NORMAL, stock and large or 16)		-- 16
		SetFont(GameFontNormalMed3,					NORMAL, stock and medium or 15)		-- 14
		SetFont(GameTooltipHeader,					NORMAL, size)						-- 14
		SetFont(InvoiceFont_Med,					NORMAL, stock and size or 12)		-- 12  Mail
		SetFont(InvoiceFont_Small,					NORMAL, stock and small or size)	-- 10  Mail
		SetFont(MailFont_Large,						NORMAL, 14)							-- 10  Mail
		SetFont(NumberFont_Outline_Huge,			NUMBER, stock and huge or 28, thick)		-- 30
		SetFont(NumberFont_Outline_Large,			NUMBER, stock and large or 15, outline)		-- 16
		SetFont(NumberFont_Outline_Med,				NUMBER, medium, "OUTLINE")					-- 14
		SetFont(NumberFont_OutlineThick_Mono_Small,	NUMBER, size, "OUTLINE")					-- 12
		SetFont(NumberFont_Shadow_Med,				NORMAL, stock and medium or size)			-- 14  Chat EditBox
		SetFont(NumberFont_Shadow_Small,			NORMAL, stock and small or size)			-- 12
		SetFont(NumberFontNormalSmall,				NORMAL, stock and small or 11, "OUTLINE")	-- 12  Calendar
		SetFont(PVPArenaTextString,					NORMAL, 22, outline)
		SetFont(PVPInfoTextString,					NORMAL, 22, outline)
		SetFont(QuestFont,							NORMAL, size)								-- 18  Quest rewards title(Rewards)
		SetFont(QuestFont_Large,					NORMAL, stock and large or 14)				-- 14
		SetFont(QuestFont_Shadow_Huge,				NORMAL, stock and huge or 15)				-- 18  Quest Title
		SetFont(ReputationDetailFont,				NORMAL, size)								-- 10  Rep Desc when clicking a rep
		SetFont(SpellFont_Small,					NORMAL, 10)
		SetFont(SubSpellFont,						NORMAL, 10)									-- Spellbook Sub Names
		SetFont(SubZoneTextFont,					NORMAL, 24, outline)						-- 26  World Map(SubZone)
		SetFont(SubZoneTextString,					NORMAL, 25, outline)						-- 26
		SetFont(SystemFont_Huge1, 					NORMAL, 20)									-- Garrison Mission XP
		SetFont(SystemFont_Large,					NORMAL, stock and 16 or 15)
		SetFont(SystemFont_Med1,					NORMAL, size)								-- 12
		SetFont(SystemFont_Med3,					NORMAL, medium)								-- 14
		SetFont(SystemFont_Outline,					NORMAL, stock and size or 13, outline)		-- 13  Pet level on World map
		SetFont(SystemFont_Outline_Small,			NUMBER, stock and small or size, "OUTLINE")	-- 10
		SetFont(SystemFont_OutlineThick_Huge2,		NORMAL, stock and huge or 20, thick)		-- 22
		SetFont(SystemFont_OutlineThick_WTF,		NORMAL, stock and enormous or 32, outline)	-- 32  World Map
		SetFont(SystemFont_Shadow_Huge1,			NORMAL, 20, outline)						-- Raid Warning, Boss emote frame too
		SetFont(SystemFont_Shadow_Huge3,			NORMAL, 22)									-- 25  FlightMap
		SetFont(SystemFont_Shadow_Large,			NORMAL, 15)
		SetFont(SystemFont_Shadow_Med1,				NORMAL, size)								-- 12
		SetFont(SystemFont_Shadow_Med2,				NORMAL, stock and medium or 14.3)			-- 14  Shows Order resourses on OrderHallTalentFrame
		SetFont(SystemFont_Shadow_Med3,				NORMAL, medium)								-- 14
		SetFont(SystemFont_Shadow_Small,			NORMAL, small)								-- 10
		SetFont(SystemFont_Small,					NORMAL, stock and small or size)			-- 10
		SetFont(SystemFont_Tiny,					NORMAL, stock and tiny or size)				-- 09
		SetFont(Tooltip_Med,						NORMAL, size)								-- 12
		SetFont(Tooltip_Small,						NORMAL, stock and small or size)			-- 10
		SetFont(ZoneTextString,						NORMAL, stock and enormous or 32, outline)	-- 32

		SetFont(ChatFontSmall,						NORMAL, size)
		SetFont(QuestFontHighlight,					NORMAL, size)
		SetFont(QuestTitleFont,						NORMAL, size + 8)
		SetFont(QuestTitleFontBlackShadow,			NORMAL, size + 8)
		SetFont(SystemFont_Shadow_Outline_Huge2,	NORMAL, 20, outline)
	end
end