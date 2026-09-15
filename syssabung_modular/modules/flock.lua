-- ==============================================================================
--              SYSHUB | MODUL FLOCK (HATCH, SELL, PROMOTE, FUSE, CHARMS)
-- ==============================================================================
return function(Context, FlockTab)
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
    local executeSellChickens = Context.executeSellChickens
    local getSharedDataServiceClient = Context.getSharedDataServiceClient
    local formatSpeciesName = Context.formatSpeciesName
    local detectChickenRarity = Context.detectChickenRarity
    local FlockTab = FlockTab or Context.FlockTab or (getgenv and getgenv().FlockTab)
    local promoteTargetList = Context.promoteTargetList or (getgenv and getgenv().promoteTargetList) or {"Belum di-refresh (Klik tombol Refresh)"}
    local promoteFodderList = Context.promoteFodderList or (getgenv and getgenv().promoteFodderList) or {"Pilih ayam target terlebih dahulu"}
    local promoteTargetMap = Context.promoteTargetMap or (getgenv and getgenv().promoteTargetMap) or {}
    local promoteFodderMap = Context.promoteFodderMap or (getgenv and getgenv().promoteFodderMap) or {}
    local selectedPromoteFoddersMap = Context.selectedPromoteFoddersMap or (getgenv and getgenv().selectedPromoteFoddersMap) or {}
    local availableFuseSkills = Context.availableFuseSkills or (getgenv and getgenv().availableFuseSkills) or {"Stormcall", "Final Grace", "Lightning Strike", "Inferno Breath", "Void Pulse", "Golden Touch"}
    local chickenNames = Context.chickenNames or (getgenv and getgenv().chickenNames) or {"Buka menu Flock di game lalu klik Refresh!"}
    local favoritedChickenIds = Context.favoritedChickenIds or (getgenv and getgenv().favoritedChickenIds) or {}
    local promotedChickenIds = Context.promotedChickenIds or (getgenv and getgenv().promotedChickenIds) or {}
    local selectedSellRarities = Context.selectedSellRarities or (getgenv and getgenv().selectedSellRarities) or {}
    local autoPromote = Context.autoPromote or (getgenv and getgenv().autoPromote) or false
    local autoFuse = Context.autoFuse or (getgenv and getgenv().autoFuse) or false
    local autoSellChickens = Context.autoSellChickens or (getgenv and getgenv().autoSellChickens) or false

-- [TAB 4: CHICKEN]
-- ==============================================================================
do
    local PromoteSec = FlockTab:Section({
        Title = "Auto Promote",
        Opened = false
    })

promoteStatusPara = PromoteSec:Paragraph({
    Title = "Status Persyaratan Promote",
    Desc = "Pilih ayam target di Target Promote dan centang bahan di Bahan Korban."
})

promoteTargetDropdown = PromoteSec:Dropdown({
    Title = "Target Promote:",
    Values = promoteTargetList,
    Value = promoteTargetList[1],
    MenuWidth = 300,
    Multi = false,
    Callback = function(val)
        selectedPromoteTarget = val
        if updatePromoteFodders then
            updatePromoteFodders(val)
        end
    end
})
if expandDropdown then
    expandDropdown(promoteTargetDropdown, 300)
end

promoteFodderDropdown = PromoteSec:Dropdown({
    Title = "Bahan Korban:",
    Values = promoteFodderList,
    Value = {},
    MenuWidth = 300,
    Multi = true,
    Callback = function(list)
        selectedPromoteFoddersMap = {}
        if type(list) == "table" then
            for k, v in pairs(list) do
                if type(k) == "string" and v == true then
                    selectedPromoteFoddersMap[k] = true
                elseif type(v) == "string" then
                    selectedPromoteFoddersMap[v] = true
                end
            end
        elseif type(list) == "string" then
            selectedPromoteFoddersMap[list] = true
        end
        if updatePromoteStatusDisplay then
            updatePromoteStatusDisplay()
        end
    end
})
if expandDropdown then
    expandDropdown(promoteFodderDropdown, 300)
end

autoPromoteToggle = PromoteSec:Toggle({
    Title = "Auto Promote",
    Flag = "auto_promote",
    Callback = function(state)
        autoPromote = parseToggle(state)
    end
})

PromoteSec:Button({
    Title = "Refresh Daftar Ayam Kawanan",
    Callback = function()
        scanFlockChickens()
        notify("Promote", "Daftar kawanan berhasil diperbarui!")
    end
})

local FuseSec = FlockTab:Section({
    Title = "Auto Fuse",
    Opened = false
})

