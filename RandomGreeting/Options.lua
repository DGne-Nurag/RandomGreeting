-- ==========================================================
-- RandomGreeting – Options Panel (Options.lua)
-- Adds a panel under Interface > AddOns > RandomGreeting.
-- Loaded AFTER RandomGreeting.lua (see .toc order).
--
-- Features:
--   * Language selector (Auto / English / Deutsch)
--   * Per-list Import & Export buttons
--   * Scrollable message list with single-entry delete
-- ==========================================================

local ADDON_NAME = "RandomGreeting"
local MAX_ROWS   = 30   -- upper cap; actual visible count is computed from frame height
local ROW_HEIGHT = 18

-- Upvalues set once the panel is built
local listScrollFrame = nil
local listRows        = {}
local selectedListKey = "HI"

-- ----------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------

local function GetListLabel(key)
    local db = RandomGreetingDB
    if     key == "HI"      then return "/rhi  –  "      .. (RG_L["LABEL_HI"]    or "Greeting")
    elseif key == "BYE"     then return "/rbye  –  "     .. (RG_L["LABEL_BYE"]   or "Farewell")
    elseif key == "CUSTOM1" then return "/rcustom1  –  " .. (db.custom1Label      or RG_L["LABEL_CUSTOM1"] or "Custom1")
    elseif key == "CUSTOM2" then return "/rcustom2  –  " .. (db.custom2Label      or RG_L["LABEL_CUSTOM2"] or "Custom2")
    end
    return key
end

local LANG_ENTRIES = {
    { value = "auto", key = "OPT_LANG_AUTO", fallback = "Auto (client language)" },
    { value = "enUS", key = "OPT_LANG_ENUS", fallback = "English"                },
    { value = "deDE", key = "OPT_LANG_DEDE", fallback = "Deutsch"                },
}

local function GetLangText(val)
    for _, e in ipairs(LANG_ENTRIES) do
        if e.value == val then return RG_L[e.key] or e.fallback end
    end
    return "Auto"
end

-- ----------------------------------------------------------
-- Refresh the scrollable message list
-- ----------------------------------------------------------

local function RefreshListRows()
    if not listScrollFrame then return end
    local msgs = RG_Internal.GetListByKey(selectedListKey) or {}
    local total  = #msgs
    local offset = listScrollFrame.offset or 0

    -- Compute how many rows actually fit the current frame height
    local sfH        = listScrollFrame:GetHeight()
    local visibleRows = (sfH and sfH > 0)
        and math.max(1, math.floor(sfH / ROW_HEIGHT))
        or 12

    for i = 1, MAX_ROWS do
        local row    = listRows[i]
        if not row then break end
        local msgIdx = offset + i
        if i <= visibleRows and msgIdx <= total then
            local text = msgs[msgIdx]
            row.label:SetText(text)
            row.deleteBtn.msgIdx = msgIdx
            row.fullText = text
            row:Show()
        else
            row.fullText = nil
            row:Hide()
        end
    end

    FauxScrollFrame_Update(listScrollFrame, total, visibleRows, ROW_HEIGHT)
end

-- Exposed so RandomGreeting.lua can call after a successful import
RG_Internal.RefreshOptionsPanel = RefreshListRows

-- ----------------------------------------------------------
-- Copy-URL dialog (for the Import Generator link)
-- ----------------------------------------------------------
local RG_URLDialog = nil
local function ShowURLDialog(url, title)
    if not RG_URLDialog then
        local f = CreateFrame("Frame", "RGURLDialog", UIParent, "BackdropTemplate")
        f:SetSize(480, 110)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:EnableMouse(true)
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self) self:StartMoving() end)
        f:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)
        f:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
        f:Hide()
        local titleBg = f:CreateTexture(nil, "ARTWORK")
        titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
        titleBg:SetWidth(480); titleBg:SetHeight(64)
        titleBg:SetPoint("TOP", 0, 12)
        local titleText = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        titleText:SetPoint("TOP", titleBg, "TOP", 0, -14)
        titleText:SetWidth(460); titleText:SetJustifyH("CENTER")
        f.titleText = titleText
        local eb = CreateFrame("EditBox", "RGURLDialogEB", f, "InputBoxTemplate")
        eb:SetSize(440, 20)
        eb:SetPoint("CENTER", 0, 0)
        eb:SetAutoFocus(false)
        eb:SetMaxLetters(0)
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        f.editBox = eb
        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", 4, 4)
        closeBtn:SetScript("OnClick", function() f:Hide() end)
        RG_URLDialog = f
    end
    RG_URLDialog.titleText:SetText(title or "URL")
    RG_URLDialog.editBox:SetText(url or "")
    RG_URLDialog:Show()
    RG_URLDialog.editBox:SetFocus()
    RG_URLDialog.editBox:HighlightText()
