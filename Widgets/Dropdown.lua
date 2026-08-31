local ADDON_NAME, PvPIdiot = ...

function PvPIdiot:CreateDropdown(parent, labelText, valueText)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(180, 48)

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT")
    label:SetText(labelText or "")
    label:SetTextColor(0.58, 0.61, 0.67)
    frame.label = label

    local box = CreateFrame("Button", nil, frame, "BackdropTemplate")
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
    value:SetPoint("RIGHT", -22, 0)
    value:SetJustifyH("LEFT")
    value:SetText(valueText or "")
    frame.value = value

    local arrow = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    arrow:SetPoint("RIGHT", -7, 0)
    arrow:SetText("▾")
    arrow:SetTextColor(0.65, 0.67, 0.72)
    frame.arrow = arrow

    function frame:SetValue(text)
        self.value:SetText(text or "")
    end

    function frame:SetEnabled(enabled)
        self.enabled = enabled ~= false
        self.box:EnableMouse(self.enabled)
        self.arrow:SetShown(self.enabled)
        self.box:SetBackdropBorderColor(
            self.enabled and 0.22 or 0.14,
            self.enabled and 0.24 or 0.15,
            self.enabled and 0.28 or 0.18,
            1
        )
    end

    function frame:SetOptions(options, onSelect)
        self.options = options or {}
        self.onSelect = onSelect
        self:SetEnabled(#self.options > 0)
    end

    local function SelectOption(option)
        if not option then return end
        frame:SetValue(option.text or option.label or tostring(option.value or ""))
        if frame.onSelect then frame.onSelect(option) end
    end

    box:SetScript("OnEnter", function(self)
        if frame.enabled ~= false then
            self:SetBackdropBorderColor(0.55, 0.40, 0.16, 1)
        end
    end)
    box:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.22, 0.24, 0.28, 1)
    end)
    box:SetScript("OnClick", function()
        if frame.enabled == false or not frame.options or #frame.options == 0 then return end

        if MenuUtil and MenuUtil.CreateContextMenu then
            MenuUtil.CreateContextMenu(box, function(_, rootDescription)
                for _, option in ipairs(frame.options) do
                    local current = option
                    rootDescription:CreateButton(
                        current.text or current.label or tostring(current.value or ""),
                        function() SelectOption(current) end
                    )
                end
            end)
            return
        end

        -- Safe fallback for clients where the modern menu API is unavailable:
        -- clicking cycles through the available values.
        local currentText = frame.value:GetText()
        local nextIndex = 1
        for i, option in ipairs(frame.options) do
            local text = option.text or option.label or tostring(option.value or "")
            if text == currentText then
                nextIndex = (i % #frame.options) + 1
                break
            end
        end
        SelectOption(frame.options[nextIndex])
    end)

    frame:SetEnabled(false)
    return frame
end
