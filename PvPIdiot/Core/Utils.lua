local ADDON_NAME, PvPIdiot = ...

local Utils = {}
PvPIdiot.Utils = Utils

local traitLookupCache = {}

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
            return a.name or ("PvP Talent " .. id), a.icon or 134400, a.spellID
        elseif type(a) == "string" then
            return a, b or 134400, nil
        end
    end
    return "PvP Talent " .. tostring(id), 134400, nil
end

local function GetCurrentSpecID()
    if PlayerUtil and PlayerUtil.GetCurrentSpecID then
        return PlayerUtil.GetCurrentSpecID()
    end
    if GetSpecialization and GetSpecializationInfo then
        local index = GetSpecialization()
        if index then return select(1, GetSpecializationInfo(index)) end
    end
end

local function GetActiveEntryID(node)
    if not node then return nil end
    if type(node.activeEntry) == "table" then
        return node.activeEntry.entryID or node.activeEntry.ID
    end
    return node.activeEntry or node.activeEntryID
end

local function AddTraitLookupEntry(lookup, configID, nodeID, entryID, mapNode)
    if not entryID or not C_Traits or not C_Traits.GetEntryInfo then return end
    local entry = C_Traits.GetEntryInfo(configID, entryID)
    if not entry then return end

    local definitionID = entry.definitionID
    local definition = definitionID and C_Traits.GetDefinitionInfo and C_Traits.GetDefinitionInfo(definitionID)
    local spellID = definition and definition.spellID
    local spellInfo = spellID and C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
    local name = spellInfo and spellInfo.name
    local icon = spellInfo and spellInfo.iconID
    if not name or name == "?" then return end

    local info = {
        name = name,
        icon = icon or 134400,
        spellID = spellID,
        nodeID = nodeID,
        entryID = entryID,
        definitionID = definitionID,
    }

    if mapNode and nodeID then lookup[nodeID] = lookup[nodeID] or info end
    lookup[entryID] = lookup[entryID] or info
    if definitionID then lookup[definitionID] = lookup[definitionID] or info end
    if spellID then lookup[spellID] = lookup[spellID] or info end
end

local function BuildTraitLookup()
    local specID = (PvPIdiot.config and PvPIdiot.config.selectedSpecID) or GetCurrentSpecID()
    local configID = C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID()
    local treeID = specID and C_ClassTalents and C_ClassTalents.GetTraitTreeForSpec and C_ClassTalents.GetTraitTreeForSpec(specID)
    if not specID or not configID or not treeID or not C_Traits or not C_Traits.GetTreeNodes then
        return {}
    end

    local cacheKey = tostring(specID) .. ":" .. tostring(configID) .. ":" .. tostring(treeID)
    if traitLookupCache[cacheKey] then return traitLookupCache[cacheKey] end

    local lookup = {}
    for _, nodeID in ipairs(C_Traits.GetTreeNodes(treeID) or {}) do
        local node = C_Traits.GetNodeInfo and C_Traits.GetNodeInfo(configID, nodeID)
        if node then
            local activeEntryID = GetActiveEntryID(node)
            if activeEntryID then
                AddTraitLookupEntry(lookup, configID, nodeID, activeEntryID, true)
            end

            local entryIDs = node.entryIDs or node.entries or {}
            for index, entryID in ipairs(entryIDs) do
                AddTraitLookupEntry(lookup, configID, nodeID, entryID, not activeEntryID and index == 1)
            end
        end
    end

    traitLookupCache[cacheKey] = lookup
    return lookup
end

function Utils:ClearTraitLookupCache()
    traitLookupCache = {}
end

function Utils:GetTraitTalentInfo(id, fallbackKind)
    if not id then return (fallbackKind or "Talent") .. " #-", 134400, nil end

    local configID = C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID()
    local node = configID and C_Traits and C_Traits.GetNodeInfo and C_Traits.GetNodeInfo(configID, id)
    if node then
        local entryID = GetActiveEntryID(node)
        if not entryID then
            local entryIDs = node.entryIDs or node.entries
            entryID = entryIDs and entryIDs[1]
        end
        local entry = entryID and C_Traits.GetEntryInfo and C_Traits.GetEntryInfo(configID, entryID)
        local definition = entry and entry.definitionID and C_Traits.GetDefinitionInfo and C_Traits.GetDefinitionInfo(entry.definitionID)
        local spellInfo = definition and definition.spellID and C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(definition.spellID)
        if spellInfo and spellInfo.name and spellInfo.name ~= "?" then
            return spellInfo.name, spellInfo.iconID or 134400, definition.spellID
        end
    end

    -- Murlok has used different talent identifiers over time (node, entry,
    -- definition and spell IDs). Build a lookup from the live Blizzard tree so
    -- snapshots remain readable even when the upstream identifier shape changes.
    local info = BuildTraitLookup()[tonumber(id) or id]
    if info then
        return info.name, info.icon, info.spellID
    end

    local spellInfo = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(id)
    if spellInfo and spellInfo.name and spellInfo.name ~= "?" then
        return spellInfo.name, spellInfo.iconID or 134400, tonumber(id)
    end

    return (fallbackKind or "Talent") .. " #" .. tostring(id), 134400, nil
end
