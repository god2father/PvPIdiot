local ADDON_NAME, PvPIdiot = ...

function PvPIdiot:CreateTalentButton(parent, width, height)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetSize(width or 300, height or 44)
    row:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    row:SetBackdropColor(0.055, 0.07, 0.095, 0.8)
    row:SetBackdropBorderColor(0.12, 0.14, 0.18, 1)
    row:RegisterForClicks("LeftButtonUp")

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
        self.kind = kind
        self.spellID = nil

        local talentName, talentIcon, spellID
        if kind == "pvp" then
            talentName, talentIcon, spellID = PvPIdiot.Utils:GetPvpTalentInfo(talent.id)
        else
            local kindLabels = {
                class = PvPIdiot:L("CLASS_TALENTS"),
                spec = PvPIdiot:L("SPEC_TALENTS"),
                hero = PvPIdiot:L("HERO_TALENTS"),
            }
            talentName, talentIcon, spellID = PvPIdiot.Utils:GetTraitTalentInfo(talent.id, kindLabels[kind] or "Talent")
        end

        self.spellID = spellID
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

    function row:SetAction(callback)
        self.onActivate = callback
    end

    row:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.76, 0.51, 0.16, 1)
        if self.kind == "pvp" and self.talentID and GameTooltip.SetPvpTalent then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            pcall(GameTooltip.SetPvpTalent, GameTooltip, self.talentID)
            GameTooltip:AddLine(PvPIdiot:L("CHAT_LINK_HINT"), 0.55, 0.58, 0.64)
            GameTooltip:Show()
        elseif self.spellID and GameTooltip.SetSpellByID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            pcall(GameTooltip.SetSpellByID, GameTooltip, self.spellID)
            GameTooltip:AddLine(PvPIdiot:L("CHAT_LINK_HINT"), 0.55, 0.58, 0.64)
            GameTooltip:Show()
        end
    end)

    row:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.12, 0.14, 0.18, 1)
        GameTooltip:Hide()
    end)

    row:SetScript("OnClick", function(self)
        local handled = false
        if self.spellID then
            handled = PvPIdiot.Utils:InsertModifiedSpellLink(self.spellID)
        end
        if not handled and self.onActivate then
            self.onActivate(self)
        end
    end)

    return row
end
