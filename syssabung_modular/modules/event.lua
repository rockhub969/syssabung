-- ==============================================================================
--              SYSHUB | MODUL EVENT (JURASSIC, UFO & CHICKEN BOSS)
-- ==============================================================================
return function(Context, EventTab)
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

-- [11B] JURASSIC EVENT CONTROLLER & TAB EVENT UI
-- ==============================================================================

UpdateHub.recentPickedJurassicEggs = {}
UpdateHub.lastJurassicEggCheckTime = 0
UpdateHub.cachedJurassicEggActive = false

-- Watcher Real-Time Deteksi Telur Tersenggol di Jalan (Mid-Path Intercept)
UpdateHub.midpathWatcherConnections = {}

UpdateHub.isEggLikeObject = function(obj)
    local success, result = pcall(function()
        local n = obj.Name:lower()
        if n:find("root") or n:find("head") or n:find("torso") or n:find("arm") 
           or n:find("leg") or n:find("humanoid") or n:find("animate") 
           or n:find("accessory") or n:find("hat") or n:find("shirt") 
           or n:find("pants") or n:find("body") or n:find("face") 
           or n:find("health") or n:find("sound") or n:find("script") then
            return false
        end
        if obj:GetAttribute("StackKind") == "ancientEgg" then return true end
        if obj:GetAttribute("CarryAttr") then return true end
        if obj:GetAttribute("EggType") then return true end
        if obj:GetAttribute("Egg") then return true end
        if n:find("egg") or n:find("ancient") or n:find("pitscrap") 
           or n:find("loose") or n:find("telur") then
            return true
        end
        if obj:IsA("Tool") then
            if n:find("egg") or n:find("ancient") or n:find("carry") 
               or n:find("loose") or n:find("pitscrap") then
                return true
            end
        end
        return false
    end)
    return success and result or false
end

UpdateHub.setupMidpathWatcher = function()
    for _, conn in ipairs(UpdateHub.midpathWatcherConnections) do
        pcall(function() conn:Disconnect() end)
    end
    UpdateHub.midpathWatcherConnections = {}

    local char = player.Character
    if not char then return end

    local conn1 = char.ChildAdded:Connect(function(child)
        if UpdateHub.autoDetectMidwayEgg ~= false and UpdateHub.isDeliveringJurassicEgg then
            task.defer(function()
                if UpdateHub.isEggLikeObject(child) then
                    UpdateHub.holdingJurassicEgg = true
                    UpdateHub.holdingJurassicEggTime = os.clock()
                    UpdateHub.midwayEggDetected = true
                    printLog("Mid-Path Watcher", "TERDETEKSI! Objek telur muncul di Character: " .. child.Name)
                end
            end)
        end
    end)
    table.insert(UpdateHub.midpathWatcherConnections, conn1)

    local conn2 = char.DescendantAdded:Connect(function(desc)
        if UpdateHub.autoDetectMidwayEgg ~= false and UpdateHub.isDeliveringJurassicEgg then
            task.defer(function()
                if UpdateHub.isEggLikeObject(desc) then
                    UpdateHub.holdingJurassicEgg = true
                    UpdateHub.holdingJurassicEggTime = os.clock()
                    UpdateHub.midwayEggDetected = true
                    printLog("Mid-Path Watcher", "TERDETEKSI (Descendant)! Objek telur muncul di Character: " .. desc.Name)
                end
            end)
        end
    end)
    table.insert(UpdateHub.midpathWatcherConnections, conn2)
end

UpdateHub.setupMidpathWatcher()
player.CharacterAdded:Connect(function(newChar)
    task.wait(0.5)
    UpdateHub.setupMidpathWatcher()
end)

-- Helper Teleport Instan (Digunakan untuk Mode Hybrid Pintar)
UpdateHub.instantTeleportTo = function(pos)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    enableNoclip()
    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 0.5, 0))
        if char.PrimaryPart then
            char:SetPrimaryPartCFrame(CFrame.new(pos + Vector3.new(0, 0.5, 0)))
        end
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end)
    task.wait(0.12)
    return true
end

