local ADDON_NAME, PvPIdiot = ...

local DB = {}
PvPIdiot.DB = DB
_G.PvPIdiotDB = DB

local function FindSeason(data, seasonID)
    if not data or not data.seasons then return nil end
    for _, season in ipairs(data.seasons) do
        if season.id == seasonID then
            return season
        end
    end
    return data.seasons[1]
end

function DB:GetRoot()
    return _G.PvPIdiotData or PvPIdiot.Data or PvPIdiot.MockData
end

function DB:GetMetadata()
    local root = self:GetRoot() or {}
    return {
        version = root.version,
        updatedAt = root.updatedAt,
        generatedAt = root.generatedAt,
        isMock = root.isMock == true,
        source = root.source,
        sourceMode = root.sourceMode,
        sourceScope = root.sourceScope,
        fetchFailures = root.fetchFailures or {},
    }
end

function DB:GetSpecIndex()
    local root = self:GetRoot() or {}
    if root.specIndex then return root.specIndex end

    -- v0.1 Mock Data predates specIndex. Keep a compatible fallback.
    return {
        [71] = {
            classSlug = "warrior",
            specSlug = "arms",
            className = "Warrior",
            specName = "Arms",
        },
    }
end

function DB:GetSpecMeta(specID)
    local index = self:GetSpecIndex()
    local indexed = index and index[specID]
    local data = self:GetSpecData(specID)
    local meta = data and data.meta or nil

    if indexed or meta then
        return {
            specID = specID,
            classSlug = (indexed and indexed.classSlug) or (meta and meta.classSlug),
            specSlug = (indexed and indexed.specSlug) or (meta and meta.specSlug),
            className = (indexed and indexed.className) or (meta and meta.className),
            specName = (indexed and indexed.specName) or (meta and meta.specName),
            dataAvailable = not meta or meta.dataAvailable ~= false,
        }
    end
end

function DB:GetSpecData(specID, bracket, region, seasonID, topRange)
    local root = self:GetRoot()
    local season = FindSeason(root, seasonID or 1)
    if not season or not season.brackets then return nil end

    -- Region/topRange are part of the stable access-layer signature. The current
    -- Murlok snapshot is already globally aggregated Top 50 data.
    local bracketData = season.brackets[bracket or "shuffle"]
    if not bracketData or not bracketData.specs then return nil end
    return bracketData.specs[specID]
end

function DB:GetCurrentSpecData()
    local config = PvPIdiot.config or {}
    return self:GetSpecData(
        config.selectedSpecID or 71,
        config.selectedBracket or "shuffle",
        config.region or "global",
        config.selectedSeason or 1,
        config.topRange or 50
    )
end

function DB:GetCurrentSpecMeta()
    local config = PvPIdiot.config or {}
    return self:GetSpecMeta(config.selectedSpecID or 71)
end

function DB:GetGearSlot(slotKey)
    local data = self:GetCurrentSpecData()
    return data and data.gear and data.gear[slotKey] or {}
end

function DB:GetTopGear(limit)
    limit = limit or 3
    local data = self:GetCurrentSpecData()
    if not data or not data.gear then return {} end

    local result = {}
    for slot, items in pairs(data.gear) do
        if items and items[1] then
            table.insert(result, {
                slot = slot,
                itemID = items[1].itemID,
                usage = items[1].usage,
                count = items[1].count,
            })
        end
    end
    table.sort(result, function(a, b) return (a.usage or 0) > (b.usage or 0) end)
    while #result > limit do table.remove(result) end
    return result
end
