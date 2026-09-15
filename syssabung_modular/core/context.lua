-- ==============================================================================
--              SYSHUB | CORE CONTEXT (SHARED REGISTRY & ENGINE)
-- ==============================================================================
local Context = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

Context.Players = Players
Context.Workspace = Workspace
Context.ReplicatedStorage = ReplicatedStorage
Context.CoreGui = CoreGui
Context.RunService = RunService
Context.UserInputService = UserInputService
Context.Lighting = Lighting
Context.TeleportService = TeleportService
Context.HttpService = HttpService
Context.player = player

-- [CONFIG SYSTEM]: MANUAL CONFIGURATION MANAGER (ELEMENT REGISTRY & STORAGE)
-- ==============================================================================
local registeredUiElements = {}
-- Interceptor WindUI: Otomatis mencatat setiap elemen UI yang memiliki Flag
pcall(function()
    if Window and type(Window.Tab) == "function" then
        local originalWindowTab = Window.Tab
        Window.Tab = function(self, tabConfig)
            local tab = originalWindowTab(self, tabConfig)
            if tab and type(tab.Section) == "function" then
                local originalTabSection = tab.Section
                tab.Section = function(tSelf, secConfig)
                    local sec = originalTabSection(tSelf, secConfig)
                    if sec then
                        local elemTypes = {"Toggle", "Input", "Slider", "Dropdown", "Colorpicker", "Keybind"}
                        for _, eType in ipairs(elemTypes) do
                            local origFn = sec[eType]
                            if type(origFn) == "function" then
                                sec[eType] = function(sSelf, elemConfig)
                                    local el = origFn(sSelf, elemConfig)
                                    if elemConfig and elemConfig.Flag and el then
                                        registeredUiElements[elemConfig.Flag] = el
                                    end
                                    return el
                                end
                            end
                        end
                    end
                    return sec
                end
            end
            return tab
        end
    end
end)

local function saveConfig()
    -- Auto-save dinonaktifkan sesuai preferensi: Pengguna menyimpan konfigurasi secara manual melalui Tab Misc.
end

-- ==============================================================================
-- [FIX WINDUI DROPDOWN POPUP WIDTH]: UNLOCK UISizeConstraint & AUTO-EXPAND
-- Mengatasi batasan default WindUI (180px - 300px) agar daftar popup ayam
-- bisa terbuka lebar (300px) dan seluruh teks ayam terlihat utuh!
-- ==============================================================================
local expandDropdown = nil
local function setupDropdownPopupExpander()
    local TARGET_POPUP_WIDTH = 300

    local function patchGui(gui)
        if not gui then
            return
        end
        local function fixDescendant(inst)
            pcall(function()
                if inst:IsA("UISizeConstraint") then
                    inst:Destroy()
                elseif inst:IsA("Frame") and inst.Parent == gui then
                    inst.Size = UDim2.new(0, TARGET_POPUP_WIDTH, inst.Size.Y.Scale, inst.Size.Y.Offset)
                    for _, child in ipairs(inst:GetChildren()) do
                        if child:IsA("UISizeConstraint") then
                            child:Destroy()
                        end
                    end
                end
            end)
        end

        for _, desc in ipairs(gui:GetDescendants()) do
            fixDescendant(desc)
        end
        gui.DescendantAdded:Connect(function(desc)
            task.defer(function()
                fixDescendant(desc)
            end)
        end)
    end

    pcall(function()
        if WindUI and WindUI.DropdownGui then
            patchGui(WindUI.DropdownGui)
        end

        local hGui = (gethui and gethui()) or CoreGui
        if hGui then
            local dropScreen = hGui:FindFirstChild("WindUI/Dropdowns") or hGui:FindFirstChild("DropdownGui")
            if dropScreen then
                patchGui(dropScreen)
            end
            hGui.ChildAdded:Connect(function(child)
                if child.Name:find("Dropdown") then
                    patchGui(child)
                end
            end)
        end

        local pGui = player:FindFirstChild("PlayerGui")
        if pGui then
            local dropScreen = pGui:FindFirstChild("WindUI/Dropdowns")
            if dropScreen then
                patchGui(dropScreen)
            end
            pGui.ChildAdded:Connect(function(child)
                if child.Name:find("Dropdown") then
                    patchGui(child)
                end
            end)
        end
    end)
end
setupDropdownPopupExpander()

expandDropdown = function(dd, width)
    if not dd then
        return
    end
    local w = width or 300
    pcall(function()
        if dd.UIElements then
            local canvas = dd.UIElements.MenuCanvas
            if canvas then
                for _, c in ipairs(canvas:GetChildren()) do
                    if c:IsA("UISizeConstraint") then
                        c:Destroy()
                    end
                end
                canvas.Size = UDim2.new(0, w, canvas.Size.Y.Scale, canvas.Size.Y.Offset)

                if not canvas:GetAttribute("WidthEnforced") then
                    canvas:SetAttribute("WidthEnforced", true)
                    canvas:GetPropertyChangedSignal("Visible"):Connect(function()
                        if canvas.Visible then
                            pcall(function()
                                for _, c in ipairs(canvas:GetChildren()) do
                                    if c:IsA("UISizeConstraint") then
                                        c:Destroy()
                                    end
                                end
                                canvas.Size = UDim2.new(0, w, canvas.Size.Y.Scale, canvas.Size.Y.Offset)
                            end)
                            task.defer(function()
                                pcall(function()
                                    canvas.Size = UDim2.new(0, w, canvas.Size.Y.Scale, canvas.Size.Y.Offset)
                                end)
                            end)
                            task.delay(0.05, function()
                                pcall(function()
                                    canvas.Size = UDim2.new(0, w, canvas.Size.Y.Scale, canvas.Size.Y.Offset)
                                end)
                            end)
                        end
                    end)

                    canvas:GetPropertyChangedSignal("Size"):Connect(function()
                        if canvas.Size.X.Offset ~= w then
                            canvas.Size = UDim2.new(0, w, canvas.Size.Y.Scale, canvas.Size.Y.Offset)
                        end
                    end)
                end
            end

            if dd.UIElements.Dropdown then
                dd.UIElements.Dropdown.Size = UDim2.new(0, 240, 0, 36)
            end
        end
    end)
end


-- [2] LOGGING & NOTIFICATION HELPERS
-- ==============================================================================
local function logError(featureName, err)
    warn(string.format("[SysHub ERROR - %s]: %s", tostring(featureName), tostring(err)))
end

local function printLog(featureName, msg)
    print(string.format("[SysHub - %s]: %s", tostring(featureName), tostring(msg)))
end

local function notify(title, content)
    pcall(function()
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = title,
                Content = content,
                Duration = 3
            })
        end
    end)
end

local function parseToggle(state)
    if type(state) == "boolean" then
        return state
    end
    if type(state) == "table" and state.Value ~= nil then
        return state.Value == true
    end
    return state == true
end

-- ==============================================================================
-- [3] VARIABEL & PENGATURAN DEFAULT
-- ==============================================================================
-- PLOT IDENTIFICATION
local currentPlotId = player:GetAttribute("Plot") or 1
pcall(function()
    player:GetAttributeChangedSignal("Plot"):Connect(function()
        currentPlotId = player:GetAttribute("Plot") or 1
        if getgenv then
            getgenv().currentPlotId = currentPlotId
        end
    end)
    if getgenv then
        getgenv().currentPlotId = currentPlotId
    end
end)

-- FAST REBIRTH (FARM TAB)
local autoFastRebirth = false
local autoRebirth = false -- alias kompatibilitas
local delayFastRebirth = 1
local delayRebirth = 1
local fastAutoUpgradeCoop = true
local fastTargetCoop = 1 -- Default target Coop level 1
local fastAutoUpgradeFeeder = true
local fastTargetFeederCount = 2 -- Default jumlah feeder 2
local fastTargetFeederLevel = 10 -- Default level feeder 10
local fastMaxFeeders = 2 -- alias kompatibilitas
local fastAutoTower = true
local fastTargetFloor = 25
local cachedRequiredFloor = nil
local lastSilentRefreshTime = 0
local fastFloorOverride = 0 -- 0 = otomatis ikuti syarat game
local updateFastRebirthStatus = nil
local fastRebirthCurrentAction = "Standby (Fast Rebirth Siap Diaktifkan)"

-- COOP
local autoUpgradeCoop = false
local delayCoop = 0.5
local autoUpgradeRecycler = false
local delayRecycler = 0.1
local autoBuyFeeder = false
local delayBuy = 0.1
local autoUpgradeFeeder = false
local delayUpgrade = 0.1
local MAX_FEEDER_SLOTS = 6
local autoCollectNestEggs = false
local delayCollectEgg = 1

-- FARM
local autoClaimIncubator = false
local autoPutIncubator = false
local autoUpgradeIncubator = false
local delayUpgradeIncubator = 1.5
local autoSweep = false
local isSweepRunning = false
local MAX_CAPACITY = 20
local autoTower = false
local retreatFloor = 0
local delayTower = 0.5
local towerHpThreshold = 100 -- HP% threshold untuk kirim ayam lagi ke tower (10-100)
local towerStartMode = "Lanjut Lantai Tertinggi" -- "Lanjut Lantai Tertinggi" atau "Mulai dari Lantai 1"
local autoSellChickens = false
local delaySellChicken = 0.5
local sellMaxLevelProtection = 5
local selectedSellRarities = {
    ["Common"] = true,
    ["Uncommon"] = true,
    ["Rare"] = false,
    ["Epic"] = false,
    ["Legendary"] = false,
    ["Mythic"] = false,
    ["Divine"] = false,
    ["Celestial"] = false,
    ["Cosmic"] = false,
    ["Secret"] = false
}

-- CHICKEN
local autoPromote = false
local delayPromote = 1
local selectedPromoteTarget = nil
local promoteTargetList = {"Belum di-refresh (Klik tombol Refresh)"}
local promoteTargetMap = {}
local selectedPromoteFodder = nil
local selectedPromoteFoddersMap = {}
local promoteFodderList = {"Pilih ayam target terlebih dahulu"}
local promoteFodderMap = {}
local globalSpeciesTracker = {}
local updatePromoteStatusDisplay = nil
local promoteStatusPara = nil
local autoPromoteToggle = nil

local autoFuse = false
local fuseMainChickenName = nil
local fuseFodderChickenName = nil
local fuseLockedSkill = "Stormcall"

local favoritedChickenIds = {}
local promotedChickenIds = {}
local selectedFavChickenName = nil

-- WEBHOOK
local webhookUrl = ""
local webhookRebirthEnabled = true
local triggerWebhookRebirthEvent = function(newCount) end

-- REWARDS & UPDATE HUB
local UpdateHub = {
    -- JURASSIC EVENT & ANCIENT EGG (UPDATE)
    autoClaimJurassicPass = false,
    autoClaimJurassicQuests = false,
    autoDeliverJurassicEggs = false,
    autoReturnToCoopAfterEvent = true,
    initialSpawnPosition = nil,
    customFrontCoopPos = nil,
    deliveryMode = "Safe Walk",
    prioritizeEggColor = true,
    autoDetectMidwayEgg = true,
    cycleDelay = 0.5,
    midwayEggDetected = false,
    eventWalkSpeed = 22,
    recentPickedJurassicEggs = {},
    lastJurassicEggCheckTime = 0,
    cachedJurassicEggActive = false,
    midpathWatcherConnections = {},
    movementModeDropdown = nil,
    walkSpeedDropdown = nil,
    priorityEggDropdown = nil,
    delayMovementInput = nil,
    isJurassicEggLive = false,
    isDeliveringJurassicEgg = false,
    holdingJurassicEgg = false,
    holdingJurassicEggTime = 0,
    jurassicEggStatusParagraph = nil,
    -- REWARDS
    autoClaimPlayToday = false,
    autoClaimDailyStreak = false,
    autoClaimMission = false,
    autoClaimCharmDust = false,
    autoClaimArena = false,
    autoClaimMilestones = false,
    autoClaimIndex = false,

    -- ARENA AUTO-BATTLE (UPDATE)
    autoArenaFight = false,
    delayArenaFight = 3.0,
    isArenaFightRunning = false,

    -- AUTO UFO EVENT (UPDATE)
    autoUfoEvent = false,
    ufoPriorityMode = true,
    selectedUfoChickenName = nil,
    ufoChickenDropdown = nil,
    isUfoRunning = false,
    ufoEventLive = false,
    lastUfoEndedTimestamp = 0,
    ufoChickenStatus = "AT_BASE",
    lastUfoSendTime = 0,
    previousActiveChickenId = nil,
    previousActiveChickenName = nil,
    lastKnownNonUfoChickenId = nil,
    lastKnownNonUfoChickenName = nil,
    lastChaosEntryTime = nil,
    lastUfoNudgeTime = 0,
    isRestoringPreviousChicken = false,
    isUfoEventActive = function() return false end,
    isUfoPriorityActive = function() return false end,
    getUfoBeamPosition = function() return Vector3.new(0, 5, 0) end,
    getMyChickenBody = function() return nil end,
    getChickenUfoLocation = function() return "AT_BASE" end,
    getCurrentActiveChicken = function() return nil, nil, nil end,
    restorePreviousChicken = function(prevId, prevName) end,
    returnChickenToCoop = function() end,
    handleUfoEventEnded = function() end,
    executeSendChickenToUfoBeam = function(silent) end,

    -- AUTO CHICKEN BOSS EVENT (UPDATE)
    autoBossEvent = false,
    bossPriorityMode = true,
    selectedBossChickenName = nil,
    bossChickenDropdown = nil,
    isBossRunning = false,
    bossEventLive = false,
    lastBossEndedTimestamp = 0,
    bossChickenStatus = "AT_BASE",
    lastBossSendTime = 0,
    previousActiveChickenIdBoss = nil,
    previousActiveChickenNameBoss = nil,
    lastKnownNonBossChickenId = nil,
    lastKnownNonBossChickenName = nil,
    lastBossChaosEntryTime = nil,
    lastBossNudgeTime = 0,
    isRestoringPreviousChickenBoss = false,
    bossStatusParagraph = nil,
    isBossEventActive = function() return false end,
    isBossPriorityActive = function() return false end,
    findPitBoss = function() return nil end,
    handleBossEventEnded = function() end,
    executeSendChickenToBoss = function(silent) end,

    -- CHARMS AUTOMATION (UPDATE)
    autoRollCharms = false,
    selectedCharmChickenName = nil,
    charmMinTier = "Super Rare+",
    charmPreferredStats = {
        ["atk"] = true,
        ["hp"] = true,
        ["crit"] = true,
        ["critDmg"] = true
    },
    charmDropdown = nil,
    isCharmRolling = false,

    -- EGG UNBOXING & AUTO OPEN (UPDATE)
    autoHatchEggs = false,
    selectedEggType = "Fortune Egg",
    delayHatchEggs = 1.0,
    isHatchingEggs = false,
    eggDropdown = nil,
    eggKeepDropdown = nil,
    selectedKeepSpecies = {},
    autoKeepInverted = true,
    autoKeepJurassic = true,
    ownedEggTypes = {},
    eggOpenRepeatCount = 5,
    stopHatching = false,

    -- BOOST FPS & PERFORMANCE (MISC)
    boostFps = false,
    lowTextures = false,
    disable3dRendering = false,
    fpsCap = "Default (60)"
}