-- Safe Walk To Egg dengan Interupsi Mid-Path Cepat & Unstuck Pintar
UpdateHub.safeWalkToEgg = function(targetPos, stopDistance, earlyExitCallback)
    stopDistance = tonumber(stopDistance) or 2.0
    local char = player.Character
    if not char then return "ERROR" end
    local humanoid = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return "ERROR" end

    local targetSpeed = tonumber(UpdateHub.eventWalkSpeed) or 22
    pcall(function()
        humanoid.WalkSpeed = targetSpeed
    end)

    enableNoclip()
    pcall(function()
        humanoid:MoveTo(targetPos)
    end)

    local initialDist = (Vector3.new(targetPos.X, 0, targetPos.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude
    local maxWait = math.clamp(initialDist / 8, 3.0, 16.0)
    local timeout = 0
    local lastPos = hrp.Position
    local stuckTimer = 0

    UpdateHub.midwayEggDetected = false

    while timeout < maxWait do
        if not UpdateHub.autoDeliverJurassicEggs and not UpdateHub.isDeliveringJurassicEgg then break end

        -- Cek flag real-time Mid-Path Watcher (INSTANT)
        if UpdateHub.autoDetectMidwayEgg ~= false and UpdateHub.midwayEggDetected == true then
            disableNoclip()
            pcall(function() humanoid:MoveTo(hrp.Position) end)
            printLog("Mid-Path", "INTERUPSI INSTAN via real-time watcher!")
            return "INTERRUPTED"
        end

        -- Cek interupsi dini via callback (fallback)
        if earlyExitCallback and earlyExitCallback() then
            disableNoclip()
            pcall(function() humanoid:MoveTo(hrp.Position) end)
            return "INTERRUPTED"
        end

        task.wait(0.05)
        timeout = timeout + 0.05

        -- Jaga WalkSpeed agar stabil
        if humanoid.WalkSpeed ~= targetSpeed then
            pcall(function() humanoid.WalkSpeed = targetSpeed end)
        end

        local currentPos = hrp.Position
        local dist = (Vector3.new(currentPos.X, 0, currentPos.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude
        if dist <= stopDistance then
            disableNoclip()
            pcall(function() humanoid:MoveTo(hrp.Position) end)
            return "ARRIVED"
        end

        stuckTimer = stuckTimer + 0.05
        if stuckTimer >= 0.4 then
            local moveDist = (Vector3.new(currentPos.X, 0, currentPos.Z) - Vector3.new(lastPos.X, 0, lastPos.Z)).Magnitude
            if moveDist < 0.8 then
                pcall(function()
                    humanoid.Jump = true
                    local direction = (Vector3.new(targetPos.X, currentPos.Y, targetPos.Z) - currentPos).Unit
                    hrp.CFrame = hrp.CFrame + (direction * 1.5)
                    humanoid:MoveTo(targetPos)
                end)
            else
                pcall(function()
                    humanoid:MoveTo(targetPos)
                end)
            end
            lastPos = currentPos
            stuckTimer = 0
        end
    end
    disableNoclip()
    pcall(function() humanoid:MoveTo(hrp.Position) end)
    return "TIMEOUT"
end

-- Helper Kembali ke Depan Base / Coop Setelah Event Telur Purba Selesai
UpdateHub.returnToFrontOfCoop = function()
    local targetPos = getFrontOfCoopPosition()
    if not targetPos then
        targetPos = getCoopPosition()
    end
    if not targetPos then
        printLog("Jurassic Event", "Gagal menemukan posisi depan base/coop!")
        return false
    end

    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    printLog("Jurassic Event", "Event Selesai: Mengembalikan karakter ke depan base/coop...")
    notify("Telur Purba", "Event selesai! Karakter kembali ke depan base/coop.")

    disableNoclip()
    pcall(function()
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum:MoveTo(hrp.Position) end
    end)
    task.wait(0.1)

    local isHybrid = (UpdateHub.deliveryMode and UpdateHub.deliveryMode:find("Hybrid")) ~= nil
    local dist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude

    if isHybrid or dist > 80 then
        UpdateHub.instantTeleportTo(targetPos)
        task.wait(0.2)
        disableNoclip()
        pcall(function()
            local coopBase = getCoopPosition()
            if coopBase and hrp then
                hrp.CFrame = CFrame.lookAt(targetPos, Vector3.new(coopBase.X, targetPos.Y, coopBase.Z))
            end
        end)
    else
        UpdateHub.safeWalkToEgg(targetPos, 3.0)
        disableNoclip()
    end

    pcall(function()
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end)
    return true
end

-- Deteksi AncientEgg Sentral di Pit
UpdateHub.findPitGiantEgg = function()
    for _, obj in ipairs(Workspace:GetChildren()) do
        local n = obj.Name:lower()
        if not n:find("chicken") and not n:find("player") and not n:find("hot") and (obj:IsA("Model") or obj:IsA("BasePart")) then
            local pos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
            local dist = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(0, 0, 0)).Magnitude
            if dist <= 18 and (n:find("ancient") or n:find("jurassic") or n == "ancientegg" or n == "jurassicegg") then
                return obj
            end
        end
    end

    local pit = Workspace:FindFirstChild("Pit") 
        or (Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("Pit"))
        or Workspace:FindFirstChild("Arena")
        or (Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("Arena"))
    
    if pit then
        for _, desc in ipairs(pit:GetDescendants()) do
            local n = desc.Name:lower()
            if (desc:IsA("BasePart") or desc:IsA("Model")) and not n:find("chicken") and not n:find("player") and not n:find("hot") then
                if n:find("ancient") or n:find("jurassic") or n == "ancientegg" or n == "jurassicegg" then
                    local pos = desc:IsA("Model") and desc:GetPivot().Position or desc.Position
                    local dist = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(0, 0, 0)).Magnitude
                    if dist <= 18 then
                        return desc
                    end
                end
            end
        end
    end

    return nil
end

-- Deteksi Status Aktif Event Jurassic
UpdateHub.isJurassicEggEventActive = function()
    if UpdateHub.isJurassicEggLive == true then
        return true
    end

    local now = os.clock()
    if now - UpdateHub.lastJurassicEggCheckTime < 1.5 then
        return UpdateHub.cachedJurassicEggActive
    end
    UpdateHub.lastJurassicEggCheckTime = now

    local pitEgg = UpdateHub.findPitGiantEgg()
    if pitEgg then
        UpdateHub.cachedJurassicEggActive = true
        return true
    end

    local ok, res = pcall(function()
        return invokeRemote("LiveEventGetActive")
    end)
    if ok and res then
        local str = ""
        if type(res) == "string" then
            str = res:lower()
        elseif type(res) == "table" then
            for k, v in pairs(res) do
                str = str .. " " .. tostring(k):lower() .. " " .. tostring(v):lower()
            end
        end
        if not str:find("hot") and not str:find("ufo") then
            if str:find("jurassic") or str:find("ancient") or str:find("purba") or str:find("dino") then
                UpdateHub.cachedJurassicEggActive = true
                return true
            end
        end
    end

    UpdateHub.cachedJurassicEggActive = false
    return false
end

-- Klasifikasi Warna & Nilai Poin Telur Purba (Tier 3 Coklat > Tier 2 Hijau > Tier 1 Putih)
UpdateHub.classifyJurassicEggColor = function(obj)
    local targetPart = obj
    if not targetPart:IsA("BasePart") then
        targetPart = targetPart:FindFirstChildWhichIsA("BasePart", true) or targetPart.PrimaryPart
    end
    if not targetPart then
        return 1, "Putih"
    end

    for _, attr in ipairs({"StackTier", "ColorName", "EggColor", "Tier", "EggType", "Rarity", "Kind", "Value", "Quality"}) do
        local val = targetPart:GetAttribute(attr) or obj:GetAttribute(attr)
        if val then
            local s = tostring(val):lower()
            if s:find("brown") or s:find("coklat") or s:find("mud") or s:find("dirt") or s:find("rock") or s:find("ancient") or s:find("gold") or s:find("bronze") or s == "3" or s:find("tier3") or s:find("high") or s:find("legend") then
                return 3, "Coklat"
            elseif s:find("vine") or s:find("moss") or s:find("green") or s:find("hijau") or s:find("lime") or s == "2" or s:find("tier2") or s:find("med") or s:find("rare") then
                return 2, "Hijau"
            elseif s:find("normal") or s:find("khaki") or s:find("white") or s:find("putih") or s:find("silver") or s == "1" or s:find("tier1") or s:find("low") or s:find("common") then
                return 1, "Putih"
            end
        end
    end

    local bc = targetPart.BrickColor
    local bcName = bc and bc.Name:lower() or ""

    local brownKeywords = {"brown", "rust", "copper", "dirt", "sand", "earth", "taupe", "nougat", "umber", "chocolate", "bronze", "dark orange", "carmine", "tan", "terracotta", "maroon", "brick red"}
    for _, kw in ipairs(brownKeywords) do
        if bcName:find(kw) then return 3, "Coklat" end
    end

    local greenKeywords = {"green", "lime", "camo", "forest", "olive", "sage", "mint", "emerald", "sea green", "spring", "grime", "moss"}
    for _, kw in ipairs(greenKeywords) do
        if bcName:find(kw) then return 2, "Hijau" end
    end

    local whiteKeywords = {"white", "grey", "gray", "silver", "ghost", "flint", "stone", "pearl", "snow", "fog", "cloud", "khaki"}
    for _, kw in ipairs(whiteKeywords) do
        if bcName:find(kw) then return 1, "Putih" end
    end

    local c = targetPart.Color
    local h, s, v = c:ToHSV()
    if h >= 0.18 and h <= 0.48 and s > 0.20 and v > 0.15 then
        return 2, "Hijau"
    end
    if (h <= 0.14 or h >= 0.95) and s > 0.25 and v >= 0.10 and v <= 0.72 then
        if c.R > c.B and (c.R - c.B) > 0.12 then
            return 3, "Coklat"
        end
    end

    return 1, "Putih"
end

-- Deteksi Telur Tercecer yang Dapat Diambil (Mendukung Prioritas Warna Tier & Jarak)
UpdateHub.findCollectibleJurassicEggs = function()
    local eggs = {}
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local myPos = hrp and hrp.Position or Vector3.new(0, 0, 0)
    local pitEgg = UpdateHub.findPitGiantEgg()
    local pitPos = pitEgg and (pitEgg:IsA("Model") and pitEgg:GetPivot().Position or pitEgg.Position) or Vector3.new(0, 4, 0)

    local checkedMap = {}

    local function checkAndAddEgg(obj, sourceName)
        if not obj or checkedMap[obj] then return end
        if not (obj:IsA("Model") or obj:IsA("BasePart")) then return end
        checkedMap[obj] = true

        if UpdateHub.recentPickedJurassicEggs[obj] and (os.clock() - UpdateHub.recentPickedJurassicEggs[obj]) < 8 then
            return
        end

        local n = obj.Name:lower()

        if n:find("chicken") or n:find("nestegg") or n:find("incubator") or n:find("coop") or n:find("hot") then
            return
        end
        if n == "collider" or n == "post" or n == "floor" or n == "wall" or n == "barrier" then
            return
        end
        if obj == pitEgg or obj.Parent == pitEgg then
            return
        end

        local pos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
        local distFromCenter = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(pitPos.X, 0, pitPos.Z)).Magnitude
        if distFromCenter <= 5 and (n:find("ancient") or n:find("egg")) then
            return
        end

        local isEgg = false
        local stackKind = obj:GetAttribute("StackKind")
        local carryAttr = obj:GetAttribute("CarryAttr")
        local skStr = tostring(stackKind or ""):lower()
        local caStr = tostring(carryAttr or ""):lower()

        if skStr:find("hot") or caStr:find("hot") or n:find("hot") then
            return
        end

        if skStr:find("ancient") or skStr:find("jurassic") or skStr:find("dino") or skStr:find("purba") or (skStr:find("shard") and not skStr:find("meteor")) then
            isEgg = true
        elseif caStr:find("ancient") or caStr:find("jurassic") or caStr:find("dino") or caStr:find("purba") then
            isEgg = true
        elseif obj:GetAttribute("AncientEgg") ~= nil or obj:GetAttribute("JurassicEgg") == true then
            isEgg = true
        elseif n:find("ancient") or n:find("jurassic") or n:find("purba") or n:find("dino") or (n:find("shard") and not n:find("meteor")) then
            isEgg = true
        elseif (n == "loose" or stackKind) and pitEgg and distFromCenter <= 160 and skStr ~= "scrap" and skStr ~= "goldcoin" and skStr ~= "none" then
            isEgg = true
        elseif obj:FindFirstChildWhichIsA("ProximityPrompt", true) then
            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
            local act = (prompt.ActionText or ""):lower()
            local objTxt = (prompt.ObjectText or ""):lower()
            if not act:find("hot") and not objTxt:find("hot") then
                if act:find("ancient") or act:find("jurassic") or act:find("purba") 
                   or objTxt:find("ancient") or objTxt:find("jurassic") or objTxt:find("purba") then
                    isEgg = true
                end
            end
        end

        if isEgg then
            local distFromMe = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(myPos.X, 0, myPos.Z)).Magnitude
            local tier, colorName = UpdateHub.classifyJurassicEggColor(obj)
            table.insert(eggs, {
                object = obj,
                position = pos,
                distance = distFromMe,
                name = obj.Name,
                tier = tier,
                colorName = colorName
            })
        end
    end

    local scanFolders = {}
    local function addFolderIfExist(f)
        if f and typeof(f) == "Instance" then table.insert(scanFolders, f) end
    end

    addFolderIfExist(Workspace:FindFirstChild("PitScrap"))
    addFolderIfExist(Workspace:FindFirstChild("Pit"))
    addFolderIfExist(Workspace:FindFirstChild("World"))
    addFolderIfExist(Workspace:FindFirstChild("Drops"))

    local world = Workspace:FindFirstChild("World")
    if world then
        addFolderIfExist(world:FindFirstChild("PitScrap"))
        addFolderIfExist(world:FindFirstChild("Pit"))
        addFolderIfExist(world:FindFirstChild("Drops"))
        addFolderIfExist(world:FindFirstChild("Loose"))
    end

    for _, folder in ipairs(scanFolders) do
        for _, desc in ipairs(folder:GetDescendants()) do
            checkAndAddEgg(desc, folder.Name)
        end
    end

    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
            local pPart = prompt.Parent
            if pPart then
                checkAndAddEgg(pPart, "ProximityPrompt")
            end
        end
    end

    for _, obj in ipairs(Workspace:GetChildren()) do
        checkAndAddEgg(obj, "Workspace")
    end

    if UpdateHub.prioritizeEggColor ~= false then
        table.sort(eggs, function(a, b)
            if a.tier ~= b.tier then
                return a.tier > b.tier
            end
            return a.distance < b.distance
        end)
    else
        table.sort(eggs, function(a, b)
            return a.distance < b.distance
        end)
    end

    local result = {}
    for _, item in ipairs(eggs) do
        table.insert(result, item.object)
    end
    return result, eggs
