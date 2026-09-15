-- ==============================================================================
--              SYSHUB | MODUL FARM (REBIRTH, TOWER, SWEEP, UFO, ARENA, BOSS)
-- ==============================================================================
return function(Context, FarmTab)
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
    local enableNoclip = Context.enableNoclip
    local disableNoclip = Context.disableNoclip
    local isChickenHpFull = Context.isChickenHpFull
    local getCurrentFloor = Context.getCurrentFloor
    local getRebirthCount = Context.getRebirthCount
    local getExactRebirthRequirement = Context.getExactRebirthRequirement
    local getChickenStatus = Context.getChickenStatus
    local FlockTab = Context.FlockTab or (getgenv and getgenv().FlockTab)

-- [TAB: FARM]
-- ==============================================================================
do
-- ==============================================================
-- PRE-REGISTER SEMUA SECTION FARM TAB (Urutan tampilan di UI)
-- ==============================================================
local TowerRebirthConfigSec = FarmTab:Section({ Title = "Tower & Rebirth Config", Opened = false })
local FastRebirthSec = FarmTab:Section({ Title = "Fast Rebirth", Opened = false })
local UfoSec = FarmTab:Section({ Title = "Auto UFO Event", Opened = false })
local TowerSec = FarmTab:Section({ Title = "Auto Tower", Opened = false })
local SweepSec = FarmTab:Section({ Title = "Auto Sweep Items", Opened = false })
local ArenaBattleSec = FarmTab:Section({ Title = "Auto Arena Battle", Opened = false })

-- ==============================================================
-- SECTION 1: TOWER & REBIRTH CONFIG (Elements)
-- ==============================================================
TowerRebirthConfigSec:Input({
    Title = "Set HP Kirim Ayam (10-100%)",
    Flag = "tower_hp_threshold",
    Value = tostring(towerHpThreshold),
    Callback = function(text)
        local val = tonumber(text)
        if val then
            val = math.clamp(math.floor(val), 10, 100)
            towerHpThreshold = val
            notify("Tower Config", "HP Threshold diset ke: " .. towerHpThreshold .. "%")
        end
    end
})

TowerRebirthConfigSec:Dropdown({
    Title = "Mode Start Lantai",
    Flag = "tower_start_mode",
    Values = {"Lanjut Lantai Tertinggi", "Mulai dari Lantai 1"},
    Value = "Lanjut Lantai Tertinggi",
    Multi = false,
    Callback = function(val)
        if type(val) == "table" then
            for k, v in pairs(val) do
                if v == true then
                    towerStartMode = k
                    break
                end
            end
        else
            towerStartMode = tostring(val)
        end
        notify("Tower Config", "Mode Start Lantai: " .. towerStartMode)
    end
})

TowerRebirthConfigSec:Paragraph({
    Title = "Info Config",
    Desc = "Setting ini berlaku untuk Auto Tower & Fast Rebirth sekaligus.\n• Set HP: Ayam dikirim ke tower saat HP >= threshold (default 100%)\n• Mode Start: Lanjut lantai tertinggi atau mulai dari lantai 1\n• Set 0 di Retreat At Floor = tower loop tanpa batas"
})

-- ==============================================================
-- SECTION 2: FAST REBIRTH (Elements)
-- ==============================================================

    local FastRebirthStatus = FastRebirthSec:Paragraph({
        Title = "Live Monitor",
        Desc = "Menunggu data Fast Rebirth..."
    })

    updateFastRebirthStatus = function(title, desc)
        if not FastRebirthStatus then
            return
        end
        pcall(function()
            if type(FastRebirthStatus.SetTitle) == "function" and type(FastRebirthStatus.SetDesc) == "function" then
                FastRebirthStatus:SetTitle(title)
                FastRebirthStatus:SetDesc(desc)
            elseif type(FastRebirthStatus.Set) == "function" then
                FastRebirthStatus:Set({
                    Title = title,
                    Desc = desc
                })
            end
        end)
    end

    FastRebirthSec:Toggle({ 
        Title = "Enable Fast Rebirth", 
        Flag = "enable_fast_rebirth",
        Callback = function(state) 
            autoFastRebirth = parseToggle(state) 
            autoRebirth = autoFastRebirth
            invokeRemote("SetAutoRebirth", autoFastRebirth)
            if not autoFastRebirth then
                fastRebirthCurrentAction = "Standby (Fast Rebirth Siap Diaktifkan)"
            else
                fastRebirthCurrentAction = "Memulai Fast Rebirth..."
            end
            saveConfig()
        end 
    })

    FastRebirthSec:Input({
        Title = "Target Coop Level",
        Flag = "target_coop_level",
        Value = tostring(fastTargetCoop),
        Callback = function(text)
            fastTargetCoop = tonumber(text) or 1
            saveConfig()
        end
    })

    FastRebirthSec:Input({
        Title = "Target Jumlah Feeder",
        Flag = "target_feeder_count",
        Value = tostring(fastTargetFeederCount),
        Callback = function(text)
            fastTargetFeederCount = tonumber(text) or 2
            fastMaxFeeders = fastTargetFeederCount
            saveConfig()
        end
    })

    FastRebirthSec:Input({
        Title = "Target Level Feeder",
        Flag = "target_feeder_level",
        Value = tostring(fastTargetFeederLevel),
        Callback = function(text)
            fastTargetFeederLevel = tonumber(text) or 10
            saveConfig()
        end
    })

-- ==============================================================
-- SECTION 4: AUTO TOWER (Elements)
-- ==============================================================

TowerSec:Toggle({
    Title = "Auto Tower",
    Flag = "auto_tower",
    Callback = function(state)
        autoTower = parseToggle(state)
        saveConfig()
        if autoTower then
            notify("Auto Tower", "Auto Tower ON! HP Threshold: " .. towerHpThreshold .. "% | Mode: " .. towerStartMode)
        end
    end
})

TowerSec:Input({
    Title = "Retreat At Floor (0 = tanpa batas)",
    Flag = "retreat_floor",
    Value = tostring(retreatFloor),
    Callback = function(text)
        retreatFloor = tonumber(text) or retreatFloor
        saveConfig()
    end
})

-- ==============================================================
-- SECTION 5: AUTO SWEEP ITEMS (Elements)
-- ==============================================================
    SweepSec:Toggle({ 
        Title = "Auto Sweep Items", 
        Flag = "auto_sweep_items",
        Callback = function(state) 
            autoSweep = parseToggle(state) 
            saveConfig()
            if not autoSweep then
                disableNoclip()
            end 
        end 
    })

    SweepSec:Input({
        Title = "Max Bag Capacity",
        Flag = "max_bag_capacity",
        Value = tostring(MAX_CAPACITY),
        Callback = function(text)
            MAX_CAPACITY = tonumber(text) or MAX_CAPACITY
            saveConfig()
        end
    })

    local SellSec = FlockTab:Section({
        Title = "Auto Sell Ayam",
        Opened = false
    })

    SellSec:Button({
        Title = "Jual Ayam Sesuai Filter Sekarang",
        Callback = function()
            local count = executeSellChickens(true)
            notify("Auto Sell", count .. " ayam berhasil dijual!")
        end
    })

    SellSec:Toggle({
        Title = "Auto Sell Ayam",
        Flag = "auto_sell_chickens",
        Callback = function(state)
            autoSellChickens = parseToggle(state)
            saveConfig()
        end
    })

    SellSec:Dropdown({
        Title = "Rarity Dijual:",
        Flag = "sell_rarities",
        Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Celestial", "Cosmic", "Secret"},
        Value = {"Common", "Uncommon"},
        Multi = true,
        Callback = function(list)
            for k in pairs(selectedSellRarities) do
                selectedSellRarities[k] = false
            end
            if type(list) == "table" then
                for k, v in pairs(list) do
                    if type(k) == "string" and v == true then
                        selectedSellRarities[k] = true
                    elseif type(v) == "string" then
                        selectedSellRarities[v] = true
                    end
                end
            end
            saveConfig()
        end
    })

    SellSec:Input({
        Title = "Sell Delay (s)",
        Flag = "sell_delay",
        Value = tostring(delaySellChicken),
        Callback = function(text)
            delaySellChicken = tonumber(text) or delaySellChicken
            saveConfig()
        end
    })

