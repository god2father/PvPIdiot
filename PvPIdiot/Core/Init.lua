local ADDON_NAME, PvPIdiot = ...

PvPIdiot.name = ADDON_NAME
PvPIdiot.version = "0.2.1"
PvPIdiot.modules = PvPIdiot.modules or {}
PvPIdiot.widgets = PvPIdiot.widgets or {}
PvPIdiot.ui = PvPIdiot.ui or {}
PvPIdiot.locale = PvPIdiot.locale or {}
PvPIdiot.events = PvPIdiot.events or {}

local eventFrame = CreateFrame("Frame")
PvPIdiot.eventFrame = eventFrame

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local handler = PvPIdiot.events[event]
    if handler then
        handler(PvPIdiot, ...)
    end
end)

function PvPIdiot:RegisterEvent(event, handler)
    self.events[event] = handler
    eventFrame:RegisterEvent(event)
end

function PvPIdiot:L(key)
    local clientLocale = GetLocale and GetLocale() or "enUS"
    local localeTable = self.locale[clientLocale] or self.locale.enUS or {}
    return localeTable[key] or (self.locale.enUS and self.locale.enUS[key]) or key
end

SLASH_PVPIDIOT1 = "/pvpi"
SLASH_PVPIDIOT2 = "/pvpidiot"
SlashCmdList.PVPIDIOT = function()
    if PvPIdiot.ui.mainFrame then
        PvPIdiot:ToggleMainFrame()
    end
end
