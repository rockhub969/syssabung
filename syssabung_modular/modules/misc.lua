-- ==============================================================================
--              SYSHUB | MODUL MISC, OPTIMIZER, CONFIG & WEBHOOK
-- ==============================================================================
return function(Context, MiscTab, WebhookTab)
    local player = Context.player
    local TeleportService = Context.TeleportService
    local HttpService = Context.HttpService
    local Lighting = Context.Lighting
    local RunService = Context.RunService
    local notify = Context.notify
    local printLog = Context.printLog
    local logError = Context.logError
    local UpdateHub = Context.UpdateHub
    local saveConfig = Context.saveConfig
    local parseToggle = Context.parseToggle
    local chickenMap = Context.chickenMap
    local chickenNames = Context.chickenNames
    local webhookUrl = Context.webhookUrl
    local webhookRebirthEnabled = Context.webhookRebirthEnabled
    local triggerWebhookRebirthEvent = Context.triggerWebhookRebirthEvent

-- [12] TAB MISC - SERVER MANAGEMENT
-- ==============================================================================
do
    local ServerSec = MiscTab:Section({
        Title = "Server Management",
        Opened = false
    })

-- PARAGRAF STATUS SERVER
local ServerStatusPara = ServerSec:Paragraph({
    Title = "Status Server",
    Desc = string.format("ID Server : %s\nJumlah Pemain : %d/%d", 
        (game.JobId and game.JobId ~= "") and game.JobId or "N/A (Studio/Private)", 
        #Players:GetPlayers(), 
        Players.MaxPlayers > 0 and Players.MaxPlayers or 4
    )
})

local function updateServerStatusUI()
    if not ServerStatusPara then
        return
    end
    local currentPlayers = #Players:GetPlayers()
    local maxCap = Players.MaxPlayers > 0 and Players.MaxPlayers or 4
    local sId = (game.JobId and game.JobId ~= "") and game.JobId or "N/A (Studio/Private)"
    local descText = string.format("ID Server : %s\nJumlah Pemain : %d/%d", sId, currentPlayers, maxCap)
    
    pcall(function()
        if type(ServerStatusPara.SetDesc) == "function" then
            ServerStatusPara:SetDesc(descText)
        elseif type(ServerStatusPara.Set) == "function" then
            ServerStatusPara:Set({
                Title = "Status Server",
                Desc = descText
            })
        end
    end)
end

Players.PlayerAdded:Connect(updateServerStatusUI)
Players.PlayerRemoving:Connect(updateServerStatusUI)

ServerSec:Button({
    Title = "Salin ID Server",
    Callback = function()
        local sId = game.JobId
        if sId and sId ~= "" then
            pcall(function()
                if setclipboard then
                    setclipboard(sId)
                elseif toclipboard then
                    toclipboard(sId)
                end
            end)
            notify("Server Management", "ID Server berhasil disalin ke clipboard!")
        else
            notify("Server Management", "ID Server kosong (Studio / Private Server).")
        end
    end
})

-- HELPER AMBIL LIST SERVER DARI ROBLOX API
local function getPublicServerList(sortOrder)
    sortOrder = sortOrder or 1 -- 1 = Ascending (Paling sepi), 2 = Descending
    local placeId = game.PlaceId
    local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=%s&limit=100", tostring(placeId), tostring(sortOrder))
    
    local success, response = pcall(function()
        if type(game.HttpGet) == "function" then
            return game:HttpGet(url)
        end
        local req = request or http_request
        if not req then
            local env = (getfenv and getfenv()) or _G
            local synTable = env and env.syn
            if synTable and type(synTable.request) == "function" then
                req = synTable.request
            end
        end
        if type(req) == "function" then
            local res = req({Url = url, Method = "GET"})
            return res and res.Body
        end
        return nil
    end)

    if success and response then
        local decodeOk, parsed = pcall(function()
            return HttpService:JSONDecode(response)
        end)
        if decodeOk and parsed and parsed.data then
            return parsed.data
        end
    end
    return nil
end