fuseMainDropdown = FuseSec:Dropdown({
    Title = "Ayam Utama:",
    Values = chickenNames,
    Value = chickenNames[1],
    MenuWidth = 300,
    Multi = false,
    Callback = function(val)
        fuseMainChickenName = val
        if updateAvailableSkills then
            updateAvailableSkills()
        end
    end
})
if expandDropdown then
    expandDropdown(fuseMainDropdown, 300)
end

fuseFodderDropdown = FuseSec:Dropdown({
    Title = "Ayam Bahan:",
    Values = chickenNames,
    Value = chickenNames[2] or chickenNames[1],
    MenuWidth = 300,
    Multi = false,
    Callback = function(val)
        fuseFodderChickenName = val
        if updateAvailableSkills then
            updateAvailableSkills()
        end
    end
})
if expandDropdown then
    expandDropdown(fuseFodderDropdown, 300)
end

fuseSkillDropdown = FuseSec:Dropdown({
    Title = "Lock Skill:",
    Values = availableFuseSkills,
    Value = availableFuseSkills[1],
    Multi = false,
    Callback = function(val)
        fuseLockedSkill = val
    end
})

FuseSec:Toggle({
    Title = "Auto Fuse",
    Flag = "auto_fuse",
    Callback = function(state)
        autoFuse = parseToggle(state)
    end
})

local AutoFavSec = FlockTab:Section({
    Title = "Auto Favorite Chicken",
    Opened = false
})

AutoFavSec:Button({
    Title = "Refresh Daftar Ayam",
    Callback = function()
        scanFlockChickens()
        notify("Favorite", "Daftar ayam flock berhasil diperbarui!")
    end
})

favDropdown = AutoFavSec:Dropdown({
    Title = "Ayam Favorit:",
    Values = chickenNames,
    Value = chickenNames[1],
    MenuWidth = 300,
    Multi = false,
    Callback = function(val)
        selectedFavChickenName = val
    end
})
if expandDropdown then
    expandDropdown(favDropdown, 300)
end

AutoFavSec:Button({
    Title = "⭐ Kunci Sebagai Ayam Favorit (Lock)",
    Callback = function()
        if selectedFavChickenName and chickenMap[selectedFavChickenName] then
            local targetData = chickenMap[selectedFavChickenName]
            favoritedChickenIds[targetData.Id] = true
            local numId = tonumber(string.match(targetData.Id, "%d+"))
            if numId then
                favoritedChickenIds[numId] = true
            end
            invokeRemote("SetChickenFavorite", targetData.Id, true)
            scanFlockChickens()
            notify("Auto Favorite", "Ayam '" .. tostring(targetData.Name) .. "' BERHASIL DIKUNCI!")
        end
    end
})

AutoFavSec:Button({
    Title = "🔓 Hapus Kunci Favorit (Unlock)",
    Callback = function()
        if selectedFavChickenName and chickenMap[selectedFavChickenName] then
            local targetData = chickenMap[selectedFavChickenName]
            favoritedChickenIds[targetData.Id] = nil
            local numId = tonumber(string.match(targetData.Id, "%d+"))
            if numId then
                favoritedChickenIds[numId] = nil
            end
            invokeRemote("SetChickenFavorite", targetData.Id, false)
            scanFlockChickens()
            notify("Auto Favorite", "Kunci favorit ayam '" .. tostring(targetData.Name) .. "' dilepas.")
        end
    end
})

-- ==============================================================================
-- [CHARMS CATALOG & STATS CONFIGURATION (OFFICIAL DATA)]
-- ==============================================================================
local CHARM_TIER_BY_NAME = {
    ["Semua Tier"] = 1,
    ["Uncommon+"] = 2,
    ["Rare+"] = 3,
    ["Super Rare+"] = 4,
    ["Legendary+"] = 5,
    ["Ascended"] = 6,
}

local CHARM_STAT_DISPLAY_MAP = {
    ["atk"] = "ATK BOOST",
    ["def"] = "DEF BOOST",
    ["hp"] = "HP BOOST",
    ["crit"] = "CRIT% BOOST",
    ["critRes"] = "CRIT RES BOOST",
    ["critDmg"] = "CRIT DMG BOOST",
    ["ability"] = "ABILITY BOOST",
    ["dmgReduction"] = "DMG REDUCTION",
    ["moveSpeed"] = "MOVEMENT SPEED",
}

