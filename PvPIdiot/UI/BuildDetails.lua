local ADDON_NAME, PvPIdiot = ...

local GROUPS = {
    { key = "class", label = "CLASS_TALENTS" },
    { key = "spec", label = "SPEC_TALENTS" },
    { key = "hero", label = "HERO_TALENTS" },
    { key = "pvp", label = "PVP" },
}

function PvPIdiot:CreateBuildDetails(parent)
    local modal = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    modal:SetAllPoints()
    modal:SetFrameStrata("DIALOG")
    modal:SetFrameLevel((parent:GetFrameLevel() or 0) + 30)
    modal:EnableMouse(true)
    if modal.SetToplevel then modal:SetToplevel(true) end
    modal:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    modal:SetBackdropColor(0.015, 0.02, 0.035, 0.98)
    modal:SetBackdropBorderColor(0.76, 0.51, 0.16, 1)
    modal:Hide()

    local close = CreateFrame("Button", nil, modal, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)
    close:SetScript("OnClick", function() modal:Hide() end)

    local title = modal:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 18, -18)
    title:SetTextColor(0.95, 0.71, 0.25)
    modal.title = title

    local import = CreateFrame("Button", nil, modal, "UIPanelButtonTemplate")
    import:SetSize(84, 24)
    import:SetPoint("TOPRIGHT", -40, -18)
    import:SetText(PvPIdiot:L("IMPORT"))
    modal.import = import

    local hint = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPRIGHT", import, "TOPLEFT", -12, -4)
    hint:SetText(PvPIdiot:L("TALENT_HOVER_HINT"))
    hint:SetTextColor(0.55, 0.58, 0.64)

    local scroll, content = self:CreateScrollableContainer(modal, 620)
    scroll:ClearAllPoints()
    scroll:SetPoint("TOPLEFT", 12, -54)
    scroll:SetPoint("BOTTOMRIGHT", -12, 12)
    modal.scroll = scroll
    modal.content = content
    modal.rows = {}
    modal.headers = {}

    function modal:ShowBuild(build, index)
        self.build = build
        self.title:SetText(string.format(PvPIdiot:L("BUILD_DETAILS"), index or 1))
        self.import:SetScript("OnClick", function()
            PvPIdiot:ImportBuild(build)
        end)

        local y = -8
        local rowIndex = 1
        local headerIndex = 1
        local hasDetails = false

        for _, group in ipairs(GROUPS) do
            local list = group.key == "pvp" and build.pvpTalents or build.talents and build.talents[group.key]
            if list and #list > 0 then
                hasDetails = true
                local header = self.headers[headerIndex]
                if not header then
                    header = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    header:SetTextColor(0.95, 0.71, 0.25)
                    self.headers[headerIndex] = header
                end
                header:ClearAllPoints()
                header:SetPoint("TOPLEFT", 12, y)
                header:SetText(PvPIdiot:L(group.label))
                header:Show()
                headerIndex = headerIndex + 1
                y = y - 28

                for _, talent in ipairs(list) do
                    local row = self.rows[rowIndex]
                    if not row then
                        row = PvPIdiot:CreateTalentButton(content, 620, 44)
                        self.rows[rowIndex] = row
                    end
                    row:ClearAllPoints()
                    row:SetPoint("TOPLEFT", 12, y)
                    row:SetPoint("TOPRIGHT", content, "TOPRIGHT", -12, y)
                    row:SetTalent(talent, group.key)
                    row:Show()
                    rowIndex = rowIndex + 1
                    y = y - 48
                end
                y = y - 8
            end
        end

        for i = headerIndex, #self.headers do self.headers[i]:Hide() end
        for i = rowIndex, #self.rows do self.rows[i]:Hide() end

        if not hasDetails then
            local header = self.headers[1]
            if not header then
                header = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                self.headers[1] = header
            end
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", 12, -8)
            header:SetText(PvPIdiot:L("BUILD_DETAILS_UNAVAILABLE"))
            header:SetTextColor(0.72, 0.74, 0.78)
            header:Show()
            headerIndex = 2
        end

        self.scroll:SetMinimumHeight(math.max(620, -y + 20))
        self:Show()
        self:Raise()
    end

    return modal
end

function PvPIdiot:OpenBuildDetails(build, index)
    if not build then return end
    local modal = self.ui.buildDetails or self:CreateBuildDetails(self.ui.mainFrame)
    self.ui.buildDetails = modal
    modal:ShowBuild(build, index)
end
