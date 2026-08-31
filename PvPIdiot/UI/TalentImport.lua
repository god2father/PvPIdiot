local ADDON_NAME, PvPIdiot = ...

local function LoadTalentUI()
    if PlayerSpellsFrame then return true end

    local function TryLoad(name)
        if C_AddOns and C_AddOns.LoadAddOn then
            return pcall(C_AddOns.LoadAddOn, name)
        elseif UIParentLoadAddOn then
            return pcall(UIParentLoadAddOn, name)
        elseif LoadAddOn then
            return pcall(LoadAddOn, name)
        end
        return false
    end

    TryLoad("Blizzard_ClassTalentUI")
    TryLoad("Blizzard_PlayerSpells")
    return PlayerSpellsFrame ~= nil
end

function PvPIdiot:OpenTalentPanel()
    if InCombatLockdown and InCombatLockdown() then
        UIErrorsFrame:AddMessage(self:L("COMBAT_IMPORT"), 1, 0.25, 0.25)
        return false
    end

    if not LoadTalentUI() or not PlayerSpellsFrame then
        UIErrorsFrame:AddMessage(self:L("IMPORT_FAILED"), 1, 0.25, 0.25)
        return false
    end

    PlayerSpellsFrame:Show()
    if PlayerSpellsFrame.SetTab and PlayerSpellsFrame.talentTabID then
        pcall(PlayerSpellsFrame.SetTab, PlayerSpellsFrame, PlayerSpellsFrame.talentTabID)
    end
    return true
end

local function FillImportDialog(talentString, loadoutName)
    local dialog = ClassTalentLoadoutImportDialog
    if not dialog or not dialog.ShowDialog then return false end

    local ok = pcall(dialog.ShowDialog, dialog)
    if not ok then return false end

    local importBox = dialog.ImportControl
        and dialog.ImportControl.InputContainer
        and dialog.ImportControl.InputContainer.EditBox
    local nameBox = dialog.NameControl and dialog.NameControl.EditBox

    if not importBox then return false end
    importBox:SetText(talentString)
    if nameBox then nameBox:SetText(loadoutName) end
    return true
end

function PvPIdiot:ImportBuild(build)
    if not build or not build.talentString or build.talentString == "" then
        UIErrorsFrame:AddMessage(self:L("IMPORT_FAILED"), 1, 0.25, 0.25)
        return false
    end

    if InCombatLockdown and InCombatLockdown() then
        UIErrorsFrame:AddMessage(self:L("COMBAT_IMPORT"), 1, 0.25, 0.25)
        return false
    end

    if build.talentString:match("^MOCK") then
        UIErrorsFrame:AddMessage(self:L("MOCK_IMPORT"), 1, 0.82, 0.2)
        return false
    end

    if not self:OpenTalentPanel() then return false end

    local specMeta = self.DB:GetCurrentSpecMeta()
    local specName = specMeta and (specMeta.specName or specMeta.specSlug) or "PvP"
    local loadoutName = "PvP Idiot - " .. tostring(specName) .. " - Solo"
    local talentsFrame = PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame

    -- Match the Blizzard/GearInsight style flow: import the build into the
    -- talent UI, then leave the protected final "Apply Changes" click to the
    -- player. ImportLoadout is Blizzard's own ClassTalentImportExportMixin API.
    if talentsFrame and talentsFrame.ImportLoadout then
        local ok, result = pcall(talentsFrame.ImportLoadout, talentsFrame, build.talentString, loadoutName)
        if ok and result ~= false then
            UIErrorsFrame:AddMessage(self:L("IMPORT_OPENED"), 0.35, 0.90, 0.45)
            return true
        end
    end

    -- API/layout names can move between Retail patches. If direct staging is
    -- unavailable, fall back to Blizzard's import dialog and pre-fill both the
    -- build string and loadout name instead of failing silently.
    if FillImportDialog(build.talentString, loadoutName) then
        UIErrorsFrame:AddMessage(self:L("IMPORT_OPENED"), 0.95, 0.71, 0.25)
        return true
    end

    UIErrorsFrame:AddMessage(self:L("IMPORT_FAILED"), 1, 0.25, 0.25)
    return false
end
