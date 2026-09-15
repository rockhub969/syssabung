-- ANTI-DUPLICATE SINGLE INSTANCE GUARD (Mencegah lag tumpukan loop saat re-execute)
local currentInstanceId = (getgenv and getgenv().SysHubInstanceId or 0) + 1
if getgenv then
    getgenv().SysHubInstanceId = currentInstanceId
end

local function isCurrentInstance()
    return not getgenv or getgenv().SysHubInstanceId == currentInstanceId
end

-- ==============================================================================
--              SYSHUB | GROW A CHICKEN FIGHTER (MODULAR INIT)
-- ==============================================================================

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

-- Fetcher helper (Support Lokal & GitHub Online)
local fetch = getgenv and getgenv().SysHubFetch or function(relPath)
    if isfile and isfile("syssabung_modular/" .. relPath) then
        return readfile("syssabung_modular/" .. relPath)
    end
    local url = "https://raw.githubusercontent.com/rockhub969/syssabung/main/syssabung_modular/" .. relPath
    return game:HttpGet(url)
end

local function import(relPath)
    local code = fetch(relPath)
    if not code or #code < 10 then
        error("[SysHub Init ERROR]: Gagal memuat " .. tostring(relPath))
    end
    local fn, err = loadstring(code)
    if not fn then
        error("[SysHub Syntax ERROR in " .. relPath .. "]: " .. tostring(err))
    end
    return fn()
end

-- 1. Inisialisasi WindUI & Window
local WindUI = nil
local successUI, resultUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if successUI and resultUI then
    WindUI = resultUI
else
    local okRaw, rawResult = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end)
    if okRaw and rawResult then
        WindUI = rawResult
    end
end

if not WindUI then
    warn("[SysHub ERROR]: Gagal memuat library WindUI dari GitHub! Periksa koneksi internet.")
    return
end

local Window = nil
local successWindow, resultWindow = pcall(function()
    return WindUI:CreateWindow({
        Title = "SysHub - Grow A Chicken Fighter",
        Icon = "egg",
        Author = "Premium Version",
        Folder = "SysHub",
        Size = UDim2.fromOffset(640, 420),
        MinSize = Vector2.new(480, 320),
        MaxSize = Vector2.new(950, 650),
        Transparent = true,
        NewElements = true,
        Theme = "Sky",
        Resizable = true,
        SideBarWidth = 160,
        BackgroundImageTransparency = 0.42,
        HideSearchBar = true,
        ScrollBarEnabled = true
    })
end)

if successWindow and resultWindow then
    Window = resultWindow
else
    warn("[SysHub ERROR]: Gagal membuat Window: " .. tostring(resultWindow))
    return
end

pcall(function()
    Window:EditOpenButton({
        Title = "SysHub - Grow A Chicken Fighter",
        Icon = "egg",
        CornerRadius = UDim.new(0, 30),
        StrokeThickness = 1.5,
        Color = ColorSequence.new(Color3.fromHex("87CEFA"), Color3.fromHex("191970")),
        OnlyMobile = false,
        Enabled = true,
        Draggable = true
    })
end)

task.spawn(function() pcall(function() loadstring(game:HttpGet("https://rockhub.net/ntahlahwog3a09spk/iconsys.lua"))()(Window) end) end)

-- ==============================================================================

if getgenv then
    getgenv().WindUI = WindUI
    getgenv().Window = Window
end

-- 2. Muat Core Context Engine
local Context = import("core/context.lua")
local UpdateHub = Context.UpdateHub
local chickenMap = Context.chickenMap
local chickenNames = Context.chickenNames
local invokeRemote = Context.invokeRemote
local notify = Context.notify
local printLog = Context.printLog
local logError = Context.logError
local saveConfig = Context.saveConfig
local parseToggle = Context.parseToggle
local scanFlockChickens = Context.scanFlockChickens
local cleanESP = Context.cleanESP
local createESPHighlight = Context.createESPHighlight
local createESPBillboard = Context.createESPBillboard
local collectMyNestEggs = Context.collectMyNestEggs
local findMyRecycler = Context.findMyRecycler
local enableNoclip = Context.enableNoclip
local disableNoclip = Context.disableNoclip
local safeWalkTo = Context.safeWalkTo
local getMyChickenBody = Context.getMyChickenBody
local getChickenStatus = Context.getChickenStatus
local isChickenAtBase = Context.isChickenAtBase
local isChickenHpFull = Context.isChickenHpFull
local getCurrentFloor = Context.getCurrentFloor
local getRebirthCount = Context.getRebirthCount
local getExactRebirthRequirement = Context.getExactRebirthRequirement
local getRebirthRequirement = Context.getRebirthRequirement
local getRealBackpackCount = Context.getRealBackpackCount
local getCoopPosition = Context.getCoopPosition
local getFrontOfCoopPosition = Context.getFrontOfCoopPosition
local getCoopAndFeederStats = Context.getCoopAndFeederStats
local executeSellChickens = Context.executeSellChickens
local executeFuseChickens = Context.executeFuseChickens
local executePromoteSelectedSpecies = Context.executePromoteSelectedSpecies
local updatePromoteStatusDisplay = Context.updatePromoteStatusDisplay
local updatePromoteFodders = Context.updatePromoteFodders
local updateAvailableSkills = Context.updateAvailableSkills
local isHeldBySomeone = Context.isHeldBySomeone
local fireCollectEvents = Context.fireCollectEvents
local dismissTowerKOUI = Context.dismissTowerKOUI
local triggerWebhookRebirthEvent = Context.triggerWebhookRebirthEvent
if getgenv then
    getgenv().SysHubContext = Context
end

-- 3. Inisialisasi Tabs Resmi
-- TAB RESMI SESUAI REQUEST USER
local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "user"
})

local FarmTab = Window:Tab({
    Title = "Farm",
    Icon = "sprout"
})

local CoopTab = Window:Tab({
    Title = "Coop",
    Icon = "warehouse"
})

local FlockTab = Window:Tab({
    Title = "Flock",
    Icon = "feather"
})

local EventTab = Window:Tab({
    Title = "Event",
    Icon = "sparkles"
})


local RewardsTab = Window:Tab({
    Title = "Rewards",
    Icon = "gift"
})

local MiscTab = Window:Tab({
    Title = "Misc",
    Icon = "server"
})

local WebhookTab = Window:Tab({
    Title = "Webhook",
    Icon = "webhook"
})

local aboutTab = Window:Tab({ Title = "About", Icon = "info", Locked = false })

-- ABOUT TAB
aboutTab:Section({ Title = "Have Problem / Need Help? Join Server Now", Box = true, TextTransparency = 0.05, TextXAlignment = "Center", TextSize = 17, Opened = false })

local InviteCode = "syshub"
local Response, ErrorMessage = nil, nil
xpcall(function() Response = HttpService:JSONDecode(WindUI.Creator.Request({ Url = "https://discord.com/api/v10/invites/" .. InviteCode .. "?with_counts=true&with_expiration=true", Method = "GET", Headers = { ["Accept"] = "application/json" } }).Body) end, function(err) ErrorMessage = tostring(err) end)

if Response and Response.guild then
    local pCfg = { Title = Response.guild.name, Desc = ' <font color="#52525b">•</font> Member Count: ' .. tostring(Response.approximate_member_count) .. '\n <font color="#16a34a">•</font> Online Count: ' .. tostring(Response.approximate_presence_count), Image = "https://cdn.discordapp.com/icons/" .. Response.guild.id .. "/" .. Response.guild.icon .. ".png?size=256", ImageSize = 42, Buttons = { { Icon = "link", Title = "Copy Discord Invite", Callback = function() pcall(function() setclipboard("https://discord.gg/" .. InviteCode) end) end } } }
    if Response.guild.banner then
        pCfg.Thumbnail = "https://cdn.discordapp.com/banners/" .. Response.guild.id .. "/" .. Response.guild.banner .. ".png?size=256"
        pCfg.ThumbnailSize = 80
    end
    aboutTab:Paragraph(pCfg)
else
    aboutTab:Paragraph({ Title = "Error loading Discord info", Desc = ErrorMessage or "Unknown error", Image = "triangle-alert", ImageSize = 26, Color = "Red" })
end

-- Export Tabs to Context and getgenv (Aksesibilitas Antar-Modul)
Context.PlayerTab = PlayerTab
Context.FarmTab = FarmTab
Context.CoopTab = CoopTab
Context.FlockTab = FlockTab
Context.EventTab = EventTab
Context.RewardsTab = RewardsTab
Context.MiscTab = MiscTab
Context.WebhookTab = WebhookTab
Context.aboutTab = aboutTab

if getgenv then
    getgenv().PlayerTab = PlayerTab
    getgenv().FarmTab = FarmTab
    getgenv().CoopTab = CoopTab
    getgenv().FlockTab = FlockTab
    getgenv().EventTab = EventTab
    getgenv().RewardsTab = RewardsTab
    getgenv().MiscTab = MiscTab
    getgenv().WebhookTab = WebhookTab
    getgenv().aboutTab = aboutTab
