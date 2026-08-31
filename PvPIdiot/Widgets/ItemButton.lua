local ADDON_NAME, PvPIdiot = ...

function PvPIdiot:CreateItemButton(parent, width, height)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 300, height or 42)
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    button:SetBackdropColor(0.06, 0.075, 0.10, 0.92)
    button:SetBackdropBorderColor(0.22, 0.24, 0.28, 1)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetPoint("LEFT", 6, 0)
    icon:SetTexture(134400)
    button.icon = icon

    local name = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    name:SetPoint("LEFT", icon, "RIGHT", 8, 6)
    name:SetPoint("RIGHT", -70, 6)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    button.name = name

    local usage = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    usage:SetPoint("LEFT", icon, "RIGHT", 8, -9)
    usage:SetTextColor(0.72, 0.72, 0.75)
    button.usage = usage

    local badge = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    badge:SetPoint("RIGHT", -8, 0)
    badge:SetTextColor(0.95, 0.71, 0.25)
    button.badge = badge

    button:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.76, 0.51, 0.16, 1)
        if self.itemID then
            PvPIdiot.Utils:ShowItemTooltip(self, self.itemID)
        end
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.22, 0.24, 0.28, 1)
        PvPIdiot.Utils:HideTooltip()
    end)

    function button:SetItem(itemID, usageValue, badgeText)
        self.itemID = itemID
        self.icon:SetTexture(PvPIdiot.Utils:SafeItemIcon(itemID))
        self.name:SetText(PvPIdiot.Utils:SafeItemName(itemID))
        if usageValue == nil then
            self.usage:SetText("")
        else
            self.usage:SetText(PvPIdiot:L("USAGE") .. " " .. PvPIdiot.Utils:FormatPercent(usageValue, 1))
        end
        self.badge:SetText(badgeText or "")

        if Item and Item.CreateFromItemID and itemID then
            local item = Item:CreateFromItemID(itemID)
            item:ContinueOnItemLoad(function()
                if self.itemID ~= itemID then return end
                self.icon:SetTexture(PvPIdiot.Utils:SafeItemIcon(itemID))
                self.name:SetText(PvPIdiot.Utils:SafeItemName(itemID))
            end)
        end
    end

    function button:SetEmpty(badgeText)
        self.itemID = nil
        self.icon:SetTexture(134400)
        self.name:SetText("-")
        self.usage:SetText("")
        self.badge:SetText(badgeText or "")
    end

    return button
end
