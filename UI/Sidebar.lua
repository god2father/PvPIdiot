local ADDON_NAME, PvPIdiot = ...

function PvPIdiot:CreateSidebar(parent)
    local y = -14
    local gap = 54
    local fields = {
        { key = "mode", label = self:L("MODE"), value = self:L("SOLO_SHUFFLE") },
        { key = "class", label = self:L("CLASS"), value = self:L("WARRIOR") },
        { key = "spec", label = self:L("SPECIALIZATION"), value = self:L("ARMS") },
        { key = "season", label = self:L("SEASON"), value = self:L("CURRENT_SEASON") },
        { key = "region", label = self:L("REGION"), value = self:L("GLOBAL") },
        { key = "top", label = self:L("TOP_RANGE"), value = "Top " .. tostring((self.config and self.config.topRange) or 50) },
    }

    self.ui.sidebarFields = {}
    for _, info in ipairs(fields) do
        local field = self:CreateDropdown(parent, info.label, info.value)
        field:SetPoint("TOPLEFT", 14, y)
        self.ui.sidebarFields[info.key] = field
        y = y - gap
    end

    local sample = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    sample:SetPoint("BOTTOMLEFT", 14, 14)
    sample:SetPoint("BOTTOMRIGHT", -14, 14)
    sample:SetHeight(150)
    sample:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    sample:SetBackdropColor(0.045, 0.055, 0.075, 1)
    sample:SetBackdropBorderColor(0.28, 0.23, 0.12, 1)
    self.ui.sampleCard = sample

    local title = sample:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 10, -10)
    title:SetText(self:L("SAMPLE"))
    title:SetTextColor(0.95, 0.71, 0.25)

    local rows = {
        { "players", self:L("PLAYERS") },
        { "highest", self:L("HIGHEST") },
        { "lowest", self:L("LOWEST") },
        { "average", self:L("AVERAGE") },
    }
    self.ui.sampleValues = {}
    for i, row in ipairs(rows) do
        local label = sample:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("TOPLEFT", 10, -35 - (i - 1) * 25)
        label:SetText(row[2])
        label:SetTextColor(0.62, 0.65, 0.70)

        local value = sample:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        value:SetPoint("TOPRIGHT", -10, -35 - (i - 1) * 25)
        self.ui.sampleValues[row[1]] = value
    end

    self:RefreshSidebar()
end

function PvPIdiot:RefreshSidebar()
    local data = self.DB:GetCurrentSpecData()
    local meta = data and data.meta
    if not self.ui.sampleValues then return end

    self.ui.sampleValues.players:SetText(meta and meta.sampleSize or "-")
    self.ui.sampleValues.highest:SetText(meta and meta.maxRating or "-")
    self.ui.sampleValues.lowest:SetText(meta and meta.minRating or "-")
    self.ui.sampleValues.average:SetText(meta and meta.avgRating or "-")

    if self.ui.sidebarFields and self.ui.sidebarFields.top then
        self.ui.sidebarFields.top:SetValue("Top " .. tostring((self.config and self.config.topRange) or 50))
    end
end
