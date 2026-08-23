--==============================================================================
--  BossPassiveFilter  v4.4.5
--
--  Removes bad/useless passives from boss/lucky pals.
--  Custom setting: fills every empty slot up to 4 from a weighted good pool.
--
--  v4.4.5: Added SKIP_LUCKY_PALS toggle — when true, skips pals with the
--           "Rare" passive to avoid conflicts with AmazingLuckyPals.
--
--  INSTALL: Copy this file into ue4ss/Mods/BossPassiveFilter/Scripts/
--  Requires: BossRarePalIVFloor (for IV-based boss detection)
--==============================================================================

local TAG = "[BossPassiveFilter] "

--==============================================================================
-- CONFIG
--==============================================================================

-- Set to true to skip lucky pals (pals with the "Rare" passive).
-- Use this when running alongside AmazingLuckyPals or any other mod that
-- specifically handles lucky pals, to avoid overwriting each other's changes.
local SKIP_LUCKY_PALS = false

-- Aggressive random mode: every qualifying new wild boss/lucky pal receives
-- four unique passives randomly drawn from this premium pool.
local FORCE_RANDOM_GOD_ROLL = true
local GOD_POOL = {
    { name = "CraftSpeed_up3",     label = "Remarkable Craftsmanship" },
    { name = "Deffence_up3",      label = "Diamond Body" },
    { name = "PAL_ALLAttack_up3", label = "Demon God" },
    { name = "PAL_FullStomach_Down_3", label = "Mastery of Fasting" },
    { name = "PAL_Sanity_Down_3", label = "Heart of the Immovable King" },
    { name = "MoveSpeed_up_3",    label = "Swift" },
    { name = "Stamina_Up_3",      label = "Eternal Engine" },
    { name = "Vampire",           label = "Vampiric" },
    { name = "SwimSpeed_up_3",    label = "King of the Waves" },
    { name = "SelfDeathAddItemDrop_up_3", label = "Lavish Hospitality" },
    { name = "WorkSuitabilityAddRank_MonsterFarm_2", label = "Ranch Master" },
    { name = "RideJumpCount_Increase1", label = "Lightfooted" },
}

-- Fixed/special passives remain exclusive to the Pal that originally has them.
-- They are never added from GOD_POOL, and are preserved before random slots fill.
local PRESERVE_EXCLUSIVE = {
    Rare = true,
    Legend = true,
    Witch = true,
    EternalFlame = true,
    Invader = true,
    Alien = true,
    Nushi = true,
    Salvation = true,
    OctaviaArmorVampire = true,
}

local function isExclusivePassive(name)
    if PRESERVE_EXCLUSIVE[name] then return true end
    if name:match("^MutationPal_") then return true end
    if name:match("^WorldTree_") then return true end
    if name:match("^GYM_NAME_") then return true end
    return false
end

--==============================================================================
-- BAD PASSIVES
--==============================================================================
local BAD = {}
BAD["CraftSpeed_down2"]    = "Slacker"
BAD["Deffence_down2"]      = "Brittle"
BAD["PAL_ALLAttack_down2"] = "Pacifist"
BAD["PAL_FullStomach_Up_2"] = "Bottomless Stomach"
BAD["PAL_Sanity_Up_2"]      = "Destructive"
BAD["CraftSpeed_down1"]     = "Clumsy"
BAD["PAL_ALLAttack_down1"]  = "Coward"
BAD["Deffence_down1"]       = "Downtrodden"
BAD["CoolTimeReduction_Down_1"] = "Easygoing"
BAD["PAL_FullStomach_Up_1"] = "Glutton"
BAD["NightOwl"]             = "Night Owl"
BAD["SalePrice_Down_1"]     = "Shabby"
BAD["Stamina_Down_1"]       = "Sickly"
BAD["PAL_Sanity_Up_1"]      = "Unstable"
BAD["ElementResist_Normal_1_PAL"]    = "Abnormal"
BAD["ElementResist_Fire_1_PAL"]      = "Suntan Lover"
BAD["ElementResist_Aqua_1_PAL"]      = "Waterproof"
BAD["ElementResist_Thunder_1_PAL"]   = "Insulated Body"
BAD["ElementResist_Leaf_1_PAL"]      = "Botanical Barrier"
BAD["ElementResist_Ice_1_PAL"]       = "Heated Body"
BAD["ElementResist_Earth_1_PAL"]     = "Earthquake Resistant"
BAD["ElementResist_Dark_1_PAL"]      = "Cheery"
BAD["ElementResist_Dragon_1_PAL"]    = "Dragonkiller"
BAD["ElementBoost_Normal_1_PAL"]    = "Spirit of Zen"
BAD["ElementBoost_Fire_1_PAL"]      = "Pyromaniac"
BAD["ElementBoost_Aqua_1_PAL"]      = "Hydromaniac"
BAD["ElementBoost_Thunder_1_PAL"]   = "Capacitor"
BAD["ElementBoost_Leaf_1_PAL"]      = "Fragrant Foliage"
BAD["ElementBoost_Ice_1_PAL"]       = "Coldblooded"
BAD["ElementBoost_Earth_1_PAL"]     = "Power of Gaia"
BAD["ElementBoost_Dark_1_PAL"]      = "Veil of Darkness"
BAD["ElementBoost_Dragon_1_PAL"]    = "Blood of the Dragon"
BAD["PAL_rude"]              = "Hooligan"
BAD["PAL_sadist"]            = "Sadist"
BAD["PAL_masochist"]         = "Masochist"
BAD["PAL_CorporateSlave"]    = "Work Slave"
BAD["PAL_conceited"]         = "Conceited"
BAD["PAL_ALLAttack_up1"]     = "Brave"
BAD["Deffence_up1"]          = "Hard Skin"
BAD["MoveSpeed_up_1"]        = "Nimble"
BAD["Stamina_Up_2"]          = "Fit as a Fiddle"
BAD["PAL_Sanity_Down_1"]     = "Positive Thinker"
BAD["PAL_FullStomach_Down_1"] = "Dainty Eater"
BAD["SalePrice_Up_2"]        = "Fine Furs"
BAD["PAL_oraora"]            = "Aggressive"