UpdateHub.getChickenArenaPower = function(ch)
    if not ch or type(ch) ~= "table" then
        return 0, "0"
    end

    local powerNum = 0
    local powerStr = "0"

    pcall(function()
        local featFolder = ReplicatedStorage:FindFirstChild("Features")
        local arenaFeat = featFolder and featFolder:FindFirstChild("Arena")
        local arenaViewMod = arenaFeat and arenaFeat:FindFirstChild("ArenaView")
        if arenaViewMod then
            local ok, ArenaView = pcall(function() return require(arenaViewMod) end)
            if ok and ArenaView and ArenaView.chickenPower then
                local res = ArenaView.chickenPower(ch)
                if type(res) == "number" then
                    powerNum = res
                    powerStr = tostring(math.floor(res))
                elseif type(res) == "table" or type(res) == "userdata" then
                    if res.toNumber then
                        local okNum, n = pcall(function() return res:toNumber() end)
                        if okNum and n and n == n and n ~= (1/0) and n ~= (-1/0) then
                            powerNum = n
                        end
                    end
                    if powerNum == 0 and res.mantissa and res.exponent then
                        local m = tonumber(res.mantissa) or 1
                        local e = tonumber(res.exponent) or 0
                        powerNum = (e * 1e7) + m
                    end
                    powerStr = tostring(res)
                end
            end
        end
    end)

    if powerNum == 0 then
        local lvl = tonumber(ch.level) or 1
        local promo = tonumber(ch.promo) or 0
        powerNum = (lvl * 100) + (promo * 500)
        if powerStr == "0" then
            powerStr = tostring(powerNum)
        end
    end

    return powerNum, powerStr
end