end

-- Cek Apakah Karakter Memegang Telur Purba (Multi-Layer: Watcher, Tool, Fisik, Backpack, State)
UpdateHub.isCarryingJurassicEgg = function()
    local char = player.Character
    if not char then return false end

    -- 0. Cek flag real-time dari Mid-Path Watcher (TERCEPAT)
    if UpdateHub.midwayEggDetected == true then
        return true, "MidpathWatcher"
    end

    -- 1. Cek Tool di Character
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") then
            local n = child.Name:lower()
            if n:find("egg") or n:find("ancient") or n:find("carry") or n:find("loose") or n:find("pitscrap") or n:find("telur") then
                return true, "Tool:" .. child.Name
            end
            if child:GetAttribute("StackKind") == "ancientEgg" or child:GetAttribute("CarryAttr") or child:GetAttribute("EggType") then
                return true, "ToolAttr:" .. child.Name
            end
        end
    end

    -- 2. Cek Objek Fisik Telur di dalam Character
    for _, child in ipairs(char:GetDescendants()) do
        if child:IsA("BasePart") or child:IsA("Model") or child:IsA("Tool") then
            local n = child.Name:lower()
            if not n:find("root") and not n:find("head") and not n:find("torso") and not n:find("arm") and not n:find("leg") and not n:find("accessory") and not n:find("attachment") and not n:find("animate") and not n:find("humanoid") and not n:find("handle") and not n:find("body") and not n:find("shirt") and not n:find("pants") and not n:find("face") then
                local sk = child:GetAttribute("StackKind")
                local ca = child:GetAttribute("CarryAttr")
                local et = child:GetAttribute("EggType")
                if sk == "ancientEgg" or ca or et or (n:find("ancient") and n:find("egg")) or n:find("pitscrap") or n:find("loose") or (n:find("egg") and not n:find("legg")) then
                    return true, "Physical:" .. child.Name
                end
            end
        end
    end

    -- 3. Cek Attribute spesifik pada Character
    for attr, val in pairs(char:GetAttributes()) do
        local a = attr:lower()
        if (a:find("carry") or a:find("holding") or a:find("egg")) and (val == true or (type(val) == "number" and val > 0)) then
            return true, "CharAttr:" .. attr
        end
    end

    -- 4. Cek Backpack apakah ada Tool telur
    local backpackTool = nil
    pcall(function()
        local bp = player:FindFirstChild("Backpack")
        if bp then
            for _, item in ipairs(bp:GetChildren()) do
                if item:IsA("Tool") then
                    local n = item.Name:lower()
                    if n:find("egg") or n:find("ancient") or n:find("carry") or n:find("telur") then
                        backpackTool = item.Name
                        break
                    end
                end
            end
        end
    end)
    if backpackTool then
        return true, "Backpack:" .. tostring(backpackTool)
    end

    -- 5. Fallback Internal State (timeout 12 detik)
    if UpdateHub.holdingJurassicEgg == true then
        local now = os.clock()
        if UpdateHub.holdingJurassicEggTime and (now - UpdateHub.holdingJurassicEggTime) > 12 then
            UpdateHub.holdingJurassicEgg = false
            UpdateHub.midwayEggDetected = false
            return false
        end
        return true, "InternalHolding"
    end

    return false
