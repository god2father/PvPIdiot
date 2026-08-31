local ADDON_NAME, PvPIdiot = ...

local NODE_SIZE = 42
local TREE_PADDING = 34

local function CurrentSpecID()
    if PlayerUtil and PlayerUtil.GetCurrentSpecID then
        return PlayerUtil.GetCurrentSpecID()
    end
    if GetSpecialization and GetSpecializationInfo then
        local index = GetSpecialization()
        if index then return select(1, GetSpecializationInfo(index)) end
    end
end

local function GetConfigForSpec(specID)
    if not C_ClassTalents then return nil end

    -- Midnight exposes a read-only "view loadout" config. It lets us query the
    -- real Blizzard tree for any class/spec, not just the player's current spec.
    if C_ClassTalents.InitializeViewLoadout
        and C_ClassTalents.ViewLoadout
        and Constants
        and Constants.TraitConsts
        and Constants.TraitConsts.VIEW_TRAIT_CONFIG_ID
    then
        local ok = pcall(C_ClassTalents.InitializeViewLoadout, specID, 100)
        if ok then
            pcall(C_ClassTalents.ViewLoadout, {})
            return Constants.TraitConsts.VIEW_TRAIT_CONFIG_ID
        end
    end

    if specID == CurrentSpecID() and C_ClassTalents.GetActiveConfigID then
        local active = C_ClassTalents.GetActiveConfigID()
        if active then return active end
    end

    if C_ClassTalents.GetConfigIDsBySpecID then
        local configIDs = C_ClassTalents.GetConfigIDsBySpecID(specID)
        if configIDs and configIDs[1] then
            return configIDs[1]
        end
    end
end

local function NumberKey(value)
    return tonumber(value) or value
end

local function AddAlias(target, value)
    if value ~= nil then target[NumberKey(value)] = true end
end

local function EntryRecord(configID, entryID)
    if not entryID or not C_Traits or not C_Traits.GetEntryInfo then return nil end
    local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
    if not entryInfo then return nil end

    local definitionID = entryInfo.definitionID
    local definition = definitionID and C_Traits.GetDefinitionInfo and C_Traits.GetDefinitionInfo(definitionID)
    local spellID = definition and definition.spellID
    local spellInfo = spellID and C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
    local name = definition and definition.overrideName
        or spellInfo and spellInfo.name
        or ("Talent #" .. tostring(entryID))
    local icon = definition and definition.overrideIcon
        or spellInfo and spellInfo.iconID
        or 134400

    local aliases = {}
    AddAlias(aliases, entryID)
    AddAlias(aliases, definitionID)
    AddAlias(aliases, spellID)

    return {
        entryID = entryID,
        definitionID = definitionID,
        spellID = spellID,
        name = name,
        icon = icon,
        aliases = aliases,
    }
end

local function NodeCurrencyKind(configID, nodeID, classCurrencyID, specCurrencyID)
    if C_Traits and C_Traits.GetNodeCost then
        for _, cost in ipairs(C_Traits.GetNodeCost(configID, nodeID) or {}) do
            if cost.ID == classCurrencyID then return "class" end
            if cost.ID == specCurrencyID then return "spec" end
        end
    end

    local nodeInfo = C_Traits and C_Traits.GetNodeInfo and C_Traits.GetNodeInfo(configID, nodeID)
    for _, conditionID in ipairs(nodeInfo and nodeInfo.conditionIDs or {}) do
        local condition = C_Traits.GetConditionInfo and C_Traits.GetConditionInfo(configID, conditionID)
        if condition and condition.traitCurrencyID == classCurrencyID then return "class" end
        if condition and condition.traitCurrencyID == specCurrencyID then return "spec" end
    end
end

local function MakeRecommendationSet(list)
    local result = {}
    for _, talent in ipairs(list or {}) do
        if talent and talent.id ~= nil then
            result[NumberKey(talent.id)] = talent
        end
    end
    return result
end

