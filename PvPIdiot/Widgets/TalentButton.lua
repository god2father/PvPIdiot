local ADDON_NAME, PvPIdiot = ...

function PvPIdiot:CreateTalentButton(parent, width, height)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetSize(width or 300, height or 44)
    row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    row:SetBackdropColor(0.055, 0.07, 0.095, 0.8)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetPoint("LEFT", 6, 0)
    icon:SetTexture(134400)
    row.icon = icon

    local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -1)
    name:SetPoint("RIGHT", -62, 0)
    name:SetJustifyH("LEFT")
    row.name = name

    local usage = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    usage:SetPoint("RIGHT", -8, 6)
    usage:SetTextColor(0.95, 0.71, 0.25)
    row.usage = usage

    local bar = PvPIdiot:CreateProgressBar(row, 180, 8)
    bar:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 8, 3)
    bar.text:Hide()
    row.bar = bar

    function row:SetTalent(talent, kind)
        talent = talent or {}
        self.talentID = talent.id
        local talentName, talentIcon
        if kind == "pvp" then
            talentName, talentIcon = PvPIdiot.Utils:GetPvpTalentInfo(talent.id)
        else
            local kindLabels = {
                class = PvPIdiot:L("CLASS_TALENTS"),
                spec = PvPIdiot:L("SPEC_TALENTS"),
                hero = PvPIdiot:L("HERO_TALENTS"),
            }
            talentName, talentIcon = PvPIdiot.Utils:GetTraitTalentInfo(talent.id, kindLabels[kind] or "Talent")
        end
        self.icon:SetTexture(talentIcon or 134400)
        self.name:SetText(talentName)
        if talent.usage == nil then
            self.usage:SetText("")
            self.bar:Hide()
        else
            self.usage:SetText(PvPIdiot.Utils:FormatPercent(talent.usage, 1))
            self.bar:SetPercent(talent.usage)
            self.bar:Show()
        end
    end

    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        if self.kind == "pvp" and self.talentID and GameTooltip.SetPvpTalent then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            pcall(GameTooltip.SetPvpTalent, GameTooltip, self.talentID)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return row
end