end

-- Ambil Telur Purba (Menempel Langsung & Konfirmasi Terangkat)
UpdateHub.pickupJurassicEgg = function(eggObj)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not eggObj or not eggObj.Parent then return false end

    local targetPart = eggObj:IsA("BasePart") and eggObj or (eggObj:FindFirstChildWhichIsA("BasePart", true) or eggObj.PrimaryPart or eggObj)
    local humanoid = char:FindFirstChild("Humanoid")

    local prompts = {}
    for _, p in ipairs(eggObj:GetDescendants()) do
        if p:IsA("ProximityPrompt") then table.insert(prompts, p) end
    end
    if eggObj:IsA("ProximityPrompt") then table.insert(prompts, eggObj) end
    if eggObj.Parent and eggObj.Parent:FindFirstChildWhichIsA("ProximityPrompt") then
        table.insert(prompts, eggObj.Parent:FindFirstChildWhichIsA("ProximityPrompt"))
    end

    for attempt = 1, 5 do
        for _, prompt in ipairs(prompts) do
            pcall(function()
                prompt.RequiresLineOfSight = false
                prompt.MaxActivationDistance = 40
                prompt.HoldDuration = 0
                fireproximityprompt(prompt)
            end)
        end

        if firetouchinterest and targetPart and targetPart:IsA("BasePart") then
            pcall(function()
                firetouchinterest(hrp, targetPart, 0)
                task.wait(0.02)
                firetouchinterest(hrp, targetPart, 1)
            end)
        end

        for _, desc in ipairs(eggObj:GetDescendants()) do
            if desc:IsA("BasePart") and desc:FindFirstChild("TouchInterest") and firetouchinterest then
                pcall(function()
                    firetouchinterest(hrp, desc, 0)
                    task.wait(0.01)
                    firetouchinterest(hrp, desc, 1)
                end)
            end
        end

        task.wait(0.1)

        local carrying, _ = UpdateHub.isCarryingJurassicEgg()
        if carrying or not eggObj.Parent or not eggObj:IsDescendantOf(Workspace) then
            UpdateHub.holdingJurassicEgg = true
            UpdateHub.holdingJurassicEggTime = os.clock()
            UpdateHub.recentPickedJurassicEggs[eggObj] = os.clock()
            if eggObj.Parent then UpdateHub.recentPickedJurassicEggs[eggObj.Parent] = os.clock() end
            printLog("Jurassic Egg", "Telur tercecer berhasil terangkat: " .. eggObj.Name)
            return true
        end

        pcall(function()
            if humanoid and targetPart then
                humanoid:MoveTo(targetPart.Position)
            end
        end)
    end

    UpdateHub.holdingJurassicEgg = true
    UpdateHub.holdingJurassicEggTime = os.clock()
    UpdateHub.recentPickedJurassicEggs[eggObj] = os.clock()
    if eggObj.Parent then UpdateHub.recentPickedJurassicEggs[eggObj.Parent] = os.clock() end
    printLog("Jurassic Egg", "Selesai memicu interaksi telur: " .. eggObj.Name)
    return true
