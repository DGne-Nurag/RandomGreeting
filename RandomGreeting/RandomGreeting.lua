-- ==========================================================
-- RandomGreeting v2.0
-- Random messages without repeats – multilingual,
-- importable, extensible via custom lists.
-- ==========================================================

local ADDON_NAME = "RandomGreeting"

-- ==========================================================
-- 1. UTILITY FUNCTIONS
-- ==========================================================

--- Refills the random pool when it is empty.
local function CheckPool(pool, messages)
    if #pool == 0 then
        for i = 1, #messages do
            table.insert(pool, i)
        end
    end
end

--- Splits a string at the ";;" separator.
--- Returns a list of trimmed entries.
local function SplitBySep(str)
    local result = {}
    for entry in (str .. ";;"):gmatch("(.-);;") do
        entry = entry:match("^%s*(.-)%s*$") -- trim
        if entry ~= "" then
            table.insert(result, entry)
        end
    end
    return result
end

-- ==========================================================
-- 2. IMPORT / EXPORT
-- ==========================================================
--
-- Format: RG2:<LISTE>:<Eintrag1>;;<Eintrag2>;;<Eintrag3>
--   LISTE   = HI | BYE | CUSTOM1 | CUSTOM2
--   Entries are separated by ";;" (because WoW color codes use |)
--
-- Beispiel: RG2:BYE:Tschuess;;Ciao;;Auf Wiedersehen
--

local LIST_KEYS = { HI = true, BYE = true, CUSTOM1 = true, CUSTOM2 = true }

--- Returns the messages/pool pair for a given list key.
local function GetListByKey(key)
    local db = RandomGreetingDB
    if     key == "HI"      then return db.hiMessages,      db.hiPool
    elseif key == "BYE"     then return db.byeMessages,     db.byePool
    elseif key == "CUSTOM1" then return db.custom1Messages, db.custom1Pool
    elseif key == "CUSTOM2" then return db.custom2Messages, db.custom2Pool
    end
    return nil, nil
end

