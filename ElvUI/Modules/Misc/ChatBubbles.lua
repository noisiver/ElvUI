local E, L, V, P, G = unpack(ElvUI)
local M = E:GetModule("Misc")
local CH = E:GetModule("Chat")

local format, wipe, pairs = format, wipe, pairs
local strmatch, strlower, gmatch, gsub = strmatch, strlower, gmatch, gsub

local CreateFrame = CreateFrame
local PRIEST_COLOR = RAID_CLASS_COLORS.PRIEST
local WorldGetChildren = WorldFrame.GetChildren
local WorldGetNumChildren = WorldFrame.GetNumChildren

--Message caches
local messageToGUID = {}
local messageToSender = {}

function M:UpdateBubbleBorder()
	local holder = self.holder
	local str = holder and holder.String
	if not str then return end

	local option = E.private.general.chatBubbles
	if option == "backdrop" then
		holder:SetBackdropBorderColor(str:GetTextColor())
	elseif option == "backdrop_noborder" then
		holder:SetBackdropBorderColor(0,0,0,0)
	end

	local name = self.Name and self.Name:GetText()
	if name then self.Name:SetText() end

	local text = str:GetText()
	if not text then return end

	if E.private.general.chatBubbleName then
		M:AddChatBubbleName(self, messageToGUID[text], messageToSender[text])
	end

	if E.private.chat.enable and E.private.general.classColorMentionsSpeech then
		local isFirstWord, rebuiltString
		if text and strmatch(text, "%s-%S+%s*") then
			for word in gmatch(text, "%s-%S+%s*") do
				local tempWord = gsub(word, "^[%s%p]-([^%s%p]+)([%-]?[^%s%p]-)[%s%p]*$", "%1%2")
				local lowerCaseWord = strlower(tempWord)

				local classMatch = CH.ClassNames[lowerCaseWord]
				local wordMatch = classMatch and lowerCaseWord

				if wordMatch and not E.global.chat.classColorMentionExcludedNames[wordMatch] then
					local classColorTable = E:ClassColor(classMatch)
					if classColorTable then
						word = gsub(word, gsub(tempWord, "%-","%%-"), format("|cff%.2x%.2x%.2x%s|r", classColorTable.r*255, classColorTable.g*255, classColorTable.b*255, tempWord))
					end
				end

				if not isFirstWord then
					rebuiltString = word
					isFirstWord = true
				else
					rebuiltString = format("%s%s", rebuiltString, word)
				end
			end

			if rebuiltString then
				str:SetText(gsub(rebuiltString, "     +", "    "))
			end
		end
	end
end

function M:AddChatBubbleName(chatBubble, guid, name)
	if not name then return end

	local color = PRIEST_COLOR
	local data = guid and guid ~= "" and CH:GetPlayerInfoByGUID(guid)
	if data and data.classColor then
		color = data.classColor
	end

	chatBubble.Name:SetFormattedText("|c%s%s|r", color.colorStr, name)
	chatBubble.Name:Width(chatBubble:GetWidth()-10)
end