end

-- Masukkan / Setor Telur ke AncientEgg di Pit (Sentuhan Fisik Langsung)
UpdateHub.depositJurassicEggToPit = function(pitEgg)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    if not pitEgg or not pitEgg.Parent then
        pitEgg = UpdateHub.findPitGiantEgg()
    end

    local targetPart = nil
    if pitEgg and pitEgg.Parent then
        targetPart = pitEgg:IsA("BasePart") and pitEgg or (pitEgg:FindFirstChildWhichIsA("BasePart", true) or pitEgg.PrimaryPart)
    end

    if firetouchinterest and targetPart and targetPart:IsA("BasePart") then
        pcall(function()
            firetouchinterest(hrp, targetPart, 0)
            task.wait(0.04)
            firetouchinterest(hrp, targetPart, 1)
        end)
    end

    if pitEgg and pitEgg.Parent and firetouchinterest then
        for _, p in ipairs(pitEgg:GetDescendants()) do
            if p:IsA("BasePart") then
                pcall(function()
                    firetouchinterest(hrp, p, 0)
                    task.wait(0.02)
                    firetouchinterest(hrp, p, 1)
                end)
            end
        end
    end

    if pitEgg and pitEgg.Parent then
        for _, p in ipairs(pitEgg:GetDescendants()) do
            if p:IsA("ProximityPrompt") then
                pcall(function()
                    p.RequiresLineOfSight = false
                    p.HoldDuration = 0
                    fireproximityprompt(p)
                end)
            end
        end
    end

    pcall(function()
        invokeRemote("JurassicEggDeposit")
        invokeRemote("DepositEgg")
        invokeRemote("LiveEventClientSignal", "deposit")
    end)

    UpdateHub.holdingJurassicEgg = false
    UpdateHub.holdingJurassicEggTime = 0
    UpdateHub.midwayEggDetected = false
    printLog("Jurassic Egg", "Menempel dan menyetor telur ke AncientEgg di Pit!")
    notify("Telur Purba", "Telur berhasil disetor ke Pit!")
    return true
