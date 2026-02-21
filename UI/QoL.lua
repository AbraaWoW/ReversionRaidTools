local _, RRT = ...
local DF = _G["DetailsFramework"]

local Core = RRT.UI.Core
local RRTUI = Core.RRTUI

function RRT:UpdateQoLTextDisplay()
    if self.IsQoLTextPreview then
        self:ToggleQoLTextPreview()
        return
    end
    self:CreateQoLTextDisplay()
    local F = self.RRTFrame.QoLText
    F:ClearAllPoints()
    F:SetPoint(RRTDB.QoL.TextDisplay.Anchor, self.RRTFrame, RRTDB.QoL.TextDisplay.relativeTo, RRTDB.QoL.TextDisplay.xOffset, RRTDB.QoL.TextDisplay.yOffset)
    F.text:SetFont(self.LSM:Fetch("font", RRTDB.Settings.GlobalFont), RRTDB.QoL.TextDisplay.FontSize, "OUTLINE")
    local text = ""
    local now = GetTime()
    for _, v in pairs(self.QoLTextDisplays or {}) do -- table structure: {SettingsName = string, text = string}
        if RRTDB.QoL[v.SettingsName] then
            text = text..v.text.."\n"
        end
    end
    F.text:SetText(text)
    F:SetSize(F.text:GetStringWidth(), F.text:GetStringHeight())
end

function RRT:CreateQoLTextDisplay()
    if self.RRTFrame.QoLText then return end
    self.RRTFrame.QoLText = CreateFrame("Frame", nil, self.RRTFrame, "BackdropTemplate")
    self.RRTFrame.QoLText.text = self.RRTFrame.QoLText:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local F = self.RRTFrame.QoLText
    F:SetPoint(RRTDB.QoL.TextDisplay.Anchor, self.RRTFrame, RRTDB.QoL.TextDisplay.relativeTo, RRTDB.QoL.TextDisplay.xOffset, RRTDB.QoL.TextDisplay.yOffset)
    F:SetFrameStrata("DIALOG")
    F.text:SetFont(self.LSM:Fetch("font", RRTDB.Settings.GlobalFont), RRTDB.QoL.TextDisplay.FontSize, "OUTLINE")
    F.text:SetPoint("TOP", F, "TOP", 0, 0)
    F.text:SetTextColor(1, 1, 1, 1)
    F.Border = CreateFrame("Frame", nil, F, "BackdropTemplate")
    F.Border:SetPoint("TOPLEFT", F, "TOPLEFT", -6, 6)
    F.Border:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT", 6, -6)
    F.Border:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            tileSize = 0,
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 2,
        })
    F.Border:SetBackdropBorderColor(1, 1, 1, 1)
    F.Border:SetBackdropColor(0, 0, 0, 0)
    F.Border:Hide()
    F.Border:SetFrameStrata("DIALOG")
    F:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    F:SetScript("OnDragStop", function(Frame)
        self:StopFrameMove(Frame, RRTDB.QoL.TextDisplay)
    end)
end

function RRT:ToggleQoLTextPreview()
    if self.IsQoLTextPreview then
        self:CreateQoLTextDisplay()
        local GatewayIcon = "\124T"..C_Spell.GetSpellTexture(111771)..":12:12:0:0:64:64:4:60:4:60\124t"
        local ResetBossIcon = "\124T"..C_Spell.GetSpellTexture(57724)..":12:12:0:0:64:64:4:60:4:60\124t"
        local CrestIcon = "\124T"..C_CurrencyInfo.GetCurrencyInfo(3347).iconFileID..":12:12:0:0:64:64:4:60:4:60\124t"
        local PrevieWTexts = {
            "This is a preview of the QoL Text Display.",
            RRTDB.QoL.GatewayUseableDisplay and GatewayIcon.."Gateway Useable"..GatewayIcon or "",
            RRTDB.QoL.ResetBossDisplay and ResetBossIcon.."Reset Boss"..ResetBossIcon or "",
            RRTDB.QoL.LootBossReminder and CrestIcon.."Loot Boss"..CrestIcon or "",
            "All enabled Text Displays will show here.",
        }
        local text = ""
        for _, v in ipairs(PrevieWTexts) do -- table structure: {enabled = bool, text = string}
            if v ~= "" then
                text = text..v.."\n"
            end
        end
        local F = self.RRTFrame.QoLText
        F.text:SetText(text)
        F.text:SetFont(self.LSM:Fetch("font", RRTDB.Settings.GlobalFont), RRTDB.QoL.TextDisplay.FontSize, "OUTLINE")
        F:SetSize(F.text:GetStringWidth(), F.text:GetStringHeight())
        self:ToggleMoveFrames(F, true)
    else
        self:ToggleMoveFrames(self.RRTFrame.QoLText)
        self:UpdateQoLTextDisplay()
    end
end




-- Export to namespace
RRT.UI = RRT.UI or {}
RRT.UI.QoL = {
}