end


-- ==============================================================================

-- 4. Helper Muat Modul dengan Error Reporting Transparan
local function loadModule(name, path, ...)
    local okImport, modFn = pcall(function() return import(path) end)
    if not okImport or type(modFn) ~= "function" then
        warn("[SysHub Mod ERROR]: Gagal impor " .. name .. ": " .. tostring(modFn))
        return
    end
    local args = {...}
    local okRun, runErr = pcall(function()
        modFn(Context, unpack(args))
    end)
    if not okRun then
        warn("[SysHub Mod RUN ERROR in " .. name .. "]: " .. tostring(runErr))
    else
        print("[SysHub]: Berhasil memuat modul " .. name)
    end
end

-- 5. Muat Seluruh Modul Fitur
loadModule("Player", "modules/player.lua", PlayerTab)
loadModule("Farm", "modules/farm.lua", FarmTab)
loadModule("Coop", "modules/coop.lua", CoopTab)
loadModule("Flock", "modules/flock.lua", FlockTab)
loadModule("Event", "modules/event.lua", EventTab)
loadModule("Rewards", "modules/rewards.lua", RewardsTab)
loadModule("Misc", "modules/misc.lua", MiscTab, WebhookTab)

-- 6. Background Threads & Loops
-- [13] BACKGROUND THREADS & LOOPS
-- ==============================================================================

-- STEALTH ANTI-AFK
do
    local function disableIdleKick()
        local getConn = getconnections or get_signal_cons
        if getConn then
            pcall(function()
                for _, conn in ipairs(getConn(player.Idled)) do
                    if conn.Disable then
                        conn:Disable()
                    elseif conn.Disconnect then
                        conn:Disconnect()
                    end
                end
            end)
        end
    end

    task.spawn(function()
        while isCurrentInstance() do
            pcall(disableIdleKick)
            task.wait(25)
        end
    end)
end

-- STREAMER MODE ENGINE (MASK KARAKTER, BASE PLOT, PLOTSIGN, COOP, & GUI)
local function safeReplace(text, target, repl)
    if not text or text == "" or not target or target == "" then
        return text
    end
    if text == target then
        return repl
    end
    local escapedTarget = target:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
    local ok, res = pcall(function()
        return string.gsub(text, escapedTarget, repl)
    end)
    return ok and res or text
end

