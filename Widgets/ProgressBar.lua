local ADDON_NAME, PvPIdiot = ...

function PvPIdiot:CreateProgressBar(parent, width, height)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(width or 220, height or 16)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    bar:SetStatusBarColor(0.76, 0.51, 0.16, 0.95)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.08, 0.10, 0.13, 1)
    bar.bg = bg

    local border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    border:SetAllPoints()
    border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    border:SetBackdropBorderColor(0.28, 0.30, 0.33, 1)
    bar.border = border

    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER")
    text:SetText("0%")
    bar.text = text

    function bar:SetPercent(value, label)
        value = PvPIdiot.Utils:Clamp(tonumber(value) or 0, 0, 1)
        self:SetValue(value)
        self.text:SetText(label or PvPIdiot.Utils:FormatPercent(value, 1))
    end

    return bar
end
