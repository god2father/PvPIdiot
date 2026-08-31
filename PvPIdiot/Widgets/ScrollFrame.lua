local ADDON_NAME, PvPIdiot = ...

function PvPIdiot:CreateScrollableContainer(parent, minimumHeight)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetAllPoints()
    scrollFrame:EnableMouseWheel(true)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, minimumHeight or 1)
    scrollFrame:SetScrollChild(content)

    local function UpdateContentSize()
        local width = math.max(1, scrollFrame:GetWidth() - 18)
        local height = math.max(scrollFrame:GetHeight(), minimumHeight or 1)
        content:SetSize(width, height)

        local maxScroll = math.max(0, height - scrollFrame:GetHeight())
        scrollFrame:SetVerticalScroll(math.min(scrollFrame:GetVerticalScroll(), maxScroll))
    end

    scrollFrame:SetScript("OnSizeChanged", UpdateContentSize)
    function scrollFrame:SetMinimumHeight(value)
        minimumHeight = value or 1
        UpdateContentSize()
    end
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local step = 40
        local maxScroll = math.max(0, content:GetHeight() - self:GetHeight())
        local nextScroll = math.max(0, math.min(maxScroll, self:GetVerticalScroll() - delta * step))
        self:SetVerticalScroll(nextScroll)
    end)
    UpdateContentSize()

    return scrollFrame, content
end
