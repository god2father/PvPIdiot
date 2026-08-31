local ADDON_NAME, PvPIdiot = ...

local SLOTS = {
    { key = "HEAD", labelKey = "SLOT_HEAD", inventory = 1 },
    { key = "NECK", labelKey = "SLOT_NECK", inventory = 2 },
    { key = "SHOULDER", labelKey = "SLOT_SHOULDER", inventory = 3 },
    { key = "BACK", labelKey = "SLOT_BACK", inventory = 15 },
    { key = "CHEST", labelKey = "SLOT_CHEST", inventory = 5 },
    { key = "WRIST", labelKey = "SLOT_WRIST", inventory = 9 },
    { key = "HANDS", labelKey = "SLOT_HANDS", inventory = 10 },
    { key = "WAIST", labelKey = "SLOT_WAIST", inventory = 6 },
    { key = "LEGS", labelKey = "SLOT_LEGS", inventory = 7 },
    { key = "FEET", labelKey = "SLOT_FEET", inventory = 8 },
    { key = "FINGER", labelKey = "SLOT_FINGER", inventory = 11 },
    { key = "TRINKET", labelKey = "SLOT_TRINKET", inventory = 13 },
    { key = "MAIN_HAND", labelKey = "SLOT_MAIN_HAND", inventory = 16 },
    { key = "OFF_HAND", labelKey = "SLOT_OFF_HAND", inventory = 17 },
}

local function GetItemIDFromLink(link)
    if not link then return nil end
    if GetItemInfoInstant then
        return select(1, GetItemInfoInstant(link))
    end
    return tonumber(link:match("item:(%d+)"))
end

function PvPIdiot:CreateGearPage(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()
    page.selectedSlot = "HEAD"
    page.slotButtons = {}

    local left = CreateFrame("Frame", nil, page, "BackdropTemplate")
    left:SetPoint("TOPLEFT", 10, -10)
    left:SetPoint("BOTTOMLEFT", 10, 10)
    left:SetWidth(160)
    left:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    left:SetBackdropColor(0.035, 0.045, 0.065, 0.95)
    left:SetBackdropBorderColor(0.16, 0.18, 0.22, 1)

    local right = CreateFrame("Frame", nil, page, "BackdropTemplate")
    right:SetPoint("TOPLEFT", left, "TOPRIGHT", 10, 0)
    right:SetPoint("BOTTOMRIGHT", -10, 10)
    right:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    right:SetBackdropColor(0.035, 0.045, 0.065, 0.95)
    right:SetBackdropBorderColor(0.16, 0.18, 0.22, 1)

    local title = left:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 10, -10)
    title:SetText(self:L("GEAR"))
    title:SetTextColor(0.95, 0.71, 0.25)

    for i, slot in ipairs(SLOTS) do
        local button = CreateFrame("Button", nil, left, "BackdropTemplate")
        button:SetSize(138, 28)
        button:SetPoint("TOPLEFT", 10, -34 - (i - 1) * 31)
        button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        local text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("LEFT", 8, 0)
        text:SetText(self:L(slot.labelKey))
        button.text = text
        button.slotInfo = slot
        button:SetScript("OnClick", function()
            page.selectedSlot = slot.key
            page:Refresh()
        end)
        page.slotButtons[slot.key] = button
    end

    local selectedTitle = right:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    selectedTitle:SetPoint("TOPLEFT", 14, -14)
    selectedTitle:SetTextColor(0.95, 0.71, 0.25)
    page.selectedTitle = selectedTitle

    local yourLabel = right:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    yourLabel:SetPoint("TOPLEFT", 14, -50)
    yourLabel:SetText(self:L("YOUR_GEAR"))

    local yourItem = self:CreateItemButton(right, 500, 46)
    yourItem:SetPoint("TOPLEFT", 14, -72)
    yourItem:SetPoint("RIGHT", -14, 0)
    page.yourItem = yourItem

    local metaLabel = right:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    metaLabel:SetPoint("TOPLEFT", 14, -135)
    metaLabel:SetText("Top 5")

    page.metaRows = {}
    for i = 1, 5 do
        local row = self:CreateItemButton(right, 500, 48)
        row:SetPoint("TOPLEFT", 14, -158 - (i - 1) * 54)
        row:SetPoint("RIGHT", -14, 0)
        page.metaRows[i] = row
    end

    function page:Refresh()
        local selectedInfo
        for _, slot in ipairs(SLOTS) do
            if slot.key == self.selectedSlot then selectedInfo = slot break end
        end
        selectedInfo = selectedInfo or SLOTS[1]
        self.selectedTitle:SetText(PvPIdiot:L(selectedInfo.labelKey))

        for key, button in pairs(self.slotButtons) do
            if key == self.selectedSlot then
                button:SetBackdropColor(0.10, 0.085, 0.055, 1)
                button:SetBackdropBorderColor(0.76, 0.51, 0.16, 1)
                button.text:SetTextColor(0.95, 0.71, 0.25)
            else
                button:SetBackdropColor(0.05, 0.06, 0.08, 1)
                button:SetBackdropBorderColor(0.20, 0.22, 0.25, 1)
                button.text:SetTextColor(0.72, 0.74, 0.78)
            end
        end

        local recommendations = PvPIdiot.DB:GetGearSlot(self.selectedSlot)
        local currentLink = GetInventoryItemLink and GetInventoryItemLink("player", selectedInfo.inventory)
        local currentID = GetItemIDFromLink(currentLink)
        local badge = PvPIdiot:L("NOT_TOP3")
        if currentID and recommendations[1] and currentID == recommendations[1].itemID then
            badge = "✓ " .. PvPIdiot:L("META")
        elseif currentID then
            for i = 1, math.min(3, #recommendations) do
                if currentID == recommendations[i].itemID then
                    badge = "✓ " .. PvPIdiot:L("RECOMMENDED")
                    break
                end
            end
        end

        if currentID then
            self.yourItem:SetItem(currentID, 0, badge)
            self.yourItem:Show()
        else
            self.yourItem.itemID = nil
            self.yourItem.icon:SetTexture(134400)
            self.yourItem.name:SetText("-")
            self.yourItem.usage:SetText("")
            self.yourItem.badge:SetText(badge)
            self.yourItem:Show()
        end

        for i, row in ipairs(self.metaRows) do
            local item = recommendations[i]
            row:SetShown(item ~= nil)
            if item then row:SetItem(item.itemID, item.usage, "#" .. i) end
        end
    end

    return page
end