end

-- Eksekutor Klaim Hadiah Jurassic Pass
UpdateHub.claimJurassicPassPrizes = function()
    local passData = nil
    local statusOk, sRet = pcall(function()
        return invokeRemote("JurassicPassStatus")
    end)
    if statusOk and sRet ~= nil then
        passData = sRet
    end

    local pData = (type(passData) == "table" and passData.data) or passData
    if type(pData) ~= "table" then
        return false
    end

    local claimable = pData.claimable or 0
    local hasRewards = false
    if type(claimable) == "number" and claimable > 0 then
        hasRewards = true
    elseif type(claimable) == "table" and next(claimable) ~= nil then
        hasRewards = true
    end

    if not hasRewards then
        return false
    end

    printLog("Jurassic Pass", "Mengklaim hadiah Jurassic Pass...")
    local ok, res = pcall(function()
        return invokeRemote("JurassicPassClaimAll")
    end)

    task.wait(0.4)
    if ok and res ~= nil and (type(res) ~= "table" or res.ok ~= false) then
        printLog("Jurassic Pass", "Hadiah Jurassic Pass berhasil diklaim!")
        notify("Jurassic Pass", "Hadiah Jurassic Pass berhasil diklaim!")
        return true
    end
    return false
end

-- Eksekutor Klaim Jurassic Quests
UpdateHub.claimAllJurassicQuests = function()
    local boardData = nil
    local bOk, bRet = pcall(function()
        return invokeRemote("JurassicQuestBoard")
    end)
    if bOk and bRet ~= nil then
        boardData = bRet
    end

    local bData = (type(boardData) == "table" and boardData.data) or boardData
    if type(bData) ~= "table" then
        return false
    end

    local claimedCount = 0
    local categories = {"daily", "hourly"}

    for _, cat in ipairs(categories) do
        local catObj = bData[cat]
        if type(catObj) == "table" and type(catObj.quests) == "table" then
            for qId, qInfo in pairs(catObj.quests) do
                if type(qInfo) == "table" then
                    local isCompleted = false
                    local isAlreadyClaimed = (qInfo.claimed == true or qInfo.isClaimed == true)

                    if qInfo.completed == true or qInfo.isCompleted == true then
                        isCompleted = true
                    elseif type(qInfo.progress) == "number" and type(qInfo.target or qInfo.goal) == "number" then
                        if qInfo.progress >= (qInfo.target or qInfo.goal) then
                            isCompleted = true
                        end
                    end

                    if isCompleted and not isAlreadyClaimed then
                        local realId = qInfo.id or qInfo.questId or qId
                        local ok, res = pcall(function()
                            return invokeRemote("JurassicQuestClaim", realId)
                        end)

                        if ok and res ~= nil and (type(res) ~= "table" or res.ok ~= false) then
                            claimedCount = claimedCount + 1
                            printLog("Jurassic Quests", string.format("Misi %s berhasil diklaim!", tostring(realId)))
                        end
                        task.wait(0.3)
                    end
                end
            end
        end
    end

    if claimedCount > 0 then
        notify("Jurassic Quests", string.format("Berhasil mengklaim %d misi!", claimedCount))
        return true
    end
    return false
end