local function AddNodeAliases(aliasIndex, node)
    aliasIndex[node.nodeID] = aliasIndex[node.nodeID] or { node = node }
    for _, entry in ipairs(node.entries) do
        for alias in pairs(entry.aliases) do
            local current = aliasIndex[alias]
            if not current then
                aliasIndex[alias] = { node = node, entry = entry }
            end
        end
    end
end

local function PickDisplayEntry(node)
    if node.selectedEntry then return node.selectedEntry end

    local activeEntryID = node.info.activeEntry and node.info.activeEntry.entryID
    if activeEntryID then
        for _, entry in ipairs(node.entries) do
            if entry.entryID == activeEntryID then return entry end
        end
    end

    local committed = node.info.entryIDsWithCommittedRanks
    if committed and committed[1] then
        for _, entry in ipairs(node.entries) do
            if entry.entryID == committed[1] then return entry end
        end
    end

    return node.entries[1]
end

local function NearestKnownKind(node, nodes)
    local bestKind, bestDistance
    for _, other in ipairs(nodes) do
        if other.kind == "class" or other.kind == "spec" then
            local dx = (other.info.posX or 0) - (node.info.posX or 0)
            local dy = (other.info.posY or 0) - (node.info.posY or 0)
            local distance = dx * dx + dy * dy
            if not bestDistance or distance < bestDistance then
                bestDistance = distance
                bestKind = other.kind
            end
        end
    end
    return bestKind
end

local function BuildModel(specID, kind, data, buildIndex)
    if kind == "pvp" then return nil, "pvp" end
    if not C_ClassTalents or not C_Traits then return nil, "api" end

    local configID = GetConfigForSpec(specID)
    if not configID then return nil, "config" end

    local configInfo = C_Traits.GetConfigInfo and C_Traits.GetConfigInfo(configID)
    local treeID = configInfo and configInfo.treeIDs and configInfo.treeIDs[1]
        or C_ClassTalents.GetTraitTreeForSpec and C_ClassTalents.GetTraitTreeForSpec(specID)
    if not treeID then return nil, "tree" end

    local currencies = C_Traits.GetTreeCurrencyInfo and C_Traits.GetTreeCurrencyInfo(configID, treeID, true) or {}
    local classCurrencyID = currencies[1] and currencies[1].traitCurrencyID
    local specCurrencyID = currencies[2] and currencies[2].traitCurrencyID

    local allNodes = {}
    local allByID = {}
    for _, nodeID in ipairs(C_Traits.GetTreeNodes and C_Traits.GetTreeNodes(treeID) or {}) do
        local info = C_Traits.GetNodeInfo and C_Traits.GetNodeInfo(configID, nodeID)
        if info and info.ID and info.ID ~= 0 and info.isVisible ~= false and info.type ~= 3 then
            local node = {
                nodeID = nodeID,
                info = info,
                entries = {},
                aliases = { [nodeID] = true },
                kind = info.subTreeID and "hero"
                    or NodeCurrencyKind(configID, nodeID, classCurrencyID, specCurrencyID),
            }

            for _, entryID in ipairs(info.entryIDs or {}) do
                local entry = EntryRecord(configID, entryID)
                if entry then
                    table.insert(node.entries, entry)
                    for alias in pairs(entry.aliases) do
                        node.aliases[alias] = true
                    end
                end
            end

            if #node.entries > 0 then
                table.insert(allNodes, node)
                allByID[nodeID] = node
            end
        end
    end

    -- Granted/root nodes can have no direct currency cost. Infer their side from
    -- adjacent nodes first, then from the closest classified node.
    for _ = 1, 4 do
        local changed = false
        for _, node in ipairs(allNodes) do
            if not node.kind and not node.info.subTreeID then
                for _, edge in ipairs(node.info.visibleEdges or {}) do
                    local target = allByID[edge.targetNode]
                    if target and (target.kind == "class" or target.kind == "spec") then
                        node.kind = target.kind
                        changed = true
                        break
                    end
                end
            end
        end
        if not changed then break end
    end
    for _, node in ipairs(allNodes) do
        if not node.kind and not node.info.subTreeID then
            node.kind = NearestKnownKind(node, allNodes)
        end
    end

    local build = data and data.builds and data.builds[buildIndex or 1]
    local buildList = build and build.talents and build.talents[kind] or {}
    local buildSet = MakeRecommendationSet(buildList)
    local aggregateList = data and data.talents and data.talents[kind] or {}

    local aliasIndex = {}
    for _, node in ipairs(allNodes) do
        AddNodeAliases(aliasIndex, node)
    end

    for id in pairs(buildSet) do
        local match = aliasIndex[id]
        if match then
            match.node.selected = true
            if match.entry then match.node.selectedEntry = match.entry end
        end
    end

    for _, talent in ipairs(aggregateList) do
        local match = talent and aliasIndex[NumberKey(talent.id)]
        if match then
            local usage = tonumber(talent.usage) or 0
            if usage >= (match.node.usage or -1) then
                match.node.usage = usage
                match.node.count = talent.count
                match.node.aggregateEntry = match.entry
            end
        end
    end

    local selectedSubTrees = {}
    if kind == "hero" then
        for _, node in ipairs(allNodes) do
            if node.selected and node.info.subTreeID then
                selectedSubTrees[node.info.subTreeID] = true
            end
        end
        if not next(selectedSubTrees) then
            for _, node in ipairs(allNodes) do
                if node.info.subTreeID and node.info.subTreeActive then
                    selectedSubTrees[node.info.subTreeID] = true
                end
            end
        end
    end

    local nodes = {}
    local byID = {}
    for _, node in ipairs(allNodes) do
        local include = node.kind == kind
        if include and kind == "hero" and next(selectedSubTrees) then
            include = selectedSubTrees[node.info.subTreeID] == true
        end
        if include then
            node.displayEntry = PickDisplayEntry(node)
            if not node.selectedEntry and node.aggregateEntry and not node.selected then
                node.displayEntry = node.aggregateEntry
            end
            table.insert(nodes, node)
            byID[node.nodeID] = node
        end
    end

    if #nodes == 0 then return nil, "nodes" end

    local title
    if kind == "hero" and next(selectedSubTrees) and C_Traits.GetSubTreeInfo then
        for subTreeID in pairs(selectedSubTrees) do
            local subTreeInfo = C_Traits.GetSubTreeInfo(configID, subTreeID)
            if subTreeInfo and subTreeInfo.name then
                title = subTreeInfo.name
                break
            end
        end
    end

    return {
        configID = configID,
        treeID = treeID,
        nodes = nodes,
        byID = byID,
        build = build,
        kind = kind,
        title = title,
    }
