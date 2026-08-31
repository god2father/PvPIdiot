local ADDON_NAME, PvPIdiot = ...

local defaults = {
    selectedBracket = "shuffle",
    selectedClass = "WARRIOR",
    selectedSpecID = 71,
    selectedSeason = 1,
    region = "global",
    topRange = 50,
    autoDetectSpec = true,
    selectedTab = "overview",
    selectedTalentKind = "class",
    selectedBuildIndex = 1,
    width = 1060,
    height = 680,
    position = {},
}

local function CopyDefaults(source, target)
    for key, value in pairs(source) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end
            CopyDefaults(value, target[key])
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

function PvPIdiot:InitializeConfig()
    PvPIdiotConfig = PvPIdiotConfig or {}
    CopyDefaults(defaults, PvPIdiotConfig)
    self.config = PvPIdiotConfig
end

function PvPIdiot:SyncSelectedSpecToPlayer()
    if not self.config or self.config.autoDetectSpec == false then return false end
    if not GetSpecialization or not GetSpecializationInfo then return false end

    local specializationIndex = GetSpecialization()
    if not specializationIndex then return false end

    local specID = GetSpecializationInfo(specializationIndex)
    if not specID then return false end

    local _, classFile = UnitClass("player")
    local changed = self.config.selectedSpecID ~= specID
        or (classFile and self.config.selectedClass ~= classFile)

    self.config.selectedSpecID = specID
    if classFile then
        self.config.selectedClass = classFile
    end

    return changed
end

function PvPIdiot:SaveFrameState(frame)
    if not self.config or not frame then return end

    self.config.width = math.floor(frame:GetWidth() + 0.5)
    self.config.height = math.floor(frame:GetHeight() + 0.5)

    local point, _, relativePoint, x, y = frame:GetPoint(1)
    self.config.position = {
        point = point,
        relativePoint = relativePoint,
        x = x,
        y = y,
    }
end

function PvPIdiot:RestoreFrameState(frame)
    if not self.config or not frame then return end

    local width = math.max(900, math.min(self.config.width or 1060, UIParent:GetWidth()))
    local height = math.max(600, math.min(self.config.height or 680, UIParent:GetHeight()))
    frame:SetSize(width, height)

    frame:ClearAllPoints()
    local pos = self.config.position
    if pos and pos.point and pos.relativePoint then
        frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x or 0, pos.y or 0)
    else
        frame:SetPoint("CENTER")
    end
end