-- UI TAB EVENT
do
    local JurassicPassSec = EventTab:Section({
        Title = "Jurassic Pass & Quests",
        Opened = false
    })

    JurassicPassSec:Toggle({
        Title = "Auto Klaim Hadiah Jurassic Pass",
        Flag = "auto_claim_jurassic_pass",
        Callback = function(state)
            UpdateHub.autoClaimJurassicPass = parseToggle(state)
            if UpdateHub.autoClaimJurassicPass then
                notify("Jurassic Pass", "Auto Klaim Hadiah Pass DIAKTIFKAN!")
            else
                notify("Jurassic Pass", "Auto Klaim Hadiah Pass dinonaktifkan.")
            end
        end
    })

    JurassicPassSec:Toggle({
        Title = "Auto Klaim Jurassic Quests",
        Flag = "auto_claim_jurassic_quests",
        Callback = function(state)
            UpdateHub.autoClaimJurassicQuests = parseToggle(state)
            if UpdateHub.autoClaimJurassicQuests then
                notify("Jurassic Quests", "Auto Klaim Quests DIAKTIFKAN!")
            else
                notify("Jurassic Quests", "Auto Klaim Quests dinonaktifkan.")
            end
        end
    })

    JurassicPassSec:Button({
        Title = "🎁 Klaim Semua Hadiah Pass Sekarang",
        Callback = function()
            task.spawn(function()
                notify("Jurassic Pass", "Memeriksa hadiah pass...")
                local success = UpdateHub.claimJurassicPassPrizes()
                if not success then
                    notify("Jurassic Pass", "Belum ada hadiah pass yang siap diklaim.")
                end
            end)
        end
    })

    JurassicPassSec:Button({
        Title = "📜 Klaim Semua Quests Sekarang",
        Callback = function()
            task.spawn(function()
                notify("Jurassic Quests", "Memeriksa misi...")
                local success = UpdateHub.claimAllJurassicQuests()
                if not success then
                    notify("Jurassic Quests", "Belum ada misi yang selesai untuk diklaim.")
                end
            end)
        end
    })

    local JurassicEggSec = EventTab:Section({
        Title = "Auto Ancient Egg",
        Opened = false
    })

    local eggStatusPara = JurassicEggSec:Paragraph({
        Title = "Status Event Telur Purba",
        Desc = "Memeriksa status event di Pit..."
    })
    UpdateHub.jurassicEggStatusParagraph = eggStatusPara

    JurassicEggSec:Toggle({
        Title = "Auto Deteksi & Antar Telur ke Pit",
        Flag = "auto_deliver_jurassic_eggs",
        Callback = function(state)
            UpdateHub.autoDeliverJurassicEggs = parseToggle(state)
            if UpdateHub.autoDeliverJurassicEggs then
                notify("Telur Purba", "Auto Deteksi & Antar Telur Purba DIAKTIFKAN!")
            else
                disableNoclip()
                local char = player.Character
                local hum = char and char:FindFirstChild("Humanoid")
                if hum then
                    pcall(function() hum.WalkSpeed = 16 end)
                end
                notify("Telur Purba", "Auto Antar Telur dinonaktifkan. Kecepatan dikembalikan ke 16.")
            end
        end
    })

    UpdateHub.movementModeDropdown = JurassicEggSec:Dropdown({
        Title = "Movement Mode:",
        Flag = "delivery_mode",
        Values = {
            "Safe Walk",
            "Hybrid"
        },
        Value = UpdateHub.deliveryMode or "Safe Walk",
        Multi = false,
        Callback = function(val)
            local strVal = ""
            if type(val) == "string" then
                strVal = val
            elseif type(val) == "table" then
                for k, v in pairs(val) do
                    if v == true then
                        strVal = k
                        break
                    end
                end
            end
            if strVal ~= "" then
                UpdateHub.deliveryMode = strVal
                printLog("Jurassic Egg", "Movement mode diset ke: " .. strVal)
            end
        end
    })

    UpdateHub.walkSpeedDropdown = JurassicEggSec:Dropdown({
        Title = "WalkSpeed:",
        Flag = "event_walk_speed",
        Values = {
            "22 (rekomen)",
            "20",
            "24",
            "26",
            "16"
        },
        Value = "22 (rekomen)",
        Multi = false,
        Callback = function(val)
            local strVal = ""
            if type(val) == "string" then
                strVal = val
            elseif type(val) == "table" then
                for k, v in pairs(val) do
                    if v == true then
                        strVal = k
                        break
                    end
                end
            end
            local speedNum = tonumber(strVal:match("%d+"))
            if speedNum then
                UpdateHub.eventWalkSpeed = speedNum
                local char = player.Character
                local hum = char and char:FindFirstChild("Humanoid")
                if hum then
                    pcall(function() hum.WalkSpeed = speedNum end)
                end
                printLog("Jurassic Egg", string.format("Kecepatan jalan diatur ke: %d studs/detik", speedNum))
            end
        end
    })

    UpdateHub.priorityEggDropdown = JurassicEggSec:Dropdown({
        Title = "Priority Egg:",
        Flag = "prioritize_egg_color",
        Values = {
            "Prioritas Nilai Warna (Coklat > Hijau > Putih) [Direkomendasikan]",
            "Jarak Terdekat Saja (Abaikan Warna)"
        },
        Value = "Prioritas Nilai Warna (Coklat > Hijau > Putih) [Direkomendasikan]",
        Multi = false,
        Callback = function(val)
            local str = tostring(val)
            UpdateHub.prioritizeEggColor = (str:find("Prioritas Nilai Warna") ~= nil)
            printLog("Jurassic Egg", "Prioritas Telur: " .. (UpdateHub.prioritizeEggColor and "Nilai Warna (Tier)" or "Jarak Terdekat"))
        end
    })

    UpdateHub.delayMovementInput = JurassicEggSec:Input({
        Title = "Delay Movement:",
        Flag = "cycle_delay",
        Desc = "Mendukung format koma atau titik (misal: 0.5 atau 0,5).",
        Value = tostring(UpdateHub.cycleDelay or 0.5),
        Callback = function(text)
            local cleanText = tostring(text):gsub(",", ".")
            local num = tonumber(cleanText)
            if num and num >= 0 then
                UpdateHub.cycleDelay = num
                printLog("Jurassic Egg", string.format("Delay movement diatur ke: %.2f detik", num))
                notify("Telur Purba", string.format("Delay movement diset ke: %.2f detik", num))
            end
        end
    })


