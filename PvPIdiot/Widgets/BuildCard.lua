local ADDON_NAME, PvPIdiot = ...

function PvPIdiot:CreateBuildCard(parent, width, height)
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetSize(width or 200, height or 125)
    card:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    card:SetBackdropColor(0.055, 0.07, 0.095, 0.96)
    card:SetBackdropBorderColor(0.28, 0.30, 0.33, 1)
    card:RegisterForClicks("LeftButtonUp")

    local rank = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    rank:SetPoint("TOPLEFT", 10, -10)
    rank:SetTextColor(0.95, 0.71, 0.25)
    card.rank = rank

    local usage = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    usage:SetPoint("TOPRIGHT", -10, -10)
    card.usage = usage

    local count = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    count:SetPoint("TOPLEFT", rank, "BOTTOMLEFT", 0, -14)
    count:SetTextColor(0.70, 0.72, 0.76)
    card.count = count

    local hero = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hero:SetPoint("TOPLEFT", count, "BOTTOMLEFT", 0, -9)
    hero:SetTextColor(0.58, 0.62, 0.70)
    card.hero = hero

    local preview = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    preview:SetPoint("BOTTOMLEFT", 10, 11)
    preview:SetText(PvPIdiot:L("VIEW_TALENTS"))
    preview:SetTextColor(0.58, 0.62, 0.70)
    card.preview = preview

    local import = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
    import:SetSize(72, 24)
    import:SetPoint("BOTTOMRIGHT", -8, 8)
    import:SetText(PvPIdiot:L("IMPORT"))
    card.import = import

    function card:SetBuild(build, index)
        self.build = build
        self.rank:SetText("#" .. tostring(index or 1))
        self.usage:SetText(PvPIdiot.Utils:FormatPercent(build and build.usage or 0, 1))
        self.count:SetText(PvPIdiot:L("COUNT") .. ": " .. tostring(build and build.count or 0))
        self.hero:SetText(PvPIdiot:L("HERO_ID") .. ": " .. tostring(build and build.heroTalentID or "-"))
        self.import:SetScript("OnClick", function()
            PvPIdiot:ImportBuild(build)
        end)
        self:SetScript("OnClick", function()
            PvPIdiot:ImportBuild(build)
        end)
        self:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(0.76, 0.51, 0.16, 1)
        end)
        self:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(0.28, 0.30, 0.33, 1)
        end)
    end

    return card
end