end

-- ----------------------------------------------------------
-- Build the panel (called once at ADDON_LOADED)
-- ----------------------------------------------------------

local function BuildOptionsPanel()
    local panel = CreateFrame("Frame", "RGOptionsPanel", UIParent)
    panel.name  = ADDON_NAME

    -- Vorwärts-Deklaration: wird nach dem Aufbau aller UI-Elemente befüllt
    local RefreshPanelTexts

    ---------- Title ----------
    local titleFS = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    titleFS:SetPoint("TOPLEFT", 16, -16)
    titleFS:SetText(RG_L["OPT_TITLE"] or ADDON_NAME)

    local versionFS = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    versionFS:SetPoint("TOPLEFT", titleFS, "BOTTOMLEFT", 0, -4)
    versionFS:SetText("v" .. ((C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)(ADDON_NAME, "Version") or "?"))

    ---------- Language dropdown ----------
    local langLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    langLabel:SetPoint("TOPLEFT", versionFS, "BOTTOMLEFT", 0, -12)
    langLabel:SetText(RG_L["OPT_LANG_LABEL"] or "Language:")

    local langDD = CreateFrame("Frame", "RGOptionsLangDD", panel, "UIDropDownMenuTemplate")
    langDD:SetPoint("TOPLEFT", langLabel, "BOTTOMLEFT", -15, -4)
    UIDropDownMenu_SetWidth(langDD, 240)

    local function InitLangDD(_, level)
        local curVal = RandomGreetingDB and (RandomGreetingDB.locale or "auto") or "auto"
        for _, entry in ipairs(LANG_ENTRIES) do
            local info   = {}
            info.text    = RG_L[entry.key] or entry.fallback
            info.value   = entry.value
            info.checked = curVal == entry.value
            info.func    = function(btn)
                local val = btn.value
                RandomGreetingDB.locale = val
                local eff = (val == "auto")
                    and ((GetLocale() == "deDE") and "deDE" or "enUS")
                    or val
                RG_Internal.ApplyLocale(eff)
                UIDropDownMenu_SetText(langDD, GetLangText(val))
                CloseDropDownMenus()
                if RefreshPanelTexts then RefreshPanelTexts() end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end
    UIDropDownMenu_Initialize(langDD, InitLangDD)
    UIDropDownMenu_SetText(langDD, GetLangText(
        RandomGreetingDB and (RandomGreetingDB.locale or "auto") or "auto"
    ))
    panel.langDD = langDD

    ---------- Language reset button ----------
    local langResetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    langResetBtn:SetSize(155, 26)
    langResetBtn:SetPoint("LEFT", langDD, "RIGHT", 4, 2)
    langResetBtn:SetText(RG_L["OPT_RESET_BTN"] or "Reset Lists")
    langResetBtn:SetScript("OnClick", function()
        local db   = RandomGreetingDB
        -- Aktive Sprache ermitteln
        local loc  = db.locale or "auto"
        local lang = (loc == "auto")
            and ((GetLocale() == "deDE") and "deDE" or "enUS")
            or loc
        local defaults = RG_LOCALE_DEFAULTS and RG_LOCALE_DEFAULTS[lang]
        if defaults then
            if defaults.hi then
                wipe(db.hiMessages)
                for _, v in ipairs(defaults.hi)  do db.hiMessages[#db.hiMessages + 1] = v end
                db.hiPool = {}
            end
            if defaults.bye then
                wipe(db.byeMessages)
                for _, v in ipairs(defaults.bye) do db.byeMessages[#db.byeMessages + 1] = v end
                db.byePool = {}
            end
        end
        -- Listenansicht aktualisieren
        listScrollFrame.offset = 0
        listScrollFrame:SetVerticalScroll(0)
        RefreshListRows()
    end)
    langResetBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(RG_L["OPT_RESET_BTN"] or "Reset Lists", 1, 0.82, 0)
        GameTooltip:AddLine(RG_L["OPT_RESET_BTN_TT"] or "Resets Hi and Bye to language defaults:", 0.9, 0.9, 0.9, true)
        local loc  = RandomGreetingDB and (RandomGreetingDB.locale or "auto") or "auto"
        local lang = (loc == "auto") and ((GetLocale() == "deDE") and "deDE" or "enUS") or loc
        GameTooltip:AddDoubleLine(RG_L["LABEL_HI"]  or "Hi",  lang, 0.7,0.7,0.7, 1,1,1)
        GameTooltip:AddDoubleLine(RG_L["LABEL_BYE"] or "Bye", lang, 0.7,0.7,0.7, 1,1,1)
        GameTooltip:Show()
    end)
    langResetBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    ---------- Reset action window position ----------
    local awResetPosBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    awResetPosBtn:SetHeight(26)
    awResetPosBtn:SetPoint("LEFT",  langResetBtn, "RIGHT", 6,   0)
    awResetPosBtn:SetPoint("RIGHT", panel,         "RIGHT", -16, 0)
    awResetPosBtn:SetText(RG_L["OPT_RESET_POS_BTN"] or "Reset Window position")
    awResetPosBtn:SetScript("OnClick", function()
        RandomGreetingCharDB.actionWindowPos = false
        local f = _G["RGActionWindow"]
        if f then
            f:ClearAllPoints()
            f:SetPoint("CENTER", UIParent, "CENTER", 250, 0)
        end
    end)

    ---------- Aktionsfenster – Button-Sichtbarkeit ----------
    local awSectionLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    awSectionLabel:SetPoint("TOPLEFT", langDD, "BOTTOMLEFT", 15, -10)
    awSectionLabel:SetText(RG_L["OPT_AW_TITLE"] or "Action-Window:")

    -- Linke Spalte: HI (oben), BYE (unten)
    local awCbHI = CreateFrame("CheckButton", "RGAW_CB_HI", panel, "UICheckButtonTemplate")
    awCbHI:SetSize(24, 24)
    awCbHI:SetPoint("TOPLEFT", awSectionLabel, "BOTTOMLEFT", 0, -2)
    local awLblHI = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    awLblHI:SetPoint("LEFT", awCbHI, "RIGHT", 2, 0)
    awLblHI:SetWidth(120)
    awLblHI:SetText(RG_L["LABEL_HI"] or "Greeting")

    local awCbBYE = CreateFrame("CheckButton", "RGAW_CB_BYE", panel, "UICheckButtonTemplate")
    awCbBYE:SetSize(24, 24)
    awCbBYE:SetPoint("TOPLEFT", awCbHI, "BOTTOMLEFT", 0, -2)
    local awLblBYE = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    awLblBYE:SetPoint("LEFT", awCbBYE, "RIGHT", 2, 0)
    awLblBYE:SetWidth(120)
    awLblBYE:SetText(RG_L["LABEL_BYE"] or "Farewell")

    -- Rechte Spalte: CUSTOM1 (oben, gleiche Zeile wie HI), CUSTOM2 (unten)
    local awCbC1 = CreateFrame("CheckButton", "RGAW_CB_C1", panel, "UICheckButtonTemplate")
    awCbC1:SetSize(24, 24)
    awCbC1:SetPoint("TOPLEFT", awCbHI, "TOPLEFT", 165, 0)
    local awLblC1 = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    awLblC1:SetPoint("LEFT", awCbC1, "RIGHT", 2, 0)
    awLblC1:SetWidth(160)

    local awCbC2 = CreateFrame("CheckButton", "RGAW_CB_C2", panel, "UICheckButtonTemplate")
    awCbC2:SetSize(24, 24)
    awCbC2:SetPoint("TOPLEFT", awCbC1, "BOTTOMLEFT", 0, -2)
    local awLblC2 = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    awLblC2:SetPoint("LEFT", awCbC2, "RIGHT", 2, 0)
    awLblC2:SetWidth(160)

    local function SyncAWCheckbox(cb, key)
        cb:SetScript("OnClick", function(self)
            local db = RandomGreetingDB
            if not db.actionWindowButtons then
                db.actionWindowButtons = { HI = false, BYE = false, CUSTOM1 = false, CUSTOM2 = false }
            end
            db.actionWindowButtons[key] = (self:GetChecked() and true or false)
            if RG_Internal.RebuildActionWindow then RG_Internal.RebuildActionWindow() end
        end)
    end
    SyncAWCheckbox(awCbHI,  "HI")
    SyncAWCheckbox(awCbBYE, "BYE")
    SyncAWCheckbox(awCbC1,  "CUSTOM1")
    SyncAWCheckbox(awCbC2,  "CUSTOM2")

    ---------- Theme section ----------
    local appearLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    appearLabel:SetPoint("TOPLEFT", awCbBYE, "BOTTOMLEFT", 0, -10)
    appearLabel:SetText(RG_L["OPT_APPEARANCE_TITLE"] or "Window Design:")

    local THEME_ENTRIES = {
        { value = "wow",    key = "OPT_THEME_WOW",    fallback = "WoW (Classic)" },
        { value = "modern", key = "OPT_THEME_MODERN",  fallback = "Modern (dark)" },
    }
    local function GetThemeText(val)
        for _, e in ipairs(THEME_ENTRIES) do
            if e.value == val then return RG_L[e.key] or e.fallback end
        end
        return "WoW (Classic)"
    end

    local themeDD = CreateFrame("Frame", "RGOptionsThemeDD", panel, "UIDropDownMenuTemplate")
    themeDD:SetPoint("TOPLEFT", appearLabel, "BOTTOMLEFT", -15, -2)
    UIDropDownMenu_SetWidth(themeDD, 240)

    local function InitThemeDD(_, level)
        local curVal = (RandomGreetingCharDB and RandomGreetingCharDB.theme) or "wow"
        for _, entry in ipairs(THEME_ENTRIES) do
            local info   = {}
            info.text    = RG_L[entry.key] or entry.fallback
            info.value   = entry.value
            info.checked = curVal == entry.value
            info.func    = function(btn)
                RandomGreetingCharDB.theme = btn.value
                UIDropDownMenu_SetText(themeDD, GetThemeText(btn.value))
                CloseDropDownMenus()
                if RG_Internal.ApplyTheme then RG_Internal.ApplyTheme() end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end
    UIDropDownMenu_Initialize(themeDD, InitThemeDD)
    UIDropDownMenu_SetText(themeDD, GetThemeText((RandomGreetingCharDB and RandomGreetingCharDB.theme) or "wow"))

    -- Kompaktmodus-Checkbox (rechts neben Theme-Dropdown)
    local awCbCompact = CreateFrame("CheckButton", "RGAW_CB_COMPACT", panel, "UICheckButtonTemplate")
    awCbCompact:SetSize(24, 24)
    awCbCompact:SetPoint("LEFT", themeDD, "RIGHT", 4, 0)
    local awLblCompact = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    awLblCompact:SetPoint("LEFT", awCbCompact, "RIGHT", 2, 0)
    awLblCompact:SetText(RG_L["OPT_AW_COMPACT"] or "Compact mode")
    awCbCompact:SetScript("OnClick", function(self)
        RandomGreetingCharDB.actionWindowCompact = (self:GetChecked() and true or false)
        if RG_Internal.RebuildActionWindow then RG_Internal.RebuildActionWindow() end
    end)

    -- Minimap-Button ausblenden
    local cbMinimapHide = CreateFrame("CheckButton", "RG_CB_MINIMAP_HIDE", panel, "UICheckButtonTemplate")
    cbMinimapHide:SetSize(24, 24)
    cbMinimapHide:SetPoint("TOPLEFT", themeDD, "BOTTOMLEFT", 15, -4)
    local lblMinimapHide = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    lblMinimapHide:SetPoint("LEFT", cbMinimapHide, "RIGHT", 2, 0)
    lblMinimapHide:SetText(RG_L["OPT_MINIMAP_HIDE"] or "Minimap Button")
    cbMinimapHide:SetScript("OnClick", function(self)
        -- Checkbox checked = Button sichtbar, unchecked = ausgeblendet
        local visible = (self:GetChecked() == 1 or self:GetChecked() == true)
        if RG_Internal.SetMinimapVisible then RG_Internal.SetMinimapVisible(visible) end
    end)

    -- Fensterposition fixieren
    local cbLockPos = CreateFrame("CheckButton", "RG_CB_LOCK_POS", panel, "UICheckButtonTemplate")
    cbLockPos:SetSize(24, 24)
    cbLockPos:SetPoint("LEFT", lblMinimapHide, "RIGHT", 15, 0)
    local lblLockPos = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    lblLockPos:SetPoint("LEFT", cbLockPos, "RIGHT", 2, 0)
    lblLockPos:SetText(RG_L["OPT_AW_LOCK_POS"] or "Lock window position")
    cbLockPos:SetScript("OnClick", function(self)
        RandomGreetingCharDB.actionWindowLocked = (self:GetChecked() and true or false)
    end)

    -- Schließen-Button ausblenden (rechts neben Lock)
    local cbHideClose = CreateFrame("CheckButton", "RG_CB_HIDE_CLOSE", panel, "UICheckButtonTemplate")
    cbHideClose:SetSize(24, 24)
    cbHideClose:SetPoint("LEFT", lblLockPos, "RIGHT", 15, 0)
    local lblHideClose = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    lblHideClose:SetPoint("LEFT", cbHideClose, "RIGHT", 2, 0)
    lblHideClose:SetText(RG_L["OPT_HIDE_CLOSE_BTN"] or "Hide close button")
    cbHideClose:SetScript("OnClick", function(self)
        local visible = not (self:GetChecked() == 1 or self:GetChecked() == true)
        if RG_Internal.SetCloseBtnVisible then RG_Internal.SetCloseBtnVisible(visible) end
    end)

    ---------- List selector dropdown ----------
    local listLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    listLabel:SetPoint("TOPLEFT", cbMinimapHide, "BOTTOMLEFT", 0, -6)
    listLabel:SetText(RG_L["OPT_LIST_LABEL"] or "List:")

    local listDD = CreateFrame("Frame", "RGOptionsListDD", panel, "UIDropDownMenuTemplate")
    listDD:SetPoint("TOPLEFT", listLabel, "BOTTOMLEFT", -15, -2)
    UIDropDownMenu_SetWidth(listDD, 240)

    local LIST_KEYS_ORDER = { "HI", "BYE", "CUSTOM1", "CUSTOM2" }

    local function InitListDD(_, level)
        for _, key in ipairs(LIST_KEYS_ORDER) do
            local info   = {}
            info.text    = GetListLabel(key)
            info.value   = key
            info.checked = selectedListKey == key
            info.func    = function(btn)
                selectedListKey = btn.value
                UIDropDownMenu_SetText(listDD, GetListLabel(selectedListKey))
                CloseDropDownMenus()
                listScrollFrame.offset = 0
                listScrollFrame:SetVerticalScroll(0)
                RefreshListRows()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end
    UIDropDownMenu_Initialize(listDD, InitListDD)
    UIDropDownMenu_SetText(listDD, GetListLabel(selectedListKey))
    panel.listDD = listDD

    ---------- Message list header ----------
    local msgsLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    msgsLabel:SetPoint("TOPLEFT", listDD, "BOTTOMLEFT", 15, -12)
    msgsLabel:SetText(RG_L["OPT_MESSAGES_TITLE"] or "Messages:")

    ---------- Background / border frame ----------
    local listBg = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    listBg:SetPoint("TOPLEFT",     msgsLabel, "BOTTOMLEFT",   0, -4)
    listBg:SetPoint("BOTTOMRIGHT", panel,     "BOTTOMRIGHT", -16, 82)
    listBg:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    listBg:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
    listBg:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    ---------- FauxScrollFrame inside the border ----------
    local sf = CreateFrame("ScrollFrame", "RGOptionsFauxSF", listBg, "FauxScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",     listBg, "TOPLEFT",     3,  -3)
    sf:SetPoint("BOTTOMRIGHT", listBg, "BOTTOMRIGHT", -22,  3)
    sf:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, RefreshListRows)
    end)
    listScrollFrame = sf

    ---------- Row frames (reused) ----------
    for i = 1, MAX_ROWS do
        local row = CreateFrame("Frame", nil, sf)
        row:SetHeight(ROW_HEIGHT)
        row:SetPoint("TOPLEFT",  sf, "TOPLEFT",  0, -(i - 1) * ROW_HEIGHT)
        row:SetPoint("TOPRIGHT", sf, "TOPRIGHT", 0, -(i - 1) * ROW_HEIGHT)

        -- Subtle alternating stripe (SetTexture+SetVertexColor is safe on all Classic builds)
        if i % 2 == 0 then
            local stripe = row:CreateTexture(nil, "BACKGROUND")
            stripe:SetAllPoints()
            stripe:SetTexture("Interface\\Buttons\\WHITE8X8")
            stripe:SetVertexColor(1, 1, 1, 0.04)
        end

        local lbl = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        lbl:SetPoint("LEFT",  row, "LEFT",  4,   0)
        lbl:SetPoint("RIGHT", row, "RIGHT", -52, 0)
        lbl:SetJustifyH("LEFT")
        lbl:SetWordWrap(false)
        row.label = lbl

        -- Tooltip: show full text on mouseover
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            if self.fullText and #self.fullText > 0 then
                -- Only show tooltip when the text is actually clipped
                if self.label:GetStringWidth() > self.label:GetWidth() then
                    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                    GameTooltip:SetText(self.fullText, 1, 1, 1, 1, true)
                    GameTooltip:Show()
                end
            end
        end)
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        local delBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        delBtn:SetSize(46, ROW_HEIGHT - 2)
        delBtn:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        delBtn:SetText(RG_L["OPT_DELETE_BTN"] or "Del")
        delBtn:SetScript("OnClick", function(self)
            local idx = self.msgIdx
            if not idx then return end
            local msgs, pool = RG_Internal.GetListByKey(selectedListKey)
            if msgs and msgs[idx] then
                table.remove(msgs, idx)
                if pool then wipe(pool) end
                -- Clamp scroll offset when deleting near the end of the list
                local total    = #msgs
                local curOff   = listScrollFrame.offset or 0
                local visRows  = math.max(1, math.floor((listScrollFrame:GetHeight() or 0) / ROW_HEIGHT))
                if curOff > 0 and curOff + visRows > total then
                    local newOff = math.max(0, total - visRows)
                    listScrollFrame.offset = newOff
                    listScrollFrame:SetVerticalScroll(newOff * ROW_HEIGHT)
                end
                RefreshListRows()
            end
        end)
        row.deleteBtn = delBtn
        row:Hide()

        listRows[i] = row
    end

    ---------- Add new entry ----------
    local addBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    addBtn:SetSize(90, 22)
    addBtn:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -16, 54)

    local addEB = CreateFrame("EditBox", "RGOptionsAddEB", panel, "InputBoxTemplate")
    addEB:SetHeight(20)
    addEB:SetPoint("BOTTOMLEFT",  panel,  "BOTTOMLEFT", 20,    54)
    addEB:SetPoint("BOTTOMRIGHT", addBtn, "BOTTOMLEFT",  -6,    0)
    addEB:SetAutoFocus(false)
    addEB:SetMaxLetters(255)
    addBtn:SetText(RG_L["OPT_ADD_BTN"] or "Add")

    local function DoAddEntry()
        local text = addEB:GetText():match("^%s*(.-)%s*$")
        if text ~= "" then
            local msgs, pool = RG_Internal.GetListByKey(selectedListKey)
            if msgs then
                table.insert(msgs, text)
                if pool then wipe(pool) end
                addEB:SetText("")
                RefreshListRows()
            end
        end
    end
    addBtn:SetScript("OnClick", DoAddEntry)
    addEB:SetScript("OnEnterPressed", DoAddEntry)
    addEB:SetScript("OnEscapePressed", function()
        addEB:SetText("")
        addEB:ClearFocus()
    end)

    ---------- Separator above Import / Export ----------
    local sep2 = CreateFrame("Frame", nil, panel)
    sep2:SetHeight(1)
    sep2:SetPoint("BOTTOMLEFT",  panel, "BOTTOMLEFT",  16,  46)
    sep2:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -16, 46)
    local sep2Tex = sep2:CreateTexture(nil, "ARTWORK")
    sep2Tex:SetAllPoints()
    sep2Tex:SetTexture("Interface\\Buttons\\WHITE8X8")
    sep2Tex:SetVertexColor(0.4, 0.4, 0.4, 0.6)

    ---------- Import / Export + Generator (bottom) ----------
    local importBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    importBtn:SetSize(110, 24)
    importBtn:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 16, 16)
    importBtn:SetText(RG_L["OPT_IMPORT_BTN"] or "Import...")
    importBtn:SetScript("OnClick", function()
        RG_Internal.ShowImportDialog(selectedListKey)
    end)

    local exportBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    exportBtn:SetSize(110, 24)
    exportBtn:SetPoint("LEFT", importBtn, "RIGHT", 6, 0)
    exportBtn:SetText(RG_L["OPT_EXPORT_BTN"] or "Export...")
    exportBtn:SetScript("OnClick", function()
        local msgs = RG_Internal.GetListByKey(selectedListKey) or {}
        RG_Internal.ExportList(msgs, selectedListKey)
    end)

    local generatorBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    generatorBtn:SetSize(220, 24)
    generatorBtn:SetPoint("LEFT", exportBtn, "RIGHT", 6, 0)
    generatorBtn:SetText(RG_L["OPT_GENERATOR_BTN"] or "Import Generator (external)")
    generatorBtn:SetScript("OnClick", function()
        ShowURLDialog(
            "https://dgne-nurag.github.io/RandomGreeting/",
            RG_L["OPT_GENERATOR_URL_TITLE"] or "Import Generator URL"
        )
    end)

    -- Aktualisiert alle statischen Texte im Panel (nach Sprachänderung sofort aufrufbar)
    RefreshPanelTexts = function()
        local db     = RandomGreetingDB
        local charDB = RandomGreetingCharDB
        -- Dropdowns
        UIDropDownMenu_SetText(langDD,  GetLangText((db and db.locale) or "auto"))
        UIDropDownMenu_SetText(listDD,  GetListLabel(selectedListKey))
        UIDropDownMenu_SetText(themeDD, GetThemeText((charDB and charDB.theme) or "wow"))
        -- Abschnitts-Labels
        langLabel:SetText(RG_L["OPT_LANG_LABEL"]         or "Language:")
        awSectionLabel:SetText(RG_L["OPT_AW_TITLE"]      or "Action-Window:")
        appearLabel:SetText(RG_L["OPT_APPEARANCE_TITLE"] or "Window Design:")
        listLabel:SetText(RG_L["OPT_LIST_LABEL"]         or "Active list:")
        msgsLabel:SetText(RG_L["OPT_MESSAGES_TITLE"]     or "Messages:")
        -- Buttons
        langResetBtn:SetText(RG_L["OPT_RESET_BTN"]      or "Reset Lists")
        awResetPosBtn:SetText(RG_L["OPT_RESET_POS_BTN"] or "Reset pos.")
        importBtn:SetText(RG_L["OPT_IMPORT_BTN"]        or "Import...")
        exportBtn:SetText(RG_L["OPT_EXPORT_BTN"]        or "Export...")
        generatorBtn:SetText(RG_L["OPT_GENERATOR_BTN"]  or "Import Generator (external)")
        addBtn:SetText(RG_L["OPT_ADD_BTN"]              or "Add")
        -- Checkbox-Labels
        awLblHI:SetText(RG_L["LABEL_HI"]              or "Greeting")
        awLblBYE:SetText(RG_L["LABEL_BYE"]            or "Farewell")
        awLblC1:SetText((db and db.custom1Label) or RG_L["LABEL_CUSTOM1"] or "Custom1")
        awLblC2:SetText((db and db.custom2Label) or RG_L["LABEL_CUSTOM2"] or "Custom2")
        awLblCompact:SetText(RG_L["OPT_AW_COMPACT"]    or "Compact mode")
        lblMinimapHide:SetText(RG_L["OPT_MINIMAP_HIDE"] or "Minimap Button")
        lblLockPos:SetText(RG_L["OPT_AW_LOCK_POS"]      or "Lock window position")
        lblHideClose:SetText(RG_L["OPT_HIDE_CLOSE_BTN"] or "Hide close button")
        -- Löschen-Button in allen Zeilen
        local delTxt = RG_L["OPT_DELETE_BTN"] or "Del"
        for _, row in ipairs(listRows) do
            if row.deleteBtn then row.deleteBtn:SetText(delTxt) end
        end
    end

    ---------- OnShow: Zustand synchronisieren ----------
    panel:SetScript("OnShow", function()
        local db     = RandomGreetingDB
        local charDB = RandomGreetingCharDB
        RefreshPanelTexts()
        listScrollFrame.offset = 0
        listScrollFrame:SetVerticalScroll(0)
        RefreshListRows()
        -- Checkboxen synchronisieren
        local btnCfg = db.actionWindowButtons or {}
        awCbHI:SetChecked(btnCfg.HI      == true)
        awCbBYE:SetChecked(btnCfg.BYE    == true)
        awCbC1:SetChecked(btnCfg.CUSTOM1 == true)
        awCbC2:SetChecked(btnCfg.CUSTOM2 == true)
        awCbCompact:SetChecked(charDB.actionWindowCompact == true)
        UIDropDownMenu_SetText(themeDD, GetThemeText(charDB.theme or "wow"))
        cbMinimapHide:SetChecked(not charDB.minimapHidden)
        cbLockPos:SetChecked(charDB.actionWindowLocked  == true)
        cbHideClose:SetChecked(charDB.closeButtonHidden == true)
    end)

    ---------- Default button: reset language to Auto ----------
    panel.default = function()
        if RandomGreetingDB then
            RandomGreetingDB.locale = "auto"
            local eff = (GetLocale() == "deDE") and "deDE" or "enUS"
            RG_Internal.ApplyLocale(eff)
            UIDropDownMenu_SetText(langDD, GetLangText("auto"))
        end
    end

    -- Register with the Interface Options.
    -- Classic Era 1.15.x replaced InterfaceOptions_AddCategory with the Settings API.
    -- TBC Anniversary (2.5.x) still uses the old API -> support both.
    if Settings and Settings.RegisterCanvasLayoutCategory then
        -- Classic Era 1.15.x+ (new API)
        local category = Settings.RegisterCanvasLayoutCategory(panel, ADDON_NAME)
        Settings.RegisterAddOnCategory(category)
        panel.settingsCategory = category
        -- The Settings framework manages visibility; do NOT hide the panel here.
    elseif InterfaceOptions_AddCategory then
        -- TBC Anniversary / older Classic (legacy API)
        InterfaceOptions_AddCategory(panel)
        panel:Hide()
    end
end

-- ----------------------------------------------------------
-- Open the options panel from slash commands
-- ----------------------------------------------------------
RG_Internal.OpenOptions = function(listKey)
    if listKey then
        selectedListKey = listKey
    end
    local panel = _G["RGOptionsPanel"]
    if not panel then return end
    if Settings and Settings.OpenToCategory and panel.settingsCategory then
        local ok = pcall(function()
            Settings.OpenToCategory(panel.settingsCategory:GetID())
        end)
        if not ok then
            pcall(Settings.OpenToCategory, panel.settingsCategory)
        end
    elseif InterfaceOptionsFrame_OpenToCategory then
        pcall(InterfaceOptionsFrame_OpenToCategory, "RandomGreeting")
        if InterfaceOptionsFrame then InterfaceOptionsFrame:Show() end
    end
end

-- ----------------------------------------------------------
-- Initialize on PLAYER_LOGIN so that the InterfaceOptionsFrame
-- and all SavedVariables are guaranteed to be fully ready.
-- ----------------------------------------------------------

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self)
    local ok, err = pcall(BuildOptionsPanel)
    if not ok then
        print("|cffff0000RandomGreeting Options Error:|r " .. tostring(err))
    end
    self:UnregisterEvent("PLAYER_LOGIN")
end)
