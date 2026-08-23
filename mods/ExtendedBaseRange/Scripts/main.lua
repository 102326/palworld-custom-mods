-- Extended Base Range 1.0.5-local compatibility revision for Palworld 1.0.
-- Fixed-radius adaptation based on Progressive Base Radius by ceruleen/PalMods.
-- Keeps the original mod's 2x setting while applying it authoritatively on
-- the server and matching the boundary ring on every client.

local Config = require("config")
local MOD_NAME = "ExtendedBaseRangeCompat"

local function log(message, force)
    if force or Config.verbose_logging then
        print(string.format("[%s] %s\n", MOD_NAME, tostring(message)))
    end
end

local function protected(callback, ...)
    local ok, value = pcall(callback, ...)
    if ok then return value end
    return nil
end

local function finite_number(value, fallback)
    local number = tonumber(value)
    if number == nil or number ~= number or number == math.huge or number == -math.huge then
        return fallback
    end
    return number
end

local radius_cm = finite_number(Config.radius_cm, 7000.0)
radius_cm = math.max(1000.0, math.min(radius_cm, 100000.0))
local scale_factor = radius_cm / 3500.0
local ring_scale = radius_cm / 50.0
local reapply_interval_ms = math.floor(math.max(1000, math.min(
    finite_number(Config.reapply_interval_ms, 5000), 300000)))
local initialization_delay_ms = math.floor(math.max(1000, math.min(
    finite_number(Config.initialization_delay_ms, 10000), 60000)))

local function valid(object)
    return object ~= nil and protected(function() return object:IsValid() end) == true
end

local function read_field(object, field)
    if object == nil then return nil end
    return protected(function() return object[field] end)
end

local function write_field(object, field, value)
    if object == nil then return false end
    return pcall(function() object[field] = value end)
end

local function tune_enemy_observer(observer)
    if observer == nil then return false end
    return write_field(observer, "CampAreaRange", radius_cm)
end

local function tune_model(model)
    if not valid(model) then return false end
    local changed = write_field(model, "AreaRange", radius_cm)
    local observer = read_field(model, "EnemyObserver")
    if observer ~= nil then tune_enemy_observer(observer) end
    return changed
end

local function scale_ring_component(component)
    if not valid(component) then return false end
    local current_scale = read_field(component, "RelativeScale3D")
    local z = tonumber(read_field(current_scale, "Z")) or 100.0
    local target = { X = ring_scale, Y = ring_scale, Z = z }
    if pcall(function() component:SetRelativeScale3D(target) end) then return true end
    return write_field(component, "RelativeScale3D", target)
end

local function tune_palbox(palbox)
    if not valid(palbox) then return false end
    local primary = scale_ring_component(read_field(palbox, "AreaRange"))
    local alternate = scale_ring_component(read_field(palbox, "AreaRange1"))
    return primary or alternate
end

local function tune_template_rings()
    for _, path in ipairs({
        "/Game/Pal/Blueprint/MapObject/BuildObject/BP_BuildObject_PalBoxV2.BP_BuildObject_PalBoxV2_C:AreaRange_GEN_VARIABLE",
        "/Game/Pal/Blueprint/MapObject/BuildObject/BP_BuildObject_PalBoxV2.BP_BuildObject_PalBoxV2_C:AreaRange1_GEN_VARIABLE"
    }) do
        local component = protected(StaticFindObject, path)
        if component ~= nil then scale_ring_component(component) end
    end
end

local function tune_global_settings()
    local values = {
        SpawnerDisableDistanceCM_FromBaseCamp = 4000.0 * scale_factor,
        BaseCampExtraWorkAreaRange = 7000.0 * scale_factor,
        BaseCampAreaRange = radius_cm,
        BaseCampPalFindWorkRange = 400.0 * scale_factor,
        BaseCampNeighborMinimumDistance = 1500.0 * scale_factor,
        BaseCampPalCombatRange_AddCampRange = 2000.0 * scale_factor,
        BaseCampNeighborMinimumDistance_PVP = 1500.0 * scale_factor,
        BaseCampFoliageWorkableRange = 200.0 * scale_factor,
        BaseCampPalCombatRange_AddCampRange_PVP = 2000.0 * scale_factor,
    }

    for _, settings in ipairs(protected(FindAllOf, "PalGameSetting") or {}) do
        if valid(settings) then
            for field, value in pairs(values) do write_field(settings, field, value) end
        end
    end
end

local function apply_all()
    tune_template_rings()
    tune_global_settings()

    local model_count = 0
    for _, model in ipairs(protected(FindAllOf, "PalBaseCampModel") or {}) do
        if tune_model(model) then model_count = model_count + 1 end
    end

    local palbox_count = 0
    for _, palbox in ipairs(protected(FindAllOf, "BP_BuildObject_PalBoxV2_C") or {}) do
        if tune_palbox(palbox) then palbox_count = palbox_count + 1 end
    end

    log(string.format("refresh: %d base model(s), %d Palbox ring(s)",
        model_count, palbox_count), false)
end

local function on_game_thread(callback)
    if ExecuteInGameThread ~= nil then ExecuteInGameThread(callback) else callback() end
end

local function later(milliseconds, callback)
    if ExecuteWithDelay ~= nil then
        ExecuteWithDelay(milliseconds, function() on_game_thread(callback) end)
    else
        on_game_thread(callback)
    end
end

pcall(function()
    NotifyOnNewObject("/Script/Pal.PalBaseCampModel", function()
        -- Do not capture and dereference the spawned object after the delay.
        -- Re-scan live objects instead, preventing the 1.0.4 stale-object crash.
        later(initialization_delay_ms, apply_all)
    end)
end)

pcall(function()
    NotifyOnNewObject("/Script/Pal.PalBuildObjectBaseCampPoint", function()
        later(initialization_delay_ms, apply_all)
    end)
end)

pcall(function()
    RegisterHook("/Script/Engine.PlayerController:ClientRestart", function()
        later(500, apply_all)
        later(3000, apply_all)
    end)
end)

pcall(function()
    RegisterHook("/Script/Engine.GameModeBase:StartPlay", function()
        later(500, apply_all)
        later(3000, apply_all)
    end)
end)

local function schedule_refresh()
    if ExecuteWithDelay == nil then return end
    ExecuteWithDelay(reapply_interval_ms, function()
        on_game_thread(apply_all)
        schedule_refresh()
    end)
end

for _, delay in ipairs({ 500, 2000, 6000, initialization_delay_ms }) do
    later(delay, apply_all)
end
schedule_refresh()

log(string.format("loaded: fixed %.1f m radius (%.2fx vanilla)",
    radius_cm / 100.0, scale_factor), true)