local CHARM_STAT_ALIAS_MAP = {
    ["atk"] = "atk",
    ["atkboost"] = "atk",
    ["attack"] = "atk",
    ["attackboost"] = "atk",

    ["def"] = "def",
    ["defboost"] = "def",
    ["defense"] = "def",
    ["defenseboost"] = "def",

    ["hp"] = "hp",
    ["hpboost"] = "hp",
    ["health"] = "hp",
    ["healthboost"] = "hp",

    ["crit"] = "crit",
    ["critboost"] = "crit",
    ["crit%"] = "crit",
    ["crit%boost"] = "crit",
    ["critchance"] = "crit",
    ["critrate"] = "crit",

    ["critres"] = "critRes",
    ["critresboost"] = "critRes",
    ["critresistance"] = "critRes",

    ["critdmg"] = "critDmg",
    ["critdmgboost"] = "critDmg",
    ["criticaldamage"] = "critDmg",

    ["ability"] = "ability",
    ["abilityboost"] = "ability",

    ["dmgreduction"] = "dmgReduction",
    ["damagereduction"] = "dmgReduction",
    ["dmgred"] = "dmgReduction",

    ["movespeed"] = "moveSpeed",
    ["movementspeed"] = "moveSpeed",
    ["speed"] = "moveSpeed",
}

local function normalizeCharmStat(statRaw)
    if not statRaw then return nil end
    local clean = tostring(statRaw):lower():gsub("[^%a%d]", "")
    return CHARM_STAT_ALIAS_MAP[clean] or clean
end

local function getCharmTierRank(tierRaw)
    if not tierRaw then return 1 end
    local s = tostring(tierRaw):lower():gsub("[^%a%d]", "")
    if s == "ascended" or s == "a" or s:find("ascend") then return 6 end
    if s == "legendary" or s == "l" or s:find("legend") then return 5 end
    if s == "superrare" or s == "sr" or s:find("super") then return 4 end
    if s == "rare" or s == "r" then return 3 end
    if s == "uncommon" or s == "u" then return 2 end
    if s == "common" or s == "c" then return 1 end
    return 1
end

local function getCharmMinTierRank(minTierStr)
    if not minTierStr then return 4 end
    if CHARM_TIER_BY_NAME[minTierStr] then
        return CHARM_TIER_BY_NAME[minTierStr]
    end
    local s = tostring(minTierStr):lower():gsub("[^%a%d]", "")
    if s:find("ascend") then return 6 end
    if s:find("legend") then return 5 end
    if s:find("super") or s:find("epic") then return 4 end
    if s:find("rare") then return 3 end
    if s:find("uncommon") then return 2 end
    return 1
end

local CHARM_SLOT_STAR_REQS = { 0, 2, 4, 6, 8, 8, 10, 10 }

UpdateHub.executeAutoRollCharms = function()
    if UpdateHub.isCharmRolling or not UpdateHub.selectedCharmChickenName or not chickenMap[UpdateHub.selectedCharmChickenName] then
        return
    end
    UpdateHub.isCharmRolling = true
    pcall(function()
        local targetData = chickenMap[UpdateHub.selectedCharmChickenName]
        local cId = targetData.Id
        if not cId then
            return
        end

        local dsClient = getSharedDataServiceClient()
        local raw = dsClient and dsClient._data and dsClient._data._data
        local chickenObj = nil
        if raw and raw.roster and raw.roster.chickens and type(raw.roster.chickens) == "table" then
            for k, ch in pairs(raw.roster.chickens) do
                if tostring(ch.id) == tostring(cId) or tostring(k) == tostring(cId) then
                    chickenObj = ch
                    break
                end
            end
        end

        if not chickenObj then
            return
        end

        local promo = tonumber(chickenObj.promo) or 0
        local totalAvailableSlots = 0
        local lockedOrSatisfiedCount = 0
        local needsRoll = false
        local minTierRank = getCharmMinTierRank(UpdateHub.charmMinTier)

        for slotIdx = 1, 8 do
            local starReq = CHARM_SLOT_STAR_REQS[slotIdx] or 0
            if starReq <= promo then
                totalAvailableSlots = totalAvailableSlots + 1
                local charm = chickenObj.charms and chickenObj.charms[slotIdx]
                if charm and type(charm) == "table" then
                    local statId = normalizeCharmStat(charm.stat or charm.type or charm.id or charm.name)
                    local tierRank = getCharmTierRank(charm.tier or charm.rarity or charm.tierId or charm.letter)
                    local isLocked = (charm.locked == true)

                    local dispStat = CHARM_STAT_DISPLAY_MAP[statId] or tostring(statId):upper()
                    local matchesStat = (statId and (UpdateHub.charmPreferredStats[statId] == true or UpdateHub.charmPreferredStats[dispStat] == true))
                    local matchesTier = (tierRank >= minTierRank)

                    if matchesStat and matchesTier then
                        if not isLocked then
                            invokeRemote("SetCharmLock", cId, slotIdx, true)
                            local dispTier = (tierRank == 6 and "Ascended") or (tierRank == 5 and "Legendary") or (tierRank == 4 and "Super Rare") or (tierRank == 3 and "Rare") or (tierRank == 2 and "Uncommon") or "Common"
                            printLog("Charms", string.format("Slot %d (%s [%s]) memenuhi kriteria -> di-LOCK!", slotIdx, dispStat, dispTier))
                        end
                        lockedOrSatisfiedCount = lockedOrSatisfiedCount + 1
                    else
                        if isLocked then
                            lockedOrSatisfiedCount = lockedOrSatisfiedCount + 1
                        else
                            needsRoll = true
                        end
                    end
                else
                    needsRoll = true
                end
            end
        end

        if needsRoll and totalAvailableSlots > 0 then
            local rollRes = invokeRemote("RollCharms", cId)
            if rollRes then
                printLog("Charms", string.format("Roll Charms dieksekusi untuk %s (Slot terkunci: %d/%d)", tostring(targetData.Species or targetData.Name), lockedOrSatisfiedCount, totalAvailableSlots))
            end
        else
            if totalAvailableSlots > 0 and lockedOrSatisfiedCount >= totalAvailableSlots then
                printLog("Charms", string.format("Semua slot charm target (%d slot) telah memenuhi kriteria / terkunci!", totalAvailableSlots))
            end
        end
    end)
    UpdateHub.isCharmRolling = false