-- Catat posisi awal saat pemain masuk game / spawn (tempat awal masuk game posisinya)
pcall(function()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        UpdateHub.initialSpawnPosition = hrp.Position
    end
end)
player.CharacterAdded:Connect(function(char)
    task.spawn(function()
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if hrp then
            task.wait(0.5)
            local pit = Workspace:FindFirstChild("AncientEggPit", true) or Workspace:FindFirstChild("EggPit", true)
            local pitPos = pit and (pit:IsA("BasePart") and pit.Position or pit:GetPivot().Position)
            if not pitPos or (hrp.Position - pitPos).Magnitude > 80 then
                UpdateHub.initialSpawnPosition = hrp.Position
            end
        end
    end)
end)

local customPromoCode = ""
local promoCodesList = {
    "RELEASE", "CHICKEN", "FIGHTER", "EGG", "ARENA",
    "1KLIKES", "5KLIKES", "10KLIKES", "UPDATE1", "UPDATE2",
    "SECRET", "TOWER", "GOOSE", "BOOST", "FREE", "COOP",
    "DUST", "GOLD", "LUCKY"
}

-- PLAYER
local espPlayerEnabled = false
local espEggEnabled = false
local espScrapEnabled = false
local streamerMode = false
local fakeName = "Anonymous"

-- DROPDOWNS & MAPS
local chickenNames = {"Belum di-refresh (Klik tombol Refresh)"}
local chickenMap = {}
local selectedChickenName = nil
local selectedChickenId = nil
local chickenDropdown = nil
local promoteTargetDropdown = nil
local promoteFodderDropdown = nil
local promoteDropdown = nil
local fuseMainDropdown = nil
local fuseFodderDropdown = nil
local fuseSkillDropdown = nil
local availableFuseSkills = {"Stormcall", "Final Grace", "Lightning Strike", "Inferno Breath", "Void Pulse", "Golden Touch"}
local favDropdown = nil

-- ==============================================================================
-- [4] FUNGSI UNIVERSAL PANGGIL REMOTE
-- ==============================================================================
local remoteCache = {}
local function invokeRemote(remoteName, ...)
    local args = {...}
    local remote = remoteCache[remoteName]
    if not remote or not remote.Parent then
        local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
        if remotesFolder then
            remote = remotesFolder:FindFirstChild(remoteName)
        end

        if not remote then
            local reFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
            if reFolder then
                remote = reFolder:FindFirstChild(remoteName)
            end
        end

        if not remote then
            for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
                if (desc:IsA("RemoteFunction") or desc:IsA("RemoteEvent")) and desc.Name == remoteName then
                    remote = desc
                    break
                end
            end
        end

        if remote then
            remoteCache[remoteName] = remote
        end
    end

    if not remote then
        logError("invokeRemote", "Remote '" .. tostring(remoteName) .. "' tidak ditemukan!")
        return nil
    end

    local success, ret = pcall(function()
        if remote:IsA("RemoteFunction") then
            return remote:InvokeServer(unpack(args))
        elseif remote:IsA("RemoteEvent") then
            remote:FireServer(unpack(args))
            return true
        end
        return nil
    end)

    if not success then
        logError("invokeRemote (" .. tostring(remoteName) .. ")", ret)
        return nil
    end
    return ret
end

-- ==============================================================================
-- [5] SISTEM AUTO "NO THANKS" & SKIP ANIMASI KO
-- ==============================================================================
local function dismissTowerKOUI()
    pcall(function()
        local playerGui = player:FindFirstChild("PlayerGui")
        if not playerGui then
            return
        end

        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled then
                for _, desc in ipairs(gui:GetDescendants()) do
                    if desc:IsA("TextButton") or desc:IsA("TextLabel") then
                        local txt = (desc.Text or ""):lower()
                        if txt:find("no thanks") or txt:find("no, thanks") or txt:find("decline") or txt:find("give up") then
                            local targetBtn = nil
                            if desc:IsA("TextButton") then
                                targetBtn = desc
                            elseif desc.Parent and desc.Parent:IsA("TextButton") then
                                targetBtn = desc.Parent
                            end

                            if targetBtn and firesignal then
                                pcall(function()
                                    firesignal(targetBtn.MouseButton1Click)
                                end)
                                pcall(function()
                                    firesignal(targetBtn.Activated)
                                end)
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- Interseptor Jaringan Instan
task.spawn(function()
    local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 5)
    if remotesFolder then
        local offerRemote = remotesFolder:FindFirstChild("TowerContinueOffer")
        if offerRemote and offerRemote:IsA("RemoteEvent") then
            offerRemote.OnClientEvent:Connect(function()
                task.wait(0.05)
                invokeRemote("TowerContinueDecline")
                dismissTowerKOUI()
                printLog("Auto Tower", "Mendapat tawaran Robux! Otomatis pilih 'No Thanks' & skip animasi.")
            end)
        end

        local defeatRemote = remotesFolder:FindFirstChild("TowerDefeat")
        if defeatRemote and defeatRemote:IsA("RemoteEvent") then
            defeatRemote.OnClientEvent:Connect(function()
                task.wait(0.05)
                invokeRemote("TowerContinueDecline")
                dismissTowerKOUI()
            end)
        end

        -- LiveEvent Listeners (UFO Invasion dsb)
        local leStarted = remotesFolder:FindFirstChild("LiveEventStarted")
        if leStarted and leStarted:IsA("RemoteEvent") then
            leStarted.OnClientEvent:Connect(function(eventData)
                local str = tostring(eventData):lower()
                if type(eventData) == "table" then
                    str = (eventData.id or eventData.name or eventData.title or ""):lower()
                end
                if str:find("ufo") or str:find("invasion") then
                    UpdateHub.ufoEventLive = true
                    UpdateHub.lastUfoEndedTimestamp = 0
                    printLog("UFO Event", "LiveEventStarted: UFO INVASION Aktif!")
                elseif str:find("boss") or str:find("giant") or str:find("raid") or str:find("world_boss") or str:find("titan") then
                    UpdateHub.bossEventLive = true
                    UpdateHub.lastBossEndedTimestamp = 0
                    printLog("Boss Event", "LiveEventStarted: CHICKEN BOSS Aktif!")
                end
            end)
        end

        local leEnded = remotesFolder:FindFirstChild("LiveEventEnded")
        if leEnded and leEnded:IsA("RemoteEvent") then
            leEnded.OnClientEvent:Connect(function(eventData)
                local str = tostring(eventData):lower()
                if type(eventData) == "table" then
                    str = (eventData.id or eventData.name or eventData.title or ""):lower()
                end
                if str:find("ufo") or str:find("invasion") then
                    UpdateHub.ufoEventLive = false
                    UpdateHub.lastUfoEndedTimestamp = os.clock()
                    UpdateHub.isUfoRunning = false
                    printLog("UFO Event", "LiveEventEnded: UFO INVASION Selesai!")

                    pcall(function()
                        local fn = rawget(UpdateHub, "handleUfoEventEnded") or UpdateHub.handleUfoEventEnded
                        if fn then
                            fn()
                        end
                    end)
                elseif str:find("boss") or str:find("giant") or str:find("raid") or str:find("world_boss") or str:find("titan") then
                    UpdateHub.bossEventLive = false
                    UpdateHub.lastBossEndedTimestamp = os.clock()
                    UpdateHub.isBossRunning = false
                    printLog("Boss Event", "LiveEventEnded: CHICKEN BOSS Selesai!")

                    pcall(function()
                        local fn = rawget(UpdateHub, "handleBossEventEnded") or UpdateHub.handleBossEventEnded
                        if fn then
                            fn()
                        end
                    end)
                end
            end)
        end
    end
end)

-- Thread Pengawas UI KO
task.spawn(function()
    while true do
        if not autoTower and not autoFastRebirth then
            task.wait(1.5)
        else
            task.wait(0.5)
            dismissTowerKOUI()
        end
    end
end)

-- ==============================================================================
-- [6] FUNGSI BANTUAN UMUM & KAPASITAS TAS ASLI (DARI SCRIPT KERJA)
-- ==============================================================================
local function isHeldBySomeone(obj)
    local success, result = pcall(function()
        local parent = obj.Parent
        while parent and parent ~= Workspace do
            if parent:IsA("Model") and parent:FindFirstChild("Humanoid") then
                return true
            end
            parent = parent.Parent
        end
        return false
    end)
    return success and result or false
end

local function getNearestScrap(currentPos, scrapList)
    local nearest, minDist, nearestIdx = nil, math.huge, nil
    pcall(function()
        for i, obj in ipairs(scrapList) do
            if obj and obj.Parent then
                local targetPos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
                local dist = (Vector3.new(targetPos.X, 0, targetPos.Z) - Vector3.new(currentPos.X, 0, currentPos.Z)).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = obj
                    nearestIdx = i
                end
            end
        end
    end)
    return nearest, nearestIdx
end

local function fireCollectEvents(obj, hrp)
    pcall(function()
        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
        if not prompt and obj.Parent then
            prompt = obj.Parent:FindFirstChildWhichIsA("ProximityPrompt", true)
        end
        if prompt then
            pcall(function()
                fireproximityprompt(prompt)
            end)
        end

        local touch = obj:FindFirstChild("TouchInterest")
        if not touch and obj.Parent then
            touch = obj.Parent:FindFirstChild("TouchInterest")
        end

        if touch and firetouchinterest then
            pcall(function()
                firetouchinterest(hrp, obj, 0)
                task.wait(0.01)
                firetouchinterest(hrp, obj, 1)
            end)
        end
    end)
end

local function getCurrentFloor()
    local success, result = pcall(function()
        local ls = player:FindFirstChild("leaderstats")
        if ls then
            local tower = ls:FindFirstChild("Tower")
            if tower and tower:IsA("ValueBase") then
                local val = tonumber(tower.Value)
                return val or 0
            end
        end
        return 0
    end)
    return (success and type(result) == "number") and result or 0
end

local liveRebirthCount = 0

