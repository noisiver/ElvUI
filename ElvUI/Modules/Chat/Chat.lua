local E, L, V, P, G = unpack(select(2, ...))
local CH = E:GetModule("Chat")
local LO = E:GetModule("Layout")
local Skins = E:GetModule("Skins")
local LSM = E.Libs.LSM

--Lua functions
local _G = _G
local issecurevariable = issecurevariable
local time = time
local pairs, ipairs, unpack, select, tostring, pcall, next, tonumber, type = pairs, ipairs, unpack, select, tostring, pcall, next, tonumber, type
local tinsert, tremove, tconcat, wipe = table.insert, table.remove, table.concat, table.wipe
local gsub, find, gmatch, format, strtrim = string.gsub, string.find, string.gmatch, string.format, string.trim
local strlower, strmatch, strsub, strlen, strupper = strlower, strmatch, strsub, strlen, strupper
--WoW API / Variables
local BetterDate = BetterDate
local ChatEdit_ActivateChat = ChatEdit_ActivateChat
local ChatEdit_ChooseBoxForSend = ChatEdit_ChooseBoxForSend
local ChatEdit_SetLastTellTarget = ChatEdit_SetLastTellTarget
local ChatFrame_GetMessageEventFilters = ChatFrame_GetMessageEventFilters
local ChatHistory_GetAccessID = ChatHistory_GetAccessID
local Chat_GetChatCategory = Chat_GetChatCategory
local CreateFrame = CreateFrame
local FCFManager_ShouldSuppressMessage = FCFManager_ShouldSuppressMessage
local FCFTab_UpdateAlpha = FCFTab_UpdateAlpha
local FCF_GetCurrentChatFrame = FCF_GetCurrentChatFrame
local FCF_StartAlertFlash = FCF_StartAlertFlash
local GMChatFrame_IsGM = GMChatFrame_IsGM
local GetChannelName = GetChannelName
local GetGuildRosterMOTD = GetGuildRosterMOTD
local GetMouseFocus = GetMouseFocus
local GetNumPartyMembers = GetNumPartyMembers
local GetNumRaidMembers = GetNumRaidMembers
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local HasLFGRestrictions = HasLFGRestrictions
local InCombatLockdown = InCombatLockdown
local IsAltKeyDown = IsAltKeyDown
local IsInInstance = IsInInstance
local IsShiftKeyDown = IsShiftKeyDown
local PlaySoundFile = PlaySoundFile
local StaticPopup_Visible = StaticPopup_Visible
local UnitName = UnitName
local hooksecurefunc = hooksecurefunc

local AFK = AFK
local CHAT_BN_CONVERSATION_GET_LINK = CHAT_BN_CONVERSATION_GET_LINK
local CHAT_FILTERED = CHAT_FILTERED
local CHAT_FRAMES = CHAT_FRAMES
local CHAT_IGNORED = CHAT_IGNORED
local CHAT_OPTIONS = CHAT_OPTIONS
local CHAT_RESTRICTED = CHAT_RESTRICTED
local CUSTOM_CLASS_COLORS = CUSTOM_CLASS_COLORS
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local DND = DND
local ICON_LIST = ICON_LIST
local ICON_TAG_LIST = ICON_TAG_LIST
local MAX_WOW_CHAT_CHANNELS = MAX_WOW_CHAT_CHANNELS
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local RAID_WARNING = RAID_WARNING

CH.GuidCache = {}
CH.ClassNames = {}
CH.Keywords = {}
CH.PluginMessageFilters = {}
CH.Smileys = {}
CH.TalkingList = {}
CH.RoleIcons = {
	TANK = E:TextureString(E.Media.Textures.Tank, ":15:15:0:0:64:64:2:56:2:56"),
	HEALER = E:TextureString(E.Media.Textures.Healer, ":15:15:0:0:64:64:2:56:2:56"),
	DAMAGER = E:TextureString(E.Media.Textures.DPS, ":15:15")
}

local lfgRoles = {}
local throttle = {}

local PLAYER_REALM = E:ShortenRealm(E.myrealm)
local PLAYER_NAME = format("%s-%s", E.myname, PLAYER_REALM)

local DEFAULT_STRINGS = {
	BATTLEGROUND = L["BG"],
	GUILD = L["G"],
	PARTY = L["P"],
	RAID = L["R"],
	OFFICER = L["O"],
	BATTLEGROUND_LEADER = L["BGL"],
	PARTY_LEADER = L["PL"],
	RAID_LEADER = L["RL"],
}

local hyperlinkTypes = {
	["item"] = true,
	["spell"] = true,
	["unit"] = true,
	["quest"] = true,
	["enchant"] = true,
	["achievement"] = true,
	["instancelock"] = true,
	["talent"] = true,
	["glyph"] = true,
}

local tabTexs = {
	"",
	"Selected",
	"Highlight"
}

local historyTypes = { -- the events set on the chats are still in FindURL_Events, this is used to ignore some types only
	CHAT_MSG_WHISPER = "WHISPER",
	CHAT_MSG_WHISPER_INFORM = "WHISPER",
	CHAT_MSG_BN_WHISPER = "WHISPER",
	CHAT_MSG_BN_WHISPER_INFORM = "WHISPER",
	CHAT_MSG_GUILD = "GUILD",
	CHAT_MSG_GUILD_ACHIEVEMENT = "GUILD",
	CHAT_MSG_OFFICER = "OFFICER",
	CHAT_MSG_PARTY = "PARTY",
	CHAT_MSG_PARTY_LEADER = "PARTY",
	CHAT_MSG_RAID = "RAID",
	CHAT_MSG_RAID_LEADER = "RAID",
	CHAT_MSG_RAID_WARNING = "RAID",
	CHAT_MSG_BATTLEGROUND = "BATTLEGROUND",
	CHAT_MSG_BATTLEGROUND_LEADER = "BATTLEGROUND",
	CHAT_MSG_CHANNEL = "CHANNEL",
	CHAT_MSG_SAY = "SAY",
	CHAT_MSG_YELL = "YELL",
	CHAT_MSG_EMOTE = "EMOTE" -- this never worked, check it sometime.
}

local canChangeMessage = function(arg1, id)
	if id and arg1 == "" then return id end
end

function CH:MessageIsProtected(message)
	return message and (message ~= gsub(message, "(:?|?)|K(.-)|k", canChangeMessage))
end

function CH:RemoveSmiley(key)
	if key and (type(key) == "string") then
		CH.Smileys[key] = nil
	end
end

function CH:AddSmiley(key, texture)
	if key and (type(key) == "string" and not find(key, ":%%", 1, true)) and texture then
		CH.Smileys[key] = texture
	end
end

local specialChatIcons
do --this can save some main file locals
	local y = ":13:25"
--	local ElvMelon		= E:TextureString(E.Media.ChatLogos.ElvMelon,y)
--	local ElvRainbow	= E:TextureString(E.Media.ChatLogos.ElvRainbow,y)
--	local ElvRed		= E:TextureString(E.Media.ChatLogos.ElvRed,y)
--	local ElvOrange		= E:TextureString(E.Media.ChatLogos.ElvOrange,y)
--	local ElvYellow		= E:TextureString(E.Media.ChatLogos.ElvYellow,y)
--	local ElvGreen		= E:TextureString(E.Media.ChatLogos.ElvGreen,y)
--	local ElvBlue		= E:TextureString(E.Media.ChatLogos.ElvBlue,y)
--	local ElvPurple		= E:TextureString(E.Media.ChatLogos.ElvPurple,y)
	local ElvPink		= E:TextureString(E.Media.ChatLogos.ElvPink,y)

	specialChatIcons = {
		["Крольчонак-x100"] = ElvPink,
	}
end

function CH:ChatFrame_OnMouseScroll(delta)
	local numScrollMessages = CH.db.numScrollMessages or 3
	if delta < 0 then
		if IsShiftKeyDown() then
			self:ScrollToBottom()
		elseif IsAltKeyDown() then
			self:ScrollDown()
		else
			for _ = 1, numScrollMessages do
				self:ScrollDown()
			end
		end
	elseif delta > 0 then
		if IsShiftKeyDown() then
			self:ScrollToTop()
		elseif IsAltKeyDown() then
			self:ScrollUp()
		else
			for _ = 1, numScrollMessages do
				self:ScrollUp()
			end
		end

		if CH.db.scrollDownInterval ~= 0 then
			if self.ScrollTimer then
				CH:CancelTimer(self.ScrollTimer, true)
			end

			self.ScrollTimer = CH:ScheduleTimer("ScrollToBottom", CH.db.scrollDownInterval, self)
		end
	end
end

function CH:GetGroupDistribution()
	local inInstance, kind = IsInInstance()
	if inInstance and (kind == "pvp") then
		return "/bg "
	elseif GetNumRaidMembers() > 0 then
		return "/ra "
	elseif GetNumPartyMembers() > 0 then
		return "/p "
	else
		return "/s "
	end
end

function CH:InsertEmotions(msg)
	for word in gmatch(msg, "%s-%S+%s*") do
		word = strtrim(word)
		local pattern = E:EscapeString(word)
		local emoji = CH.Smileys[pattern]
		if emoji and strmatch(msg, "[%s%p]-"..pattern.."[%s%p]*") then
			local encode = E.Libs.Deflate:EncodeForPrint(word) -- btw keep `|h|cFFffffff|r|h` as it is
			msg = gsub(msg, "([%s%p]-)"..pattern.."([%s%p]*)", (encode and ("%1|Helvmoji:%%"..encode.."|h|cFFffffff|r|h") or "%1")..emoji.."%2")
		end
	end

	return msg
end

function CH:GetSmileyReplacementText(msg)
	if not msg or not self.db.emotionIcons or find(msg, "/run") or find(msg, "/dump") or find(msg, "/script") then
		return msg
	end

	local origlen = strlen(msg)
	local startpos = 1
	local outstr = ""
	local _, pos, endpos

	while startpos <= origlen do
		pos = find(msg, "|H", startpos, true)
		endpos = pos or origlen
		outstr = outstr .. CH:InsertEmotions(strsub(msg, startpos, endpos)) --run replacement on this bit
		startpos = endpos + 1

		if pos then
			_, endpos = find(msg, "|h.-|h", startpos)
			endpos = endpos or origlen

			if startpos < endpos then
				outstr = outstr .. strsub(msg, startpos, endpos) --don"t run replacement on this bit
				startpos = endpos + 1
			end
		end
	end

	return outstr
end

function CH:CopyButtonOnMouseUp(btn)
	local chat = self:GetParent()
	if btn == "RightButton" and chat:GetID() == 1 then
		ToggleFrame(ChatMenu)
	else
		CH:CopyChat(chat)
	end
end

function CH:CopyButtonOnEnter()
	self:SetAlpha(1)
end

function CH:CopyButtonOnLeave()
	local chatName = self:GetParent():GetName()
	local tabText = _G[chatName.."TabText"] or _G[chatName.."Tab"].text
	self:SetAlpha(tabText:IsShown() and 0.35 or 0)
end

function CH:ChatFrameTab_SetAlpha(_, skip)
	if skip then return end
	local chat = CH:GetOwner(self)
	self:SetAlpha((not chat.isDocked or self.selected) and 1 or 0.6, true)
end

do
	local charCount
	function CH:CountLinkCharacters()
		charCount = charCount + (strlen(self) + 4) -- 4 is ending "|h|r"
	end

	local repeatedText
	function CH:EditBoxOnTextChanged()
		local text = self:GetText()
		local len = strlen(text)

		if CH.db.enableCombatRepeat and InCombatLockdown() and (not repeatedText or not strfind(text, repeatedText, 1, true)) then
			local MIN_REPEAT_CHARACTERS = CH.db.numAllowedCombatRepeat
			if len > MIN_REPEAT_CHARACTERS then
				local repeatChar = true
				for i = 1, MIN_REPEAT_CHARACTERS, 1 do
					local first = -1 - i
					if strsub(text,-i,-i) ~= strsub(text,first,first) then
						repeatChar = false
						break
					end
				end
				if repeatChar then
					repeatedText = text
					self:Hide()
					return
				end
			end
		end

		if len == 4 then
			if text == "/tt " then
				local Name, Realm = UnitName("target")
				if Name then
					Name = gsub(Name,"%s","")

					if Realm and Realm ~= "" then
						Name = format("%s-%s", Name, E:ShortenRealm(Realm))
					end
				end

				if Name then
					ChatFrame_SendTell(Name, self.chatFrame)
				else
					UIErrorsFrame:AddMessage(E.InfoColor .. L["Invalid Target"])
				end
			elseif text == "/gr " then
				self:SetText(CH:GetGroupDistribution() .. strsub(text, 5))
				ChatEdit_ParseText(self, 0)
			end
		end

		-- recalculate the character count correctly with hyperlinks in it, using gsub so it matches multiple without gmatch
		charCount = 0
		gsub(text, "(|c%x-|H.-|h).-|h|r", CH.CountLinkCharacters)
		if charCount ~= 0 then len = len - charCount end

		self.characterCount:SetText(len > 0 and (255 - len) or "")

		if repeatedText then
			repeatedText = nil
		end
	end
end