--==============================================================================
-- GOOD POOL
--==============================================================================
local GOOD_POOL = {
    { name = "PAL_ALLAttack_up2",     label = "Ferocious",       weight = 6 },
    { name = "Deffence_up2",          label = "Burly Body",      weight = 6 },
    { name = "MoveSpeed_up_2",        label = "Runner",          weight = 5 },
    { name = "Noukin",                label = "Musclehead",      weight = 5 },
    { name = "CoolTimeReduction_Up_2", label = "Impatient",      weight = 4 },
    { name = "Deffence_up2_2",        label = "Heavyweight",     weight = 4 },
    { name = "RideJumpCount_Increase1", label = "Lightfooted",   weight = 2 },
    { name = "Deffence_up3",          label = "Diamond Body",    weight = 2 },
    { name = "MoveSpeed_up_3",        label = "Swift",           weight = 2 },
    { name = "CoolTimeReduction_Up_1", label = "Serenity",       weight = 2 },
    { name = "Stamina_Up_1",          label = "Infinite Stamina", weight = 1 },
    { name = "Stamina_Up_3",          label = "Eternal Engine",  weight = 1 },
}

--==============================================================================
-- HELPERS
--==============================================================================

local function safe(fn, default)
    local ok, result = pcall(fn)
    if ok then return result end
    return default
end

local function valid(obj)
    if obj == nil then return false end
    return safe(function() return obj:IsValid() end, false)
end

