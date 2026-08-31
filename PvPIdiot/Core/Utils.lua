local ADDON_NAME, PvPIdiot = ...

local Utils = {}
PvPIdiot.Utils = Utils

function Utils:Clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

function Utils:FormatPercent(value, decimals)
    decimals = decimals or 1
    value = tonumber(value) or 0
    return string.format("%." .. decimals .. "f%%", value * 100)
end

function Utils:FormatDate(iso)
    if type(iso) ~= "string" then return "-" end
    local y, m, d = iso:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)")
    if y then
        return string.format("%s/%s/%s", y, m, d)
    end
    return iso
end

function Utils:SafeItemName(itemID)
    if not itemID then return "-" end
    if C_Item and C_Item.GetItemNameByID then
        local name = C_Item.GetItemNameByID(itemID)
        if name then return name end
    end
    local name = GetItemInfo and GetItemInfo(itemID)
    return name or ("Item " .. itemID)
end

function Utils:SafeItemIcon(itemID)
    if C_Item and C_Item.GetItemIconByID then
        return C_Item.GetItemIconByID(itemID)
    end
    return 134400
end

function Utils:GetItemLink(itemID)
    if not itemID then return nil end
    if C_Item and C_Item.GetItemLinkByID then
        local link = C_Item.GetItemLinkByID(itemID)
        if link then return link end
    end
    return GetItemInfo and select(2, GetItemInfo(itemID)) or nil
end

function Utils:InsertModifiedLink(link)
    if not link or not IsModifiedClick or not IsModifiedClick("CHATLINK") then return false end
    if HandleModifiedItemClick then
        HandleModifiedItemClick(link)
        return true
    end
    if ChatEdit_InsertLink then
        ChatEdit_InsertLink(link)
        return true
    end
    return false
end

function Utils:InsertModifiedItemLink(itemID)
    if not itemID or not IsModifiedClick or not IsModifiedClick("CHATLINK") then return false end

    local link = self:GetItemLink(itemID)
    if link then return self:InsertModifiedLink(link) end

    if Item and Item.CreateFromItemID then
        local item = Item:CreateFromItemID(itemID)
        item:ContinueOnItemLoad(function()
            self:InsertModifiedLink(self:GetItemLink(itemID))
        end)
    end
    return false
end

function Utils:InsertModifiedSpellLink(spellID)
    if not spellID or not IsModifiedClick or not IsModifiedClick("CHATLINK") then return false end
    local link
    if C_Spell and C_Spell.GetSpellLink then
        link = C_Spell.GetSpellLink(spellID)
    elseif GetSpellLink then
        link = GetSpellLink(spellID)
    end
    return self:InsertModifiedLink(link)
end

function Utils:ShowItemTooltip(owner, itemID)
    if not owner or not itemID then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    local link = self:GetItemLink(itemID)
    if link then
        GameTooltip:SetHyperlink(link)
        GameTooltip:AddLine(PvPIdiot:L("CHAT_LINK_HINT"), 0.55, 0.58, 0.64)
    else
        GameTooltip:SetText(self:SafeItemName(itemID))
        GameTooltip:AddLine(PvPIdiot:L("ITEM_LOADING"), 0.7, 0.7, 0.7)
    end
    GameTooltip:Show()
end

function Utils:HideTooltip()
    GameTooltip:Hide()
end

function Utils:GetPvpTalentInfo(id)
    if C_SpecializationInfo and C_SpecializationInfo.GetPvpTalentInfo then
        local a, b = C_SpecializationInfo.GetPvpTalentInfo(id)
        if type(a) == "table" then
            return a.name or ("PvP Talent " .. id), a.icon or 134400
        elseif type(a) == "string" then
            return a, b or 134400
        end
    end
    return "PvP Talent " .. tostring(id), 134400
end

function Utils:GetTraitTalentInfo(nodeID, fallbackKind)
    local configID = C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID()
    local node = configID and C_Traits and C_Traits.GetNodeInfo and C_Traits.GetNodeInfo(configID, nodeID)
    local entryID = node and (node.activeEntry or node.activeEntryID or (node.entries and node.entries[1]))
    local entry = entryID and C_Traits and C_Traits.GetEntryInfo and C_Traits.GetEntryInfo(configID, entryID)
    local definition = entry and entry.definitionID and C_Traits and C_Traits.GetDefinitionInfo and C_Traits.GetDefinitionInfo(entry.definitionID)
    local spellInfo = definition and definition.spellID and C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(definition.spellID)

    if spellInfo and spellInfo.name and spellInfo.name ~= "?" then
        return spellInfo.name, spellInfo.iconID or 134400
    end

    return (fallbackKind or "Talent") .. " #" .. tostring(nodeID or "-"), 134400
end