local function getRebirthCount()
    -- 1. Jalur DataService resmi via ReplicatedStorage (Replicated, aman dan resmi diakses)
    pcall(function()
        local pkg = ReplicatedStorage:FindFirstChild("Packages")
        local dsMod = pkg and pkg:FindFirstChild("DataService")
        if dsMod and dsMod:IsA("ModuleScript") then
            local ds = require(dsMod)
            local client = ds and ds.client
            if client and type(client.get) == "function" then
                local cur = client:get({"rebirth"})
                if type(cur) == "table" and type(cur.count) == "number" then
                    liveRebirthCount = cur.count
                elseif type(cur) == "number" then
                    liveRebirthCount = cur
                end
            end
        end
    end)

    -- 2. Jalur getloadedmodules (Mencari DataController yang sudah aktif di memori client)
    if liveRebirthCount <= 0 and type(getloadedmodules) == "function" then
        pcall(function()
            for _, m in ipairs(getloadedmodules()) do
                if m.Name == "DataController" then
                    local dc = require(m)
                    if dc and type(dc.rebirth) == "function" then
                        local res = dc.rebirth()
                        if type(res) == "table" and type(res.count) == "number" then
                            liveRebirthCount = res.count
                            return
                        elseif type(res) == "number" then
                            liveRebirthCount = res
                            return
                        end
                    end
                end
            end
        end)
    end

    -- 3. Jalur GUI Rebirth jika menu pernah dibuka atau dirender
    if liveRebirthCount <= 0 then
        pcall(function()
            local pg = player:FindFirstChild("PlayerGui")
            local rbGui = pg and pg:FindFirstChild("Rebirth")
            if rbGui then
                for _, desc in ipairs(rbGui:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Text then
                        local num = desc.Text:match("Rebirth%s*#%s*(%d+)")
                        if num then
                            liveRebirthCount = tonumber(num)
                            return
                        end
                    end
                end
            end
        end)
    end

    -- 4. Jalur Atribut Player & Leaderstats
    if liveRebirthCount <= 0 then
        pcall(function()
            for _, attrName in ipairs({"Rebirth", "Rebirths", "RebirthCount", "PV_Rebirth"}) do
                local val = player:GetAttribute(attrName)
                if type(val) == "number" and val > 0 then
                    liveRebirthCount = val
                    return
                end
            end
            local ls = player:FindFirstChild("leaderstats")
            if ls then
                for _, name in ipairs({"Rebirth", "Rebirths", "RebirthCount"}) do
                    local rb = ls:FindFirstChild(name)
                    if rb and rb:IsA("ValueBase") and tonumber(rb.Value) then
                        local n = tonumber(rb.Value)
                        if n > 0 then
                            liveRebirthCount = n
                            return
                        end
                    end
                end
            end
        end)
    end

    return liveRebirthCount
end

local _detectedFormulaArm = nil -- nil=belum cek, "v1", "v2", "fallback"

local function getExactRebirthRequirement(rbCount)
    local count = tonumber(rbCount) or 0

    -- Lazy detection (SEKALI saja): deteksi formula arm via getloadedmodules
    -- Pola ini SAMA persis dengan getRebirthCount() jalur 2 yang sudah terbukti aman
    if _detectedFormulaArm == nil and type(getloadedmodules) == "function" then
        pcall(function()
            for _, m in ipairs(getloadedmodules()) do
                if m.Name == "RebirthExperiment" then
                    local exp = require(m) -- Module sudah loaded oleh game, instant return
                    if exp and type(exp.floorFor) == "function" then
                        -- Test: count=200 → V1 menghasilkan 47, V2 menghasilkan 48
                        local testResult = exp.floorFor(player, 200)
                        if type(testResult) == "number" then
                            _detectedFormulaArm = (testResult >= 48) and "v2" or "v1"
                            printLog("RebirthDetect", "Formula arm: " .. _detectedFormulaArm .. " (test=200→" .. tostring(testResult) .. ")")
                        end
                    end
                    break
                end
            end
        end)
        if not _detectedFormulaArm then
            _detectedFormulaArm = "fallback"
        end
    end

    local isVariant = (_detectedFormulaArm == "v2")
    if not isVariant then
        pcall(function()
            isVariant = (player:GetAttribute("RebirthFormulaArm") == "variant")
        end)
    end

    if isVariant then
        local v1 = math.log(count * 0.4 + 1) * 5 + 25
        local tail = math.log(math.max(0, count - 25) / 500 + 1) * 5
        return math.floor(v1 + tail + 0.5)
    else
        return math.floor(25 + 5 * math.log(1 + 0.4 * count) + 0.5)
    end
end

-- ==============================================================================
-- PENGECEKAN KANDANG (COOP) & TUBUH AYAM
-- ==============================================================================
local cachedCoopPosition = nil
local function getCoopPosition()
    if cachedCoopPosition then
        return cachedCoopPosition
    end

    local plotId = player:GetAttribute("Plot") or currentPlotId or 1

    -- 1. Model Coop di Workspace.Coops
    local coopsFolder = Workspace:FindFirstChild("Coops")
    local myCoop = coopsFolder and coopsFolder:FindFirstChild("Coop" .. tostring(plotId))
    if myCoop then
        local pos = nil
        pcall(function()
            pos = myCoop:GetPivot().Position
        end)
        if pos then
            cachedCoopPosition = pos
            return pos
        end
    end

    -- 2. Model Plot di Workspace.World.Plots atau Workspace.Plots
    local plots = (Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("Plots")) or Workspace:FindFirstChild("Plots")
    local myPlot = plots and plots:FindFirstChild("Plot" .. tostring(plotId))
    if myPlot then
        local pos = nil
        pcall(function()
            pos = myPlot:GetPivot().Position
        end)
        if pos then
            cachedCoopPosition = pos
            return pos
        end
    end

    -- 3. Model Recycler milik plot di Workspace.Recyclers
    local recyclers = Workspace:FindFirstChild("Recyclers")
    local myRec = recyclers and recyclers:FindFirstChild("Recycler" .. tostring(plotId))
    if myRec then
        local pos = nil
        pcall(function()
            pos = myRec:GetPivot().Position
        end)
        if pos then
            cachedCoopPosition = pos
            return pos
        end
    end

    -- 4. Model Incubator milik plot di Workspace.Incubators
    local incubators = Workspace:FindFirstChild("Incubators")
    local myInc = incubators and incubators:FindFirstChild("Incubator" .. tostring(plotId))
    if myInc then
        local pos = nil
        pcall(function()
            pos = myInc:GetPivot().Position
        end)
        if pos then
            cachedCoopPosition = pos
            return pos
        end
    end

    return nil
end

local function getFrontOfCoopPosition()
    -- 0. Titik Kustom yang disimpan pengguna secara manual via tombol UI
    if UpdateHub.customFrontCoopPos and typeof(UpdateHub.customFrontCoopPos) == "Vector3" then
        return UpdateHub.customFrontCoopPos
    end

    local plotId = player:GetAttribute("Plot") or currentPlotId or 1
    local coopBasePos = getCoopPosition()

    -- 1. Lokasi Spawn Resmi Roblox (player.RespawnLocation)
    local respawnLoc = nil
    pcall(function() respawnLoc = player.RespawnLocation end)
    if respawnLoc and respawnLoc:IsA("BasePart") then
        return respawnLoc.Position + Vector3.new(0, 3, 0)
    end

    -- 2. Posisi Awal Masuk Game / Respawn (Tempat Awal Kita Masuk Game Posisinya)
    if UpdateHub.initialSpawnPosition and typeof(UpdateHub.initialSpawnPosition) == "Vector3" then
        if not coopBasePos or (UpdateHub.initialSpawnPosition - coopBasePos).Magnitude < 150 then
            return UpdateHub.initialSpawnPosition + Vector3.new(0, 0.5, 0)
        end
    end

    -- 3. Cari SpawnLocation di dalam Plot atau Coop
    local plots = (Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("Plots")) or Workspace:FindFirstChild("Plots")
    local myPlot = plots and plots:FindFirstChild("Plot" .. tostring(plotId))
    if myPlot then
        for _, desc in ipairs(myPlot:GetDescendants()) do
            if desc:IsA("SpawnLocation") then
                return desc.Position + Vector3.new(0, 3, 0)
            end
        end
        for _, name in ipairs({"Spawn", "SpawnLocation", "PlayerSpawn", "SpawnPoint", "StartPoint", "Entrance", "Gate"}) do
            local found = myPlot:FindFirstChild(name, true)
            if found and found:IsA("BasePart") then
                return found.Position + Vector3.new(0, 3, 0)
            end
        end
    end

    local coopsFolder = Workspace:FindFirstChild("Coops")
    local myCoop = coopsFolder and coopsFolder:FindFirstChild("Coop" .. tostring(plotId))
    if myCoop then
        for _, desc in ipairs(myCoop:GetDescendants()) do
            if desc:IsA("SpawnLocation") then
                return desc.Position + Vector3.new(0, 3, 0)
            end
        end
        for _, name in ipairs({"Spawn", "SpawnLocation", "PlayerSpawn", "SpawnPoint", "StartPoint", "Entrance", "Gate"}) do
            local found = myCoop:FindFirstChild(name, true)
            if found and found:IsA("BasePart") then
                return found.Position + Vector3.new(0, 3, 0)
            end
        end
    end

    -- 4. Papan Nama Depan Base (PlotSigns) - Terletak persis di depan pintu masuk plot dari jalan utama
    local plotSigns = Workspace:FindFirstChild("PlotSigns")
    if plotSigns then
        local pName = player.Name:lower()
        local pDisplay = player.DisplayName:lower()
        for _, sign in ipairs(plotSigns:GetChildren()) do
            local sName = sign.Name:lower()
            if sName:find(tostring(plotId)) or sName:find(pName) or sName:find(pDisplay) then
                local sPart = (sign:IsA("BasePart") and sign) or sign:FindFirstChildWhichIsA("BasePart", true)
                if sPart then
                    return sPart.Position + Vector3.new(0, 3, 0)
                end
            end
        end
    end

    -- 5. Hitung Posisi Depan Coop Menghadap ke Jalan / Pusat Peta (Center of Map)
    -- Di Grow a Chicken Fighter, pintu depan coop selalu menghadap ke arah pusat arena (Vector3.new(0, 0, 0))
    if coopBasePos then
        local centerPos = Vector3.new(0, coopBasePos.Y, 0)
        local toCenter = (centerPos - coopBasePos)
        if toCenter.Magnitude > 1 then
            local frontDir = toCenter.Unit
            -- Maju 16 stud ke arah tengah peta (ke depan halaman kandang, BUKAN ke belakang)
            return coopBasePos + (frontDir * 16) + Vector3.new(0, 3, 0)
        end
    end

    -- 6. Pivot CFrame Forward Calculation
    local pivot = nil
    pcall(function() pivot = (myCoop and myCoop:GetPivot()) or (myPlot and myPlot:GetPivot()) end)
    if pivot then
        local toCenter = (Vector3.new(0, pivot.Position.Y, 0) - pivot.Position).Unit
        local lookDot = pivot.LookVector:Dot(toCenter)
        local forwardDir = (lookDot >= 0) and pivot.LookVector or (-pivot.LookVector)
        return pivot.Position + (forwardDir * 16) + Vector3.new(0, 3, 0)
    end

    return coopBasePos
end

local function getMyChickenBody()
    local chickenFolder = Workspace:FindFirstChild("ChickenBodies")
    if not chickenFolder then
        return nil
    end

    local plotId = player:GetAttribute("Plot") or currentPlotId or 1

    -- 1. Cek penamaan standar model plot: ChickenBody_coop:<plotId>
    local byName = chickenFolder:FindFirstChild("ChickenBody_coop:" .. tostring(plotId))
    if byName then
        return byName
    end

    -- 2. Cek atribut ovOwner (UserId pemain) atau Owner/owner (Username)
    local pUserId = player.UserId
    local pNameLower = string.lower(player.Name)
    for _, c in ipairs(chickenFolder:GetChildren()) do
        local ownerId = c:GetAttribute("ovOwner")
        if ownerId and tonumber(ownerId) == pUserId then
            return c
        end
        local ownerAttr = c:GetAttribute("Owner") or c:GetAttribute("owner")
        if ownerAttr and string.lower(tostring(ownerAttr)) == pNameLower then
            return c
        end
    end

    return nil
end

local function getChickenDistanceToCoop()
    local cBody = getMyChickenBody()
    if not cBody or not cBody.Parent then
        return nil, nil, nil
    end

    local cPos = nil
    pcall(function()
        if cBody:IsA("Model") then
            local pp = cBody.PrimaryPart
            cPos = (pp and pp.Position) or cBody:GetPivot().Position
        elseif cBody:IsA("BasePart") then
            cPos = cBody.Position
        end
    end)

    local coopPos = getCoopPosition()
    if cPos and coopPos then
        local dist = (Vector3.new(cPos.X, 0, cPos.Z) - Vector3.new(coopPos.X, 0, coopPos.Z)).Magnitude
        return dist, cPos, coopPos
    end

    return nil, cPos, coopPos
end

local function getChickenStatus()
    local status = {
        HpFrac = 1,
        IsAlive = true,
        IsFull = false,
        InBattle = false
    }
    pcall(function()
        local myChicken = getMyChickenBody()
        if myChicken then
            local ovLife = myChicken:GetAttribute("ovLife")
            if type(ovLife) == "boolean" then
                status.IsAlive = ovLife
            end

            local hpFrac = myChicken:GetAttribute("ovHpFrac")
            if type(hpFrac) == "number" then
                status.HpFrac = hpFrac
                status.IsFull = (hpFrac >= 0.99)
            end

            local ovState = myChicken:GetAttribute("ovState")
            if ovState and tostring(ovState):lower() == "battle" then
                status.InBattle = true
            end
        end
    end)
    return status
end

local function isChickenAtBase(strictCoopOnly)
    -- 1. Cek status pertempuran ayam: jika sedang bertarung di Tower / Arena
    local cStatus = getChickenStatus()
    if cStatus.InBattle then
        return false
    end

    -- 2. Cek jarak fisik tubuh ayam ke pusat Kandang (Coop)
    local distToCoop = getChickenDistanceToCoop()
    if distToCoop then
        if strictCoopOnly then
            -- Wajib benar-benar di dalam pagar kandang (Coop/Corral)
            return distToCoop <= 20
        else
            -- Berada di area Base / Plot pemain (sampai 55 stud dari pusat coop)
            return distToCoop <= 55
        end
    end

    -- 3. Jika posisi ayam belum bisa diukur, return false agar aman dan tidak memicu rebirth prematur
    return false
end

local function getRebirthRequirement()
    local myFloor = getCurrentFloor()
    local rbCount = getRebirthCount()
    local requiredFloor = getExactRebirthRequirement(rbCount)

    fastTargetFloor = requiredFloor
    cachedRequiredFloor = requiredFloor

    local isTowerMet = (myFloor >= requiredFloor and requiredFloor > 0 and myFloor > 0)

    local req = {
        Current = myFloor,
        Required = requiredFloor,
        IsReady = isTowerMet,
        DisplayStatus = "",
        RawText = ""
    }

    if req.IsReady then
        req.DisplayStatus = string.format("Floor %d / %d (READY!)", req.Current, req.Required)
    else
        local sisa = math.max(0, req.Required - req.Current)
        req.DisplayStatus = string.format("Floor %d / %d (Kurang %d Floor)", req.Current, req.Required, sisa)
    end

    return req
end

local function getRealBackpackCount(char)
    local count = 0
    pcall(function()
        local directScrap = player:GetAttribute("scrapCarry")
        if type(directScrap) == "number" then
            count = directScrap
            return
        end

        for attr, val in pairs(player:GetAttributes()) do
            if type(val) == "number" and (attr:lower():find("carry") or attr:lower():find("scrap") or attr:lower():find("coin")) then
                count = count + val
            end
        end
        if char then
            local physicalCount = 0
            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("BasePart") or obj:IsA("Model") then
                    if obj:GetAttribute("StackKind") or obj:GetAttribute("CarryAttr") then
                        physicalCount = physicalCount + 1
                    end
                end
            end
            if physicalCount > count then
                count = physicalCount
            end
        end
    end)
    return count
end

-- ==============================================================================
-- [7] PENGECEKAN STATUS LENGKAP AYAM (HP & KO)
-- ==============================================================================
local function isChickenHpFull()
    return getChickenStatus().IsFull
end

local function getCoopAndFeederStats()
    local curCoop = 1
    local feederLevels = {}
    local feederCount = 0

    pcall(function()
        local plotId = player:GetAttribute("Plot") or currentPlotId or 1
        local coopsFolder = Workspace:FindFirstChild("Coops")
        local myCoop = coopsFolder and coopsFolder:FindFirstChild("Coop" .. tostring(plotId))
        if myCoop then
            local pvSlots = myCoop:GetAttribute("PV_Slots")
            local parsedSlots = pvSlots and tonumber(pvSlots)
            if parsedSlots then
                curCoop = math.max(1, parsedSlots - 1)
            else
                for _, desc in ipairs(myCoop:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Name == "name" then
                        local txt = desc.Text or desc.ContentText or ""
                        if txt:find("COOP") then
                            local matchLvl = string.match(txt, "Lv%.%s*(%d+)")
                            local num = matchLvl and tonumber(matchLvl)
                            if num then
                                curCoop = num
                                break
                            end
                        end
                    end
                end
            end

            local feedersAttr = myCoop:GetAttribute("PV_Feeders")
            if feedersAttr and type(feedersAttr) == "string" then
                for entry in string.gmatch(feedersAttr, "[^|]+") do
                    local slotStr, lvlStr = string.match(entry, "(%d+):(%d+)")
                    if slotStr and lvlStr then
                        local sId = tonumber(slotStr)
                        local sLvl = tonumber(lvlStr)
                        if sId and sLvl then
                            feederLevels[sId] = sLvl
                            feederCount = feederCount + 1
                        end
                    end
                end
            end
        end
    end)

    return curCoop, feederLevels, feederCount
end

-- ==============================================================================
-- [9] PENCARIAN RECYCLER KHUSUS PEMAIN (DARI SCRIPT KERJA)
-- ==============================================================================
local cachedMyRecycler = nil
local function findMyRecycler()
    if cachedMyRecycler and cachedMyRecycler.Parent then
        return cachedMyRecycler
    end

    local success, result = pcall(function()
        local plotIdAttr = player:GetAttribute("Plot")
        local plotId = (type(plotIdAttr) == "number" and plotIdAttr) or 1
        local recyclersFolder = Workspace:FindFirstChild("Recyclers")

        if recyclersFolder then
            local myRec = recyclersFolder:FindFirstChild("Recycler" .. tostring(plotId))
            if myRec then
                local prompt = myRec:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and prompt.Parent and prompt.Parent:IsA("BasePart") then
                    cachedMyRecycler = prompt.Parent
                    return prompt.Parent
                end
                local touch = myRec:FindFirstChild("TouchInterest", true)
                if touch and touch.Parent and touch.Parent:IsA("BasePart") then
                    cachedMyRecycler = touch.Parent
                    return touch.Parent
                end
                if myRec:IsA("BasePart") then
                    cachedMyRecycler = myRec
                    return myRec
                end
                if myRec:IsA("Model") then
                    local target = myRec.PrimaryPart or myRec:FindFirstChildWhichIsA("BasePart", true) or myRec
                    cachedMyRecycler = target
                    return target
                end
            end
        end

        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            return nil
        end
        local closestRecycler, minDist = nil, math.huge

        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc:IsA("BasePart") and desc.Name:lower():find("recycler") then
                local dist = (desc.Position - hrp.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closestRecycler = desc
                end
            end
        end
        if closestRecycler then
            cachedMyRecycler = closestRecycler
        end
        return closestRecycler
    end)
    return success and result or nil
end

-- ==============================================================================
-- [10] SISTEM NOCLIP & MOVEMENT (DARI SCRIPT KERJA)
-- ==============================================================================
local noclipConnection = nil
local noclipPartsCache = {}
local function enableNoclip()
    if noclipConnection then
        return
    end
    pcall(function()
        local char = player.Character
        table.clear(noclipPartsCache)
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    table.insert(noclipPartsCache, part)
                end
            end
        end
        noclipConnection = RunService.Stepped:Connect(function()
            for i = 1, #noclipPartsCache do
                local part = noclipPartsCache[i]
                if part and part.Parent and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end)
    end)
end

local function disableNoclip()
    if noclipConnection then
        pcall(function()
            noclipConnection:Disconnect()
            noclipConnection = nil
            table.clear(noclipPartsCache)
        end)
    end
end

local function safeWalkTo(targetPos, stopDistance, checkCapacity)
    stopDistance = tonumber(stopDistance) or 3
    local char = player.Character
    if not char then
        return "ERROR"
    end
    local humanoid, hrp = char:FindFirstChild("Humanoid"), char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then
        return "ERROR"
    end

    enableNoclip()
    pcall(function()
        humanoid:MoveTo(targetPos)
    end)

    local initialDist = (Vector3.new(targetPos.X, 0, targetPos.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude
    local maxWait = math.clamp(initialDist / 8, 8, 25)
    local timeout = 0
    local lastPos = hrp.Position
    local stuckTimer = 0

    while timeout < maxWait do
        if not autoSweep then
            break
        end

        local okLoop, resLoop = pcall(function()
            local currentPos = hrp.Position
            local dist = (Vector3.new(currentPos.X, 0, currentPos.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude
            if dist <= stopDistance then
                return "STOP"
            end

            if checkCapacity and getRealBackpackCount(char) >= MAX_CAPACITY then
                disableNoclip()
                return "FULL"
            end

            stuckTimer = stuckTimer + 0.1
            if stuckTimer >= 0.5 then
                local moveDist = (Vector3.new(currentPos.X, 0, currentPos.Z) - Vector3.new(lastPos.X, 0, lastPos.Z)).Magnitude
                if moveDist < 1 then
                    local direction = (Vector3.new(targetPos.X, currentPos.Y, targetPos.Z) - currentPos).Unit
                    hrp.CFrame = hrp.CFrame + (direction * 4)
                    humanoid:MoveTo(targetPos)
                end
                lastPos = currentPos
                stuckTimer = 0
            end
            return "CONTINUE"
        end)

        if not okLoop or resLoop == "STOP" then
            break
        elseif resLoop == "FULL" then
            disableNoclip()
            return "FULL"
        end

        timeout = timeout + task.wait(0.1)
    end

    disableNoclip()

    local finalDist = (Vector3.new(targetPos.X, 0, targetPos.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude
    if finalDist <= stopDistance + 3 then
        return "ARRIVED"
    else
        return "TIMEOUT"
    end
end

-- ==============================================================================
-- [11] VISUAL ESP ENGINE (PLAYER, EGG, SCRAP)
-- ==============================================================================
local function cleanESP(tag)
    pcall(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                for _, desc in ipairs(p.Character:GetChildren()) do
                    if desc.Name == tag then desc:Destroy() end
                end
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local bb = hrp:FindFirstChild(tag)
                    if bb then bb:Destroy() end
                end
            end
        end
        local nestFolder = Workspace:FindFirstChild("NestEggs")
        if nestFolder then
            for _, egg in ipairs(nestFolder:GetChildren()) do
                local obj = egg:FindFirstChild(tag)
                if obj then obj:Destroy() end
            end
        end
        local pitFolder = Workspace:FindFirstChild("PitScrap") or (Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("PitScrap"))
        if pitFolder then
            for _, scrap in ipairs(pitFolder:GetChildren()) do
                local obj = scrap:FindFirstChild(tag)
                if obj then obj:Destroy() end
            end
        end
    end)
end

local function createESPBillboard(parent, text, color, offset, tag)
    local existing = parent:FindFirstChild(tag)
    if existing then
        local label = existing:FindFirstChildWhichIsA("TextLabel")
        if label then
            label.Text = text
        end
        return
    end

    local bb = Instance.new("BillboardGui")
    bb.Name = tag
    bb.Adornee = parent
    bb.Size = UDim2.new(0, 160, 0, 35)
    bb.StudsOffset = offset or Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 500

    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Text = text
    tl.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    tl.TextStrokeTransparency = 0
    tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = 13
    tl.Parent = bb

    bb.Parent = parent
end

local function createESPHighlight(parent, fillColor, outlineColor, tag)
    local existing = parent:FindFirstChild(tag)
    if existing and existing:IsA("Highlight") then
        return
    end

    local hl = Instance.new("Highlight")
    hl.Name = tag
    hl.Adornee = parent
    hl.FillColor = fillColor or Color3.fromRGB(0, 255, 120)
    hl.OutlineColor = outlineColor or Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.Parent = parent
end

-- ==============================================================================
-- [12] SCANNER FLOCK & FITUR AYAM (PROMOTE, FUSE, FAVORIT, SELL, NEST EGGS)
-- ==============================================================================
local function collectMyNestEggs(isManual)
    local collectedCount = 0
    pcall(function()
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local nestFolder = Workspace:FindFirstChild("NestEggs")
        if nestFolder and hrp then
            for _, egg in ipairs(nestFolder:GetChildren()) do
                if egg:IsA("BasePart") or egg:IsA("Model") then
                    local owner = egg:GetAttribute("owner")
                    if owner and tonumber(owner) == player.UserId then
                        local targetPart = egg:IsA("BasePart") and egg or (egg:FindFirstChildWhichIsA("BasePart") or egg.PrimaryPart)
                        if targetPart and firetouchinterest then
                            firetouchinterest(hrp, targetPart, 0)
                            task.wait(0.02)
                            firetouchinterest(hrp, targetPart, 1)
                            collectedCount = collectedCount + 1
                        end
                        local prompt = egg:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            pcall(function()
                                fireproximityprompt(prompt)
                            end)
                        end
                    end
                end
            end
        end
    end)
    return collectedCount
end

local scanFlockChickens = nil

local OFFICIAL_PROMOTE_REQUIREMENTS = {
    ["common"] = {
        [1] = 5, [2] = 10, [3] = 15, [4] = 25, [5] = 40,
        [6] = 60, [7] = 90, [8] = 120, [9] = 160, [10] = 220
    },
    ["uncommon"] = {
        [1] = 4, [2] = 8, [3] = 12, [4] = 20, [5] = 30,
        [6] = 45, [7] = 65, [8] = 90, [9] = 125, [10] = 170
    },
    ["rare"] = {
        [1] = 3, [2] = 5, [3] = 8, [4] = 12, [5] = 20,
        [6] = 30, [7] = 45, [8] = 65, [9] = 95, [10] = 130
    },
    ["epic"] = {
        [1] = 2, [2] = 4, [3] = 6, [4] = 8, [5] = 20,
        [6] = 25, [7] = 35, [8] = 50, [9] = 75, [10] = 100
    },
    ["legendary"] = {
        [1] = 2, [2] = 3, [3] = 5, [4] = 10, [5] = 15,
        [6] = 20, [7] = 30, [8] = 40, [9] = 55, [10] = 75
    },
    ["mythic"] = {
        [1] = 1, [2] = 2, [3] = 3, [4] = 5, [5] = 8,
        [6] = 12, [7] = 20, [8] = 30, [9] = 40, [10] = 55
    },
    ["divine"] = {
        [1] = 1, [2] = 2, [3] = 3, [4] = 5, [5] = 8,
        [6] = 12, [7] = 18, [8] = 25, [9] = 35, [10] = 50
    },
    ["celestial"] = {
        [1] = 1, [2] = 2, [3] = 3, [4] = 4, [5] = 6,
        [6] = 10, [7] = 15, [8] = 20, [9] = 30, [10] = 40
    },
    ["cosmic"] = {
        [1] = 1, [2] = 1, [3] = 2, [4] = 3, [5] = 5,
        [6] = 8, [7] = 12, [8] = 18, [9] = 25, [10] = 35
    },
    ["secret"] = {
        [1] = 1, [2] = 1, [3] = 2, [4] = 2, [5] = 3,
        [6] = 5, [7] = 7, [8] = 10, [9] = 14, [10] = 20
    }
}

local function getRequiredFodders(rarity, currentStars)
    local cur = currentStars or 0
    local nextStar = cur + 1
    if nextStar > 10 then
        nextStar = 10
    end

    -- 1. Panggil langsung fungsi resmi PromotionView dari game jika tersedia
    local dynamicReq = nil
    pcall(function()
        local featChicken = ReplicatedStorage:FindFirstChild("Features") and ReplicatedStorage.Features:FindFirstChild("Chicken")
        local viewMod = featChicken and featChicken:FindFirstChild("PromotionView")
        if viewMod then
            local PromotionView = require(viewMod)
            if PromotionView and PromotionView.requirement then
                local rName = tostring(rarity or "common"):lower()
                local res = PromotionView.requirement(rName, nextStar)
                if type(res) == "number" and res > 0 then
                    dynamicReq = res
                end
            end
        end
    end)
    if dynamicReq then
        return dynamicReq, nextStar
    end

    -- 2. Fallback menggunakan tabel resmi hasil ekstraksi data game
    local rLower = tostring(rarity or "common"):lower()
    local rTable = OFFICIAL_PROMOTE_REQUIREMENTS[rLower] or OFFICIAL_PROMOTE_REQUIREMENTS["common"]
    local req = rTable[nextStar] or rTable[#rTable] or 5
    return req, nextStar
end

local function scanGamePromoteData()
    local results = {}
    local function logLine(s)
        table.insert(results, s)
        print(s)
    end
    logLine("==================================================================")
    logLine("  SYSHUB: SCANNER PERSYARATAN PROMOTE & RARITY ASLI DARI GAME     ")
    logLine("==================================================================")
    logLine("Waktu: " .. os.date("%Y-%m-%d %H:%M:%S"))
    logLine("Player: " .. player.Name)
    logLine("")

    -- 1. Scan ModuleScripts di ReplicatedStorage & PlayerScripts
    local keywords = {"promote", "sacrifice", "chicken", "flock", "rarit", "fuse", "require", "tuning", "config", "setting", "tier", "grade", "star"}
    local candidateModules = {}
    for _, root in ipairs({ReplicatedStorage, player:FindFirstChild("PlayerScripts"), game:GetService("StarterPlayer")}) do
        if root then
            for _, desc in ipairs(root:GetDescendants()) do
                if desc:IsA("ModuleScript") then
                    local dName = desc.Name:lower()
                    for _, kw in ipairs(keywords) do
                        if dName:find(kw) then
                            table.insert(candidateModules, desc)
                            break
                        end
                    end
                end
            end
        end
    end

    logLine(string.format("Memeriksa %d ModuleScript yang relevan...", #candidateModules))
    for _, mod in ipairs(candidateModules) do
        pcall(function()
            local res = require(mod)
            if type(res) == "table" then
                local hasMatch = false
                for k, v in pairs(res) do
                    local kStr = tostring(k):lower()
                    if kStr:find("promote") or kStr:find("sacrifice") or kStr:find("requirement") or kStr:find("common") or kStr:find("legendary") or kStr:find("rarit") or kStr:find("star") then
                        hasMatch = true
                        break
                    end
                end
                if hasMatch then
                    logLine("\n[MODUL TERKAIT]: " .. mod:GetFullName())
                    for k, v in pairs(res) do
                        if type(v) == "table" then
                            logLine("  [" .. tostring(k) .. "] = {")
                            local c = 0
                            for subK, subV in pairs(v) do
                                c = c + 1
                                if c > 30 then
                                    logLine("    ... (dipotong)")
                                    break
                                end
                                logLine("    [" .. tostring(subK) .. "] = " .. tostring(subV) .. " (" .. typeof(subV) .. ")")
                            end
                            logLine("  }")
                        else
                            logLine("  [" .. tostring(k) .. "] = " .. tostring(v) .. " (" .. typeof(v) .. ")")
                        end
                    end
                end
            end
        end)
    end

    -- 2. Scan UI TextLabels
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        for _, desc in ipairs(playerGui:GetDescendants()) do
            local dName = desc.Name:lower()
            if dName:find("sacrifice") or dName:find("promote") or dName:find("requirement") then
                if desc:IsA("TextLabel") and desc.Text and #desc.Text > 0 then
                    logLine(string.format("UI Text [%s]: \"%s\"", desc:GetFullName(), desc.Text))
                end
                local attrs = desc:GetAttributes()
                for k, v in pairs(attrs) do
                    logLine(string.format("UI Attr [%s].[%s] = %s", desc.Name, tostring(k), tostring(v)))
                end
            end
        end
    end

    local fullText = table.concat(results, "\n")
    local copied = false
    pcall(function()
        if setclipboard then
            setclipboard(fullText)
            copied = true
        elseif toclipboard then
            toclipboard(fullText)
            copied = true
        end
    end)
    pcall(function()
        if writefile then
            writefile("promote_data.txt", fullText)
        end
    end)
    return copied, fullText
end

local KNOWN_SPECIES_RARITY = {
    ["CLASSIC ROOSTER"] = "Common",
    ["FARMER ROOSTER"] = "Common",
    ["SCRATCH HEN"] = "Common",
    ["BARN ROOSTER"] = "Common",
    ["BROWN HEN"] = "Common",
    ["WHITE HEN"] = "Common",
    ["CHICKEN"] = "Common",
    ["ROOSTER"] = "Common",
    ["FARMED ROOSTER"] = "Uncommon",
    ["SPOTTED ROOSTER"] = "Uncommon",
    ["GREEN ROOSTER"] = "Uncommon",
    ["FOREST CHICKEN"] = "Uncommon",
    ["DESERT ROOSTER"] = "Uncommon",
    ["404 CHICK"] = "Rare",
    ["PIRATE ROOSTER"] = "Rare",
    ["GOLDEN GOOSE"] = "Legendary",
    ["GOOSE"] = "Legendary",
    ["FOUNDER ROOSTER"] = "Legendary",
    ["FOUNDER"] = "Legendary",
    ["SOVEREIGN ROOSTER"] = "Legendary",
    ["DEVIL CHICKEN"] = "Mythic",
    ["ANGEL CHICKEN"] = "Divine",
    ["NEBULA HEN"] = "Celestial",
    ["COSMIC ROOSTER"] = "Cosmic",
    ["STORM COLOSSUS"] = "Secret",
    ["COLOSSUS"] = "Secret",
    ["JONTOR"] = "Secret",
}

local function evaluateColorRarity(col)
    if not col then
        return nil
    end
    -- Abaikan warna putih terang, abu-abu netral, dan hitam pekat
    if (col.R > 0.95 and col.G > 0.95 and col.B > 0.95) or (col.R < 0.12 and col.G < 0.12 and col.B < 0.12) then
        return nil
    end

    -- 1. Legendary: Emas / Kuning Oranye (R tinggi, G sedang-tinggi, B rendah)
    -- Contoh Founder Rooster latar kartu emas: R ≈ 0.7-0.95, G ≈ 0.45-0.75, B < 0.35
    if col.R > 0.6 and col.G > 0.38 and col.B < 0.35 and (col.R > col.B * 1.8) then
        return "Legendary"
    -- 2. Epic: Ungu / Magenta (R tinggi, B tinggi, G rendah)
    elseif col.R > 0.35 and col.B > 0.35 and col.G < 0.3 and (col.R > col.G * 1.3 or col.B > col.G * 1.3) then
        return "Epic"
    -- 3. Rare: Biru (B tinggi, B > R, B > G)
    elseif col.B > 0.4 and col.B > col.R * 1.25 and col.B > col.G * 1.1 then
        return "Rare"
    -- 4. Uncommon: Hijau (G tinggi, G > R, G > B)
    elseif col.G > 0.35 and col.G > col.R * 1.25 and col.G > col.B * 1.25 then
        return "Uncommon"
    -- 5. Mythic: Merah Pekat (R tinggi, G & B sangat rendah)
    elseif col.R > 0.6 and col.G < 0.3 and col.B < 0.3 then
        return "Mythic"
    end
    return nil
end

local catalogPreloaded = false
local function preloadGameChickenCatalog()
    if catalogPreloaded then
        return
    end
    catalogPreloaded = true
    pcall(function()
        local contentFolder = ReplicatedStorage:FindFirstChild("Content")
        local catMod = contentFolder and contentFolder:FindFirstChild("Catalog")
        if catMod then
            local cat = require(catMod)
            if type(cat) == "table" then
                for _, section in pairs(cat) do
                    if type(section) == "table" then
                        for id, item in pairs(section) do
                            if type(item) == "table" then
                                local r = item.rarity or item.Rarity or item.tier or item.Tier
                                local n = item.name or item.Name or (type(id) == "string" and id)
                                if r and n and type(r) == "string" and type(n) == "string" then
                                    local properR = r:sub(1,1):upper() .. r:sub(2):lower()
                                    KNOWN_SPECIES_RARITY[n:upper()] = properR
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    pcall(function()
        local featChicken = ReplicatedStorage:FindFirstChild("Features") and ReplicatedStorage.Features:FindFirstChild("Chicken")
        if featChicken then
            for _, mod in ipairs(featChicken:GetDescendants()) do
                if mod:IsA("ModuleScript") and mod.Name ~= "PromotionView" and mod.Name ~= "FusionRules" then
                    pcall(function()
                        local data = require(mod)
                        if type(data) == "table" then
                            for id, item in pairs(data) do
                                if type(item) == "table" then
                                    local r = item.rarity or item.Rarity or item.tier or item.Tier
                                    local n = item.name or item.Name or (type(id) == "string" and id)
                                    if r and n and type(r) == "string" and type(n) == "string" then
                                        local properR = r:sub(1,1):upper() .. r:sub(2):lower()
                                        KNOWN_SPECIES_RARITY[n:upper()] = properR
                                    end
                                end
                            end
                        end
                    end)
                end
            end
        end
    end)
end

local function detectChickenRarity(frame, chickenName)
    preloadGameChickenCatalog()
    local upName = chickenName and chickenName:upper():gsub("^%s*(.-)%s*$", "%1")

    -- 1. Cek dari kamus spesies yang sudah terverifikasi
    if upName then
        if KNOWN_SPECIES_RARITY[upName] then
            return KNOWN_SPECIES_RARITY[upName]
        end
        for k, r in pairs(KNOWN_SPECIES_RARITY) do
            if upName:find(k) then
                return r
            end
        end
    end
    -- 2. Cek frame (Dioptimasi: Tanpa scanning seluruh PlayerGui agar 0ms & anti-freeze)
    if not frame then
        return "Unknown"
    end

    -- 3. Cek atribut pada frame
    for _, attrName in ipairs({"rarity", "Rarity", "tier", "Tier", "grade", "Grade"}) do
        local val = frame:GetAttribute(attrName)
        if val and type(val) == "string" then
            local vLower = val:lower()
            if vLower:find("secret") then
                return "Secret"
            elseif vLower:find("cosmic") then
                return "Cosmic"
            elseif vLower:find("celestial") then
                return "Celestial"
            elseif vLower:find("divine") then
                return "Divine"
            elseif vLower:find("mythic") then
                return "Mythic"
            elseif vLower:find("legend") then
                return "Legendary"
            elseif vLower:find("epic") then
                return "Epic"
            elseif vLower:find("rare") then
                return "Rare"
            elseif vLower:find("uncommon") then
                return "Uncommon"
            elseif vLower:find("common") then
                return "Common"
            end
        end
    end

    -- 4. Cek teks label di dalam kartu
    for _, child in ipairs(frame:GetDescendants()) do
        if child:IsA("TextLabel") then
            local txt = (child.Text or ""):lower():gsub("^%s*(.-)%s*$", "%1")
            if txt == "secret" then
                return "Secret"
            elseif txt == "cosmic" then
                return "Cosmic"
            elseif txt == "celestial" then
                return "Celestial"
            elseif txt == "divine" then
                return "Divine"
            elseif txt == "mythic" then
                return "Mythic"
            elseif txt == "legendary" then
                return "Legendary"
            elseif txt == "epic" then
                return "Epic"
            elseif txt == "rare" then
                return "Rare"
            elseif txt == "uncommon" then
                return "Uncommon"
            elseif txt == "common" then
                return "Common"
            end
        end
    end

    -- 5. Deteksi Warna Visual Kartu (UIGradient, ImageColor3, BackgroundColor3)
    for _, child in ipairs(frame:GetDescendants()) do
        if child:IsA("UIGradient") then
            local keypoints = child.Color and child.Color.Keypoints
            if keypoints and #keypoints > 0 then
                for _, kp in ipairs(keypoints) do
                    local r = evaluateColorRarity(kp.Value)
                    if r then
                        if upName then
                            KNOWN_SPECIES_RARITY[upName] = r
                        end
                        return r
                    end
                end
            end
        end

        if (child:IsA("ImageLabel") or child:IsA("ImageButton")) and child.Visible ~= false then
            local trans = child.ImageTransparency or 0
            if trans < 0.75 then
                local r = evaluateColorRarity(child.ImageColor3)
                if r then
                    if upName then
                        KNOWN_SPECIES_RARITY[upName] = r
                    end
                    return r
                end
            end
        end

        if child:IsA("GuiObject") and child.Visible ~= false then
            local trans = child.BackgroundTransparency or 0
            if trans < 0.75 then
                local r = evaluateColorRarity(child.BackgroundColor3)
                if r then
                    if upName then
                        KNOWN_SPECIES_RARITY[upName] = r
                    end
                    return r
                end
            end
        end
    end

    local fName = frame.Name:upper()
    if KNOWN_SPECIES_RARITY[fName] then
        return KNOWN_SPECIES_RARITY[fName]
    end

    return "Unknown"
end

local function getChickenStarCount(frame, cId, numId)
    if not frame then
        return 0
    end
    local stars = 0

    -- 1. Cek PromotionView.stars jika tersedia secara internal di game
    pcall(function()
        local featChicken = ReplicatedStorage:FindFirstChild("Features") and ReplicatedStorage.Features:FindFirstChild("Chicken")
        local viewMod = featChicken and featChicken:FindFirstChild("PromotionView")
        if viewMod then
            local PromotionView = require(viewMod)
            if PromotionView and type(PromotionView.stars) == "function" then
                local s = PromotionView.stars(frame) or (numId and PromotionView.stars(numId)) or (cId and PromotionView.stars(cId))
                if type(s) == "number" and s > 0 and s <= 10 then
                    stars = math.max(stars, s)
                end
            end
        end
    end)

    -- 2. Cek atribut angka pada frame kartu dan wadah bintang
    for _, obj in ipairs({frame, frame:FindFirstChild("Stars"), frame:FindFirstChild("Content")}) do
        if obj then
            for _, attr in ipairs({"Star", "Stars", "star", "stars", "Promotion", "Promotions", "Rank", "StarCount"}) do
                local val = obj:GetAttribute(attr)
                if val ~= nil and type(val) == "number" and val > 0 and val <= 10 then
                    stars = math.max(stars, val)
                end
            end
        end
    end

    -- 3. Hitung jumlah bintang visual yang menyala aktif pada kartu
    local visualStars = 0
    for _, desc in ipairs(frame:GetDescendants()) do
        if desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
            local dName = desc.Name:lower()
            local pName = desc.Parent and desc.Parent.Name:lower() or ""
            local img = tostring(desc.Image or ""):lower()
            local isStarAsset = (dName:find("star") or pName:find("star") or img:find("85144809432918") or img:find("129382203646873"))

            if isStarAsset and desc.Visible ~= false then
                local trans = desc.ImageTransparency or 0
                local col = desc.ImageColor3
                if trans < 0.6 and col then
                    -- Bintang kosong selalu GELAP PEKAT / HITAM (brightness < 0.28)
                    -- Bintang aktif (emas / kuning / putih / ungu) selalu TERANG (brightness >= 0.28)
                    local brightness = (col.R + col.G + col.B) / 3
                    local isDarkBlack = (col.R < 0.28 and col.G < 0.28 and col.B < 0.28)

                    if not isDarkBlack and brightness >= 0.28 then
                        visualStars = visualStars + 1
                    end
                end
            end
        end

        if desc:IsA("TextLabel") and desc.Text and desc.Text ~= "" then
            local txt = desc.Text
            local count = 0
            for _ in txt:gmatch("★") do
                count = count + 1
            end
            for _ in txt:gmatch("⭐") do
                count = count + 1
            end
            if count > visualStars then
                visualStars = count
            end
        end
    end

    if visualStars > stars then
        stars = visualStars
    end

    return stars
end

local function isChickenPromoted(frame, cId, numId)
    if cId and promotedChickenIds[cId] then
        return true
    end
    if numId and promotedChickenIds[numId] then
        return true
    end
    return getChickenStarCount(frame, cId, numId) > 0
end

local formatSpeciesName = nil
local cachedDataServiceClient = nil
local function getSharedDataServiceClient()
    if cachedDataServiceClient then
        return cachedDataServiceClient
    end
    pcall(function()
        local dsMod = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("DataService")
        if dsMod then
            local ok, ds = pcall(function() return require(dsMod) end)
            if ok and ds and type(ds) == "table" and ds.client then
                cachedDataServiceClient = ds.client
            end
        end
    end)
    return cachedDataServiceClient
end

local isScanFlockScheduled = false
local function requestFlockScan(delaySec)
    local d = delaySec or 0.8
    if isScanFlockScheduled then
        return
    end
    isScanFlockScheduled = true
    task.delay(d, function()
        isScanFlockScheduled = false
        pcall(function()
            if scanFlockChickens then
                scanFlockChickens()
            end
        end)
    end)
end

local function executeSellChickens(isManual)
    local toSellList = {}
    local processedFromDs = false

    -- [ENGINE 1: PRIORITAS TERTINGGI] Deteksi instan via DataService memory (0.001ms, 60 FPS mulus tanpa freeze)
    pcall(function()
        local dsClient = getSharedDataServiceClient()
        local raw = dsClient and dsClient._data and dsClient._data._data
        if raw and raw.roster and raw.roster.chickens and type(raw.roster.chickens) == "table" then
            processedFromDs = true
            for k, ch in pairs(raw.roster.chickens) do
                if type(ch) == "table" then
                    local cId = tostring(ch.id or k)
                    local numId = tonumber(string.match(cId, "%d+"))

                    -- 1. Proteksi Favorit
                    local isFav = (ch.favorite == true) or favoritedChickenIds[cId] or (numId and favoritedChickenIds[numId])

                    -- 2. Proteksi Promoted / Bintang (Stars > 0)
                    local stars = tonumber(ch.promo) or 0
                    local isProm = (stars > 0) or promotedChickenIds[cId] or (numId and promotedChickenIds[numId])

                    -- 3. Proteksi Mutasi Mutlak (Jurassic, Inverted, dan mutasi lainnya 100% AMAN!)
                    local hasMutation = false
                    if ch.mutation then
                        local m = type(ch.mutation) == "string" and ch.mutation or (type(ch.mutation) == "table" and ch.mutation.name)
                        if m and tostring(m):lower() ~= "none" and tostring(m) ~= "" then
                            hasMutation = true
                        end
                    end

                    -- 4. Proteksi Level Maksimal (sellMaxLevelProtection)
                    local chLevel = tonumber(ch.level) or 1
                    local isLvlProtected = (chLevel > sellMaxLevelProtection)

                    -- Hanya masukkan ke daftar jual jika lolos SEMUA proteksi
                    if not isFav and not isProm and not hasMutation and not isLvlProtected then
                        local rarity = nil
                        if ch.rarity and type(ch.rarity) == "string" and ch.rarity ~= "" and ch.rarity:lower() ~= "unknown" then
                            rarity = ch.rarity:sub(1, 1):upper() .. ch.rarity:sub(2):lower()
                        end
                        if not rarity then
                            local spName = (formatSpeciesName and formatSpeciesName(ch.typeId)) or tostring(ch.typeId or "Chicken")
                            rarity = detectChickenRarity(nil, spName)
                        end

                        if rarity and rarity ~= "Unknown" and selectedSellRarities[rarity] == true then
                            table.insert(toSellList, {
                                idStr = cId,
                                idNum = numId,
                                name = (formatSpeciesName and formatSpeciesName(ch.typeId)) or tostring(ch.typeId or cId),
                                rarity = rarity
                            })
                        end
                    end
                end
            end
        end
    end)

    -- [ENGINE 2: FALLBACK GUI] Hanya aktif jika DataService belum termuat di memori
    if not processedFromDs and #toSellList == 0 then
        pcall(function()
            local playerGui = player:FindFirstChild("PlayerGui")
            if not playerGui then return end

            for _, desc in ipairs(playerGui:GetDescendants()) do
                local matchNum = string.match(desc.Name, "^c(%d+)$")
                if matchNum and (desc:IsA("Frame") or desc:IsA("GuiObject") or desc:IsA("TextButton")) then
                    local cId = desc.Name
                    local numId = tonumber(matchNum)

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

                    local isFav = favoritedChickenIds[cId] or (numId and favoritedChickenIds[numId]) or desc:GetAttribute("Favorite") == true or desc:FindFirstChild("Favorite")
                    local isPromoted = isChickenPromoted(desc, cId, numId)

                    local hasMutation = false
                    local attrMut = desc:GetAttribute("Mutation") or desc:GetAttribute("ovMutation") or desc:GetAttribute("mutation")
                    if attrMut and tostring(attrMut):lower() ~= "none" and tostring(attrMut) ~= "" then
                        hasMutation = true
                    end

                    if not isFav and not isPromoted and not hasMutation then
                        local rarity = detectChickenRarity(desc, cName)
                        if rarity and rarity ~= "Unknown" and selectedSellRarities[rarity] == true then
                            table.insert(toSellList, {
                                idStr = cId,
                                idNum = numId,
                                name = cName or cId,
                                rarity = rarity
                            })
                        end
                    end
                end
            end
        end)
    end

    local soldCount = #toSellList
    if soldCount > 0 then
        local allStrIds = {}
        local allNumIds = {}
        for _, item in ipairs(toSellList) do
            table.insert(allStrIds, item.idStr)
            if item.idNum then
                table.insert(allNumIds, item.idNum)
            end
        end

        -- Jual secara bulk (1 remote call atomic, instant tanpa freeze)
        task.spawn(function()
            pcall(function()
                invokeRemote("SellChickens", allStrIds)
            end)
            if #allNumIds > 0 then
                pcall(function()
                    invokeRemote("SellChickens", allNumIds)
                end)
            end

            -- Update UI dropdowns secara halus & ter-debounce di background
            requestFlockScan(0.8)
        end)
    end
    return soldCount
end
local function extractChickenSkill(frame)
    if not frame then
        return nil
    end
    for _, attr in ipairs({"Skill", "skill", "Ability", "ability", "Special", "special"}) do
        local val = frame:GetAttribute(attr)
        if val and type(val) == "string" and val ~= "" then
            return val:gsub("^%s*(.-)%s*$", "%1")
        end
    end
    for _, child in ipairs(frame:GetDescendants()) do
        if child:IsA("TextLabel") and child.Text and child.Text ~= "" then
            local raw = child.Text:gsub("^%s*(.-)%s*$", "%1")
            local lower = raw:lower()
            if child.Name:lower():find("skill") or child.Name:lower():find("ability") then
                local clean = raw:gsub("^[Ss][Kk][Ii][Ll][Ll]%s*:?%s*", "")
                if clean ~= "" and clean:lower() ~= "skill" and #clean > 2 then
                    return clean
                end
            end
            if lower:find("^skill%s*:") or lower:find("^ability%s*:") then
                local clean = raw:gsub("^[Ss][Kk][Ii][Ll][Ll]%s*:?%s*", ""):gsub("^[Aa][Bb][Ii][Ll][Ii][Tt][Yy]%s*:?%s*", "")
                if clean ~= "" and #clean > 2 then
                    return clean
                end
            end
        end
    end
    return nil
end

local function getSkillFromInspector()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then
        return nil
    end
    for _, lbl in ipairs(playerGui:GetDescendants()) do
        if lbl:IsA("TextLabel") and lbl.Text and lbl.Text ~= "" then
            local raw = lbl.Text:gsub("^%s*(.-)%s*$", "%1")
            local lower = raw:lower()
            if lbl.Name:lower() == "skill" or lbl.Name:lower() == "skillname" or lower:find("^skill%s*:") then
                local s = raw:gsub("^[Ss][Kk][Ii][Ll][Ll]%s*:?%s*", "")
                if s ~= "" and s:lower() ~= "skill" and #s > 2 then
                    return s
                end
            end
        end
    end
    return nil
end

local updateAvailableSkills = nil
local updatePromoteFodders = nil

-- [getSharedDataServiceClient sudah didefinisikan di baris 2082]

local CHICKEN_NAME_BY_TYPE_ID = {
    ["ace_rooster"] = "Ace Rooster",
    ["agent_cluck"] = "Agent Cluck",
    ["alien_chick"] = "Alien Chick",
    ["angel_chicken"] = "Angel Chicken",
    ["astro_chick"] = "Astro Chick",
    ["aurora_hen"] = "Aurora Hen",
    ["ballet_hen"] = "Ballet Hen",
    ["banner_hen"] = "Banner Hen",
    ["barcelos"] = "Barcelos",
    ["barista_hen"] = "Barista Hen",
    ["baron"] = "Baron Cluck",
    ["basilisk"] = "Basilisk Rooster",
    ["beacon_rooster"] = "Beacon Rooster",
    ["beast_rooster"] = "Beast Rooster",
    ["blitz_rooster"] = "Blitz Rooster",
    ["boba_hen"] = "Boba Hen",
    ["bombardier"] = "Bombardier Rooster",
    ["bone_rooster"] = "Bone Rooster",
    ["bonk_hen"] = "Bonk Hen",
    ["boom_rooster"] = "Boom Rooster",
    ["bow_chick"] = "Bow Chick",
    ["boxer_hen"] = "Southpaw Hen",
    ["bravo_rooster"] = "Bravo Rooster",
    ["bucket_rooster"] = "Bucket Rooster",
    ["bulwark_hen"] = "Bulwark Hen",
    ["bunker_hen"] = "Bunker Hen",
    ["butterfly_hen"] = "Butterfly Hen",
    ["caddie_rooster"] = "Caddie Rooster",
    ["capoeira"] = "Capoeira Rooster",
    ["catalyst_hen"] = "Catalyst Hen",
    ["chameleon_hen"] = "Chameleon Hen",
    ["champ_rooster"] = "Belt Champion",
    ["checkmate_hen"] = "Checkmate Hen",
    ["cheer_chick"] = "Cheer Chick",
    ["chef_rooster"] = "Chef Rooster",
    ["classic"] = "Classic Rooster",
    ["clown_chick"] = "Clown Chick",
    ["cockatrice"] = "Cockatrice",
    ["comet_rooster"] = "Comet Rooster",
    ["commando_rooster"] = "Commando Rooster",
    ["cosmo_brat"] = "Cosmo Brat",
    ["crest_rooster"] = "Crest Rooster",
    ["crusader"] = "Bulwark Knight",
    ["crystal_hen"] = "Crystal Hen",
    ["cupcake_chick"] = "Cupcake Chick",
    ["deepfried_hen"] = "Deep Fried Hen",
    ["devil_chicken"] = "Devil Chicken",
    ["dj_rooster"] = "DJ Rooster",
    ["doll_hen"] = "Doll Hen",
    ["domino_chick"] = "Domino Chick",
    ["drone_hen"] = "Drone Hen",
    ["duelist_rooster"] = "Duelist Rooster",
    ["eclipse_hen"] = "Eclipse Hen",
    ["eel_hen"] = "Eel Hen",
    ["error_chick"] = "Error Chick",
    ["fairy_hen"] = "Fairy Hen",
    ["farmer_rooster"] = "Farmer Rooster",
    ["fenghuang"] = "Radiant Fenghuang",
    ["fine_rooster"] = "Fine Rooster",
    ["flame_rooster"] = "Flame Rooster",
    ["founder_rooster"] = "Founder Rooster",
    ["frost_hen"] = "Frostbite Hen",
    ["ghost_hen"] = "Ghost Hen",
    ["glam_hen"] = "Glam Hen",
    ["golden_goose"] = "Golden Goose",
    ["grandmaster_rooster"] = "Grandmaster Rooster",
    ["hacker_hen"] = "Hacker Hen",
    ["halo_hen"] = "Halo Hen",
    ["heart_hen"] = "Heart Hen",
    ["hex_rooster"] = "Hex Rooster",
    ["high_roller_rooster"] = "High Roller Rooster",
    ["hive_rooster"] = "Hive Rooster",
    ["idol_hen"] = "Idol Hen",
    ["impostor_chick"] = "Impostor Chick",
    ["ironcluck"] = "Ironcluck",
    ["jack_rooster"] = "Jack Rooster",
    ["jackal_rooster"] = "Jackal Rooster",
    ["janitor_rooster"] = "Janitor Rooster",
    ["karaoke_rooster"] = "Karaoke Rooster",
    ["kitsune_hen"] = "Nine-Tail Hen",
    ["kitty_chick"] = "Kitty Chick",
    ["laser_rooster"] = "Laser Rooster",
    ["loco_rooster"] = "Loco Rooster",
    ["luchador"] = "Luchador",
    ["magma_cock"] = "Magma Rooster",
    ["magnet_hen"] = "Magnet Hen",
    ["mantis_hen"] = "Mantis Hen",
    ["mecha_rooster"] = "Mecha Rooster",
    ["medic_hen"] = "Medic Hen",
    ["mercy_hen"] = "Mercy Hen",
    ["mermaid_hen"] = "Mermaid Hen",
    ["mime_hen"] = "Mime Hen",
    ["moai_rooster"] = "Stone Face",
    ["moon_hen"] = "Moonwalk Hen",
    ["mummy_hen"] = "Mummy Hen",
    ["nail_hen"] = "Manicure Hen",
    ["nano_rooster"] = "Nano Rooster",
    ["nebula_hen"] = "Nebula Hen",
    ["ninja_rooster"] = "Shadow Ninja",
    ["npc_chick"] = "NPC Chick",
    ["nugget_chick"] = "Nugget Chick",
    ["oracle_chick"] = "Oracle Chick",
    ["overclock"] = "Overclock Rooster",
    ["pact_hen"] = "Pact Hen",
    ["pastel_goth"] = "Pastel Goth",
    ["phoenix_hen"] = "Phoenix Hen",
    ["pizza_rooster"] = "Pizza Rooster",
    ["plumber_hen"] = "Plumber Hen",
    ["plush_chick"] = "Plush Chick",
    ["prism_rooster"] = "Prism Rooster",
    ["probe_rooster"] = "Probe Rooster",
    ["puck_rooster"] = "Enforcer Rooster",
    ["pufferhen"] = "Pufferhen",
    ["puzzle_hen"] = "Puzzle Hen",
    ["quake_rooster"] = "Quake Rooster",
    ["reaper_rooster"] = "Reaper Rooster",
    ["reek_rooster"] = "Reek Rooster",
    ["riot_hen"] = "Riot Hen",
    ["ronin_hen"] = "Ronin Hen",
    ["rumble_rooster"] = "Rumble Rooster",
    ["sapper_hen"] = "Sapper Hen",
    ["satellite_hen"] = "Orbital Hen",
    ["seraph_rooster"] = "Seraph Rooster",
    ["sergeant_hen"] = "Sergeant Hen",
    ["shadow_rooster"] = "Shadow Rooster",
    ["shark_chicken"] = "Shark Chicken",
    ["shockwave_hen"] = "Shockwave Hen",
    ["sigma_rooster"] = "Sigma Rooster",
    ["singular"] = "Singularity Hen",
    ["sirocco"] = "Sandstorm Rooster",
    ["skater_chick"] = "Skater Chick",
    ["skyscrest_rooster"] = "Skyscrest Rooster",
    ["slugger_hen"] = "Slugger Hen",
    ["snapper"] = "Snapper",
    ["sniper_rooster"] = "Sniper Rooster",
    ["solar_rooster"] = "Solar Rooster",
    ["sovereign_rooster"] = "Sovereign Rooster",
    ["spa_hen"] = "Spa Hen",
    ["sparkbeak"] = "Static Chick",
    ["spider_chicken"] = "Spider Chicken",
    ["squire_chick"] = "Squire Chick",
    ["stonks_hen"] = "Stonks Hen",
    ["storm_colossus"] = "Storm Colossus",
    ["strike_hen"] = "Strike Hen",
    ["striker_hen"] = "Striker Hen",
    ["sumo_rooster"] = "Sumo Rooster",
    ["sushi_hen"] = "Sushi Hen",
    ["talon_titan"] = "Talon Titan",
    ["tank_rooster"] = "Tank Rooster",
    ["taser_hen"] = "Taser Hen",
    ["tengu_rooster"] = "Tengu Rooster",
    ["tide_hen"] = "Tsunami Hen",
    ["twin_rooster"] = "Twin Rooster",
    ["twister_hen"] = "Twister Hen",
    ["unicorn_hen"] = "Unicorn Hen",
    ["valkyrie_hen"] = "Valkyrie Hen",
    ["vampire_rooster"] = "Vampire Rooster",
    ["viking_rooster"] = "Viking Rooster",
    ["viper_hen"] = "Viper Hen",
    ["voidbeak"] = "Voidbeak",
    ["witch_hen"] = "Cauldron Hen",
    ["zodiac_hen"] = "Zodiac Hen",
    ["zombie_chick"] = "Zombie Chick",
}

formatSpeciesName = function(typeId)
    if not typeId or typeId == "" then
        return "Unknown Chicken"
    end
    local raw = tostring(typeId):lower():gsub("^%s*(.-)%s*$", "%1")
    if CHICKEN_NAME_BY_TYPE_ID[raw] then
        return CHICKEN_NAME_BY_TYPE_ID[raw]
    end
    local words = {}
    for word in string.gmatch(raw, "[^_]+") do
        local cap = word:sub(1, 1):upper() .. word:sub(2):lower()
        table.insert(words, cap)
    end
    return table.concat(words, " ")
end

scanFlockChickens = function()
    local foundNames = {}
    local newMap = {}
    local duplicateCounter = {}
    local speciesTracker = {}

    -- =========================================================================
    -- [ENGINE 1 - UTAMA]: DETEKSI INSTAN BACKGROUND DARI DATASERVICE MEMORY
    -- (Tidak butuh pemain membuka menu Flock sama sekali!)
    -- =========================================================================
    pcall(function()
        local dsClient = getSharedDataServiceClient()
        local raw = dsClient and dsClient._data and dsClient._data._data
        if raw and raw.roster and raw.roster.chickens and type(raw.roster.chickens) == "table" then
            for _, ch in pairs(raw.roster.chickens) do
                if type(ch) == "table" and ch.id then
                    local cId = tostring(ch.id)
                    local numId = tonumber(string.match(cId, "%d+"))
                    local speciesName = formatSpeciesName(ch.typeId)
                    local cleanSpecies = speciesName:upper()

                    local chickenName = speciesName
                    local cleanTypeId = tostring(ch.typeId):gsub("_", " "):lower()
                    local nickClean = ch.nickname and type(ch.nickname) == "string" and ch.nickname:gsub("^%s*(.-)%s*$", "%1")
                    if nickClean and #nickClean > 0 and nickClean:lower() ~= cleanTypeId and nickClean:lower() ~= tostring(ch.typeId):lower() and nickClean:lower() ~= speciesName:lower() then
                        local nickCap = nickClean:sub(1, 1):upper() .. nickClean:sub(2)
                        chickenName = string.format("%s (%s)", nickCap, speciesName)
                    end

                    local finalLvlNum = tonumber(ch.level) or 1
                    local finalLvlStr = "Lvl " .. tostring(finalLvlNum)
                    local stars = tonumber(ch.promo) or 0
                    local rarity = ch.rarity and tostring(ch.rarity):upper() or "UNKNOWN"
                    local isFav = (ch.favorite == true)
                    local chickenSkill = ch.ability and tostring(ch.ability) or ""

                    local mutationBadge = ""
                    local mutName = nil
                    if ch.mutation then
                        if type(ch.mutation) == "string" and #ch.mutation > 0 and ch.mutation:lower() ~= "none" then
                            mutName = ch.mutation:sub(1, 1):upper() .. ch.mutation:sub(2):lower()
                        elseif type(ch.mutation) == "table" and ch.mutation.name then
                            local m = tostring(ch.mutation.name)
                            mutName = m:sub(1, 1):upper() .. m:sub(2):lower()
                        end
                        if mutName then
                            local mLow = mutName:lower()
                            local mIcon = mLow:find("jurassic") and "🦖" or (mLow:find("inverted") and "🌀" or "✨")
                            mutationBadge = string.format(" [%s %s]", mIcon, mutName)
                        end
                    end

                    if stars > 0 then
                        promotedChickenIds[cId] = true
                        if numId then
                            promotedChickenIds[numId] = true
                        end
                    end
                    if isFav then
                        favoritedChickenIds[cId] = true
                        if numId then
                            favoritedChickenIds[numId] = true
                        end
                    end

                    if not speciesTracker[cleanSpecies] then
                        speciesTracker[cleanSpecies] = {}
                    end
                    table.insert(speciesTracker[cleanSpecies], {
                        Id = cId,
                        NumId = numId,
                        Name = chickenName,
                        Species = cleanSpecies,
                        Lvl = finalLvlStr,
                        LvlNum = finalLvlNum,
                        Frame = nil,
                        Stars = stars,
                        Rarity = rarity,
                        IsFavorite = isFav,
                        Mutation = mutName,
                        MutationBadge = mutationBadge
                    })

                    local starBadge = string.format("★%d", stars)
                    local baseDisplay = string.format("%s %s (%s)%s", chickenName, starBadge, finalLvlStr, mutationBadge)
                    if isFav then
                        baseDisplay = "❤️ " .. baseDisplay
                    end

                    duplicateCounter[baseDisplay] = (duplicateCounter[baseDisplay] or 0) + 1
                    local finalDisplay = baseDisplay
                    if duplicateCounter[baseDisplay] > 1 then
                        finalDisplay = baseDisplay .. " #" .. tostring(duplicateCounter[baseDisplay])
                    end

                    if not newMap[finalDisplay] then
                        table.insert(foundNames, finalDisplay)
                        newMap[finalDisplay] = {
                            Id = cId,
                            Frame = nil,
                            Name = chickenName,
                            Lvl = finalLvlStr,
                            LvlNum = finalLvlNum,
                            Skill = chickenSkill,
                            IsFavorite = isFav,
                            Mutation = mutName,
                            MutationBadge = mutationBadge
                        }
                    end
                end
            end
        end
    end)

    -- =========================================================================
    -- [ENGINE 2 - FALLBACK]: SCAN LEWAT PLAYERGUI JIKA DATASERVICE BELUM SIAP
    -- =========================================================================
    if #foundNames == 0 then
        pcall(function()
            local playerGui = player:FindFirstChild("PlayerGui")
            if not playerGui then
                return
            end

            for _, desc in ipairs(playerGui:GetDescendants()) do
                local matchNumber = string.match(desc.Name, "^c(%d+)$")
                if matchNumber and (desc:IsA("Frame") or desc:IsA("GuiObject") or desc:IsA("TextButton")) then
                    local cId = desc.Name
                    local numId = tonumber(matchNumber)

                    local chickenName = nil
                    local chickenLvl = nil
                    local chickenLvlNum = nil
                    local isEgg = false

                    if desc.Name:lower():find("egg") then
                        isEgg = true
                    end

                    for _, child in ipairs(desc:GetDescendants()) do
                        if child:IsA("TextLabel") and child.Text and child.Text ~= "" then
                            local txt = child.Text:gsub("^%s*(.-)%s*$", "%1")
                            local txtLower = txt:lower()

                            if txtLower:find("egg") or txtLower:find("telur") then
                                isEgg = true
                            end

                            local lvlMatch = string.match(txt, "[Ll][Vv][Ll]?%.?%s*(%d+)") or string.match(txt, "[Ll]evel%s*(%d+)")
                            if lvlMatch and not chickenLvlNum then
                                chickenLvlNum = tonumber(lvlMatch)
                                chickenLvl = "Lvl " .. lvlMatch
                            else
                                local isGarbage = false
                                if txtLower:find("^%+") or txtLower:find("^%-") or txtLower:find("%%") then
                                    isGarbage = true
                                elseif txtLower:find("xp") or txtLower:find("boost") or txtLower:find("%$") then
                                    isGarbage = true
                                elseif string.match(txtLower, "^x%d+$") or string.match(txtLower, "^%d+x$") then
                                    isGarbage = true
                                elseif string.match(txt, "^%d+%.?%d*[kKmMbBtT]?$") then
                                    isGarbage = true
                                elseif txtLower == "chicken name" or txtLower == "active" or txtLower == "fuse" or txtLower == "promote" or txtLower == "sell" or txtLower == "index" or txtLower == "sell mode" or txtLower == "template" then
                                    isGarbage = true
                                end

                                if not isGarbage and not isEgg and #txt > 1 and not chickenName then
                                    chickenName = txt
                                end
                            end
                        end
                    end

                    if not isEgg and chickenName then
                        local finalLvlNum = chickenLvlNum or 1
                        local finalLvlStr = chickenLvl or ("Lvl " .. tostring(finalLvlNum))
                        local cleanSpecies = chickenName:upper()
                        local stars = getChickenStarCount(desc, cId, numId)
                        local rarity = detectChickenRarity(desc, chickenName)
                        if not rarity or rarity == "" then
                            rarity = "Unknown"
                        end

                        if stars > 0 then
                            promotedChickenIds[cId] = true
                            if numId then
                                promotedChickenIds[numId] = true
                            end
                        end

                        local isFav = favoritedChickenIds[cId] or (numId and favoritedChickenIds[numId]) or desc:GetAttribute("Favorite") == true or desc:FindFirstChild("Favorite")

                        local mutationBadge = ""
                        local mutName = nil
                        local attrMut = desc:GetAttribute("Mutation") or desc:GetAttribute("ovMutation") or desc:GetAttribute("mutation")
                        if attrMut and type(attrMut) == "string" and #attrMut > 0 and attrMut:lower() ~= "none" then
                            mutName = attrMut:sub(1, 1):upper() .. attrMut:sub(2):lower()
                        else
                            for _, child in ipairs(desc:GetDescendants()) do
                                if child:IsA("TextLabel") and child.Text and child.Text ~= "" then
                                    local txtLower = child.Text:lower()
                                    if txtLower:find("jurassic") then
                                        mutName = "Jurassic"
                                        break
                                    elseif txtLower:find("inverted") then
                                        mutName = "Inverted"
                                        break
                                    end
                                end
                            end
                        end
                        if mutName then
                            local mLow = mutName:lower()
                            local mIcon = mLow:find("jurassic") and "🦖" or (mLow:find("inverted") and "🌀" or "✨")
                            mutationBadge = string.format(" [%s %s]", mIcon, mutName)
                        end

                        if not speciesTracker[cleanSpecies] then
                            speciesTracker[cleanSpecies] = {}
                        end
                        table.insert(speciesTracker[cleanSpecies], {
                            Id = cId,
                            NumId = numId,
                            Name = chickenName,
                            Species = cleanSpecies,
                            Lvl = finalLvlStr,
                            LvlNum = finalLvlNum,
                            Frame = desc,
                            Stars = stars,
                            Rarity = rarity,
                            IsFavorite = isFav,
                            Mutation = mutName,
                            MutationBadge = mutationBadge
                        })

                        local starBadge = string.format("★%d", stars)
                        local baseDisplay = string.format("%s %s (%s)%s", chickenName, starBadge, finalLvlStr, mutationBadge)
                        if isFav then
                            baseDisplay = "❤️ " .. baseDisplay
                        end

                        duplicateCounter[baseDisplay] = (duplicateCounter[baseDisplay] or 0) + 1
                        local finalDisplay = baseDisplay
                        if duplicateCounter[baseDisplay] > 1 then
                            finalDisplay = baseDisplay .. " #" .. tostring(duplicateCounter[baseDisplay])
                        end

                        local chickenSkill = extractChickenSkill(desc)

                        if not newMap[finalDisplay] then
                            table.insert(foundNames, finalDisplay)
                            newMap[finalDisplay] = {
                                Id = cId,
                                Frame = desc,
                                Name = chickenName,
                                Lvl = finalLvlStr,
                                LvlNum = finalLvlNum,
                                Skill = chickenSkill,
                                IsFavorite = isFav,
                                Mutation = mutName,
                                MutationBadge = mutationBadge
                            }
                        end
                    end
                end
            end
        end)
    end

    table.sort(foundNames, function(a, b)
        return a < b
    end)
    if #foundNames == 0 then
        table.insert(foundNames, "Buka menu Flock di game lalu klik Refresh!")
    end

    chickenNames = foundNames
    chickenMap = newMap
    if not selectedChickenName or not chickenMap[selectedChickenName] then
        selectedChickenName = chickenNames[1]
        selectedChickenId = chickenMap[selectedChickenName] and chickenMap[selectedChickenName].Id
    end
    if not selectedFavChickenName or not chickenMap[selectedFavChickenName] then
        selectedFavChickenName = chickenNames[1]
    end

    globalSpeciesTracker = speciesTracker

    -- Bangun promoteTargetList & promoteTargetMap untuk Dropdown 1
    local newTargetList = {}
    local newTargetMap = {}
    local targetDupCounter = {}

    for specName, list in pairs(speciesTracker) do
        -- Hanya tampilkan jika jenis ayam ini memiliki duplikat sejenis (> 1 ekor di kawanan)
        if #list > 1 then
            for _, ch in ipairs(list) do
                local mutBadge = ch.MutationBadge or ""
                local favBadge = ch.IsFavorite and "❤️ " or ""
                local baseLabel = string.format("%s%s ★%d (%s)%s", favBadge, ch.Name, ch.Stars, ch.Lvl, mutBadge)
                targetDupCounter[baseLabel] = (targetDupCounter[baseLabel] or 0) + 1
                local label = baseLabel .. " #" .. tostring(targetDupCounter[baseLabel])
                table.insert(newTargetList, label)
                newTargetMap[label] = ch
            end
        end
    end

    table.sort(newTargetList, function(a, b)
        return a < b
    end)
    if #newTargetList == 0 then
        table.insert(newTargetList, "Tidak ada ayam yang memiliki duplikat sejenis")
    end

    promoteTargetList = newTargetList
    promoteTargetMap = newTargetMap
    if not selectedPromoteTarget or not promoteTargetMap[selectedPromoteTarget] then
        selectedPromoteTarget = promoteTargetList[1]
    end

    local function safeRefreshDropdown(dd, list)
        if not dd or not list then
            return
        end
        pcall(function()
            if type(dd.Refresh) == "function" then
                dd:Refresh(list, true)
            elseif type(dd.SetValues) == "function" then
                dd:SetValues(list)
            end
            if type(dd.SetValue) == "function" and list and list[1] then
                dd:SetValue(list[1])
            end
            if expandDropdown then
                expandDropdown(dd, 300)
            end
        end)
    end

    -- Update Dropdown 2 (Bahan) secara real-time berdasarkan ayam target terpilih
    if updatePromoteFodders then
        updatePromoteFodders(selectedPromoteTarget)
    end

    -- Refresh 7 dropdown secara terdistribusi (staggered) agar framerate tetap 60 FPS tanpa freeze
    task.spawn(function()
        pcall(function() safeRefreshDropdown(chickenDropdown, chickenNames) end)
        task.wait(0.02)
        pcall(function()
            safeRefreshDropdown(promoteTargetDropdown, promoteTargetList)
            safeRefreshDropdown(promoteDropdown, promoteTargetList)
        end)
        task.wait(0.02)
        pcall(function()
            safeRefreshDropdown(fuseMainDropdown, chickenNames)
            safeRefreshDropdown(fuseFodderDropdown, chickenNames)
        end)
        task.wait(0.02)
        pcall(function()
            safeRefreshDropdown(favDropdown, chickenNames)
            safeRefreshDropdown(UpdateHub.charmDropdown, chickenNames)
            safeRefreshDropdown(UpdateHub.ufoChickenDropdown, chickenNames)
            if updateAvailableSkills then
                updateAvailableSkills()
            end
        end)
    end)
end

updatePromoteFodders = function(targetLabel)
    if not targetLabel or not promoteTargetMap[targetLabel] then
        promoteFodderList = {"Pilih ayam target terlebih dahulu"}
        if promoteFodderDropdown and promoteFodderDropdown.Refresh then
            pcall(function()
                promoteFodderDropdown:Refresh(promoteFodderList, true)
                if promoteFodderDropdown.SetValue then
                    promoteFodderDropdown:SetValue(promoteFodderList[1])
                end
                if expandDropdown then
                    expandDropdown(promoteFodderDropdown, 300)
                end
            end)
        end
        return
    end

    local target = promoteTargetMap[targetLabel]
    local targetSpecies = target.Species
    local targetRarity = target.Rarity
    local currentStars = target.Stars
    local neededFodders, nextStar = getRequiredFodders(targetRarity, currentStars)

    local candidateFodders = {}
    if globalSpeciesTracker[targetSpecies] then
        for _, ch in ipairs(globalSpeciesTracker[targetSpecies]) do
            local isMutated = (ch.Mutation and ch.Mutation ~= "" and ch.Mutation:lower() ~= "none" and ch.Mutation:lower() ~= "tidak ada")
            if ch.Id ~= target.Id and not favoritedChickenIds[ch.Id] and not isMutated then
                table.insert(candidateFodders, ch)
            end
        end
    end

    -- Urutkan bahan: utamakan ayam tanpa bintang & level terendah
    table.sort(candidateFodders, function(a, b)
        if a.Stars ~= b.Stars then
            return a.Stars < b.Stars
        end
        return a.LvlNum < b.LvlNum
    end)

    local newFodderList = {}
    local newFodderMap = {}
    local defaultSelected = {}
    selectedPromoteFoddersMap = {}

    local fodderDupCounter = {}
    for i, f in ipairs(candidateFodders) do
        local mutBadge = f.MutationBadge or ""
        local baseLabel = string.format("%s ★%d (%s)%s", f.Name, f.Stars, f.Lvl, mutBadge)
        fodderDupCounter[baseLabel] = (fodderDupCounter[baseLabel] or 0) + 1
        local label = baseLabel .. " #" .. tostring(fodderDupCounter[baseLabel])
        table.insert(newFodderList, label)
        newFodderMap[label] = f

        -- Otomatis pre-select bahan sejumlah neededFodders (utamakan ayam tanpa bintang terendah)
        if i <= neededFodders then
            table.insert(defaultSelected, label)
            selectedPromoteFoddersMap[label] = true
        end
    end

    if #newFodderList == 0 then
        table.insert(newFodderList, "Tidak ada ayam sejenis yang dapat dikorbankan")
    end

    promoteFodderList = newFodderList
    promoteFodderMap = newFodderMap

    if promoteFodderDropdown and promoteFodderDropdown.Refresh then
        pcall(function()
            promoteFodderDropdown:Refresh(promoteFodderList, true)
            if #defaultSelected > 0 and promoteFodderDropdown.SetValue then
                promoteFodderDropdown:SetValue(defaultSelected)
            end
            if expandDropdown then
                expandDropdown(promoteFodderDropdown, 300)
            end
        end)
    end

    if updatePromoteStatusDisplay then
        updatePromoteStatusDisplay()
    end
end

updatePromoteStatusDisplay = function()
    if not promoteStatusPara then
        return
    end
    if not selectedPromoteTarget or not promoteTargetMap[selectedPromoteTarget] then
        pcall(function()
            if type(promoteStatusPara.SetTitle) == "function" and type(promoteStatusPara.SetDesc) == "function" then
                promoteStatusPara:SetTitle("Status Persyaratan Promote")
                promoteStatusPara:SetDesc("Silakan pilih ayam target pada Target Promote.")
            elseif type(promoteStatusPara.Set) == "function" then
                promoteStatusPara:Set({
                    Title = "Status Persyaratan Promote",
                    Desc = "Silakan pilih ayam target pada Target Promote."
                })
            end
        end)
        return
    end

    local target = promoteTargetMap[selectedPromoteTarget]
    local neededFodders, nextStar = getRequiredFodders(target.Rarity, target.Stars)

    local chosenCount = 0
    for label, isChecked in pairs(selectedPromoteFoddersMap) do
        if isChecked and promoteFodderMap[label] then
            chosenCount = chosenCount + 1
        end
    end

    local curStarTxt = string.format("★%d", target.Stars)
    local mutTxt = target.MutationBadge or ""
    local title = string.format("Promote: %s%s (%s • %s)", target.Name, mutTxt, curStarTxt, target.Rarity)
    local desc = ""

    if chosenCount < neededFodders then
        local kurang = neededFodders - chosenCount
        desc = string.format("🎯 Target: Naik ke ★ %d (%s)\n📋 Syarat Resmi Game: Butuh %d Ekor Bahan Sejenis\n\n⚠️ Status Bahan: %d/%d Terpilih (Kurang %d ekor)\n👉 Centang %d ekor ayam lagi di Bahan Korban.", nextStar, target.Rarity, neededFodders, chosenCount, neededFodders, kurang, kurang)
    elseif chosenCount > neededFodders then
        local lebih = chosenCount - neededFodders
        desc = string.format("🎯 Target: Naik ke ★ %d (%s)\n📋 Syarat Resmi Game: Butuh %d Ekor Bahan Sejenis\n\n⚠️ Status Bahan: %d/%d Terpilih (Kelebihan %d ekor)\n👉 Hapus centang %d ekor agar pas %d ekor saja.", nextStar, target.Rarity, neededFodders, chosenCount, neededFodders, lebih, lebih, neededFodders)
    else
        desc = string.format("🎯 Target: Naik ke ★ %d (%s)\n📋 Syarat Resmi Game: Butuh %d Ekor Bahan Sejenis\n\n✅ Status Bahan: PAS %d/%d Terpilih!\n✨ Semua bahan aman & siap dikorbankan. Klik tombol di bawah untuk promote.", nextStar, target.Rarity, neededFodders, chosenCount, neededFodders)
    end

    pcall(function()
        if type(promoteStatusPara.SetTitle) == "function" and type(promoteStatusPara.SetDesc) == "function" then
            promoteStatusPara:SetTitle(title)
            promoteStatusPara:SetDesc(desc)
        elseif type(promoteStatusPara.Set) == "function" then
            promoteStatusPara:Set({
                Title = title,
                Desc = desc
            })
        end
    end)
end

local function executePromoteSelectedSpecies()
    if not selectedPromoteTarget or not promoteTargetMap[selectedPromoteTarget] then
        return false, "Pilih ayam target untuk dipromote terlebih dahulu"
    end

    local target = promoteTargetMap[selectedPromoteTarget]
    local targetSpecies = target.Species
    local targetRarity = target.Rarity
    local currentStars = target.Stars
    local neededFodders, nextStar = getRequiredFodders(targetRarity, currentStars)

    -- Kumpulkan ayam bahan yang benar-benar dicentang oleh user di Dropdown 2
    local chosenFodders = {}
    for label, isChecked in pairs(selectedPromoteFoddersMap) do
        if isChecked and promoteFodderMap[label] then
            table.insert(chosenFodders, promoteFodderMap[label])
        end
    end

    -- PROTEKSI KETAT: Jumlah bahan terpilih WAJIB PERSIS SAMA dengan neededFodders!
    if #chosenFodders < neededFodders then
        local kurang = neededFodders - #chosenFodders
        return false, string.format("Dibatalkan: Baru %d/%d bahan terpilih untuk naik ke ★ %d (Kurang %d ekor). Silakan centang bahan di Bahan Korban.", #chosenFodders, neededFodders, nextStar, kurang)
    end

    if #chosenFodders > neededFodders then
        local lebih = #chosenFodders - neededFodders
        return false, string.format("Dibatalkan: Anda mencentang %d bahan (Kelebihan %d ekor). Syarat resmi hanya butuh %d ekor. Harap centang pas %d ekor.", #chosenFodders, lebih, neededFodders, neededFodders)
    end

    -- Kumpulkan HANYA ID dari ayam bahan yang dipilih oleh user
    local selectedFodderStrIds = {}
    local selectedFodderNumIds = {}
    for _, f in ipairs(chosenFodders) do
        table.insert(selectedFodderStrIds, f.Id)
        if f.NumId then
            table.insert(selectedFodderNumIds, f.NumId)
        end
    end

    local initialStars = target.Stars

    -- PANGGIL REMOTE RESMI PROMOTECHICKEN HANYA DENGAN BAHAN TERPILIH (TIDAK PERNAH PANGGIL FUSECHICKENS)
    local anySuccess = false

    -- 1. Format: PromoteChicken(targetId, {fodderId1, fodderId2, ...})
    pcall(function()
        local r1 = invokeRemote("PromoteChicken", target.Id, selectedFodderStrIds)
        if r1 ~= nil and (type(r1) ~= "table" or not r1.error) then
            anySuccess = true
        end
    end)

    -- 2. Format: PromoteChicken(targetNumId, {numId1, numId2, ...})
    if not anySuccess and target.NumId and #selectedFodderNumIds > 0 then
        pcall(function()
            local r2 = invokeRemote("PromoteChicken", target.NumId, selectedFodderNumIds)
            if r2 ~= nil and (type(r2) ~= "table" or not r2.error) then
                anySuccess = true
            end
        end)
    end

    -- 3. Format: PromoteChicken(targetId, fodderId1, fodderId2, ...)
    if not anySuccess and #selectedFodderStrIds > 0 then
        pcall(function()
            local r1b = invokeRemote("PromoteChicken", target.Id, unpack(selectedFodderStrIds))
            if r1b ~= nil and (type(r1b) ~= "table" or not r1b.error) then
                anySuccess = true
            end
        end)
    end

    -- 4. Format: PromoteChicken(targetId) (Server otomatis memproses target jika state bahan siap)
    if not anySuccess then
        pcall(function()
            local r4 = invokeRemote("PromoteChicken", target.Id)
            if r4 ~= nil and (type(r4) ~= "table" or not r4.error) then
                anySuccess = true
            end
        end)
    end

    task.wait(1.5)
    scanFlockChickens()

    local updatedTarget = promoteTargetMap[selectedPromoteTarget]
    local newStars = updatedTarget and updatedTarget.Stars or 0
    local promotedOk = (newStars > initialStars) or anySuccess

    if promotedOk then
        promotedChickenIds[target.Id] = true
        if target.NumId then
            promotedChickenIds[target.NumId] = true
        end
        return true, string.format("%s berhasil dipromote ke ★ %d dengan %d bahan terpilih!", target.Species, nextStar, #chosenFodders)
    else
        return false, "Server belum memproses promote untuk " .. tostring(target.Species)
    end
end

updateAvailableSkills = function()
    local detectedSkills = {}
    local skillSet = {}

    local function addSkill(skillName)
        if skillName and type(skillName) == "string" and skillName ~= "" then
            local trimmed = skillName:gsub("^%s*(.-)%s*$", "%1")
            if not skillSet[trimmed:upper()] and trimmed:lower() ~= "skill" and #trimmed > 2 then
                skillSet[trimmed:upper()] = true
                table.insert(detectedSkills, trimmed)
            end
        end
    end

    if fuseMainChickenName and chickenMap[fuseMainChickenName] then
        local mainData = chickenMap[fuseMainChickenName]
        local s = mainData.Skill or extractChickenSkill(mainData.Frame)
        if s then
            addSkill(s)
        end
    end

    if fuseFodderChickenName and chickenMap[fuseFodderChickenName] then
        local fodderData = chickenMap[fuseFodderChickenName]
        local s = fodderData.Skill or extractChickenSkill(fodderData.Frame)
        if s then
            addSkill(s)
        end
    end

    local insp = getSkillFromInspector()
    if insp then
        addSkill(insp)
    end

    if #detectedSkills == 0 then
        detectedSkills = {"Stormcall", "Final Grace", "Lightning Strike", "Inferno Breath", "Void Pulse", "Golden Touch"}
    end

    availableFuseSkills = detectedSkills
    if not fuseLockedSkill or not skillSet[fuseLockedSkill:upper()] then
        fuseLockedSkill = availableFuseSkills[1]
    end

    pcall(function()
        if fuseSkillDropdown then
            if type(fuseSkillDropdown.Refresh) == "function" then
                fuseSkillDropdown:Refresh(availableFuseSkills, true)
            elseif type(fuseSkillDropdown.SetValues) == "function" then
                fuseSkillDropdown:SetValues(availableFuseSkills)
            end
        end
    end)
end

local function executeFuseChickens()
    if not fuseMainChickenName or not chickenMap[fuseMainChickenName] then
        return false, "Pilih ayam utama!"
    end
    if not fuseFodderChickenName or not chickenMap[fuseFodderChickenName] then
        return false, "Pilih ayam bahan!"
    end
    if fuseMainChickenName == fuseFodderChickenName then
        return false, "Ayam utama & bahan tidak boleh sama!"
    end

    local mainData = chickenMap[fuseMainChickenName]
    local fodderData = chickenMap[fuseFodderChickenName]
    local mainId = mainData.Id
    local fodderId = fodderData.Id
    if favoritedChickenIds[fodderId] then
        return false, "Ayam bahan terkunci sebagai Favorit!"
    end
    if fodderData.Mutation and fodderData.Mutation ~= "" and fodderData.Mutation:lower() ~= "none" and fodderData.Mutation:lower() ~= "tidak ada" then
        return false, "Ayam bahan memiliki mutasi (" .. tostring(fodderData.Mutation) .. ")! Proteksi aktif."
    end

    invokeRemote("FuseChickens", mainId, fodderId, fuseLockedSkill or "Stormcall")
    invokeRemote("FuseChickens", mainId, fodderId)
    invokeRemote("DevourChicken", fodderId, mainId)
    scanFlockChickens()
    return true, "Penggabungan selesai!"
end

-- ==============================================================================

-- EXPORT ALL STATE TABLES & FUNCTIONS TO CONTEXT & GETGENV
Context.Players = Players
Context.Workspace = Workspace
Context.ReplicatedStorage = ReplicatedStorage
Context.CoreGui = CoreGui
Context.RunService = RunService
Context.UserInputService = UserInputService
Context.Lighting = Lighting
Context.TeleportService = TeleportService
Context.HttpService = HttpService
Context.player = player
Context.registeredUiElements = registeredUiElements
Context.saveConfig = saveConfig
Context.expandDropdown = expandDropdown
Context.setupDropdownPopupExpander = setupDropdownPopupExpander
Context.logError = logError
Context.printLog = printLog
Context.notify = notify
Context.parseToggle = parseToggle
Context.currentPlotId = currentPlotId
Context.autoFastRebirth = autoFastRebirth
Context.autoRebirth = autoRebirth
Context.delayFastRebirth = delayFastRebirth
Context.delayRebirth = delayRebirth
Context.fastAutoUpgradeCoop = fastAutoUpgradeCoop
Context.fastTargetCoop = fastTargetCoop
Context.fastAutoUpgradeFeeder = fastAutoUpgradeFeeder
Context.fastTargetFeederCount = fastTargetFeederCount
Context.fastTargetFeederLevel = fastTargetFeederLevel
Context.fastMaxFeeders = fastMaxFeeders
Context.fastAutoTower = fastAutoTower
Context.fastTargetFloor = fastTargetFloor
Context.cachedRequiredFloor = cachedRequiredFloor
Context.lastSilentRefreshTime = lastSilentRefreshTime
Context.fastFloorOverride = fastFloorOverride
Context.updateFastRebirthStatus = updateFastRebirthStatus
Context.fastRebirthCurrentAction = fastRebirthCurrentAction
Context.autoUpgradeCoop = autoUpgradeCoop
Context.delayCoop = delayCoop
Context.autoUpgradeRecycler = autoUpgradeRecycler
Context.delayRecycler = delayRecycler
Context.autoBuyFeeder = autoBuyFeeder
Context.delayBuy = delayBuy
Context.autoUpgradeFeeder = autoUpgradeFeeder
Context.delayUpgrade = delayUpgrade
Context.MAX_FEEDER_SLOTS = MAX_FEEDER_SLOTS
Context.autoCollectNestEggs = autoCollectNestEggs
Context.delayCollectEgg = delayCollectEgg
Context.autoClaimIncubator = autoClaimIncubator
Context.autoPutIncubator = autoPutIncubator
Context.autoUpgradeIncubator = autoUpgradeIncubator
Context.delayUpgradeIncubator = delayUpgradeIncubator
Context.autoSweep = autoSweep
Context.isSweepRunning = isSweepRunning
Context.MAX_CAPACITY = MAX_CAPACITY
Context.autoTower = autoTower
Context.retreatFloor = retreatFloor
Context.delayTower = delayTower
Context.towerHpThreshold = towerHpThreshold
Context.towerStartMode = towerStartMode
Context.autoSellChickens = autoSellChickens
Context.delaySellChicken = delaySellChicken
Context.sellMaxLevelProtection = sellMaxLevelProtection
Context.selectedSellRarities = selectedSellRarities
Context.autoPromote = autoPromote
Context.delayPromote = delayPromote
Context.selectedPromoteTarget = selectedPromoteTarget
Context.promoteTargetList = promoteTargetList
Context.promoteTargetMap = promoteTargetMap
Context.selectedPromoteFodder = selectedPromoteFodder
Context.selectedPromoteFoddersMap = selectedPromoteFoddersMap
Context.promoteFodderList = promoteFodderList
Context.promoteFodderMap = promoteFodderMap
Context.globalSpeciesTracker = globalSpeciesTracker
Context.updatePromoteStatusDisplay = updatePromoteStatusDisplay
Context.promoteStatusPara = promoteStatusPara
Context.autoPromoteToggle = autoPromoteToggle
Context.autoFuse = autoFuse
Context.fuseMainChickenName = fuseMainChickenName
Context.fuseFodderChickenName = fuseFodderChickenName
Context.fuseLockedSkill = fuseLockedSkill
Context.favoritedChickenIds = favoritedChickenIds
Context.promotedChickenIds = promotedChickenIds
Context.selectedFavChickenName = selectedFavChickenName
Context.webhookUrl = webhookUrl
Context.webhookRebirthEnabled = webhookRebirthEnabled
Context.triggerWebhookRebirthEvent = triggerWebhookRebirthEvent
Context.UpdateHub = UpdateHub
Context.customPromoCode = customPromoCode
Context.promoCodesList = promoCodesList
Context.espPlayerEnabled = espPlayerEnabled
Context.espEggEnabled = espEggEnabled
Context.espScrapEnabled = espScrapEnabled
Context.streamerMode = streamerMode
Context.fakeName = fakeName
Context.chickenNames = chickenNames
Context.chickenMap = chickenMap
Context.selectedChickenName = selectedChickenName
Context.selectedChickenId = selectedChickenId
Context.chickenDropdown = chickenDropdown
Context.promoteTargetDropdown = promoteTargetDropdown
Context.promoteFodderDropdown = promoteFodderDropdown
Context.promoteDropdown = promoteDropdown
Context.fuseMainDropdown = fuseMainDropdown
Context.fuseFodderDropdown = fuseFodderDropdown
Context.fuseSkillDropdown = fuseSkillDropdown
Context.availableFuseSkills = availableFuseSkills
Context.favDropdown = favDropdown
Context.remoteCache = remoteCache
Context.invokeRemote = invokeRemote
Context.dismissTowerKOUI = dismissTowerKOUI
Context.isHeldBySomeone = isHeldBySomeone
Context.getNearestScrap = getNearestScrap
Context.fireCollectEvents = fireCollectEvents
Context.getCurrentFloor = getCurrentFloor
Context.liveRebirthCount = liveRebirthCount
Context.getRebirthCount = getRebirthCount
Context._detectedFormulaArm = _detectedFormulaArm
Context.getExactRebirthRequirement = getExactRebirthRequirement
Context.cachedCoopPosition = cachedCoopPosition
Context.getCoopPosition = getCoopPosition
Context.getFrontOfCoopPosition = getFrontOfCoopPosition
Context.getMyChickenBody = getMyChickenBody
Context.getChickenDistanceToCoop = getChickenDistanceToCoop
Context.getChickenStatus = getChickenStatus
Context.isChickenAtBase = isChickenAtBase
Context.getRebirthRequirement = getRebirthRequirement
Context.getRealBackpackCount = getRealBackpackCount
Context.isChickenHpFull = isChickenHpFull
Context.getCoopAndFeederStats = getCoopAndFeederStats
Context.cachedMyRecycler = cachedMyRecycler
Context.findMyRecycler = findMyRecycler
Context.noclipConnection = noclipConnection
Context.noclipPartsCache = noclipPartsCache
Context.enableNoclip = enableNoclip
Context.disableNoclip = disableNoclip
Context.safeWalkTo = safeWalkTo
Context.cleanESP = cleanESP
Context.createESPBillboard = createESPBillboard
Context.createESPHighlight = createESPHighlight
Context.collectMyNestEggs = collectMyNestEggs
Context.scanFlockChickens = scanFlockChickens
Context.OFFICIAL_PROMOTE_REQUIREMENTS = OFFICIAL_PROMOTE_REQUIREMENTS
Context.getRequiredFodders = getRequiredFodders
Context.scanGamePromoteData = scanGamePromoteData
Context.KNOWN_SPECIES_RARITY = KNOWN_SPECIES_RARITY
Context.evaluateColorRarity = evaluateColorRarity
Context.catalogPreloaded = catalogPreloaded
Context.preloadGameChickenCatalog = preloadGameChickenCatalog
Context.detectChickenRarity = detectChickenRarity
Context.getChickenStarCount = getChickenStarCount
Context.isChickenPromoted = isChickenPromoted
Context.formatSpeciesName = formatSpeciesName
Context.cachedDataServiceClient = cachedDataServiceClient
Context.getSharedDataServiceClient = getSharedDataServiceClient
Context.isScanFlockScheduled = isScanFlockScheduled
Context.requestFlockScan = requestFlockScan
Context.executeSellChickens = executeSellChickens
Context.extractChickenSkill = extractChickenSkill
Context.getSkillFromInspector = getSkillFromInspector
Context.updateAvailableSkills = updateAvailableSkills
Context.updatePromoteFodders = updatePromoteFodders
Context.CHICKEN_NAME_BY_TYPE_ID = CHICKEN_NAME_BY_TYPE_ID
Context.executePromoteSelectedSpecies = executePromoteSelectedSpecies
Context.executeFuseChickens = executeFuseChickens

-- Global bridge for Roblox executor environment
if getgenv then
    local env = getgenv()
    for k, v in pairs(Context) do
        env[k] = v
    end
    env.SysHubContext = Context
end

return Context