UpdateHub.executeEquipBestArenaTeam = function()
    local ok, err = pcall(function()
        local dsClient = getSharedDataServiceClient()
        local raw = dsClient and dsClient._data and dsClient._data._data
        local chickens = raw and raw.roster and raw.roster.chickens
        if not chickens or type(chickens) ~= "table" or not next(chickens) then
            notify("Arena", "Gagal memuat data ayam dari memori!")
            return
        end

        local teamSize = 3
        pcall(function()
            local contentFolder = ReplicatedStorage:FindFirstChild("Content")
            local arenaContent = contentFolder and contentFolder:FindFirstChild("Arena")
            if arenaContent then
                local okA, Arena = pcall(function() return require(arenaContent) end)
                if okA and Arena and Arena.team and Arena.team.size then
                    teamSize = tonumber(Arena.team.size) or 3
                end
            end
        end)

        local chickenList = {}
        for k, ch in pairs(chickens) do
            if type(ch) == "table" then
                local cId = ch.id or k
                local pNum, pStr = UpdateHub.getChickenArenaPower(ch)
                local sName = formatSpeciesName(ch.typeId)
                table.insert(chickenList, {
                    id = cId,
                    ch = ch,
                    powerNum = tonumber(pNum) or 0,
                    powerStr = tostring(pStr or "0"),
                    name = sName,
                    level = tonumber(ch.level) or 1,
                    promo = tonumber(ch.promo) or 0,
                })
            end
        end

        if #chickenList == 0 then
            notify("Arena", "Tidak ada ayam yang ditemukan di kawanan!")
            return
        end

        -- STRICT WEAK ORDERING: Terjamin tidak pernah memicu 'invalid order function for sorting'
        table.sort(chickenList, function(a, b)
            local pa = a.powerNum or 0
            local pb = b.powerNum or 0
            if pa ~= pb then
                return pa > pb
            end
            return tostring(a.id) > tostring(b.id)
        end)

        local bestTeam = {}
        local teamIds = {}
        local numTeamIds = {}
        local summaryLines = {}

        local count = math.min(teamSize, #chickenList)
        for i = 1, count do
            local entry = chickenList[i]
            table.insert(bestTeam, entry)
            table.insert(teamIds, entry.id)
            local nId = tonumber(tostring(entry.id):match("%d+")) or entry.id
            table.insert(numTeamIds, nId)

            local starStr = entry.promo > 0 and string.format(" [%d★]", entry.promo) or ""
            table.insert(summaryLines, string.format("#%d: %s (Lv.%d%s | Power: %s)", i, entry.name, entry.level, starStr, entry.powerStr))
        end

        local setSuccess = false
        pcall(function()
            local res = invokeRemote("ArenaSetTeam", teamIds)
            if res then setSuccess = true end
        end)
        if not setSuccess then
            pcall(function()
                local res = invokeRemote("ArenaSetTeam", unpack(teamIds))
                if res then setSuccess = true end
            end)
        end
        if not setSuccess then
            pcall(function()
                local res = invokeRemote("ArenaSetTeam", numTeamIds)
                if res then setSuccess = true end
            end)
        end
        if not setSuccess then
            pcall(function()
                local res = invokeRemote("ArenaSetTeam", unpack(numTeamIds))
                if res then setSuccess = true end
            end)
        end

        local summaryText = table.concat(summaryLines, "\n")
        printLog("Arena", "Tim Arena Terbaik Berhasil Dipasang:\n" .. summaryText)
        notify("Arena", string.format("Tim Arena terbaik (%d ayam) berhasil dipasang!\n%s", count, summaryLines[1] or ""))
    end)
    if not ok then
        logError("executeEquipBestArenaTeam", err)
        notify("Arena", "Terjadi kendala saat memasang tim arena: " .. tostring(err))
    end
end

UpdateHub.executeArenaAutoFight = function()
    if UpdateHub.isArenaFightRunning then
        return
    end
    UpdateHub.isArenaFightRunning = true
    pcall(function()
        local view = invokeRemote("ArenaGetView")
        local targetOpponentId = nil
        if type(view) == "table" then
            local opponents = view.opponents or view.list or view.players or view
            if type(opponents) == "table" then
                local bestRating = math.huge
                for k, opp in pairs(opponents) do
                    if type(opp) == "table" then
                        local oppId = opp.id or opp.userId or opp.playerId or k
                        local rating = tonumber(opp.rating or opp.power or opp.score or opp.level) or 999999
                        if rating < bestRating then
                            bestRating = rating
                            targetOpponentId = oppId
                        end
                    end
                end
            end
        end

        if targetOpponentId then
            invokeRemote("ArenaFight", targetOpponentId)
        else
            invokeRemote("ArenaFight", 1)
            invokeRemote("ArenaFight")
        end

        task.wait(0.2)
        invokeRemote("ArenaSkip")
        invokeRemote("SetArenaAutoAbility", true)
        printLog("Arena", "Arena battle dieksekusi!")
    end)
    UpdateHub.isArenaFightRunning = false
end

-- ==============================================================
-- SECTION 6: AUTO ARENA BATTLE (Elements)
-- ==============================================================

ArenaBattleSec:Button({
    Title = "Gunakan Ayam Terbaik (Equip Best Team)",
    Callback = function()
        task.spawn(UpdateHub.executeEquipBestArenaTeam)
    end
})

ArenaBattleSec:Toggle({
    Title = "Auto Arena Fight",
    Flag = "auto_arena_fight",
    Callback = function(state)
        UpdateHub.autoArenaFight = parseToggle(state)
    end
})

ArenaBattleSec:Input({
    Title = "Fight Delay (s)",
    Flag = "delay_arena_fight",
    Value = tostring(UpdateHub.delayArenaFight),
    Callback = function(text)
        UpdateHub.delayArenaFight = tonumber(text) or UpdateHub.delayArenaFight
    end
})

ArenaBattleSec:Button({
    Title = "Tantang Lawan Sekarang (1-Fight)",
    Callback = function()
        task.spawn(UpdateHub.executeArenaAutoFight)
        notify("Arena", "Mengeksekusi pertarungan arena...")
    end
})

local lastUfoCheckTime = 0
local cachedUfoActive = false
UpdateHub.isUfoEventActive = function()
    -- 1. Cek event live flag dari network event server (0 delay)
    if UpdateHub.ufoEventLive == true then
        return true
    end

    -- 2. Buffer Cooldown 60 Detik setelah event UFO selesai
    -- Mencegah false positive dari sisa teks banner / billboard yang belum di-despawn
    local now = os.clock()
    if UpdateHub.lastUfoEndedTimestamp and (now - UpdateHub.lastUfoEndedTimestamp < 60) then
        cachedUfoActive = false
        return false
    end

    -- Throttle fallback polling maksimal 1x per 1.5 detik
    if now - lastUfoCheckTime < 1.5 then
        return cachedUfoActive
    end
    lastUfoCheckTime = now

    -- 3. Cek remote function LiveEventGetActive (Autoritatif dari Server game)
    pcall(function()
        local rf = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("LiveEventGetActive")
        if not rf then
            rf = ReplicatedStorage:FindFirstChild("LiveEventGetActive", true)
        end
        if rf and rf:IsA("RemoteFunction") then
            local res = rf:InvokeServer()
            if res then
                if type(res) == "boolean" then
                    if res == true then
                        cachedUfoActive = true
                        return true
                    end
                elseif type(res) == "table" then
                    local isExplicitlyInactive = (res.active == false) or (res.isActive == false) or (res.isLive == false)
                    local stateStr = tostring(res.state or res.status or ""):lower()
                    if stateStr:find("end") or stateStr:find("finish") or stateStr:find("over") then
                        isExplicitlyInactive = true
                    end

                    if not isExplicitlyInactive then
                        for k, v in pairs(res) do
                            local kStr = tostring(k):lower()
                            local vStr = tostring(v):lower()
                            if (kStr:find("ufo") or kStr:find("invasion") or vStr:find("ufo") or vStr:find("invasion")) then
                                if v ~= false and not vStr:find("false") and not vStr:find("ended") and not vStr:find("selesai") and not vStr:find("finish") and not kStr:find("ended") then
                                    cachedUfoActive = true
                                    return true
                                end
                            end
                        end
                    end
                elseif type(res) == "string" then
                    local str = res:lower()
                    if (str:find("ufo") or str:find("invasion")) and not str:find("ended") and not str:find("selesai") and not str:find("finish") and not str:find("false") then
                        cachedUfoActive = true
                        return true
                    end
                end
            end
        end
        return false
    end)
    if cachedUfoActive == true then
        return true
    end

    -- 4. Cek Billboard 3D Game "UFO INVASION LIVE" yang melayang di atas Pit / Arena
    local pit = Workspace:FindFirstChild("Pit") or (Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("Pit"))
    if pit then
        local found3DBillboard = false
        pcall(function()
            for _, desc in ipairs(pit:GetDescendants()) do
                if (desc:IsA("BillboardGui") or desc:IsA("SurfaceGui")) and desc.Enabled == true then
                    for _, t in ipairs(desc:GetDescendants()) do
                        if t:IsA("TextLabel") and t.Visible == true and (t.TextTransparency or 0) < 0.8 then
                            local txt = (t.Text or ""):lower()
                            if (txt:find("ufo") or txt:find("invasion"))
                                and not txt:find("ended")
                                and not txt:find("selesai")
                                and not txt:find("over")
                                and not txt:find("finish")
                                and not txt:find("next")
                                and not txt:find("starts in")
                                and not txt:find("starting")
                                and not txt:find("cooldown") then
                                if txt:find("live") or txt:find("active") or txt:find("invasion") or txt:match("%d+:%d%d") then
                                    found3DBillboard = true
                                    return
                                end
                            end
                        end
                    end
                end
            end
        end)
        if found3DBillboard then
            cachedUfoActive = true
            return true
        end
    end

    -- 5. Cek Tombol HUD UFO Countdown Timer di PlayerGui (pojok kanan bawah layar game)
    local pg = player:FindFirstChild("PlayerGui")
    if pg then
        local foundHudButton = false
        pcall(function()
            for _, gui in ipairs(pg:GetChildren()) do
                local gName = gui.Name:lower()
                local isScriptGui = gName:find("wind")
                    or gName:find("syshub")
                    or gName:find("hub")
                    or gName:find("dropdown")
                    or (gui:FindFirstChild("WindUI") ~= nil)
                    or (gui:FindFirstChild("Holder") ~= nil)

                if gui:IsA("ScreenGui") and gui.Enabled and not isScriptGui then
                    for _, desc in ipairs(gui:GetDescendants()) do
                        if desc:IsA("TextLabel") and desc.Visible and (desc.TextTransparency or 0) < 0.8 then
                            local txt = desc.Text or ""
                            local txtLower = txt:lower()

                            local isEndedText = txtLower:find("ended")
                                or txtLower:find("selesai")
                                or txtLower:find("over")
                                or txtLower:find("finish")
                                or txtLower:find("claim")
                                or txtLower:find("reward")
                                or txtLower:find("winner")
                                or txtLower:find("next")
                                or txtLower:find("starts in")

                            if not isEndedText then
                                -- Timer countdown "2:23" di tombol HUD UFO (bukan 0:00)
                                if txt:match("^%d+:%d%d$") and txt ~= "0:00" and txt ~= "00:00" then
                                    local pName = (desc.Parent and desc.Parent.Name or ""):lower()
                                    local gpName = (desc.Parent and desc.Parent.Parent and desc.Parent.Parent.Name or ""):lower()
                                    if pName:find("ufo") or pName:find("invasion") or gpName:find("ufo") or gpName:find("invasion") then
                                        foundHudButton = true
                                        return
                                    end
                                end

                                -- Banner teks resmi game "UFO INVASION LIVE"
                                if (txtLower:find("ufo invasion") or (txtLower:find("ufo") and txtLower:find("live"))) then
                                    foundHudButton = true
                                    return
                                end
                            end
                        end
                    end
                end
            end
        end)
        if foundHudButton then
            cachedUfoActive = true
            return true
        end
    end

    cachedUfoActive = false
    return false
end

UpdateHub.isUfoPriorityActive = function()
    return UpdateHub.autoUfoEvent == true
        and UpdateHub.ufoPriorityMode == true
        and UpdateHub.isUfoEventActive() == true
end

UpdateHub.getUfoBeamPosition = function()
    -- 1. Cek langsung part/model Beam atau UFO di Workspace
    local beamPart = nil
    for _, obj in ipairs(Workspace:GetChildren()) do
        local n = obj.Name:lower()
        if (n:find("beam") or n:find("ufo") or n:find("invasion") or n:find("alien")) and not n:find("chicken") then
            if obj:IsA("BasePart") then
                beamPart = obj
                break
            elseif obj:IsA("Model") then
                local b = obj:FindFirstChild("Beam", true) or obj:FindFirstChild("Light", true) or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                if b and b:IsA("BasePart") then
                    beamPart = b
                    break
                end
            end
        end
    end
    if beamPart then
        return beamPart.Position
    end

    -- 2. Cek Model/Part Pit atau Arena langsung (tempat mendaratnya UFO Invasion)
    local pit = Workspace:FindFirstChild("Pit")
        or (Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("Pit"))
        or Workspace:FindFirstChild("Arena")
        or (Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("Arena"))

    if pit then
        if pit:IsA("Model") then
            local floor = pit:FindFirstChild("Floor", true) or pit:FindFirstChild("Base", true) or pit:FindFirstChild("Ground", true)
            if floor and floor:IsA("BasePart") then
                return floor.Position + Vector3.new(0, 1.5, 0)
            end
            local cf, _ = pit:GetBoundingBox()
            return cf.Position + Vector3.new(0, 1.5, 0)
        elseif pit:IsA("BasePart") then
            return pit.Position + Vector3.new(0, 1.5, 0)
        end
    end

    -- 3. Cek posisi tengah dari rata-rata part scrap di PitScrap
    local pitScrap = Workspace:FindFirstChild("PitScrap") or (Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("PitScrap"))
    if pitScrap then
        local sumX, sumY, sumZ, count = 0, 0, 0, 0
        for _, desc in ipairs(pitScrap:GetDescendants()) do
            if desc:IsA("BasePart") and (desc.Name == "Loose" or desc.Name:lower():find("scrap")) then
                sumX = sumX + desc.Position.X
                sumY = sumY + desc.Position.Y
                sumZ = sumZ + desc.Position.Z
                count = count + 1
            end
        end
        if count > 0 then
            return Vector3.new(sumX / count, (sumY / count) + 1.5, sumZ / count)
        end
    end

    return Vector3.new(0, 5, 0)
end

UpdateHub.getMyChickenBody = function()
    local chickenFolder = Workspace:FindFirstChild("ChickenBodies")
    if not chickenFolder then
        return nil
    end

    local plotId = player:GetAttribute("Plot") or currentPlotId or 1
    local byName = chickenFolder:FindFirstChild("ChickenBody_coop:" .. tostring(plotId))
    if byName then
        return byName
    end

    for _, c in ipairs(chickenFolder:GetChildren()) do
        local ownerId = c:GetAttribute("ovOwner")
        if ownerId and tonumber(ownerId) == player.UserId then
            return c
        end
    end

    for _, c in ipairs(chickenFolder:GetChildren()) do
        local ownerAttr = c:GetAttribute("Owner") or c:GetAttribute("owner")
        if ownerAttr and string.lower(tostring(ownerAttr)) == string.lower(player.Name) then
            return c
        end
    end

    return nil
end

UpdateHub.getChickenUfoLocation = function()
    local cBody = UpdateHub.getMyChickenBody()
    if not cBody or not cBody.Parent then
        -- Ayam sedang despawn / proses respawn setelah kena beam
        return "RESPAWNING"
    end

    -- Cek status kehidupan ayam (jika KO pingsan akibat kena upgrade beam)
    local ovLife = cBody:GetAttribute("ovLife")
    local hpFrac = cBody:GetAttribute("ovHpFrac")
    local isKo = (ovLife == false) or (hpFrac and type(hpFrac) == "number" and hpFrac <= 0)

    local cPos = nil
    pcall(function()
        if cBody:IsA("BasePart") then
            cPos = cBody.Position
        elseif cBody:IsA("Model") then
            local pp = cBody.PrimaryPart
            cPos = (pp and pp.Position) or cBody:GetPivot().Position
        end
    end)

    if not cPos then
        return "RESPAWNING"
    end

    -- Dapatkan posisi Pit / Arena tengah (Jarak Horizontal 2D X/Z)
    local pit = Workspace:FindFirstChild("Pit") or (Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("Pit"))
    local pitPos = (pit and (pit:IsA("Model") and pit:GetPivot().Position or pit.Position)) or Vector3.new(0, 5, 0)
    local distToPit = (Vector3.new(cPos.X, 0, cPos.Z) - Vector3.new(pitPos.X, 0, pitPos.Z)).Magnitude

    -- Dapatkan posisi Base / Coop pemain
    local plotId = player:GetAttribute("Plot") or currentPlotId or 1
    local coopsFolder = Workspace:FindFirstChild("Coops")
    local myCoop = coopsFolder and coopsFolder:FindFirstChild("Coop" .. tostring(plotId))
    local basePos = nil
    if myCoop then
        basePos = myCoop:GetPivot().Position
    else
        local plots = Workspace:FindFirstChild("Plots") or (Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("Plots"))
        local myPlot = plots and plots:FindFirstChild("Plot" .. tostring(plotId))
        if myPlot then
            basePos = myPlot:GetPivot().Position
        end
    end

    -- 1. Jika ayam sedang KO / kena proses upgrade beam di arena pit
    if isKo then
        if distToPit < 70 then
            return "BEAM_UPGRADING"
        else
            return "RESPAWNING"
        end
    end

    -- 2. Jika ayam hidup dan sedang berada di arena tengah (di bawah beam)
    if distToPit < 65 then
        return "IN_CHAOS"
    end

    -- 3. Cek apakah ayam sudah BENAR-BENAR spawn hidup di Base / Coop (Jarak Horizontal 2D X/Z)
    if basePos then
        local distToBase = (Vector3.new(cPos.X, 0, cPos.Z) - Vector3.new(basePos.X, 0, basePos.Z)).Magnitude
        if distToBase < 65 then
            return "AT_BASE"
        end
    else
        if distToPit > 85 then
            return "AT_BASE"
        end
    end

    -- 4. Ayam sedang berjalan / berlari dari Base menuju Chaos
    return "IN_TRANSIT"
end

UpdateHub.getCurrentActiveChicken = function()
    local activeId = nil
    local activeName = nil
    local activeData = nil

    -- 1. Deteksi primer dari DataService memory
    pcall(function()
        local dsClient = getSharedDataServiceClient()
        local raw = dsClient and dsClient._data and dsClient._data._data
        if raw then
            if raw.vitals and raw.vitals.id then
                activeId = raw.vitals.id
            elseif raw.roster then
                if raw.roster.active then
                    activeId = raw.roster.active
                elseif raw.roster.activeId then
                    activeId = raw.roster.activeId
                elseif raw.roster.equipped then
                    activeId = raw.roster.equipped
                elseif raw.roster.chickens and type(raw.roster.chickens) == "table" then
                    for _, ch in pairs(raw.roster.chickens) do
                        if type(ch) == "table" and (ch.active == true or ch.isEquipped == true or ch.equipped == true or ch.is_active == true) and ch.id then
                            activeId = ch.id
                            break
                        end
                    end
                end
            elseif raw.activeChicken then
                activeId = raw.activeChicken
            elseif raw.equippedChicken then
                activeId = raw.equippedChicken
            end
        end
    end)

    -- 2. Fallback deteksi dari atribut Player
    if not activeId then
        pcall(function()
            for attr, val in pairs(player:GetAttributes()) do
                local aLow = tostring(attr):lower()
                if (aLow:find("active") or aLow:find("rooster") or aLow:find("equip")) and not aLow:find("team") and not aLow:find("plot") then
                    if val and type(val) ~= "boolean" and type(val) ~= "table" and tostring(val) ~= "" then
                        activeId = val
                        break
                    end
                end
            end
        end)
    end

    -- 3. Fallback deteksi dari PlayerGui
    if not activeId then
        pcall(function()
            local pg = player:FindFirstChild("PlayerGui")
            if pg then
                for _, desc in ipairs(pg:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Text and desc.Text:lower():find("active") then
                        local frame = desc:FindFirstAncestorWhichIsA("Frame") or desc:FindFirstAncestorWhichIsA("GuiObject")
                        if frame then
                            local matchNumber = string.match(frame.Name, "^c(%d+)$")
                            if matchNumber then
                                activeId = frame.Name
                                break
                            end
                        end
                    end
                end
            end
        end)
    end

    -- 4. Fallback dari model ayam pemain di Workspace (ChickenBodies)
    if not activeId then
        pcall(function()
            local cBody = UpdateHub.getMyChickenBody()
            if cBody then
                for attr, val in pairs(cBody:GetAttributes()) do
                    local aLow = tostring(attr):lower()
                    if aLow == "id" or aLow == "ovid" or aLow == "chickenid" then
                        activeId = val
                        break
                    end
                end
            end
        end)
    end

    -- Cocokkan dengan chickenMap untuk mendapatkan nama dan data lengkap
    if activeId then
        if not chickenMap or next(chickenMap) == nil then
            scanFlockChickens()
        end
        for dispName, data in pairs(chickenMap) do
            if tostring(data.Id) == tostring(activeId) or (data.NumId and tostring(data.NumId) == tostring(activeId)) then
                activeName = data.Name or dispName
                activeData = data
                break
            end
        end
    end

    return activeId, activeName or (activeId and tostring(activeId)), activeData
end

UpdateHub.returnChickenToCoop = function()
    pcall(function()
        -- 1. Jalur Remote SetChickenOrder ("coop", "retreat")
        -- CATATAN: JANGAN kirim "call" karena "call" memerintahkan ayam datang ke pemain, BUKAN ke dalam coop!
        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes and remotes:FindFirstChild("SetChickenOrder") then
                remotes.SetChickenOrder:FireServer("coop")
                remotes.SetChickenOrder:FireServer("retreat")
            else
                invokeRemote("SetChickenOrder", "coop")
                invokeRemote("SetChickenOrder", "retreat")
            end
        end)

        -- 2. Jalur Menekan Tombol HUD "TO COOP" / "Retreat" di Layar (PlayerGui)
        pcall(function()
            local pg = player:FindFirstChild("PlayerGui")
            if pg then
                for _, desc in ipairs(pg:GetDescendants()) do
                    local isScriptGui = false
                    pcall(function()
                        local rootGui = desc:FindFirstAncestorWhichIsA("ScreenGui")
                        if rootGui then
                            local rName = rootGui.Name:lower()
                            if rName:find("wind") or rName:find("syshub") or rName:find("hub") or rName:find("dropdown") then
                                isScriptGui = true
                            end
                        end
                    end)

                    if not isScriptGui then
                        if desc:IsA("GuiButton") or desc:IsA("TextButton") or desc:IsA("ImageButton") then
                            local txt = (desc:IsA("TextButton") and desc.Text or ""):lower()
                            local n = desc.Name:lower()
                            local isToCoop = txt:find("to coop") or n:find("to coop") or txt == "coop" or n == "coop"
                            local isRetreat = txt:find("retreat") or n:find("retreat") or txt:find("base") or n == "base" or txt:find("home")
                            if isToCoop or isRetreat then
                                if firesignal then
                                    firesignal(desc.MouseButton1Click)
                                    firesignal(desc.Activated)
                                end
                            end
                        elseif desc:IsA("TextLabel") then
                            local txt = (desc.Text or ""):lower()
                            local isToCoop = txt:find("to coop") or txt == "coop"
                            local isRetreat = txt:find("retreat") or txt:find("base") or txt:find("home")
                            if isToCoop or isRetreat then
                                local parentBtn = desc:FindFirstAncestorWhichIsA("GuiButton")
                                if parentBtn and firesignal then
                                    firesignal(parentBtn.MouseButton1Click)
                                    firesignal(parentBtn.Activated)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end)
end

UpdateHub.handleUfoEventEnded = function()
    if UpdateHub.isRestoringPreviousChicken then
        return
    end
    UpdateHub.isRestoringPreviousChicken = true

    -- Segera tandai event selesai dan set cooldown agar loop background tidak mengirim ayam lagi!
    UpdateHub.ufoEventLive = false
    UpdateHub.lastUfoEndedTimestamp = os.clock()
    cachedUfoActive = false
    UpdateHub.isUfoRunning = false

    task.spawn(function()
        pcall(function()
            local prevId = UpdateHub.previousActiveChickenId or UpdateHub.lastKnownNonUfoChickenId
            local prevName = UpdateHub.previousActiveChickenName or UpdateHub.lastKnownNonUfoChickenName or (prevId and tostring(prevId))

            printLog("Auto UFO Event", string.format("Event UFO Invasion Selesai! Mengirim sinyal kembali ke coop & memproses pemulihan ayam: %s (ID: %s)...", tostring(prevName or "Default"), tostring(prevId or "None")))

            -- 1. Panggil perintah retreat / CALL agar ayam yang sedang berjalan ke pit langsung putar balik ke coop
            UpdateHub.returnChickenToCoop()

            -- 2. Jika ada data ayam awal sebelum event, jalankan loop restorasi & verifikasi (sampai 12 detik)
            if prevId then
                local numId = tonumber(string.match(tostring(prevId), "%d+"))
                local restored = false
                local startRestore = os.clock()

                while (os.clock() - startRestore < 12) do
                    -- Periksa apakah ayam saat ini sudah kembali aktif sebagai prevId
                    local curId = UpdateHub.getCurrentActiveChicken()
                    if curId and (tostring(curId) == tostring(prevId) or (numId and tostring(curId) == tostring(numId))) then
                        restored = true
                        break
                    end

                    -- Kirim sinyal SetActiveChicken & Equip berulang kali (mengatasi delay status KO / respawn server)
                    pcall(function()
                        invokeRemote("SetActiveChicken", prevId)
                        if numId and numId ~= prevId then
                            invokeRemote("SetActiveChicken", numId)
                        end
                        invokeRemote("Equip", prevId)
                        if numId and numId ~= prevId then
                            invokeRemote("Equip", numId)
                        end
                    end)

                    -- Tekan tombol UI di frame Flock jika tersedia
                    pcall(function()
                        if chickenMap then
                            for _, data in pairs(chickenMap) do
                                if (tostring(data.Id) == tostring(prevId) or (data.NumId and tostring(data.NumId) == tostring(prevId))) then
                                    local btn = data.Button or (data.Frame and (data.Frame:IsA("GuiButton") and data.Frame or data.Frame:FindFirstChildWhichIsA("GuiButton", true)))
                                    if btn and firesignal then
                                        firesignal(btn.MouseButton1Click)
                                        firesignal(btn.Activated)
                                    end
                                    break
                                end
                            end
                        end
                    end)

                    task.wait(1.0)
                end

                if restored then
                    printLog("Auto UFO Event", string.format("Event UFO selesai! Ayam berhasil dikembalikan ke: %s (ID: %s)", tostring(prevName), tostring(prevId)))
                    notify("Auto UFO Event", string.format("Event UFO selesai! Ayam dikembalikan ke: %s", tostring(prevName)))
                else
                    -- Upaya pemanggilan akhir
                    pcall(function()
                        invokeRemote("SetActiveChicken", prevId)
                        invokeRemote("Equip", prevId)
                    end)
                    printLog("Auto UFO Event", string.format("Pengembalian ayam selesai diproses untuk: %s", tostring(prevName)))
                    notify("Auto UFO Event", string.format("Ayam dikembalikan ke: %s", tostring(prevName)))
                end
            end

            -- 3. Pastikan ayam benar-benar bergerak dan masuk ke dalam pagar Coop (jarak <= 20 stud)
            local startWaitCoop = os.clock()
            while (os.clock() - startWaitCoop < 6) do
                local dist = getChickenDistanceToCoop()
                if dist and dist <= 20 then
                    break
                end
                UpdateHub.returnChickenToCoop()
                task.wait(0.5)
            end

            -- 4. Bersihkan state
            UpdateHub.previousActiveChickenId = nil
            UpdateHub.previousActiveChickenName = nil
            UpdateHub.ufoChickenStatus = "AT_BASE"
            UpdateHub.lastChaosEntryTime = nil
            UpdateHub.lastUfoSendTime = 0
            UpdateHub.lastUfoEndedTimestamp = os.clock()

            if UpdateHub.ufoPriorityMode then
                printLog("Prioritas UFO", "Event UFO selesai! Fitur lain (Fast Rebirth, Tower, Sweep, Arena) otomatis dilanjutkan kembali.")
                notify("Prioritas UFO", "Fitur otomatis yang sempat dijeda kini dilanjutkan kembali!")
            end
        end)
        UpdateHub.isRestoringPreviousChicken = false
    end)
end

UpdateHub.restorePreviousChicken = function(prevId, prevName)
    if prevId then
        UpdateHub.previousActiveChickenId = prevId
        UpdateHub.previousActiveChickenName = prevName
    end
    UpdateHub.handleUfoEventEnded()
end

UpdateHub.executeSendChickenToUfoBeam = function(silent)
    if UpdateHub.isUfoRunning then
        return
    end
    if not UpdateHub.isUfoEventActive() or (UpdateHub.lastUfoEndedTimestamp and (os.clock() - UpdateHub.lastUfoEndedTimestamp < 60)) then
        return
    end
    UpdateHub.isUfoRunning = true

    local success, err = pcall(function()
        local rawTarget = UpdateHub.selectedUfoChickenName
        local targetName = ""
        if type(rawTarget) == "table" then
            for k, v in pairs(rawTarget) do
                if v == true then
                    targetName = k
                    break
                elseif type(k) == "number" and type(v) == "string" then
                    targetName = v
                    break
                end
            end
            if targetName == "" and (rawTarget.Title or rawTarget.Name) then
                targetName = rawTarget.Title or rawTarget.Name
            end
        else
            targetName = tostring(rawTarget or "")
        end

        if not chickenMap or next(chickenMap) == nil or not chickenMap[targetName] then
            scanFlockChickens()
        end

        local targetData = chickenMap and chickenMap[targetName]
        if not targetData and chickenMap then
            -- Fuzzy match: cocokkan nama ayam tanpa terganggu emoji / spasi / format bintang
            local cleanTarget = targetName:gsub("[%p%c%s]", ""):lower()
            for dispName, data in pairs(chickenMap) do
                local cleanDisp = dispName:gsub("[%p%c%s]", ""):lower()
                local cleanName = (data.Name or ""):gsub("[%p%c%s]", ""):lower()
                if cleanDisp == cleanTarget or cleanDisp:find(cleanTarget, 1, true) or cleanTarget:find(cleanDisp, 1, true) or (cleanName ~= "" and cleanTarget:find(cleanName, 1, true)) then
                    targetData = data
                    targetName = dispName
                    UpdateHub.selectedUfoChickenName = dispName
                    break
                end
            end
        end

        -- Fallback jika masih belum ada: ambil ayam pertama di kawanan
        if not targetData and chickenNames and #chickenNames > 0 and chickenNames[1] ~= "Tidak ada ayam" and chickenNames[1] ~= "Belum di-refresh (Klik tombol Refresh)" and chickenNames[1] ~= "Buka menu Flock di game lalu klik Refresh!" then
            targetName = chickenNames[1]
            targetData = chickenMap[targetName]
            UpdateHub.selectedUfoChickenName = targetName
        end

        if targetData and targetData.Id then
            local cId = targetData.Id
            local numId = targetData.NumId or tonumber(string.match(tostring(cId), "%d+"))

            -- Simpan ayam aktif sebelum event jika belum tersimpan (Snapshot dengan Fallback Lengkap)
            if UpdateHub.autoUfoEvent and not UpdateHub.previousActiveChickenId then
                local curId, curName = UpdateHub.getCurrentActiveChicken()
                if not curId or tostring(curId) == tostring(cId) or (numId and tostring(curId) == tostring(numId)) then
                    if UpdateHub.lastKnownNonUfoChickenId and tostring(UpdateHub.lastKnownNonUfoChickenId) ~= tostring(cId) then
                        curId = UpdateHub.lastKnownNonUfoChickenId
                        curName = UpdateHub.lastKnownNonUfoChickenName
                    elseif selectedChickenId and tostring(selectedChickenId) ~= tostring(cId) then
                        curId = selectedChickenId
                        curName = selectedChickenName
                    end
                end

                if curId and tostring(curId) ~= tostring(cId) and (not numId or tostring(curId) ~= tostring(numId)) then
                    UpdateHub.previousActiveChickenId = curId
                    UpdateHub.previousActiveChickenName = curName or tostring(curId)
                    UpdateHub.lastKnownNonUfoChickenId = curId
                    UpdateHub.lastKnownNonUfoChickenName = curName or tostring(curId)
                    printLog("Auto UFO Event", string.format("Menyimpan ayam aktif sebelum event: %s (ID: %s)", tostring(UpdateHub.previousActiveChickenName), tostring(curId)))
                end
                if UpdateHub.ufoPriorityMode then
                    printLog("Prioritas UFO", "Event UFO aktif! Fitur pergerakan/rebirth (Fast Rebirth, Tower, Sweep, Arena) dijeda sementara...")
                    notify("Prioritas UFO", "Event UFO aktif! Menjeda sementara fitur pergerakan & rebirth hingga event selesai.")
                end
            end

            -- [1] Buat ayam yang dipilih menjadi aktif (Active Rooster) & Equip
            invokeRemote("SetActiveChicken", cId)
            if numId and numId ~= cId then
                invokeRemote("SetActiveChicken", numId)
            end
            invokeRemote("Equip", cId)
            if numId and numId ~= cId then
                invokeRemote("Equip", numId)
            end
            if targetData.Button and firesignal then
                pcall(function()
                    firesignal(targetData.Button.MouseButton1Click)
                    firesignal(targetData.Button.Activated)
                end)
            end
            task.wait(0.1)
        end

        -- [2] Kirim ayam HANYA ke arena tengah (Chaos / The Pit)
        if not UpdateHub.isUfoEventActive() or (UpdateHub.lastUfoEndedTimestamp and (os.clock() - UpdateHub.lastUfoEndedTimestamp < 60)) then
            UpdateHub.returnChickenToCoop()
            UpdateHub.isUfoRunning = false
            return
        end

        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes and remotes:FindFirstChild("SetChickenOrder") then
                remotes.SetChickenOrder:FireServer("chaos")
            else
                invokeRemote("SetChickenOrder", "chaos")
            end
        end)

        -- Trigger tombol HUD 'pit' / 'TO CHAOS' di PlayerGui jika ada
        pcall(function()
            local pg = player:FindFirstChild("PlayerGui")
            if pg then
                for _, desc in ipairs(pg:GetDescendants()) do
                    if desc:IsA("GuiButton") or desc:IsA("TextButton") or desc:IsA("ImageButton") then
                        local txt = (desc:IsA("TextButton") and desc.Text or ""):lower()
                        local n = desc.Name:lower()
                        if n == "pit" or txt:find("to chaos") or txt:find("chaos") then
                            if firesignal then
                                firesignal(desc.MouseButton1Click)
                                firesignal(desc.Activated)
                            end
                        end
                    elseif desc:IsA("TextLabel") then
                        local txt = (desc.Text or ""):lower()
                        if txt:find("to chaos") or txt:find("chaos") then
                            local parentBtn = desc:FindFirstAncestorWhichIsA("GuiButton")
                            if parentBtn and firesignal then
                                firesignal(parentBtn.MouseButton1Click)
                                firesignal(parentBtn.Activated)
                            end
                        end
                    end
                end
            end
        end)

        -- Konfirmasi ulang order agar server langsung memproses tanpa delay
        task.wait(0.12)
        if not UpdateHub.isUfoEventActive() or (UpdateHub.lastUfoEndedTimestamp and (os.clock() - UpdateHub.lastUfoEndedTimestamp < 60)) then
            UpdateHub.returnChickenToCoop()
            UpdateHub.isUfoRunning = false
            return
        end
        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes and remotes:FindFirstChild("SetChickenOrder") then
                remotes.SetChickenOrder:FireServer("chaos")
            end
        end)

        UpdateHub.lastUfoSendTime = os.clock()
        UpdateHub.ufoChickenStatus = "SENT_TO_CHAOS"

        if not silent then
            local dispName = targetData and (targetData.Name or targetName) or "Ayam Aktif"
            printLog("Auto UFO Event", string.format("Ayam '%s' aktif & dikirim ke arena tengah (To Chaos)!", dispName))
            notify("Auto UFO Event", string.format("Ayam '%s' aktif & dikirim ke arena tengah (To Chaos)!", dispName))
        end
    end)

    if not success then
        logError("executeSendChickenToUfoBeam", err)
    end

    UpdateHub.isUfoRunning = false