end

local function SetNodeTooltip(button)
    local node = button.node
    if not node then return end
    local entry = node.displayEntry

    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    if entry and entry.spellID and GameTooltip.SetSpellByID then
        pcall(GameTooltip.SetSpellByID, GameTooltip, entry.spellID)
    elseif entry then
        GameTooltip:SetText(entry.name or ("Talent #" .. tostring(node.nodeID)))
    else
        GameTooltip:SetText("Talent #" .. tostring(node.nodeID))
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(
        PvPIdiot:L("TALENT_TREE_BUILD_STATUS"),
        node.selected and PvPIdiot:L("TALENT_TREE_SELECTED") or PvPIdiot:L("TALENT_TREE_NOT_SELECTED"),
        0.72, 0.74, 0.78,
        node.selected and 0.95 or 0.60,
        node.selected and 0.71 or 0.62,
        node.selected and 0.25 or 0.66
    )
    if node.usage ~= nil then
        GameTooltip:AddDoubleLine(
            PvPIdiot:L("RECOMMEND_USAGE"),
            PvPIdiot.Utils:FormatPercent(node.usage, 1),
            0.72, 0.74, 0.78, 1, 1, 1
        )
    end
    if node.count ~= nil then
        GameTooltip:AddDoubleLine(
            PvPIdiot:L("COUNT"),
            tostring(node.count),
            0.62, 0.65, 0.70, 1, 1, 1
        )
    end
    if entry and entry.spellID then
        GameTooltip:AddLine(PvPIdiot:L("CHAT_LINK_HINT"), 0.55, 0.58, 0.64)
    end
    GameTooltip:Show()
end

