local ADDON_NAME, PvPIdiot = ...

local TAB_DEFS = {
    { id = "overview", label = "OVERVIEW" },
    { id = "talents", label = "TALENTS" },
    { id = "gear", label = "GEAR" },
    { id = "gems", label = "GEMS_ENCHANTS" },
    { id = "stats", label = "STATS" },
}

local PAGE_MIN_HEIGHTS = {
    overview = 560,
    talents = 620,
    gear = 560,
    gems = 390,
    stats = 340,
}

function PvPIdiot:CreateTabs(frame)
    local tabBar = CreateFrame("Frame", nil, frame)
    tabBar:SetPoint("TOPLEFT", 10, -62)
    tabBar:SetPoint("TOPRIGHT", -10, -62)
    tabBar:SetHeight(32)
    self.ui.tabBar = tabBar
    self.ui.tabButtons = {}
    self.ui.pages = {}
    self.ui.pageContainers = {}

    local previous
    for _, def in ipairs(TAB_DEFS) do
        local button = CreateFrame("Button", nil, tabBar, "BackdropTemplate")
        button:SetSize(def.id == "gems" and 145 or 112, 30)
        if previous then
            button:SetPoint("LEFT", previous, "RIGHT", 6, 0)
        else
            button:SetPoint("LEFT", 0, 0)
        end
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })

        local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER")
        text:SetText(self:L(def.label))
        button.text = text
        button.tabID = def.id
        button:SetScript("OnClick", function() self:ShowTab(def.id) end)
        self.ui.tabButtons[def.id] = button
        previous = button
    end

    local function CreateScrollablePage(id, createPage)
        local container, content = self:CreateScrollableContainer(frame.content, PAGE_MIN_HEIGHTS[id])
        self.ui.pageContainers[id] = container
        self.ui.pages[id] = createPage(self, content)
    end

    CreateScrollablePage("overview", self.CreateOverviewPage)
    CreateScrollablePage("talents", self.CreateTalentsPage)
    CreateScrollablePage("gear", self.CreateGearPage)
    CreateScrollablePage("gems", self.CreateGemsEnchantsPage)
    CreateScrollablePage("stats", self.CreateStatsPage)

    local noData = frame.content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    noData:SetPoint("CENTER")
    noData:SetText(self:L("NO_DATA"))
    noData:SetTextColor(0.72, 0.72, 0.76)
    noData:Hide()
    self.ui.noDataText = noData

    self:ShowTab((self.config and self.config.selectedTab) or "overview")
end

function PvPIdiot:ShowTab(tabID)
    if not self.ui.pages or not self.ui.pages[tabID] then tabID = "overview" end
    local data = self.DB:GetCurrentSpecData()
    local hasData = data ~= nil and (not data.meta or data.meta.dataAvailable ~= false)

    for id, container in pairs(self.ui.pageContainers or {}) do
        container:SetShown(hasData and id == tabID)
    end
    if self.ui.noDataText then self.ui.noDataText:SetShown(not hasData) end

    for id, button in pairs(self.ui.tabButtons or {}) do
        if id == tabID then
            button:SetBackdropColor(0.10, 0.085, 0.055, 1)
            button:SetBackdropBorderColor(0.76, 0.51, 0.16, 1)
            button.text:SetTextColor(0.95, 0.71, 0.25)
        else
            button:SetBackdropColor(0.05, 0.06, 0.08, 1)
            button:SetBackdropBorderColor(0.20, 0.22, 0.25, 1)
            button.text:SetTextColor(0.70, 0.72, 0.76)
        end
    end

    if self.config then self.config.selectedTab = tabID end
    local page = self.ui.pages[tabID]
    if hasData and page and page.Refresh then page:Refresh() end
end