do -- this fixes a taint when you push tab on editbox which blocks secure commands to the chat
	local safe, list = {}, hash_ChatTypeInfoList

	function CH:ChatEdit_UntaintTabList()
		for cmd, name in next, list do
			if not issecurevariable(list, cmd) then
				safe[cmd] = name
				list[cmd] = nil
			end
		end
	end

	function CH:ChatEdit_PleaseRetaint()
		for cmd, name in next, safe do
			list[cmd] = name
			safe[cmd] = nil
		end
	end

	function CH:ChatEdit_PleaseUntaint(event)
		if event == "PLAYER_REGEN_DISABLED" then
			if ChatEdit_GetActiveWindow() then
				CH:ChatEdit_UntaintTabList()
			end
		elseif InCombatLockdown() then
			CH:ChatEdit_UntaintTabList()
		end
	end
end

function CH:EditBoxOnKeyDown(key)
	--Work around broken SetAltArrowKeyMode API. Code from Prat and modified by Simpy
	if (not self.historyLines) or #self.historyLines == 0 then
		return
	end

	if key == "DOWN" then
		self.historyIndex = self.historyIndex - 1

		if self.historyIndex < 1 then
			self.historyIndex = 0
			self:SetText("")
			return
		end
	elseif key == "UP" then
		self.historyIndex = self.historyIndex + 1

		if self.historyIndex > #self.historyLines then
			self.historyIndex = #self.historyLines
		end
	else
		return
	end

	self:SetText(strtrim(self.historyLines[#self.historyLines - (self.historyIndex - 1)]))
end

function CH:EditBoxFocusGained()
	if not LeftChatPanel:IsShown() then
		LeftChatPanel.editboxforced = true
		LeftChatToggleButton:OnEnter()
		self:Show()
	end
end

function CH:EditBoxFocusLost()
	if LeftChatPanel.editboxforced then
		LeftChatPanel.editboxforced = nil

		if LeftChatPanel:IsShown() then
			LeftChatToggleButton:OnLeave()
			self:Hide()
		end
	end

	self.historyIndex = 0
end

function CH:UpdateEditboxFont(chatFrame)
	local style = GetCVar("chatStyle")
	if style == "classic" and CH.LeftChatWindow then
		chatFrame = CH.LeftChatWindow
	end

	if chatFrame == GeneralDockManager.primary then
		chatFrame = GeneralDockManager.selected
	end

	local id = chatFrame:GetID()
	local font = LSM:Fetch("font", CH.db.font)
	local _, fontSize = FCF_GetChatWindowInfo(id)

	local editbox = ChatEdit_ChooseBoxForSend(chatFrame)
	editbox:FontTemplate(font, fontSize, "NONE")
	editbox.header:FontTemplate(font, fontSize, "NONE")

	if editbox.characterCount then
		editbox.characterCount:FontTemplate(font, fontSize, "NONE")
	end

	-- the header and text will not update the placement without focus
	if editbox and editbox:IsShown() then
		editbox:SetFocus()
	end
end

function CH:StyleChat(frame)
	local name = frame:GetName()
	local tab = CH:GetTab(frame)
	tab.text = _G[name.."TabText"]

	local id = frame:GetID()
	local _, fontSize = FCF_GetChatWindowInfo(id)
	local font, size, outline = LSM:Fetch("font", CH.db.font), fontSize, CH.db.fontOutline
	frame:FontTemplate(font, size, outline)

	frame:SetTimeVisible(CH.db.inactivityTimer)
	frame:SetMaxLines(CH.db.maxLines)
	frame:SetFading(CH.db.fade)

	tab.text:FontTemplate(LSM:Fetch("font", CH.db.tabFont), CH.db.tabFontSize, CH.db.tabFontOutline)

	if frame.styled then return end

	frame:SetFrameLevel(4)
	frame:SetClampRectInsets(0,0,0,0)
	frame:SetClampedToScreen(false)
	frame:StripTextures(true)

	_G[name.."ButtonFrame"]:Kill()

	local scrollTex = _G[name.."ThumbTexture"]
	local scrollToBottom = frame.ScrollToBottomButton
	local scroll = frame.ScrollBar
	local editbox = frame.editBox

	if scroll then
		scroll:Kill()
		scrollToBottom:Kill()
		scrollTex:Kill()
	end

	--Character count
	local charCount = editbox:CreateFontString(nil, "ARTWORK")
	charCount:FontTemplate()
	charCount:SetTextColor(190, 190, 190, 0.4)
	charCount:Point("TOPRIGHT", editbox, "TOPRIGHT", -5, 0)
	charCount:Point("BOTTOMRIGHT", editbox, "BOTTOMRIGHT", -5, 0)
	charCount:SetJustifyH("CENTER")
	charCount:Width(40)
	editbox.characterCount = charCount

	for _, texName in pairs(tabTexs) do
		local t, l, m, r = name.."Tab", texName.."Left", texName.."Middle", texName.."Right"
		local main = _G[t]
		local left = _G[t..l] or (main and main[l])
		local middle = _G[t..m] or (main and main[m])
		local right = _G[t..r] or (main and main[r])

		if left then left:SetTexture() end
		if middle then middle:SetTexture() end
		if right then right:SetTexture() end
	end

	hooksecurefunc(tab, "SetAlpha", CH.ChatFrameTab_SetAlpha)

	if not tab.Left then
		tab.Left = _G[name.."TabLeft"] or _G[name.."Tab"].Left
	end

	tab.text:ClearAllPoints()
	tab.text:Point("LEFT", tab, "LEFT", tab.Left:GetWidth(), 0)
	tab:Height(22)

	if tab.conversationIcon then
		tab.conversationIcon:ClearAllPoints()
		tab.conversationIcon:Point("RIGHT", tab.text, "LEFT", -1, 0)
	end

	local a, b, c = select(6, editbox:GetRegions())
	a:Kill()
	b:Kill()
	c:Kill()

	_G[name.."EditBoxLeft"]:Kill()
	_G[name.."EditBoxMid"]:Kill()
	_G[name.."EditBoxRight"]:Kill()

	_G[name.."EditBoxFocusLeft"]:Kill()
	_G[name.."EditBoxFocusMid"]:Kill()
	_G[name.."EditBoxFocusRight"]:Kill()

	editbox:SetAltArrowKeyMode(CH.db.useAltKey)
	editbox:SetAllPoints(LeftChatDataPanel)
	editbox:SetScript("OnTextChanged", CH.EditBoxOnTextChanged)
	editbox:SetScript("OnEditFocusGained", CH.EditBoxFocusGained)
	editbox:SetScript("OnEditFocusLost", CH.EditBoxFocusLost)
	editbox:SetScript("OnKeyDown", CH.EditBoxOnKeyDown)
	editbox:Hide()

	for _, text in ipairs(ElvCharacterDB.ChatEditHistory) do
		editbox:AddHistoryLine(text)
	end

	CH:SecureHook(editbox, "AddHistoryLine", "ChatEdit_AddHistory")

	local language = _G[name.."EditBoxLanguage"]
	language:Height(22)
	language:StripTextures()
	language:SetTemplate("Transparent")
	language:Point("LEFT", editbox, "RIGHT", -32, 0)

	--copy chat button
	local copyButton = CreateFrame("Frame", format("ElvUI_CopyChatButton%d", id), frame)
	copyButton:EnableMouse(true)
	copyButton:SetAlpha(0.35)
	copyButton:Size(20, 22)
	copyButton:Point("TOPRIGHT", 0, -4)
	copyButton:SetFrameLevel(frame:GetFrameLevel() + 5)
	frame.copyButton = copyButton

	local copyTexture = frame.copyButton:CreateTexture(nil, "OVERLAY")
	copyTexture:SetInside()
	copyTexture:SetTexture(E.Media.Textures.Copy)
	copyButton.texture = copyTexture

	copyButton:SetScript("OnMouseUp", CH.CopyButtonOnMouseUp)
	copyButton:SetScript("OnEnter", CH.CopyButtonOnEnter)
	copyButton:SetScript("OnLeave", CH.CopyButtonOnLeave)
	CH:ToggleChatButton(copyButton)

	frame.styled = true
end

function CH:AddMessage(msg, infoR, infoG, infoB, infoID, accessID, typeID, isHistory, historyTime)
	local historyTimestamp --we need to extend the arguments on AddMessage so we can properly handle times without overriding
	if isHistory == "ElvUI_ChatHistory" then historyTimestamp = historyTime end

	if CH.db.timeStampFormat and CH.db.timeStampFormat ~= "NONE" then
		local timeStamp = BetterDate(CH.db.timeStampFormat, historyTimestamp or time())
		timeStamp = gsub(timeStamp, " ", "")
		timeStamp = gsub(timeStamp, "AM", " AM")
		timeStamp = gsub(timeStamp, "PM", " PM")
		if CH.db.useCustomTimeColor then
			local color = CH.db.customTimeColor
			local hexColor = E:RGBToHex(color.r, color.g, color.b)
			msg = format("%s[%s]|r %s", hexColor, timeStamp, msg)
		else
			msg = format("[%s] %s", timeStamp, msg)
		end
	end

	self.OldAddMessage(self, msg, infoR, infoG, infoB, infoID, accessID, typeID)
end

function CH:UpdateSettings()
	for _, frameName in ipairs(CHAT_FRAMES) do
		_G[frameName.."EditBox"]:SetAltArrowKeyMode(CH.db.useAltKey)
	end
end

local removeIconFromLine
do
	local raidIconFunc = function(x) x = x~="" and _G["RAID_TARGET_"..x];return x and ("{"..strlower(x).."}") or "" end
	local stripTextureFunc = function(w, x, y) if x=="" then return (w~="" and w) or (y~="" and y) or "" end end
	local hyperLinkFunc = function(w, x, y) if w~="" then return end
		local emoji = (x~="" and x) and strmatch(x, "elvmoji:%%(.+)")
		return (emoji and E.Libs.Deflate:DecodeForPrint(emoji)) or y
	end
	local fourString = function(v, w, x, y)
		return format("%s%s%s", v, w, (v and v == "1" and x) or y)
	end
	removeIconFromLine = function(text)
		text = gsub(text, [[|TInterface\TargetingFrame\UI%-RaidTargetingIcon_(%d+):0|t]], raidIconFunc) --converts raid icons into {star} etc, if possible.
		text = gsub(text, "(%s?)(|?)|[TA].-|[ta](%s?)", stripTextureFunc) --strip any other texture out but keep a single space from the side(s).
		text = gsub(text, "(|?)|H(.-)|h(.-)|h", hyperLinkFunc) --strip hyperlink data only keeping the actual text.
		text = gsub(text, "(%d+)(.-)|4(.-):(.-);", fourString) --stuff where it goes "day" or "days" like played; tech this is wrong but okayish
		return text
	end
end

local function colorizeLine(text, r, g, b)
	local hexCode = E:RGBToHex(r, g, b)
	local hexReplacement = format("|r%s", hexCode)

	text = gsub(text, "|r", hexReplacement) -- If the message contains color strings then we need to add message color hex code after every "|r"
	text = format("%s%s|r", hexCode, text) -- Add message color

	return text
end

local chatTypeIndexToName = {}
local copyLines = {}

for chatType in pairs(ChatTypeInfo) do
	chatTypeIndexToName[GetChatTypeIndex(chatType)] = chatType
end

function CH:GetLines(frame)
	local lineCount = 0
	local _, message, lineID, info, r, g, b

	for i = 1, frame:GetNumMessages() do
		message, _, lineID = frame:GetMessageInfo(i)

		if message then
			info = ChatTypeInfo[chatTypeIndexToName[lineID]]

			--Set fallback color values
			if info then
				r, g, b = info.r, info.g, info.b
			else
				r, g, b = 1, 1, 1
			end

			--Remove icons
			message = removeIconFromLine(message)

			--Add text color
			message = colorizeLine(message, r, g, b)

			lineCount = lineCount + 1
			copyLines[lineCount] = message
		end
	end

	return lineCount
end

function CH:CopyChat(frame)
	if not CopyChatFrame:IsShown() then
		local _, fontSize = FCF_GetChatWindowInfo(frame:GetID())

		FCF_SetChatWindowFontSize(frame, frame, 0.01)
		CopyChatFrame:Show()
		local lineCt = CH:GetLines(frame)
		local text = tconcat(copyLines, " \n", 1, lineCt)
		FCF_SetChatWindowFontSize(frame, frame, fontSize)
		CopyChatFrameEditBox:SetText(text)
	else
		CopyChatFrame:Hide()
	end
end

function CH:GetOwner(tab)
	if not tab.owner then
		tab.owner = _G[format("ChatFrame%s", tab:GetID())]
	end

	return tab.owner
end

function CH:GetTab(chat)
	if not chat.tab then
		chat.tab = _G[format("ChatFrame%sTab", chat:GetID())]
	end

	return chat.tab
end

function CH:TabOnEnter(tab)
	tab.text:Show()

	if tab.conversationIcon then
		tab.conversationIcon:Show()
	end

	if not CH.db.hideCopyButton then
		local chat = CH:GetOwner(tab)
		if chat and chat.copyButton and GetMouseFocus() ~= chat.copyButton then
			chat.copyButton:SetAlpha(0.35)
		end
	end
end

function CH:TabOnLeave(tab)
	tab.text:Hide()

	if tab.conversationIcon then
		tab.conversationIcon:Hide()
	end

	if not CH.db.hideCopyButton then
		local chat = CH:GetOwner(tab)
		if chat and chat.copyButton and GetMouseFocus() ~= chat.copyButton then
			chat.copyButton:SetAlpha(0)
		end
	end
end

function CH:ChatOnEnter(chat)
	CH:TabOnEnter(CH:GetTab(chat))
end

function CH:ChatOnLeave(chat)
	CH:TabOnLeave(CH:GetTab(chat))
end

function CH:HandleFadeTabs(chat, hook)
	local tab = CH:GetTab(chat)

	if hook then
		if not CH.hooks or not CH.hooks[chat] or not CH.hooks[chat].OnEnter then
			CH:HookScript(chat, "OnEnter", "ChatOnEnter")
			CH:HookScript(chat, "OnLeave", "ChatOnLeave")
		end

		if not CH.hooks or not CH.hooks[tab] or not CH.hooks[tab].OnEnter then
			CH:HookScript(tab, "OnEnter", "TabOnEnter")
			CH:HookScript(tab, "OnLeave", "TabOnLeave")
		end
	else
		if CH.hooks and CH.hooks[chat] and CH.hooks[chat].OnEnter then
			CH:Unhook(chat, "OnEnter")
			CH:Unhook(chat, "OnLeave")
		end

		if CH.hooks and CH.hooks[tab] and CH.hooks[tab].OnEnter then
			CH:Unhook(tab, "OnEnter")
			CH:Unhook(tab, "OnLeave")
		end
	end

	local focus = GetMouseFocus()
	if not hook then
		CH:TabOnEnter(tab)
	elseif focus ~= tab and focus ~= chat then
		CH:TabOnLeave(tab)
	end
end

function CH:ChatEdit_SetLastActiveWindow(editbox)
	local style = editbox.chatStyle or GetCVar("chatStyle")
	if style == "im" then editbox:SetAlpha(0.5) end
end

function CH:FCFDock_SelectWindow(_, chatFrame)
	if chatFrame then
		CH:UpdateEditboxFont(chatFrame)
	end
end

function CH:ChatEdit_ActivateChat(editbox)
	if editbox.chatFrame then
		CH:UpdateEditboxFont(editbox.chatFrame)
	end
end

function CH:ChatEdit_DeactivateChat(editbox)
	local style = editbox.chatStyle or GetCVar("chatStyle")
	if style == "im" then editbox:Hide() end
end

function CH:UpdateEditboxAnchors(event, cvar, value)
	if event and cvar ~= "chatStyle" then return
	elseif not cvar then value = GetCVar("chatStyle") end

	local classic = value == "classic"
	local leftChat = classic and LeftChatPanel
	local panel = 22

	for _, name in ipairs(CHAT_FRAMES) do
		local frame = _G[name]
		local editbox = frame and frame.editBox
		if not editbox then return end
		editbox.chatStyle = value
		editbox:ClearAllPoints()

		local anchorTo = leftChat or frame
		local below, belowInside = CH.db.editBoxPosition == "BELOW_CHAT", CH.db.editBoxPosition == "BELOW_CHAT_INSIDE"
		if below or belowInside then
			local showLeftPanel = E.db.datatexts.panels.LeftChatDataPanel.enable
			editbox:Point("TOPLEFT", anchorTo, "BOTTOMLEFT", classic and (showLeftPanel and 1 or 0) or -2, (classic and (belowInside and 1 or 0) or -5))
			editbox:Point("BOTTOMRIGHT", anchorTo, "BOTTOMRIGHT", classic and (showLeftPanel and -1 or 0) or -2, (classic and (belowInside and 1 or 0) or -5) + (belowInside and panel or -panel))
		else
			local aboveInside = CH.db.editBoxPosition == "ABOVE_CHAT_INSIDE"
			editbox:Point("BOTTOMLEFT", anchorTo, "TOPLEFT", classic and (aboveInside and 1 or 0) or -2, (classic and (aboveInside and -1 or 0) or 2))
			editbox:Point("TOPRIGHT", anchorTo, "TOPRIGHT", classic and (aboveInside and -1 or 0) or 2, (classic and (aboveInside and -1 or 0) or 2) + (aboveInside and -panel or panel))
		end
	end
end

function CH:FindChatWindows()
	if not CH.db.panelSnapping then return end

	local left, right = CH.LeftChatWindow, CH.RightChatWindow

	-- they already exist just return them :)
	if left and right then
		return left, right
	end

	local docker = GeneralDockManager.primary
	for index, name in ipairs(CHAT_FRAMES) do
		local chat = _G[name]
		if (chat.isDocked and chat == docker) or (not chat.isDocked and chat:IsShown()) then
			if not left and index ~= CH.db.panelSnapRightID then
				if CH.db.panelSnapLeftID then
					if CH.db.panelSnapLeftID == index then
						left = chat
					end
				elseif E:FramesOverlap(chat, LeftChatPanel) then
					CH.db.panelSnapLeftID = index
					left = chat
				end
			end

			if not right and index ~= CH.db.panelSnapLeftID then
				if CH.db.panelSnapRightID then
					if CH.db.panelSnapRightID == index then
						right = chat
					end
				elseif E:FramesOverlap(chat, RightChatPanel) then
					CH.db.panelSnapRightID = index
					right = chat
				end
			end

			-- if both are found just return now, don"t wait
			if left and right then
				return left, right
			end
		end
	end

	-- none or one was found
	return left, right
end

function CH:GetDockerParent(docker, chat)
	if not docker then return end

	local _, relativeTo = chat:GetPoint()
	if relativeTo == docker then
		return docker:GetParent()
	end
end

function CH:UpdateChatTab(chat)
	if chat == true then return end
	if chat.lastGM then return end -- ignore GM Chat

	local fadeLeft, fadeRight
	if CH.db.fadeTabsNoBackdrop then
		local both = CH.db.panelBackdrop == "HIDEBOTH"
		fadeLeft = (both or CH.db.panelBackdrop == "RIGHT")
		fadeRight = (both or CH.db.panelBackdrop == "LEFT")
	end

	local tab = CH:GetTab(chat)
	if chat == CH.LeftChatWindow then
		tab:SetParent(LeftChatPanel or UIParent)
		chat:SetParent(LeftChatPanel or UIParent)

		CH:HandleFadeTabs(chat, fadeLeft)
	elseif chat == CH.RightChatWindow then
		tab:SetParent(RightChatPanel or UIParent)
		chat:SetParent(RightChatPanel or UIParent)

		CH:HandleFadeTabs(chat, fadeRight)
	else
		local docker = GeneralDockManager.primary
		local parent = CH:GetDockerParent(docker, chat)

		-- we need to update the tab parent to mimic the docker if its not docked
		if not chat.isDocked then tab:SetParent(parent or UIParent) end
		chat:SetParent(parent or UIParent)

		if parent and docker == CH.LeftChatWindow then
			CH:HandleFadeTabs(chat, fadeLeft)
		elseif parent and docker == CH.RightChatWindow then
			CH:HandleFadeTabs(chat, fadeRight)
		else
			CH:HandleFadeTabs(chat, CH.db.fadeUndockedTabs and CH:IsUndocked(chat, docker))
		end
	end

	-- reparenting chat changes the strata of the resize button
	if chat.EditModeResizeButton then
		chat.EditModeResizeButton:SetFrameStrata("HIGH")
		chat.EditModeResizeButton:SetFrameLevel(6)
	end
end

function CH:UpdateChatTabs()
	for _, name in ipairs(CHAT_FRAMES) do
		CH:UpdateChatTab(_G[name])
	end
end

function CH:ToggleChatButton(button)
	if button then
		if not CH.db.hideCopyButton then
			button:Show()
		else
			button:Hide()
		end
	end
end

function CH:ToggleCopyChatButtons()
	for _, name in ipairs(CHAT_FRAMES) do
		CH:ToggleChatButton(_G[name].copyButton)
	end
end

function CH:RefreshToggleButtons()
	LeftChatToggleButton:SetAlpha(E.db.LeftChatPanelFaded and CH.db.fadeChatToggles and 0 or 1)
	RightChatToggleButton:SetAlpha(E.db.RightChatPanelFaded and CH.db.fadeChatToggles and 0 or 1)

	if not CH.db.hideChatToggles and E.db.datatexts.panels.LeftChatDataPanel.enable then
		LeftChatToggleButton:Show()
	else
		LeftChatToggleButton:Hide()
	end

	if not CH.db.hideChatToggles and E.db.datatexts.panels.RightChatDataPanel.enable then
		RightChatToggleButton:Show()
	else
		RightChatToggleButton:Hide()
	end
end

function CH:IsUndocked(chat, docker)
	if not docker then docker = GeneralDockManager.primary end

	local primaryUndocked = docker ~= CH.LeftChatWindow and docker ~= CH.RightChatWindow
	return not chat.isDocked or (primaryUndocked and ((chat == docker) or CH:GetDockerParent(docker, chat)))
end

function CH:Unsnapped(chat)
	if chat == CH.LeftChatWindow then
		CH.LeftChatWindow = nil
		CH.db.panelSnapLeftID = nil
	elseif chat == CH.RightChatWindow then
		CH.RightChatWindow = nil
		CH.db.panelSnapRightID = nil
	end
end

function CH:ClearSnapping()
	CH.LeftChatWindow = nil
	CH.RightChatWindow = nil
	CH.db.panelSnapLeftID = nil
	CH.db.panelSnapRightID = nil
end

function CH:SnappingChanged(chat)
	CH:Unsnapped(chat)

	if chat == GeneralDockManager.primary then
		for _, frame in ipairs(GeneralDockManager.DOCKED_CHAT_FRAMES) do
			CH:PositionChat(frame)
		end
	else
		CH:PositionChat(chat)
	end
end

function CH:ResnapDock(event)
	if event == "PLAYER_ENTERING_WORLD" then
		return
	end

	CH:SnappingChanged(GeneralDockManager.primary)
end

function CH:ShowBackground(background, show)
	if not background then return end

	if show then
		background.Show = nil
		background:Show()
	else
		background:Kill()
	end
end

function CH:PositionChat(chat)
	if chat == true then return end
	CH.LeftChatWindow, CH.RightChatWindow = CH:FindChatWindows()

	local docker = GeneralDockManager.primary
	if chat == docker then
		local _, chatParent = CH:GetAnchorParents(chat)
		GeneralDockManager:SetParent(chatParent)
	end

	CH:UpdateChatTab(chat)

	if chat:IsMovable() then
		chat:SetUserPlaced(true)
	end

	if chat.FontStringContainer then -- dont use setoutside
		chat.FontStringContainer:ClearAllPoints()
		chat.FontStringContainer:SetPoint("TOPLEFT", -3, 3)
		chat.FontStringContainer:SetPoint("BOTTOMRIGHT", 3, -3)
	end

	local BASE_OFFSET = 32
	if chat == CH.LeftChatWindow then
		local LOG_OFFSET = chat:GetID() == 2 and (LeftChatTab:GetHeight() + 4) or 0

		chat:ClearAllPoints()
		chat:SetPoint("BOTTOMLEFT", LeftChatPanel, "BOTTOMLEFT", 5, 5)
		chat:SetSize(CH.db.panelWidth - 10, CH.db.panelHeight - BASE_OFFSET - LOG_OFFSET)

		CH:ShowBackground(chat.Background, false)
	elseif chat == CH.RightChatWindow then
		local LOG_OFFSET = chat:GetID() == 2 and (LeftChatTab:GetHeight() + 4) or 0

		chat:ClearAllPoints()
		chat:SetPoint("BOTTOMLEFT", RightChatPanel, "BOTTOMLEFT", 5, 5)
		chat:SetSize((CH.db.separateSizes and CH.db.panelWidthRight or CH.db.panelWidth) - 10, (CH.db.separateSizes and CH.db.panelHeightRight or CH.db.panelHeight) - BASE_OFFSET - LOG_OFFSET)

		CH:ShowBackground(chat.Background, false)
	else -- show if: not docked, or ChatFrame1, or attached to ChatFrame1
		CH:ShowBackground(chat.Background, CH:IsUndocked(chat, docker))
	end
end

function CH:PositionChats()
	LeftChatPanel:Size(CH.db.panelWidth, CH.db.panelHeight)
	if CH.db.separateSizes then
		RightChatPanel:Size(CH.db.panelWidthRight, CH.db.panelHeightRight)
	else
		RightChatPanel:Size(CH.db.panelWidth, CH.db.panelHeight)
	end

	LO:RepositionChatDataPanels()

	-- dont proceed when chat is disabled
	if not E.private.chat.enable then return end

	for _, name in ipairs(CHAT_FRAMES) do
		CH:PositionChat(_G[name])
	end
end

function CH:Panel_ColorUpdate()
	local panelColor = CH.db.panelColor
	self:SetBackdropColor(panelColor.r, panelColor.g, panelColor.b, panelColor.a)
end

function CH:Panels_ColorUpdate()
	local panelColor = CH.db.panelColor
	LeftChatPanel.backdrop:SetBackdropColor(panelColor.r, panelColor.g, panelColor.b, panelColor.a)
	RightChatPanel.backdrop:SetBackdropColor(panelColor.r, panelColor.g, panelColor.b, panelColor.a)
end

function CH:UpdateChatTabColors()
	for _, name in ipairs(CHAT_FRAMES) do
		local tab = CH:GetTab(_G[name])
		CH:FCFTab_UpdateColors(tab, tab.selected)
	end
end
E.valueColorUpdateFuncs.Chat = CH.UpdateChatTabColors

function CH:ScrollToBottom(frame)
	frame:ScrollToBottom()

	CH:CancelTimer(frame.ScrollTimer, true)
end

function CH:PrintURL(url)
	return "|cFFFFFFFF[|Hurl:"..url.."|h"..url.."|h]|r "
end

function CH:ReplaceProtocol(arg1, arg2)
	local str = self.."://"..arg1
	return (self == "Houtfit") and str..arg2 or CH:PrintURL(str)
end

function CH:FindURL(_, msg, author, ...)
	if not CH.db.url then
		msg = CH:CheckKeyword(msg, author)
		msg = CH:GetSmileyReplacementText(msg)
		return false, msg, author, ...
	end

	local text, tag = msg, strmatch(msg, "{(.-)}")
	if tag and ICON_TAG_LIST[strlower(tag)] then
		text = gsub(gsub(text, "(%S)({.-})", "%1 %2"), "({.-})(%S)", "%1 %2")
	end

	text = gsub(gsub(text, "(%S)(|c.-|H.-|h.-|h|r)", "%1 %2"), "(|c.-|H.-|h.-|h|r)(%S)", "%1 %2")

	-- http://example.com
	local newMsg, found = gsub(text, "(%a+)://(%S+)(%s?)", CH.ReplaceProtocol)
	if found > 0 then return false, CH:GetSmileyReplacementText(CH:CheckKeyword(newMsg, author)), author, ... end
	-- www.example.com
	newMsg, found = gsub(text, "www%.([_A-Za-z0-9-]+)%.(%S+)%s?", CH:PrintURL("www.%1.%2"))
	if found > 0 then return false, CH:GetSmileyReplacementText(CH:CheckKeyword(newMsg, author)), author, ... end
	-- example@example.com
	newMsg, found = gsub(text, "([_A-Za-z0-9-%.]+)@([_A-Za-z0-9-]+)(%.+)([_A-Za-z0-9-%.]+)%s?", CH:PrintURL("%1@%2%3%4"))
	if found > 0 then return false, CH:GetSmileyReplacementText(CH:CheckKeyword(newMsg, author)), author, ... end
	-- IP address with port 1.1.1.1:1
	newMsg, found = gsub(text, "(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)(:%d+)%s?", CH:PrintURL("%1.%2.%3.%4%5"))
	if found > 0 then return false, CH:GetSmileyReplacementText(CH:CheckKeyword(newMsg, author)), author, ... end
	-- IP address 1.1.1.1
	newMsg, found = gsub(text, "(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%s?", CH:PrintURL("%1.%2.%3.%4"))
	if found > 0 then return false, CH:GetSmileyReplacementText(CH:CheckKeyword(newMsg, author)), author, ... end

	msg = CH:CheckKeyword(msg, author)
	msg = CH:GetSmileyReplacementText(msg)

	return false, msg, author, ...
end

function CH:SetChatEditBoxMessage(message)
	local ChatFrameEditBox = ChatEdit_ChooseBoxForSend()
	local editBoxShown = ChatFrameEditBox:IsShown()
	local editBoxText = ChatFrameEditBox:GetText()
	if not editBoxShown then
		ChatEdit_ActivateChat(ChatFrameEditBox)
	end
	if editBoxText and editBoxText ~= "" then
		ChatFrameEditBox:SetText("")
	end
	ChatFrameEditBox:Insert(message)
	ChatFrameEditBox:HighlightText()
end

local function HyperLinkedURL(data)
	if strsub(data, 1, 3) == "url" then
		local currentLink = strsub(data, 5)
		if currentLink and currentLink ~= "" then
			CH:SetChatEditBoxMessage(currentLink)
		end
	end
end

local SetHyperlink = ItemRefTooltip.SetHyperlink
function ItemRefTooltip:SetHyperlink(data, ...)
	if strsub(data, 1, 3) == "url" then
		HyperLinkedURL(data)
	else
		SetHyperlink(self, data, ...)
	end
end

local hyperLinkEntered
function CH:OnHyperlinkEnter(frame, refString)
	if InCombatLockdown() then return end
	local linkToken = strmatch(refString, "^([^:]+)")
	if hyperlinkTypes[linkToken] then
		GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(refString)
		GameTooltip:Show()
		hyperLinkEntered = frame
	end
end

function CH:OnHyperlinkLeave()
	if hyperLinkEntered then
		hyperLinkEntered = nil
		GameTooltip:Hide()
	end
end

function CH:OnMessageScrollChanged(frame)
	if hyperLinkEntered == frame then
		hyperLinkEntered = nil
		GameTooltip:Hide()
	end
end

function CH:ToggleHyperlink(enable)
	for _, frameName in ipairs(CHAT_FRAMES) do
		local frame = _G[frameName]
		local hooked = self.hooks and self.hooks[frame] and self.hooks[frame].OnHyperlinkEnter
		if enable and not hooked then
			self:HookScript(frame, "OnHyperlinkEnter")
			self:HookScript(frame, "OnHyperlinkLeave")
			self:HookScript(frame, "OnMessageScrollChanged")
		elseif not enable and hooked then
			self:Unhook(frame, "OnHyperlinkEnter")
			self:Unhook(frame, "OnHyperlinkLeave")
			self:Unhook(frame, "OnMessageScrollChanged")
		end
	end
end

function CH:DisableChatThrottle()
	wipe(throttle)
end

function CH:ShortChannel()
	return format("|Hchannel:%s|h[%s]|h", self, DEFAULT_STRINGS[strupper(self)] or gsub(self, "channel:", ""))
end

function CH:HandleShortChannels(msg)
	msg = gsub(msg, "|Hchannel:(.-)|h%[(.-)%]|h", self.ShortChannel)
	msg = gsub(msg, "CHANNEL:", "")
	msg = gsub(msg, "^(.-|h) "..L["whispers"], "%1")
	msg = gsub(msg, "^(.-|h) "..L["says"], "%1")
	msg = gsub(msg, "^(.-|h) "..L["yells"], "%1")
	msg = gsub(msg, "<"..AFK..">", "[|cffFF0000"..AFK.."|r] ")
	msg = gsub(msg, "<"..DND..">", "[|cffE7E716"..DND.."|r] ")
	msg = gsub(msg, "^%["..RAID_WARNING.."%]", "["..L["RW"].."]")

	return msg
end

local PluginIconsCalls = {}
function CH:AddPluginIcons(func)
	tinsert(PluginIconsCalls, func)
end

function CH:GetPluginIcon(sender, name, realm)
	local icon
	for _,func in ipairs(PluginIconsCalls) do
		icon = func(sender, name, realm)
		if icon and icon ~= "" then break end
	end
	return icon
end

function CH:AddPluginMessageFilter(func, position)
	if position then
		tinsert(CH.PluginMessageFilters, position, func)
	else
		tinsert(CH.PluginMessageFilters, func)
	end
end

function CH:GetColoredName(event, _, arg2, _, _, _, _, _, arg8, _, _, _, arg12)
	local chatType = strsub(event, 10)

	local subType = strsub(chatType, 1, 7)
	if subType == "WHISPER" then
		chatType = "WHISPER"
	elseif subType == "CHANNEL" then
		chatType = "CHANNEL"..arg8
	end

	local info = arg12 and ChatTypeInfo[chatType]
	if info and info.colorNameByClass then
		local data = CH:GetPlayerInfoByGUID(arg12)
		local classColor = data and data.classColor
		if classColor then
			return format("|cff%.2x%.2x%.2x%s|r", classColor.r*255, classColor.g*255, classColor.b*255, arg2)
		end
	end

	return arg2
end

-- Clone of FCFManager_GetChatTarget as it doesn"t exist on Classic ERA
function CH:FCFManager_GetChatTarget(chatGroup, playerTarget, channelTarget)
	local chatTarget
	if chatGroup == "CHANNEL" then
		chatTarget = tostring(channelTarget)
	elseif chatGroup == "WHISPER" or chatGroup == "BN_WHISPER" then
		if strsub(playerTarget, 1, 2) ~= "|K" then
			chatTarget = strupper(playerTarget)
		else
			chatTarget = playerTarget
		end
	end

	return chatTarget
end

function CH:ChatFrame_MessageEventHandler(frame, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, isHistory, historyTime, historyName)
	if strsub(event, 1, 8) == "CHAT_MSG" then
		local historySavedName --we need to extend the arguments on CH.ChatFrame_MessageEventHandler so we can properly handle saved names without overriding
		if isHistory == "ElvUI_ChatHistory" then
			historySavedName = historyName
		end

		local chatType = strsub(event, 10)
		local info = ChatTypeInfo[chatType]

		local chatFilters = ChatFrame_GetMessageEventFilters(event)
		if chatFilters then
			for _, filterFunc in next, chatFilters do
				local filter, newarg1, newarg2, newarg3, newarg4, newarg5, newarg6, newarg7, newarg8, newarg9, newarg10, newarg11, newarg12 = filterFunc(frame, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12)
				if filter then
					return true
				elseif newarg1 then
					arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12 = newarg1, newarg2, newarg3, newarg4, newarg5, newarg6, newarg7, newarg8, newarg9, newarg10, newarg11, newarg12
				end
			end
		end

		local _, _, englishClass, _, _, _, name, realm = pcall(GetPlayerInfoByGUID, arg12)
		local coloredName = historySavedName or CH:GetColoredName(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12)

		local nameWithRealm = strmatch(realm ~= "" and realm or E.myrealm, "%s*(%S+)$")
		if name and name ~= "" then
			nameWithRealm = name.."-"..nameWithRealm
			CH.ClassNames[strlower(name)] = englishClass
			CH.ClassNames[strlower(nameWithRealm)] = englishClass
		end

		local channelLength = strlen(arg4)
		local infoType = chatType
		if (strsub(chatType, 1, 7) == "CHANNEL") and (chatType ~= "CHANNEL_LIST") and ((arg1 ~= "INVITE") or (chatType ~= "CHANNEL_NOTICE_USER")) then
			if arg1 == "WRONG_PASSWORD" then
				local staticPopup = _G[StaticPopup_Visible("CHAT_CHANNEL_PASSWORD") or ""]
				if staticPopup and strupper(staticPopup.data) == strupper(arg9) then
					-- Don"t display invalid password messages if we"re going to prompt for a password (bug 102312)
					return
				end
			end

			local found = 0
			for index, value in pairs(frame.channelList) do
				if channelLength > strlen(value) then
					-- arg9 is the channel name without the number in front...
					if ((arg7 > 0) and (frame.zoneChannelList[index] == arg7)) or (strupper(value) == strupper(arg9)) then
						found = 1
						infoType = "CHANNEL"..arg8
						info = ChatTypeInfo[infoType]
						if (chatType == "CHANNEL_NOTICE") and (arg1 == "YOU_LEFT") then
							frame.channelList[index] = nil
							frame.zoneChannelList[index] = nil
						end
						break
					end
				end
			end
			if (found == 0) or not info then
				return true
			end
		end

		local chatGroup = Chat_GetChatCategory(chatType)
		local chatTarget
		if chatGroup == "CHANNEL" or chatGroup == "BN_CONVERSATION" then
			chatTarget = tostring(arg8)
		elseif chatGroup == "WHISPER" or chatGroup == "BN_WHISPER" then
			chatTarget = strupper(arg2)
		end

		if FCFManager_ShouldSuppressMessage(frame, chatGroup, chatTarget) then
			return true
		end

		if chatGroup == "WHISPER" or chatGroup == "BN_WHISPER" then
			if frame.privateMessageList and not frame.privateMessageList[strlower(arg2)] then
				return true
			elseif frame.excludePrivateMessageList and frame.excludePrivateMessageList[strlower(arg2)] then
				return true
			end
		elseif chatGroup == "BN_CONVERSATION" then
			if frame.bnConversationList and not frame.bnConversationList[arg8] then
				return true
			elseif frame.excludeBNConversationList and frame.excludeBNConversationList[arg8] then
				return true
			end
		end

		if chatType == "SYSTEM" or chatType == "SKILL" or chatType == "LOOT" or chatType == "MONEY"
		or chatType == "OPENING" or chatType == "TRADESKILLS" or chatType == "PET_INFO" or chatType == "TARGETICONS" then
			frame:AddMessage(arg1, info.r, info.g, info.b, info.id, false, nil, nil, isHistory, historyTime)
		elseif strsub(chatType,1,7) == "COMBAT_" then
			frame:AddMessage(arg1, info.r, info.g, info.b, info.id, false, nil, nil, isHistory, historyTime)
		elseif strsub(chatType,1,6) == "SPELL_" then
			frame:AddMessage(arg1, info.r, info.g, info.b, info.id, false, nil, nil, isHistory, historyTime)
		elseif strsub(chatType,1,10) == "BG_SYSTEM_" then
			frame:AddMessage(arg1, info.r, info.g, info.b, info.id, false, nil, nil, isHistory, historyTime)
		elseif strsub(chatType,1,11) == "ACHIEVEMENT" then
			frame:AddMessage(format(arg1, "|Hplayer:"..arg2.."|h".."["..coloredName.."]".."|h"), info.r, info.g, info.b, info.id, false, nil, nil, isHistory, historyTime)
		elseif strsub(chatType,1,18) == "GUILD_ACHIEVEMENT" then
			frame:AddMessage(format(arg1, "|Hplayer:"..arg2.."|h".."["..coloredName.."]".."|h"), info.r, info.g, info.b, info.id, false, nil, nil, isHistory, historyTime)
		elseif chatType == "IGNORED" then
			frame:AddMessage(format(CHAT_IGNORED, arg2), info.r, info.g, info.b, info.id, false, nil, nil, isHistory, historyTime)
		elseif chatType == "FILTERED" then
			frame:AddMessage(format(CHAT_FILTERED, arg2), info.r, info.g, info.b, info.id, false, nil, nil, isHistory, historyTime)
		elseif chatType == "RESTRICTED" then
			frame:AddMessage(CHAT_RESTRICTED, info.r, info.g, info.b, info.id, false, nil, nil, isHistory, historyTime)
		elseif chatType == "CHANNEL_LIST" then
			if channelLength > 0 then
				frame:AddMessage(format(_G["CHAT_"..chatType.."_GET"]..arg1, tonumber(arg8), arg4), info.r, info.g, info.b, info.id, false, nil, nil, isHistory, historyTime)
			else
				frame:AddMessage(arg1, info.r, info.g, info.b, info.id, false, nil, nil, isHistory, historyTime)
			end
		elseif chatType == "CHANNEL_NOTICE_USER" then
			local globalstring = _G["CHAT_"..arg1.."_NOTICE_BN"]
			if not globalstring then
				globalstring = _G["CHAT_"..arg1.."_NOTICE"]
			end

			if arg5 ~= "" then
				-- TWO users in this notice (E.G. x kicked y)
				frame:AddMessage(format(globalstring, arg8, arg4, arg2, arg5), info.r, info.g, info.b, info.id, false, nil, nil, isHistory, historyTime)
			elseif arg1 == "INVITE" then
				frame:AddMessage(format(globalstring, arg4, arg2), info.r, info.g, info.b, info.id, false, nil, nil, isHistory, historyTime)
			else
				frame:AddMessage(format(globalstring, arg8, arg4, arg2), info.r, info.g, info.b, info.id, false, nil, nil, isHistory, historyTime)
			end
		elseif chatType == "CHANNEL_NOTICE" then
			if arg1 == "NOT_IN_LFG" then return end
			local globalstring = _G["CHAT_"..arg1.."_NOTICE_BN"]
			if not globalstring then
				globalstring = _G["CHAT_"..arg1.."_NOTICE"]
			end
			if arg10 > 0 then
				arg4 = arg4.." "..arg10
			end

			local accessID = ChatHistory_GetAccessID(Chat_GetChatCategory(chatType), arg8)
			local typeID = ChatHistory_GetAccessID(infoType, arg8)
			frame:AddMessage(format(globalstring, arg8, arg4), info.r, info.g, info.b, info.id, false, accessID, typeID, isHistory, historyTime)
		else
			local body

			-- Add AFK/DND flags
			-- Player Flags
			local pflag, chatIcon, pluginChatIcon = "", specialChatIcons[nameWithRealm], CH:GetPluginIcon(nameWithRealm, name, realm)
			if type(chatIcon) == "function" then chatIcon = chatIcon() end
			if arg6 ~= "" then
				if arg6 == "GM" then
					--If it was a whisper, dispatch it to the GMChat addon.
					if chatType == "WHISPER" then
						return
					end
					--Add Blizzard Icon, this was sent by a GM
					pflag = "|TInterface\\ChatFrame\\UI-ChatIcon-Blizz.blp:0:2:0:-3|t "
				elseif arg6 == "DEV" then
					--Add Blizzard Icon, this was sent by a Dev
					pflag = "|TInterface\\ChatFrame\\UI-ChatIcon-Blizz.blp:0:2:0:-3|t "
				elseif arg6 == "DND" or arg6 == "AFK" then
					pflag = (pflag or "").._G["CHAT_FLAG_"..arg6]
				else
					pflag = _G["CHAT_FLAG_"..arg6]
				end
			else
				-- Special Chat Icon
				if chatIcon then
					pflag = pflag..chatIcon
				end
				-- Plugin Chat Icon
				if pluginChatIcon then
					pflag = pflag..pluginChatIcon
				end
			end

			if chatType == "WHISPER_INFORM" and GMChatFrame_IsGM and GMChatFrame_IsGM(arg2) then
				return
			end

			local showLink = 1
			if strsub(chatType, 1, 7) == "MONSTER" or strsub(chatType, 1, 9) == "RAID_BOSS" then
				showLink = nil
			else
				arg1 = gsub(arg1, "%%", "%%%%")
			end

			if chatType == "PARTY_LEADER" and HasLFGRestrictions() then
				chatType = "PARTY_GUIDE"
			end

			-- Search for icon links and replace them with texture links.
			local term
			for tag in gmatch(arg1, "%b{}") do
				term = strlower(gsub(tag, "[{}]", ""))
				if ICON_TAG_LIST[term] and ICON_LIST[ICON_TAG_LIST[term]] then
					arg1 = gsub(arg1, tag, ICON_LIST[ICON_TAG_LIST[term]].."0|t")
				end
			end

			local playerLink

			if chatType ~= "BN_WHISPER" and chatType ~= "BN_WHISPER_INFORM" and chatType ~= "BN_CONVERSATION" then
				playerLink = "|Hplayer:"..arg2..":"..arg11..":"..chatGroup..(chatTarget and ":"..chatTarget or "").."|h"
			else
				playerLink = "|HBNplayer:"..arg2..":"..arg13..":"..arg11..":"..chatGroup..(chatTarget and ":"..chatTarget or "").."|h"
			end

			if arg3 ~= "" and arg3 ~= "Universal" and arg3 ~= frame.defaultLanguage then
				local languageHeader = "["..arg3.."] "
				if showLink and arg2 ~= "" then
					body = format(_G["CHAT_"..chatType.."_GET"]..languageHeader..arg1, pflag..playerLink.."["..coloredName.."]".."|h")
				else
					body = format(_G["CHAT_"..chatType.."_GET"]..languageHeader..arg1, pflag..arg2)
				end
			else
				if not showLink or strlen(arg2) == 0 then
					body = format(_G["CHAT_"..chatType.."_GET"]..arg1, pflag..arg2, arg2)
				else
					if chatType == "EMOTE" then
						body = format(_G["CHAT_"..chatType.."_GET"]..arg1, pflag..playerLink..coloredName.."|h")
					elseif chatType == "TEXT_EMOTE" then
						body = gsub(arg1, arg2, pflag..playerLink..coloredName.."|h", 1)
					else
						body = format(_G["CHAT_"..chatType.."_GET"]..arg1, pflag..playerLink.."["..coloredName.."]".."|h")
					end
				end
			end

			-- Add Channel
			arg4 = gsub(arg4, "%s%-%s.*", "")
			if chatGroup == "BN_CONVERSATION" then
				body = format(CHAT_BN_CONVERSATION_GET_LINK, arg8, MAX_WOW_CHAT_CHANNELS + arg8)..body
			elseif channelLength > 0 then
				body = "|Hchannel:channel:"..arg8.."|h["..arg4.."]|h "..body
			end

			if CH.db.shortChannels and (chatType ~= "EMOTE" and chatType ~= "TEXT_EMOTE") then
				body = CH:HandleShortChannels(body)
			end

			local accessID = ChatHistory_GetAccessID(chatGroup, chatTarget)
			local typeID = ChatHistory_GetAccessID(infoType, chatTarget)

			if not historySavedName and arg2 ~= E.myname and not CH.SoundTimer and (not CH.db.noAlertInCombat or not InCombatLockdown()) then
				local channels = chatGroup ~= "WHISPER" and chatGroup or (chatType == "WHISPER" or chatType == "BN_WHISPER") and "WHISPER"
				local alertType = CH.db.channelAlerts[channels]

				if alertType and alertType ~= "None" then
					PlaySoundFile(LSM:Fetch("sound", alertType), "Master")
					CH.SoundTimer = E:Delay(1, CH.ThrottleSound)
				end
			end

			frame:AddMessage(body, info.r, info.g, info.b, info.id, false, accessID, typeID, isHistory, historyTime)


			if not historySavedName and (chatType == "WHISPER" or chatType == "BN_WHISPER") then
				ChatEdit_SetLastTellTarget(arg2)
			end
		end

		if not historySavedName and not frame:IsShown() then
			if (frame == DEFAULT_CHAT_FRAME and info.flashTabOnGeneral) or (frame ~= DEFAULT_CHAT_FRAME and info.flashTab) then
				if not CHAT_OPTIONS.HIDE_FRAME_ALERTS or chatType == "WHISPER" or chatType == "BN_WHISPER" then
					FCF_StartAlertFlash(frame) --This would taint if we were not using LibChatAnims
				end
			end
		end

		return true
	end
end

function CH:ChatFrame_ConfigEventHandler(...)
	return ChatFrame_ConfigEventHandler(...)
end

function CH:ChatFrame_SystemEventHandler(frame, event, message, ...)
	return ChatFrame_SystemEventHandler(frame, event, message, ...)
end

function CH:ChatFrame_OnEvent(frame, event, ...)
	if frame.customEventHandler and frame.customEventHandler(frame, event, ...) then return end
	if CH:ChatFrame_ConfigEventHandler(frame, event, ...) then return end
	if CH:ChatFrame_SystemEventHandler(frame, event, ...) then return end
	if CH:ChatFrame_MessageEventHandler(frame, event, ...) then return end
end

function CH:FloatingChatFrame_OnEvent(...)
	CH:ChatFrame_OnEvent(...)
	FloatingChatFrame_OnEvent(...)
end

local function FloatingChatFrameOnEvent(...)
	CH:FloatingChatFrame_OnEvent(...)
end

function CH:ChatFrame_SetScript(script, func)
	if script == "OnMouseWheel" and func ~= CH.ChatFrame_OnMouseScroll then
		self:SetScript(script, CH.ChatFrame_OnMouseScroll)
	end
end

function CH:FCFDockOverflowButton_UpdatePulseState(btn)
	if not btn.Texture then return end

	if btn.alerting then
		btn:SetAlpha(1)
		btn.Texture:SetVertexColor(unpack(E.media.rgbvaluecolor))
	elseif not btn:IsMouseOver() then
		btn.Texture:SetVertexColor(1, 1, 1)
	end
end

do
	local overflowColor = { r = 1, g = 1, b = 1 } -- use this to prevent HandleNextPrevButton from setting the scripts, as this has its own
	function CH:Overflow_OnEnter()
		if self.Texture then
			self.Texture:SetVertexColor(unpack(E.media.rgbvaluecolor))
		end
	end

	function CH:Overflow_OnLeave()
		if self.Texture and not self.alerting then
			self.Texture:SetVertexColor(1, 1, 1)
		end
	end

	local overflow_SetAlpha
	function CH:Overflow_SetAlpha(alpha)
		if self.alerting then
			alpha = 1
		elseif alpha < 0.5 then
			local hooks = CH.hooks and CH.hooks[GeneralDockManager.primary]
			if not (hooks and hooks.OnEnter) then
				alpha = 0.5
			end
		end

		overflow_SetAlpha(self, alpha)
	end

	function CH:StyleOverflowButton()
		local btn = GeneralDockManagerOverflowButton
		local wasSkinned = btn.isSkinned -- keep this before HandleNextPrev
		Skins:HandleNextPrevButton(btn, "down", overflowColor, true)
		btn:SetHighlightTexture(E.Media.Textures.ArrowUpGlow)

		if not wasSkinned then
			overflow_SetAlpha = btn.SetAlpha
			btn.SetAlpha = CH.Overflow_SetAlpha

			btn:HookScript("OnEnter", CH.Overflow_OnEnter)
			btn:HookScript("OnLeave", CH.Overflow_OnLeave)
		end

		local hl = btn.Texture
		hl:SetVertexColor(unpack(E.media.rgbvaluecolor))
		hl:SetRotation(Skins.ArrowRotation.down)

		btn.list:SetTemplate("Transparent")
	end
end

local ignoreChats = { [2]="Log" }
function CH:SetupChat()
	if not E.private.chat.enable then return end

	for _, frameName in ipairs(CHAT_FRAMES) do
		local frame = _G[frameName]
		local id = frame:GetID()
		CH:StyleChat(frame)

		FCFTab_UpdateAlpha(frame)

		local allowHooks = not ignoreChats[id]
		if allowHooks and not frame.OldAddMessage then
			--Don"t add timestamps to combat log, they don"t work.
			--This usually taints, but LibChatAnims should make sure it doesn"t.
			frame.OldAddMessage = frame.AddMessage
			frame.AddMessage = CH.AddMessage
		end

		if not frame.scriptsSet then
			if allowHooks then
				frame:SetScript("OnEvent", FloatingChatFrameOnEvent)
			end

			frame:SetScript("OnMouseWheel", CH.ChatFrame_OnMouseScroll)
			hooksecurefunc(frame, "SetScript", CH.ChatFrame_SetScript)
			frame.scriptsSet = true
		end
	end

	CH:ToggleHyperlink(CH.db.hyperlinkHover)

	local chat = GeneralDockManager.primary
	GeneralDockManager:ClearAllPoints()
	GeneralDockManager:Point("BOTTOMLEFT", chat, "TOPLEFT", 0, 3)
	GeneralDockManager:Point("BOTTOMRIGHT", chat, "TOPRIGHT", 0, 3)
	GeneralDockManager:Height(22)
	GeneralDockManagerScrollFrame:Height(22)
	GeneralDockManagerScrollFrameChild:Height(22)

	CH:StyleOverflowButton()
	CH:PositionChats()

	if not self.HookSecured then
		self:SecureHook("FCF_OpenTemporaryWindow", "SetupChat")
		self.HookSecured = true
	end
end

local function PrepareMessage(author, message)
	if author ~= "" and message ~= "" then
		return format("%s%s", strupper(author), message)
	end
end

function CH:ChatThrottleHandler(author, msg, when)
	msg = PrepareMessage(author, msg)

	if msg then
		for message, msgTime in pairs(throttle) do
			if (when - msgTime) >= self.db.throttleInterval then
				throttle[message] = nil
			end
		end

		if not throttle[msg] then
			throttle[msg] = when
		end
	end
end

function CH:ChatThrottleBlockFlag(author, message, when)
	if author ~= E.myname and self.db.throttleInterval ~= 0 then
		message = PrepareMessage(author, message)
		local msgTime = message and throttle[message]

		if msgTime then
			if (when - msgTime) > self.db.throttleInterval then
				return false, message
			end
		else
			return false
		end
	else
		return false
	end
	return true
end

function CH:ChatThrottleIntervalHandler(event, message, author, ...)
	local when = time()
	local blockFlag, formattedMessage = self:ChatThrottleBlockFlag(author, message, when)

	if blockFlag then
		return true
	else
		if formattedMessage then
			throttle[formattedMessage] = when
		end
		return self:FindURL(event, message, author, ...)
	end
end

function CH:CHAT_MSG_CHANNEL(event, message, author, ...)
	return CH:ChatThrottleIntervalHandler(event, message, author, ...)
end

function CH:CHAT_MSG_YELL(event, message, author, ...)
	return CH:ChatThrottleIntervalHandler(event, message, author, ...)
end

function CH:CHAT_MSG_SAY(event, message, author, ...)
	return CH:ChatThrottleIntervalHandler(event, message, author, ...)
end

function CH:ThrottleSound()
	CH.SoundTimer = nil
end

local protectLinks = {}
function CH:CheckKeyword(message, author)
	local canPlaySound = author ~= E.myname and not self.SoundTimer and self.db.keywordSound ~= "None" and (not self.db.noAlertInCombat or not InCombatLockdown())

	for hyperLink in gmatch(message, "|%x+|H.-|h.-|h|r") do
		local tempLink = gsub(hyperLink, "%s", "|s")
		message = gsub(message, E:EscapeString(hyperLink), tempLink)
		protectLinks[hyperLink] = tempLink

		if canPlaySound then
			for keyword in pairs(CH.Keywords) do
				if hyperLink == keyword then
					PlaySoundFile(LSM:Fetch("sound", self.db.keywordSound), "Master")
					self.SoundTimer = E:Delay(1, self.ThrottleSound)
					canPlaySound = nil
					break
				end
			end
		end
	end

	local rebuiltString
	local isFirstWord = true
	local protectLinksNext = next(protectLinks)

	for word in gmatch(message, "%s-%S+%s*") do
		if not protectLinksNext or not protectLinks[gsub(gsub(word, "%s", ""), "|s", " ")] then
			local tempWord = gsub(word, "[%s%p]", "")
			local lowerCaseWord = strlower(tempWord)

			for keyword in pairs(CH.Keywords) do
				if lowerCaseWord == strlower(keyword) then
					word = gsub(word, tempWord, format("%s%s|r", E.media.hexvaluecolor, tempWord))

					if canPlaySound then
						PlaySoundFile(LSM:Fetch("sound", self.db.keywordSound), "Master")
						self.SoundTimer = E:Delay(1, self.ThrottleSound)
						canPlaySound = nil
					end
				end
			end

			if self.db.classColorMentionsChat then
				tempWord = gsub(word, "^[%s%p]-([^%s%p]+)([%-]?[^%s%p]-)[%s%p]*$", "%1%2")
				lowerCaseWord = strlower(tempWord)

				local classMatch = CH.ClassNames[lowerCaseWord]
				local wordMatch = classMatch and lowerCaseWord

				if wordMatch and not E.global.chat.classColorMentionExcludedNames[wordMatch] then
					local classColorTable = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[classMatch] or RAID_CLASS_COLORS[classMatch]
					word = gsub(word, gsub(tempWord, "%-", "%%-"), format("\124cff%.2x%.2x%.2x%s\124r", classColorTable.r*255, classColorTable.g*255, classColorTable.b*255, tempWord))
				end
			end
		end

		if isFirstWord then
			rebuiltString = word
			isFirstWord = nil
		else
			rebuiltString = rebuiltString..word
		end
	end

	for hyperLink, tempLink in pairs(protectLinks) do
		rebuiltString = gsub(rebuiltString, E:EscapeString(tempLink), hyperLink)
		protectLinks[hyperLink] = nil
	end

	return rebuiltString
end

function CH:AddLines(lines, ...)
	for i = select("#", ...), 1, -1 do
		local x = select(i, ...)
		if x:IsObjectType("FontString") and not x:GetName() then
			tinsert(lines, x:GetText())
		end
	end
end

function CH:ChatEdit_OnEnterPressed(editBox)
	local chatType = editBox:GetAttribute("chatType")
	local chatFrame = chatType and editBox:GetParent()
	if chatFrame and (not chatFrame.isTemporary) and (ChatTypeInfo[chatType].sticky == 1) then
		if not CH.db.sticky then chatType = "SAY" end
		editBox:SetAttribute("chatType", chatType)
	end
end

function CH:SetChatFont(dropDown, chatFrame, fontSize)
	if not chatFrame then chatFrame = FCF_GetCurrentChatFrame() end
	if not fontSize then fontSize = dropDown.value end

	chatFrame:FontTemplate(LSM:Fetch("font", CH.db.font), fontSize, CH.db.fontOutline)

	CH:UpdateEditboxFont(chatFrame)
end

function CH:ChatEdit_AddHistory(_, line) -- editBox, line
	line = line and strtrim(line)

	if line and strlen(line) > 0 then
		local cmd = strmatch(line, "^/%w+")
		if cmd and IsSecureCmd(cmd) then return end -- block secure commands from history

		for index, text in pairs(ElvCharacterDB.ChatEditHistory) do
			if text == line then
				tremove(ElvCharacterDB.ChatEditHistory, index)
				break
			end
		end

		tinsert(ElvCharacterDB.ChatEditHistory, line)

		if #ElvCharacterDB.ChatEditHistory > CH.db.editboxHistorySize then
			tremove(ElvCharacterDB.ChatEditHistory, 1)
		end
	end
end

function CH:UpdateChatKeywords()
	wipe(CH.Keywords)

	local keywords = CH.db.keywords
	keywords = gsub(keywords,",%s",",")

	for stringValue in gmatch(keywords, "[^,]+") do
		if stringValue ~= "" then
			CH.Keywords[stringValue == "%MYNAME%" and E.myname or stringValue] = true
		end
	end
end

function CH:PostChatClose(chat)
	-- clear these off when it"s closed, used by FCFTab_UpdateColors
	local tab = CH:GetTab(chat)
	tab.whisperName = nil
	tab.classColor = nil
end

function CH:UpdateFading()
	for _, frameName in ipairs(CHAT_FRAMES) do
		local frame = _G[frameName]
		if frame then
			frame:SetTimeVisible(CH.db.inactivityTimer)
			frame:SetFading(CH.db.fade)
		end
	end
end

function CH:DisplayChatHistory()
	local data = ElvCharacterDB.ChatHistoryLog
	if not (data and next(data)) then return end

	if not CH:GetPlayerInfoByGUID(E.myguid) then
		E:Delay(0.1, CH.DisplayChatHistory)
		return
	end

	CH.SoundTimer = true -- ignore sounds during pass through ChatFrame_GetMessageEventFilters

	for _, chat in ipairs(CHAT_FRAMES) do
		for _, d in ipairs(data) do
			if type(d) == "table" then
				for _, messageType in pairs(_G[chat].messageTypeList) do
					local historyType, skip = historyTypes[d[50]]
					if historyType then -- let others go by..
						if not CH.db.showHistory[historyType] then skip = true end -- but kill ignored ones
					end
					if not skip and gsub(strsub(d[50],10),"_INFORM","") == messageType then
						if d[1] and not CH:MessageIsProtected(d[1]) then
							CH:ChatFrame_MessageEventHandler(_G[chat],d[50],d[1],d[2],d[3],d[4],d[5],d[6],d[7],d[8],d[9],d[10],d[11],d[12],d[13],d[14],d[15],d[16],d[17],"ElvUI_ChatHistory",d[51],d[52],d[53])
						end
					end
				end
			end
		end
	end

	CH.SoundTimer = nil
end

tremove(ChatTypeGroup.GUILD, 2)
function CH:DelayGuildMOTD()
	tinsert(ChatTypeGroup.GUILD, 2, "GUILD_MOTD")

	local registerGuildEvents = function(msg)
		for _, frameName in ipairs(CHAT_FRAMES) do
			local chat = _G[frameName]
			if chat:IsEventRegistered("CHAT_MSG_GUILD") then
				if msg then
					CH:ChatFrame_SystemEventHandler(chat, "GUILD_MOTD", msg)
				end
				chat:RegisterEvent("GUILD_MOTD")
			end
		end
	end

	if not IsInGuild() then
		registerGuildEvents()
		return
	end

	local delay, checks = 0, 0
	CreateFrame("Frame"):SetScript("OnUpdate", function(df, elapsed)
		delay = delay + elapsed
		if delay < 5 then return end

		local msg = GetGuildRosterMOTD()

		if msg and msg ~= "" then
			registerGuildEvents(msg)
			df:SetScript("OnUpdate", nil)
		else -- 5 seconds can be too fast for the API response. let"s try once every 5 seconds (max 5 checks).
			delay, checks = 0, checks + 1
			if checks >= 5 then
				registerGuildEvents()
				df:SetScript("OnUpdate", nil)
			end
		end
	end)
end

function CH:SaveChatHistory(event, ...)
	local historyType = historyTypes[event]
	if historyType then -- let others go by..
		if not CH.db.showHistory[historyType] then return end -- but kill ignored ones
	end

	if CH.db.throttleInterval ~= 0 and (event == "CHAT_MSG_SAY" or event == "CHAT_MSG_YELL" or event == "CHAT_MSG_CHANNEL") then
		local message, author = ...
		local when = time()

		CH:ChatThrottleHandler(author, message, when)

		if CH:ChatThrottleBlockFlag(author, message, when) then
			return
		end
	end

	if not CH.db.chatHistory then return end
	local data = ElvCharacterDB.ChatHistoryLog
	if not data then return end

	local tempHistory = {}
	for i = 1, select("#", ...) do
		tempHistory[i] = select(i, ...) or false
	end

	if #tempHistory > 0 and not CH:MessageIsProtected(tempHistory[1]) then
		tempHistory[50] = event
		tempHistory[51] = time()

		local coloredName, battleTag
		if tempHistory[13] and tempHistory[13] > 0 then coloredName, battleTag = CH:GetBNFriendColor(tempHistory[2], tempHistory[13], true) end
		if battleTag then tempHistory[53] = battleTag end -- store the battletag, only when the person is known by battletag, so we can replace arg2 later in the function
		tempHistory[52] = coloredName or CH:GetColoredName(event, ...)

		tinsert(data, tempHistory)
		while #data >= CH.db.historySize do
			tremove(data, 1)
		end
	end
end

function CH:GetCombatLog()
	local LOG = COMBATLOG -- ChatFrame2
	if LOG then return LOG, CH:GetTab(LOG) end
end

function CH:FCFDock_ScrollToSelectedTab(dock)
	if dock ~= GeneralDockManager then return end

	local logchat, logchattab = CH:GetCombatLog()
	dock.scrollFrame:ClearAllPoints()
	dock.scrollFrame:Point("RIGHT", dock.overflowButton, "LEFT")
	dock.scrollFrame:Point("TOPLEFT", (logchat and logchat.isDocked and logchattab) or CH:GetTab(dock.primary), "TOPRIGHT")
end

function CH:FCF_SetWindowAlpha(frame, alpha)
	frame.oldAlpha = alpha or 1
end

function CH:CheckLFGRoles()
	if not CH.db.lfgIcons or (GetNumPartyMembers() <= 0) then return end

	wipe(lfgRoles)

	local playerRole = UnitGroupRolesAssigned("player")
	if playerRole then
		lfgRoles[PLAYER_NAME] = CH.RoleIcons[playerRole]
	end

	local unit = ((GetNumRaidMembers() > 0) and "raid" or "party")
	for i = 1, GetNumPartyMembers() do
		if UnitExists(unit..i) and not UnitIsUnit(unit..i, "player") then
			local role = UnitGroupRolesAssigned(unit..i)
			local name, realm = UnitName(unit..i)

			if role and name then
				name = (realm and realm ~= "" and name.."-"..realm) or name.."-"..PLAYER_REALM
				lfgRoles[name] = CH.RoleIcons[role]
			end
		end
	end
end

local FindURL_Events = {
	"CHAT_MSG_WHISPER",
	"CHAT_MSG_WHISPER_INFORM",
	"CHAT_MSG_BN_WHISPER",
	"CHAT_MSG_BN_WHISPER_INFORM",
	"CHAT_MSG_GUILD_ACHIEVEMENT",
	"CHAT_MSG_GUILD",
	"CHAT_MSG_OFFICER",
	"CHAT_MSG_PARTY",
	"CHAT_MSG_PARTY_LEADER",
	"CHAT_MSG_RAID",
	"CHAT_MSG_RAID_LEADER",
	"CHAT_MSG_RAID_WARNING",
	"CHAT_MSG_BATTLEGROUND",
	"CHAT_MSG_BATTLEGROUND_LEADER",
	"CHAT_MSG_CHANNEL",
	"CHAT_MSG_SAY",
	"CHAT_MSG_YELL",
	"CHAT_MSG_EMOTE",
	"CHAT_MSG_TEXT_EMOTE",
	"CHAT_MSG_AFK",
	"CHAT_MSG_DND",
}

function CH:DefaultSmileys()
	local x = ":16:16"
	if next(CH.Smileys) then
		wipe(CH.Smileys)
	end

	-- new keys
	CH:AddSmiley(":angry:", E:TextureString(E.Media.ChatEmojis.Angry,x))
	CH:AddSmiley(":blush:", E:TextureString(E.Media.ChatEmojis.Blush,x))
	CH:AddSmiley(":broken_heart:", E:TextureString(E.Media.ChatEmojis.BrokenHeart,x))
	CH:AddSmiley(":call_me:", E:TextureString(E.Media.ChatEmojis.CallMe,x))
	CH:AddSmiley(":cry:", E:TextureString(E.Media.ChatEmojis.Cry,x))
	CH:AddSmiley(":facepalm:", E:TextureString(E.Media.ChatEmojis.Facepalm,x))
	CH:AddSmiley(":grin:", E:TextureString(E.Media.ChatEmojis.Grin,x))
	CH:AddSmiley(":heart:", E:TextureString(E.Media.ChatEmojis.Heart,x))
	CH:AddSmiley(":heart_eyes:", E:TextureString(E.Media.ChatEmojis.HeartEyes,x))
	CH:AddSmiley(":joy:", E:TextureString(E.Media.ChatEmojis.Joy,x))
	CH:AddSmiley(":kappa:", E:TextureString(E.Media.ChatEmojis.Kappa,x))
	CH:AddSmiley(":middle_finger:", E:TextureString(E.Media.ChatEmojis.MiddleFinger,x))
	CH:AddSmiley(":murloc:", E:TextureString(E.Media.ChatEmojis.Murloc,x))
	CH:AddSmiley(":ok_hand:", E:TextureString(E.Media.ChatEmojis.OkHand,x))
	CH:AddSmiley(":open_mouth:", E:TextureString(E.Media.ChatEmojis.OpenMouth,x))
	CH:AddSmiley(":poop:", E:TextureString(E.Media.ChatEmojis.Poop,x))
	CH:AddSmiley(":rage:", E:TextureString(E.Media.ChatEmojis.Rage,x))
	CH:AddSmiley(":sadkitty:", E:TextureString(E.Media.ChatEmojis.SadKitty,x))
	CH:AddSmiley(":scream:", E:TextureString(E.Media.ChatEmojis.Scream,x))
	CH:AddSmiley(":scream_cat:", E:TextureString(E.Media.ChatEmojis.ScreamCat,x))
	CH:AddSmiley(":slight_frown:", E:TextureString(E.Media.ChatEmojis.SlightFrown,x))
	CH:AddSmiley(":smile:", E:TextureString(E.Media.ChatEmojis.Smile,x))
	CH:AddSmiley(":smirk:", E:TextureString(E.Media.ChatEmojis.Smirk,x))
	CH:AddSmiley(":sob:", E:TextureString(E.Media.ChatEmojis.Sob,x))
	CH:AddSmiley(":sunglasses:", E:TextureString(E.Media.ChatEmojis.Sunglasses,x))
	CH:AddSmiley(":thinking:", E:TextureString(E.Media.ChatEmojis.Thinking,x))
	CH:AddSmiley(":thumbs_up:", E:TextureString(E.Media.ChatEmojis.ThumbsUp,x))
	CH:AddSmiley(":semi_colon:", E:TextureString(E.Media.ChatEmojis.SemiColon,x))
	CH:AddSmiley(":wink:", E:TextureString(E.Media.ChatEmojis.Wink,x))
	CH:AddSmiley(":zzz:", E:TextureString(E.Media.ChatEmojis.ZZZ,x))
	CH:AddSmiley(":stuck_out_tongue:", E:TextureString(E.Media.ChatEmojis.StuckOutTongue,x))
	CH:AddSmiley(":stuck_out_tongue_closed_eyes:", E:TextureString(E.Media.ChatEmojis.StuckOutTongueClosedEyes,x))

	-- Darth"s keys
	CH:AddSmiley(":meaw:", E:TextureString(E.Media.ChatEmojis.Meaw, x))

	-- Simpy"s keys
	CH:AddSmiley(">:%(", E:TextureString(E.Media.ChatEmojis.Rage, x))
	CH:AddSmiley(":%$", E:TextureString(E.Media.ChatEmojis.Blush, x))
	CH:AddSmiley("<\\3", E:TextureString(E.Media.ChatEmojis.BrokenHeart, x))
	CH:AddSmiley(":\"%)", E:TextureString(E.Media.ChatEmojis.Joy, x))
	CH:AddSmiley(";\"%)", E:TextureString(E.Media.ChatEmojis.Joy, x))
	CH:AddSmiley(",,!,,", E:TextureString(E.Media.ChatEmojis.MiddleFinger, x))
	CH:AddSmiley("D:<", E:TextureString(E.Media.ChatEmojis.Rage, x))
	CH:AddSmiley(":o3", E:TextureString(E.Media.ChatEmojis.ScreamCat, x))
	CH:AddSmiley("XP", E:TextureString(E.Media.ChatEmojis.StuckOutTongueClosedEyes, x))
	CH:AddSmiley("8%-%)", E:TextureString(E.Media.ChatEmojis.Sunglasses, x))
	CH:AddSmiley("8%)", E:TextureString(E.Media.ChatEmojis.Sunglasses, x))
	CH:AddSmiley(":%+1:", E:TextureString(E.Media.ChatEmojis.ThumbsUp, x))
	CH:AddSmiley(":;:", E:TextureString(E.Media.ChatEmojis.SemiColon, x))
	CH:AddSmiley(";o;", E:TextureString(E.Media.ChatEmojis.Sob, x))

	-- old keys
	CH:AddSmiley(":%-@", E:TextureString(E.Media.ChatEmojis.Angry, x))
	CH:AddSmiley(":@", E:TextureString(E.Media.ChatEmojis.Angry, x))
	CH:AddSmiley(":%-%)", E:TextureString(E.Media.ChatEmojis.Smile, x))
	CH:AddSmiley(":%)", E:TextureString(E.Media.ChatEmojis.Smile, x))
	CH:AddSmiley(":D", E:TextureString(E.Media.ChatEmojis.Grin, x))
	CH:AddSmiley(":%-D", E:TextureString(E.Media.ChatEmojis.Grin, x))
	CH:AddSmiley(";%-D", E:TextureString(E.Media.ChatEmojis.Grin, x))
	CH:AddSmiley(";D", E:TextureString(E.Media.ChatEmojis.Grin, x))
	CH:AddSmiley("=D", E:TextureString(E.Media.ChatEmojis.Grin, x))
	CH:AddSmiley("xD", E:TextureString(E.Media.ChatEmojis.Grin, x))
	CH:AddSmiley("XD", E:TextureString(E.Media.ChatEmojis.Grin, x))
	CH:AddSmiley(":%-%(", E:TextureString(E.Media.ChatEmojis.SlightFrown, x))
	CH:AddSmiley(":%(", E:TextureString(E.Media.ChatEmojis.SlightFrown, x))
	CH:AddSmiley(":o", E:TextureString(E.Media.ChatEmojis.OpenMouth, x))
	CH:AddSmiley(":%-o", E:TextureString(E.Media.ChatEmojis.OpenMouth, x))
	CH:AddSmiley(":%-O", E:TextureString(E.Media.ChatEmojis.OpenMouth, x))
	CH:AddSmiley(":O", E:TextureString(E.Media.ChatEmojis.OpenMouth, x))
	CH:AddSmiley(":%-0", E:TextureString(E.Media.ChatEmojis.OpenMouth, x))
	CH:AddSmiley(":P", E:TextureString(E.Media.ChatEmojis.StuckOutTongue, x))
	CH:AddSmiley(":%-P", E:TextureString(E.Media.ChatEmojis.StuckOutTongue, x))
	CH:AddSmiley(":p", E:TextureString(E.Media.ChatEmojis.StuckOutTongue, x))
	CH:AddSmiley(":%-p", E:TextureString(E.Media.ChatEmojis.StuckOutTongue, x))
	CH:AddSmiley("=P", E:TextureString(E.Media.ChatEmojis.StuckOutTongue, x))
	CH:AddSmiley("=p", E:TextureString(E.Media.ChatEmojis.StuckOutTongue, x))
	CH:AddSmiley(";%-p", E:TextureString(E.Media.ChatEmojis.StuckOutTongueClosedEyes, x))
	CH:AddSmiley(";p", E:TextureString(E.Media.ChatEmojis.StuckOutTongueClosedEyes, x))
	CH:AddSmiley(";P", E:TextureString(E.Media.ChatEmojis.StuckOutTongueClosedEyes, x))
	CH:AddSmiley(";%-P", E:TextureString(E.Media.ChatEmojis.StuckOutTongueClosedEyes, x))
	CH:AddSmiley(";%-%)", E:TextureString(E.Media.ChatEmojis.Wink, x))
	CH:AddSmiley(";%)", E:TextureString(E.Media.ChatEmojis.Wink, x))
	CH:AddSmiley(":S", E:TextureString(E.Media.ChatEmojis.Smirk, x))
	CH:AddSmiley(":%-S", E:TextureString(E.Media.ChatEmojis.Smirk, x))
	CH:AddSmiley(":,%(", E:TextureString(E.Media.ChatEmojis.Cry, x))
	CH:AddSmiley(":,%-%(", E:TextureString(E.Media.ChatEmojis.Cry, x))
	CH:AddSmiley(":\"%(", E:TextureString(E.Media.ChatEmojis.Cry, x))
	CH:AddSmiley(":\"%-%(", E:TextureString(E.Media.ChatEmojis.Cry, x))
	CH:AddSmiley(":F", E:TextureString(E.Media.ChatEmojis.MiddleFinger, x))
	CH:AddSmiley("<3", E:TextureString(E.Media.ChatEmojis.Heart, x))
	CH:AddSmiley("</3", E:TextureString(E.Media.ChatEmojis.BrokenHeart, x))
end

function CH:GetAnchorParents(chat)
	local Left = (chat == CH.LeftChatWindow and LeftChatPanel)
	local Right = (chat == CH.RightChatWindow and RightChatPanel)
	local Chat, TabPanel = Left or Right or UIParent
	if CH.db.panelTabBackdrop and not ((CH.db.panelBackdrop == "HIDEBOTH") or (Left and CH.db.panelBackdrop == "RIGHT") or (Right and CH.db.panelBackdrop == "LEFT")) then
		TabPanel = (Left and LeftChatTab) or (Right and RightChatTab)
	end

	return TabPanel or Chat, Chat
end

function CH:BuildCopyChatFrame()
	local frame = CreateFrame("Frame", "CopyChatFrame", E.UIParent)
	tinsert(UISpecialFrames, "CopyChatFrame")
	frame:SetTemplate("Transparent")
	frame:Size(700, 200)
	frame:Point("BOTTOM", E.UIParent, "BOTTOM", 0, 3)
	frame:Hide()
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetResizable(true)
	frame:SetScript("OnMouseDown", function(copyChat, button)
		if button == "LeftButton" and not copyChat.isMoving then
			copyChat:StartMoving()
			copyChat.isMoving = true
		elseif button == "RightButton" and not copyChat.isSizing then
			copyChat:StartSizing()
			copyChat.isSizing = true
		end
	end)
	frame:SetScript("OnMouseUp", function(copyChat, button)
		if button == "LeftButton" and copyChat.isMoving then
			copyChat:StopMovingOrSizing()
			copyChat.isMoving = false
		elseif button == "RightButton" and copyChat.isSizing then
			copyChat:StopMovingOrSizing()
			copyChat.isSizing = false
		end
	end)
	frame:SetScript("OnHide", function(copyChat)
		if copyChat.isMoving or copyChat.isSizing then
			copyChat:StopMovingOrSizing()
			copyChat.isMoving = false
			copyChat.isSizing = false
		end
	end)
	frame:SetFrameStrata("DIALOG")

	local scrollArea = CreateFrame("ScrollFrame", "CopyChatScrollFrame", frame, "UIPanelScrollFrameTemplate")
	scrollArea:Point("TOPLEFT", frame, "TOPLEFT", 8, -30)
	scrollArea:Point("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 8)
	Skins:HandleScrollBar(CopyChatScrollFrameScrollBar)
	scrollArea:SetScript("OnSizeChanged", function(scroll)
		CopyChatFrameEditBox:Width(scroll:GetWidth())
		CopyChatFrameEditBox:Height(scroll:GetHeight())
	end)
	scrollArea:HookScript("OnVerticalScroll", function(scroll, offset)
		CopyChatFrameEditBox:SetHitRectInsets(0, 0, offset, (CopyChatFrameEditBox:GetHeight() - offset - scroll:GetHeight()))
	end)

	local editBox = CreateFrame("EditBox", "CopyChatFrameEditBox", frame)
	editBox:SetMultiLine(true)
	editBox:SetMaxLetters(99999)
	editBox:EnableMouse(true)
	editBox:SetAutoFocus(false)
	editBox:SetFontObject("ChatFontNormal")
	editBox:Width(scrollArea:GetWidth())
	editBox:Height(200)
	editBox:SetScript("OnEscapePressed", function() CopyChatFrame:Hide() end)
	scrollArea:SetScrollChild(editBox)
	CopyChatFrameEditBox:SetScript("OnTextChanged", function(_, userInput)
		if userInput then return end
		local _, Max = CopyChatScrollFrameScrollBar:GetMinMaxValues()
		for _ = 1, Max do
			ScrollFrameTemplate_OnMouseWheel(CopyChatScrollFrame, -1)
		end
	end)

	local close = CreateFrame("Button", "CopyChatFrameCloseButton", frame, "UIPanelCloseButton")
	close:Point("TOPRIGHT")
	close:SetFrameLevel(close:GetFrameLevel() + 1)
	close:EnableMouse(true)
	Skins:HandleCloseButton(close)
end

CH.TabStyles = {
	NONE	= "%s",
	ARROW	= "%s>|r%s%s<|r",
	ARROW1	= "%s>|r %s %s<|r",
	ARROW2	= "%s<|r%s%s>|r",
	ARROW3	= "%s<|r %s %s>|r",
	BOX		= "%s[|r%s%s]|r",
	BOX1	= "%s[|r %s %s]|r",
	CURLY	= "%s{|r%s%s}|r",
	CURLY1	= "%s{|r %s %s}|r",
	CURVE	= "%s(|r%s%s)|r",
	CURVE1	= "%s(|r %s %s)|r"
}

function CH:FCFTab_UpdateColors(tab, selected)
	if not tab then return end

	-- actual chat tab and other
	local chat = CH:GetOwner(tab)
	if not chat then return end

	tab.selected = selected

	local whisper = tab.conversationIcon and chat.chatTarget
	local name = chat.name or UNKNOWN

	if whisper and not tab.whisperName then
		tab.whisperName = gsub(E:StripMyRealm(name), "([%S]-)%-[%S]+", "%1|cFF999999*|r")
	end

	if selected then -- color tables are class updated in UpdateMedia
		if CH.db.tabSelector == "NONE" then
			tab:SetFormattedText(CH.TabStyles.NONE, tab.whisperName or name)
		else
			local color = CH.db.tabSelectorColor
			local hexColor = E:RGBToHex(color.r, color.g, color.b)
			tab:SetFormattedText(CH.TabStyles[CH.db.tabSelector] or CH.TabStyles.ARROW1, hexColor, tab.whisperName or name, hexColor)
		end

		if CH.db.tabSelectedTextEnabled then
			local color = CH.db.tabSelectedTextColor
			tab.text:SetTextColor(color.r, color.g, color.b)
			return -- using selected text color
		end
	end

	if whisper then
		if not selected then
			tab:SetText(tab.whisperName or name)
		end

		if not tab.classColor then
			local classMatch = CH.ClassNames[strlower(name)]
			if classMatch then tab.classColor = E:ClassColor(classMatch) end
		end

		if tab.classColor then
			tab:GetText():SetTextColor(tab.classColor.r, tab.classColor.g, tab.classColor.b)
		end
	else
		if not selected then
			tab:SetText(name)
		end

		if tab.text then
			tab.text:SetTextColor(unpack(E.media.rgbvaluecolor))
		end
	end
end

function CH:GetPlayerInfoByGUID(guid)
	local data = CH.GuidCache[guid]
	if not data then
		local ok, localizedClass, englishClass, localizedRace, englishRace, sex, name, realm = pcall(GetPlayerInfoByGUID, guid)
		if not (ok and englishClass) then return end

		if realm == "" then realm = nil end -- dont add realm for people on your realm
		local shortRealm, nameWithRealm = realm and E:ShortenRealm(realm)
		if name and name ~= "" then
			nameWithRealm = (shortRealm and name.."-"..shortRealm) or name.."-"..PLAYER_REALM
		end

		-- move em into a table
		data = {
			localizedClass = localizedClass,
			englishClass = englishClass,
			localizedRace = localizedRace,
			englishRace = englishRace,
			sex = sex,
			name = name,
			realm = realm,
			nameWithRealm = nameWithRealm -- we use this to correct mobile to link with the realm as well
		}

		-- add it to ClassNames
		if name then
			CH.ClassNames[strlower(name)] = englishClass
		end
		if nameWithRealm then
			CH.ClassNames[strlower(nameWithRealm)] = englishClass
		end

		-- push into the cache
		CH.GuidCache[guid] = data
	end

	-- we still need to recheck this each time because CUSTOM_CLASS_COLORS can change
	if data then data.classColor = E:ClassColor(data.englishClass) end

	return data
end

function CH:ResetEditboxHistory()
	ElvCharacterDB.ChatEditHistory = {}
end

function CH:ResetHistory()
	ElvCharacterDB.ChatHistoryLog = {}
end

--Copied from FrameXML FloatingChatFrame.lua and modified to fix
--not being able to close chats in combat since 8.2 or something. ~Simpy
function CH:FCF_Close(fallback)
	if fallback then self = fallback end
	if not self or self == CH then self = FCF_GetCurrentChatFrame() end
	if self == DEFAULT_CHAT_FRAME then return end

	FCF_UnDockFrame(self)
	self:Hide() -- switch from HideUIPanel(frame) to frame:Hide()
	CH:GetTab(self):Hide() -- use our get tab function instead

	FCF_FlagMinimizedPositionReset(self)

	if self.minFrame and self.minFrame:IsShown() then
		self.minFrame:Hide()
	end

	if self.isTemporary then
		FCFManager_UnregisterDedicatedFrame(self, self.chatType, self.chatTarget)

		self.isRegistered = false
		self.inUse = false
	end

	--Reset what this window receives.
	ChatFrame_RemoveAllChannels(self)
	ChatFrame_RemoveAllMessageGroups(self)
	ChatFrame_ReceiveAllPrivateMessages(self)

	CH:PostChatClose(self) -- also call this since it won"t call from blizzard in this case
end

--Same reason as CH.FCF_Close
function CH:FCF_PopInWindow(fallback)
	if fallback then self = fallback end
	if not self or self == CH then self = FCF_GetCurrentChatFrame() end
	if self == DEFAULT_CHAT_FRAME then return end

	--Restore any chats this frame had to the DEFAULT_CHAT_FRAME
	FCF_RestoreChatsToFrame(DEFAULT_CHAT_FRAME, self)
	CH.FCF_Close(self) -- use ours to fix close chat bug
end

do
	local closeButtons = {
		[CLOSE_CHAT_CONVERSATION_WINDOW] = true,
		[CLOSE_CHAT_WHISPER_WINDOW] = true,
		[CLOSE_CHAT_WINDOW] = true
	}

	function CH:UIDropDownMenu_AddButton(info, level)
		if info and closeButtons[info.text] then
			if not level then level = 1 end

			local list = _G["DropDownList"..level]
			local index = (list and list.numButtons) or 1
			local button = _G[list:GetName().."Button"..index]

			if button.func == FCF_PopInWindow then
				button.func = CH.FCF_PopInWindow
			elseif button.func == FCF_Close then
				button.func = CH.FCF_Close
			end
		end
	end
end

function CH:Initialize()
	if ElvCharacterDB.ChatHistory then ElvCharacterDB.ChatHistory = nil end --Depreciated
	if ElvCharacterDB.ChatLog then ElvCharacterDB.ChatLog = nil end --Depreciated

	self:DelayGuildMOTD() --Keep this before `is Chat Enabled` check

	CH.db = E.db.chat
	if not E.private.chat.enable then
		-- if the chat module is off we still need to spawn the dts for the panels
		-- if we are going to have the panels show even when it"s disabled
		CH:PositionChats()
		CH:Panels_ColorUpdate()
		return
	end
	CH.Initialized = true

	if not ElvCharacterDB.ChatEditHistory then ElvCharacterDB.ChatEditHistory = {} end
	if not ElvCharacterDB.ChatHistoryLog or not CH.db.chatHistory then ElvCharacterDB.ChatHistoryLog = {} end

	ChatFrameMenuButton:Kill()
	FriendsMicroButton:Kill()

	CH:SetupChat()
	CH:DefaultSmileys()
	CH:UpdateChatKeywords()
	CH:UpdateFading()
	CH:CheckLFGRoles()
	CH:Panels_ColorUpdate()
	CH:UpdateEditboxAnchors()

	CH:SecureHook("ChatEdit_ActivateChat")
	CH:SecureHook("ChatEdit_DeactivateChat")
	CH:SecureHook("ChatEdit_OnEnterPressed")
	CH:SecureHook("ChatEdit_SetLastActiveWindow")
	CH:SecureHook("FCFTab_UpdateColors")
	CH:SecureHook("FCFDock_SelectWindow")
	CH:SecureHook("FCFDock_ScrollToSelectedTab")
	CH:SecureHook("FCF_SetWindowAlpha")
	CH:SecureHook("FCF_Close", "PostChatClose")
	CH:SecureHook("FCF_DockFrame", "SnappingChanged")
	CH:SecureHook("FCF_ResetChatWindows", "ClearSnapping")
	CH:SecureHook("FCF_SavePositionAndDimensions", "SnappingChanged")
	CH:SecureHook("FCF_SetChatWindowFontSize", "SetChatFont")
	CH:SecureHook("FCF_UnDockFrame", "SnappingChanged")
	CH:SecureHook("ChatEdit_OnShow", "ChatEdit_PleaseUntaint")
	CH:SecureHook("ChatEdit_OnHide", "ChatEdit_PleaseRetaint")
	CH:SecureHook("FCFDockOverflowButton_UpdatePulseState")
	CH:SecureHook("UIDropDownMenu_AddButton")
	CH:SecureHook("GetPlayerInfoByGUID")

	CH:RegisterEvent("PLAYER_ENTERING_WORLD", "ResnapDock")
	CH:RegisterEvent("UPDATE_CHAT_WINDOWS", "SetupChat")
	CH:RegisterEvent("UPDATE_FLOATING_CHAT_WINDOWS", "SetupChat")
	CH:RegisterEvent("RAID_ROSTER_UPDATE", "CheckLFGRoles")
	CH:RegisterEvent("PARTY_MEMBERS_CHANGED", "CheckLFGRoles")
	CH:RegisterEvent("PLAYER_REGEN_DISABLED", "ChatEdit_PleaseUntaint")
	CH:RegisterEvent("CVAR_UPDATE", "UpdateEditboxAnchors")

	if WIM then
		WIM.RegisterWidgetTrigger("chat_display", "whisper,chat,w2w,demo", "OnHyperlinkClick", function(self) CH.clickedframe = self end)
		WIM.RegisterItemRefHandler("url", HyperLinkedURL)
	end

	for _, event in ipairs(FindURL_Events) do
		ChatFrame_AddMessageEventFilter(event, CH[event] or CH.FindURL)
		local nType = strsub(event, 10)
		if nType ~= "AFK" and nType ~= "DND" then
			CH:RegisterEvent(event, "SaveChatHistory")
		end
	end

	if CH.db.chatHistory then CH:DisplayChatHistory() end
	CH:BuildCopyChatFrame()

	-- Editbox Backdrop Color
	hooksecurefunc("ChatEdit_UpdateHeader", function(editbox)
		local chatType = editbox:GetAttribute("chatType")
		if not chatType then return end

		local ChatTypeInfo = ChatTypeInfo
		local info = ChatTypeInfo[chatType]
		local chanTarget = editbox:GetAttribute("channelTarget")
		local chanName = chanTarget and GetChannelName(chanTarget)

		--Increase inset on right side to make room for character count text
		local insetLeft, insetRight, insetTop, insetBottom = editbox:GetTextInsets()
		editbox:SetTextInsets(insetLeft, insetRight + 30, insetTop, insetBottom)
		editbox:SetTemplate(nil, true)

		if chanName and (chatType == "CHANNEL") then
			if chanName == 0 then
				editbox:SetBackdropBorderColor(unpack(E.media.bordercolor))
			else
				info = ChatTypeInfo[chatType..chanName]
				editbox:SetBackdropBorderColor(info.r, info.g, info.b)
			end
		else
			editbox:SetBackdropBorderColor(info.r, info.g, info.b)
		end
	end)

	GeneralDockManagerOverflowButton:Size(17)
	GeneralDockManagerOverflowButtonList:SetTemplate("Transparent")
	hooksecurefunc(GeneralDockManagerScrollFrame, "SetPoint", function(self, point, anchor, attachTo, x, y)
		if anchor == GeneralDockManagerOverflowButton and x == 0 and y == 0 then
			self:Point(point, anchor, attachTo, -2, -4)
		end
	end)

	CombatLogQuickButtonFrame_Custom:StripTextures()
	CombatLogQuickButtonFrame_Custom:CreateBackdrop("Default", true)
	CombatLogQuickButtonFrame_Custom.backdrop:Point("TOPLEFT", 0, -1)
	CombatLogQuickButtonFrame_Custom.backdrop:Point("BOTTOMRIGHT", -22, -1)

	CombatLogQuickButtonFrame_CustomProgressBar:StripTextures()
	CombatLogQuickButtonFrame_CustomProgressBar:SetStatusBarTexture(E.media.normTex)
	CombatLogQuickButtonFrame_CustomProgressBar:SetStatusBarColor(0.31, 0.31, 0.31)
	CombatLogQuickButtonFrame_CustomProgressBar:ClearAllPoints()
	CombatLogQuickButtonFrame_CustomProgressBar:SetInside(CombatLogQuickButtonFrame_Custom.backdrop)

	Skins:HandleNextPrevButton(CombatLogQuickButtonFrame_CustomAdditionalFilterButton)
	CombatLogQuickButtonFrame_CustomAdditionalFilterButton:Size(22)
	CombatLogQuickButtonFrame_CustomAdditionalFilterButton:Point("TOPRIGHT", 3, -1)
	CombatLogQuickButtonFrame_CustomAdditionalFilterButton:SetHitRectInsets(0 , 0, 0, 0)
end

local function InitializeCallback()
	CH:Initialize()
end

E:RegisterModule(CH:GetName(), InitializeCallback)