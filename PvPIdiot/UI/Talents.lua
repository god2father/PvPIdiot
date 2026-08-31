local ADDON_NAME, PvPIdiot = ...

local TALENT_TABS = {
    { id = "class", label = "CLASS_TALENTS" },
    { id = "spec", label = "SPEC_TALENTS" },
    { id = "hero", label = "HERO_TALENTS" },
    { id = "pvp", label = "PVP" },
}

local function SetTabStyle(button, selected)
    if selected then
        button:SetBackdropColor(0.10, 0.085, 0.055, 1)
        button:SetBackdropBorderColor(0.76, 0.51, 0.16, 1)
        button.text:SetTextColor(0.95, 0.71, 0.25)
    else
        button:SetBackdropColor(0.05, 0.06, 0.08, 1)
        button:SetBackdropBorderColor(0.20, 0.22, 0.25, 1)
        button.text:SetTextColor(0.70, 0.72, 0.76)
    end
end

function PvPIdiot:CreateTalentsPage(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()
    page.selectedTalentTab = (self.config and self.config.selectedTalentKind) or "class"
    page.selectedBuildIndex = (self.config and self.config.selectedBuildIndex) or 1
    page.buttons = {}
    page.buildButtons = {}

    local title = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 18, -16)
    title:SetText(self:L("TALENTS"))
    title:SetTextColor(0.95, 0.71, 0.25)

    local buildLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    buildLabel:SetPoint("TOPLEFT", 18, -44)
    buildLabel:SetText(self:L("BUILD_TOP3"))
    buildLabel:SetTextColor(0.95, 0.71, 0.25)

    local previousBuild
    for i = 1, 3 do
        local button = CreateFrame("Button", nil, page, "BackdropTemplate")
        button:SetSize(154, 30)
        if previousBuild then
            button:SetPoint("LEFT", previousBuild, "RIGHT", 6, 0)
        else
            button:SetPoint("TOPLEFT", 18, -62)
        end
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })

        local text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("CENTER")
        button.text = text
        button.buildIndex = i

        button:SetScript("OnClick", function(self)
            page.selectedBuildIndex = self.buildIndex
            if PvPIdiot.config then PvPIdiot.config.selectedBuildIndex = self.buildIndex end
            page:Refresh()
        end)
        button:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(0.95, 0.71, 0.25, 1)
        end)
        button:SetScript("OnLeave", function(self)
            local selected = page.selectedBuildIndex == self.buildIndex
            self:SetBackdropBorderColor(
                selected and 0.76 or 0.28,
                selected and 0.51 or 0.30,
                selected and 0.16 or 0.33,
                1
            )
        end)

        page.buildButtons[i] = button
        previousBuild = button
    end

    local importButton = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    importButton:SetSize(100, 30)
    importButton:SetPoint("LEFT", previousBuild, "RIGHT", 10, 0)
    importButton:SetText(self:L("IMPORT"))
    importButton:SetScript("OnClick", function()
        local data = PvPIdiot.DB:GetCurrentSpecData()
        local build = data and data.builds and data.builds[page.selectedBuildIndex]
        if build then PvPIdiot:ImportBuild(build) end
    end)
    page.importButton = importButton

    local previous
    for _, def in ipairs(TALENT_TABS) do
        local button = CreateFrame("Button", nil, page, "BackdropTemplate")
        button:SetSize(108, 28)
        if previous then
            button:SetPoint("LEFT", previous, "RIGHT", 6, 0)
        else
            button:SetPoint("TOPLEFT", 18, -106)
        end
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })

        local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("CENTER")
        text:SetText(self:L(def.label))
        button.text = text
        button.kind = def.id

        button:SetScript("OnClick", function(self)
            page.selectedTalentTab = self.kind
            if PvPIdiot.config then PvPIdiot.config.selectedTalentKind = self.kind end
            page:Refresh()
        end)

        page.buttons[def.id] = button
        previous = button
    end

    local header = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", 18, -145)
    header:SetTextColor(0.95, 0.71, 0.25)
    page.treeHeader = header

    local hint = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", 18, -166)
    hint:SetText(self:L("TALENT_TREE_HINT"))
    hint:SetTextColor(0.55, 0.58, 0.64)

    local treeView = self:CreateTalentTreeView(page)
    treeView:SetPoint("TOPLEFT", 18, -190)
    treeView:SetPoint("BOTTOMRIGHT", -18, 18)
    page.treeView = treeView

    local pvpPanel = CreateFrame("Frame", nil, page, "BackdropTemplate")
    pvpPanel:SetPoint("TOPLEFT", 18, -190)
    pvpPanel:SetPoint("BOTTOMRIGHT", -18, 18)
    pvpPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    pvpPanel:SetBackdropColor(0.018, 0.024, 0.035, 0.98)
    pvpPanel:SetBackdropBorderColor(0.15, 0.17, 0.21, 1)
    pvpPanel:Hide()
    page.pvpPanel = pvpPanel

    local pvpTitle = pvpPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pvpTitle:SetPoint("TOPLEFT", 14, -14)
    pvpTitle:SetText(self:L("PVP_TALENTS"))
    pvpTitle:SetTextColor(0.95, 0.71, 0.25)

    local pvpHint = pvpPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    pvpHint:SetPoint("TOPLEFT", 14, -36)
    pvpHint:SetText(self:L("PVP_TALENT_HINT"))
    pvpHint:SetTextColor(0.55, 0.58, 0.64)

    page.pvpRows = {}
    for i = 1, 8 do
        local row = self:CreateTalentButton(pvpPanel, 620, 44)
        row:SetPoint("TOPLEFT", 14, -60 - (i - 1) * 49)
        row:SetPoint("RIGHT", -14, 0)
        page.pvpRows[i] = row
    end

    function page:RefreshBuildButtons(data)
        local available = data and data.builds or {}
        if self.selectedBuildIndex > #available and #available > 0 then
            self.selectedBuildIndex = 1
            if PvPIdiot.config then PvPIdiot.config.selectedBuildIndex = 1 end
        end

        for i, button in ipairs(self.buildButtons) do
            local build = available[i]
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

            local selected = self.selectedBuildIndex == i
            button:SetBackdropColor(
                selected and 0.10 or 0.055,
                selected and 0.085 or 0.07,
                selected and 0.055 or 0.095,
                0.96
            )
            button:SetBackdropBorderColor(
                selected and 0.76 or 0.28,
                selected and 0.51 or 0.30,
                selected and 0.16 or 0.33,
                1
            )
            button.text:SetTextColor(
                selected and 0.95 or 0.76,
                selected and 0.71 or 0.78,
                selected and 0.25 or 0.82
            )
        end

        self.importButton:SetEnabled(available[self.selectedBuildIndex] ~= nil)
    end

    function page:RefreshPvP(data)
        local build = data and data.builds and data.builds[self.selectedBuildIndex]
        local selected = {}
        for _, talent in ipairs(build and build.pvpTalents or {}) do
            if talent and talent.id then selected[tonumber(talent.id) or talent.id] = true end
        end

        local list = {}
        for _, talent in ipairs(data and data.pvpTalents or {}) do
            if selected[tonumber(talent.id) or talent.id] then
                table.insert(list, talent)
            end
        end

        -- If the snapshot does not include per-build PvP talent details, show
        -- the aggregate recommendations rather than leaving the panel empty.
        if #list == 0 then list = data and data.pvpTalents or {} end

        for i, row in ipairs(self.pvpRows) do
            local talent = list[i]
            row:SetShown(talent ~= nil)
            if talent then row:SetTalent(talent, "pvp") end
        end
    end

    function page:Refresh()
        local data = PvPIdiot.DB:GetCurrentSpecData()
        self:RefreshBuildButtons(data)

        for id, button in pairs(self.buttons) do
            SetTabStyle(button, id == self.selectedTalentTab)
        end

        local labelKey = self.selectedTalentTab == "class" and "CLASS_TALENTS"
            or self.selectedTalentTab == "spec" and "SPEC_TALENTS"
            or self.selectedTalentTab == "hero" and "HERO_TALENTS"
            or "PVP"

        self.treeHeader:SetText(string.format(
            PvPIdiot:L("TALENT_TREE_TITLE"),
            PvPIdiot:L(labelKey),
            self.selectedBuildIndex
        ))

        if self.selectedTalentTab == "pvp" then
            self.treeView:Hide()
            self.pvpPanel:Show()
            self:RefreshPvP(data)
        else
            self.pvpPanel:Hide()
            self.treeView:Show()
            self.treeView.kind = self.selectedTalentTab
            self.treeView.buildIndex = self.selectedBuildIndex
            self.treeView:Refresh(self.selectedTalentTab, self.selectedBuildIndex)
        end
    end

    return page
end

function PvPIdiot:OpenTalentRecommendations(kind)
    if not self.ui or not self.ui.pages or not self.ui.pages.talents then return end
    local page = self.ui.pages.talents
    page.selectedTalentTab = (page.buttons and page.buttons[kind]) and kind or "class"
    if self.config then self.config.selectedTalentKind = page.selectedTalentTab end
    self:ShowTab("talents")
end

function PvPIdiot:OpenTalentBuild(index, kind)
    if not self.ui or not self.ui.pages or not self.ui.pages.talents then return end
    local page = self.ui.pages.talents
    page.selectedBuildIndex = tonumber(index) or 1
    if kind and page.buttons and page.buttons[kind] then
        page.selectedTalentTab = kind
    end
    if self.config then
        self.config.selectedBuildIndex = page.selectedBuildIndex
        self.config.selectedTalentKind = page.selectedTalentTab
    end
    self:ShowTab("talents")
end
