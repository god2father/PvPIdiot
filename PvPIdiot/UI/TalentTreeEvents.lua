local ADDON_NAME, PvPIdiot = ...

local function RefreshTalentTree(self)
    if self.Utils and self.Utils.ClearTraitLookupCache then
        self.Utils:ClearTraitLookupCache()
    end
    local page = self.ui and self.ui.pages and self.ui.pages.talents
    if page and self.config and self.config.selectedTab == "talents" and page.Refresh then
        page:Refresh()
    end
end

PvPIdiot:RegisterEvent("TRAIT_CONFIG_LIST_UPDATED", function(self)
    RefreshTalentTree(self)
end)

PvPIdiot:RegisterEvent("TRAIT_TREE_CHANGED", function(self)
    RefreshTalentTree(self)
end)

PvPIdiot:RegisterEvent("TRAIT_SUB_TREE_CHANGED", function(self)
    RefreshTalentTree(self)
end)

PvPIdiot:RegisterEvent("ACTIVE_COMBAT_CONFIG_CHANGED", function(self)
    RefreshTalentTree(self)
end)
