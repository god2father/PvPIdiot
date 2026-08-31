local ADDON_NAME, PvPIdiot = ...

local function CreateBackdropFrame(parent)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    return frame
end

function PvPIdiot:ImportBuild(build)
    if not build or not build.talentString then
        UIErrorsFrame:AddMessage(self:L("IMPORT_FAILED"), 1, 0.25, 0.25)
        return
    end

    if InCombatLockdown and InCombatLockdown() then
        UIErrorsFrame:AddMessage(self:L("COMBAT_IMPORT"), 1, 0.25, 0.25)
        return
    end

    if build.talentString:match("^MOCK") then
        UIErrorsFrame:AddMessage(self:L("MOCK_IMPORT"), 1, 0.82, 0.2)
        return
    end

    local specMeta = self.DB:GetCurrentSpecMeta()
    local specName = specMeta and specMeta.specName or "PvP"
    local ok = pcall(function()
        if C_AddOns and C_AddOns.LoadAddOn and not PlayerSpellsFrame then
            C_AddOns.LoadAddOn("Blizzard_PlayerSpells")
        elseif LoadAddOn and not PlayerSpellsFrame then
            LoadAddOn("Blizzard_PlayerSpells")
        end

        if PlayerSpellsFrame then
            PlayerSpellsFrame:Show()
            if PlayerSpellsFrame.SetTab and PlayerSpellsFrame.talentTabID then
                PlayerSpellsFrame:SetTab(PlayerSpellsFrame.talentTabID)
            end
            if PlayerSpellsFrame.TalentsFrame and PlayerSpellsFrame.TalentsFrame.ImportLoadout then
                PlayerSpellsFrame.TalentsFrame:ImportLoadout(
                    build.talentString,
                    "PvP Idiot - " .. specName .. " - Solo"
                )
                return
            end
        end
        error("Talent import UI unavailable")
    end)

    if not ok then
        UIErrorsFrame:AddMessage(self:L("IMPORT_FAILED"), 1, 0.25, 0.25)
    end
end

function PvPIdiot:CreateMainFrame()
    if self.ui.mainFrame then return self.ui.mainFrame end

    local frame = CreateBackdropFrame(UIParent)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdropColor(0.025, 0.035, 0.055, 0.98)
    frame:SetBackdropBorderColor(0.53, 0.38, 0.14, 1)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    if frame.SetResizeBounds then
        frame:SetResizeBounds(900, 600, 1400, 900)
    end
    frame:Hide()
    self.ui.mainFrame = frame

    local header = CreateBackdropFrame(frame)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(54)
    header:SetBackdropColor(0.035, 0.05, 0.075, 1)
    header:SetBackdropBorderColor(0.16, 0.18, 0.22, 1)
    frame.header = header

    local logo = header:CreateTexture(nil, "ARTWORK")
    logo:SetSize(32, 32)
    logo:SetPoint("LEFT", 14, 0)
    logo:SetTexture("Interface\\Icons\\Achievement_Arena_2v2_7")

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", logo, "RIGHT", 10, 5)
    title:SetText(self:L("TITLE"))
    title:SetTextColor(0.95, 0.71, 0.25)

    local version = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    version:SetPoint("LEFT", logo, "RIGHT", 10, -12)
    version:SetText("v" .. self.version)
    version:SetTextColor(0.55, 0.58, 0.64)

    local metadata = self.DB:GetMetadata()
    local dataText = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dataText:SetPoint("RIGHT", -48, 0)
    dataText:SetText(self:L("DATA") .. ": " .. self.Utils:FormatDate(metadata.updatedAt))
    dataText:SetTextColor(0.68, 0.70, 0.76)
    frame.dataText = dataText

    local sourceBadge = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sourceBadge:SetPoint("RIGHT", dataText, "LEFT", -12, 0)
    if metadata.isMock then
        sourceBadge:SetText(self:L("MOCK_DATA"))
        sourceBadge:SetTextColor(1, 0.55, 0.15)
    elseif metadata.source == "murlok.io" then
        sourceBadge:SetText("Murlok Snapshot")
        sourceBadge:SetTextColor(0.95, 0.71, 0.25)
    else
        sourceBadge:SetText("")
    end
    frame.sourceBadge = sourceBadge
    frame.mockBadge = sourceBadge -- compatibility with the original v0.1 field name

    local close = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    close:SetPoint("RIGHT", -4, 0)
    close:SetScript("OnClick", function() frame:Hide() end)

    local sidebar = CreateBackdropFrame(frame)
    sidebar:SetPoint("TOPLEFT", 10, -102)
    sidebar:SetPoint("BOTTOMLEFT", 10, 10)
    sidebar:SetWidth(210)
    sidebar:SetBackdropColor(0.035, 0.045, 0.065, 0.95)
    sidebar:SetBackdropBorderColor(0.16, 0.18, 0.22, 1)
    frame.sidebar = sidebar

    local content = CreateBackdropFrame(frame)
    content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 10, 0)
    content:SetPoint("BOTTOMRIGHT", -10, 10)
    content:SetBackdropColor(0.027, 0.036, 0.052, 0.90)
    content:SetBackdropBorderColor(0.16, 0.18, 0.22, 1)
    frame.content = content

    local resize = CreateFrame("Button", nil, frame)
    resize:SetSize(20, 20)
    resize:SetPoint("BOTTOMRIGHT", -2, 2)
    resize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resize:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resize:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resize:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then frame:StartSizing("BOTTOMRIGHT") end
    end)
    resize:SetScript("OnMouseUp", function() frame:StopMovingOrSizing(); self:SaveFrameState(frame) end)

    frame:SetScript("OnDragStart", function(f) f:StartMoving() end)
    frame:SetScript("OnDragStop", function(f) f:StopMovingOrSizing(); self:SaveFrameState(f) end)
    frame:SetScript("OnSizeChanged", function(f)
        if self.config then
            self.config.width = math.floor(f:GetWidth() + 0.5)
            self.config.height = math.floor(f:GetHeight() + 0.5)
        end
    end)
    frame:SetScript("OnHide", function(f) self:SaveFrameState(f) end)

    self:RestoreFrameState(frame)
    self:CreateSidebar(sidebar)
    self:CreateTabs(frame)
    return frame
end

function PvPIdiot:ToggleMainFrame()
    local frame = self.ui.mainFrame or self:CreateMainFrame()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        self:RefreshUI()
    end
end

function PvPIdiot:RefreshUI()
    if self.RefreshSidebar then self:RefreshSidebar() end
    if self.ShowTab then self:ShowTab((self.config and self.config.selectedTab) or "overview") end
end

PvPIdiot:RegisterEvent("ADDON_LOADED", function(self, loadedName)
    if loadedName ~= ADDON_NAME then return end
    self:InitializeConfig()
    self:CreateMainFrame()
end)

PvPIdiot:RegisterEvent("PLAYER_LOGIN", function(self)
    if self:SyncSelectedSpecToPlayer() then
        self:RefreshUI()
    end
end)

PvPIdiot:RegisterEvent("PLAYER_ENTERING_WORLD", function(self)
    if self:SyncSelectedSpecToPlayer() then
        self:RefreshUI()
    end
end)

PvPIdiot:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(self, unit)
    if unit ~= "player" then return end
    if self:SyncSelectedSpecToPlayer() then
        self:RefreshUI()
    end
end)
