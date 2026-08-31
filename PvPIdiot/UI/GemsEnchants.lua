local ADDON_NAME, PvPIdiot = ...

function PvPIdiot:CreateGemsEnchantsPage(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()

    local gems = CreateFrame("Frame", nil, page, "BackdropTemplate")
    gems:SetPoint("TOPLEFT", 10, -10)
    gems:SetPoint("BOTTOMRIGHT", page, "BOTTOM", -5, 10)
    gems:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    gems:SetBackdropColor(0.035, 0.045, 0.065, 0.95)
    gems:SetBackdropBorderColor(0.16, 0.18, 0.22, 1)

    local enchants = CreateFrame("Frame", nil, page, "BackdropTemplate")
    enchants:SetPoint("TOPLEFT", page, "TOP", 5, -10)
    enchants:SetPoint("BOTTOMRIGHT", -10, 10)
    enchants:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    enchants:SetBackdropColor(0.035, 0.045, 0.065, 0.95)
    enchants:SetBackdropBorderColor(0.16, 0.18, 0.22, 1)

    local gemTitle = gems:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    gemTitle:SetPoint("TOPLEFT", 14, -14)
    gemTitle:SetText(self:L("GEMS_TOP3"):gsub(" Top 3", "") .. " — Top 5")
    gemTitle:SetTextColor(0.95, 0.71, 0.25)

    local enchantTitle = enchants:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    enchantTitle:SetPoint("TOPLEFT", 14, -14)
    enchantTitle:SetText(self:L("GEMS_ENCHANTS"))
    enchantTitle:SetTextColor(0.95, 0.71, 0.25)

    page.gemRows = {}
    for i = 1, 5 do
        local row = self:CreateItemButton(gems, 350, 50)
        row:SetPoint("TOPLEFT", 14, -50 - (i - 1) * 58)
        row:SetPoint("RIGHT", -14, 0)
        page.gemRows[i] = row
    end

    page.enchantRows = {}
    for i = 1, 6 do
        local row = self:CreateItemButton(enchants, 350, 50)
        row:SetPoint("TOPLEFT", 14, -50 - (i - 1) * 58)
        row:SetPoint("RIGHT", -14, 0)
        page.enchantRows[i] = row
    end

    function page:Refresh()
        local data = PvPIdiot.DB:GetCurrentSpecData()
        local gemsData = data and data.gems or {}
        for i, row in ipairs(self.gemRows) do
            local gem = gemsData[i]
            row:SetShown(gem ~= nil)
            if gem then row:SetItem(gem.itemID, gem.usage, "#" .. i) end
        end

        local flattened = {}
        for slot, list in pairs(data and data.enchants or {}) do
            for _, entry in ipairs(list) do
                table.insert(flattened, { slot = slot, entry = entry })
            end
        end
        table.sort(flattened, function(a, b) return (a.entry.usage or 0) > (b.entry.usage or 0) end)
        for i, row in ipairs(self.enchantRows) do
            local info = flattened[i]
            row:SetShown(info ~= nil)
            if info then
                local source = info.entry.source or {}
                if source.type == "item" then
                    row:SetItem(source.id, info.entry.usage, (info.slot == "WEAPON" and PvPIdiot:L("ENCHANT_WEAPON") or info.slot == "RING" and PvPIdiot:L("ENCHANT_RING") or info.slot) .. " #" .. tostring(i))
                else
                    row:SetSpell(
                        source.id or info.entry.enchantID,
                        info.entry.usage,
                        info.slot == "WEAPON" and PvPIdiot:L("ENCHANT_WEAPON") or info.slot == "RING" and PvPIdiot:L("ENCHANT_RING") or info.slot,
                        source.name or (PvPIdiot:L("ENCHANT") .. " #" .. tostring(info.entry.enchantID or "-"))
                    )
                end
            end
        end
    end

    return page
end