end

-- ==============================================================
-- [CORE CONTROLLER: AUTO CHICKEN BOSS EVENT]
-- ==============================================================
local cachedBossModel = nil
local lastBossModelCheck = 0
UpdateHub.findPitBoss = function()
    local now = os.clock()
    if now - lastBossModelCheck < 1.0 and cachedBossModel and cachedBossModel.Parent then
        return cachedBossModel
    end
    lastBossModelCheck = now

    local candidate = nil
    pcall(function()
        -- 1. Cek Model langsung di Workspace
        for _, obj in ipairs(Workspace:GetChildren()) do
            if (obj:IsA("Model") or obj:IsA("BasePart")) and not obj:IsA("Terrain") then
                local n = obj.Name:lower()
                if (n:find("boss") or n:find("giant") or n:find("titan") or n:find("chickenboss") or n:find("worldboss") or n:find("megachicken"))
                    and not n:find("player") and not n:find("spawner") and not n:find("gate") and not n:find("door") then
                    candidate = obj
                    break
                end
            end
        end

        -- 2. Cek Model di dalam folder Pit / World.Pit / Arena
        if not candidate then
            local pit = Workspace:FindFirstChild("Pit") 
                or (Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("Pit"))
                or Workspace:FindFirstChild("Arena")
                or (Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("Arena"))
            if pit then
                for _, desc in ipairs(pit:GetChildren()) do
                    if desc:IsA("Model") or desc:IsA("BasePart") then
                        local n = desc.Name:lower()
                        if (n:find("boss") or n:find("giant") or n:find("titan") or n:find("chickenboss") or n:find("worldboss") or n:find("megachicken"))
                            and not n:find("player") and not n:find("spawner") then
                            candidate = desc
                            break
                        end
                        local hum = desc:FindFirstChildOfClass("Humanoid")
                        if hum and hum.MaxHealth > 5000 and hum.Health > 0 then
                            candidate = desc
                            break
                        end
                    end
                end
            end
        end
    end)

    cachedBossModel = candidate
    return candidate
