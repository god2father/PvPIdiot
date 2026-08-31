local ADDON_NAME, PvPIdiot = ...

function PvPIdiot:CreateDropdown(parent, labelText, valueText)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(180, 48)

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT")
    label:SetText(labelText or "")
    label:SetTextColor(0.58, 0.61, 0.67)
    frame.label = label

    local box = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    box:SetPoint("TOPLEFT", 0, -16)
    box:SetPoint("RIGHT", 0, 0)
    box:SetHeight(28)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    box:SetBackdropColor(0.045, 0.055, 0.075, 1)
    box:SetBackdropBorderColor(0.22, 0.24, 0.28, 1)
    frame.box = box

    local value = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    value:SetPoint("LEFT", 8, 0)
    value:SetPoint("RIGHT", -8, 0)
    value:SetJustifyH("LEFT")
    value:SetText(valueText or "")
    frame.value = value

    function frame:SetValue(text)
        self.value:SetText(text or "")
    end

    return frame
end