end

local CharmsSec = FlockTab:Section({
    Title = "Auto Roll Charms & Lock",
    Opened = false
})

CharmsSec:Paragraph({
    Title = "Panduan Auto Roll Charms",
    Desc = "Pilih ayam target, Min Tier, dan Stat yang diinginkan. Sistem otomatis me-lock stat/tier yang sesuai dan me-roll slot yang belum memenuhi syarat."
})

CharmsSec:Button({
    Title = "Refresh Daftar Ayam",
    Callback = function()
        scanFlockChickens()
        notify("Charms", "Daftar ayam flock berhasil diperbarui!")
    end
})

UpdateHub.charmDropdown = CharmsSec:Dropdown({
    Title = "Target Ayam Charms:",
    Flag = "selected_charm_chicken_name",
    Values = chickenNames,
    Value = chickenNames[1],
    MenuWidth = 300,
    Multi = false,
    Callback = function(val)
        UpdateHub.selectedCharmChickenName = val
    end
})
if expandDropdown then
    expandDropdown(UpdateHub.charmDropdown, 300)
end

local charmTierDropdown = CharmsSec:Dropdown({
    Title = "Min Tier Kunci:",
    Flag = "charm_min_tier",
    Values = {"Super Rare+", "Legendary+", "Ascended", "Rare+", "Uncommon+", "Semua Tier"},
    Value = "Super Rare+",
    MenuWidth = 300,
    Multi = false,
    Callback = function(val)
        UpdateHub.charmMinTier = val
    end
})
if expandDropdown then
    expandDropdown(charmTierDropdown, 300)
end

local charmStatDropdown = CharmsSec:Dropdown({
    Title = "Stat Diinginkan (Kunci):",
    Values = {
        "ATK BOOST",
        "HP BOOST",
        "DEF BOOST",
        "CRIT% BOOST",
        "CRIT DMG BOOST",
        "CRIT RES BOOST",
        "ABILITY BOOST",
        "DMG REDUCTION",
        "MOVEMENT SPEED"
    },
    Value = {"ATK BOOST", "HP BOOST", "CRIT% BOOST", "CRIT DMG BOOST"},
    MenuWidth = 300,
    Multi = true,
    Callback = function(list)
        local newPrefs = {}
        if type(list) == "table" then
            for k, v in pairs(list) do
                local item = nil
                if type(k) == "string" and v == true then
                    item = k
                elseif type(v) == "string" then
                    item = v
                end
                if item then
                    local id = normalizeCharmStat(item)
                    if id then
                        newPrefs[id] = true
                    end
                end
            end
        elseif type(list) == "string" then
            local id = normalizeCharmStat(list)
            if id then
                newPrefs[id] = true
            end
        end
        UpdateHub.charmPreferredStats = newPrefs
    end
})
if expandDropdown then
    expandDropdown(charmStatDropdown, 300)
end

CharmsSec:Toggle({
    Title = "Auto Roll Charms",
    Flag = "auto_roll_charms",
    Callback = function(state)
        UpdateHub.autoRollCharms = parseToggle(state)
    end
})

CharmsSec:Button({
    Title = "Roll Charms Sekarang (1x)",
    Callback = function()
        task.spawn(UpdateHub.executeAutoRollCharms)
        notify("Charms", "Mengeksekusi roll charms...")
    end
})
end

-- ==============================================================================
end