end

local lastBossCheckTime = 0
local cachedBossActive = false
UpdateHub.isBossEventActive = function()
    if UpdateHub.bossEventLive == true then
        return true
    end

    local now = os.clock()
    if UpdateHub.lastBossEndedTimestamp and (now - UpdateHub.lastBossEndedTimestamp < 45) then
        cachedBossActive = false
        return false
    end

    if now - lastBossCheckTime < 1.5 then
        return cachedBossActive
    end
    lastBossCheckTime = now

    local pitBoss = UpdateHub.findPitBoss()
    if pitBoss then
        cachedBossActive = true
        return true
    end

    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local rf = remotes and remotes:FindFirstChild("LiveEventGetActive")
        if not rf then
            rf = ReplicatedStorage:FindFirstChild("LiveEventGetActive", true)
        end
        if rf and rf:IsA("RemoteFunction") then
            local res = rf:InvokeServer()
            if res then
                if type(res) == "table" then
                    for k, v in pairs(res) do
                        local kStr = tostring(k):lower()
                        local vStr = tostring(v):lower()
                        if (kStr:find("boss") or kStr:find("giant") or kStr:find("raid") or vStr:find("boss") or vStr:find("giant") or vStr:find("raid")) then
                            if v ~= false and not vStr:find("false") and not vStr:find("ended") and not vStr:find("selesai") and not vStr:find("finish") and not kStr:find("ended") then
                                cachedBossActive = true
                                return true
                            end
                        end
                    end
                elseif type(res) == "string" then
                    local str = res:lower()
                    if (str:find("boss") or str:find("giant") or str:find("raid")) and not str:find("ended") and not str:find("selesai") and not str:find("finish") and not str:find("false") then
                        cachedBossActive = true
                        return true
                    end
                end
            end
        end
        return false
    end)
    if cachedBossActive == true then
        return true
    end

    local pit = Workspace:FindFirstChild("Pit") or (Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("Pit"))
    if pit then
        local found3DBillboard = false
        pcall(function()
            for _, desc in ipairs(pit:GetDescendants()) do
                if (desc:IsA("BillboardGui") or desc:IsA("SurfaceGui")) and desc.Enabled == true then
                    for _, t in ipairs(desc:GetDescendants()) do
                        if t:IsA("TextLabel") and t.Visible == true and (t.TextTransparency or 0) < 0.8 then
                            local txt = (t.Text or ""):lower()
                            if (txt:find("boss") or txt:find("giant") or txt:find("titan") or txt:find("world boss"))
                                and not txt:find("ended")
                                and not txt:find("selesai")
                                and not txt:find("over")
                                and not txt:find("next")
                                and not txt:find("starts in")
                                and not txt:find("cooldown") then
                                found3DBillboard = true
                                return
                            end
                        end
                    end
                end
            end
        end)
        if found3DBillboard then
            cachedBossActive = true
            return true
        end
    end

    local pg = player:FindFirstChild("PlayerGui")
    if pg then
        local foundHud = false
        pcall(function()
            for _, gui in ipairs(pg:GetChildren()) do
                local gName = gui.Name:lower()
                local isScriptGui = gName:find("wind") or gName:find("syshub") or gName:find("hub") or gName:find("dropdown")
                if gui:IsA("ScreenGui") and gui.Enabled and not isScriptGui then
                    for _, desc in ipairs(gui:GetDescendants()) do
                        if desc:IsA("TextLabel") and desc.Visible and (desc.TextTransparency or 0) < 0.8 then
                            local txt = (desc.Text or ""):lower()
                            if (txt:find("boss") or txt:find("giant chicken") or txt:find("world boss"))
                                and not txt:find("ended")
                                and not txt:find("selesai")
                                and not txt:find("over")
                                and not txt:find("next")
                                and not txt:find("starting") then
                                foundHud = true
                                return
                            end
                        end
                    end
                end
            end
        end)
        if foundHud then
            cachedBossActive = true
            return true
        end
    end

    cachedBossActive = false
    return false
