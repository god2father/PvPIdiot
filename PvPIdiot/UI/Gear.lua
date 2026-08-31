local ADDON_NAME, PvPIdiot = ...

local SLOTS = {
    { id = "HEAD", dataKey = "HEAD", labelKey = "SLOT_HEAD", inventory = 1 },
    { id = "NECK", dataKey = "NECK", labelKey = "SLOT_NECK", inventory = 2 },
    { id = "SHOULDER", dataKey = "SHOULDER", labelKey = "SLOT_SHOULDER", inventory = 3 },
    { id = "BACK", dataKey = "BACK", labelKey = "SLOT_BACK", inventory = 15 },
    { id = "CHEST", dataKey = "CHEST", labelKey = "SLOT_CHEST", inventory = 5 },
    { id = "WRIST", dataKey = "WRIST", labelKey = "SLOT_WRIST", inventory = 9 },
    { id = "HANDS", dataKey = "HANDS", labelKey = "SLOT_HANDS", inventory = 10 },
    { id = "WAIST", dataKey = "WAIST", labelKey = "SLOT_WAIST", inventory = 6 },
    { id = "LEGS", dataKey = "LEGS", labelKey = "SLOT_LEGS", inventory = 7 },
    { id = "FEET", dataKey = "FEET", labelKey = "SLOT_FEET", inventory = 8 },
    { id = "FINGER_1", dataKey = "FINGER", labelKey = "SLOT_FINGER_1", inventory = 11 },
    { id = "FINGER_2", dataKey = "FINGER", labelKey = "SLOT_FINGER_2", inventory = 12 },
    { id = "TRINKET_1", dataKey = "TRINKET", labelKey = "SLOT_TRINKET_1", inventory = 13 },
    { id = "TRINKET_2", dataKey = "TRINKET", labelKey = "SLOT_TRINKET_2", inventory = 14 },
    { id = "MAIN_HAND", dataKey = "MAIN_HAND", labelKey = "SLOT_MAIN_HAND", inventory = 16 },
    { id = "OFF_HAND", dataKey = "OFF_HAND", labelKey = "SLOT_OFF_HAND", inventory = 17 },
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
    left:SetWidth(240)
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
    title:SetText(self:L("YOUR_GEAR"))
    title:SetTextColor(0.95, 0.71, 0.25)

    for i, slot in ipairs(SLOTS) do
        local button = self:CreateItemButton(left, 218, 28)
        button:SetPoint("TOPLEFT", 10, -34 - (i - 1) * 30)
        button.slotInfo = slot
        button:SetAction(function()
            page.selectedSlot = slot.id
            page:Refresh()
        end)
        page.slotButtons[slot.id] = button
    end

    local selectedTitle = right:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    selectedTitle:SetPoint("TOPLEFT", 14, -14)
    selectedTitle:SetTextColor(0.95, 0.71, 0.25)
    page.selectedTitle = selectedTitle

    local comparisonStatus = right:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    comparisonStatus:SetPoint("TOPLEFT", 14, -48)
    comparisonStatus:SetPoint("TOPRIGHT", -14, -48)
    comparisonStatus:SetJustifyH("LEFT")
    comparisonStatus:SetTextColor(0.72, 0.74, 0.78)
    page.comparisonStatus = comparisonStatus

    local yourLabel = right:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    yourLabel:SetPoint("TOPLEFT", 14, -72)
    yourLabel:SetText(self:L("YOUR_GEAR"))

    local yourItem = self:CreateItemButton(right, 250, 46)
    yourItem:SetPoint("TOPLEFT", 14, -94)
    yourItem:SetPoint("TOPRIGHT", right, "TOP", -4, -94)
    page.yourItem = yourItem

    local recommendedLabel = right:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    recommendedLabel:SetPoint("TOPLEFT", right, "TOP", 6, -72)
    recommendedLabel:SetText(self:L("RECOMMENDED_GEAR"))

    local recommendedItem = self:CreateItemButton(right, 250, 46)
    recommendedItem:SetPoint("TOPLEFT", right, "TOP", 6, -94)
    recommendedItem:SetPoint("TOPRIGHT", -14, -94)
    page.recommendedItem = recommendedItem

    local metaLabel = right:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    metaLabel:SetPoint("TOPLEFT", 14, -158)
    metaLabel:SetText(self:L("ALTERNATIVE_GEAR"))

    page.metaRows = {}
    for i = 1, 5 do
        local row = self:CreateItemButton(right, 500, 48)
        row:SetPoint("TOPLEFT", 14, -181 - (i - 1) * 54)
        row:SetPoint("RIGHT", -14, 0)
        page.metaRows[i] = row
    end

    function page:Refresh()
        local selectedInfo
        for _, slot in ipairs(SLOTS) do
            if slot.id == self.selectedSlot then selectedInfo = slot break end
        end
        selectedInfo = selectedInfo or SLOTS[1]
        self.selectedTitle:SetText(PvPIdiot:L(selectedInfo.labelKey))

        for key, button in pairs(self.slotButtons) do
            local slot = button.slotInfo
            local itemLink = GetInventoryItemLink and GetInventoryItemLink("player", slot.inventory)
            local itemID = GetItemIDFromLink(itemLink)
            if itemID then
                button:SetItem(itemID, nil, PvPIdiot:L(slot.labelKey))
            else
                button:SetEmpty(PvPIdiot:L(slot.labelKey))
            end
            button:SetSelected(key == self.selectedSlot)
        end

        local currentLink = GetInventoryItemLink and GetInventoryItemLink("player", selectedInfo.inventory)
        local currentID = GetItemIDFromLink(currentLink)
        local comparison = PvPIdiot.DB:GetGearComparison(selectedInfo.dataKey, currentID)
        local recommendations = comparison.recommendations

        if currentID then
            self.yourItem:SetItem(currentID, nil, PvPIdiot:L("CURRENT"))
            self.yourItem:Show()
        else
            self.yourItem:SetEmpty(PvPIdiot:L("NO_EQUIPPED_ITEM"))
            self.yourItem:Show()
        end

        if comparison.recommendedItem then
            self.recommendedItem:SetItem(
                comparison.recommendedItem.itemID,
                comparison.recommendedItem.usage,
                "#1"
            )
        else
            self.recommendedItem:SetEmpty(PvPIdiot:L("NO_GEAR_DATA"))
        end
        self.recommendedItem:Show()

        if not currentID then
            self.comparisonStatus:SetText(PvPIdiot:L("NO_EQUIPPED_ITEM"))
            self.comparisonStatus:SetTextColor(0.72, 0.74, 0.78)
        elseif comparison.rank == 1 then
            self.comparisonStatus:SetText(PvPIdiot:L("GEAR_MATCH_TOP1"))
            self.comparisonStatus:SetTextColor(0.35, 0.90, 0.45)
        elseif comparison.rank and comparison.rank <= 3 then
            self.comparisonStatus:SetText(string.format(PvPIdiot:L("GEAR_MATCH_TOP3"), comparison.rank))
            self.comparisonStatus:SetTextColor(0.95, 0.71, 0.25)
        elseif comparison.rank then
            self.comparisonStatus:SetText(string.format(PvPIdiot:L("GEAR_MATCH_TOP5"), comparison.rank))
            self.comparisonStatus:SetTextColor(0.95, 0.71, 0.25)
        else
            self.comparisonStatus:SetText(PvPIdiot:L("GEAR_NOT_RECOMMENDED"))
            self.comparisonStatus:SetTextColor(1, 0.45, 0.32)
        end

        for i, row in ipairs(self.metaRows) do
            local item = recommendations[i]
            row:SetShown(item ~= nil)
            if item then row:SetItem(item.itemID, item.usage, "#" .. i) end
        end
    end

    return page
end