--- Imports entries from an import string.
--- targetKey: expected list key (nil = auto-detect from string)
local function ImportList(importStr, targetKey)
    local listKey, data = importStr:match("^RG2:(%w+):(.+)$")
    if not listKey then
        print("|cffff0000" .. RG_L["ERR_IMPORT_INVALID"] .. "|r")
        return false
    end

    if not LIST_KEYS[listKey] then
        print("|cffff0000" .. RG_L["ERR_IMPORT_UNKNOWNLIST"] .. ": " .. listKey .. "|r")
        return false
    end

    if targetKey and listKey ~= targetKey then
        print("|cffff0000" .. string.format(RG_L["ERR_IMPORT_WRONGLIST"], listKey, targetKey) .. "|r")
        return false
    end

    local messages, pool = GetListByKey(listKey)
    local entries = SplitBySep(data)
    for _, entry in ipairs(entries) do
        table.insert(messages, entry)
    end
    wipe(pool)
    print("|cff00ff00" .. string.format(RG_L["MSG_IMPORTED"], #entries, listKey) .. "|r")
    return true
end

-- ==========================================================
-- 3. STRING DIALOG (Export / Import window)
-- ==========================================================
-- Opens a WoW UI frame with an EditBox so the player can
-- copy the export string or paste an import string.
-- This works around the limitation that the WoW chat is not copyable.

local RG_Dialog = nil

local function EnsureDialog()
    if RG_Dialog then return end

    -- Main frame
    -- "BackdropTemplate" is required because SetBackdrop is no longer
    -- natively available on Frame since Classic 1.14+; it is now a mixin.
    local frame = CreateFrame("Frame", "RGStringDialog", UIParent, "BackdropTemplate")
    frame:SetSize(520, 170)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)
    frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    frame:Hide()

    -- Title bar (texture + text)
    -- Width = frame width (520) so long text does not overflow.
    local titleBg = frame:CreateTexture(nil, "ARTWORK")
    titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    titleBg:SetWidth(520)
    titleBg:SetHeight(64)
    titleBg:SetPoint("TOP", 0, 12)

    local titleText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    -- Anchor relative to texture: 14 px from texture TOP = visual centre of the header strip.
    titleText:SetPoint("TOP", titleBg, "TOP", 0, -14)
    titleText:SetWidth(490)
    titleText:SetJustifyH("CENTER")
    frame.titleText = titleText

    -- Description line
    local desc = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", 20, -28)
    desc:SetWidth(480)
    desc:SetJustifyH("LEFT")
    frame.desc = desc

    -- EditBox (single-line, full width)
    local eb = CreateFrame("EditBox", "RGStringDialogEditBox", frame, "InputBoxTemplate")
    eb:SetSize(480, 20)
    eb:SetPoint("TOPLEFT", 20, -52)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(0)
    -- Close on Escape
    eb:SetScript("OnEscapePressed", function() frame:Hide() end)
    frame.editBox = eb

    -- Import button (visible in import mode only)
    local importBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    importBtn:SetSize(110, 24)
    importBtn:SetPoint("BOTTOMLEFT", 20, 10)
    importBtn:Hide()
    frame.importBtn = importBtn

    -- "Clear list" checkbox (visible in import mode only)
    local clearCb = CreateFrame("CheckButton", "RGImportClearCheckbox", frame, "UICheckButtonTemplate")
    clearCb:SetSize(24, 24)
    clearCb:SetPoint("LEFT", importBtn, "RIGHT", 12, 0)
    clearCb:Hide()
    -- Separate FontString label next to the checkbox
    local clearCbLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    clearCbLabel:SetPoint("LEFT", clearCb, "RIGHT", 2, 0)
    clearCbLabel:Hide()
    clearCb.label = clearCbLabel
    frame.clearCheck = clearCb

    -- Close button (standard X top-right)
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", 4, 4)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    frame.closeBtn = closeBtn

    RG_Dialog = frame
end

--- Shows the dialog in export mode:
--- The EditBox contains the ready-to-copy import string, pre-selected (Ctrl+C).
local function ShowExportDialog(exportStr, listKey)
    EnsureDialog()
    local frame = RG_Dialog
    frame.titleText:SetText("RandomGreeting  |cff00ccff[" .. listKey .. "]|r")
    frame.desc:SetText(RG_L["DIALOG_EXPORT_DESC"])
    frame.editBox:SetText(exportStr)
    frame.editBox:SetEnabled(true)
    frame.importBtn:Hide()
    frame.clearCheck:Hide()
    frame.clearCheck.label:Hide()
    frame:Show()
    frame.editBox:SetFocus()
    frame.editBox:HighlightText()
end

--- Shows the dialog in import mode:
--- The player pastes a string and confirms via button or Enter.
--- listKey: nil = auto-detect from the string
local function ShowImportDialog(listKey)
    EnsureDialog()
    local frame = RG_Dialog
    local listLabel = listKey or "AUTO"
    frame.titleText:SetText("RandomGreeting  |cff00ccff[" .. listLabel .. "]|r")
    frame.desc:SetText(RG_L["DIALOG_IMPORT_DESC"])
    frame.editBox:SetText("")
    frame.editBox:SetEnabled(true)

    -- Configure and show the import button
    frame.importBtn:SetText(RG_L["DIALOG_IMPORT_BTN"])
    frame.importBtn:SetScript("OnClick", function()
        local str = frame.editBox:GetText():match("^%s*(.-)%s*$")
        if str ~= "" then
            -- If checkbox is checked, clear the target list first
            if frame.clearCheck:GetChecked() then
                local msgs, pool = GetListByKey(
                    str:match("^RG2:(%w+):") or (listKey or "")
                )
                if msgs then wipe(msgs) end
                if pool  then wipe(pool)  end
            end
            local ok = ImportList(str, listKey)
            if ok then frame:Hide() end
        else
            print("|cffff0000" .. RG_L["ERR_NO_TEXT"] .. "|r")
        end
    end)
    -- Also trigger import on Enter
    frame.editBox:SetScript("OnEnterPressed", function()
        frame.importBtn:GetScript("OnClick")(frame.importBtn)
    end)
    frame.importBtn:Show()
    -- Show checkbox and reset its state
    frame.clearCheck:SetChecked(false)
    frame.clearCheck.label:SetText(RG_L["DIALOG_IMPORT_CLEAR"])
    frame.clearCheck:Show()
    frame.clearCheck.label:Show()

    frame:Show()
    frame.editBox:SetFocus()
end

--- Exports a list: opens the string dialog.
local function ExportList(messages, listKey)
    if #messages == 0 then
        print("|cffff0000" .. RG_L["ERR_EXPORT_EMPTY"] .. "|r")
        return
    end
    local str = "RG2:" .. listKey .. ":" .. table.concat(messages, ";;")
    ShowExportDialog(str, listKey)
end

-- ==========================================================
-- 4. DATABASE & INITIALIZATION
-- ==========================================================

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, name)
    if name ~= ADDON_NAME then return end

    RandomGreetingDB = RandomGreetingDB or {}
    local db = RandomGreetingDB

    -- Greetings (/rhi)
    db.hiMessages = db.hiMessages or {}
    if #db.hiMessages == 0 then
        for _, v in ipairs(RG_DEFAULTS.hi) do table.insert(db.hiMessages, v) end
    end
    db.hiPool = {}

    -- Farewells (/rbye)
    db.byeMessages = db.byeMessages or {}
    if #db.byeMessages == 0 then
        for _, v in ipairs(RG_DEFAULTS.bye) do table.insert(db.byeMessages, v) end
    end
    db.byePool = {}

    -- Custom 1 (/rcustom1) – empty by default
    db.custom1Messages = db.custom1Messages or {}
    db.custom1Pool     = {}
    db.custom1Label    = db.custom1Label or RG_L["LABEL_CUSTOM1"]

    -- Custom 2 (/rcustom2) – empty by default
    db.custom2Messages = db.custom2Messages or {}
    db.custom2Pool     = {}
    db.custom2Label    = db.custom2Label or RG_L["LABEL_CUSTOM2"]

    print("|cff00ff00" .. ADDON_NAME .. ":|r " .. RG_L["MSG_LOADED"])
    self:UnregisterEvent("ADDON_LOADED")
