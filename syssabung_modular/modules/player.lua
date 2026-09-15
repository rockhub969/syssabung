-- ==============================================================================
--              SYSHUB | MODUL PLAYER & VISUAL ESP
-- ==============================================================================
return function(Context, PlayerTab)
    local player = Context.player
    local saveConfig = Context.saveConfig
    local parseToggle = Context.parseToggle
    local cleanESP = Context.cleanESP
    local espPlayerEnabled = Context.espPlayerEnabled
    local espEggEnabled = Context.espEggEnabled
    local espScrapEnabled = Context.espScrapEnabled
    local streamerMode = Context.streamerMode
    local fakeName = Context.fakeName

-- [TAB 5: PLAYER]
-- ==============================================================================
do
    local EspSec = PlayerTab:Section({
        Title = "Visual ESP",
        Opened = false
    })

    EspSec:Toggle({
        Title = "Player ESP",
        Flag = "esp_player_enabled",
        Callback = function(state)
            espPlayerEnabled = parseToggle(state)
            saveConfig()
            if not espPlayerEnabled then
                cleanESP("SysHub_PlayerESP_HL")
                cleanESP("SysHub_PlayerESP_BB")
            end
        end
    })

    EspSec:Toggle({
        Title = "Egg ESP",
        Flag = "esp_egg_enabled",
        Callback = function(state)
            espEggEnabled = parseToggle(state)
            saveConfig()
            if not espEggEnabled then
                cleanESP("SysHub_EggESP_HL")
                cleanESP("SysHub_EggESP_BB")
            end
        end
    })

    EspSec:Toggle({
        Title = "Scrap & Coin ESP",
        Flag = "esp_scrap_enabled",
        Callback = function(state)
            espScrapEnabled = parseToggle(state)
            saveConfig()
            if not espScrapEnabled then
                cleanESP("SysHub_ScrapESP_HL")
                cleanESP("SysHub_ScrapESP_BB")
            end
        end
    })

    local StreamerSec = PlayerTab:Section({
        Title = "Streamer Mode",
        Opened = false
    })

    StreamerSec:Toggle({ 
        Title = "Streamer Mode (Hide Name)", 
        Flag = "streamer_mode_enabled",
        Callback = function(state) 
            streamerMode = parseToggle(state)
            saveConfig()
            if not streamerMode and player.Character then
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    pcall(function()
                        hum.DisplayName = player.DisplayName
                    end)
                end
            end
        end 
    })

    StreamerSec:Input({
        Title = "Custom Fake Name",
        Flag = "fake_name",
        Value = fakeName,
        Callback = function(text)
            if text and text ~= "" then
                fakeName = text
                saveConfig()
            end
        end
    })
end



-- ==============================================================================
end
