local ADDON_NAME, PvPIdiot = ...

local function Section(parent, titleText)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.035, 0.045, 0.065, 0.94)
    frame:SetBackdropBorderColor(0.16, 0.18, 0.22, 1)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 10, -9)
    title:SetText(titleText)
    title:SetTextColor(0.95, 0.71, 0.25)
    frame.title = title
    return frame
end

function PvPIdiot:CreateOverviewPage(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()

    local build = Section(page, self:L("BUILD_TOP3"))
    build:SetPoint("TOPLEFT", 8, -8)
    build:SetPoint("TOPRIGHT", page, "TOP", -4, -8)
    build:SetHeight(178)

    local pvp = Section(page, self:L("PVP_TALENTS"))
    pvp:SetPoint("TOPLEFT", page, "TOP", 4, -8)
    pvp:SetPoint("TOPRIGHT", -8, -8)
    pvp:SetHeight(178)

    local gear = Section(page, self:L("GEAR_TOP3"))
    gear:SetPoint("TOPLEFT", build, "BOTTOMLEFT", 0, -8)
    gear:SetPoint("TOPRIGHT", build, "BOTTOMRIGHT", 0, -8)
    gear:SetHeight(188)

    local stats = Section(page, self:L("STATS"))
    stats:SetPoint("TOPLEFT", pvp, "BOTTOMLEFT", 0, -8)
    stats:SetPoint("TOPRIGHT", pvp, "BOTTOMRIGHT", 0, -8)
    stats:SetHeight(158)

    local gems = Section(page, self:L("GEMS_TOP3"))
    gems:SetPoint("TOPLEFT", gear, "BOTTOMLEFT", 0, -8)
    gems:SetPoint("BOTTOMRIGHT", page, "BOTTOM", -4, 8)

    local enchants = Section(page, self:L("ENCHANTS_TOP3"))
    enchants:SetPoint("TOPLEFT", stats, "BOTTOMLEFT", 0, -8)
    enchants:SetPoint("BOTTOMRIGHT", -8, 8)

    page.sections = { build = build, pvp = pvp, gear = gear, stats = stats, gems = gems, enchants = enchants }

    build.cards = {}
    for i = 1, 3 do
        local card = self:CreateBuildCard(build, 120, 128)
        card:SetPoint("TOPLEFT", 10 + (i - 1) * 126, -38)
        build.cards[i] = card
    end

    pvp.rows = {}
    for i = 1, 3 do
        local row = self:CreateTalentButton(pvp, 310, 38)
        row:SetPoint("TOPLEFT", 10, -34 - (i - 1) * 43)
        row:SetPoint("RIGHT", -10, 0)
        row.kind = "pvp"
        pvp.rows[i] = row
    end

    gear.rows = {}
    for i = 1, 3 do
        local row = self:CreateItemButton(gear, 350, 34)
        row:SetPoint("TOPLEFT", 10, -34 - (i - 1) * 38)
        row:SetPoint("RIGHT", -10, 0)
        gear.rows[i] = row
    end
    local gearMore = CreateFrame("Button", nil, gear, "UIPanelButtonTemplate")
    gearMore:SetSize(90, 22)
    gearMore:SetPoint("BOTTOMRIGHT", -8, 7)
    gearMore:SetText(self:L("VIEW_MORE"))
    gearMore:SetScript("OnClick", function() self:ShowTab("gear") end)

    stats.rows = {}
    local statDefs = {
        { "versatility", self:L("VERSATILITY") },
        { "haste", self:L("HASTE") },
        { "mastery", self:L("MASTERY") },
        { "crit", self:L("CRIT") },
    }
    for i, def in ipairs(statDefs) do
        local label = stats:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("TOPLEFT", 10, -35 - (i - 1) * 28)
        label:SetText(def[2])
        local bar = self:CreateProgressBar(stats, 190, 13)
        bar:SetPoint("TOPLEFT", 105, -33 - (i - 1) * 28)
        bar:SetPoint("RIGHT", -10, 0)
        stats.rows[i] = { key = def[1], bar = bar, label = label }
    end
    local statUnavailable = stats:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statUnavailable:SetPoint("CENTER", 0, -5)
    statUnavailable:SetWidth(300)
    statUnavailable:SetJustifyH("CENTER")
    statUnavailable:SetText(self:L("STATS_UNAVAILABLE"))
    statUnavailable:SetTextColor(0.62, 0.65, 0.70)
    statUnavailable:Hide()
    stats.unavailable = statUnavailable

    gems.rows = {}
    for i = 1, 3 do
        local row = self:CreateItemButton(gems, 350, 34)
        row:SetPoint("TOPLEFT", 10, -34 - (i - 1) * 38)
        row:SetPoint("RIGHT", -10, 0)
        gems.rows[i] = row
    end

    enchants.rows = {}
    for i = 1, 3 do
        local row = self:CreateItemButton(enchants, 350, 34)
        row:SetPoint("TOPLEFT", 10, -34 - (i - 1) * 38)
        row:SetPoint("RIGHT", -10, 0)
        enchants.rows[i] = row
    end

    function page:Refresh()
        local data = PvPIdiot.DB:GetCurrentSpecData()
        if not data then
            for _, section in pairs(self.sections) do section:Hide() end
            return
        end
        for _, section in pairs(self.sections) do section:Show() end

        local topGear = PvPIdiot.DB:GetTopGear(3)
        for i = 1, 3 do
            local buildData = data.builds and data.builds[i]
            self.sections.build.cards[i]:SetShown(buildData ~= nil)
            if buildData then self.sections.build.cards[i]:SetBuild(buildData, i) end

            local talent = data.pvpTalents and data.pvpTalents[i]
            self.sections.pvp.rows[i]:SetShown(talent ~= nil)
            if talent then self.sections.pvp.rows[i]:SetTalent(talent, "pvp") end

            local gearInfo = topGear[i]
            self.sections.gear.rows[i]:SetShown(gearInfo ~= nil)
            if gearInfo then self.sections.gear.rows[i]:SetItem(gearInfo.itemID, gearInfo.usage, gearInfo.slot) end

            local gem = data.gems and data.gems[i]
            self.sections.gems.rows[i]:SetShown(gem ~= nil)
            if gem then self.sections.gems.rows[i]:SetItem(gem.itemID, gem.usage) end
        end

        local statData = PvPIdiot.DB:GetCurrentStats()
        local hasStats = next(statData) ~= nil
        self.sections.stats.unavailable:SetShown(not hasStats)
        for _, row in ipairs(self.sections.stats.rows) do
            row.label:SetShown(hasStats)
            row.bar:SetShown(hasStats)
            if hasStats then row.bar:SetPercent(statData[row.key] or 0) end
        end

        local flattened = {}
        for slot, list in pairs(data.enchants or {}) do
            for _, entry in ipairs(list) do
                table.insert(flattened, { slot = slot, entry = entry })
            end
        end
        table.sort(flattened, function(a, b) return (a.entry.usage or 0) > (b.entry.usage or 0) end)
        for i = 1, 3 do
            local info = flattened[i]
            self.sections.enchants.rows[i]:SetShown(info ~= nil)
            if info and info.entry.source then
                if info.entry.source.type == "item" then
                    self.sections.enchants.rows[i]:SetItem(info.entry.source.id, info.entry.usage, info.slot)
                else
                    self.sections.enchants.rows[i]:SetSpell(
                        info.entry.source.id or info.entry.enchantID,
                        info.entry.usage,
                        info.slot,
                        self:L("ENCHANT") .. " #" .. tostring(info.entry.enchantID or "-")
                    )
                end
            end
        end
    end

    return page
end