function PvPIdiot:CreateTalentTreeView(parent)
    local view = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    view:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    view:SetBackdropColor(0.018, 0.024, 0.035, 0.98)
    view:SetBackdropBorderColor(0.15, 0.17, 0.21, 1)
    view.nodePool = {}
    view.linePool = {}

    local empty = view:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    empty:SetPoint("CENTER")
    empty:SetWidth(500)
    empty:SetJustifyH("CENTER")
    empty:SetTextColor(0.66, 0.69, 0.74)
    empty:Hide()
    view.empty = empty

    local subtreeTitle = view:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtreeTitle:SetPoint("TOP", 0, -9)
    subtreeTitle:SetTextColor(0.95, 0.71, 0.25)
    subtreeTitle:Hide()
    view.subtreeTitle = subtreeTitle

    local function AcquireNode(index)
        local button = view.nodePool[index]
        if button then return button end

        button = CreateFrame("Button", nil, view, "BackdropTemplate")
        button:SetSize(NODE_SIZE, NODE_SIZE)
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 2,
        })
        button:RegisterForClicks("LeftButtonUp")

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 4, -4)
        icon:SetPoint("BOTTOMRIGHT", -4, 4)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        button.icon = icon

        local choice = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        choice:SetPoint("TOPRIGHT", 3, 4)
        choice:SetText("◆")
        choice:SetTextColor(0.95, 0.71, 0.25)
        choice:Hide()
        button.choice = choice

        local usage = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        usage:SetPoint("TOP", button, "BOTTOM", 0, -2)
        usage:SetTextColor(0.78, 0.80, 0.84)
        button.usage = usage

        local selectedGlow = button:CreateTexture(nil, "OVERLAY")
        selectedGlow:SetPoint("TOPLEFT", -3, 3)
        selectedGlow:SetPoint("BOTTOMRIGHT", 3, -3)
        selectedGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        selectedGlow:SetBlendMode("ADD")
        selectedGlow:SetAlpha(0.72)
        selectedGlow:Hide()
        button.selectedGlow = selectedGlow

        button:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(0.95, 0.71, 0.25, 1)
            SetNodeTooltip(self)
        end)
        button:SetScript("OnLeave", function(self)
            local selected = self.node and self.node.selected
            if selected then
                self:SetBackdropBorderColor(0.86, 0.58, 0.18, 1)
            else
                self:SetBackdropBorderColor(0.24, 0.27, 0.31, 1)
            end
            if view.pinnedButton ~= self then GameTooltip:Hide() end
        end)
        button:SetScript("OnClick", function(self)
            local entry = self.node and self.node.displayEntry
            if entry and entry.spellID and PvPIdiot.Utils:InsertModifiedSpellLink(entry.spellID) then
                return
            end

            if view.pinnedButton == self then
                view.pinnedButton = nil
                GameTooltip:Hide()
            else
                view.pinnedButton = self
                SetNodeTooltip(self)
            end
        end)

        view.nodePool[index] = button
        return button
    end

    local function AcquireLine(index)
        local line = view.linePool[index]
        if line then return line end
        if not view.CreateLine then return nil end

        line = view:CreateLine(nil, "BACKGROUND")
        line:SetThickness(2)
        view.linePool[index] = line
        return line
    end

    function view:ClearTree()
        self.pinnedButton = nil
        GameTooltip:Hide()
        for _, button in ipairs(self.nodePool) do
            button.node = nil
            button:Hide()
        end
        for _, line in ipairs(self.linePool) do
            line:Hide()
        end
    end

    function view:SetUnavailable(reason)
        self:ClearTree()
        self.subtreeTitle:Hide()
        if reason == "config" then
            self.empty:SetText(PvPIdiot:L("TALENT_TREE_CONFIG_UNAVAILABLE"))
        elseif reason == "nodes" then
            self.empty:SetText(PvPIdiot:L("TALENT_TREE_NO_NODES"))
        else
            self.empty:SetText(PvPIdiot:L("TALENT_TREE_API_UNAVAILABLE"))
        end
        self.empty:Show()
    end

    function view:Refresh(kind, buildIndex)
        self.kind = kind
        self.buildIndex = buildIndex
        self:ClearTree()
        self.empty:Hide()

        local data = PvPIdiot.DB:GetCurrentSpecData()
        local specID = PvPIdiot.config and PvPIdiot.config.selectedSpecID
        if not data or not specID then
            self:SetUnavailable("nodes")
            return
        end

        local model, reason = BuildModel(specID, kind, data, buildIndex)
        if not model then
            self:SetUnavailable(reason)
            return
        end
        self.model = model

        if model.title then
            self.subtreeTitle:SetText(model.title)
            self.subtreeTitle:Show()
        else
            self.subtreeTitle:Hide()
        end

        local minX, maxX, minY, maxY
        for _, node in ipairs(model.nodes) do
            local x = tonumber(node.info.posX) or 0
            local y = tonumber(node.info.posY) or 0
            minX = not minX and x or math.min(minX, x)
            maxX = not maxX and x or math.max(maxX, x)
            minY = not minY and y or math.min(minY, y)
            maxY = not maxY and y or math.max(maxY, y)
        end

        local width = math.max(280, self:GetWidth())
        local height = math.max(360, self:GetHeight())
        local usableWidth = math.max(1, width - TREE_PADDING * 2)
        local usableHeight = math.max(1, height - TREE_PADDING * 2 - 18)
        local spanX = math.max(1, (maxX or 1) - (minX or 0))
        local spanY = math.max(1, (maxY or 1) - (minY or 0))

        for index, node in ipairs(model.nodes) do
            local button = AcquireNode(index)
            button.node = node
            node.button = button

            local x = TREE_PADDING + (((node.info.posX or minX) - minX) / spanX) * usableWidth
            local y = TREE_PADDING + 18 + (((node.info.posY or minY) - minY) / spanY) * usableHeight
            button:ClearAllPoints()
            button:SetPoint("CENTER", self, "TOPLEFT", x, -y)

            local entry = node.displayEntry
            button.icon:SetTexture(entry and entry.icon or 134400)
            button.choice:SetShown((node.info.type == 2) or (#node.entries > 1))
            button.usage:SetText(node.usage ~= nil and string.format("%.0f%%", node.usage * 100) or "")

            if node.selected then
                button:SetBackdropColor(0.13, 0.095, 0.035, 0.98)
                button:SetBackdropBorderColor(0.86, 0.58, 0.18, 1)
                button.icon:SetDesaturated(false)
                button.icon:SetAlpha(1)
                button.selectedGlow:Show()
                button.usage:SetTextColor(0.95, 0.71, 0.25)
            else
                button:SetBackdropColor(0.045, 0.055, 0.07, 0.96)
                button:SetBackdropBorderColor(0.24, 0.27, 0.31, 1)
                button.icon:SetDesaturated(true)
                button.icon:SetAlpha(0.52)
                button.selectedGlow:Hide()
                button.usage:SetTextColor(0.56, 0.59, 0.64)
            end
            button:Show()
        end

        local lineIndex = 1
        for _, node in ipairs(model.nodes) do
            for _, edge in ipairs(node.info.visibleEdges or {}) do
                local target = model.byID[edge.targetNode]
                if target and node.button and target.button then
                    local line = AcquireLine(lineIndex)
                    if line then
                        line:ClearAllPoints()
                        line:SetStartPoint("CENTER", node.button, 0, 0)
                        line:SetEndPoint("CENTER", target.button, 0, 0)
                        if node.selected and target.selected then
                            line:SetColorTexture(0.82, 0.56, 0.18, 0.88)
                            line:SetThickness(2.5)
                        else
                            line:SetColorTexture(0.20, 0.23, 0.28, 0.72)
                            line:SetThickness(2)
                        end
                        line:Show()
                        lineIndex = lineIndex + 1
                    end
                end
            end
        end

        for i = lineIndex, #self.linePool do
            self.linePool[i]:Hide()
        end
    end

    view:SetScript("OnSizeChanged", function(self)
        if self:IsShown() and self.kind then
            self:Refresh(self.kind, self.buildIndex)
        end
    end)

    return view
end
