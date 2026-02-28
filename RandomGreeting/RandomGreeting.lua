-- ==========================================================
-- 1. STANDARD-SPRÜCHE (Das Start-Paket)
-- ==========================================================
local defaultMessages = {
    "Ciao for now",
    "Tschüsseldorf",
    "Adios Amigos",
    "Tschüssikowski",
    "San Frantschüssko",
    "Tschüsli Müsli",
    "Tschüssing",
    "Ciao Kakao",
    "Tschüssinger",
    "Ciao mit Au",
    "Adele",
    "Bis Baldrian",
    "Bis dannimannski",
    "Bis Danzig",
    "Bis Denver",
    "Erst die Rechte, dann die Linke. Beide machen winke, winke.",
    "Wirsing",
    "Bis denne, Antenne",
    "Hastalavista, Mister",
    "Tüdelü",
    "Bye Bye, Butterfly",
    "Hau rein, Brian",
    "Mach’s gut, aber nicht zu oft",
    "Paris, Athen, auf Wiedersehn",
    "Tschüssen",
    "Ciao panthao",
    "Ciao Miau",
    "Bis dann, Hermann",
    "Mach’s gut, ich machs besser",
    "Hau Reinhardt",
    "Man sieht sich. Wir ham ja Augen",
    "Bye Bye Kartoffelbrei",
    "Mach’s gut, Schwing den Hut",
    "ciao du Pfau",
    "Tschüssilinski",
    "Sayonara Carbonara",
    "Hau rein, du Stein",
    "Ade war schee",
    "Tudelu Känguru",
    "See you soon Sailor Moon",
    "Adieu Mathieu",
    "Rammel den Björn, auf wiederhörn",
    "Ferrero Tschüsschen",
    "Bundesgartenciao",
    "Bis Spätersilie",
    "Tchövapcici",
    "Auf wirsing",
    "Goodbayern",
    "Machs Gucci",
    "Ciao mit V",
    "Ciaokelstuhl",
    "Auf videosehen",
    "Tschüssi mit üssi"
}

-- ==========================================================
-- 2. DATENBANK & INITIALISIERUNG
-- ==========================================================
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, name)
    if name == "RandomGreeting" then
        RandomGreetingDB = RandomGreetingDB or {}
        -- Falls Liste leer oder neu, lade Standard-Sprüche
        if not RandomGreetingDB.customByeMessages or #RandomGreetingDB.customByeMessages == 0 then 
            RandomGreetingDB.customByeMessages = {}
            for _, v in ipairs(defaultMessages) do table.insert(RandomGreetingDB.customByeMessages, v) end
        end
        RandomGreetingDB.pool = RandomGreetingDB.pool or {}
        print("|cff00ff00RandomBye:|r Geladen. Nutze |cff00ccff/bye help|r")
    end
end)

-- Prüft den Counter und füllt ihn, wenn alle Sprüche einmal dran waren
local function CheckPool()
    if #RandomGreetingDB.pool == 0 then
        for i = 1, #RandomGreetingDB.customByeMessages do
            table.insert(RandomGreetingDB.pool, i)
        end
    end
end

-- ==========================================================
-- 3. SLASH-BEFEHLE & LOGIK
-- ==========================================================
SLASH_RANDOMGREETING1 = "/bye"
SlashCmdList["RANDOMGREETING"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do table.insert(args, word) end
    local cmd = args[1] and args[1]:lower() or ""

    -- BEFEHL: LISTE
    if cmd == "list" then
        print("|cff00ff00RandomBye Liste:|r")
        if #RandomGreetingDB.customByeMessages == 0 then
            print("  (Die Liste ist leer)")
        else
            for i, text in ipairs(RandomGreetingDB.customByeMessages) do
                print(string.format("|cff00ccff[%d]|r %s", i, text))
            end
        end

    -- BEFEHL: ADD
    elseif cmd == "add" then
        local newText = msg:sub(5):trim()
        if newText ~= "" then
            table.insert(RandomGreetingDB.customByeMessages, newText)
            RandomGreetingDB.pool = {} -- Reset damit der neue Spruch in die Rotation kommt
            print("|cff00ff00Hinzugefügt:|r " .. newText)
        end

    -- BEFEHL: REMOVE
    elseif cmd == "remove" then
        local id = tonumber(args[2])
        if id and RandomGreetingDB.customByeMessages[id] then
            local removed = table.remove(RandomGreetingDB.customByeMessages, id)
            RandomGreetingDB.pool = {} 
            print("|cffff0000Gelöscht:|r [" .. id .. "] " .. removed)
        else
            print("|cffff0000Fehler:|r Ungültige ID. Nutze /bye list")
        end

    -- BEFEHL: CLEAR
    elseif cmd == "clear" then
        if args[2] == "confirm" then
            RandomGreetingDB.customByeMessages = {}
            RandomGreetingDB.pool = {}
            print("|cffff0000RandomBye:|r Alles gelöscht!")
        else
            print("|cffff0000Warnung:|r Sicher? Tippe |cff00ccff/bye clear confirm|r")
        end

    -- BEFEHL: HELP
    elseif cmd == "help" then
        print("|cff00ff00RandomBye Hilfe:|r")
        print("  |cff00ccff/bye [s|g|p|r]|r - Senden (Say, Guild, Party, Raid)")
        print("  |cff00ccff/bye list|r - Zeigt alle Sprüche mit ID")
        print("  |cff00ccff/bye add [Text]|r - Spruch hinzufügen")
        print("  |cff00ccff/bye remove [ID]|r - Spruch löschen")
        print("  |cff00ccff/bye clear|r - Alles löschen")

    -- HAUPTFUNKTION: SPRUCH SENDEN
    else
        if #RandomGreetingDB.customByeMessages == 0 then
            print("|cffff0000Fehler:|r Liste leer! Nutze /bye add.")
            return
        end

        local target = (cmd == "s" and "SAY") or (cmd == "g" and "GUILD") or 
                       (cmd == "p" and "PARTY") or (cmd == "r" and "RAID")
        
        if not target then
            target = IsInRaid() and "RAID" or IsInGroup() and "PARTY" or "SAY"
        end

        CheckPool()
        local randomIndex = math.random(1, #RandomGreetingDB.pool)
        local messageIndex = table.remove(RandomGreetingDB.pool, randomIndex)
        
        SendChatMessage(RandomGreetingDB.customByeMessages[messageIndex], target)
    end
end

-- ==========================================================
-- 4. TAB-AUTOCOMPLETE
-- ==========================================================
local subCommands = {"list", "add", "remove", "clear", "help", "s", "g", "p", "r"}

hooksecurefunc("ChatEdit_CustomTabCompleteExecute", function(editBox)
    local text = editBox:GetText()
    if text:find("^/bye") then
        local command, rest = text:match("^(/%S+)%s*(.*)$")
        if command == "/bye" then
            for _, suggestion in ipairs(subCommands) do
                if suggestion:find("^" .. rest:lower()) then
                    editBox:SetText("/bye " .. suggestion .. " ")
                    return
                end
            end
        end
    end
end)