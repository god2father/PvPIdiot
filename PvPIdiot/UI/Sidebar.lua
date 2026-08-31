local ADDON_NAME, PvPIdiot = ...

local CLASS_FILE_BY_SLUG = {
    ["death-knight"] = "DEATHKNIGHT",
    ["demon-hunter"] = "DEMONHUNTER",
    druid = "DRUID",
    evoker = "EVOKER",
    hunter = "HUNTER",
    mage = "MAGE",
    monk = "MONK",
    paladin = "PALADIN",
    priest = "PRIEST",
    rogue = "ROGUE",
    shaman = "SHAMAN",
    warlock = "WARLOCK",
    warrior = "WARRIOR",
}

local function LocalizedClassName(meta)
    if not meta then return "-" end
    local classFile = CLASS_FILE_BY_SLUG[meta.classSlug]
    if classFile and LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classFile] then
        return LOCALIZED_CLASS_NAMES_MALE[classFile]
    end
    return meta.className or meta.classSlug or "-"
end

local function LocalizedSpecName(specID, fallback)
    if GetSpecializationInfoByID then
        local _, name = GetSpecializationInfoByID(specID)
        if name and name ~= "" then return name end
    end
    return fallback or tostring(specID)
end

local function BuildSelectionData(db)
    local index = db:GetSpecIndex() or {}
    local classesBySlug = {}

    for specID, meta in pairs(index) do
        if meta and meta.classSlug then
            local class = classesBySlug[meta.classSlug]
            if not class then
                class = {
                    slug = meta.classSlug,
                    name = LocalizedClassName(meta),
                    specs = {},
                }
                classesBySlug[meta.classSlug] = class
            end
            table.insert(class.specs, {
                specID = tonumber(specID) or specID,
                classSlug = meta.classSlug,
                text = LocalizedSpecName(tonumber(specID) or specID, meta.specName),
            })
        end
    end

    local classes = {}
    for _, class in pairs(classesBySlug) do
        table.sort(class.specs, function(a, b) return a.text < b.text end)
        table.insert(classes, class)
    end
    table.sort(classes, function(a, b) return a.name < b.name end)
    return classes, classesBySlug
end

function PvPIdiot:CreateSidebar(parent)
    local currentMeta = self.DB:GetCurrentSpecMeta()
    local y = -14
    local gap = 54
    local fields = {
        { key = "mode", label = self:L("MODE"), value = self:L("SOLO_SHUFFLE") },
        { key = "class", label = self:L("CLASS"), value = LocalizedClassName(currentMeta) },
        { key = "spec", label = self:L("SPECIALIZATION"), value = LocalizedSpecName((self.config and self.config.selectedSpecID) or 71, currentMeta and currentMeta.specName) },
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

    -- Mode/season/region/range are fixed for this one-time snapshot. Only the
    -- class and specialization selectors are interactive in the current build.
    self.ui.sidebarFields.mode:SetEnabled(false)
    self.ui.sidebarFields.season:SetEnabled(false)
    self.ui.sidebarFields.region:SetEnabled(false)
    self.ui.sidebarFields.top:SetEnabled(false)

    self:RefreshSidebar()
end

function PvPIdiot:ConfigureSpecSelectors()
    if not self.ui.sidebarFields then return end
    local classField = self.ui.sidebarFields.class
    local specField = self.ui.sidebarFields.spec
    if not classField or not specField then return end

    local classes, classesBySlug = BuildSelectionData(self.DB)
    local currentMeta = self.DB:GetCurrentSpecMeta()
    local currentClassSlug = currentMeta and currentMeta.classSlug

    local classOptions = {}
    for _, class in ipairs(classes) do
        table.insert(classOptions, {
            value = class.slug,
            text = class.name,
        })
    end

    classField:SetOptions(classOptions, function(option)
        local class = classesBySlug[option.value]
        local firstSpec = class and class.specs and class.specs[1]
        if firstSpec and self.config then
            self.config.selectedSpecID = firstSpec.specID
            self:RefreshUI()
        end
    end)

    local currentClass = currentClassSlug and classesBySlug[currentClassSlug]
    local specOptions = {}
    if currentClass then
        for _, spec in ipairs(currentClass.specs) do
            table.insert(specOptions, {
                value = spec.specID,
                text = spec.text,
            })
        end
    end

    specField:SetOptions(specOptions, function(option)
        if self.config then
            self.config.selectedSpecID = option.value
            self:RefreshUI()
        end
    end)
end

function PvPIdiot:RefreshSidebar()
    local data = self.DB:GetCurrentSpecData()
    local meta = data and data.meta
    local specMeta = self.DB:GetCurrentSpecMeta()
    if not self.ui.sampleValues then return end

    local available = not meta or meta.dataAvailable ~= false
    self.ui.sampleValues.players:SetText(available and meta and meta.sampleSize or "-")
    self.ui.sampleValues.highest:SetText(available and meta and meta.maxRating or "-")
    self.ui.sampleValues.lowest:SetText(available and meta and meta.minRating or "-")
    self.ui.sampleValues.average:SetText(available and meta and meta.avgRating or "-")

    if self.ui.sidebarFields then
        if self.ui.sidebarFields.class then
            self.ui.sidebarFields.class:SetValue(LocalizedClassName(specMeta))
        end
        if self.ui.sidebarFields.spec then
            self.ui.sidebarFields.spec:SetValue(LocalizedSpecName(
                (self.config and self.config.selectedSpecID) or 71,
                specMeta and specMeta.specName
            ))
        end
        if self.ui.sidebarFields.top then
            self.ui.sidebarFields.top:SetValue("Top " .. tostring((self.config and self.config.topRange) or 50))
        end
    end

    self:ConfigureSpecSelectors()
end
