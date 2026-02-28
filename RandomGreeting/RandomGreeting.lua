-- ==========================================================
-- 1. STANDARD-LISTEN (Start-Pakete)
-- ==========================================================
local defaultByes = {
    "Ciao for now", "Tschüsseldorf", "Adios Amigos", "Tschüssikowski", 
    "San Frantschüssko", "Tschüsli Müsli", "Tschüssing", "Ciao Kakao", 
    "Tschüssinger", "Ciao mit Au", "Adele", "Bis Baldrian", 
    "Bis dannimannski", "Bis Danzig", "Bis Denver", "Wirsing", 
    "Bis denne, Antenne", "Hastalavista, Mister", "Tüdelü", "Bye Bye, Butterfly", 
    "Hau rein, Brian", "Mach’s gut, aber nicht zu oft", "Paris, Athen, auf Wiedersehn", 
    "Tschüssen", "Ciao panthao", "Ciao Miau", "Bis dann, Hermann", 
    "Mach’s gut, ich machs besser", "Hau Reinhardt", "Man sieht sich. Wir ham ja Augen", 
    "Bye Bye Kartoffelbrei", "Mach’s gut, Schwing den Hut", "ciao du Pfau", 
    "Tschüssilinski", "Sayonara Carbonara", "Hau rein, du Stein", "Ade war schee", 
    "Tudelu Känguru", "See you soon Sailor Moon", "Adieu Mathieu", 
    "Rammel den Björn, auf wiederhörn", "Ferrero Tschüsschen", "Bundesgartenciao", 
    "Bis Spätersilie", "Tchövapcici", "Auf wirsing", "Goodbayern", "Machs Gucci", 
    "Ciao mit V", "Ciaokelstuhl", "Auf videosehen", "Tschüssi mit üssi"
}

local defaultHis = {
    "Huhu!", "Hallöchen Popöchen!", "Moinsen!", "Greetings!", "Seid gegrüßt!",
    "Blood and Thunder!", "Blut und Donner!", "Light be with you.", "Das Licht mit euch.",
    "Time is money, friend!", "Zeit ist Geld, mein Freund!", "Well met!",
    "Ishnu-alah!", "Stay away from the Voodoo.", "Haltet euch vom Voodoo fern.",
    "Greetings, Earthlings!", "What's cooking, good looking?", "Aloha!",
    "Howdy, partner!", "Ahoy, Mateys!", "Moin Moin!", "Einen wunderschönen guten Gulasch!",
    "Level 100 Boss betritt das Gebäude!", "Bin bereit zum Lootsammeln!"
}

-- ==========================================================
-- 2. DATENBANK & INITIALISIERUNG
-- ==========================================================
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, name)
    if name == "RandomGreeting" then
        RandomGreetingDB = RandomGreetingDB or {}
        
        -- Tabellen für Begrüßungen (rhi)
        RandomGreetingDB.hiMessages = RandomGreetingDB.hiMessages or {}
        if #RandomGreetingDB.hiMessages == 0 then
            for _, v in ipairs(defaultHis) do table.insert(RandomGreetingDB.hiMessages, v) end
        end
        RandomGreetingDB.hiPool = RandomGreetingDB.hiPool or {}
        
        -- Tabellen für Abschiede (rbye)
        RandomGreetingDB.byeMessages = RandomGreetingDB.byeMessages or {}
        if #RandomGreetingDB.byeMessages == 0 then
            for _, v in ipairs(defaultByes) do table.insert(RandomGreetingDB.byeMessages, v) end
        end
        RandomGreetingDB.byePool = RandomGreetingDB.byePool or {}
        
        print("|cff00ff00RandomGreeting:|r Nutze |cff00ccff/rhi|r und |cff00ccff/rbye|r. Hilfe mit /rhi help.")
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Universal-Pool-Check
local function CheckPool(pool, messages)
    if #pool == 0 then
        for i = 1, #messages do table.insert(pool, i) end
    end
end