end

UpdateHub.isBossPriorityActive = function()
    return (UpdateHub.autoBossEvent == true and UpdateHub.bossPriorityMode == true and UpdateHub.isBossEventActive() == true)
end

UpdateHub.handleBossEventEnded = function()
    if UpdateHub.isRestoringPreviousChickenBoss then
        return
    end
    UpdateHub.isRestoringPreviousChickenBoss = true

    UpdateHub.bossEventLive = false
    UpdateHub.lastBossEndedTimestamp = os.clock()
    cachedBossActive = false
    UpdateHub.isBossRunning = false

    task.spawn(function()
        pcall(function()
            local prevId = UpdateHub.previousActiveChickenIdBoss or UpdateHub.lastKnownNonBossChickenId
            local prevName = UpdateHub.previousActiveChickenNameBoss or UpdateHub.lastKnownNonBossChickenName or (prevId and tostring(prevId))

            printLog("Auto Boss Event", string.format("Event Chicken Boss Selesai! Mengirim sinyal kembali ke coop & memproses pemulihan ayam: %s (ID: %s)...", tostring(prevName or "Default"), tostring(prevId or "None")))

            UpdateHub.returnChickenToCoop()

            if prevId then
                local numId = tonumber(string.match(tostring(prevId), "%d+"))
                local restored = false
                local startRestore = os.clock()

                while (os.clock() - startRestore < 12) do
                    local curId = UpdateHub.getCurrentActiveChicken()
                    if curId and (tostring(curId) == tostring(prevId) or (numId and tostring(curId) == tostring(numId))) then
                        restored = true
                        break
                    end

                    pcall(function()
                        invokeRemote("SetActiveChicken", prevId)
                        if numId and numId ~= prevId then
                            invokeRemote("SetActiveChicken", numId)
                        end
                        invokeRemote("Equip", prevId)
                        if numId and numId ~= prevId then
                            invokeRemote("Equip", numId)
                        end
                    end)

                    pcall(function()
                        if chickenMap then
                            for _, data in pairs(chickenMap) do
                                if (tostring(data.Id) == tostring(prevId) or (data.NumId and tostring(data.NumId) == tostring(prevId))) then
                                    local btn = data.Button or (data.Frame and (data.Frame:IsA("GuiButton") and data.Frame or data.Frame:FindFirstChildWhichIsA("GuiButton", true)))
                                    if btn and firesignal then
                                        firesignal(btn.MouseButton1Click)
                                        firesignal(btn.Activated)
                                    end
                                    break
                                end
                            end
                        end
                    end)

                    task.wait(1.0)
                end

                if restored then
                    printLog("Auto Boss Event", string.format("Event Boss selesai! Ayam berhasil dikembalikan ke: %s (ID: %s)", tostring(prevName), tostring(prevId)))
                    notify("Auto Boss Event", string.format("Event Boss selesai! Ayam dikembalikan ke: %s", tostring(prevName)))
                else
                    warn("[Auto Boss Event]: Gagal merestore ayam aktif semula dalam batas waktu 12 detik.")
                end
            end

            UpdateHub.previousActiveChickenIdBoss = nil
            UpdateHub.previousActiveChickenNameBoss = nil
            UpdateHub.bossChickenStatus = "AT_BASE"
            UpdateHub.lastBossSendTime = 0
            UpdateHub.lastBossChaosEntryTime = nil
            UpdateHub.isRestoringPreviousChickenBoss = false

            if UpdateHub.bossStatusParagraph then
                pcall(function()
                    UpdateHub.bossStatusParagraph:SetDesc("Status: Event Boss Selesai (Standby)")
                end)
            end
        end)
    end)