local function pickGood(exclude)
    local avail, total = {}, 0
    for _, e in ipairs(GOOD_POOL) do
        if e.weight > 0 and not exclude[e.name] then
            table.insert(avail, e)
            total = total + e.weight
        end
    end
    if total <= 0 then return nil end
    local roll = math.random() * total
    local acc = 0
    for _, e in ipairs(avail) do
        acc = acc + e.weight
        if roll <= acc then return e.name, e.label end
    end
    local last = avail[#avail]
    return last and last.name, last and last.label
end

-- Check if FGuid is non-zero (pal has an owner)
local function isNonZeroGuid(guid)
    if guid == nil then return false end
    local a = tonumber(safe(function() return guid.A end))
    local b = tonumber(safe(function() return guid.B end))
    local c = tonumber(safe(function() return guid.C end))
    local d = tonumber(safe(function() return guid.D end))
    if a == nil or b == nil or c == nil or d == nil then return false end
    return (a ~= 0) or (b ~= 0) or (c ~= 0) or (d ~= 0)
end

-- Check if a pal is already owned (not a wild spawn)
local function isOwned(sp)
    return safe(function()
        if isNonZeroGuid(sp.OwnerPlayerUId) then return true end
        -- Also check old owners
        local old = sp.OldOwnerPlayerUIds
        if old ~= nil then
            local n = #old
            if n and n > 0 then return true end
        end
        return false
    end, false)
end

-- Check if a pal has the "Rare" passive (i.e., it's a lucky pal)
local function isLuckyPal(sp)
    local list = safe(function() return sp.PassiveSkillList end)
    if list == nil then return false end
    local n = safe(function() return #list end, 0) or 0
    for i = 1, math.min(n, 4) do
        local elem = safe(function() return list[i] end)
        if elem ~= nil then
            local raw = safe(function() return elem:ToString() end, "") or ""
            if raw == "Rare" then return true end
        end
    end
    return false
end

--==============================================================================
-- CORE LOGIC
--==============================================================================

local function cleanPassives(parameter, passiveSkillComp)
    if not valid(parameter) then return end

    local sp = safe(function() return parameter.SaveParameter end)
    if sp == nil then return end

    local list = safe(function() return sp.PassiveSkillList end)
    if list == nil then return end

    if FORCE_RANDOM_GOD_ROLL then
        local candidates = {}
        for _, entry in ipairs(GOD_POOL) do
            table.insert(candidates, entry)
        end
        local finalNames = {}
        local labels = {}
        local originalCount = safe(function() return #list end, 0) or 0
        for i = 1, math.min(originalCount, 4) do
            local elem = safe(function() return list[i] end)
            local raw = elem and (safe(function() return elem:ToString() end, "") or "") or ""
            if raw ~= "" and isExclusivePassive(raw) then
                table.insert(finalNames, FName(raw))
                table.insert(labels, raw .. " (preserved exclusive)")
            end
        end
        while #finalNames < 4 and #candidates > 0 do
            local index = math.random(1, #candidates)
            local entry = table.remove(candidates, index)
            table.insert(finalNames, FName(entry.name))
            table.insert(labels, entry.label)
        end
        safe(function() sp.PassiveSkillList = finalNames end)
        safe(function() parameter.PassiveSkillList = finalNames end)
        if valid(passiveSkillComp) then
            safe(function() passiveSkillComp:SetupSkillFromSelf(parameter, finalNames) end)
        end
        print(TAG .. "Forced random god roll: " .. table.concat(labels, ", "))
        return
    end

    local n = safe(function() return #list end, 0) or 0

    local goodNames = {}
    local exclude = {}
    local removedAny = false

    for i = 1, math.min(n, 4) do
        local elem = safe(function() return list[i] end)
        if elem ~= nil then
            local raw = safe(function() return elem:ToString() end, "") or ""
            if raw ~= "" then
                exclude[raw] = true
                if BAD[raw] then
                    removedAny = true
                else
                    table.insert(goodNames, raw)
                end
            end
        end
    end

    if not removedAny then
        return
    end

    local targetMax = 4
    local result = {}
    for _, n in ipairs(goodNames) do table.insert(result, n) end
    for _ = #result + 1, targetMax do
        local picked, label = pickGood(exclude)
        if picked == nil then break end
        exclude[picked] = true
        table.insert(result, picked)
    end
    goodNames = result

    if #goodNames == 0 then
        safe(function() sp.PassiveSkillList = {} end)
        safe(function() parameter.PassiveSkillList = {} end)
        if valid(passiveSkillComp) then
            safe(function() passiveSkillComp:SetupSkillFromSelf(parameter, {}) end)
        end
        return
    end

    local finalNames = {}
    for _, name in ipairs(goodNames) do
        table.insert(finalNames, FName(name))
    end

    safe(function() sp.PassiveSkillList = finalNames end)
    safe(function() parameter.PassiveSkillList = finalNames end)
    if valid(passiveSkillComp) then
        safe(function() passiveSkillComp:SetupSkillFromSelf(parameter, finalNames) end)
    end

    local logStr = "Done. "
    for _, n in ipairs(goodNames) do
        local label = n
        for _, e in ipairs(GOOD_POOL) do
            if e.name == n then label = e.label break end
        end
        logStr = logStr .. label .. ", "
    end
    logStr = logStr:gsub(", $", "")
    print(TAG .. logStr)
end

--==============================================================================
-- HOOK
--==============================================================================

NotifyOnNewObject("/Script/Pal.PalCharacter", function(palCharacter)
    if not valid(palCharacter) then return end

    ExecuteWithDelay(500, function()
        if not valid(palCharacter) then return end

        local component = safe(function() return palCharacter.CharacterParameterComponent end)
        if not valid(component) then return end

        local parameter = safe(function() return component.IndividualParameter end)
        if not valid(parameter) then return end

        local passiveComp = safe(function() return palCharacter.PassiveSkillComponent end)

        local sp = safe(function() return parameter.SaveParameter end)
        if sp == nil then return end

        local hp  = safe(function() return tonumber(sp.Talent_HP) end, -1)
        local atk = safe(function() return tonumber(sp.Talent_Shot) end, -1)
        local def = safe(function() return tonumber(sp.Talent_Defense) end, -1)

        if not (type(hp) == "number" and type(atk) == "number" and type(def) == "number") then return end
        if not (hp >= 80 and atk >= 80 and def >= 80) then return end

        -- v4.4.5: Skip lucky pals if toggle is on (defer to AmazingLuckyPals)
        if SKIP_LUCKY_PALS and isLuckyPal(sp) then
            return
        end

        -- First ownership check (fast path for team/palbox)
        if isOwned(sp) then return end

        -- Not owned at 500ms. Schedule retry at 3s for base-deployed pals.
        ExecuteWithDelay(2500, function()
            if not valid(palCharacter) then return end

            -- Re-fetch sp (may have changed)
            local sp2 = safe(function() return parameter.SaveParameter end)
            if sp2 == nil then return end

            -- v4.4.5: Re-check lucky status on retry
            if SKIP_LUCKY_PALS and isLuckyPal(sp2) then
                print(TAG .. "Lucky pal detected on retry, skipped.")
                return
            end

            if isOwned(sp2) then
                print(TAG .. "Base pal detected, skipped.")
                return  -- Base pal, don't touch
            end

            -- Still not owned — this is a wild spawn
            cleanPassives(parameter, passiveComp)
        end)
    end)
end)

print(TAG .. "v4.4.5 loaded. SKIP_LUCKY_PALS=" .. tostring(SKIP_LUCKY_PALS))