-- ==========================================================
-- 3. LOGIK-KERN (Universal-Funktion für beide Befehle)
-- ==========================================================
local function HandleCommand(msg, dbTable, poolTable, label, slash)
    local args = {}
    for word in msg:gmatch("%S+") do table.insert(args, word) end
    local cmd = args[1] and args[1]:lower() or ""

    if cmd == "list" then
        print("|cff00ff00" .. label .. " Liste:|r")
        if #dbTable == 0 then print("  (Leer)")
        else
            for i, text in ipairs(dbTable) do print(string.format("|cff00ccff[%d]|r %s", i, text)) end
        end
    elseif cmd == "add" then
        local newText = msg:sub(5):trim()
        if newText ~= "" then
            table.insert(dbTable, newText)
            wipe(poolTable)
            print("|cff00ff00" .. label .. " Hinzugefügt:|r " .. newText)
        end
    elseif cmd == "remove" then
        local id = tonumber(args[2])
        if id and dbTable[id] then
            local removed = table.remove(dbTable, id)
            wipe(poolTable)
            print("|cffff0000" .. label .. " Gelöscht:|r " .. removed)
        else
            print("|cffff0000Fehler:|r Ungültige ID.")
        end
    elseif cmd == "clear" then
        if args[2] == "confirm" then
            wipe(dbTable)
            wipe(poolTable)
            print("|cffff0000" .. label .. ":|r Alle Sprüche gelöscht!")
        else
            print("|cffff0000Warnung:|r Alle " .. label .. " löschen? Tippe |cff00ccff" .. slash .. " clear confirm|r")
        end
    elseif cmd == "help" then
        print("|cff00ff00" .. label .. " Hilfe:|r")
        print("  |cff00ccff" .. slash .. "|r - Zufällig senden")
        print("  |cff00ccff" .. slash .. " list|r - Zeigt alle Einträge")
        print("  |cff00ccff" .. slash .. " add [Text]|r - Eintrag hinzufügen")
        print("  |cff00ccff" .. slash .. " remove [ID]|r - Eintrag löschen")
    else
        if #dbTable == 0 then 
            print("|cffff0000Fehler:|r Keine Sprüche in " .. label .. "!")
            return 
        end
        local target = (cmd == "s" and "SAY") or (cmd == "g" and "GUILD") or (cmd == "p" and "PARTY") or (cmd == "r" and "RAID")
        if not target then target = IsInRaid() and "RAID" or IsInGroup() and "PARTY" or "SAY" end
        CheckPool(poolTable, dbTable)
        local idx = table.remove(poolTable, math.random(1, #poolTable))
        SendChatMessage(dbTable[idx], target)
    end
end

-- ==========================================================
-- 4. SLASH-COMMANDS REGISTRIERUNG
-- ==========================================================
SLASH_RANDOMHI1 = "/rhi"
SlashCmdList["RANDOMHI"] = function(msg) 
    HandleCommand(msg, RandomGreetingDB.hiMessages, RandomGreetingDB.hiPool, "Begrüßung", "/rhi") 
end

SLASH_RANDOMBYE1 = "/rbye"
SlashCmdList["RANDOMBYE"] = function(msg) 
    HandleCommand(msg, RandomGreetingDB.byeMessages, RandomGreetingDB.byePool, "Abschied", "/rbye") 
end

-- ==========================================================
-- 5. TAB-AUTOCOMPLETE
-- ==========================================================
local subCommands = {"list", "add", "remove", "clear", "help", "s", "g", "p", "r"}
hooksecurefunc("ChatEdit_CustomTabCompleteExecute", function(editBox)
    local text = editBox:GetText()
    local cmdUsed = text:match("^(/%S+)")
    if cmdUsed == "/rhi" or cmdUsed == "/rbye" then
        local rest = text:match("^/%S+%s*(.*)$") or ""
        for _, suggestion in ipairs(subCommands) do
            if suggestion:find("^" .. rest:lower()) then
                editBox:SetText(cmdUsed .. " " .. suggestion .. " ")
                return
            end
        end
    end
end)