end

UpdateHub.executeSendChickenToBoss = function(silent)
    if UpdateHub.isBossRunning then
        return
    end
    UpdateHub.isBossRunning = true

    local success, err = pcall(function()
        local rawTarget = UpdateHub.selectedBossChickenName
        local targetName = rawTarget
        if type(rawTarget) == "table" then
            targetName = rawTarget.Title or rawTarget.Name or rawTarget[1] or tostring(rawTarget)
        end

        local targetData = nil
        if targetName and chickenMap and chickenMap[targetName] then
            targetData = chickenMap[targetName]
        end

        if not targetData and chickenNames and #chickenNames > 0 and chickenNames[1] ~= "Tidak ada ayam" and chickenNames[1] ~= "Belum di-refresh (Klik tombol Refresh)" and chickenNames[1] ~= "Buka menu Flock di game lalu klik Refresh!" then
            local fallbackName = chickenNames[1]
            if type(fallbackName) == "table" then
                fallbackName = fallbackName.Title or fallbackName.Name or fallbackName[1]
            end
            if fallbackName and chickenMap and chickenMap[fallbackName] then
                targetData = chickenMap[fallbackName]
                targetName = fallbackName
                UpdateHub.selectedBossChickenName = targetName
            end
        end

        local curId, curName = UpdateHub.getCurrentActiveChicken()
        local cId = targetData and targetData.Id

        if UpdateHub.autoBossEvent and not UpdateHub.previousActiveChickenIdBoss then
            if curId and (not cId or tostring(curId) ~= tostring(cId)) then
                UpdateHub.previousActiveChickenIdBoss = curId
                UpdateHub.previousActiveChickenNameBoss = curName or tostring(curId)
            elseif UpdateHub.lastKnownNonBossChickenId and tostring(UpdateHub.lastKnownNonBossChickenId) ~= tostring(cId) then
                curId = UpdateHub.lastKnownNonBossChickenId
                curName = UpdateHub.lastKnownNonBossChickenName
                UpdateHub.previousActiveChickenIdBoss = curId
                UpdateHub.previousActiveChickenNameBoss = curName
            end

            if curId and not UpdateHub.previousActiveChickenIdBoss then
                UpdateHub.previousActiveChickenIdBoss = curId
                UpdateHub.previousActiveChickenNameBoss = curName or tostring(curId)
            end

            if curId and (not cId or tostring(curId) ~= tostring(cId)) then
                UpdateHub.lastKnownNonBossChickenId = curId
                UpdateHub.lastKnownNonBossChickenName = curName or tostring(curId)
            end

            printLog("Auto Boss Event", string.format("Menyimpan ayam aktif sebelum event Boss: %s (ID: %s)", tostring(UpdateHub.previousActiveChickenNameBoss), tostring(curId)))
            if UpdateHub.bossPriorityMode then
                printLog("Prioritas Boss", "Event Boss aktif! Fitur lain (Fast Rebirth, Tower, Sweep, Arena) dijeda sementara...")
                notify("Prioritas Boss", "Event Chicken Boss aktif! Menjeda sementara fitur pergerakan & rebirth.")
            end
        end

        if cId then
            local numId = tonumber(string.match(tostring(cId), "%d+"))
            local isAlreadyActive = (curId and (tostring(curId) == tostring(cId) or (numId and tostring(curId) == tostring(numId))))

            if not isAlreadyActive then
                pcall(function()
                    invokeRemote("SetActiveChicken", cId)
                    if numId and numId ~= cId then
                        invokeRemote("SetActiveChicken", numId)
                    end
                    invokeRemote("Equip", cId)
                    if numId and numId ~= cId then
                        invokeRemote("Equip", numId)
                    end
                end)
                task.wait(0.3)
            end
        end

        if not UpdateHub.isBossEventActive() or (UpdateHub.lastBossEndedTimestamp and (os.clock() - UpdateHub.lastBossEndedTimestamp < 45)) then
            UpdateHub.isBossRunning = false
            return
        end

        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes and remotes:FindFirstChild("SetChickenOrder") then
                remotes.SetChickenOrder:FireServer("chaos")
            end
        end)

        UpdateHub.lastBossSendTime = os.clock()
        UpdateHub.bossChickenStatus = "SENT_TO_CHAOS"

        if not silent then
            local dispName = targetData and (targetData.Name or targetName) or "Ayam Aktif"
            printLog("Auto Boss Event", string.format("Ayam '%s' aktif & dikirim menyerang Chicken Boss di Pit!", dispName))
            notify("Auto Boss Event", string.format("Ayam '%s' dikirim menyerang Chicken Boss!", dispName))
        end
    end)

    if not success then
        logError("executeSendChickenToBoss", err)
    end
    UpdateHub.isBossRunning = false
