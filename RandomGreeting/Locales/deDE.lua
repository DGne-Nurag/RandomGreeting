-- ==========================================================
-- RandomGreeting v2 - Deutsch (deDE)
-- Wird nur geladen, wenn GetLocale() == "deDE".
-- Überschreibt nur die Strings, die lokalisiert werden sollen.
-- ==========================================================

if GetLocale() ~= "deDE" then return end

local L = RG_L
local D = RG_DEFAULTS

-- ----------------------------------------------------------
-- UI-Strings (Deutsch)
-- ----------------------------------------------------------
L["MSG_LOADED"]             = "Nutze |cff00ccff/rhi|r, |cff00ccff/rbye|r, |cff00ccff/rcustom1|r, |cff00ccff/rcustom2|r  –  Hilfe: |cff00ccff/rhi help|r"
L["LABEL_HI"]               = "Begrüßung"
L["LABEL_BYE"]              = "Abschied"
L["LABEL_CUSTOM1"]          = "Custom1"
L["LABEL_CUSTOM2"]          = "Custom2"

L["HELP_TITLE"]             = "Hilfe"
L["HELP_SEND"]              = "Sendet eine zufällige Nachricht"
L["HELP_CHANNEL"]           = "In Kanal senden: s=sagen  g=gilde  p=gruppe  r=schlachtzug"
L["HELP_WHISPER"]           = "Flüstern an einen Spieler: w [Spielername]"
L["HELP_LIST"]              = "Alle Einträge anzeigen"
L["HELP_ADD"]               = "Neuen Eintrag hinzufügen"
L["HELP_REMOVE"]            = "Eintrag per ID löschen"
L["HELP_CLEAR"]             = "ALLE Einträge löschen (Bestätigung nötig)"
L["HELP_IMPORT"]            = "Einträge aus einem Importstring importieren"
L["HELP_IMPORT_DIALOG"]     = "Import-Dialog öffnen (String dort einfügen)"
L["HELP_EXPORT"]            = "Einträge als Importstring exportieren"
L["HELP_LABEL"]             = "Eigenen Anzeigenamen für diesen Befehl setzen"
L["HELP_RESET"]             = "Liste auf Addon-Standards zurücksetzen (Bestätigung nötig)"

L["LIST_TITLE"]             = "Liste"
L["LIST_EMPTY"]             = "(Leer)"

L["MSG_ADDED"]              = "Hinzugefügt"
L["MSG_REMOVED"]            = "Gelöscht"
L["MSG_CLEARED"]            = "Alle Einträge gelöscht!"
L["MSG_IMPORTED"]           = "%d Einträge in %s importiert."
L["MSG_EXPORT"]             = "Exportstring (kopiere die Zeile unten)"
L["MSG_LABEL_SET"]          = "Label gesetzt: %s"
L["MSG_RESET"]              = "Liste auf Standard zurückgesetzt."

L["WARN_CLEAR"]             = "Warnung: Alle Einträge löschen? Tippe |cff00ccff%s clear confirm|r"
L["WARN_RESET"]             = "Warnung: Auf Standard zurücksetzen? Tippe |cff00ccff%s reset confirm|r"

L["ERR_NO_TEXT"]            = "Fehler: Kein Text angegeben."
L["ERR_WHISPER_NO_TARGET"]  = "Fehler: Kein Spielername angegeben. Nutzung: /rhi w [Name]"
L["ERR_INVALID_ID"]         = "Fehler: Ungültige ID."
L["ERR_EMPTY_LIST"]         = "Keine Einträge in der Liste!"
L["ERR_IMPORT_INVALID"]     = "Fehler: Ungültiger Importstring. Muss mit RG2: beginnen."
L["ERR_IMPORT_WRONGLIST"]   = "Fehler: Importstring ist für Liste '%s', nicht '%s'. Nutze /rg import für automatische Erkennung."
L["ERR_IMPORT_UNKNOWNLIST"] = "Fehler: Unbekannter Listenschlüssel"
L["ERR_EXPORT_EMPTY"]       = "Fehler: Liste ist leer, nichts zu exportieren."

-- Dialog
L["DIALOG_EXPORT_TITLE"]    = "Export – String kopieren"
L["DIALOG_EXPORT_DESC"]     = "Alles markieren mit Strg+A, dann kopieren mit Strg+C:"
L["DIALOG_IMPORT_TITLE"]    = "Import – String einfügen"
L["DIALOG_IMPORT_DESC"]     = "Importstring (RG2:...) einfügen und auf Importieren klicken:"
L["DIALOG_IMPORT_BTN"]      = "Importieren"
L["DIALOG_IMPORT_CLEAR"]    = "Liste vor Import leeren"
L["DIALOG_CLOSE_BTN"]       = "Schließen"

-- ----------------------------------------------------------
-- Standard-Nachrichten (Deutsch)
-- ----------------------------------------------------------
D.hi = {
    "Huhu!", "Hallöchen Popöchen!", "Moinsen!", "Seid gegrüßt!",
    "Blut und Donner!", "Das Licht sei mit euch.", "Moin Moin!",
    "Na du?", "Herzlich Willkommen!", "Aloha!", "Ahoi, Matrosen!",
    "Lok'tar!", "Ishnu-alah!", "Grüß Gott!", "Tach auch!",
    "Na, wie geht's?", "Auf in den Kampf!", "Heil und Segen!",
}

D.bye = {
    "Ciao for now", "Tschüsseldorf", "Adios Amigos", "Tschüssikowski",
    "San Frantschüssko", "Tschüsli Müsli", "Tschüssing", "Ciao Kakao",
    "Tschüssinger", "Ciao mit Au", "Bis Baldrian", "Ciaokelstuhl",
    "Bis dannimannski", "Bis Danzig", "Bis Denver", "Wirsing",
    "Bis denne, Antenne", "Hastalavista, Mister", "Tüdelü",
    "Bye Bye, Butterfly", "Hau rein, Brian",
    "Mach's gut, aber nicht zu oft", "Paris, Athen, auf Wiedersehn",
    "Tschüssen", "Ciao panthao", "Ciao Miau", "Bis dann, Hermann",
    "Mach's gut, ich machs besser", "Hau Reinhardt",
    "Man sieht sich. Wir ham ja Augen", "Bye Bye Kartoffelbrei",
    "Mach's gut, Schwing den Hut", "Ciao du Pfau", "Tschüssilinski",
    "Sayonara Carbonara", "Hau rein, du Stein", "Ade war schee",
    "Tudelu Känguru", "See you soon Sailor Moon", "Adieu Mathieu",
    "Rammel den Björn, auf wiederhörn", "Ferrero Tschüsschen",
    "Bundesgartenciao", "Bis Spätersilie", "Tchövapcici",
    "Auf Wirsing", "Goodbayern", "Machs Gucci",
    "Ciao mit V", "Auf Videosehen", "Tschüssi mit üssi",
}