local function applyStreamerMode()
    if not streamerMode then
        return
    end

    local pName = player.Name
    local pDisplay = player.DisplayName
    local repl = fakeName or "Anonymous"

    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.DisplayName ~= repl then
            pcall(function()
                hum.DisplayName = repl
            end)
        end
        for _, desc in ipairs(char:GetDescendants()) do
            if desc:IsA("TextLabel") then
                local txt = desc.Text or ""
                if txt == pName or txt == pDisplay or txt:find(pName) or txt:find(pDisplay) then
                    desc.Text = safeReplace(safeReplace(txt, pName, repl), pDisplay, repl)
                end
            end
        end
    end

    -- Papan Base / Plot di Workspace.World.Plots (PlotX.Owner.PlayerName)
    local plots = (Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("Plots")) or Workspace:FindFirstChild("Plots")
    if plots then
        for _, desc in ipairs(plots:GetDescendants()) do
            if desc:IsA("TextLabel") then
                local txt = desc.Text or ""
                if txt == pName or txt == pDisplay or txt:find(pName) or txt:find(pDisplay) then
                    desc.Text = safeReplace(safeReplace(txt, pName, repl), pDisplay, repl)
                end
            end
        end
    end

    local plotSigns = Workspace:FindFirstChild("PlotSigns")
    if plotSigns then
        for _, desc in ipairs(plotSigns:GetDescendants()) do
            if desc:IsA("TextLabel") then
                local txt = desc.Text or ""
                if txt == pName or txt == pDisplay or txt:find(pName) or txt:find(pDisplay) then
                    desc.Text = safeReplace(safeReplace(txt, pName, repl), pDisplay, repl)
                end
            end
        end
    end

    local coops = Workspace:FindFirstChild("Coops")
    if coops then
        for _, desc in ipairs(coops:GetDescendants()) do
            if desc:IsA("TextLabel") then
                local txt = desc.Text or ""
                if txt == pName or txt == pDisplay or txt:find(pName) or txt:find(pDisplay) then
                    desc.Text = safeReplace(safeReplace(txt, pName, repl), pDisplay, repl)
                end
            end
        end
    end

    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        for _, desc in ipairs(playerGui:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Visible then
                local txt = desc.Text or ""
                if txt == pName or txt == pDisplay or txt:find(pName) or txt:find(pDisplay) then
                    desc.Text = safeReplace(safeReplace(txt, pName, repl), pDisplay, repl)
                end
            end
        end
    end

    -- Leaderboard / PlayerList di CoreGui (Kanan Atas)
    pcall(function()
        local pList = CoreGui:FindFirstChild("PlayerList")
        if pList then
            for _, desc in ipairs(pList:GetDescendants()) do
                if desc:IsA("TextLabel") then
                    local txt = desc.Text or ""
                    if txt == pName or txt == pDisplay or txt:find(pName) or txt:find(pDisplay) then
                        desc.Text = safeReplace(safeReplace(txt, pName, repl), pDisplay, repl)
                    end
                end
            end
        else
            for _, desc in ipairs(CoreGui:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Visible then
                    local txt = desc.Text or ""
                    if txt == pName or txt == pDisplay or txt:find(pName) or txt:find(pDisplay) then
                        desc.Text = safeReplace(safeReplace(txt, pName, repl), pDisplay, repl)
                    end
                end
            end
        end
    end)
end

task.spawn(function()
    while isCurrentInstance() do
        if not streamerMode then
            task.wait(2)
        else
            task.wait(1.2)
            pcall(applyStreamerMode)
        end
    end
end)

-- REAL-TIME VISUAL ESP THREAD
task.spawn(function()
    while isCurrentInstance() do
        if not espPlayerEnabled and not espEggEnabled and not espScrapEnabled then
            task.wait(1.5)
        else
            task.wait(0.5)
            local myChar = player.Character
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")

            -- 1. PLAYER ESP
            if espPlayerEnabled then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= player and p.Character then
                        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if hrp and myHrp then
                            local dist = math.floor((hrp.Position - myHrp.Position).Magnitude)
                            local tag = "SysHub_PlayerESP"
                            createESPHighlight(p.Character, Color3.fromRGB(0, 255, 150), Color3.fromRGB(255, 255, 255), tag .. "_HL")
                            createESPBillboard(hrp, string.format("%s\n[%dm]", p.DisplayName, dist), Color3.fromRGB(0, 255, 150), Vector3.new(0, 3, 0), tag .. "_BB")
                        end
                    end
                end
            end

            -- 2. EGG ESP
            if espEggEnabled then
                local nestFolder = Workspace:FindFirstChild("NestEggs")
                if nestFolder and myHrp then
                    for _, egg in ipairs(nestFolder:GetChildren()) do
                        if egg:IsA("BasePart") then
                            local dist = math.floor((egg.Position - myHrp.Position).Magnitude)
                            local tier = tostring(egg:GetAttribute("tier") or "Egg"):upper()
                            local owner = egg:GetAttribute("owner")
                            local isMine = (owner and tonumber(owner) == player.UserId)

                            local eggColor = Color3.fromRGB(255, 255, 255)
                            if tier:find("GOLD") then
                                eggColor = Color3.fromRGB(255, 215, 0)
                            elseif tier:find("CIRCUIT") then
                                eggColor = Color3.fromRGB(0, 255, 255)
                            elseif tier:find("ORDNANCE") then
                                eggColor = Color3.fromRGB(255, 80, 0)
                            end

                            local title = isMine and string.format("[MY EGG: %s]\n%dm", tier, dist) or string.format("[EGG: %s]\n%dm", tier, dist)
                            local tag = "SysHub_EggESP"
                            createESPHighlight(egg, eggColor, Color3.fromRGB(255, 255, 255), tag .. "_HL")
                            createESPBillboard(egg, title, eggColor, Vector3.new(0, 1.5, 0), tag .. "_BB")
                        end
                    end
                end
            end

            -- 3. SCRAP & COIN ESP (Optimized with max 16 Highlights to prevent Roblox engine lag)
            if espScrapEnabled and myHrp then
                local pitFolder = Workspace:FindFirstChild("PitScrap") or (Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("PitScrap"))
                if pitFolder then
                    local hlCount = 0
                    for _, scrap in ipairs(pitFolder:GetChildren()) do
                        if scrap:IsA("BasePart") and scrap.Name == "Loose" then
                            local dist = math.floor((scrap.Position - myHrp.Position).Magnitude)
                            if dist <= 300 then
                                local tier = tostring(scrap:GetAttribute("StackTier") or "Scrap"):upper()
                                local kind = tostring(scrap:GetAttribute("StackKind") or "scrap")

                                local sColor = Color3.fromRGB(0, 200, 255)
                                if kind == "goldCoin" or tier:find("GOLD") then
                                    sColor = Color3.fromRGB(255, 215, 0)
                                elseif tier:find("SILVER") then
                                    sColor = Color3.fromRGB(210, 210, 230)
                                elseif tier:find("BRONZE") then
                                    sColor = Color3.fromRGB(205, 127, 50)
                                end

                                local labelTxt = (kind == "goldCoin") and string.format("[GOLD COIN]\n%dm", dist) or string.format("[%s SCRAP]\n%dm", tier, dist)
                                local tag = "SysHub_ScrapESP"
                                if hlCount < 16 and dist <= 100 then
                                    createESPHighlight(scrap, sColor, Color3.fromRGB(255, 255, 255), tag .. "_HL")
                                    hlCount = hlCount + 1
                                end
                                createESPBillboard(scrap, labelTxt, sColor, Vector3.new(0, 1, 0), tag .. "_BB")
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- AUTO PROMOTE ENGINE (STATUS & SUCCESS DRIVEN - ANTI-SPAM & CRASH PROOF)
task.spawn(function()
    local isPromoteRunning = false
    while isCurrentInstance() do
        task.wait(3)
        if autoPromote and not isPromoteRunning and not (UpdateHub.isUfoPriorityActive() or UpdateHub.isBossPriorityActive()) then
            isPromoteRunning = true
            local success, ok, msg = pcall(executePromoteSelectedSpecies)
            if success and ok then
                autoPromote = false
                pcall(function()
                    if autoPromoteToggle and type(autoPromoteToggle.Set) == "function" then
                        autoPromoteToggle:Set(false)
                    end
                end)
                notify("Auto Promote", tostring(msg) .. " (Auto Promote dinonaktifkan demi keamanan)")
                printLog("Auto Promote", "Sukses: " .. tostring(msg))
            end
            isPromoteRunning = false
        end
    end
end)

-- AUTO FUSE ENGINE (EVENT & STATUS DRIVEN - DENGAN NOTIFIKASI)
task.spawn(function()
    while isCurrentInstance() do
        task.wait(2)
        if autoFuse and not (UpdateHub.isUfoPriorityActive() or UpdateHub.isBossPriorityActive()) then
            if fuseMainChickenName and fuseFodderChickenName and chickenMap[fuseMainChickenName] and chickenMap[fuseFodderChickenName] and fuseMainChickenName ~= fuseFodderChickenName then
                local ok, msg = executeFuseChickens()
                if ok then
                    notify("Auto Fuse", "Berhasil menggabungkan ayam (" .. tostring(fuseMainChickenName) .. ")!")
                    printLog("Auto Fuse", "Penggabungan ayam berhasil dengan skill lock: " .. tostring(fuseLockedSkill))
                end
            end
        end
    end
end)

-- AUTO SELL LOOP
task.spawn(function()
    while isCurrentInstance() do
        task.wait(2)
        if autoSellChickens and not (UpdateHub.isUfoPriorityActive() or UpdateHub.isBossPriorityActive()) then
            pcall(function()
                executeSellChickens(false)
            end)
        end
    end
end)

-- AUTO UPGRADE INCUBATOR LOOP
task.spawn(function()
    while isCurrentInstance() do
        task.wait(delayUpgradeIncubator)
        if autoUpgradeIncubator then
            invokeRemote("IncubatorUpgrade")
            invokeRemote("IncubatorUpgrade", 1)
        end
    end
end)

-- AUTO COLLECT NEST EGGS (DETEKSI OTOMATIS)
task.spawn(function()
    local nestFolder = Workspace:WaitForChild("NestEggs", 10) or Workspace:FindFirstChild("NestEggs")
    if nestFolder then
        nestFolder.ChildAdded:Connect(function(child)
            if autoCollectNestEggs then
                task.wait(0.15)
                pcall(function()
                    local char = player.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then
                        return
                    end
                    local owner = child:GetAttribute("owner")
                    if owner and tonumber(owner) == player.UserId then
                        local targetPart = child:IsA("BasePart") and child or (child:FindFirstChildWhichIsA("BasePart") or child.PrimaryPart)
                        if targetPart and firetouchinterest then
                            firetouchinterest(hrp, targetPart, 0)
                            task.wait(0.02)
                            firetouchinterest(hrp, targetPart, 1)
                        end
                        local prompt = child:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            pcall(function()
                                fireproximityprompt(prompt)
                            end)
                        end
                        printLog("Auto Collect Egg", "Telur baru terdeteksi di sarang! Berhasil diambil ke tas.")
                    end
                end)
            end
        end)
    end

    while isCurrentInstance() do
        task.wait(2)
        if autoCollectNestEggs then
            local count = collectMyNestEggs(false)
            if count > 0 then
                printLog("Auto Collect Egg", count .. " telur terdeteksi di sarang & berhasil diambil.")
            end
        end
    end
end)

-- AUTO FARM INCUBATOR CLAIM & PUT
task.spawn(function()
    while isCurrentInstance() do
        task.wait(2)
        if autoClaimIncubator then
            invokeRemote("IncubatorClaim")
            invokeRemote("IncubatorClaim", 1)
        end
    end
end)

task.spawn(function()
    while isCurrentInstance() do
        task.wait(2.5)
        if autoPutIncubator and selectedChickenId then
            pcall(function()
                local plotIdAttr = player:GetAttribute("Plot")
                local plotId = (type(plotIdAttr) == "number" and plotIdAttr) or 1
                local myInc = Workspace:FindFirstChild("Incubators") and Workspace.Incubators:FindFirstChild("Incubator" .. tostring(plotId))
                local occ = myInc and myInc:GetAttribute("Occupant")
                if not occ or occ == "" or occ == "{}" or occ == "none" then
                    invokeRemote("IncubatorInsert", selectedChickenId)
                    invokeRemote("IncubatorInsert", 1, selectedChickenId)
                end
            end)
        end
    end
end)

-- AUTO CLAIM REWARDS BACKGROUND LOOP (AMAN & ANTI-CRASH)
task.spawn(function()
    while isCurrentInstance() do
        task.wait(20)
        pcall(function()
            if UpdateHub.autoClaimCharmDust then
                UpdateHub.executeClaimCharmDust()
                task.wait(0.5)
            end
            if UpdateHub.autoClaimMilestones then
                UpdateHub.executeClaimMilestones()
                task.wait(0.5)
            end
            if UpdateHub.autoClaimArena then
                UpdateHub.executeClaimArena()
                task.wait(0.5)
            end
            if UpdateHub.autoClaimDailyStreak then
                UpdateHub.executeClaimDailyStreak()
                task.wait(0.5)
            end
            if UpdateHub.autoClaimPlayToday then
                UpdateHub.executeClaimPlayToday()
                task.wait(0.5)
            end
            if UpdateHub.autoClaimMission then
                UpdateHub.executeClaimMission()
                task.wait(0.5)
            end
            if UpdateHub.autoClaimIndex then
                UpdateHub.executeClaimIndexMilestones()
                task.wait(0.5)
            end
        end)
    end
end)

-- COOP UPGRADE LOOPS
task.spawn(function()
    while isCurrentInstance() do
        if not autoUpgradeCoop and not autoUpgradeRecycler then
            task.wait(1)
        else
            task.wait(0.1)
            if autoUpgradeCoop then
                invokeRemote("ExpandCoop")
                if delayCoop > 0 then
                    task.wait(delayCoop)
                end
            end
            if autoUpgradeRecycler then
                invokeRemote("UpgradeRecycler")
                if delayRecycler > 0 then
                    task.wait(delayRecycler)
                end
            end
        end
    end
end)

-- ==============================================================================
-- CONTINUOUS LIVE MONITOR UPDATER (REAL-TIME HEARTBEAT UNTUK SEMUA AKUN)
-- ==============================================================================
task.spawn(function()
    local lastMonitorDesc = ""
    while isCurrentInstance() do
        if not autoFastRebirth then
            task.wait(1.5)
        else
            task.wait(0.35)
        end
        local ok, err = pcall(function()
            if updateFastRebirthStatus then
                local myFloor = getCurrentFloor()
                local rbCount = getRebirthCount()
                local rbReq = getRebirthRequirement()

                local targetRetreatFloor = fastTargetFloor or 25
                if fastFloorOverride and fastFloorOverride > 0 then
                    targetRetreatFloor = fastFloorOverride
                elseif rbReq.Required and rbReq.Required > 0 then
                    targetRetreatFloor = rbReq.Required
                end

                local countStr = "#" .. tostring(rbCount or 0)
                local reqStr = rbReq.DisplayStatus
                if (myFloor >= targetRetreatFloor and myFloor > 0) or (rbReq.IsReady and myFloor > 0) then
                    reqStr = string.format("Floor %d / %d (READY!)", myFloor, targetRetreatFloor)
                elseif targetRetreatFloor > 0 then
                    reqStr = string.format("Floor %d / %d (Kurang %d Floor)", myFloor, targetRetreatFloor, math.max(0, targetRetreatFloor - myFloor))
                else
                    reqStr = string.format("Floor %d / Target %d", myFloor, targetRetreatFloor)
                end

                local monitorDesc = string.format(
                    "Status: %s\n\n" ..
                    "[ INFO REBIRTH ]\n" ..
                    "• Rebirth Saat Ini : %s\n" ..
                    "• Syarat Rebirth   : %s\n\n" ..
                    "[ TOWER SAYA ]\n" ..
                    "• Lantai Tower     : Floor %d (Target: %d)",
                    fastRebirthCurrentAction,
                    countStr,
                    reqStr,
                    myFloor,
                    targetRetreatFloor
                )
                if monitorDesc ~= lastMonitorDesc then
                    lastMonitorDesc = monitorDesc
                    updateFastRebirthStatus("Live Monitor", monitorDesc)
                end
            end
        end)
        
        if not ok and updateFastRebirthStatus then
            if lastMonitorDesc ~= "ERROR_STATE" then
                lastMonitorDesc = "ERROR_STATE"
                updateFastRebirthStatus("Live Monitor CRASHED!", "Tolong kirimkan error ini ke AI:\n\n" .. tostring(err))
            end
        end
    end
end)

-- ==============================================================================
-- THREAD FAST REBIRTH (INTELLIGENT SPEED-FARMING WITH TOWER & FEEDER)
-- ==============================================================================
task.spawn(function()
    local lastTowerEntryTime = 0
    local isRetreating = false
    local lastRebirthTime = 0
    local lastRebirthedCount = nil

    while isCurrentInstance() do
        if not autoFastRebirth then
            task.wait(1.5)
        else
            task.wait(0.35)
        end

        local mainOk, mainErr = pcall(function()
            if autoFastRebirth then
                if UpdateHub.isUfoPriorityActive() or UpdateHub.isBossPriorityActive() then
                    local activePriorityEvent = UpdateHub.isBossPriorityActive() and "Chicken Boss" or "UFO Invasion"
                    fastRebirthCurrentAction = "JEDA: Prioritas Event " .. activePriorityEvent .. " sedang aktif!"
                    task.wait(1)
                    return
                end

                local myFloor = getCurrentFloor()
                local rbCount = getRebirthCount()
                local targetRetreatFloor = getExactRebirthRequirement(rbCount)
                if fastFloorOverride and fastFloorOverride > 0 then
                    targetRetreatFloor = fastFloorOverride
                end
                fastTargetFloor = targetRetreatFloor

                -- 1. TAHAP COOP & FEEDER DI BASE
                local curCoop, feederLevels, feederCount = getCoopAndFeederStats()

                -- Auto Upgrade Coop sampai mencapai target
                if fastAutoUpgradeCoop and curCoop < fastTargetCoop then
                    invokeRemote("ExpandCoop")
                end

                -- Auto Beli & Upgrade Feeder sampai mencapai target jumlah dan level
                if fastAutoUpgradeFeeder then
                    for fId = 1, fastTargetFeederCount do
                        if not feederLevels[fId] then
                            invokeRemote("BuyGenerator", fId)
                        end
                        local curLvl = feederLevels[fId] or 0
                        if curLvl < fastTargetFeederLevel then
                            invokeRemote("UpgradeGenerator", fId)
                        end
                    end
                end

                -- 2. CEK INISIALISASI AWAL (Jika baru diaktifkan di base dan syarat sudah tercapai)
                if lastRebirthedCount == nil then
                    if myFloor >= targetRetreatFloor and myFloor > 0 and isChickenAtBase(true) then
                        fastRebirthCurrentAction = "Syarat Rebirth awal sudah terpenuhi di Base! Mengeksekusi Rebirth..."
                        local beforeCount = rbCount
                        invokeRemote("Rebirth")
                        lastRebirthTime = tick()
                        lastRebirthedCount = beforeCount
                        liveRebirthCount = math.max(liveRebirthCount, beforeCount + 1)
                        triggerWebhookRebirthEvent(liveRebirthCount)
                        task.wait(2.0)
                        return
                    else
                        lastRebirthedCount = rbCount
                    end
                end

                local atBase = isChickenAtBase()
                local cStatus = getChickenStatus()
                local hpPercent = math.floor((cStatus.HpFrac or 0) * 100)
                local hpThresholdFrac = (towerHpThreshold or 100) / 100

                -- STATE A: AYAM SEDANG DI BASE
                if atBase then
                    isRetreating = false

                    -- Jika ayam masih di luar pagar coop, arahkan masuk
                    local distToCoop = getChickenDistanceToCoop()
                    if distToCoop and distToCoop > 20 then
                        UpdateHub.returnChickenToCoop()
                    end

                    -- Jika darah ayam sudah mencapai threshold HP, masuk ke Tower
                    if cStatus.IsAlive and cStatus.HpFrac >= hpThresholdFrac and (tick() - lastTowerEntryTime > 4) and (tick() - lastRebirthTime > 3) then
                        lastTowerEntryTime = tick()
                        local targetFloor
                        if towerStartMode == "Mulai dari Lantai 1" then
                            targetFloor = 1
                        else
                            targetFloor = (myFloor > 0 and myFloor) or 1
                        end
                        fastRebirthCurrentAction = string.format("Ayam siap (HP %d%%)! Memasuki Tower (Lantai %d ➔ Target: %d)...", hpPercent, targetFloor, targetRetreatFloor)

                        task.spawn(function()
                            invokeRemote("TowerElevator", math.floor(targetFloor))
                            task.wait(0.5)
                            invokeRemote("TowerStart")
                        end)
                        task.wait(5) -- Beri jeda 5 detik agar ayam masuk ke Tower
                    elseif cStatus.IsAlive and cStatus.HpFrac < hpThresholdFrac then
                        fastRebirthCurrentAction = string.format("Ayam di Base memulihkan HP (%d%% / %d%%)...", hpPercent, towerHpThreshold)
                    else
                        fastRebirthCurrentAction = "Ayam di Base bersiap memasuki Tower..."
                    end

                -- STATE B: AYAM SEDANG DI DALAM TOWER
                else
                    dismissTowerKOUI()

                    -- Jika ayam KO di dalam tower
                    if not cStatus.IsAlive or cStatus.HpFrac <= 0 then
                        invokeRemote("TowerContinueDecline")
                        dismissTowerKOUI()
                        fastRebirthCurrentAction = string.format("Ayam KO di Tower (Tolak Revive Robux) — Tunggu HP pulih ke %d%%", towerHpThreshold)
                        task.wait(1)

                    -- Target Lantai Tercapai saat Ayam di Tower -> Retreat & Rebirth Seketika di Base
                    elseif myFloor >= targetRetreatFloor and myFloor > 0 then
                        isRetreating = true
                        fastRebirthCurrentAction = string.format("Target Floor %d Tercapai! Mengirim perintah Retreat...", targetRetreatFloor)

                        -- Surrender dari tower
                        invokeRemote("TowerSurrender")
                        task.wait(0.5)

                        -- Tunggu ayam berjalan kembali dari tower ke base sampai BENAR-BENAR masuk ke dalam pagar Coop (jarak <= 20 stud)
                        local waitArrive = 0
                        local maxWaitSteps = 90 -- Maksimal 45 detik (90 * 0.5s)
                        local enteredCoop = false

                        while waitArrive < maxWaitSteps do
                            task.wait(0.5)
                            waitArrive = waitArrive + 1

                            local dist = getChickenDistanceToCoop()
                            local distStr = ""
                            if dist then
                                distStr = string.format(" (Sisa Jarak: %d stud)", math.floor(dist))
                            end
                            fastRebirthCurrentAction = "Ayam sedang berjalan kembali ke Coop..." .. distStr

                            -- Ayam HANYA dianggap telah masuk jika jarak fisik <= 20 stud dari pusat kandang!
                            if dist and dist <= 20 then
                                enteredCoop = true
                                break
                            end
                        end

                        -- Beri jeda 1.5 detik agar ayam stabil berada di dalam kandang sebelum mengeksekusi Rebirth
                        fastRebirthCurrentAction = "Ayam telah sampai di dalam Coop! Menstabilkan posisi..."
                        task.wait(1.5)

                        -- Begitu ayam BENAR-BENAR tiba di dalam kandang, eksekusi Rebirth!
                        fastRebirthCurrentAction = "Ayam telah berada di dalam Coop! Mengeksekusi Rebirth..."
                        local beforeCount = getRebirthCount()
                        invokeRemote("Rebirth")
                        lastRebirthTime = tick()

                        -- Tunggu server memproses rebirth
                        local waitCount = 0
                        while waitCount < 12 do
                            task.wait(0.25)
                            waitCount = waitCount + 1
                            if getRebirthCount() > beforeCount then
                                break
                            end
                        end

                        liveRebirthCount = math.max(liveRebirthCount, beforeCount + 1)
                        lastRebirthedCount = liveRebirthCount
                        triggerWebhookRebirthEvent(liveRebirthCount)
                        isRetreating = false
                        fastRebirthCurrentAction = "Rebirth Sukses! Menyiapkan siklus berikutnya..."
                        task.wait(1.5)

                    -- Sedang memanjat tower
                    else
                        local distToCoop = getChickenDistanceToCoop()
                        if not cStatus.InBattle and (distToCoop and distToCoop <= 55) then
                            fastRebirthCurrentAction = "Ayam di luar Coop, mengarahkan masuk ke dalam Coop..."
                            UpdateHub.returnChickenToCoop()
                            task.wait(0.5)
                        else
                            fastRebirthCurrentAction = string.format("Memanjat Tower: Lantai %d / %d (HP: %d%%)", myFloor, targetRetreatFloor, hpPercent)
                        end
                    end
                end
            end
        end)

        if not mainOk then
            logError("Fast Rebirth Thread", mainErr)
        end
    end
end)

task.spawn(function()
    while isCurrentInstance() do
        if not autoBuyFeeder then
            task.wait(1)
        else
            task.wait(0.1)
            for id = 1, MAX_FEEDER_SLOTS do
                if not autoBuyFeeder then
                    break
                end
                invokeRemote("BuyGenerator", id)
                if delayBuy > 0 then
                    task.wait(delayBuy)
                end
            end
            task.wait(0.5)
        end
    end
end)

task.spawn(function()
    while isCurrentInstance() do
        if not autoUpgradeFeeder then
            task.wait(1)
        else
            task.wait(0.1)
            for id = 1, MAX_FEEDER_SLOTS do
                if not autoUpgradeFeeder then
                    break
                end
                invokeRemote("UpgradeGenerator", id)
                if delayUpgrade > 0 then
                    task.wait(delayUpgrade)
                end
            end
            task.wait(0.5)
        end
    end
end)

-- ==============================================================================
-- [14] THREAD AUTO TOWER (DENGAN SISTEM HP THRESHOLD & AUTO RESEND)
-- ==============================================================================
task.spawn(function()
    local towerLastSendTime = 0
    local towerWaitingForHeal = false
    local towerKOCount = 0

    while isCurrentInstance() do
        if not autoTower then
            towerWaitingForHeal = false
            towerKOCount = 0
            task.wait(1.5)
        else
            task.wait(1)
            if UpdateHub.isUfoPriorityActive() or UpdateHub.isBossPriorityActive() then
                task.wait(1)
            else
                local currentFloor = getCurrentFloor()
                local cStatus = getChickenStatus()
                local hpPercent = math.floor((cStatus.HpFrac or 0) * 100)
                local hpThresholdFrac = (towerHpThreshold or 100) / 100

                -- ============================================
                -- STATE 1: AYAM KO (Mati di Tower)
                -- ============================================
                if not cStatus.IsAlive or cStatus.HpFrac <= 0 then
                    invokeRemote("TowerContinueDecline")
                    dismissTowerKOUI()
                    towerKOCount = towerKOCount + 1
                    towerWaitingForHeal = true
                    printLog("Auto Tower", string.format("Ayam KO! (KO ke-%d) Menunggu HP pulih ke %d%% untuk kirim ulang...", towerKOCount, towerHpThreshold))
                    task.wait(1.5)

                -- ============================================
                -- STATE 2: TARGET RETREAT FLOOR TERCAPAI
                -- ============================================
                elseif currentFloor >= retreatFloor and retreatFloor > 0 then
                    printLog("Auto Tower", string.format("Target floor %d tercapai! (Current: %d) Retreat...", retreatFloor, currentFloor))
                    task.spawn(function()
                        invokeRemote("TowerSurrender")
                    end)
                    towerWaitingForHeal = true
                    printLog("Auto Tower", string.format("Retreat selesai. Menunggu HP pulih ke %d%% untuk ronde baru...", towerHpThreshold))
                    task.wait(3)

                -- ============================================
                -- STATE 3: MENUNGGU HP PULIH (Setelah KO/Retreat)
                -- ============================================
                elseif towerWaitingForHeal then
                    if cStatus.IsAlive and cStatus.HpFrac >= hpThresholdFrac then
                        -- HP sudah mencapai threshold! Kirim ayam ke tower lagi
                        towerWaitingForHeal = false
                        printLog("Auto Tower", string.format("HP sudah %d%% (>= %d%%)! Mengirim ayam ke Tower...", hpPercent, towerHpThreshold))

                        local targetFloor
                        if towerStartMode == "Mulai dari Lantai 1" then
                            targetFloor = 1
                        else
                            -- Lanjut dari lantai tertinggi
                            targetFloor = (currentFloor > 0 and currentFloor) or 1
                        end

                        towerLastSendTime = tick()
                        task.spawn(function()
                            invokeRemote("TowerElevator", math.floor(targetFloor))
                            task.wait(0.5)
                            invokeRemote("TowerStart")
                        end)
                        notify("Auto Tower", string.format("Ayam dikirim ke Tower! Lantai %d | HP: %d%%", targetFloor, hpPercent))
                        task.wait(6)
                    else
                        -- Masih menunggu HP pulih
                        if tick() % 10 < 1.5 then
                            printLog("Auto Tower", string.format("Menunggu HP pulih: %d%% / %d%%", hpPercent, towerHpThreshold))
                        end
                    end

                -- ============================================
                -- STATE 4: AYAM SIAP & HP CUKUP (Kirim ke Tower)
                -- ============================================
                elseif cStatus.IsAlive and cStatus.HpFrac >= hpThresholdFrac then
                    if (tick() - towerLastSendTime) > 5 then
                        local targetFloor
                        if towerStartMode == "Mulai dari Lantai 1" then
                            targetFloor = 1
                        else
                            targetFloor = (currentFloor > 0 and currentFloor) or 1
                        end

                        towerLastSendTime = tick()
                        printLog("Auto Tower", string.format("HP %d%% >= %d%%. Masuk Tower lantai %d", hpPercent, towerHpThreshold, targetFloor))

                        task.spawn(function()
                            invokeRemote("TowerElevator", math.floor(targetFloor))
                            task.wait(0.5)
                            invokeRemote("TowerStart")
                        end)

                        task.wait(6)
                    end

                -- ============================================
                -- STATE 5: AYAM HIDUP TAPI HP BELUM CUKUP
                -- ============================================
                elseif cStatus.IsAlive and cStatus.HpFrac < hpThresholdFrac then
                    if not towerWaitingForHeal then
                        towerWaitingForHeal = true
                    end
                end
            end
        end
    end
end)

-- ==============================================================================
-- [15] THREAD AUTO SWEEP & DEPOSIT RECYCLER
-- ==============================================================================
task.spawn(function()
    while isCurrentInstance() do
        local shouldSweep = autoSweep and not (UpdateHub.isUfoPriorityActive() or UpdateHub.isBossPriorityActive())
        if not shouldSweep then
            task.wait(1)
        else
            task.wait(0.15)
            local loopOk, loopErr = pcall(function()
                if shouldSweep and not isSweepRunning then
                    isSweepRunning = true
                    local character = player.Character
                    local hrp = character and character:FindFirstChild("HumanoidRootPart")

                    if hrp then
                        local availableScraps = {}
                        local pitFolder = Workspace:FindFirstChild("PitScrap") or (Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("PitScrap"))
                        local scrapCandidates = (pitFolder and pitFolder:GetChildren()) or Workspace:GetChildren()

                        for _, obj in ipairs(scrapCandidates) do
                            local isScrap, stackKind = false, obj:GetAttribute("StackKind")
                            if obj.Name == "Loose" and obj.Parent and obj.Parent.Name == "PitScrap" then
                                isScrap = true
                            elseif stackKind == "scrap" or stackKind == "goldCoin" then
                                isScrap = true
                            elseif obj:GetAttribute("CarryAttr") == "scrapCarry" then
                                isScrap = true
                            elseif obj.Name == "Part" and obj.Parent and obj.Parent.Name == "PitScrap" and stackKind then
                                isScrap = true
                            elseif obj:IsA("ProximityPrompt") and (obj.Parent.Name:lower():find("scrap") or obj.Parent.Name:lower():find("coin") or obj.Parent.Name:lower():find("item")) then
                                isScrap = true
                            end

                            if isScrap and not isHeldBySomeone(obj) then
                                local targetPart = obj:IsA("ProximityPrompt") and obj.Parent or obj
                                local targetPos = targetPart:IsA("Model") and targetPart:GetPivot().Position or targetPart.Position
                                local distFromPlayer = (Vector3.new(targetPos.X, 0, targetPos.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude

                                if distFromPlayer <= 150 then
                                    table.insert(availableScraps, targetPart)
                                end
                            end
                        end

                    if #availableScraps > 0 then
                        while autoSweep and not (UpdateHub.isUfoPriorityActive() or UpdateHub.isBossPriorityActive()) and #availableScraps > 0 do
                            local currentCarry = getRealBackpackCount(character)

                            if currentCarry >= MAX_CAPACITY then
                                local recycler = findMyRecycler()
                                if recycler then
                                    local recPos = recycler:IsA("Model") and recycler:GetPivot().Position or recycler.Position
                                    printLog("Auto Sweep", "Tas penuh (20 Scrap). Bergerak menuju Recycler...")

                                    safeWalkTo(recPos, 5, false)

                                    local currentDist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(recPos.X, 0, recPos.Z)).Magnitude

                                    if currentDist <= 8 then
                                        printLog("Auto Sweep", "Tiba di Recycler (Jarak: " .. string.format("%.1f", currentDist) .. " stud). Memulai proses Deposit...")

                                        invokeRemote("ScrapDeposited")

                                        local prompt = recycler:FindFirstChildWhichIsA("ProximityPrompt", true)
                                        if not prompt and recycler.Parent then
                                            prompt = recycler.Parent:FindFirstChildWhichIsA("ProximityPrompt", true)
                                        end
                                        if prompt then
                                            pcall(function()
                                                fireproximityprompt(prompt)
                                            end)
                                        end

                                        if firetouchinterest then
                                            pcall(function()
                                                firetouchinterest(hrp, recycler, 0)
                                                task.wait(0.05)
                                                firetouchinterest(hrp, recycler, 1)
                                            end)
                                        end

                                        local waitDepositTime = 0
                                        while waitDepositTime < 1.5 do
                                            task.wait(0.15)
                                            waitDepositTime = waitDepositTime + 0.15
                                            local carryNow = getRealBackpackCount(character)
                                            if carryNow < currentCarry then
                                                printLog("Auto Sweep", "Scrap berhasil masuk ke Recycler!")
                                                break
                                            end
                                        end

                                        local waitEmpty = 0
                                        while character and getRealBackpackCount(character) > 0 and waitEmpty < 2 do
                                            task.wait(0.2)
                                            waitEmpty = waitEmpty + 0.2
                                        end
                                        break
                                    else
                                        printLog("Auto Sweep", "Masih dalam perjalanan ke Recycler (Jarak: " .. math.floor(currentDist) .. " stud)...")
                                        task.wait(0.5)
                                    end
                                else
                                    logError("Auto Sweep", "Recycler pemain tidak ditemukan saat tas penuh!")
                                    task.wait(1)
                                    break
                                end
                            end

                            local nearestScrap, idx = getNearestScrap(hrp.Position, availableScraps)
                            if nearestScrap then
                                table.remove(availableScraps, idx)
                                local targetPos = nearestScrap:IsA("Model") and nearestScrap:GetPivot().Position or nearestScrap.Position
                                local walkStatus = safeWalkTo(targetPos, 3, true)

                                if walkStatus ~= "FULL" and autoSweep then
                                    fireCollectEvents(nearestScrap, hrp)
                                    task.wait(0.05)
                                end
                            else
                                break
                            end
                        end
                    else
                        task.wait(0.4)
                    end
                else
                    logError("Auto Sweep", "HumanoidRootPart tidak ada saat melakukan Sweep!")
                end
                isSweepRunning = false
            end
        end)

        if not loopOk then
            logError("Auto Sweep Main Thread", loopErr)
            isSweepRunning = false
        end
        end
    end
end)

-- ==============================================================================
-- [15] BACKGROUND LOOPS UNTUK FITUR UPDATE BARU
-- ==============================================================================
task.spawn(function()
    while isCurrentInstance() do
        task.wait(UpdateHub.delayArenaFight > 0 and UpdateHub.delayArenaFight or 3.0)
        if UpdateHub.autoArenaFight and not (UpdateHub.isUfoPriorityActive() or UpdateHub.isBossPriorityActive()) then
            UpdateHub.executeArenaAutoFight()
        end
    end
end)

task.spawn(function()
    while isCurrentInstance() do
        if not UpdateHub.autoRollCharms then
            task.wait(1.5)
        else
            task.wait(0.5)
            UpdateHub.executeAutoRollCharms()
        end
    end
end)


task.spawn(function()
    while isCurrentInstance() do
        if not UpdateHub.autoUfoEvent then
            if UpdateHub.previousActiveChickenId then
                pcall(function()
                    if UpdateHub.handleUfoEventEnded then
                        UpdateHub.handleUfoEventEnded()
                    end
                end)
            end
            UpdateHub.ufoChickenStatus = "AT_BASE"
            UpdateHub.lastChaosEntryTime = nil
            task.wait(1.5)
        else
            task.wait(1.0)
            local isLive = UpdateHub.isUfoEventActive()
            local now = os.clock()

            -- Double guard: jika baru saja selesai <60s yang lalu, paksa isLive = false
            if isLive and UpdateHub.lastUfoEndedTimestamp and (now - UpdateHub.lastUfoEndedTimestamp < 60) then
                isLive = false
            end

            if isLive then
                local loc = UpdateHub.getChickenUfoLocation()

                if loc == "IN_CHAOS" then
                    UpdateHub.ufoChickenStatus = "IN_CHAOS"
                    -- Watchdog Anti-Stuck di Arena Pit Tengah
                    if not UpdateHub.lastChaosEntryTime then
                        UpdateHub.lastChaosEntryTime = now
                    else
                        local timeInChaos = now - UpdateHub.lastChaosEntryTime
                        if timeInChaos > 25 and (now - (UpdateHub.lastUfoNudgeTime or 0) > 10) then
                            UpdateHub.lastUfoNudgeTime = now
                            printLog("Auto UFO Event", string.format("Watchdog: Ayam terdeteksi idle di arena pit selama %.1f detik. Mengirim ulang sinyal Chaos...", timeInChaos))
                            pcall(function()
                                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                                if remotes and remotes:FindFirstChild("SetChickenOrder") then
                                    remotes.SetChickenOrder:FireServer("chaos")
                                else
                                    invokeRemote("SetChickenOrder", "chaos")
                                end
                            end)
                        end
                        if timeInChaos > 40 then
                            printLog("Auto UFO Event", "Watchdog: Ayam stuck parah di arena pit (>40 detik)! Memerintahkan reset via Retreat...")
                            UpdateHub.returnChickenToCoop()
                            task.wait(0.5)
                            UpdateHub.ufoChickenStatus = "AT_BASE"
                            UpdateHub.lastChaosEntryTime = nil
                            UpdateHub.lastUfoSendTime = 0
                        end
                    end

                elseif loc == "BEAM_UPGRADING" then
                    -- Ayam sedang terkena proses upgrade beam di arena pit
                    UpdateHub.ufoChickenStatus = "WAITING_RESPAWN"
                    UpdateHub.lastChaosEntryTime = nil

                else
                    -- Status AT_BASE, RESPAWNING, atau IN_TRANSIT
                    UpdateHub.lastChaosEntryTime = nil
                    local canSend = (UpdateHub.ufoChickenStatus == "WAITING_RESPAWN")
                        or (UpdateHub.ufoChickenStatus == "IN_CHAOS")
                        or (UpdateHub.ufoChickenStatus == "AT_BASE")
                        or (loc == "AT_BASE")
                        or (now - (UpdateHub.lastUfoSendTime or 0) > 12)

                    -- Cooldown minimal 3 detik sejak kirim terakhir agar tidak spam order saat ayam mulai lari dari base
                    if canSend and (now - (UpdateHub.lastUfoSendTime or 0) >= 5) then
                        printLog("Auto UFO Event", "Event UFO sedang aktif! Mengirim ayam target ke arena tengah...")
                        UpdateHub.executeSendChickenToUfoBeam(true)
                        UpdateHub.ufoChickenStatus = "IN_TRANSIT"
                        UpdateHub.lastUfoSendTime = now
                    end
                end
            else
                -- Event UFO sedang tidak aktif (atau baru saja selesai)
                UpdateHub.lastChaosEntryTime = nil
                if UpdateHub.previousActiveChickenId or (UpdateHub.ufoChickenStatus and UpdateHub.ufoChickenStatus ~= "AT_BASE") then
                    pcall(function()
                        if UpdateHub.handleUfoEventEnded then
                            UpdateHub.handleUfoEventEnded()
                        end
                    end)
                else
                    -- Terus perbarui data ayam aktif pemain selama di luar event agar snapshot selalu akurat
                    pcall(function()
                        local curId, curName = UpdateHub.getCurrentActiveChicken()
                        local ufoName = UpdateHub.selectedUfoChickenName
                        local ufoData = ufoName and chickenMap and chickenMap[ufoName]
                        local ufoId = ufoData and ufoData.Id
                        if curId and (not ufoId or tostring(curId) ~= tostring(ufoId)) then
                            UpdateHub.lastKnownNonUfoChickenId = curId
                            UpdateHub.lastKnownNonUfoChickenName = curName or tostring(curId)
                        end
                    end)
                end
                task.wait(1.0)
            end
        end
    end
end)

-- [15B] BACKGROUND LOOP FITUR AUTO CHICKEN BOSS EVENT
task.spawn(function()
    while isCurrentInstance() do
        if not UpdateHub.autoBossEvent then
            if UpdateHub.previousActiveChickenIdBoss then
                pcall(function()
                    if UpdateHub.handleBossEventEnded then
                        UpdateHub.handleBossEventEnded()
                    end
                end)
            end
            UpdateHub.bossChickenStatus = "AT_BASE"
            UpdateHub.lastBossChaosEntryTime = nil
            pcall(function()
                if UpdateHub.bossStatusParagraph and UpdateHub.bossStatusParagraph.SetDesc then
                    UpdateHub.bossStatusParagraph:SetDesc("Status: Auto Boss Nonaktif (Standby)")
                end
            end)
            task.wait(1.5)
        else
            task.wait(0.35)
            local isLive = UpdateHub.isBossEventActive()
            local now = os.clock()

            if isLive and UpdateHub.lastBossEndedTimestamp and (now - UpdateHub.lastBossEndedTimestamp < 45) then
                isLive = false
            end

            pcall(function()
                if UpdateHub.bossStatusParagraph and UpdateHub.bossStatusParagraph.SetDesc then
                    local bossModel = UpdateHub.findPitBoss()
                    local statusDesc = isLive and "⚔️ BOSS SEDANG AKTIF DI PIT!" or "⏳ Menunggu Event Boss Muncul..."
                    local targetChicken = UpdateHub.selectedBossChickenName or "Ayam Terpilih"
                    UpdateHub.bossStatusParagraph:SetDesc(string.format("Status: %s\nAyam Boss Killer: %s\nBoss Model: %s\nStatus Ayam: %s",
                        statusDesc,
                        tostring(targetChicken),
                        bossModel and bossModel.Name or (isLive and "Terdeteksi via Signal" or "Tidak Ada"),
                        tostring(UpdateHub.bossChickenStatus or "AT_BASE")
                    ))
                end
            end)

            if isLive then
                local loc = UpdateHub.getChickenUfoLocation()

                if loc == "IN_CHAOS" then
                    UpdateHub.bossChickenStatus = "IN_CHAOS"
                    if not UpdateHub.lastBossChaosEntryTime then
                        UpdateHub.lastBossChaosEntryTime = now
                    else
                        local timeInChaos = now - UpdateHub.lastBossChaosEntryTime
                        if timeInChaos > 25 and (now - (UpdateHub.lastBossNudgeTime or 0) > 10) then
                            UpdateHub.lastBossNudgeTime = now
                            printLog("Auto Boss Event", string.format("Watchdog: Ayam menyerang boss di pit selama %.1f detik. Me-refresh sinyal Chaos...", timeInChaos))
                            pcall(function()
                                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                                if remotes and remotes:FindFirstChild("SetChickenOrder") then
                                    remotes.SetChickenOrder:FireServer("chaos")
                                else
                                    invokeRemote("SetChickenOrder", "chaos")
                                end
                            end)
                        end
                        if timeInChaos > 50 then
                            printLog("Auto Boss Event", "Watchdog: Ayam stuck di arena pit (>50 detik)! Me-reset ke Base...")
                            UpdateHub.returnChickenToCoop()
                            task.wait(0.5)
                            UpdateHub.bossChickenStatus = "AT_BASE"
                            UpdateHub.lastBossChaosEntryTime = nil
                            UpdateHub.lastBossSendTime = 0
                        end
                    end
                else
                    UpdateHub.lastBossChaosEntryTime = nil
                    local canSend = (UpdateHub.bossChickenStatus == "WAITING_RESPAWN")
                        or (UpdateHub.bossChickenStatus == "IN_CHAOS")
                        or (UpdateHub.bossChickenStatus == "AT_BASE")
                        or (loc == "AT_BASE")
                        or (now - (UpdateHub.lastBossSendTime or 0) > 12)

                    if canSend and (now - (UpdateHub.lastBossSendTime or 0) >= 3) then
                        printLog("Auto Boss Event", "Chicken Boss terdeteksi di Pit! Mengirim ayam target ke Pit...")
                        UpdateHub.executeSendChickenToBoss(true)
                        UpdateHub.bossChickenStatus = "IN_TRANSIT"
                        UpdateHub.lastBossSendTime = now
                    end
                end
            else
                UpdateHub.lastBossChaosEntryTime = nil
                if UpdateHub.previousActiveChickenIdBoss or (UpdateHub.bossChickenStatus and UpdateHub.bossChickenStatus ~= "AT_BASE") then
                    pcall(function()
                        if UpdateHub.handleBossEventEnded then
                            UpdateHub.handleBossEventEnded()
                        end
                    end)
                else
                    pcall(function()
                        local curId, curName = UpdateHub.getCurrentActiveChicken()
                        local bName = UpdateHub.selectedBossChickenName
                        local bData = bName and chickenMap and chickenMap[bName]
                        local bId = bData and bData.Id
                        if curId and (not bId or tostring(curId) ~= tostring(bId)) then
                            UpdateHub.lastKnownNonBossChickenId = curId
                            UpdateHub.lastKnownNonBossChickenName = curName or tostring(curId)
                        end
                    end)
                end
                task.wait(1.0)
            end
        end
    end
end)

printLog("Init", "SysHub berhasil dimuat dengan sempurna!")


-- ==============================================================================
-- [16] BACKGROUND LOOPS FITUR JURASSIC EVENT
-- ==============================================================================
-- 1. Loop Auto Klaim Jurassic Pass & Quests
task.spawn(function()
    while isCurrentInstance() do
        task.wait(10)
        if UpdateHub.autoClaimJurassicPass then
            pcall(UpdateHub.claimJurassicPassPrizes)
        end
        if UpdateHub.autoClaimJurassicQuests then
            pcall(UpdateHub.claimAllJurassicQuests)
        end
    end
end)

-- 2. Loop Auto Deteksi & Antar Telur Purba (Safe Walk & Hybrid Pintar)
task.spawn(function()
    local wasEventActive = false
    local returnedAfterEvent = false

    while isCurrentInstance() do
        task.wait(0.25)
        if UpdateHub.autoDeliverJurassicEggs and not UpdateHub.isDeliveringJurassicEgg then
            local isLive = false; pcall(function() if type(UpdateHub.isJurassicEggEventActive) == "function" then isLive = UpdateHub.isJurassicEggEventActive() end end)
            if isLive then
                wasEventActive = true
                returnedAfterEvent = false
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local humanoid = char and char:FindFirstChild("Humanoid")
                local pitEgg = UpdateHub.findPitGiantEgg()

                if hrp and pitEgg then
                    local pitPos = pitEgg:IsA("Model") and pitEgg:GetPivot().Position or pitEgg.Position
                    local isHybrid = (UpdateHub.deliveryMode and UpdateHub.deliveryMode:find("Hybrid")) ~= nil
                    local isCarrying, _ = UpdateHub.isCarryingJurassicEgg()

                    if isCarrying then
                        -- Karakter kebetulan sudah memegang telur -> Langsung antar menempel ke AncientEgg
                        UpdateHub.isDeliveringJurassicEgg = true
                        printLog("Jurassic Egg", "Membawa telur purba! Menempel ke AncientEgg di Pit...")
                        if isHybrid then
                            UpdateHub.instantTeleportTo(pitPos)
                            task.wait(0.1)
                            UpdateHub.depositJurassicEggToPit(pitEgg)
                            task.wait(0.25)
                            disableNoclip()
                        else
                            UpdateHub.safeWalkToEgg(pitPos, 2.0)
                            UpdateHub.depositJurassicEggToPit(pitEgg)
                            task.wait(0.35)
                        end
                        UpdateHub.isDeliveringJurassicEgg = false
                        UpdateHub.midwayEggDetected = false
                        local delaySec = tonumber(UpdateHub.cycleDelay) or 0.5
                        if delaySec > 0 then
                            printLog("Jurassic Egg", string.format("Telur bawaan disetor! Jeda %.1f detik sebelum siklus berikutnya...", delaySec))
                            task.wait(delaySec)
                        end
                    else
                        -- Belum memegang telur -> Ambil telur tercecer terdekat berdasarkan prioritas warna
                        local eggs, rawEggList = UpdateHub.findCollectibleJurassicEggs()
                        if #eggs > 0 then
                            UpdateHub.isDeliveringJurassicEgg = true
                            local nearest = eggs[1]
                            local targetInfo = rawEggList and rawEggList[1]
                            local eggPos = nearest:IsA("Model") and nearest:GetPivot().Position or nearest.Position

                            local dist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(eggPos.X, 0, eggPos.Z)).Magnitude
                            local eggColorName = targetInfo and targetInfo.colorName or "Telur"
                            local eggTier = targetInfo and targetInfo.tier or 1
                            local tierLabel = eggTier == 3 and "TINGGI (POIN MAKS)" or (eggTier == 2 and "SEDANG" or "STANDAR")

                            printLog("Jurassic Egg", string.format("[Target] Menuju Telur %s (Tier %d - %s, Jarak: %.1f stud, Speed: %d)...", 
                                eggColorName, eggTier, tierLabel, dist, UpdateHub.eventWalkSpeed or 22))

                            -- Step 1: Berjalan menuju telur target, DENGAN deteksi dini jika telur lain terambil di jalan
                            local walkRes = UpdateHub.safeWalkToEgg(eggPos, 2.0, function()
                                if UpdateHub.autoDetectMidwayEgg ~= false then
                                    local carrying, _ = UpdateHub.isCarryingJurassicEgg()
                                    return carrying == true
                                end
                                return false
                            end)

                            local isCarryingNow, carryReason = UpdateHub.isCarryingJurassicEgg()

                            if isCarryingNow then
                                -- Kasus A: Telur tidak sengaja terambil di perjalanan (mid-path) ATAU langsung terambil saat sampai
                                local midwayPos = hrp.Position
                                if walkRes == "INTERRUPTED" then
                                    printLog("Jurassic Egg", string.format("âš¡ [Auto-Detek Jalan]: Telur tidak sengaja terambil di jalan (%s)! Beralih menyetor ke Pit dulu...", tostring(carryReason)))
                                    notify("Telur Terambil di Jalan!", "Karakter memungut telur di tengah jalan! Langsung setor ke Pit terlebih dahulu...")
                                else
                                    printLog("Jurassic Egg", "Karakter memegang telur! Menyetor langsung ke Pit...")
                                end

                                if isHybrid then
                                    -- Step 2A (Hybrid): Instan TP menempel ke Pit untuk setor
                                    printLog("Jurassic Egg", "âš¡ Hybrid: Instan TP menempel ke Pit untuk setor...")
                                    UpdateHub.instantTeleportTo(pitPos)
                                    task.wait(0.1)
                                    UpdateHub.depositJurassicEggToPit(pitEgg)
                                    task.wait(0.25)

                                    -- Step 3A (Hybrid): Instan TP balik ke posisi sebelum setor agar alur tetap mulus
                                    printLog("Jurassic Egg", "âš¡ Hybrid: Instan TP balik ke posisi sebelum setor...")
                                    UpdateHub.instantTeleportTo(midwayPos)
                                    task.wait(0.15)
                                    disableNoclip()

                                    pcall(function()
                                        if humanoid then
                                            humanoid:ChangeState(Enum.HumanoidStateType.Running)
                                        end
                                        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                    end)
                                    task.wait(0.1)
                                else
                                    -- Mode Safe Walk Murni: Berjalan menempel langsung ke AncientEgg di Pit
                                    printLog("Jurassic Egg", "Membawa telur bawaan/tercecer, menempel langsung ke AncientEgg di Pit...")
                                    UpdateHub.safeWalkToEgg(pitPos, 2.0)
                                    UpdateHub.depositJurassicEggToPit(pitEgg)
                                    task.wait(0.35)
                                end

                                UpdateHub.isDeliveringJurassicEgg = false
                                UpdateHub.midwayEggDetected = false
                                local delaySec = tonumber(UpdateHub.cycleDelay) or 0.5
                                if delaySec > 0 then
                                    printLog("Jurassic Egg", string.format("Telur disetor! Jeda %.1f detik sebelum lanjut mencari target prioritas...", delaySec))
                                    task.wait(delaySec)
                                end
                            else
                                -- Kasus B: Karakter sampai di target tapi belum terangkat otomatis -> Picu pickup
                                UpdateHub.pickupJurassicEgg(nearest)
                                task.wait(0.15)

                                local returnPos = hrp.Position

                                if isHybrid then
                                    -- Step 3: Instan TP menempel ke Pit untuk setor
                                    printLog("Jurassic Egg", "âš¡ Hybrid: Instan TP menempel ke Pit untuk setor...")
                                    UpdateHub.instantTeleportTo(pitPos)
                                    task.wait(0.1)
                                    UpdateHub.depositJurassicEggToPit(pitEgg)
                                    task.wait(0.25)

                                    -- Step 4: Instan TP balik ke posisi semula tempat telur diambil
                                    printLog("Jurassic Egg", "âš¡ Hybrid: Instan TP balik ke posisi awal...")
                                    UpdateHub.instantTeleportTo(returnPos)
                                    task.wait(0.15)
                                    disableNoclip()

                                    pcall(function()
                                        if humanoid then
                                            humanoid:ChangeState(Enum.HumanoidStateType.Running)
                                        end
                                        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                    end)
                                    task.wait(0.1)
                                else
                                    -- Mode Safe Walk Murni: Berjalan menempel langsung ke AncientEgg di Pit
                                    printLog("Jurassic Egg", "Membawa telur purba, menempel langsung ke AncientEgg di Pit...")
                                    UpdateHub.safeWalkToEgg(pitPos, 2.0)
                                    UpdateHub.depositJurassicEggToPit(pitEgg)
                                    task.wait(0.35)
                                end

                                UpdateHub.isDeliveringJurassicEgg = false
                                UpdateHub.midwayEggDetected = false
                                local delaySec = tonumber(UpdateHub.cycleDelay) or 0.5
                                if delaySec > 0 then
                                    printLog("Jurassic Egg", string.format("Siklus 1 selesai disetor! Jeda %.1f detik sebelum siklus 2 bergerak...", delaySec))
                                    task.wait(delaySec)
                                end
                            end
                        else
                            task.wait(1.5)
                        end
                    end
                end
            else
                -- Jika sebelumnya event aktif dan sekarang selesai:
                if wasEventActive and not returnedAfterEvent then
                    wasEventActive = false
                    returnedAfterEvent = true
                    if UpdateHub.autoReturnToCoopAfterEvent ~= false then
                        task.wait(1.0)
                        pcall(function() if type(UpdateHub.returnToFrontOfCoop) == "function" then pcall(function() if type(UpdateHub.returnToFrontOfCoop) == "function" then UpdateHub.returnToFrontOfCoop() end end) end end)
                    end
                end
                task.wait(2.5)
            end
        end
    end
end)

-- 3. LiveEvent Listener & Polling Status UI
task.spawn(function()
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
    if remotes then
        local leStarted = remotes:FindFirstChild("LiveEventStarted")
        if leStarted and leStarted:IsA("RemoteEvent") then
            leStarted.OnClientEvent:Connect(function(eventData)
                local str = tostring(eventData):lower()
                if type(eventData) == "table" then
                    str = (eventData.id or eventData.name or eventData.title or ""):lower()
                end
                if str:find("jurassic") or str:find("ancient") or str:find("egg") or str:find("purba") then
                    UpdateHub.isJurassicEggLive = true
                    printLog("Jurassic Event", "LiveEventStarted: Ancient Egg Event Aktif!")
                end
            end)
        end

        local leEnded = remotes:FindFirstChild("LiveEventEnded")
        if leEnded and leEnded:IsA("RemoteEvent") then
            leEnded.OnClientEvent:Connect(function(eventData)
                local str = tostring(eventData):lower()
                if type(eventData) == "table" then
                    str = (eventData.id or eventData.name or eventData.title or ""):lower()
                end
                if str:find("jurassic") or str:find("ancient") or str:find("egg") or str:find("purba") then
                    UpdateHub.isJurassicEggLive = false
                    printLog("Jurassic Event", "LiveEventEnded: Ancient Egg Event Selesai!")
                    if UpdateHub.autoDeliverJurassicEggs and UpdateHub.autoReturnToCoopAfterEvent ~= false then
                        task.delay(1.5, function()
                            UpdateHub.returnToFrontOfCoop()
                        end)
                    end
                end
            end)
        end
    end

    while isCurrentInstance() do
        task.wait(5)
        local isLive = UpdateHub.isJurassicEggEventActive()
        pcall(function()
            if UpdateHub.jurassicEggStatusParagraph and UpdateHub.jurassicEggStatusParagraph.SetDesc then
                local pitEgg = UpdateHub.findPitGiantEgg()
                local eggs = UpdateHub.findCollectibleJurassicEggs()
                local statusText = isLive and "🟢 Event Telur Sedang Berlangsung!" or "🔴 Event Sedang Tidak Aktif"
                local desc = string.format("Status: %s\nTelur di Pit: %s\nTelur Tercecer di Map: %d butir",
                    statusText,
                    pitEgg and pitEgg.Name or "Tidak Ditemukan",
                    #eggs
                )
                UpdateHub.jurassicEggStatusParagraph:SetDesc(desc)
            end
        end)
    end
end)


task.spawn(function()
    task.wait(1.5)
    pcall(function() if type(scanFlockChickens) == "function" then scanFlockChickens() elseif Context and type(Context.scanFlockChickens) == "function" then Context.scanFlockChickens() end end)
end)