end

-- ==============================================================
-- SECTION 3: AUTO UFO EVENT (Elements)
-- ==============================================================

UfoSec:Paragraph({
    Title = "UFO INVASION Event (To Chaos)",
    Desc = "1. Pilih ayam target dari kawanan flock.\n2. Saat Auto UFO aktif, bot mendeteksi event UFO secara otomatis.\n3. Sebelum mengirim ayam UFO, bot otomatis mencatat ayam yang sedang aktif saat ini.\n4. Perintah 'To Chaos' dikirim 1x saat ayam berada di base, tanpa spam agar ayam tidak bulak-balik.\n5. Saat ayam selesai di-upgrade & KO kembali ke base, bot otomatis mengirim ulang ayam ke tengah arena sampai event selesai.\n6. Begitu event UFO selesai, bot otomatis mengembalikan ayam yang aktif ke ayam semula sebelum event (misal Catalyst Hen)."
})

UfoSec:Button({
    Title = "Refresh Daftar Ayam",
    Callback = function()
        scanFlockChickens()
        notify("UFO Event", "Daftar ayam flock berhasil diperbarui!")
    end
})

UpdateHub.ufoChickenDropdown = UfoSec:Dropdown({
    Title = "Pilih Ayam Target UFO:",
    Flag = "selected_ufo_chicken_name",
    Values = chickenNames,
    Value = chickenNames[1],
    MenuWidth = 300,
    Multi = false,
    Callback = function(val)
        local str = ""
        if type(val) == "string" then
            str = val
        elseif type(val) == "table" then
            for k, v in pairs(val) do
                if v == true then
                    str = k
                    break
                elseif type(k) == "number" and type(v) == "string" then
                    str = v
                    break
                end
            end
            if str == "" and (val.Title or val.Name) then
                str = val.Title or val.Name
            end
        end
        UpdateHub.selectedUfoChickenName = str ~= "" and str or tostring(val)
    end
})
if expandDropdown then
    expandDropdown(UpdateHub.ufoChickenDropdown, 300)
end

UfoSec:Button({
    Title = "Kirim Ayam ke Tengah Arena (To Chaos)",
    Callback = function()
        task.spawn(function()
            UpdateHub.executeSendChickenToUfoBeam(false)
        end)
    end
})

UfoSec:Toggle({
    Title = "Auto Deteksi UFO & Kirim Ayam ke Chaos",
    Flag = "auto_ufo_event",
    Callback = function(state)
        UpdateHub.autoUfoEvent = parseToggle(state)
        if UpdateHub.autoUfoEvent then
            UpdateHub.ufoChickenStatus = "AT_BASE"
            pcall(function()
                local curId, curName = UpdateHub.getCurrentActiveChicken()
                local ufoName = UpdateHub.selectedUfoChickenName
                local ufoData = ufoName and chickenMap and chickenMap[ufoName]
                local ufoId = ufoData and ufoData.Id
                if curId and (not ufoId or tostring(curId) ~= tostring(ufoId)) then
                    UpdateHub.lastKnownNonUfoChickenId = curId
                    UpdateHub.lastKnownNonUfoChickenName = curName or tostring(curId)
                    printLog("Auto UFO Event", string.format("Snapshot ayam aktif tersimpan: %s (ID: %s)", tostring(curName), tostring(curId)))
                end
            end)
            notify("Auto UFO Event", "Auto UFO Event aktif! Menunggu deteksi event UFO...")
        else
            pcall(function()
                if UpdateHub.handleUfoEventEnded then
                    UpdateHub.handleUfoEventEnded()
                end
            end)
            UpdateHub.ufoChickenStatus = "AT_BASE"
        end
    end
})

UfoSec:Toggle({
    Title = "Prioritaskan UFO (Jeda Fitur Lain)",
    Flag = "ufo_priority_mode",
    Value = true,
    Callback = function(state)
        UpdateHub.ufoPriorityMode = parseToggle(state)
        if UpdateHub.ufoPriorityMode then
            notify("Prioritas UFO", "Fitur lain (Fast Rebirth, Tower, Sweep, Arena) otomatis dijeda saat event UFO.")
        else
            notify("Prioritas UFO", "Mode prioritas dinonaktifkan. Fitur lain akan tetap berjalan bersamaan.")
        end
    end
})
end

-- ==============================================================================
end
