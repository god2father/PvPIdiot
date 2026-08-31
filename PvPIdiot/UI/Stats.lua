local ADDON_NAME, PvPIdiot = ...

function PvPIdiot:CreateStatsPage(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()

    local panel = CreateFrame("Frame", nil, page, "BackdropTemplate")
    panel:SetPoint("TOPLEFT", 16, -16)
    panel:SetPoint("TOPRIGHT", -16, -16)
    panel:SetHeight(300)
    panel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    panel:SetBackdropColor(0.035, 0.045, 0.065, 0.95)
    panel:SetBackdropBorderColor(0.16, 0.18, 0.22, 1)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 18, -18)
    title:SetText(self:L("STATS"))
    title:SetTextColor(0.95, 0.71, 0.25)

    local defs = {
        { key = "versatility", label = self:L("VERSATILITY") },
        { key = "haste", label = self:L("HASTE") },
        { key = "mastery", label = self:L("MASTERY") },
        { key = "crit", label = self:L("CRIT") },
    }
    page.rows = {}
    for i, def in ipairs(defs) do
        local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("TOPLEFT", 20, -65 - (i - 1) * 52)
        label:SetText(def.label)

        local bar = self:CreateProgressBar(panel, 500, 22)
        bar:SetPoint("TOPLEFT", 150, -62 - (i - 1) * 52)
        bar:SetPoint("RIGHT", -24, 0)
        page.rows[i] = { key = def.key, bar = bar, label = label }
    end

    local unavailable = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    unavailable:SetPoint("CENTER", 0, -8)
    unavailable:SetWidth(520)
    unavailable:SetJustifyH("CENTER")
    unavailable:SetText(self:L("STATS_UNAVAILABLE"))
    unavailable:SetTextColor(0.68, 0.70, 0.76)
    unavailable:Hide()
    page.unavailable = unavailable

    local note = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", panel, "BOTTOMLEFT", 4, -12)
    note:SetText(self:L("STATS_NOTE"))
    note:SetTextColor(0.55, 0.58, 0.64)

    function page:Refresh()
        local data = PvPIdiot.DB:GetCurrentSpecData()
        local stats = PvPIdiot.DB:GetCurrentStats()
        local hasStats = next(stats) ~= nil
        self.unavailable:SetShown(not hasStats)
        for _, row in ipairs(self.rows) do
            row.label:SetShown(hasStats)
            row.bar:SetShown(hasStats)
            if hasStats then row.bar:SetPercent(stats[row.key] or 0) end
        end
    end

    return page
end
