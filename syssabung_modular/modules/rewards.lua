-- ==============================================================================
--              SYSHUB | MODUL REWARDS & PROMO CODES
-- ==============================================================================
return function(Context, RewardsTab)
    local player = Context.player
    local invokeRemote = Context.invokeRemote
    local notify = Context.notify
    local printLog = Context.printLog
    local logError = Context.logError
    local UpdateHub = Context.UpdateHub
    local saveConfig = Context.saveConfig
    local parseToggle = Context.parseToggle
    local customPromoCode = Context.customPromoCode
    local promoCodesList = Context.promoCodesList

-- [TAB: REWARDS]
-- ==============================================================================

UpdateHub.executeClaimCharmDust = function()
    pcall(function()
        local res = invokeRemote("ClaimShopDust")
        if res then
            printLog("Rewards", "Free Charm Dust berhasil diklaim!")
        end
    end)
end

UpdateHub.executeClaimMilestones = function()
    pcall(function()
        local res = invokeRemote("ClaimRebirthMilestones")
        if res then
            printLog("Rewards", "Rebirth Milestones berhasil diklaim!")
        else
            for m = 1, 20 do
                invokeRemote("ClaimRebirthMilestone", m)
                task.wait(0.05)
            end
        end
    end)
end

UpdateHub.arenaRankIds = {
    "hatchling3", "hatchling2", "hatchling1",
    "bronze3", "bronze2", "bronze1",
    "silver3", "silver2", "silver1",
    "gold3", "gold2", "gold1",
    "crystal3", "crystal2", "crystal1",
    "master3", "master2", "master1",
    "champion"
}

UpdateHub.executeClaimArena = function()
    pcall(function()
        for _, rankId in ipairs(UpdateHub.arenaRankIds) do
            local res = invokeRemote("ArenaClaim", rankId)
            if res and (res == true or (type(res) == "table" and res.ok)) then
                printLog("Rewards", "Reward Arena (" .. tostring(rankId) .. ") berhasil diklaim!")
            end
            task.wait(0.15)
        end
    end)
end

UpdateHub.executeClaimPlayToday = function()
    pcall(function()
        for tier = 1, 6 do
            local res = invokeRemote("DailyClaim", "session", tier)
            if res and (res == true or (type(res) == "table" and res.ok)) then
                printLog("Rewards", "Play Today Tier " .. tostring(tier) .. " berhasil diklaim!")
            end
            task.wait(0.25)
        end
    end)
end

UpdateHub.executeClaimDailyStreak = function()
    pcall(function()
        local res = invokeRemote("DailyClaim", "day", nil)
        if res and (res == true or (type(res) == "table" and res.ok)) then
            printLog("Rewards", "Daily Streak berhasil diklaim!")
        end
    end)
end

UpdateHub.executeClaimMission = function()
    pcall(function()
        local missionsPane = player.PlayerGui:FindFirstChild("MissionsPane", true)
        if missionsPane then
            for _, child in ipairs(missionsPane:GetChildren()) do
                if not child:IsA("UIComponent") and not child:IsA("UILayout") then
                    local btn = child:FindFirstChild("claimBtn", true)
                    local label = child:FindFirstChild("label", true)
                    local isReady = btn ~= nil or (label and label.Text:upper():find("CLAIM"))

                    if isReady then
                        local rawName = child.Name
                        local cleanName = rawName:gsub("^m_", "")
                        invokeRemote("MissionClaim", rawName)
                        invokeRemote("MissionClaim", cleanName)
                        printLog("Rewards", "Misi '" .. tostring(rawName) .. "' diklaim!")
                        task.wait(0.3)
                    end
                end
            end
        end
    end)
end

local function clickGuiButton(btn)
    if not btn then return end
    pcall(function()
        if firesignal then
            if btn.Activated then firesignal(btn.Activated) end
            if btn.MouseButton1Click then firesignal(btn.MouseButton1Click) end
            if btn.MouseButton1Down then firesignal(btn.MouseButton1Down) end
            if btn.MouseButton1Up then firesignal(btn.MouseButton1Up) end
        end
        local getConn = getconnections or get_signal_cons
        if getConn then
            if btn.Activated then
                for _, c in ipairs(getConn(btn.Activated)) do pcall(function() c:Fire() end) end
            end
            if btn.MouseButton1Click then
                for _, c in ipairs(getConn(btn.MouseButton1Click)) do pcall(function() c:Fire() end) end
            end
        end
    end)
end

