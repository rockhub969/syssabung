-- ==============================================================================
--              SYSHUB | GROW A CHICKEN FIGHTER (MODULAR LOADER)
-- ==============================================================================
-- Cara Pakai di Executor:
-- 1. Mode Online (GitHub):
--    - Upload folder 'syssabung_modular' ini ke GitHub repository Anda.
--    - Ganti URL GITHUB_BASE di bawah dengan URL repo raw Anda.
--    - Eksekusi script ini di Roblox executor (Delta, Codex, Wave, Fluxus, dll).
--
-- 2. Mode Offline (Lokal):
--    - Salin folder 'syssabung_modular' ke dalam folder 'workspace' executor Anda.
--    - Eksekusi: loadstring(readfile("syssabung_modular/loader.lua"))()

local GITHUB_BASE = "https://raw.githubusercontent.com/farhan/syssabung/main/syssabung_modular/"
local LOCAL_FOLDER = "syssabung_modular/"

local function fetchSource(relPath)
    -- 1. Cek mode lokal di folder workspace executor (offline dev)
    if isfile and isfile(LOCAL_FOLDER .. relPath) then
        return readfile(LOCAL_FOLDER .. relPath)
    end

    -- 2. Mode online via GitHub
    local url = GITHUB_BASE .. relPath
    local success, content = pcall(function()
        return game:HttpGet(url)
    end)

    if success and content and #content > 10 then
        return content
    else
        warn("[SysHub Loader ERROR]: Gagal memuat " .. relPath .. " dari " .. tostring(url))
        return nil
    end
end

getgenv().SysHubFetch = fetchSource

local initCode = fetchSource("init.lua")
if initCode then
    loadstring(initCode)()
else
    warn("[SysHub Loader FATAL]: init.lua tidak ditemukan!")
end
