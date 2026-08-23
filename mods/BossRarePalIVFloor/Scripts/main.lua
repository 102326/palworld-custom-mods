--==============================================================================
--  BossRarePalIVFloor  — Raises the minimum IV floor for boss/lucky pals
--
--  Changes BossOrRarePal_TalentMin from the vanilla 50 to IV_FLOOR (custom 100).
--  Newly spawned boss/alpha/lucky/shiny pals roll IVs in [IV_FLOOR, 100].
--
--  Three redundant apply paths so it can't miss:
--    1. NotifyOnNewObject — catches fresh PalGameSetting creation
--    2. FindFirstOf on load — patches existing instance
--    3. ClientRestart hook — re-applies on zone transitions / save loads
--
--  Tweak the floor by changing IV_FLOOR below.
--     50  = vanilla default
--     80  = "at least 80+"
--    100  = guaranteed perfect IVs
--   >100  = not recommended, game clamps IVs to 0-100
--==============================================================================

local IV_FLOOR = 100
local MOD_TAG  = "[BossRarePalIVFloor]"

local function applyFloor(setting)
    if not setting or not setting:IsValid() then return false end
    setting.BossOrRarePal_TalentMin = IV_FLOOR
    print(MOD_TAG .. " applied BossOrRarePal_TalentMin = " .. tostring(IV_FLOOR))
    return true
end

NotifyOnNewObject("/Script/Pal.PalGameSetting", function(setting)
    applyFloor(setting)
end)

ExecuteInGameThread(function()
    local existing = FindFirstOf("PalGameSetting")
    if existing then
        applyFloor(existing)
    else
        print(MOD_TAG .. " no PalGameSetting yet on load; will catch it via ClientRestart.")
    end
end)

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function()
    local setting = FindFirstOf("PalGameSetting")
    if setting then applyFloor(setting) end
end)

print(MOD_TAG .. " loaded. IV_FLOOR=" .. tostring(IV_FLOOR))