end)

-- ==========================================================
-- 5. COMMAND HANDLER (shared function)
-- ==========================================================

local function HandleCommand(msg, messages, pool, label, slash, listKey, defaultList)
    local args = {}
    for word in msg:gmatch("%S+") do table.insert(args, word) end
    local cmd = args[1] and args[1]:lower() or ""

    -- ---- HELP ----
    if cmd == "help" then
        print("|cff00ff00" .. label .. " " .. RG_L["HELP_TITLE"] .. ":|r")
        print("  |cff00ccff" .. slash .. "|r - " .. RG_L["HELP_SEND"])
        print("  |cff00ccff" .. slash .. " s|g|p|r|r - " .. RG_L["HELP_CHANNEL"])
        print("  |cff00ccff" .. slash .. " w [Name]|r - " .. RG_L["HELP_WHISPER"])
        print("  |cff00ccff" .. slash .. " list|r - " .. RG_L["HELP_LIST"])
        print("  |cff00ccff" .. slash .. " add [Text]|r - " .. RG_L["HELP_ADD"])
        print("  |cff00ccff" .. slash .. " remove [ID]|r - " .. RG_L["HELP_REMOVE"])
        print("  |cff00ccff" .. slash .. " clear confirm|r - " .. RG_L["HELP_CLEAR"])
        print("  |cff00ccff" .. slash .. " import [String]|r - " .. RG_L["HELP_IMPORT"])
        print("  |cff00ccff" .. slash .. " import|r - " .. RG_L["HELP_IMPORT_DIALOG"])
        print("  |cff00ccff" .. slash .. " export|r - " .. RG_L["HELP_EXPORT"])
        if defaultList then
            print("  |cff00ccff" .. slash .. " reset confirm|r - " .. RG_L["HELP_RESET"])
        end
        if listKey == "CUSTOM1" or listKey == "CUSTOM2" then
            print("  |cff00ccff" .. slash .. " label [Name]|r - " .. RG_L["HELP_LABEL"])
        end

    -- ---- LIST ----
    elseif cmd == "list" then
        print("|cff00ff00" .. label .. " " .. RG_L["LIST_TITLE"] .. ":|r")
        if #messages == 0 then
            print("  " .. RG_L["LIST_EMPTY"])
        else
            for i, text in ipairs(messages) do
                print(string.format("  |cff00ccff[%d]|r %s", i, text))
            end
        end

    -- ---- ADD ----
    elseif cmd == "add" then
        local newText = msg:sub(5):match("^%s*(.-)%s*$")
        if newText ~= "" then
            table.insert(messages, newText)
            wipe(pool)
            print("|cff00ff00" .. label .. " " .. RG_L["MSG_ADDED"] .. ":|r " .. newText)
        else
            print("|cffff0000" .. RG_L["ERR_NO_TEXT"] .. "|r")
        end

    -- ---- REMOVE ----
    elseif cmd == "remove" then
        local id = tonumber(args[2])
        if id and messages[id] then
            local removed = table.remove(messages, id)
            wipe(pool)
            print("|cffff0000" .. label .. " " .. RG_L["MSG_REMOVED"] .. ":|r " .. removed)
        else
            print("|cffff0000" .. RG_L["ERR_INVALID_ID"] .. "|r")
        end

    -- ---- CLEAR ----
    elseif cmd == "clear" then
        if args[2] == "confirm" then
            wipe(messages)
            wipe(pool)
            print("|cffff0000" .. label .. ":|r " .. RG_L["MSG_CLEARED"])
        else
            print("|cffff0000" .. string.format(RG_L["WARN_CLEAR"], slash) .. "|r")
        end

    -- ---- RESET (HI / BYE only) ----
    elseif cmd == "reset" and defaultList then
        if args[2] == "confirm" then
            wipe(messages)
            wipe(pool)
            for _, v in ipairs(defaultList) do table.insert(messages, v) end
            print("|cff00ff00" .. label .. ":|r " .. RG_L["MSG_RESET"])
        else
            print("|cffff0000" .. string.format(RG_L["WARN_RESET"], slash) .. "|r")
        end

    -- ---- IMPORT ----
    -- With string: import immediately
    -- Without string: open import dialog
    elseif cmd == "import" then
        local importStr = msg:sub(8):match("^%s*(.-)%s*$")
        if importStr ~= "" then
            ImportList(importStr, listKey)
        else
            ShowImportDialog(listKey)
        end

    -- ---- EXPORT ----
    elseif cmd == "export" then
        ExportList(messages, listKey)

    -- ---- LABEL (CUSTOM1/CUSTOM2 only) ----
    elseif cmd == "label" and (listKey == "CUSTOM1" or listKey == "CUSTOM2") then
        local newLabel = msg:sub(7):match("^%s*(.-)%s*$")
        if newLabel ~= "" then
            if listKey == "CUSTOM1" then
                RandomGreetingDB.custom1Label = newLabel
            else
                RandomGreetingDB.custom2Label = newLabel
            end
            print("|cff00ff00" .. string.format(RG_L["MSG_LABEL_SET"], newLabel) .. "|r")
        else
            print("|cffff0000" .. RG_L["ERR_NO_TEXT"] .. "|r")
        end

    -- ---- SEND (no recognised subcommand = post message) ----
    else
        if #messages == 0 then
            print("|cffff0000" .. label .. ": " .. RG_L["ERR_EMPTY_LIST"] .. "|r")
            return
        end
        local target, whisperTarget
        if     cmd == "s" then target = "SAY"
        elseif cmd == "g" then target = "GUILD"
        elseif cmd == "p" then target = "PARTY"
        elseif cmd == "r" then target = "RAID"
        elseif cmd == "w" then
            whisperTarget = args[2]
            if not whisperTarget or whisperTarget == "" then
                print("|cffff0000" .. RG_L["ERR_WHISPER_NO_TARGET"] .. "|r")
                return
            end
            target = "WHISPER"
        else
            target = IsInRaid() and "RAID" or IsInGroup() and "PARTY" or "SAY"
        end
        CheckPool(pool, messages)
        local idx = table.remove(pool, math.random(1, #pool))
        SendChatMessage(messages[idx], target, nil, whisperTarget)
    end
end

-- ==========================================================
-- 6. SLASH COMMANDS
-- ==========================================================

-- /rhi – Random greeting
SLASH_RANDOMHI1 = "/rhi"
SlashCmdList["RANDOMHI"] = function(msg)
    local db = RandomGreetingDB
    HandleCommand(msg, db.hiMessages, db.hiPool,
        RG_L["LABEL_HI"], "/rhi", "HI", RG_DEFAULTS.hi)
end

-- /rbye – Random farewell
SLASH_RANDOMBYE1 = "/rbye"
SlashCmdList["RANDOMBYE"] = function(msg)
    local db = RandomGreetingDB
    HandleCommand(msg, db.byeMessages, db.byePool,
        RG_L["LABEL_BYE"], "/rbye", "BYE", RG_DEFAULTS.bye)
end

-- /rcustom1 – Custom list 1 (e.g. warlock portal quips)
SLASH_RANDOMCUSTOM11 = "/rcustom1"
SlashCmdList["RANDOMCUSTOM1"] = function(msg)
    local db = RandomGreetingDB
    HandleCommand(msg, db.custom1Messages, db.custom1Pool,
        db.custom1Label or RG_L["LABEL_CUSTOM1"], "/rcustom1", "CUSTOM1", nil)
end

-- /rcustom2 – Custom list 2
SLASH_RANDOMCUSTOM21 = "/rcustom2"
SlashCmdList["RANDOMCUSTOM2"] = function(msg)
    local db = RandomGreetingDB
    HandleCommand(msg, db.custom2Messages, db.custom2Pool,
        db.custom2Label or RG_L["LABEL_CUSTOM2"], "/rcustom2", "CUSTOM2", nil)
end

-- /rg import [string] – Auto-detect import
-- Without string: open import dialog (list AUTO-detected)
SLASH_RANDOMGREETING1 = "/rg"
SlashCmdList["RANDOMGREETING"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do table.insert(args, word) end
    local cmd = args[1] and args[1]:lower() or ""
    if cmd == "import" then
        local importStr = msg:sub(8):match("^%s*(.-)%s*$")
        if importStr ~= "" then
            ImportList(importStr, nil) -- targetKey nil = auto-detect
        else
            ShowImportDialog(nil)     -- nil = auto-detect from string
        end
    else
        print("|cff00ff00RandomGreeting v2:|r " .. RG_L["MSG_LOADED"])
    end
end
