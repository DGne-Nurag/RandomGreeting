-- ==========================================================
-- RandomGreeting - Client compatibility layer (Compat.lua)
-- Hides API differences between the supported clients:
--   * Classic Era / Hardcore (1.15.x)
--   * TBC Anniversary (2.5.x)
--   * WoW Forever (1.60.x, runs on the modern game client / Midnight API)
-- Loaded right after the locale setup (see .toc order).
-- ==========================================================

RG_Compat = {}

-- ----------------------------------------------------------
-- Chat sending
-- ----------------------------------------------------------
-- The modern client moved SendChatMessage into C_ChatInfo and may lock
-- addon chat messages during encounters (chat messaging lockdown).

local SendChat = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage

--- Sends a chat message on any supported client.
--- Returns true if the message was handed to the client, false if chat
--- is currently locked for addons.
function RG_Compat.SendChatMessage(text, chatType, language, target)
    if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown
        and C_ChatInfo.InChatMessagingLockdown() then
        print("|cffff0000RandomGreeting:|r "
            .. (RG_L["ERR_CHAT_LOCKDOWN"] or "Chat messages are currently blocked for addons."))
        return false
    end
    SendChat(text, chatType, language, target)
    return true
end

-- ----------------------------------------------------------
-- Dropdowns
-- ----------------------------------------------------------
-- Uses the classic UIDropDownMenu when available (all current clients).
-- Falls back to the modern Menu API (MenuUtil) if UIDropDownMenu is ever
-- removed from the modern client.
--
-- getEntries() must return a list of { text = ..., checked = bool, func = fn }.

local HAS_UIDROPDOWN = UIDropDownMenu_Initialize ~= nil and UIDropDownMenu_AddButton ~= nil

function RG_Compat.CreateDropdown(parent, name, width, getEntries)
    if HAS_UIDROPDOWN then
        local dd = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
        UIDropDownMenu_SetWidth(dd, width)
        UIDropDownMenu_Initialize(dd, function(_, level)
            for _, entry in ipairs(getEntries()) do
                local info   = UIDropDownMenu_CreateInfo and UIDropDownMenu_CreateInfo() or {}
                info.text    = entry.text
                info.checked = entry.checked
                info.func    = function()
                    entry.func()
                    CloseDropDownMenus()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)
        return dd
    end

    -- Fallback: container mimicking the UIDropDownMenuTemplate footprint
    -- (16 px left inset), so existing anchors still line up.
    local dd = CreateFrame("Frame", name, parent)
    dd:SetSize(width + 32, 32)
    local btn = CreateFrame("Button", nil, dd, "UIPanelButtonTemplate")
    btn:SetSize(width, 22)
    btn:SetPoint("LEFT", 16, 0)
    btn:SetScript("OnClick", function(self)
        MenuUtil.CreateContextMenu(self, function(_, root)
            for _, entry in ipairs(getEntries()) do
                root:CreateRadio(entry.text,
                    function() return entry.checked end,
                    function() entry.func() end)
            end
        end)
    end)
    dd.button = btn
    return dd
end

function RG_Compat.SetDropdownText(dd, text)
    if not dd then return end
    if dd.button then
        dd.button:SetText(text)
    else
        UIDropDownMenu_SetText(dd, text)
    end
end
