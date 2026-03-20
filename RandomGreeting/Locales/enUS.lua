-- ==========================================================
-- RandomGreeting v2 - English (enUS) - Default / Fallback
-- Always loaded; writes into RG_LOCALES["enUS"].
-- ApplyLocale() copies the selected locale into RG_L at runtime.
-- ==========================================================

local L = {}
RG_LOCALES["enUS"] = L

-- ----------------------------------------------------------
-- UI-Strings
-- ----------------------------------------------------------
L["MSG_LOADED"]             = "Use |cff00ccff/rhi|r, |cff00ccff/rbye|r, |cff00ccff/rcustom1|r, |cff00ccff/rcustom2|r  –  help: |cff00ccff/rhi help|r"
L["LABEL_HI"]               = "Greeting"
L["LABEL_BYE"]              = "Farewell"
L["LABEL_CUSTOM1"]          = "Custom1"
L["LABEL_CUSTOM2"]          = "Custom2"

L["HELP_TITLE"]             = "Help"
L["HELP_SEND"]              = "Send a random message"
L["HELP_CHANNEL"]           = "Send to channel: s=say  g=guild  p=party  r=raid"
L["HELP_WHISPER"]           = "Whisper a player: w [playername]"
L["HELP_LIST"]              = "Show all entries"
L["HELP_ADD"]               = "Add a new entry"
L["HELP_REMOVE"]            = "Remove entry by ID"
L["HELP_CLEAR"]             = "Delete ALL entries (requires confirm)"
L["HELP_IMPORT"]            = "Import entries from an import string"
L["HELP_IMPORT_DIALOG"]     = "Open import dialog (paste string there)"
L["HELP_EXPORT"]            = "Export entries as an import string"
L["HELP_LABEL"]             = "Set a custom display name for this command"
L["HELP_RESET"]             = "Reset list to addon defaults (requires confirm)"

L["LIST_TITLE"]             = "List"
L["LIST_EMPTY"]             = "(empty)"

L["MSG_ADDED"]              = "Added"
L["MSG_REMOVED"]            = "Removed"
L["MSG_CLEARED"]            = "All entries deleted!"
L["MSG_IMPORTED"]           = "%d entries imported into %s."
L["MSG_EXPORT"]             = "Export string (copy the line below)"
L["MSG_LABEL_SET"]          = "Label set to: %s"
L["MSG_RESET"]              = "List reset to defaults."

L["WARN_CLEAR"]             = "Warning: Delete all entries? Type |cff00ccff%s clear confirm|r"
L["WARN_RESET"]             = "Warning: Reset to defaults? Type |cff00ccff%s reset confirm|r"

L["ERR_NO_TEXT"]            = "Error: No text provided."
L["ERR_WHISPER_NO_TARGET"]  = "Error: No player name provided. Usage: /rhi w [name]"
L["ERR_INVALID_ID"]         = "Error: Invalid ID."
L["ERR_EMPTY_LIST"]         = "No entries in list!"
L["ERR_IMPORT_INVALID"]     = "Error: Invalid import string. Must start with RG2:"
L["ERR_IMPORT_WRONGLIST"]   = "Error: String is for list '%s', but you are in command '%s'. Use /rg import to auto-detect."
L["ERR_IMPORT_UNKNOWNLIST"] = "Error: Unknown list key"
L["ERR_EXPORT_EMPTY"]       = "Error: List is empty, nothing to export."

-- Dialog
L["DIALOG_EXPORT_TITLE"]    = "Export – Copy the string below"
L["DIALOG_EXPORT_DESC"]     = "Select all with Ctrl+A, then copy with Ctrl+C:"
L["DIALOG_IMPORT_TITLE"]    = "Import – Paste your string"
L["DIALOG_IMPORT_DESC"]     = "Paste your import string (RG2:...) and click Import:"
L["DIALOG_IMPORT_BTN"]      = "Import"
L["DIALOG_IMPORT_CLEAR"]    = "Clear list before import"
L["DIALOG_CLOSE_BTN"]       = "Close"

-- Options panel
L["OPT_TITLE"]              = "RandomGreeting – Options"
L["OPT_LANG_LABEL"]         = "Language:"
L["OPT_LANG_AUTO"]          = "Auto (client language)"
L["OPT_LANG_ENUS"]          = "English"
L["OPT_LANG_DEDE"]          = "Deutsch"
L["OPT_LIST_LABEL"]         = "Active list:"
L["OPT_IMPORT_BTN"]           = "Import..."
L["OPT_EXPORT_BTN"]           = "Export..."
L["OPT_MESSAGES_TITLE"]       = "Messages in this list:"
L["OPT_DELETE_BTN"]           = "Del"
L["OPT_RESET_BTN"]            = "Reset to defaults"
L["OPT_GENERATOR_BTN"]        = "Import Generator (external)"
L["OPT_GENERATOR_URL_TITLE"]  = "Import Generator URL – copy & open in browser"
L["OPT_ADD_BTN"]              = "Add"

-- ----------------------------------------------------------
-- Default messages (English)
-- ----------------------------------------------------------
RG_LOCALE_DEFAULTS["enUS"] = {
    hi = {
        "Greetings!", "Well met!", "Howdy, partner!", "Ahoy, Mateys!",
        "Hello there!", "Salutations!", "What's up?", "Hey hey!",
        "Good day to you!", "Aloha!", "Blood and Thunder!",
        "Light be with you.", "Ishnu-alah!", "Lok'tar!", "Zug zug!",
        "Stay a while and listen.", "Greetings, traveler!", "Good to see you!",
    },
    bye = {
        "Farewell!", "Safe travels!", "Until next time!", "See you around!",
        "Goodbye!", "Later!", "Take care!", "See you on the other side!",
        "May the Light guide you.", "Be well!", "Cheers!", "Toodles!",
        "Catch you later!", "Peace out!", "Until we meet again!",
        "Don't let the murlocs bite!", "For the Horde!", "For the Alliance!",
    },
}
