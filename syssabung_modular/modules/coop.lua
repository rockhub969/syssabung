-- ==============================================================================
--              SYSHUB | MODUL COOP & INCUBATOR
-- ==============================================================================
return function(Context, CoopTab)
    local player = Context.player
    local Workspace = Context.Workspace
    local ReplicatedStorage = Context.ReplicatedStorage
    local invokeRemote = Context.invokeRemote
    local notify = Context.notify
    local printLog = Context.printLog
    local logError = Context.logError
    local UpdateHub = Context.UpdateHub
    local chickenMap = Context.chickenMap
    local chickenNames = Context.chickenNames
    local scanFlockChickens = Context.scanFlockChickens
    local saveConfig = Context.saveConfig
    local parseToggle = Context.parseToggle
    local expandDropdown = Context.expandDropdown
    local collectMyNestEggs = Context.collectMyNestEggs

-- [TAB: COOP]
-- ==============================================================================
do
    local CoopBuildingSec = CoopTab:Section({
        Title = "Coop & Recycler",
        Opened = false
    })

    CoopBuildingSec:Toggle({
        Title = "Auto Upgrade Coop",
        Flag = "auto_upgrade_coop",
        Callback = function(state)
            autoUpgradeCoop = parseToggle(state)
            saveConfig()
        end
    })

    CoopBuildingSec:Input({
        Title = "Coop Delay (s)",
        Flag = "coop_delay",
        Value = tostring(delayCoop),
        Callback = function(text)
            delayCoop = tonumber(text) or delayCoop
            saveConfig()
        end
    })

    CoopBuildingSec:Toggle({
        Title = "Auto Upgrade Recycler",
        Flag = "auto_upgrade_recycler",
        Callback = function(state)
            autoUpgradeRecycler = parseToggle(state)
            saveConfig()
        end
    })

    CoopBuildingSec:Input({
        Title = "Recycler Delay (s)",
        Flag = "recycler_delay",
        Value = tostring(delayRecycler),
        Callback = function(text)
            delayRecycler = tonumber(text) or delayRecycler
            saveConfig()
        end
    })

    local FeederSec = CoopTab:Section({
        Title = "Feeder Management",
        Opened = false
    })

    FeederSec:Toggle({
        Title = "Auto Buy Feeder",
        Flag = "auto_buy_feeder",
        Callback = function(state)
            autoBuyFeeder = parseToggle(state)
            saveConfig()
        end
    })

    FeederSec:Input({
        Title = "Buy Delay (s)",
        Flag = "buy_feeder_delay",
        Value = tostring(delayBuy),
        Callback = function(text)
            delayBuy = tonumber(text) or delayBuy
            saveConfig()
        end
    })

    FeederSec:Toggle({
        Title = "Auto Upgrade Feeder",
        Flag = "auto_upgrade_feeder",
        Callback = function(state)
            autoUpgradeFeeder = parseToggle(state)
            saveConfig()
        end
    })

    FeederSec:Input({
        Title = "Upgrade Feeder Delay (s)",
        Flag = "upgrade_feeder_delay",
        Value = tostring(delayUpgrade),
        Callback = function(text)
            delayUpgrade = tonumber(text) or delayUpgrade
            saveConfig()
        end
    })

    local EggSec = CoopTab:Section({
        Title = "Auto Collect Egg",
        Opened = false
    })

    EggSec:Button({
        Title = "Ambil Semua Telur Sarang Sekarang",
        Callback = function()
            local count = collectMyNestEggs(true)
            if count > 0 then
                notify("Auto Collect Egg", count .. " telur berhasil diambil ke tas!")
            else
                notify("Auto Collect Egg", "Tidak ada telur di sarang saat ini.")
            end
        end
    })

    EggSec:Toggle({
        Title = "Auto Claim Telur Coop",
        Flag = "auto_collect_nest_eggs",
        Callback = function(state)
            autoCollectNestEggs = parseToggle(state)
            saveConfig()
            if autoCollectNestEggs then
                local count = collectMyNestEggs(false)
                if count > 0 then
                    notify("Auto Collect Egg", count .. " telur terdeteksi & diambil ke tas!")
                end
            end
        end
    })

    local IncubatorSec = CoopTab:Section({
        Title = "Auto Incubator",
        Opened = false
    })

    IncubatorSec:Toggle({
        Title = "Auto Claim Telur Incubator",
        Flag = "auto_claim_incubator",
        Callback = function(state)
            autoClaimIncubator = parseToggle(state)
        end
    })

    chickenDropdown = IncubatorSec:Dropdown({
        Title = "Ayam Incubator:",
        Flag = "selected_incubator_chicken_name",
        Values = chickenNames,
        Value = chickenNames[1],
        MenuWidth = 300,
        Multi = false,
        Callback = function(val)
            selectedChickenName = val
            if chickenMap[val] then
                selectedChickenId = chickenMap[val].Id
            end
        end
    })
    if expandDropdown then
        expandDropdown(chickenDropdown, 300)
    end

    IncubatorSec:Button({
        Title = "Refresh List Ayam",
        Callback = function()
            scanFlockChickens()
            if #chickenNames > 0 and chickenNames[1] ~= "Buka menu Flock di game lalu klik Refresh!" then
                notify("Incubator", "Berhasil mendeteksi " .. tostring(#chickenNames) .. " ayam di kawanan!")
            else
                notify("Incubator", "Buka menu Flock di game lalu klik Refresh!")
            end
        end
    })

    IncubatorSec:Toggle({
        Title = "Auto Put Ayam ke Incubator",
        Flag = "auto_put_incubator",
        Callback = function(state)
            autoPutIncubator = parseToggle(state)
        end
    })

    IncubatorSec:Toggle({
        Title = "Auto Upgrade Incubator",
        Flag = "auto_upgrade_incubator",
        Callback = function(state)
            autoUpgradeIncubator = parseToggle(state)
        end
    })

    IncubatorSec:Input({
        Title = "Upgrade Delay (s)",
        Flag = "delay_upgrade_incubator",
        Value = tostring(delayUpgradeIncubator),
        Callback = function(text)
            delayUpgradeIncubator = tonumber(text) or delayUpgradeIncubator
        end
    })

    -- ==============================================================================
    -- SECTION: AUTO OPEN EGG
    -- ==============================================================================
    local OpenEggSec = FlockTab:Section({
        Title = "Auto Open Egg",
        Opened = false
    })

    local VALID_OFFICIAL_EGGS = {
        ["FORTUNE EGG"] = "Fortune Egg",
        ["COLOSSUS EGG"] = "Colossus Egg",
        ["CHARM EGG"] = "Charm Egg",
        ["THUNDER EGG"] = "Thunder Egg",
        ["VOID EGG"] = "Void Egg",
        ["TRICK EGG"] = "Trick Egg",
        ["ASCENSION EGG"] = "Ascension Egg",
        ["CIRCUIT EGG"] = "Circuit Egg",
        ["HAUNT EGG"] = "Haunt Egg",
        ["ROYAL EGG"] = "Royal Egg",
        ["SCRATCH EGG"] = "Scratch Egg",
        ["GRUDGE EGG"] = "Grudge Egg",
        ["DEMONIC EGG"] = "Demonic Egg",
        ["NEST EGG"] = "Nest Egg",
        ["BLAZING EGG"] = "Blazing Egg",
        ["TROPHY EGG"] = "Trophy Egg",
        ["CURSED EGG"] = "Cursed Egg",
        ["BLOOM EGG"] = "Bloom Egg",
        ["DINER EGG"] = "Diner Egg",
        ["ARENA EGG"] = "Arena Egg",
        ["FANG EGG"] = "Fang Egg",
        ["ORDNANCE EGG"] = "Ordnance Egg",
        ["BLESSED EGG"] = "Blessed Egg"
    }

    local EGG_ID_BY_NAME = {
        ["Fortune Egg"] = "golden",
        ["Colossus Egg"] = "colossus",
        ["Charm Egg"] = "charm",
        ["Thunder Egg"] = "storm",
        ["Void Egg"] = "void",
        ["Trick Egg"] = "trick",
        ["Ascension Egg"] = "ascension",
        ["Circuit Egg"] = "circuit",
        ["Haunt Egg"] = "haunt",
        ["Royal Egg"] = "crown",
        ["Scratch Egg"] = "feed",
        ["Grudge Egg"] = "rival",
        ["Demonic Egg"] = "demonic",
        ["Nest Egg"] = "barn",
        ["Blazing Egg"] = "hotEgg",
        ["Trophy Egg"] = "trophy",
        ["Cursed Egg"] = "meme",
        ["Bloom Egg"] = "bloom",
        ["Diner Egg"] = "diner",
        ["Arena Egg"] = "arena",
        ["Fang Egg"] = "fang",
        ["Ordnance Egg"] = "ordnance",
        ["Blessed Egg"] = "blessed"
    }

    local EGG_NAME_BY_ID = {}
    for name, id in pairs(EGG_ID_BY_NAME) do
        EGG_NAME_BY_ID[id] = name
    end

    local STATIC_EGG_POOLS = {
        ["Arena Egg"] = {
            "Agent Cluck", "Baron Cluck", "Belt Champion", "Blitz Rooster",
            "Caddie Rooster", "Capoeira Rooster", "Clown Chick", "Enforcer Rooster",
            "Luchador", "Skater Chick", "Slugger Hen", "Southpaw Hen",
            "Spider Chicken", "Strike Hen", "Striker Hen", "Sumo Rooster"
        },
        ["Ascension Egg"] = {
            "Eclipse Hen", "Halo Hen", "Oracle Chick", "Seraph Rooster",
            "Skyscrest Rooster"
        },
        ["Blazing Egg"] = {
            "Agent Cluck", "Astro Chick", "Aurora Hen", "Baron Cluck",
            "Blitz Rooster", "Boba Hen", "Bravo Rooster", "Commando Rooster",
            "Cosmo Brat", "Crest Rooster", "Crystal Hen", "DJ Rooster",
            "Doll Hen", "Drone Hen", "Error Chick", "Farmer Rooster",
            "Fine Rooster", "Founder Rooster", "Ghost Hen", "Glam Hen",
            "Golden Goose", "Hacker Hen", "Impostor Chick", "Kitty Chick",
            "Laser Rooster", "Loco Rooster", "Mecha Rooster", "Mime Hen",
            "Mummy Hen", "Nebula Hen", "Nine-Tail Hen", "Overclock Rooster",
            "Prism Rooster", "Radiant Fenghuang", "Reaper Rooster", "Sergeant Hen",
            "Shadow Rooster", "Singularity Hen", "Slugger Hen", "Spider Chicken",
            "Unicorn Hen", "Vampire Rooster", "Viking Rooster", "Viper Hen",
            "Voidbeak", "Zodiac Hen"
        },
        ["Blessed Egg"] = {
            "Angel Chicken", "Beacon Rooster", "Mercy Hen"
        },
        ["Bloom Egg"] = {
            "Butterfly Hen", "Cauldron Hen", "Crystal Hen", "Fairy Hen",
            "Heart Hen", "Idol Hen", "Mermaid Hen", "Pastel Goth",
            "Unicorn Hen", "Zodiac Hen"
        },
        ["Charm Egg"] = {
            "Ballet Hen", "Boba Hen", "Bow Chick", "Cheer Chick",
            "Cupcake Chick", "Glam Hen", "Kitty Chick", "Manicure Hen",
            "Plush Chick", "Spa Hen"
        },
        ["Circuit Egg"] = {
            "Drone Hen", "Hacker Hen", "Laser Rooster", "Magnet Hen",
            "Mecha Rooster", "Nano Rooster", "Overclock Rooster", "Taser Hen"
        },
        ["Colossus Egg"] = {
            "Catalyst Hen", "Ironcluck", "Rumble Rooster", "Shockwave Hen",
            "Storm Colossus", "Talon Titan"
        },
        ["Cursed Egg"] = {
            "Bonk Hen", "Deep Fried Hen", "Error Chick", "Fine Rooster",
            "Impostor Chick", "Karaoke Rooster", "NPC Chick", "Sigma Rooster",
            "Stone Face", "Stonks Hen"
        },
        ["Demonic Egg"] = {
            "Devil Chicken", "Hex Rooster", "Pact Hen"
        },
        ["Diner Egg"] = {
            "Barista Hen", "Bucket Rooster", "Chef Rooster", "DJ Rooster",
            "Janitor Rooster", "Mime Hen", "Nugget Chick", "Pizza Rooster",
            "Plumber Hen", "Sushi Hen"
        },
        ["Fang Egg"] = {
            "Beast Rooster", "Bombardier Rooster", "Bravo Rooster", "Bunker Hen",
            "Chameleon Hen", "Eel Hen", "Founder Rooster", "Hive Rooster",
            "Mantis Hen", "Pufferhen", "Reek Rooster", "Shark Chicken",
            "Snapper", "Viking Rooster", "Viper Hen"
        },
        ["Fortune Egg"] = {
            "Baron Cluck", "Founder Rooster", "Golden Goose", "Sovereign Rooster"
        },
        ["Grudge Egg"] = {
            "Agent Cluck", "Belt Champion", "Duelist Rooster"
        },
        ["Haunt Egg"] = {
            "Bone Rooster", "Clown Chick", "Doll Hen", "Ghost Hen",
            "Jack Rooster", "Mummy Hen", "Reaper Rooster", "Shadow Rooster",
            "Vampire Rooster", "Zombie Chick"
        },
        ["Nest Egg"] = {
            "Classic Rooster", "Cosmo Brat", "Farmer Rooster", "Viking Rooster"
        },
        ["Ordnance Egg"] = {
            "Bulwark Knight", "Commando Rooster", "Flame Rooster", "Founder Rooster",
            "Loco Rooster", "Medic Hen", "Riot Hen", "Ronin Hen",
            "Sapper Hen", "Sergeant Hen", "Shadow Ninja", "Sniper Rooster",
            "Tank Rooster"
        },
        ["Royal Egg"] = {
            "Barcelos", "Baron Cluck", "Basilisk Rooster", "Cockatrice",
            "Crest Rooster", "Founder Rooster", "Jackal Rooster", "Nine-Tail Hen",
            "Phoenix Hen", "Radiant Fenghuang", "Spider Chicken", "Tengu Rooster",
            "Twin Rooster", "Valkyrie Hen"
        },
        ["Scratch Egg"] = {
            "Bow Chick", "Cosmo Brat", "Crest Rooster", "Farmer Rooster",
            "NPC Chick", "Pizza Rooster", "Sergeant Hen", "Slugger Hen",
            "Taser Hen", "Viking Rooster"
        },
        ["Thunder Egg"] = {
            "Astro Chick", "Aurora Hen", "Boom Rooster", "Commando Rooster",
            "Crest Rooster", "Founder Rooster", "Frostbite Hen", "Magma Rooster",
            "Prism Rooster", "Quake Rooster", "Sandstorm Rooster", "Sergeant Hen",
            "Static Chick", "Tsunami Hen", "Twister Hen", "Viking Rooster"
        },
        ["Trick Egg"] = {
            "Ace Rooster", "Checkmate Hen", "Domino Chick", "High Roller Rooster",
            "Puzzle Hen"
        },
        ["Trophy Egg"] = {
            "Banner Hen", "Bulwark Hen", "Duelist Rooster", "Grandmaster Rooster",
            "Squire Chick"
        },
        ["Void Egg"] = {
            "Alien Chick", "Astro Chick", "Comet Rooster", "Moonwalk Hen",
            "Nebula Hen", "Orbital Hen", "Probe Rooster", "Singularity Hen",
            "Solar Rooster", "Voidbeak"
        }
    }

    local function cleanEggName(name)
        if type(name) == "table" then
            name = name.Title or name.Name or name[1] or ""
        end
        if not name or type(name) ~= "string" then return "" end
        local clean = name:gsub("%s*%(.*%)", ""):gsub("%s*[xX]%d+", ""):gsub("^%s*(.-)%s*$", "%1")
        local off = VALID_OFFICIAL_EGGS[clean:upper()]
        return off or clean
    end

    local function getEggPool(eggName)
        local clean = cleanEggName(eggName)
        if clean == "" then
            clean = "Fortune Egg"
        end

        local pool = STATIC_EGG_POOLS[clean]
        if not pool then
            local cleanLower = clean:lower():gsub("%s*egg$", "")
            for k, p in pairs(STATIC_EGG_POOLS) do
                local kLower = k:lower():gsub("%s*egg$", "")
                if cleanLower == kLower then
                    pool = p
                    break
                end
            end
        end

        local result = {}
        if pool and #pool > 0 then
            for _, sp in ipairs(pool) do
                table.insert(result, sp)
            end
        else
            table.insert(result, "Classic Rooster")
        end

        table.sort(result)
        return result
    end



    UpdateHub.scanPlayerOwnedEggs = function()
        local detectedMap = {}
        local detectedList = {}

        local function addEgg(offName, qtyStr)
            if not detectedMap[offName] then
                detectedMap[offName] = true
                local disp = offName
                if qtyStr and qtyStr ~= "" then
                    local cleanQty = qtyStr:gsub("^%s*(.-)%s*$", "%1"):lower()
                    if not cleanQty:find("^x") then
                        cleanQty = "x" .. cleanQty
                    end
                    disp = string.format("%s (%s)", offName, cleanQty)
                end
                table.insert(detectedList, disp)
            end
        end

        -- [1] SCAN INSTAN VIA DATASERVICE (0ms, SANGAT SMOOTH TANPA FREEZE)
        pcall(function()
            local dsClient = getSharedDataServiceClient()
            local raw = dsClient and dsClient._data and dsClient._data._data
            if raw then
                local eggTbl = raw.eggs or (raw.roster and raw.roster.eggs) or (raw.inventory and raw.inventory.eggs)
                if type(eggTbl) == "table" then
                    for k, v in pairs(eggTbl) do
                        local count = 0
                        if type(v) == "number" then
                            count = v
                        elseif type(v) == "table" then
                            count = tonumber(v.count or v.amount or v.qty or v[1]) or 0
                        end
                        if count > 0 then
                            local eggId = tostring(k):lower():gsub("_egg$", ""):gsub("%s*egg$", "")
                            local offName = EGG_NAME_BY_ID[eggId] or VALID_OFFICIAL_EGGS[tostring(k):upper()]
                            if offName then
                                addEgg(offName, "x" .. tostring(count))
                            end
                        end
                    end
                end
            end
        end)

        -- [2] SCAN VIA PLAYERGUI FLOCK / INVENTORY (RINGAN & SHALLOW, TIDAK MEMBEBANI ENGINE)
        pcall(function()
            local pg = player:FindFirstChild("PlayerGui")
            if not pg then return end

            for _, desc in ipairs(pg:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Text and desc.Text ~= "" then
                    local tUpper = desc.Text:upper():gsub("^%s*(.-)%s*$", "%1")
                    local offName = VALID_OFFICIAL_EGGS[tUpper]
                    if offName then
                        local fn = desc:GetFullName()
                        if not fn:find("Index") and not fn:find("Templates") and not fn:find("Shop") then
                            local card = desc.Parent
                            local qty = nil
                            if card then
                                for _, sib in ipairs(card:GetChildren()) do
                                    if sib:IsA("TextLabel") and sib ~= desc then
                                        local st = sib.Text:gsub("^%s*(.-)%s*$", "%1")
                                        if st:match("^[xX]%d+$") or st:match("^%d+$") then
                                            qty = st
                                            break
                                        end
                                    end
                                end
                                if not qty then
                                    for _, sib in ipairs(card:GetChildren()) do
                                        if sib:IsA("GuiObject") then
                                            for _, sub in ipairs(sib:GetChildren()) do
                                                if sub:IsA("TextLabel") and sub ~= desc then
                                                    local st = sub.Text:gsub("^%s*(.-)%s*$", "%1")
                                                    if st:match("^[xX]%d+$") or st:match("^%d+$") then
                                                        qty = st
                                                        break
                                                    end
                                                end
                                            end
                                            if qty then break end
                                        end
                                    end
                                end
                            end
                            if qty then
                                addEgg(offName, qty)
                            end
                        end
                    end
                end
            end
        end)

        if #detectedList == 0 then
            return {"Buka menu Flock di game lalu klik Refresh Telur"}
        end

        table.sort(detectedList)
        return detectedList
    end

    local function snapshotFlockIds()
        local ids = {}
        local gotFromDs = false
        pcall(function()
            local dsClient = getSharedDataServiceClient()
            local raw = dsClient and dsClient._data and dsClient._data._data
            if raw and raw.roster and raw.roster.chickens and type(raw.roster.chickens) == "table" then
                for _, ch in pairs(raw.roster.chickens) do
                    if type(ch) == "table" and ch.id then
                        local cId = tostring(ch.id)
                        ids[cId] = true
                        local numId = tonumber(string.match(cId, "%d+"))
                        if numId then
                            ids[numId] = true
                        end
                        gotFromDs = true
                    end
                end
            end
        end)
        -- Fallback hanya jika DataService kosong/tidak ada
        if not gotFromDs then
            pcall(function()
                local playerGui = player:FindFirstChild("PlayerGui")
                if playerGui then
                    for _, desc in ipairs(playerGui:GetDescendants()) do
                        local matchNum = string.match(desc.Name, "^c(%d+)$")
                        if matchNum and (desc:IsA("Frame") or desc:IsA("GuiObject") or desc:IsA("TextButton")) then
                            ids[desc.Name] = true
                            local numId = tonumber(matchNum)
                            if numId then
                                ids[numId] = true
                            end
                        end
                    end
                end
            end)
        end
        return ids
    end

    -- AUTO SELL FILTER: HANYA jual ayam BARU yang menetas saat open egg dan tidak dipilih
    -- AYAM YANG SUDAH ADA DI KAWANAN SEBELUM BUKA TELUR 100% AMAN & TIDAK DIJUAL!
    UpdateHub.executeHatchAutoFilter = function(preHatchSnapshot)
        -- KEAMANAN MUTLAK: Jika tidak ada snapshot pre-hatch, jangan pernah jual ayam apa pun!
        if not preHatchSnapshot or not next(preHatchSnapshot) then
            return 0
        end

        local toSellList = {}
        local keepCount = 0
        local processedFromDs = false

        -- Engine 1: Cek langsung via DataService memory (0ms, sangat ringan tanpa freeze)
        pcall(function()
            local dsClient = getSharedDataServiceClient()
            local raw = dsClient and dsClient._data and dsClient._data._data
            if raw and raw.roster and raw.roster.chickens and type(raw.roster.chickens) == "table" then
                processedFromDs = true
                for k, ch in pairs(raw.roster.chickens) do
                    local cId = tostring((type(ch) == "table" and ch.id) or k)
                    local numId = tonumber(string.match(cId, "%d+"))

                    -- JIKA SUDAH ADA DI KAWANAN SEBELUM BUKA TELUR -> LEWATI (100% TIDAK DIJUAL)!
                    local isPreExisting = preHatchSnapshot[cId] or (numId and preHatchSnapshot[numId])
                    if not isPreExisting and type(ch) == "table" then
                        local speciesName = formatSpeciesName(ch.typeId)
                        local stars = tonumber(ch.promo) or 0
                        local isFav = (ch.favorite == true) or favoritedChickenIds[cId] or (numId and favoritedChickenIds[numId])
                        local isProm = (stars > 0) or promotedChickenIds[cId] or (numId and promotedChickenIds[numId])

                        if not isFav and not isProm then
                            local isInverted = false
                            local isJurassic = false
                            if ch.mutation then
                                local m = type(ch.mutation) == "string" and ch.mutation or (type(ch.mutation) == "table" and ch.mutation.name)
                                if m then
                                    local mLower = tostring(m):lower()
                                    if mLower:find("inverted") then
                                        isInverted = true
                                    end
                                    if mLower:find("jurassic") then
                                        isJurassic = true
                                    end
                                end
                            end

                            local shouldKeep = false
                            if isInverted and UpdateHub.autoKeepInverted then
                                shouldKeep = true
                            end
                            if isJurassic and UpdateHub.autoKeepJurassic then
                                shouldKeep = true
                            end
                            if ch.mutation and tostring(ch.mutation):lower() ~= "none" and tostring(ch.mutation) ~= "" and not isInverted and not isJurassic then
                                shouldKeep = true -- Proteksi mutasi masa depan
                            end

                            if not shouldKeep then
                                local normCName = speciesName:upper()
                                for keepName, isKeep in pairs(UpdateHub.selectedKeepSpecies) do
                                    if isKeep == true then
                                        local normKeep = keepName:upper()
                                        if normCName == normKeep or normCName:find(normKeep) or normKeep:find(normCName) then
                                            shouldKeep = true
                                            break
                                        end
                                    end
                                end
                            end

                            if shouldKeep then
                                keepCount = keepCount + 1
                            else
                                table.insert(toSellList, { idStr = cId, idNum = numId, name = speciesName })
                            end
                        end
                    end
                end
            end
        end)

        -- Engine 2: Fallback cek via PlayerGui (hanya jika DataService tidak aktif)
        if not processedFromDs and #toSellList == 0 then
            pcall(function()
                local playerGui = player:FindFirstChild("PlayerGui")
                if not playerGui then return end

                for _, desc in ipairs(playerGui:GetDescendants()) do
                    local matchNum = string.match(desc.Name, "^c(%d+)$")
                    if matchNum and (desc:IsA("Frame") or desc:IsA("GuiObject") or desc:IsA("TextButton")) then
                        local cId = desc.Name
                        local numId = tonumber(matchNum)

                        local isPreExisting = preHatchSnapshot[cId] or (numId and preHatchSnapshot[numId])
                        if not isPreExisting then
                            local cName = nil
                            for _, child in ipairs(desc:GetChildren()) do
                                if child:IsA("TextLabel") and child.Text and child.Text ~= "" then
                                    local t = child.Text:gsub("^%s*(.-)%s*$", "%1")
                                    local tl = t:lower()
                                    if not tl:find("lvl") and not tl:find("lv") and not tl:find("^x%d+") and not tl:find("%$") and not tl:find("^%+") and #t > 1 and tl ~= "chicken name" then
                                        cName = t
                                        break
                                    end
                                end
                            end

                            if cName then
                                local isFav = favoritedChickenIds[cId] or (numId and favoritedChickenIds[numId]) or desc:GetAttribute("Favorite") == true or desc:FindFirstChild("Favorite")
                                local isPromoted = isChickenPromoted(desc, cId, numId)

                                if not isFav and not isPromoted then
                                    local isInverted = false
                                    local isJurassic = false
                                    local attrMut = desc:GetAttribute("Mutation") or desc:GetAttribute("ovMutation") or desc:GetAttribute("mutation")
                                    if attrMut and type(attrMut) == "string" then
                                        local aLower = attrMut:lower()
                                        if aLower:find("inverted") then isInverted = true end
                                        if aLower:find("jurassic") then isJurassic = true end
                                    else
                                        for _, child in ipairs(desc:GetChildren()) do
                                            if child:IsA("TextLabel") and child.Text then
                                                local tLower = child.Text:lower()
                                                if tLower:find("inverted") then
                                                    isInverted = true
                                                end
                                                if tLower:find("jurassic") then
                                                    isJurassic = true
                                                end
                                            end
                                        end
                                    end

                                    local shouldKeep = false
                                    if isInverted and UpdateHub.autoKeepInverted then
                                        shouldKeep = true
                                    end
                                    if isJurassic and UpdateHub.autoKeepJurassic then
                                        shouldKeep = true
                                    end
                                    if (attrMut and tostring(attrMut):lower() ~= "none" and tostring(attrMut) ~= "") and not isInverted and not isJurassic then
                                        shouldKeep = true -- Proteksi mutasi masa depan
                                    end

                                    if not shouldKeep then
                                        local normCName = cName:upper()
                                        for keepName, isKeep in pairs(UpdateHub.selectedKeepSpecies) do
                                            if isKeep == true then
                                                local normKeep = keepName:upper()
                                                if normCName == normKeep or normCName:find(normKeep) or normKeep:find(normCName) then
                                                    shouldKeep = true
                                                    break
                                                end
                                            end
                                        end
                                    end

                                    if shouldKeep then
                                        keepCount = keepCount + 1
                                    else
                                        table.insert(toSellList, {
                                            idStr = cId,
                                            idNum = numId,
                                            name = cName
                                        })
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end

        if #toSellList > 0 then
            local allStrIds = {}
            for _, it in ipairs(toSellList) do
                table.insert(allStrIds, it.idStr)
            end

            -- Eksekusi penjualan dalam background thread terpisah tanpa membekukan main render thread
            task.spawn(function()
                pcall(function()
                    invokeRemote("SellChickens", allStrIds)
                end)

                printLog("Auto Open Egg", string.format("Filter selesai: %d ayam baru disimpan, %d ayam baru non-pilihan berhasil dijual!", keepCount, #toSellList))
                notify("Auto Open Egg", string.format("%d ayam baru non-pilihan berhasil dijual (Ayam lama tetap aman)!", #toSellList))

                -- Refresh dropdown flock secara halus & ter-debounce (anti-freeze)
                requestFlockScan(0.8)


            end)
        elseif keepCount > 0 then
            requestFlockScan(1.0)
        end

        return #toSellList
    end

    -- FUNGSI HATCH DENGAN SISTEM PENGULANGAN (BATCH) & JEDA AMAN ANTI-FREEZE
    local HATCH_WAIT_1X  = 0.8
    local HATCH_WAIT_10X = 1.2

    UpdateHub.executeHatchBatch = function(amountPerHatch, repeatCount, eggName)
        if UpdateHub.isHatchingEggs then
            notify("Auto Open Egg", "Proses buka telur sedang berjalan! Klik 'Stop Buka Telur' untuk menghentikan.")
            return
        end
        UpdateHub.isHatchingEggs = true
        UpdateHub.stopHatching = false

        local targetEgg = eggName or UpdateHub.selectedEggType
        local cleanName = cleanEggName(targetEgg)
        local eggId = EGG_ID_BY_NAME[cleanName] or cleanName:lower():gsub("%s+", "_")
        local totalCycles = math.max(1, tonumber(repeatCount) or 1)
        local hatchAmount = tonumber(amountPerHatch) or 10

        notify("Auto Open Egg", string.format("Memulai buka %s: %dx pengulangan (%dx telur per siklus)...", tostring(targetEgg), totalCycles, hatchAmount))

        task.spawn(function()
            for cycle = 1, totalCycles do
                if UpdateHub.stopHatching then
                    notify("Auto Open Egg", string.format("Buka telur dihentikan pada siklus %d/%d.", cycle - 1, totalCycles))
                    printLog("Auto Open Egg", string.format("Proses dihentikan oleh pengguna pada siklus %d/%d.", cycle - 1, totalCycles))
                    break
                end

                local preSnapshot = snapshotFlockIds()

                -- Eksekusi Remote Buka Telur
                pcall(function()
                    if hatchAmount == 10 then
                        local ok = invokeRemote("HatchEggs", eggId, 10)
                        if not ok then
                            invokeRemote("HatchEgg", eggId, 10)
                        end
                    else
                        local ok = invokeRemote("HatchEggs", eggId, 1)
                        if not ok then
                            invokeRemote("HatchEgg", eggId)
                        end
                    end
                end)

                -- Jeda aman menunggu animasi & data server
                local waitTime = (hatchAmount == 10) and HATCH_WAIT_10X or HATCH_WAIT_1X
                task.wait(waitTime)

                -- Eksekusi penyaringan & auto sell instan (0ms freeze)
                local sold = UpdateHub.executeHatchAutoFilter(preSnapshot)

                printLog("Auto Open Egg", string.format("Siklus [%d/%d] tuntas! (%d ayam non-pilihan terjual)", cycle, totalCycles, sold or 0))

                -- Jeda singkat antar siklus jika masih ada pengulangan berikutnya
                if cycle < totalCycles and not UpdateHub.stopHatching then
                    task.wait(0.4)
                end
            end

            UpdateHub.isHatchingEggs = false
            UpdateHub.stopHatching = false
            notify("Auto Open Egg", string.format("Selesai membuka telur %s (%dx pengulangan)!", tostring(targetEgg), totalCycles))
        end)
    end

    UpdateHub.executeHatchSingle = function(eggName)
        UpdateHub.executeHatchBatch(1, 1, eggName)
    end

    UpdateHub.executeHatchTen = function(eggName)
        UpdateHub.executeHatchBatch(10, 1, eggName)
    end

    local initialEggList = UpdateHub.scanPlayerOwnedEggs()
    if #initialEggList > 0 and initialEggList[1] ~= "Buka menu Flock di game lalu klik Refresh Telur" then
        UpdateHub.selectedEggType = initialEggList[1]
    else
        UpdateHub.selectedEggType = "Fortune Egg"
    end

    local initialPool = getEggPool(UpdateHub.selectedEggType)
    UpdateHub.selectedKeepSpecies = {}
    for _, sp in ipairs(initialPool) do
        UpdateHub.selectedKeepSpecies[sp] = true
    end

    local function syncKeepDropdown(newPool)
        if not UpdateHub.eggKeepDropdown then return end
        pcall(function()
            if type(UpdateHub.eggKeepDropdown.Refresh) == "function" then
                UpdateHub.eggKeepDropdown:Refresh(newPool)
            end
            if type(UpdateHub.eggKeepDropdown.Select) == "function" then
                UpdateHub.eggKeepDropdown:Select(newPool)
            elseif type(UpdateHub.eggKeepDropdown.SetValue) == "function" then
                UpdateHub.eggKeepDropdown:SetValue(newPool)
            end
            if expandDropdown then
                expandDropdown(UpdateHub.eggKeepDropdown, 300)
            end
        end)
    end

    -- 1. TIPE TELUR & DETEKSI TELUR DI KAWANAN
    UpdateHub.eggDropdown = OpenEggSec:Dropdown({
        Title = "Tipe Telur (Pilih Telur):",
        Values = initialEggList,
        Value = UpdateHub.selectedEggType,
        MenuWidth = 300,
        Multi = false,
        Callback = function(val)
            local chosenStr = (type(val) == "table" and (val.Title or val.Name or val[1])) or val
            if not chosenStr or chosenStr == "" then return end
            UpdateHub.selectedEggType = chosenStr
            local cleanName = cleanEggName(chosenStr)
            local newPool = getEggPool(cleanName)
            UpdateHub.selectedKeepSpecies = {}
            for _, sp in ipairs(newPool) do
                UpdateHub.selectedKeepSpecies[sp] = true
            end
            syncKeepDropdown(newPool)
        end
    })
    if expandDropdown then
        expandDropdown(UpdateHub.eggDropdown, 300)
    end

    OpenEggSec:Button({
        Title = "Deteksi / Refresh Telur Dimiliki",
        Callback = function()
            local detected = UpdateHub.scanPlayerOwnedEggs()
            if UpdateHub.eggDropdown then
                pcall(function()
                    if type(UpdateHub.eggDropdown.Refresh) == "function" then
                        UpdateHub.eggDropdown:Refresh(detected)
                    elseif type(UpdateHub.eggDropdown.SetValues) == "function" then
                        UpdateHub.eggDropdown:SetValues(detected)
                    end
                    if expandDropdown then
                        expandDropdown(UpdateHub.eggDropdown, 300)
                    end
                end)
            end
            if #detected > 0 and detected[1] ~= "Buka menu Flock di game lalu klik Refresh Telur" then
                notify("Auto Open Egg", "Berhasil mendeteksi " .. tostring(#detected) .. " jenis telur di kawanan!")
                local cur = UpdateHub.selectedEggType
                local match = false
                for _, egg in ipairs(detected) do
                    if egg == cur then
                        match = true
                        break
                    end
                end
                if not match and detected[1] then
                    UpdateHub.selectedEggType = detected[1]
                    local cleanName = cleanEggName(detected[1])
                    local newPool = getEggPool(cleanName)
                    UpdateHub.selectedKeepSpecies = {}
                    for _, sp in ipairs(newPool) do
                        UpdateHub.selectedKeepSpecies[sp] = true
                    end
                    syncKeepDropdown(newPool)
                end
            else
                notify("Auto Open Egg", "Buka menu Flock di game lalu klik Refresh Telur!")
            end
        end
    })

    -- 2. DROPDOWN LIST JENIS AYAM DARI TELUR & FILTER SIMPAN
    UpdateHub.eggKeepDropdown = OpenEggSec:Dropdown({
        Title = "Ayam yang Ingin Disimpan (Keep):",
        Values = initialPool,
        Value = initialPool,
        MenuWidth = 300,
        Multi = true,
        Callback = function(list)
            UpdateHub.selectedKeepSpecies = {}
            if type(list) == "table" then
                for k, v in pairs(list) do
                    if type(k) == "string" and v == true then
                        UpdateHub.selectedKeepSpecies[k] = true
                    elseif type(v) == "string" then
                        UpdateHub.selectedKeepSpecies[v] = true
                    end
                end
            elseif type(list) == "string" then
                UpdateHub.selectedKeepSpecies[list] = true
            end
        end
    })
    if expandDropdown then
        expandDropdown(UpdateHub.eggKeepDropdown, 300)
    end

    -- 3. TRIGGER / TOGGLE AUTO SIMPAN SEMUA AYAM INVERTED
    OpenEggSec:Toggle({
        Title = "Auto Simpan Semua Ayam Inverted [🌀]",
        Flag = "auto_keep_inverted",
        Value = UpdateHub.autoKeepInverted,
        Callback = function(state)
            UpdateHub.autoKeepInverted = parseToggle(state)
            if UpdateHub.autoKeepInverted then
                notify("Auto Open Egg", "Ayam mutasi Inverted [🌀] akan selalu disimpan!")
            else
                notify("Auto Open Egg", "Ayam mutasi Inverted TIDAK diproteksi khusus.")
            end
            saveConfig()
        end
    })

    -- 4. TRIGGER / TOGGLE AUTO SIMPAN SEMUA AYAM JURASSIC
    OpenEggSec:Toggle({
        Title = "Auto Simpan Semua Ayam Jurassic [🦖]",
        Flag = "auto_keep_jurassic",
        Value = UpdateHub.autoKeepJurassic,
        Callback = function(state)
            UpdateHub.autoKeepJurassic = parseToggle(state)
            if UpdateHub.autoKeepJurassic then
                notify("Auto Open Egg", "Ayam mutasi Jurassic [🦖] akan selalu disimpan!")
            else
                notify("Auto Open Egg", "Ayam mutasi Jurassic TIDAK diproteksi khusus.")
            end
            saveConfig()
        end
    })

    -- 4. INPUT JUMLAH PENGULANGAN BUKA TELUR
    OpenEggSec:Input({
        Title = "Jumlah Pengulangan Buka Telur",
        Flag = "egg_open_count",
        Value = tostring(UpdateHub.eggOpenRepeatCount or 5),
        Callback = function(text)
            local num = tonumber(text)
            if num and num > 0 then
                UpdateHub.eggOpenRepeatCount = math.floor(num)
                notify("Auto Open Egg", "Jumlah pengulangan diset ke: " .. tostring(UpdateHub.eggOpenRepeatCount) .. "x")
            else
                UpdateHub.eggOpenRepeatCount = 1
            end
            saveConfig()
        end
    })

    -- 5. BUTTON OPEN 10X (SESUAI JUMLAH INPUT)
    OpenEggSec:Button({
        Title = "Mulai Buka Telur (10x) [Sesuai Input]",
        Callback = function()
            local count = UpdateHub.eggOpenRepeatCount or 5
            UpdateHub.executeHatchBatch(10, count, UpdateHub.selectedEggType)
        end
    })

    -- 6. BUTTON OPEN 1X (SESUAI JUMLAH INPUT)
    OpenEggSec:Button({
        Title = "Mulai Buka Telur (1x) [Sesuai Input]",
        Callback = function()
            local count = UpdateHub.eggOpenRepeatCount or 1
            UpdateHub.executeHatchBatch(1, count, UpdateHub.selectedEggType)
        end
    })

    -- 7. BUTTON STOP BUKA TELUR
    OpenEggSec:Button({
        Title = "Stop Buka Telur",
        Callback = function()
            if UpdateHub.isHatchingEggs then
                UpdateHub.stopHatching = true
                notify("Auto Open Egg", "Menghentikan proses buka telur...")
            else
                notify("Auto Open Egg", "Tidak ada proses buka telur yang sedang berjalan.")
            end
        end
    })
end

-- ==============================================================================
end