end


    -- ==============================================================
    -- SECTION 3: AUTO CHICKEN BOSS EVENT (EventTab)
    -- ==============================================================
    local BossSec = EventTab:Section({
        Title = "Auto Chicken Boss Event",
        Opened = false
    })

    BossSec:Paragraph({
        Title = "Chicken Boss Event (World Boss)",
        Desc = "1. Pilih ayam target (Boss Killer) dari kawanan flock.\n2. Saat Auto Chicken Boss aktif, bot mendeteksi event Boss di Pit secara otomatis.\n3. Sebelum mengirim ayam, bot mencatat ayam yang sedang aktif saat ini.\n4. Perintah 'To Chaos' dikirim saat ayam berada di base untuk menyerang Boss bersama pemain lain.\n5. Jika ayam KO dan respawn di base, bot otomatis mengirim ulang ayam ke Pit hingga Boss kalah.\n6. Begitu event Boss selesai, bot otomatis mengembalikan ayam yang aktif ke ayam semula sebelum event."
    })

    UpdateHub.bossStatusParagraph = BossSec:Paragraph({
        Title = "Status Live Chicken Boss",
        Desc = "Menunggu deteksi event Boss..."
    })

    BossSec:Button({
        Title = "Refresh Daftar Ayam Kawanan",
        Callback = function()
            scanFlockChickens()
            if UpdateHub.bossChickenDropdown then
                pcall(function()
                    if type(UpdateHub.bossChickenDropdown.Refresh) == "function" then
                        UpdateHub.bossChickenDropdown:Refresh(chickenNames)
                    elseif type(UpdateHub.bossChickenDropdown.SetValues) == "function" then
                        UpdateHub.bossChickenDropdown:SetValues(chickenNames)
                    end
                    if expandDropdown then
                        expandDropdown(UpdateHub.bossChickenDropdown, 300)
                    end
                end)
            end
            notify("Chicken Boss", "Daftar ayam flock berhasil diperbarui!")
        end
    })

    UpdateHub.bossChickenDropdown = BossSec:Dropdown({
        Title = "Pilih Ayam Target Boss:",
        Flag = "selected_boss_chicken_name",
        Values = chickenNames,
        Value = chickenNames[1],
        MenuWidth = 300,
        Multi = false,
        Callback = function(val)
            local str = ""
            if type(val) == "table" then
                str = val.Title or val.Name or val[1] or ""
                if str == "" then
                    for k, v in pairs(val) do
                        if v == true then
                            str = tostring(k)
                            break
                        end
                    end
                end
            else
                str = tostring(val)
            end
            UpdateHub.selectedBossChickenName = str ~= "" and str or tostring(val)
            saveConfig()
        end
    })
    if expandDropdown then
        expandDropdown(UpdateHub.bossChickenDropdown, 300)
    end

    BossSec:Button({
        Title = "Kirim Ayam ke Boss Sekarang (Test 1x)",
        Callback = function()
            UpdateHub.executeSendChickenToBoss(false)
        end
    })

    BossSec:Toggle({
        Title = "Auto Deteksi & Serang Chicken Boss",
        Flag = "auto_boss_event",
        Callback = function(state)
            UpdateHub.autoBossEvent = parseToggle(state)
            saveConfig()
            if UpdateHub.autoBossEvent then
                UpdateHub.bossChickenStatus = "AT_BASE"
                local curId, curName = UpdateHub.getCurrentActiveChicken()
                local bName = UpdateHub.selectedBossChickenName
                local bData = bName and chickenMap and chickenMap[bName]
                local bId = bData and bData.Id
                if curId and (not bId or tostring(curId) ~= tostring(bId)) then
                    UpdateHub.lastKnownNonBossChickenId = curId
                    UpdateHub.lastKnownNonBossChickenName = curName or tostring(curId)
                    printLog("Auto Boss Event", string.format("Snapshot ayam aktif tersimpan: %s (ID: %s)", tostring(curName), tostring(curId)))
                end
                notify("Auto Boss Event", "Auto Chicken Boss aktif! Menunggu deteksi event Boss...")
            else
                if UpdateHub.handleBossEventEnded then
                    UpdateHub.handleBossEventEnded()
                end
                UpdateHub.bossChickenStatus = "AT_BASE"
                notify("Auto Boss Event", "Auto Chicken Boss dinonaktifkan.")
            end
        end
    })

    BossSec:Toggle({
        Title = "Prioritaskan Boss (Jeda Fitur Lain)",
        Flag = "boss_priority_mode",
        Callback = function(state)
            UpdateHub.bossPriorityMode = parseToggle(state)
            saveConfig()
            if UpdateHub.bossPriorityMode then
                notify("Prioritas Boss", "Fitur lain (Fast Rebirth, Tower, Sweep, Arena) otomatis dijeda saat event Boss.")
            else
                notify("Prioritas Boss", "Mode prioritas dinonaktifkan. Fitur lain akan tetap berjalan bersamaan.")
            end
        end
    })

-- ==============================================================================
end