UpdateHub.executeClaimIndexMilestones = function()
    pcall(function()
        -- 1. Panggil RemoteFunction Bulk Claim resmi jika didukung server
        pcall(function()
            invokeRemote("ClaimIndexMilestones")
        end)

        -- 2. Dapatkan modul IndexMilestones jika ada
        local IndexMilestonesMod = nil
        pcall(function()
            local content = ReplicatedStorage:FindFirstChild("Content")
            local modScript = content and content:FindFirstChild("IndexMilestones")
            if modScript and modScript:IsA("ModuleScript") then
                IndexMilestonesMod = require(modScript)
            end
        end)

        -- 3. Cek jumlah ayam yang ditemukan dari DataService
        local discoveredCount = 0
        pcall(function()
            local dsClient = getSharedDataServiceClient()
            local raw = dsClient and dsClient._data and dsClient._data._data
            if raw and raw.roster and raw.roster.discovered then
                if type(raw.roster.discovered) == "table" then
                    for _ in pairs(raw.roster.discovered) do
                        discoveredCount = discoveredCount + 1
                    end
                elseif type(raw.roster.discovered) == "number" then
                    discoveredCount = raw.roster.discovered
                end
            end
        end)

        -- 4. Tentukan batas milestone yang sudah tercapai
        local maxReached = 30
        if IndexMilestonesMod and discoveredCount > 0 then
            local r = IndexMilestonesMod.reachedCount(discoveredCount)
            if type(r) == "number" and r > 0 then
                maxReached = r
            end
        end

        -- Daftar threshold (at) dari data resmi IndexMilestones (STEP=5 hingga 100, lalu TAIL_STEP=10)
        local milestoneThresholds = {
            5, 10, 15, 20, 25, 30, 35, 40, 45, 50,
            55, 60, 65, 70, 75, 80, 85, 90, 95, 100,
            110, 120, 130, 140, 150, 160, 170, 180, 190, 200
        }

        local limit = math.min(#milestoneThresholds, maxReached)
        for idx = 1, limit do
            local atVal = milestoneThresholds[idx]
            if IndexMilestonesMod and IndexMilestonesMod.nth then
                local nthData = IndexMilestonesMod.nth(idx)
                if nthData and nthData.at then
                    atVal = nthData.at
                end
            end

            -- Panggil ClaimIndexMilestone dengan nilai 'at' (contoh: 5, 10, 15 seperti pada log Live Spy)
            invokeRemote("ClaimIndexMilestone", atVal)
            -- Cadangan pemanggilan dengan ordinal index (1, 2, 3...)
            invokeRemote("ClaimIndexMilestone", idx)
            task.wait(0.04)
        end

        -- 5. Interaksi UI Index / Milestones di PlayerGui jika menu sedang terbuka
        local pg = player:FindFirstChild("PlayerGui")
        if pg then
            for _, desc in ipairs(pg:GetDescendants()) do
                if desc:IsA("GuiButton") or desc:IsA("TextButton") or desc:IsA("ImageButton") then
                    local btnTxt = (desc:IsA("TextButton") and desc.Text or ""):lower()
                    local btnName = desc.Name:lower()

                    if btnName == "claimall" or btnName == "claim" or btnTxt == "claim all" or btnTxt == "claim" then
                        local isIndexGui = false
                        local cur = desc.Parent
                        while cur and cur ~= pg do
                            local cName = cur.Name:lower()
                            if cName:find("index") or cName:find("milestone") or cName:find("collection") then
                                isIndexGui = true
                                break
                            end
                            cur = cur.Parent
                        end

                        if isIndexGui then
                            clickGuiButton(desc)
                        end
                    end
                end
            end
        end

        printLog("Rewards", "Auto Claim Index Milestones berhasil dijalankan!")
    end)
end


UpdateHub.executeRedeemAllCodes = function()
    task.spawn(function()
        notify("Redeem Codes", "Mulai mencoba menukarkan kode promo aktif...")
        for _, code in ipairs(promoCodesList) do
            pcall(function()
                invokeRemote("RedeemCode", code)
            end)
            task.wait(0.4)
        end
        notify("Redeem Codes", "Selesai mencoba semua kode promo!")
    end)
end

-- SECTIONS TAB REWARDS
do
    local RewardsClaimSec = RewardsTab:Section({
        Title = "Auto Claim",
        Opened = false
    })

    RewardsClaimSec:Toggle({
        Title = "Auto Claim Play Today",
        Flag = "auto_claim_play_today",
        Callback = function(state)
            UpdateHub.autoClaimPlayToday = parseToggle(state)
            saveConfig()
            if UpdateHub.autoClaimPlayToday then
                task.spawn(UpdateHub.executeClaimPlayToday)
            end
        end
    })

    RewardsClaimSec:Toggle({
        Title = "Auto Claim Daily Streak",
        Flag = "auto_claim_daily_streak",
        Callback = function(state)
            UpdateHub.autoClaimDailyStreak = parseToggle(state)
            saveConfig()
            if UpdateHub.autoClaimDailyStreak then
                task.spawn(UpdateHub.executeClaimDailyStreak)
            end
        end
    })

    RewardsClaimSec:Toggle({
        Title = "Auto Claim Mission",
        Flag = "auto_claim_mission",
        Callback = function(state)
            UpdateHub.autoClaimMission = parseToggle(state)
            saveConfig()
            if UpdateHub.autoClaimMission then
                task.spawn(UpdateHub.executeClaimMission)
            end
        end
    })

    RewardsClaimSec:Toggle({
        Title = "Auto Claim Charm Dust",
        Flag = "auto_claim_charm_dust",
        Callback = function(state)
            UpdateHub.autoClaimCharmDust = parseToggle(state)
            saveConfig()
            if UpdateHub.autoClaimCharmDust then
                task.spawn(UpdateHub.executeClaimCharmDust)
            end
        end
    })

    RewardsClaimSec:Toggle({
        Title = "Auto Claim Index Milestones",
        Flag = "auto_claim_index",
        Callback = function(state)
            UpdateHub.autoClaimIndex = parseToggle(state)
            saveConfig()
            if UpdateHub.autoClaimIndex then
                task.spawn(UpdateHub.executeClaimIndexMilestones)
            end
        end
    })

    RewardsClaimSec:Button({
        Title = "Claim All Rewards Now (1-Klik)",
        Callback = function()
            notify("Rewards", "Mengeksekusi klaim seluruh hadiah...")
            task.spawn(function()
                UpdateHub.executeClaimCharmDust()
                task.wait(0.3)
                UpdateHub.executeClaimMilestones()
                task.wait(0.3)
                UpdateHub.executeClaimArena()
                task.wait(0.3)
                UpdateHub.executeClaimDailyStreak()
                task.wait(0.3)
                UpdateHub.executeClaimPlayToday()
                task.wait(0.3)
                UpdateHub.executeClaimMission()
                task.wait(0.3)
                UpdateHub.executeClaimIndexMilestones()
                notify("Rewards", "Selesai mengeksekusi klaim semua reward!")
            end)
        end
    })

    local RewardsCodeSec = RewardsTab:Section({
        Title = "Auto Redeem Code",
        Opened = false
    })

    RewardsCodeSec:Button({
        Title = "Redeem Semua Kode Aktif (1-Klik)",
        Callback = function()
            UpdateHub.executeRedeemAllCodes()
        end
    })

    RewardsCodeSec:Input({
        Title = "Kode Promo Kustom",
        Value = customPromoCode,
        Callback = function(text)
            if text and text ~= "" then
                customPromoCode = text
            end
        end
    })

    RewardsCodeSec:Button({
        Title = "Redeem Kode Kustom",
        Callback = function()
            if customPromoCode and customPromoCode ~= "" then
                pcall(function()
                    invokeRemote("RedeemCode", customPromoCode)
                end)
                notify("Redeem Code", "Kode '" .. customPromoCode .. "' dikirim ke server!")
            else
                notify("Redeem Code", "Ketik kode terlebih dahulu pada kotak di atas!")
            end
        end
    })

    local RewardsMilestoneSec = RewardsTab:Section({
        Title = "Arena & Rebirth Milestones",
        Opened = false
    })

    RewardsMilestoneSec:Toggle({
        Title = "Auto Claim Reward Arena",
        Flag = "auto_claim_arena",
        Callback = function(state)
            UpdateHub.autoClaimArena = parseToggle(state)
            if UpdateHub.autoClaimArena then
                task.spawn(UpdateHub.executeClaimArena)
            end
        end
    })

    RewardsMilestoneSec:Toggle({
        Title = "Auto Claim Rebirth Milestones",
        Flag = "auto_claim_milestones",
        Callback = function(state)
            UpdateHub.autoClaimMilestones = parseToggle(state)
            if UpdateHub.autoClaimMilestones then
                task.spawn(UpdateHub.executeClaimMilestones)
            end
        end
    })

    RewardsMilestoneSec:Button({
        Title = "Claim Arena & Milestones Sekarang",
        Callback = function()
            notify("Rewards", "Mengklaim hadiah Arena & Rebirth Milestones...")
            task.spawn(function()
                UpdateHub.executeClaimMilestones()
                task.wait(0.4)
                UpdateHub.executeClaimArena()
                notify("Rewards", "Klaim Arena & Milestones selesai!")
            end)
        end
    })

end

-- ==============================================================================
end
