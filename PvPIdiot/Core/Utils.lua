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

function Utils:ShowItemTooltip(owner, itemID)
    if not owner or not itemID then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    local link = select(2, GetItemInfo(itemID))
    if link then
        GameTooltip:SetHyperlink(link)
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
