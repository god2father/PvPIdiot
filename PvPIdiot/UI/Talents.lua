local ADDON_NAME, PvPIdiot = ...

local TALENT_TABS = {
    { id = "class", label = "CLASS_TALENTS" },
    { id = "spec", label = "SPEC_TALENTS" },
    { id = "hero", label = "HERO_TALENTS" },
    { id = "pvp", label = "PVP" },
}

function PvPIdiot:CreateTalentsPage(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()
    page.selectedTalentTab = "class"
    page.buttons = {}
    page.rows = {}
    page.buildButtons = {}

    local title = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 18, -18)
    title:SetText(self:L("TALENTS"))
    title:SetTextColor(0.95, 0.71, 0.25)

    local buildLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    buildLabel:SetPoint("TOPLEFT", 18, -50)
    buildLabel:SetText(self:L("BUILD_TOP3"))
    buildLabel:SetTextColor(0.95, 0.71, 0.25)

    local previousBuild
    for i = 1, 3 do
        local button = CreateFrame("Button", nil, page, "BackdropTemplate")
        button:SetSize(150, 30)
        if previousBuild then
            button:SetPoint("LEFT", previousBuild, "RIGHT", 6, 0)
        else
            button:SetPoint("TOPLEFT", 18, -68)
        end
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        button:SetBackdropColor(0.055, 0.07, 0.095, 0.96)
        button:SetBackdropBorderColor(0.28, 0.30, 0.33, 1)

        local text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("CENTER")
        button.text = text
        button.buildIndex = i
        button:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(0.76, 0.51, 0.16, 1)
        end)
        button:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(0.28, 0.30, 0.33, 1)
        end)
        button:SetScript("OnClick", function(self)
            local data = PvPIdiot.DB:GetCurrentSpecData()
            local build = data and data.builds and data.builds[self.buildIndex]
            if build then PvPIdiot:OpenBuildDetails(build, self.buildIndex) end
        end)
        page.buildButtons[i] = button
        previousBuild = button
    end

    local importTop = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    importTop:SetSize(105, 30)
    importTop:SetPoint("LEFT", previousBuild, "RIGHT", 10, 0)
    importTop:SetText(self:L("IMPORT") .. " #1")
    importTop:SetScript("OnClick", function()
        local data = PvPIdiot.DB:GetCurrentSpecData()
        local build = data and data.builds and data.builds[1]
        if build then PvPIdiot:ImportBuild(build) end
    end)
    page.importTop = importTop

    local previous
    for _, def in ipairs(TALENT_TABS) do
        local button = CreateFrame("Button", nil, page, "BackdropTemplate")
        button:SetSize(105, 28)
        if previous then
            button:SetPoint("LEFT", previous, "RIGHT", 6, 0)
        else
            button:SetPoint("TOPLEFT", 18, -112)
        end
        button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("CENTER")
        text:SetText(self:L(def.label))
        button.text = text
        button:SetScript("OnClick", function()
            page.selectedTalentTab = def.id
            page:Refresh()
        end)
        page.buttons[def.id] = button
        previous = button
    end

    local note = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", 18, -150)
    note:SetText(self:L("TALENT_SIMPLE_NOTE"))
    note:SetTextColor(0.55, 0.58, 0.64)

    for i = 1, 10 do
        local row = self:CreateTalentButton(page, 620, 44)
        row:SetPoint("TOPLEFT", 18, -178 - (i - 1) * 48)
        row:SetPoint("RIGHT", -18, 0)
        row:SetAction(function()
            PvPIdiot:OpenTalentPanel()
        end)
        page.rows[i] = row
    end

    function page:Refresh()
        local data = PvPIdiot.DB:GetCurrentSpecData()
        local selected = self.selectedTalentTab
        local list
        if selected == "pvp" then
            list = data and data.pvpTalents or {}
        else
            list = data and data.talents and data.talents[selected] or {}
        end

        for i, button in ipairs(self.buildButtons) do
            local build = data and data.builds and data.builds[i]
            button:SetShown(build ~= nil)
            if build then
                button.text:SetText(string.format(
                    "#%d  %s  %s:%d",
                    i,
                    PvPIdiot.Utils:FormatPercent(build.usage or 0, 1),
                    PvPIdiot:L("COUNT"),
                    tonumber(build.count) or 0
                ))
            end
        end

        local hasTopBuild = data and data.builds and data.builds[1] ~= nil
        self.importTop:SetEnabled(hasTopBuild)

        for id, button in pairs(self.buttons) do
            if id == selected then
                button:SetBackdropColor(0.10, 0.085, 0.055, 1)
                button:SetBackdropBorderColor(0.76, 0.51, 0.16, 1)
                button.text:SetTextColor(0.95, 0.71, 0.25)
            else
                button:SetBackdropColor(0.05, 0.06, 0.08, 1)
                button:SetBackdropBorderColor(0.20, 0.22, 0.25, 1)
                button.text:SetTextColor(0.70, 0.72, 0.76)
            end
        end

        for i, row in ipairs(self.rows) do
            local talent = list and list[i]
            row:SetShown(talent ~= nil)
            if talent then row:SetTalent(talent, selected) end
        end
    end

    return page
end