function M:SkinBubble(frame)
	local mult = E.mult * E.uiscale
	for i = 1, frame:GetNumRegions() do
		local region = select(i, frame:GetRegions())
		if region:IsObjectType("Texture") then
			region:SetTexture(nil)
		elseif region:IsObjectType("FontString") then
			frame.text = region
		end
	end

	local name = frame:CreateFontString(nil, "OVERLAY")
	if E.private.general.chatBubbles == "backdrop" then
		name:SetPoint("TOPLEFT", 5, E.PixelMode and 15 or 18)
	else
		name:SetPoint("TOPLEFT", 5, 6)
	end
	name:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -5, -5)
	name:SetJustifyH("LEFT")
	name:FontTemplate(E.Libs.LSM:Fetch("font", E.private.general.chatBubbleFont), E.private.general.chatBubbleFontSize * 0.85, E.private.general.chatBubbleFontOutline)
	frame.Name = name

	if E.private.general.chatBubbles == "backdrop" then
		if E.PixelMode then
			frame:SetBackdrop({
				bgFile = E.media.blankTex,
				edgeFile = E.media.blankTex,
				tile = false, tileSize = 0, edgeSize = mult,
				insets = {left = 0, right = 0, top = 0, bottom = 0}
			})
			frame:SetBackdropColor(unpack(E.media.backdropfadecolor))
			frame:SetBackdropBorderColor(0, 0, 0)
		else
			frame:SetBackdrop(nil)
		end

		local r, g, b = frame.text:GetTextColor()
		if not E.PixelMode then
			local mult2 = mult * 2
			local mult3 = mult * 3

			frame.backdrop = frame:CreateTexture(nil, "BACKGROUND")
			frame.backdrop:SetAllPoints(frame)
			frame.backdrop:SetTexture(unpack(E.media.backdropfadecolor))

			frame.bordertop = frame:CreateTexture(nil, "ARTWORK")
			frame.bordertop:SetPoint("TOPLEFT", -mult2, mult2)
			frame.bordertop:SetPoint("TOPRIGHT", mult2, mult2)
			frame.bordertop:SetHeight(mult)
			frame.bordertop:SetTexture(r, g, b)

			frame.bordertop.backdrop = frame:CreateTexture(nil, "BORDER")
			frame.bordertop.backdrop:SetPoint("TOPLEFT", frame.bordertop, "TOPLEFT", -mult, mult)
			frame.bordertop.backdrop:SetPoint("TOPRIGHT", frame.bordertop, "TOPRIGHT", mult, mult)
			frame.bordertop.backdrop:SetHeight(mult3)
			frame.bordertop.backdrop:SetTexture(0, 0, 0)

			frame.borderbottom = frame:CreateTexture(nil, "ARTWORK")
			frame.borderbottom:SetPoint("BOTTOMLEFT", -mult2, -mult2)
			frame.borderbottom:SetPoint("BOTTOMRIGHT", mult2, -mult2)
			frame.borderbottom:SetHeight(mult)
			frame.borderbottom:SetTexture(r, g, b)

			frame.borderbottom.backdrop = frame:CreateTexture(nil, "BORDER")
			frame.borderbottom.backdrop:SetPoint("BOTTOMLEFT", frame.borderbottom, "BOTTOMLEFT", -mult, -mult)
			frame.borderbottom.backdrop:SetPoint("BOTTOMRIGHT", frame.borderbottom, "BOTTOMRIGHT", mult, -mult)
			frame.borderbottom.backdrop:SetHeight(mult3)
			frame.borderbottom.backdrop:SetTexture(0, 0, 0)

			frame.borderleft = frame:CreateTexture(nil, "ARTWORK")
			frame.borderleft:SetPoint("TOPLEFT", -mult2, mult2)
			frame.borderleft:SetPoint("BOTTOMLEFT", mult2, -mult2)
			frame.borderleft:SetWidth(mult)
			frame.borderleft:SetTexture(r, g, b)

			frame.borderleft.backdrop = frame:CreateTexture(nil, "BORDER")
			frame.borderleft.backdrop:SetPoint("TOPLEFT", frame.borderleft, "TOPLEFT", -mult, mult)
			frame.borderleft.backdrop:SetPoint("BOTTOMLEFT", frame.borderleft, "BOTTOMLEFT", -mult, -mult)
			frame.borderleft.backdrop:SetWidth(mult3)
			frame.borderleft.backdrop:SetTexture(0, 0, 0)

			frame.borderright = frame:CreateTexture(nil, "ARTWORK")
			frame.borderright:SetPoint("TOPRIGHT", mult2, mult2)
			frame.borderright:SetPoint("BOTTOMRIGHT", -mult2, -mult2)
			frame.borderright:SetWidth(mult)
			frame.borderright:SetTexture(r, g, b)

			frame.borderright.backdrop = frame:CreateTexture(nil, "BORDER")
			frame.borderright.backdrop:SetPoint("TOPRIGHT", frame.borderright, "TOPRIGHT", mult, mult)
			frame.borderright.backdrop:SetPoint("BOTTOMRIGHT", frame.borderright, "BOTTOMRIGHT", mult, -mult)
			frame.borderright.backdrop:SetWidth(mult3)
			frame.borderright.backdrop:SetTexture(0, 0, 0)
		else
			frame:SetBackdropColor(unpack(E.media.backdropfadecolor))
			frame:SetBackdropBorderColor(r, g, b)
		end

		frame.text:FontTemplate(E.LSM:Fetch("font", E.private.general.chatBubbleFont), E.private.general.chatBubbleFontSize, E.private.general.chatBubbleFontOutline)
	elseif E.private.general.chatBubbles == "backdrop_noborder" then
		frame:SetBackdrop(nil)

		if not frame.backdrop then
			frame.backdrop = frame:CreateTexture(nil, "ARTWORK")
			frame.backdrop:SetInside(frame, 4, 4)
			frame.backdrop:SetTexture(unpack(E.media.backdropfadecolor))
		end
		frame.text:FontTemplate(E.LSM:Fetch("font", E.private.general.chatBubbleFont), E.private.general.chatBubbleFontSize, E.private.general.chatBubbleFontOutline)

		frame:SetClampedToScreen(false)
	elseif E.private.general.chatBubbles == "nobackdrop" then
		frame:SetBackdrop(nil)
		frame.text:FontTemplate(E.LSM:Fetch("font", E.private.general.chatBubbleFont), E.private.general.chatBubbleFontSize, E.private.general.chatBubbleFontOutline)
		frame:SetClampedToScreen(false)
	end

	frame:HookScript("OnShow", M.UpdateBubbleBorder)
	frame:SetFrameStrata("BACKGROUND")
	M.UpdateBubbleBorder(frame)

	frame.isSkinnedElvUI = true