-- FITUR 2: REJOIN SERVER ACAK
ServerSec:Button({
    Title = "Rejoin Server Acak",
    Callback = function()
        notify("Server Management", "Mencari server acak...")
        task.spawn(function()
            local servers = getPublicServerList(1)
            local validServers = {}
            if servers then
                for _, s in ipairs(servers) do
                    if s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers then
                        table.insert(validServers, s)
                    end
                end
            end

            if #validServers > 0 then
                local chosen = validServers[math.random(1, #validServers)]
                notify("Server Management", string.format("Menghubungkan ke server acak (%d/%d pemain)...", chosen.playing, chosen.maxPlayers))
                task.wait(0.5)
                TeleportService:TeleportToPlaceInstance(game.PlaceId, chosen.id, player)
            else
                notify("Server Management", "Tidak menemukan server lain via API, mencoba teleport default...")
                task.wait(0.5)
                TeleportService:Teleport(game.PlaceId, player)
            end
        end)
    end
})

-- FITUR 3: REJOIN SERVER YANG SAMA
ServerSec:Button({
    Title = "Rejoin Server Saat Ini",
    Callback = function()
        notify("Server Management", "Menghubungkan ulang ke server saat ini...")
        task.spawn(function()
            task.wait(0.5)
            if #Players:GetPlayers() <= 1 or game.JobId == "" then
                -- Jika hanya ada 1 pemain, server akan otomatis tutup saat disconnect, gunakan Teleport biasa
                TeleportService:Teleport(game.PlaceId, player)
            else
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
            end
        end)
    end
})

-- FITUR 4: HOP SERVER SEPI (MAKSIMAL 2 PEMAIN)
ServerSec:Button({
    Title = "Hop Server Sepi (Max 2 Player)",
    Callback = function()
        notify("Server Management", "Mencari server tersepi (maksimal 2 pemain)...")
        task.spawn(function()
            -- sortOrder=1 (Ascending) otomatis mengambil server dengan jumlah player terendah di awal
            local servers = getPublicServerList(1)
            if not servers or #servers == 0 then
                notify("Server Management", "Gagal mengambil daftar server dari Roblox API.")
                return
            end

            local maxTarget = 2
            local underMaxServers = {}
            local allValidServers = {}

            for _, s in ipairs(servers) do
                if s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers then
                    table.insert(allValidServers, s)
                    if s.playing <= maxTarget then
                        table.insert(underMaxServers, s)
                    end
                end
            end

            local chosenServer = nil
            if #underMaxServers > 0 then
                -- Urutkan berdasarkan yang paling sedikit pemainnya
                table.sort(underMaxServers, function(a, b)
                    return a.playing < b.playing
                end)
                chosenServer = underMaxServers[1]
                notify("Server Management", string.format("Server sepi ditemukan! (%d/%d pemain). Memulai teleport...", chosenServer.playing, chosenServer.maxPlayers))
            elseif #allValidServers > 0 then
                -- Jika tidak ada yang <= 2 pemain, pilih server dengan pemain paling sedikit yang tersedia
                table.sort(allValidServers, function(a, b)
                    return a.playing < b.playing
                end)
                chosenServer = allValidServers[1]
                notify("Server Management", string.format("Server <= 2 pemain penuh. Memilih server tersepi (%d/%d pemain)...", chosenServer.playing, chosenServer.maxPlayers))
            else
                notify("Server Management", "Tidak ada server yang memenuhi kriteria untuk berpindah.")
                return
            end

            if chosenServer then
                task.wait(0.5)
                local success, err = pcall(function()
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, chosenServer.id, player)
                end)
                if not success then
                    logError("Hop Server", err)
                    notify("Server Management", "Gagal teleport: " .. tostring(err))
                end
            end
        end)
    end
})

TeleportService.TeleportInitFailed:Connect(function(plr, teleportResult, errorMessage)
    if plr == player then
        warn(string.format("[SysHub - Teleport Failed]: %s (%s)", tostring(errorMessage), tostring(teleportResult)))
        notify("Teleport Gagal", tostring(errorMessage))
    end
end)
end



-- ==============================================================================
-- [12A] TAB MISC - BOOST FPS & PERFORMANCE OPTIMIZER
-- ==============================================================================
do
    local FpsSec = MiscTab:Section({
        Title = "FPS Boost",
        Opened = false
    })


    -- Storage untuk menyimpan pengaturan awal sebelum diubah agar bisa direstore
    local originalLighting = {
        GlobalShadows = Lighting.GlobalShadows,
        FogEnd = Lighting.FogEnd,
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime
    }
    local originalEffects = {}
    local originalMaterials = setmetatable({}, { __mode = "k" })
    local originalDecalTransparency = setmetatable({}, { __mode = "k" })
    local fpsDescendantConn = nil
    local textureDescendantConn = nil

    -- Fungsi menerapkan optimasi bayangan & efek pada objek
    local function applyPartOptimization(desc)
        pcall(function()
            if desc:IsA("BasePart") then
                desc.CastShadow = false
            elseif desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Smoke") or desc:IsA("Fire") or desc:IsA("Sparkles") or desc:IsA("Beam") or desc:IsA("Highlight") then
                desc.Enabled = false
            end
        end)
    end

    -- Fungsi menerapkan tekstur ringan (SmoothPlastic)
    local function applySmoothPlastic(desc)
        pcall(function()
            if desc:IsA("BasePart") then
                if originalMaterials[desc] == nil then
                    originalMaterials[desc] = {
                        Material = desc.Material,
                        Reflectance = desc.Reflectance
                    }
                end
                desc.Material = Enum.Material.SmoothPlastic
                desc.Reflectance = 0
            elseif desc:IsA("Decal") or desc:IsA("Texture") then
                if originalDecalTransparency[desc] == nil then
                    originalDecalTransparency[desc] = desc.Transparency
                end
                desc.Transparency = 1
            end
        end)
    end

    -- 1. TOGGLE BOOST FPS UTAMA (Lighting, Shadows, Particles, Water)
    FpsSec:Toggle({
        Title = "FPS Boost",
        Flag = "misc_boost_fps",
        Value = UpdateHub.boostFps,
        Callback = function(state)
            UpdateHub.boostFps = parseToggle(state)
            if UpdateHub.boostFps then
                -- Backup lighting state jika belum pernah
                pcall(function()
                    originalLighting.GlobalShadows = Lighting.GlobalShadows
                    originalLighting.FogEnd = Lighting.FogEnd
                    originalLighting.Brightness = Lighting.Brightness
                    originalLighting.ClockTime = Lighting.ClockTime
                end)

                -- Optimasi Lighting
                pcall(function()
                    Lighting.GlobalShadows = false
                    Lighting.FogEnd = 9e9
                    Lighting.Brightness = 1
                    Lighting.ClockTime = 12
                end)

                -- Matikan Post-Processing Effects di Lighting
                pcall(function()
                    for _, effect in ipairs(Lighting:GetChildren()) do
                        if effect:IsA("BloomEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("SunRaysEffect") or effect:IsA("BlurEffect") or effect:IsA("Atmosphere") or effect:IsA("DepthOfFieldEffect") then
                            if originalEffects[effect] == nil then
                                originalEffects[effect] = effect.Enabled
                            end
                            effect.Enabled = false
                        end
                    end
                end)

                -- Optimasi Terrain Water
                pcall(function()
                    local terrain = Workspace:FindFirstChildOfClass("Terrain") or Workspace.Terrain
                    if terrain then
                        terrain.WaterWaveSize = 0
                        terrain.WaterWaveSpeed = 0
                        terrain.WaterReflectance = 0
                        terrain.WaterTransparency = 0
                    end
                end)

                -- Turunkan Quality Level jika didukung
                pcall(function()
                    if settings and settings().Rendering then
                        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                    end
                end)

                -- Terapkan ke seluruh objek yang ada di workspace
                pcall(function()
                    for _, desc in ipairs(Workspace:GetDescendants()) do
                        applyPartOptimization(desc)
                    end
                end)

                -- Listener untuk objek / efek baru yang muncul saat game berjalan
                if not fpsDescendantConn then
                    fpsDescendantConn = Workspace.DescendantAdded:Connect(function(desc)
                        if UpdateHub.boostFps then
                            applyPartOptimization(desc)
                        end
                    end)
                end

                notify("Boost FPS", "Mode Boost FPS Aktif! Bayangan & efek visual dinonaktifkan.")
            else
                -- Restore Lighting
                pcall(function()
                    Lighting.GlobalShadows = originalLighting.GlobalShadows
                    Lighting.FogEnd = originalLighting.FogEnd
                    Lighting.Brightness = originalLighting.Brightness
                    Lighting.ClockTime = originalLighting.ClockTime
                end)

                -- Restore Post-Processing Effects
                pcall(function()
                    for effect, origEnabled in pairs(originalEffects) do
                        if effect and effect.Parent then
                            pcall(function() effect.Enabled = origEnabled end)
                        end
                    end
                end)

                -- Restore Terrain Water
                pcall(function()
                    local terrain = Workspace:FindFirstChildOfClass("Terrain") or Workspace.Terrain
                    if terrain then
                        terrain.WaterWaveSize = 0.15
                        terrain.WaterWaveSpeed = 10
                        terrain.WaterReflectance = 1
                        terrain.WaterTransparency = 1
                    end
                end)

                
                -- Restore Quality Level
                pcall(function()
                    if settings and settings().Rendering then
                        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
                    end
                end)

                -- Putuskan koneksi listener objek baru
                if fpsDescendantConn then
                    fpsDescendantConn:Disconnect()
                    fpsDescendantConn = nil
                end

                notify("Boost FPS", "Mode Boost FPS Dinonaktifkan. Pengaturan visual dikembalikan.")
            end
            saveConfig()
        end
    })

    -- 2. TOGGLE TEKSTUR RINGAN (Smooth Plastic & Sembunyikan Decals)
    FpsSec:Toggle({
        Title = "Smooth",
        Flag = "misc_low_textures",
        Value = UpdateHub.lowTextures,
        Callback = function(state)
            UpdateHub.lowTextures = parseToggle(state)
            if UpdateHub.lowTextures then
                pcall(function()
                    for _, desc in ipairs(Workspace:GetDescendants()) do
                        applySmoothPlastic(desc)
                    end
                end)

                if not textureDescendantConn then
                    textureDescendantConn = Workspace.DescendantAdded:Connect(function(desc)
                        if UpdateHub.lowTextures then
                            applySmoothPlastic(desc)
                        end
                    end)
                end

                notify("Boost FPS", "Tekstur Smooth Plastic aktif! Beban render tekstur berkurang.")
            else
                -- Kembalikan material asli
                pcall(function()
                    for part, data in pairs(originalMaterials) do
                        if part and part.Parent then
                            pcall(function()
                                part.Material = data.Material
                                part.Reflectance = data.Reflectance
                            end)
                        end
                    end
                end)

                -- Kembalikan transparansi Decal / Texture
                pcall(function()
                    for dec, origTrans in pairs(originalDecalTransparency) do
                        if dec and dec.Parent then
                            pcall(function()
                                dec.Transparency = origTrans
                            end)
                        end
                    end
                end)

                if textureDescendantConn then
                    textureDescendantConn:Disconnect()
                    textureDescendantConn = nil
                end

                notify("Boost FPS", "Tekstur normal dikembalikan.")
            end
            saveConfig()
        end
    })

    -- 3. TOGGLE DISABLE 3D RENDERING (SUPER AFK / GPU SAVER)
    FpsSec:Toggle({
        Title = "Off 3D Render",
        Flag = "misc_disable_3d_render",
        Value = UpdateHub.disable3dRendering,
        Callback = function(state)
            UpdateHub.disable3dRendering = parseToggle(state)
            local enabled3d = not UpdateHub.disable3dRendering
            local ok = pcall(function()
                RunService:Set3dRenderingEnabled(enabled3d)
            end)

            if ok then
                if UpdateHub.disable3dRendering then
                    notify("Boost FPS", "Rendering 3D Dimatikan! GPU & CPU sangat hemat. GUI tetap aktif.")
                else
                    notify("Boost FPS", "Rendering 3D Diaktifkan kembali.")
                end
            else
                notify("Boost FPS", "Executor Anda tidak mendukung Set3dRenderingEnabled.")
            end
            saveConfig()
        end
    })

    -- 4. DROPDOWN BATAS FPS (FPS CAP)
    local fpsCapList = {"Default (60)", "30 FPS (Hemat)", "45 FPS", "60 FPS", "120 FPS", "144 FPS", "240 FPS", "Unlimited (999)"}
    FpsSec:Dropdown({
        Title = "FPS Max",
        Flag = "misc_fps_cap",
        Values = fpsCapList,
        Value = UpdateHub.fpsCap or "Default (60)",
        Callback = function(val)
            UpdateHub.fpsCap = val
            local num = 60
            if val:find("30") then
                num = 30
            elseif val:find("45") then
                num = 45
            elseif val:find("60") then
                num = 60
            elseif val:find("120") then
                num = 120
            elseif val:find("144") then
                num = 144
            elseif val:find("240") then
                num = 240
            elseif val:find("999") or val:find("Unlimited") then
                num = 999
            end

            local setOk = false
            pcall(function()
                if type(setfpscap) == "function" then
                    setfpscap(num)
                    setOk = true
                end
            end)

            if setOk then
                notify("FPS Cap", string.format("FPS dibatasi ke: %d FPS", num))
            else
                notify("FPS Cap", "setfpscap tidak didukung oleh executor ini.")
            end
            saveConfig()
        end
    })

end

-- ==============================================================================
-- [12B] TAB MISC - CONFIGURATION MANAGER (MANUAL SAVE & LOAD)
-- ==============================================================================
do
    local ConfigFolder = "SysHub"
    local ConfigSubFolder = "SysHub/Configs"

    local function ensureConfigFolder()
        pcall(function()
            if type(makefolder) == "function" then
                if type(isfolder) == "function" then
                    if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
                    if not isfolder(ConfigSubFolder) then makefolder(ConfigSubFolder) end
                else
                    makefolder(ConfigFolder)
                    makefolder(ConfigSubFolder)
                end
            end
        end)
    end

    local function getConfigFileList()
        local list = {}
        pcall(function()
            ensureConfigFolder()
            if type(listfiles) == "function" then
                local files = listfiles(ConfigSubFolder)
                if files and type(files) == "table" then
                    for _, f in ipairs(files) do
                        local name = f:match("([^/\\]+)%.json$")
                        if name then
                            table.insert(list, name)
                        end
                    end
                end
            end
        end)
        table.sort(list)
        if #list == 0 then
            table.insert(list, "Default")
        end
        return list
    end

    local function saveConfigToFile(configName)
        if not configName or configName:gsub("%s+", "") == "" then
            notify("Config Manager", "Nama config tidak boleh kosong!")
            return false
        end
        configName = configName:gsub("[^%w_%-]", "")
        if configName == "" then
            configName = "Default"
        end

        local data = {}

        -- 1. Baca nilai dari semua elemen UI terdaftar via Flag
        for flag, el in pairs(registeredUiElements) do
            pcall(function()
                if el then
                    local val = nil
                    pcall(function() val = el.Value end)
                    if val == nil then pcall(function() val = el.State end) end
                    if val == nil then pcall(function() val = el.Current end) end
                    if val == nil and type(el.GetValue) == "function" then
                        pcall(function() val = el:GetValue() end)
                    end
                    if val ~= nil then
                        data[flag] = val
                    end
                end
            end)
        end

        -- 2. Direct mapping dari seluruh variabel aktif di memori (Jaminan 100% tersimpan akurat)
        local variableMap = {
            ["auto_claim_incubator"] = autoClaimIncubator,
            ["selected_incubator_chicken_name"] = selectedChickenName,
            ["auto_put_incubator"] = autoPutIncubator,
            ["auto_upgrade_incubator"] = autoUpgradeIncubator,
            ["delay_upgrade_incubator"] = delayUpgradeIncubator,
            ["auto_ufo_event"] = UpdateHub.autoUfoEvent,
            ["ufo_priority_mode"] = UpdateHub.ufoPriorityMode,
            ["selected_ufo_chicken_name"] = UpdateHub.selectedUfoChickenName,
            ["auto_boss_event"] = UpdateHub.autoBossEvent,
            ["boss_priority_mode"] = UpdateHub.bossPriorityMode,
            ["selected_boss_chicken_name"] = UpdateHub.selectedBossChickenName,
            ["auto_upgrade_coop"] = autoUpgradeCoop,
            ["coop_delay"] = delayCoop,
            ["auto_upgrade_recycler"] = autoUpgradeRecycler,
            ["recycler_delay"] = delayRecycler,
            ["auto_buy_feeder"] = autoBuyFeeder,
            ["buy_feeder_delay"] = delayBuy,
            ["auto_upgrade_feeder"] = autoUpgradeFeeder,
            ["upgrade_feeder_delay"] = delayUpgrade,
            ["auto_collect_nest_eggs"] = autoCollectNestEggs,
            ["enable_fast_rebirth"] = autoFastRebirth,
            ["target_coop_level"] = fastTargetCoop,
            ["target_feeder_count"] = fastMaxFeeders,
            ["target_feeder_level"] = fastTargetFeederLevel,
            ["auto_tower"] = autoTower,
            ["retreat_floor"] = retreatFloor,
            ["auto_sweep_items"] = autoSweep,
            ["max_bag_capacity"] = MAX_CAPACITY,
            ["auto_sell_chickens"] = autoSellChickens,
            ["sell_rarities"] = selectedSellRarities,
            ["sell_delay"] = delaySellChicken,
            ["auto_claim_play_today"] = UpdateHub.autoClaimPlayToday,
            ["auto_claim_daily_streak"] = UpdateHub.autoClaimDailyStreak,
            ["auto_claim_mission"] = UpdateHub.autoClaimMission,
            ["auto_claim_charm_dust"] = UpdateHub.autoClaimCharmDust,
            ["auto_claim_index"] = UpdateHub.autoClaimIndex,
            ["auto_claim_jurassic_pass"] = UpdateHub.autoClaimJurassicPass,
            ["auto_claim_jurassic_quests"] = UpdateHub.autoClaimJurassicQuests,
            ["auto_deliver_jurassic_eggs"] = UpdateHub.autoDeliverJurassicEggs,
            ["auto_return_to_coop_after_event"] = UpdateHub.autoReturnToCoopAfterEvent,
            ["custom_front_coop_x"] = UpdateHub.customFrontCoopPos and UpdateHub.customFrontCoopPos.X or nil,
            ["custom_front_coop_y"] = UpdateHub.customFrontCoopPos and UpdateHub.customFrontCoopPos.Y or nil,
            ["custom_front_coop_z"] = UpdateHub.customFrontCoopPos and UpdateHub.customFrontCoopPos.Z or nil,
            ["delivery_mode"] = UpdateHub.deliveryMode,
            ["prioritize_egg_color"] = UpdateHub.prioritizeEggColor,
            ["auto_detect_midway_egg"] = UpdateHub.autoDetectMidwayEgg,
            ["cycle_delay"] = UpdateHub.cycleDelay,
            ["event_walk_speed"] = UpdateHub.eventWalkSpeed,
            ["esp_player_enabled"] = espPlayerEnabled,
            ["esp_egg_enabled"] = espEggEnabled,
            ["esp_scrap_enabled"] = espScrapEnabled,
            ["streamer_mode_enabled"] = streamerMode,
            ["fake_name"] = fakeName,
            ["webhook_url"] = webhookUrl,
            ["webhook_rebirth_enabled"] = webhookRebirthEnabled,
            ["auto_arena_fight"] = UpdateHub.autoArenaFight,
            ["delay_arena_fight"] = UpdateHub.delayArenaFight,
            ["auto_roll_charms"] = UpdateHub.autoRollCharms,
            ["selected_charm_chicken_name"] = UpdateHub.selectedCharmChickenName,
            ["charm_min_tier"] = UpdateHub.charmMinTier,
            ["charm_preferred_stats"] = UpdateHub.charmPreferredStats,
            ["auto_claim_arena"] = UpdateHub.autoClaimArena,
            ["auto_claim_milestones"] = UpdateHub.autoClaimMilestones,
            ["auto_keep_inverted"] = UpdateHub.autoKeepInverted,
            ["auto_keep_jurassic"] = UpdateHub.autoKeepJurassic,
            ["egg_open_count"] = UpdateHub.eggOpenRepeatCount,
            ["tower_hp_threshold"] = towerHpThreshold,
            ["tower_start_mode"] = towerStartMode,
            ["auto_fuse"] = autoFuse,
            ["auto_promote"] = autoPromote,
            ["misc_boost_fps"] = UpdateHub.boostFps,
            ["misc_low_textures"] = UpdateHub.lowTextures,
            ["misc_disable_3d_render"] = UpdateHub.disable3dRendering,
            ["misc_fps_cap"] = UpdateHub.fpsCap
        }

        for k, v in pairs(variableMap) do
            if v ~= nil then
                data[k] = v
            end
        end

        local encoded = nil
        local okEncode, _ = pcall(function()
            encoded = HttpService:JSONEncode(data)
        end)

        if not okEncode or not encoded then
            notify("Config Manager", "Gagal meng-encode data config!")
            return false
        end

        local successWrite = false
        pcall(function()
            ensureConfigFolder()
            if type(writefile) == "function" then
                writefile(ConfigSubFolder .. "/" .. configName .. ".json", encoded)
                successWrite = true
            end
        end)

        if not successWrite then
            pcall(function()
                if type(writefile) == "function" then
                    writefile("SysHub_" .. configName .. ".json", encoded)
                    successWrite = true
                end
            end)
        end

        if successWrite then
            notify("Config Manager", string.format("Config '%s' berhasil disimpan!", configName))
            printLog("Config Manager", string.format("Config '%s' berhasil disimpan ke storage!", configName))
            return true
        else
            notify("Config Manager", "Executor tidak mendukung fungsi writefile!")
            return false
        end
    end

    local function loadConfigFromFile(configName)
        if not configName or configName == "" then
            notify("Config Manager", "Pilih config terlebih dahulu!")
            return false
        end

        local content = nil
        pcall(function()
            if type(readfile) == "function" then
                local p1 = ConfigSubFolder .. "/" .. configName .. ".json"
                local p2 = "SysHub_" .. configName .. ".json"
                if type(isfile) == "function" then
                    if isfile(p1) then
                        content = readfile(p1)
                    elseif isfile(p2) then
                        content = readfile(p2)
                    end
                else
                    local ok, res = pcall(readfile, p1)
                    if ok and res then content = res else
                        local ok2, res2 = pcall(readfile, p2)
                        if ok2 and res2 then content = res2 end
                    end
                end
            end
        end)

        if not content or content == "" then
            notify("Config Manager", string.format("File config '%s' tidak ditemukan atau kosong!", configName))
            return false
        end

        local okDecode, data = pcall(function()
            return HttpService:JSONDecode(content)
        end)

        if not okDecode or type(data) ~= "table" then
            notify("Config Manager", "Format file config rusak / bukan JSON valid!")
            return false
        end

        -- 1. Terapkan langsung ke variabel memori skrip
        if data["auto_claim_incubator"] ~= nil then autoClaimIncubator = parseToggle(data["auto_claim_incubator"]) end
        if data["auto_put_incubator"] ~= nil then autoPutIncubator = parseToggle(data["auto_put_incubator"]) end
        if data["auto_upgrade_incubator"] ~= nil then autoUpgradeIncubator = parseToggle(data["auto_upgrade_incubator"]) end
        if data["delay_upgrade_incubator"] ~= nil then delayUpgradeIncubator = tonumber(data["delay_upgrade_incubator"]) or delayUpgradeIncubator end
        if data["selected_incubator_chicken_name"] ~= nil then
            selectedChickenName = data["selected_incubator_chicken_name"]
            if chickenMap and chickenMap[selectedChickenName] then
                selectedChickenId = chickenMap[selectedChickenName].Id
            end
        end

        if data["auto_ufo_event"] ~= nil then UpdateHub.autoUfoEvent = parseToggle(data["auto_ufo_event"]) end
        if data["ufo_priority_mode"] ~= nil then UpdateHub.ufoPriorityMode = parseToggle(data["ufo_priority_mode"]) end
        if data["selected_ufo_chicken_name"] ~= nil then UpdateHub.selectedUfoChickenName = data["selected_ufo_chicken_name"] end
        if data["auto_boss_event"] ~= nil then UpdateHub.autoBossEvent = parseToggle(data["auto_boss_event"]) end
        if data["boss_priority_mode"] ~= nil then UpdateHub.bossPriorityMode = parseToggle(data["boss_priority_mode"]) end
        if data["selected_boss_chicken_name"] ~= nil then UpdateHub.selectedBossChickenName = data["selected_boss_chicken_name"] end

        if data["auto_upgrade_coop"] ~= nil then autoUpgradeCoop = parseToggle(data["auto_upgrade_coop"]) end
        if data["coop_delay"] ~= nil then delayCoop = tonumber(data["coop_delay"]) or delayCoop end
        if data["auto_upgrade_recycler"] ~= nil then autoUpgradeRecycler = parseToggle(data["auto_upgrade_recycler"]) end
        if data["recycler_delay"] ~= nil then delayRecycler = tonumber(data["recycler_delay"]) or delayRecycler end
        if data["auto_buy_feeder"] ~= nil then autoBuyFeeder = parseToggle(data["auto_buy_feeder"]) end
        if data["buy_feeder_delay"] ~= nil then delayBuy = tonumber(data["buy_feeder_delay"]) or delayBuy end
        if data["auto_upgrade_feeder"] ~= nil then autoUpgradeFeeder = parseToggle(data["auto_upgrade_feeder"]) end
        if data["upgrade_feeder_delay"] ~= nil then delayUpgrade = tonumber(data["upgrade_feeder_delay"]) or delayUpgrade end
        if data["auto_collect_nest_eggs"] ~= nil then autoCollectNestEggs = parseToggle(data["auto_collect_nest_eggs"]) end

        if data["enable_fast_rebirth"] ~= nil then autoFastRebirth = parseToggle(data["enable_fast_rebirth"]) end
        if data["target_coop_level"] ~= nil then fastTargetCoop = tonumber(data["target_coop_level"]) or fastTargetCoop end
        if data["target_feeder_count"] ~= nil then fastMaxFeeders = tonumber(data["target_feeder_count"]) or fastMaxFeeders end
        if data["target_feeder_level"] ~= nil then fastTargetFeederLevel = tonumber(data["target_feeder_level"]) or fastTargetFeederLevel end
        if data["auto_tower"] ~= nil then autoTower = parseToggle(data["auto_tower"]) end
        if data["retreat_floor"] ~= nil then retreatFloor = tonumber(data["retreat_floor"]) or retreatFloor end
        if data["auto_sweep_items"] ~= nil then autoSweep = parseToggle(data["auto_sweep_items"]) end
        if data["max_bag_capacity"] ~= nil then MAX_CAPACITY = tonumber(data["max_bag_capacity"]) or MAX_CAPACITY end
        if data["auto_sell_chickens"] ~= nil then autoSellChickens = parseToggle(data["auto_sell_chickens"]) end
        if data["sell_delay"] ~= nil then delaySellChicken = tonumber(data["sell_delay"]) or delaySellChicken end
        if data["sell_rarities"] ~= nil and type(data["sell_rarities"]) == "table" then
            for k in pairs(selectedSellRarities) do
                selectedSellRarities[k] = false
            end
            for k, v in pairs(data["sell_rarities"]) do
                if type(k) == "string" and v == true then
                    selectedSellRarities[k] = true
                elseif type(v) == "string" then
                    selectedSellRarities[v] = true
                end
            end
        end

        if data["auto_claim_play_today"] ~= nil then UpdateHub.autoClaimPlayToday = parseToggle(data["auto_claim_play_today"]) end
        if data["auto_claim_daily_streak"] ~= nil then UpdateHub.autoClaimDailyStreak = parseToggle(data["auto_claim_daily_streak"]) end
        if data["auto_claim_mission"] ~= nil then UpdateHub.autoClaimMission = parseToggle(data["auto_claim_mission"]) end
        if data["auto_claim_charm_dust"] ~= nil then UpdateHub.autoClaimCharmDust = parseToggle(data["auto_claim_charm_dust"]) end
        if data["auto_claim_index"] ~= nil then UpdateHub.autoClaimIndex = parseToggle(data["auto_claim_index"]) end
        if data["auto_claim_jurassic_pass"] ~= nil then UpdateHub.autoClaimJurassicPass = parseToggle(data["auto_claim_jurassic_pass"]) end
        if data["auto_claim_jurassic_quests"] ~= nil then UpdateHub.autoClaimJurassicQuests = parseToggle(data["auto_claim_jurassic_quests"]) end
        if data["auto_deliver_jurassic_eggs"] ~= nil then UpdateHub.autoDeliverJurassicEggs = parseToggle(data["auto_deliver_jurassic_eggs"]) end
        if data["auto_return_to_coop_after_event"] ~= nil then UpdateHub.autoReturnToCoopAfterEvent = parseToggle(data["auto_return_to_coop_after_event"]) end
        if data["custom_front_coop_x"] ~= nil and data["custom_front_coop_y"] ~= nil and data["custom_front_coop_z"] ~= nil then
            local x = tonumber(data["custom_front_coop_x"])
            local y = tonumber(data["custom_front_coop_y"])
            local z = tonumber(data["custom_front_coop_z"])
            if x and y and z then
                UpdateHub.customFrontCoopPos = Vector3.new(x, y, z)
            end
        end
                if data["delivery_mode"] ~= nil then
            local dm = tostring(data["delivery_mode"])
            if dm:lower():find("hybrid") then
                UpdateHub.deliveryMode = "Hybrid"
            else
                UpdateHub.deliveryMode = "Safe Walk"
            end
        end
        if data["prioritize_egg_color"] ~= nil then UpdateHub.prioritizeEggColor = parseToggle(data["prioritize_egg_color"]) end
        if data["auto_detect_midway_egg"] ~= nil then UpdateHub.autoDetectMidwayEgg = parseToggle(data["auto_detect_midway_egg"]) end
        if data["cycle_delay"] ~= nil then UpdateHub.cycleDelay = tonumber(data["cycle_delay"]) or UpdateHub.cycleDelay end
        if data["event_walk_speed"] ~= nil then UpdateHub.eventWalkSpeed = tonumber(data["event_walk_speed"]) or UpdateHub.eventWalkSpeed end

        if data["esp_player_enabled"] ~= nil then espPlayerEnabled = parseToggle(data["esp_player_enabled"]) end
        if data["esp_egg_enabled"] ~= nil then espEggEnabled = parseToggle(data["esp_egg_enabled"]) end
        if data["esp_scrap_enabled"] ~= nil then espScrapEnabled = parseToggle(data["esp_scrap_enabled"]) end
        if data["streamer_mode_enabled"] ~= nil then streamerMode = parseToggle(data["streamer_mode_enabled"]) end
        if data["fake_name"] ~= nil then fakeName = tostring(data["fake_name"]) end
        if data["webhook_url"] ~= nil then webhookUrl = tostring(data["webhook_url"]) end
        if data["webhook_rebirth_enabled"] ~= nil then webhookRebirthEnabled = parseToggle(data["webhook_rebirth_enabled"]) end

        if data["auto_arena_fight"] ~= nil then UpdateHub.autoArenaFight = parseToggle(data["auto_arena_fight"]) end
        if data["delay_arena_fight"] ~= nil then UpdateHub.delayArenaFight = tonumber(data["delay_arena_fight"]) or UpdateHub.delayArenaFight end
        if data["auto_roll_charms"] ~= nil then UpdateHub.autoRollCharms = parseToggle(data["auto_roll_charms"]) end
        if data["selected_charm_chicken_name"] ~= nil then UpdateHub.selectedCharmChickenName = data["selected_charm_chicken_name"] end
        if data["charm_min_tier"] ~= nil then UpdateHub.charmMinTier = data["charm_min_tier"] end
        if data["charm_preferred_stats"] ~= nil and type(data["charm_preferred_stats"]) == "table" then
            UpdateHub.charmPreferredStats = data["charm_preferred_stats"]
        end
        if data["auto_claim_arena"] ~= nil then UpdateHub.autoClaimArena = parseToggle(data["auto_claim_arena"]) end
        if data["auto_claim_milestones"] ~= nil then UpdateHub.autoClaimMilestones = parseToggle(data["auto_claim_milestones"]) end
        if data["auto_keep_inverted"] ~= nil then UpdateHub.autoKeepInverted = parseToggle(data["auto_keep_inverted"]) end
        if data["auto_keep_jurassic"] ~= nil then UpdateHub.autoKeepJurassic = parseToggle(data["auto_keep_jurassic"]) end
        if data["egg_open_count"] ~= nil then UpdateHub.eggOpenRepeatCount = tonumber(data["egg_open_count"]) or UpdateHub.eggOpenRepeatCount end
        if data["tower_hp_threshold"] ~= nil then towerHpThreshold = tonumber(data["tower_hp_threshold"]) or towerHpThreshold end
        if data["tower_start_mode"] ~= nil then towerStartMode = tostring(data["tower_start_mode"]) end
        if data["auto_fuse"] ~= nil then autoFuse = parseToggle(data["auto_fuse"]) end
        if data["auto_promote"] ~= nil then autoPromote = parseToggle(data["auto_promote"]) end
        if data["misc_boost_fps"] ~= nil then UpdateHub.boostFps = parseToggle(data["misc_boost_fps"]) end
        if data["misc_low_textures"] ~= nil then UpdateHub.lowTextures = parseToggle(data["misc_low_textures"]) end
        if data["misc_disable_3d_render"] ~= nil then UpdateHub.disable3dRendering = parseToggle(data["misc_disable_3d_render"]) end
        if data["misc_fps_cap"] ~= nil then UpdateHub.fpsCap = tostring(data["misc_fps_cap"]) end

        -- 2. Terapkan visual ke semua elemen UI yang terdaftar via Flag
        for flag, val in pairs(data) do
            local el = registeredUiElements[flag]
            if el then
                pcall(function()
                    if type(el.SetValue) == "function" then
                        el:SetValue(val)
                    elseif type(el.Set) == "function" then
                        el:Set(val)
                    elseif type(el.Select) == "function" then
                        el:Select(val)
                    end
                end)
            end
        end

        -- Update visual khusus Tab Event (Jurassic Egg)
        if UpdateHub.movementModeDropdown then
            pcall(function()
                if type(UpdateHub.movementModeDropdown.SetValue) == "function" then
                    UpdateHub.movementModeDropdown:SetValue(UpdateHub.deliveryMode or "Safe Walk")
                end
            end)
        end
        if UpdateHub.walkSpeedDropdown then
            pcall(function()
                if type(UpdateHub.walkSpeedDropdown.SetValue) == "function" then
                    local wsStr = tostring(UpdateHub.eventWalkSpeed or 22)
                    local wsVal = wsStr == "22" and "22 (rekomen)" or wsStr
                    UpdateHub.walkSpeedDropdown:SetValue(wsVal)
                end
            end)
        end
        if UpdateHub.priorityEggDropdown then
            pcall(function()
                if type(UpdateHub.priorityEggDropdown.SetValue) == "function" then
                    local pVal = UpdateHub.prioritizeEggColor and "Prioritas Nilai Warna (Coklat > Hijau > Putih) [Direkomendasikan]" or "Jarak Terdekat Saja (Abaikan Warna)"
                    UpdateHub.priorityEggDropdown:SetValue(pVal)
                end
            end)
        end
        if UpdateHub.delayMovementInput then
            pcall(function()
                if type(UpdateHub.delayMovementInput.SetValue) == "function" then
                    UpdateHub.delayMovementInput:SetValue(tostring(UpdateHub.cycleDelay or 0.5))
                end
            end)
        end

        -- Update khusus dropdown ayam incubator & UFO
        if data["selected_incubator_chicken_name"] and chickenDropdown then
            pcall(function()
                if type(chickenDropdown.SetValue) == "function" then
                    chickenDropdown:SetValue(data["selected_incubator_chicken_name"])
                end
            end)
        end
        if data["selected_ufo_chicken_name"] and UpdateHub.ufoChickenDropdown then
            pcall(function()
                if type(UpdateHub.ufoChickenDropdown.SetValue) == "function" then
                    UpdateHub.ufoChickenDropdown:SetValue(data["selected_ufo_chicken_name"])
                end
            end)
        end
        if data["selected_boss_chicken_name"] and UpdateHub.bossChickenDropdown then
            pcall(function()
                if type(UpdateHub.bossChickenDropdown.SetValue) == "function" then
                    UpdateHub.bossChickenDropdown:SetValue(data["selected_boss_chicken_name"])
                end
            end)
        end

        notify("Config Manager", string.format("Config '%s' berhasil dimuat!", configName))
        printLog("Config Manager", string.format("Config '%s' berhasil diterapkan ke semua modul!", configName))
        return true
    end

    local function deleteConfigFile(configName)
        if not configName or configName == "" or configName == "Default" then
            notify("Config Manager", "Pilih config kustom yang ingin dihapus (bukan Default)!")
            return false
        end
        local deleted = false
        pcall(function()
            if type(delfile) == "function" then
                local p1 = ConfigSubFolder .. "/" .. configName .. ".json"
                local p2 = "SysHub_" .. configName .. ".json"
                if type(isfile) == "function" then
                    if isfile(p1) then delfile(p1); deleted = true end
                    if isfile(p2) then delfile(p2); deleted = true end
                else
                    pcall(delfile, p1)
                    pcall(delfile, p2)
                    deleted = true
                end
            end
        end)
        if deleted then
            notify("Config Manager", string.format("Config '%s' berhasil dihapus!", configName))
            printLog("Config Manager", string.format("Config '%s' dihapus dari storage.", configName))
            return true
        else
            notify("Config Manager", "Gagal menghapus file config!")
            return false
        end
    end

    local ConfigSec = MiscTab:Section({
        Title = "Configuration Manager",
        Opened = false
    })

    ConfigSec:Paragraph({
        Title = "Manual Config Manager",
        Desc = "Simpan dan muat preset konfigurasi secara manual ke penyimpanan executor.\nTidak ada auto-save atau auto-load otomatis."
    })

    local cfgState = {
        name = "Default",
        load = (getConfigFileList())[1] or "Default",
        delete = (getConfigFileList())[1] or "",
        dropdown = nil,
        deleteDropdown = nil
    }

    local function refreshAllConfigDropdowns(newSelect)
        local list = getConfigFileList()
        cfgState.delete = list[1] or ""
        if newSelect then
            cfgState.load = newSelect
        else
            cfgState.load = list[1] or "Default"
        end

        pcall(function()
            if cfgState.dropdown then
                if type(cfgState.dropdown.Refresh) == "function" then
                    cfgState.dropdown:Refresh(list, true)
                elseif type(cfgState.dropdown.SetValues) == "function" then
                    cfgState.dropdown:SetValues(list)
                end
                local valToSet = newSelect or list[1] or "Default"
                if type(cfgState.dropdown.SetValue) == "function" then
                    cfgState.dropdown:SetValue(valToSet)
                end
            end
        end)
        pcall(function()
            if cfgState.deleteDropdown then
                if type(cfgState.deleteDropdown.Refresh) == "function" then
                    cfgState.deleteDropdown:Refresh(list, true)
                elseif type(cfgState.deleteDropdown.SetValues) == "function" then
                    cfgState.deleteDropdown:SetValues(list)
                end
                if list[1] and type(cfgState.deleteDropdown.SetValue) == "function" then
                    cfgState.deleteDropdown:SetValue(list[1])
                end
            end
        end)
    end

    ConfigSec:Input({
        Title = "Nama Config Baru",
        Value = "Default",
        Placeholder = "Ketik nama config...",
        Callback = function(text)
            cfgState.name = string.gsub(text, "^%s*(.-)%s*$", "%1")
        end
    })

    ConfigSec:Button({
        Title = "Save Config",
        Callback = function()
            local nameToSave = cfgState.name
            if not nameToSave or nameToSave == "" then
                nameToSave = "Default"
            end
            local ok = saveConfigToFile(nameToSave)
            if ok then
                refreshAllConfigDropdowns(nameToSave)
            end
        end
    })

    cfgState.dropdown = ConfigSec:Dropdown({
        Title = "Pilih Config Yang Ingin Dimuat (Load):",
        Values = getConfigFileList(),
        Value = "Default",
        Callback = function(val)
            cfgState.load = val
        end
    })

    ConfigSec:Button({
        Title = "Load Config",
        Callback = function()
            local nameToLoad = cfgState.load or "Default"
            loadConfigFromFile(nameToLoad)
        end
    })

    cfgState.deleteDropdown = ConfigSec:Dropdown({
        Title = "Pilih Config Yang Ingin Dihapus (Delete):",
        Values = getConfigFileList(),
        Value = getConfigFileList()[1] or "",
        Callback = function(val)
            cfgState.delete = val
        end
    })

    ConfigSec:Button({
        Title = "Delete Config",
        Callback = function()
            local nameToDelete = cfgState.delete
            if not nameToDelete or nameToDelete == "" or nameToDelete == "Default" then
                notify("Config Manager", "Pilih config kustom yang ingin dihapus (bukan Default)!")
                return
            end
            local ok = deleteConfigFile(nameToDelete)
            if ok then
                refreshAllConfigDropdowns()
            end
        end
    })

    ConfigSec:Button({
        Title = "Refresh Config",
        Callback = function()
            refreshAllConfigDropdowns()
            local list = getConfigFileList()
            notify("Config Manager", string.format("Ditemukan %d config tersimpan.", #list))
        end
    })
end

-- ==============================================================================
-- [12.5] TAB WEBHOOK - DISCORD REBIRTH & EQUIPPED CHICKEN NOTIFIER
-- ==============================================================================
do
    local WebhookSec = WebhookTab:Section({
        Title = "Pengaturan Webhook Discord",
        Opened = false
    })

    -- Multi-executor HTTP Request Helper (Luau Linter Safe)
    local function sendHttpRequest(params)
        if WindUI and WindUI.Creator and type(WindUI.Creator.Request) == "function" then
            local ok, res = pcall(function()
                return WindUI.Creator.Request(params)
            end)
            if ok and res then return res end
        end

        local env = (getfenv and getfenv()) or _G or {}
        local synTable = rawget(env, "syn") or env.syn
        local fluxusTable = rawget(env, "fluxus") or env.fluxus
        local httpTable = rawget(env, "http") or env.http

        local req = (synTable and synTable.request)
            or (httpTable and httpTable.request)
            or (fluxusTable and fluxusTable.request)
            or rawget(env, "http_request")
            or rawget(env, "request")
            or env.http_request
            or env.request

        if type(req) == "function" then
            local ok, res = pcall(function()
                return req(params)
            end)
            if ok and res then return res end
        end
        return nil
    end

    -- Send Discord Webhook Helper
    local function sendDiscordWebhook(url, payloadTable)
        if not url or url == "" then
            return false, "URL Webhook kosong!"
        end
        if not (url:find("discord%.com/api/webhooks") or url:find("discordapp%.com/api/webhooks")) then
            return false, "Format URL bukan Webhook Discord yang valid!"
        end

        local okEncode, jsonPayload = pcall(function()
            return HttpService:JSONEncode(payloadTable)
        end)
        if not okEncode or not jsonPayload then
            return false, "Gagal meng-encode payload JSON"
        end

        local response = sendHttpRequest({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = jsonPayload
        })

        if response then
            local code = response.StatusCode or response.status_code or 200
            if code >= 200 and code < 300 then
                return true, "Berhasil terkirim!"
            else
                return false, "Discord error HTTP " .. tostring(code)
            end
        end
        return false, "Tidak ada respon dari HTTP executor (periksa koneksi / executor)"
    end

    -- Helper Ambil Data Detail Ayam yang Sedang Dipakai
    local function getDetailedActiveChickenInfo()
        local cId, cName, cData = nil, nil, nil
        if UpdateHub and type(UpdateHub.getCurrentActiveChicken) == "function" then
            cId, cName, cData = UpdateHub.getCurrentActiveChicken()
        end

        if not cId then
            pcall(function()
                local dsClient = getSharedDataServiceClient()
                local raw = dsClient and dsClient._data and dsClient._data._data
                if raw and raw.vitals and raw.vitals.id then
                    cId = raw.vitals.id
                end
            end)
        end

        local rawChickenObj = nil
        pcall(function()
            local dsClient = getSharedDataServiceClient()
            local raw = dsClient and dsClient._data and dsClient._data._data
            if raw and raw.roster and raw.roster.chickens then
                for _, ch in pairs(raw.roster.chickens) do
                    if type(ch) == "table" and tostring(ch.id) == tostring(cId) then
                        rawChickenObj = ch
                        break
                    end
                end
            end
        end)

        local bodyStatus = getChickenStatus()
        local atBase = isChickenAtBase()
        local curFloor = getCurrentFloor()
        local locStr = "Base / Kandang (Coop)"
        if not atBase then
            if curFloor and curFloor > 0 then
                locStr = string.format("Tower Lantai %d", curFloor)
            else
                locStr = "Pertarungan / Di Luar Base"
            end
        end

        local info = {
            Id = cId or "N/A",
            Name = cName or "Ayam Tidak Terdeteksi",
            Species = "Unknown",
            Level = 1,
            Stars = 0,
            Rarity = "COMMON",
            Mutation = "Tidak Ada",
            PowerStr = "0",
            HpPercent = math.floor((bodyStatus.HpFrac or 1) * 100),
            IsAlive = bodyStatus.IsAlive,
            Location = locStr
        }

        if cData then
            info.Name = cData.Name or info.Name
            info.Species = cData.Species or info.Species
            info.Level = cData.LvlNum or (tonumber(string.match(tostring(cData.Lvl or ""), "%d+")) or 1)
            info.Stars = cData.Stars or 0
            info.Rarity = cData.Rarity or "COMMON"
            if cData.Mutation and cData.Mutation ~= "" then
                info.Mutation = cData.Mutation
            end
        end

        if rawChickenObj then
            if rawChickenObj.typeId then
                info.Species = formatSpeciesName(rawChickenObj.typeId)
            end
            if rawChickenObj.level then
                info.Level = tonumber(rawChickenObj.level) or info.Level
            end
            if rawChickenObj.promo then
                info.Stars = tonumber(rawChickenObj.promo) or info.Stars
            end
            if rawChickenObj.rarity then
                info.Rarity = tostring(rawChickenObj.rarity):upper()
            end
            if rawChickenObj.mutation then
                if type(rawChickenObj.mutation) == "string" and #rawChickenObj.mutation > 0 and rawChickenObj.mutation:lower() ~= "none" then
                    info.Mutation = rawChickenObj.mutation:sub(1,1):upper() .. rawChickenObj.mutation:sub(2):lower()
                elseif type(rawChickenObj.mutation) == "table" and rawChickenObj.mutation.name then
                    local m = tostring(rawChickenObj.mutation.name)
                    info.Mutation = m:sub(1,1):upper() .. m:sub(2):lower()
                end
            end

            if UpdateHub and type(UpdateHub.getChickenArenaPower) == "function" then
                local _, pStr = UpdateHub.getChickenArenaPower(rawChickenObj)
                if pStr and pStr ~= "0" then
                    info.PowerStr = pStr
                end
            end
        end

        return info
    end

    -- Warna Rarity untuk Embed Discord
    local RARITY_COLORS = {
        ["COMMON"] = 0x95A5A6,
        ["UNCOMMON"] = 0x2ECC71,
        ["RARE"] = 0x3498DB,
        ["EPIC"] = 0x9B59B6,
        ["LEGENDARY"] = 0xF1C40F,
        ["MYTHIC"] = 0xE74C3C,
        ["SECRET"] = 0xE91E63,
        ["CELESTIAL"] = 0x1ABC9C,
        ["COSMIC"] = 0x00FFFF
    }

    -- Fungsi Utama Pengiriman Notifikasi Rebirth
    local isSendingRebirth = false
    local function sendRebirthNotification(targetRebirthNum, isPreview)
        if not webhookUrl or webhookUrl == "" then
            if isPreview then
                notify("Webhook", "Harap masukkan URL Webhook Discord terlebih dahulu!")
            end
            return false
        end

        if isSendingRebirth then
            return false
        end
        isSendingRebirth = true

        local success = false
        local errReport = ""

        local ok, err = pcall(function()
            local rbNum = tonumber(targetRebirthNum) or getRebirthCount()
            local nextReqFloor = getExactRebirthRequirement(rbNum)
            local chicken = getDetailedActiveChickenInfo()

            local pName = (streamerMode and (fakeName or "Anonymous")) or player.Name
            local pDisplay = (streamerMode and (fakeName or "Anonymous")) or player.DisplayName
            local headshotUrl = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150&format=png", player.UserId)

            local embedColor = RARITY_COLORS[chicken.Rarity] or 0x2ECC71
            if isPreview then
                embedColor = 0x3498DB
            end

            local starDisplay = ""
            if chicken.Stars and chicken.Stars > 0 then
                starDisplay = " ★" .. tostring(chicken.Stars)
            end

            local titleText = isPreview and "🧪 [PREVIEW] Notifikasi Rebirth" or "🎉 BERHASIL REBIRTH!"
            local descText = string.format("Pengguna **%s** (`@%s`) telah berhasil melakukan **Rebirth ke #%d**!", pDisplay, pName, rbNum)

            local payload = {
                ["username"] = "SysHub - Rebirth Tracker",
                ["avatar_url"] = headshotUrl,
                ["embeds"] = {
                    {
                        ["title"] = titleText,
                        ["description"] = descText,
                        ["color"] = embedColor,
                        ["fields"] = {
                            {
                                ["name"] = "👑 Rebirth Tercapai",
                                ["value"] = string.format("**Rebirth #%d**", rbNum),
                                ["inline"] = true
                            },
                            {
                                ["name"] = "🎯 Syarat Rebirth Berikutnya",
                                ["value"] = string.format("Lantai **%s**", tostring(nextReqFloor)),
                                ["inline"] = true
                            },
                            {
                                ["name"] = "🐔 Ayam yang Sedang Dipakai",
                                ["value"] = string.format("**%s**%s\nSpesies: `%s` | Level: `%d`\nRarity: `%s` | Mutasi: `%s`", 
                                    tostring(chicken.Name),
                                    starDisplay,
                                    tostring(chicken.Species),
                                    chicken.Level,
                                    tostring(chicken.Rarity),
                                    tostring(chicken.Mutation)
                                ),
                                ["inline"] = false
                            },
                            {
                                ["name"] = "⚡ Arena Power",
                                ["value"] = tostring(chicken.PowerStr),
                                ["inline"] = true
                            },
                            {
                                ["name"] = "❤️ HP Saat Ini",
                                ["value"] = string.format("%d%% (%s)", chicken.HpPercent, chicken.IsAlive and "Hidup" or "KO"),
                                ["inline"] = true
                            },
                            {
                                ["name"] = "📍 Lokasi Ayam",
                                ["value"] = tostring(chicken.Location),
                                ["inline"] = true
                            }
                        },
                        ["thumbnail"] = {
                            ["url"] = headshotUrl
                        },
                        ["footer"] = {
                            ["text"] = "SysHub • Grow A Chicken Fighter • " .. os.date("%d/%m/%Y %H:%M:%S"),
                            ["icon_url"] = headshotUrl
                        },
                        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
                    }
                }
            }

            local sendOk, msg = sendDiscordWebhook(webhookUrl, payload)
            if sendOk then
                success = true
                printLog("Webhook", string.format("Notifikasi Rebirth ke #%d berhasil dikirim ke Discord!", rbNum))
                if isPreview then
                    notify("Webhook", "Pesan preview berhasil terkirim ke Discord!")
                else
                    notify("Webhook", string.format("Notifikasi Rebirth ke #%d terkirim ke Discord!", rbNum))
                end
            else
                errReport = tostring(msg)
                logError("Webhook", "Gagal mengirim webhook: " .. tostring(msg))
                if isPreview then
                    notify("Webhook Gagal", tostring(msg))
                end
            end
        end)

        isSendingRebirth = false

        if not ok then
            logError("Webhook Notification", err)
            if isPreview then
                notify("Webhook Error", tostring(err))
            end
        end

        return success
    end

    -- Forward Callback Implementation
    local highestReportedRebirth = 0
    triggerWebhookRebirthEvent = function(newCount)
        local count = tonumber(newCount) or 0
        if count <= 0 then return end
        if count <= highestReportedRebirth then return end
        highestReportedRebirth = count

        if webhookRebirthEnabled and webhookUrl and webhookUrl ~= "" then
            task.spawn(function()
                sendRebirthNotification(count, false)
            end)
        end
    end

    -- Background Watcher: Deteksi jika Rebirth bertambah (Manual atau Fast Rebirth)
    task.spawn(function()
        task.wait(3)
        highestReportedRebirth = getRebirthCount()
        while true do
            task.wait(1.5)
            local cur = getRebirthCount()
            if cur > highestReportedRebirth then
                triggerWebhookRebirthEvent(cur)
            end
        end
    end)

    -- UI ELEMENTS DI WEBHOOK TAB
    WebhookSec:Paragraph({
        Title = "Webhook Discord Notifier",
        Desc = "Tab ini mengirimkan notifikasi otomatis ke Discord setiap kali Anda berhasil melakukan Rebirth, lengkap dengan data ayam yang sedang dipakai."
    })

    WebhookSec:Input({
        Title = "URL Webhook Discord",
        Flag = "webhook_url",
        Value = webhookUrl,
        Callback = function(text)
            if text then
                webhookUrl = string.gsub(text, "^%s*(.-)%s*$", "%1")
                saveConfig()
            end
        end
    })

    WebhookSec:Toggle({
        Title = "Kirim Notif Berhasil Rebirth",
        Flag = "webhook_rebirth_enabled",
        Value = webhookRebirthEnabled,
        Callback = function(state)
            webhookRebirthEnabled = parseToggle(state)
            saveConfig()
        end
    })

    WebhookSec:Button({
        Title = "Kirim Notif Rebirth Sekarang (Preview)",
        Callback = function()
            local cur = getRebirthCount()
            sendRebirthNotification(cur > 0 and cur or 1, true)
        end
    })
end

-- ==============================================================================
end
