local _, RRT = ...
local DF = _G["DetailsFramework"]

RRT.BuffReminders = RRT.BuffReminders or {}
RRT.UI = RRT.UI or {}
RRT.UI.BuffReminders = RRT.UI.BuffReminders or {}

local Core = RRT.UI.Core
local options_button_template = Core.options_button_template

local function ApplyRRTFont(fontString, size)
    if not fontString then
        return
    end
    local fontName = (RRTDB and RRTDB.Settings and RRTDB.Settings.GlobalFont) or "Friz Quadrata TT"
    local fetched = RRT.LSM and RRT.LSM.Fetch and RRT.LSM:Fetch("font", fontName)
    if fetched then
        fontString:SetFont(fetched, size or 10, "OUTLINE")
    end
end

local function MakeEditor(parent, name)
    local editor = DF:NewSpecialLuaEditorEntry(parent, 280, 80, _, name, true, false, true)
    DF:ApplyStandardBackdrop(editor)
    if editor.scroll then
        DF:ReskinSlider(editor.scroll)
    end
    editor:SetScript("OnMouseDown", function(self)
        self:SetFocus()
    end)
    return editor
end

local function BuildImportExportTab(parent)
    if parent.ImportExportView then
        parent.ImportExportView:Show()
        if parent.ImportExportView.Refresh then
            parent.ImportExportView:Refresh()
        end
        return parent.ImportExportView
    end

    local container = CreateFrame("Frame", nil, parent)
    container:SetAllPoints()

    local margin = 14
    local spacing = 12

    local titleExport = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyRRTFont(titleExport, 11)
    titleExport:SetPoint("TOPLEFT", container, "TOPLEFT", margin, -12)
    titleExport:SetText("|cffffcc00Export Settings|r")

    local exportDesc = container:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ApplyRRTFont(exportDesc, 10)
    exportDesc:SetPoint("TOPLEFT", titleExport, "BOTTOMLEFT", 0, -spacing)
    exportDesc:SetPoint("RIGHT", container, "RIGHT", -margin, 0)
    exportDesc:SetJustifyH("LEFT")
    exportDesc:SetText("Copy the string below to share your BuffReminders settings.")

    local exportEditor = MakeEditor(container, "RRT_BuffReminders_ExportEdit")
    exportEditor:SetPoint("TOPLEFT", exportDesc, "BOTTOMLEFT", 0, -spacing)
    exportEditor:SetPoint("TOPRIGHT", container, "TOPRIGHT", -margin, -84)
    exportEditor:SetHeight(100)

    local exportButton = DF:CreateButton(container, function()
        if not (BuffReminders and BuffReminders.Export) then
            exportEditor:SetText("Error: BuffReminders export API unavailable")
            return
        end

        local exportString, err = BuffReminders:Export()
        if exportString then
            exportEditor:SetText(exportString)
            exportEditor:HighlightText()
            exportEditor:SetFocus()
        else
            exportEditor:SetText("Error: " .. (err or "Failed to export"))
        end
    end, 110, 22, "Export")
    exportButton:SetTemplate(options_button_template)
    exportButton:SetPoint("TOPLEFT", exportEditor, "BOTTOMLEFT", 0, -spacing)
    local exportButtonFrame = exportButton.widget or exportButton

    local titleImport = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyRRTFont(titleImport, 11)
    titleImport:SetPoint("TOPLEFT", exportButtonFrame, "BOTTOMLEFT", 0, -(spacing + 6))
    titleImport:SetText("|cffffcc00Import Settings|r")

    local importDesc = container:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ApplyRRTFont(importDesc, 10)
    importDesc:SetPoint("TOPLEFT", titleImport, "BOTTOMLEFT", 0, -spacing)
    importDesc:SetPoint("RIGHT", container, "RIGHT", -margin, 0)
    importDesc:SetJustifyH("LEFT")
    importDesc:SetText("Paste a BuffReminders export string. This overwrites current BuffReminders settings.")

    local importEditor = MakeEditor(container, "RRT_BuffReminders_ImportEdit")
    importEditor:SetPoint("TOPLEFT", importDesc, "BOTTOMLEFT", 0, -spacing)
    importEditor:SetPoint("TOPRIGHT", container, "TOPRIGHT", -margin, -274)
    importEditor:SetHeight(100)

    local importStatus = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ApplyRRTFont(importStatus, 10)
    importStatus:SetPoint("LEFT", importEditor, "BOTTOMLEFT", 0, -18)
    importStatus:SetPoint("RIGHT", container, "RIGHT", -margin, 0)
    importStatus:SetJustifyH("LEFT")
    importStatus:SetText("")

    local importButton = DF:CreateButton(container, function()
        if not (BuffReminders and BuffReminders.Import) then
            importStatus:SetText("|cffff0000Error: BuffReminders import API unavailable.|r")
            return
        end

        local importString = importEditor:GetText()
        local success, err = BuffReminders:Import(importString)
        if not success then
            importStatus:SetText("|cffff0000Error: " .. (err or "Unknown error") .. "|r")
            return
        end

        importStatus:SetText("|cff00ff00Settings imported successfully.|r")
        local display = RRT.BuffReminders and RRT.BuffReminders.Display
        if display and display.Update then
            display.Update()
        end
        if display and display.UpdateVisuals then
            display.UpdateVisuals()
        end
    end, 110, 22, "Import")
    importButton:SetTemplate(options_button_template)
    importButton:SetPoint("TOPLEFT", importStatus, "BOTTOMLEFT", 0, -spacing)

    local function Refresh()
        if exportEditor.editbox and exportEditor.editbox.SetFont then
            ApplyRRTFont(exportEditor.editbox, 12)
        end
        if importEditor.editbox and importEditor.editbox.SetFont then
            ApplyRRTFont(importEditor.editbox, 12)
        end
    end

    container.Refresh = Refresh
    container:Refresh()
    parent.ImportExportView = container
    return container
end

RRT.UI.BuffReminders.ImportExport = {
    Build = BuildImportExportTab,
}