end

function M:IsChatBubble(frame)
	for i = 1, frame:GetNumRegions() do
		local region = select(i, frame:GetRegions())
		if region.GetTexture and region:GetTexture() and region:GetTexture() == [[Interface\Tooltips\ChatBubble-Background]] then
			return true
		end
	end
end

local function ChatBubble_OnEvent(_, event, msg, sender, _, _, _, _, _, _, _, _, _, guid)
	if event == "PLAYER_ENTERING_WORLD" then --Clear caches
		wipe(messageToGUID)
		wipe(messageToSender)
	elseif E.private.general.chatBubbleName then
		messageToGUID[msg] = guid
		messageToSender[msg] = sender
	end
end

local lastChildern, numChildren = 0, 0
local function findChatBubbles(...)
	for i = lastChildern + 1, numChildren do
		local frame = select(i, ...)
		if not frame.isSkinnedElvUI and M:IsChatBubble(frame) then
			M:SkinBubble(frame)
		end
	end
end

local function ChatBubble_OnUpdate(eventFrame, elapsed)
	eventFrame.lastupdate = (eventFrame.lastupdate or -2) + elapsed
	if eventFrame.lastupdate < 0.1 then return end
	eventFrame.lastupdate = 0

	numChildren = WorldGetNumChildren(WorldFrame)
	if lastChildern ~= numChildren then
		findChatBubbles(WorldGetChildren(WorldFrame))
		lastChildern = numChildren
	end
end

function M:LoadChatBubbles()
	yOffset = (E.private.general.chatBubbles == "backdrop" and 2) or (E.private.general.chatBubbles == "backdrop_noborder" and -2) or 0

	M.BubbleFrame = CreateFrame("Frame")
	M.BubbleFrame:RegisterEvent("CHAT_MSG_SAY")
	M.BubbleFrame:RegisterEvent("CHAT_MSG_YELL")
	M.BubbleFrame:RegisterEvent("CHAT_MSG_MONSTER_SAY")
	M.BubbleFrame:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	M.BubbleFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

	if E.private.general.chatBubbles ~= "disabled" then
		M.BubbleFrame:SetScript("OnEvent", ChatBubble_OnEvent)
		M.BubbleFrame:SetScript("OnUpdate", ChatBubble_OnUpdate)
	else
		M.BubbleFrame:SetScript("OnEvent", nil)
		M.BubbleFrame:SetScript("OnUpdate", nil)
	end
end
