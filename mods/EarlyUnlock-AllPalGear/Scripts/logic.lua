-- =====================================================================
--  EarlyUnlock / logic.lua  (v1.2 - robusto a timing de load)
--  Destrava APENAS as selas/arreios de pal (SkillUnlock_*), DE GRACA:
--  escreve o nome direto na lista UnlockedTechnologyNameArray do
--  UPalTechnologyData (craftabilidade = Contains nessa lista), SEM cobrar
--  ponto de tecnologia; depois chama OnRep na mao pra refrescar. Dedupe
--  pela funcao do jogo (IsUnlockRecipeTechnology) pra nao inchar o array.
--
--  >>> POR QUE v1.2: a v1.1 tinha UMA corrida de load. Rodava o unlock 5s
--  depois de entrar no mundo e desistia apos ~41s; um guard de "ja rodei"
--  travava qualquer nova tentativa naquela sessao. Se o save carregava o
--  UPalTechnologyData devagar, a janela estourava -> "tudo travado" ate
--  reabrir o jogo (o boot 17:34 falhou, o 18:05 -- MESMO codigo -- deu).
--  Fix: retentar ate CONFIRMAR o efeito (a sentinela virou IsUnlock=true),
--  janela generosa (~2min), e re-armar a CADA entrada em mundo. Idempotente.
--
--  Roda sozinho no load. Ctrl+Shift+T = forcar unlock agora (manual).
-- =====================================================================
local M = { VERSION = "v1.2" }

local LOG = false   -- release
local function log(s) if LOG then print("[EarlyUnlock] " .. tostring(s) .. "\n") end end
local function safe(fn, d) local ok, v = pcall(fn); if ok and v ~= nil then return v end return d end
local function isok(o) return o ~= nil and safe(function() return o:IsValid() end, false) end

-- APENAS as selas/arreios de pal (SkillUnlock_*). As 3 construcoes cedo
-- (incubadora/expedicao/fazenda) NAO entram aqui -- isso e o mod EarlyBuildings.
-- Elas estavam misturadas por engano na v1.0/v1.1; separadas na v1.2.
local TECHS = {
    "SkillUnlock_DreamDemon", "SkillUnlock_DrillGame", "SkillUnlock_Eagle", "SkillUnlock_FlowerRabbit",
    "SkillUnlock_FlyingManta", "SkillUnlock_FlyingManta_Thunder", "SkillUnlock_Hedgehog", "SkillUnlock_Hedgehog_Ice",
    "SkillUnlock_LeafMomonga", "SkillUnlock_NegativeOctopus", "SkillUnlock_NegativeOctopus_Neutral",
    "SkillUnlock_RaijinDaughter", "SkillUnlock_RaijinDaughter_Water", "SkillUnlock_WindChimes", "SkillUnlock_WindChimes_Ice",
    "SkillUnlock_Boar", "SkillUnlock_Kitsunebi", "SkillUnlock_Alpaca", "SkillUnlock_Garm",
    "SkillUnlock_WeaselDragon", "SkillUnlock_Carbunclo", "SkillUnlock_Monkey", "SkillUnlock_Deer",
    "SkillUnlock_Monkey_Fire", "SkillUnlock_Kirin", "SkillUnlock_FlameBuffalo", "SkillUnlock_HawkBird",
    "SkillUnlock_Serpent", "SkillUnlock_Penguin", "SkillUnlock_ColorfulBird", "SkillUnlock_Penguin_Electric",
    "SkillUnlock_NaughtyCat", "SkillUnlock_FairyDragon", "SkillUnlock_PurpleSpider", "SkillUnlock_MopKing",
    "SkillUnlock_BirdDragon", "SkillUnlock_Deer_Ground", "SkillUnlock_BirdDragon_Ice", "SkillUnlock_KingAlpaca",
    "SkillUnlock_Kitsunebi_Ice", "SkillUnlock_BlueDragon", "SkillUnlock_FlowerDinosaur", "SkillUnlock_Serpent_Ground",
    "SkillUnlock_HadesBird", "SkillUnlock_FengyunDeeper", "SkillUnlock_IceSeal", "SkillUnlock_BlueDragon_Ice",
    "SkillUnlock_FeatherOstrich", "SkillUnlock_GrassMammoth", "SkillUnlock_FireKirin", "SkillUnlock_ThunderBird",
    "SkillUnlock_ThunderDog", "SkillUnlock_GhostAnglerfish", "SkillUnlock_IceDeer", "SkillUnlock_FairyDragon_Water",
    "SkillUnlock_GrassPanda", "SkillUnlock_Manticore", "SkillUnlock_RedArmorBird", "SkillUnlock_SakuraSaurus",
    "SkillUnlock_FireKirin_Dark", "SkillUnlock_GrassPanda_Electric", "SkillUnlock_FlowerDinosaur_Electric",
    "SkillUnlock_Manticore_Dark", "SkillUnlock_TropicalOstrich", "SkillUnlock_Plesiosaur", "SkillUnlock_GhostBeast",
    "SkillUnlock_SkyDragon", "SkillUnlock_BlackMetalDragon", "SkillUnlock_MushroomDragon", "SkillUnlock_MushroomDragon_Dark",
    "SkillUnlock_Umihebi", "SkillUnlock_ElecPanda", "SkillUnlock_WeaselDragon_Fire", "SkillUnlock_WhiteAlienDragon",
    "SkillUnlock_GuardianDog", "SkillUnlock_GrassMammoth_Ice", "SkillUnlock_IceNarwhal", "SkillUnlock_GhostAnglerfish_Fire",
    "SkillUnlock_VolcanicMonster", "SkillUnlock_Suzaku", "SkillUnlock_VolcanicMonster_Ice", "SkillUnlock_Suzaku_Water",
    "SkillUnlock_SakuraSaurus_Water", "SkillUnlock_SkyDragon_Grass", "SkillUnlock_LazyDragon", "SkillUnlock_Yeti",
    "SkillUnlock_KingBahamut", "SkillUnlock_KingAlpaca_Ice", "SkillUnlock_HadesBird_Electric", "SkillUnlock_BlackGriffon",
    "SkillUnlock_LazyDragon_Electric", "SkillUnlock_GrassGolem", "SkillUnlock_Yeti_Grass", "SkillUnlock_BadCatgirl",
    "SkillUnlock_MoonQueen", "SkillUnlock_GoldenHorse", "SkillUnlock_WhiteDeer", "SkillUnlock_IceSeal_Ground",
    "SkillUnlock_KingBahamut_Dragon", "SkillUnlock_NightBlueHorse", "SkillUnlock_FengyunDeeper_Electric",
    "SkillUnlock_AmaterasuWolf", "SkillUnlock_BlackPuppy", "SkillUnlock_BlueThunderHorse", "SkillUnlock_Umihebi_Fire",
    "SkillUnlock_AmaterasuWolf_Dark", "SkillUnlock_Horus", "SkillUnlock_Horus_Water", "SkillUnlock_WhiteShieldDragon",
    "SkillUnlock_SaintCentaur", "SkillUnlock_BlackCentaur", "SkillUnlock_IceHorse", "SkillUnlock_IceHorse_Dark",
    "SkillUnlock_Kirin_Ice", "SkillUnlock_PoseidonOrca", "SkillUnlock_KingSunfish", "SkillUnlock_KingSunfish_Thunder",
    "SkillUnlock_ThunderFluffyBird", "SkillUnlock_DarkMechaDragon", "SkillUnlock_GhostDragon", "SkillUnlock_GrassGolem_Dark",
    "SkillUnlock_LegendDeer", "SkillUnlock_ThunderBird_Ice", "SkillUnlock_IceNarwhal_Fire", "SkillUnlock_SnowTigerBeastman",
    "SkillUnlock_GhostDragon_Fire", "SkillUnlock_NightBlueHorse_Neutral", "SkillUnlock_WhiteDeer_Dark",
    "SkillUnlock_DomeArmorDragon", "SkillUnlock_JetDragon", "SkillUnlock_CubeTurtle", "SkillUnlock_CubeTurtle_Neutral",
    "SkillUnlock_VolcanoDragon", "SkillUnlock_VolcanoDragon_Ice", "SkillUnlock_Thunderdog_Ice", "SkillUnlock_SumoDog",
    "SkillUnlock_ThiefBird", "SkillUnlock_BlueSkyDragon", "SkillUnlock_LotusDragon",
}
M.TECHS = TECHS

-- sentinela de sucesso: a ULTIMA da lista (uma sela tardia). Se ela virou
-- IsUnlock=true, o pass inteiro rodou e PEGOU no objeto real -- prova por
-- EFEITO, nao por "pcall sem erro" (chamar sem erro != funcionou).
local SENTINEL = TECHS[#TECHS]

local function isUnlocked(td, name)
    return safe(function() return td:IsUnlockRecipeTechnology(FName(name)) end)
end

-- ---------- um pass de unlock (roda DENTRO da game thread) ----------
-- retorna: ok(bool, provado pela sentinela), msg, nAplicadas
local function unlockPass()
    local td = FindFirstOf("PalTechnologyData")
    if not isok(td) then return false, "PalTechnologyData ainda nao pronto", 0 end
    local arr = safe(function() return td.UnlockedTechnologyNameArray end)
    if not arr then return false, "sem UnlockedTechnologyNameArray", 0 end

    local n = 0
    for _, name in ipairs(TECHS) do
        if isUnlocked(td, name) ~= true then
            local cnt = safe(function() return arr:GetArrayNum() end, safe(function() return #arr end, 0))
            if pcall(function() arr[cnt + 1] = FName(name) end) then n = n + 1 end
        end
    end
    if n > 0 then pcall(function() td:OnRep_UnlockedTechnologyNameArray() end) end

    local ok = (isUnlocked(td, SENTINEL) == true)
    if ok then return true,  ("confirmado (+" .. n .. " novas destravadas)"), n
    else       return false, ("aplicou " .. n .. " mas sentinela ainda nao confirmou (objeto errado/nao pronto?)"), n end
end
M.unlockPass = unlockPass

-- ---------- auto no load: retenta ate CONFIRMAR ou esgotar ~2min ----------
local MAX_TRIES = 40   -- 40 x 3s ~= 2min de janela (v1.1 desistia em ~41s)
local function autoTry(tries)
    tries = tries or 0
    ExecuteInGameThread(function()
        if _G.__EarlyUnlock_done then return end
        local ok, msg = unlockPass()
        if ok then
            _G.__EarlyUnlock_done = true
            log("unlock OK na tentativa " .. tries .. ": " .. msg)
        elseif tries < MAX_TRIES then
            if tries == 0 or (tries % 5) == 0 then log("esperando o save (" .. msg .. "), tentativa " .. tries) end
            ExecuteWithDelay(3000, function() autoTry(tries + 1) end)
        else
            log("!! DESISTI apos " .. MAX_TRIES .. " tentativas: " .. msg .. " -- me avisa que eu investigo com sonda")
        end
    end)
end

-- forcar do zero (Ctrl+Shift+T): re-arma e tenta ja
local function forceNow()
    _G.__EarlyUnlock_done = false
    autoTry(0)
end
M.force = forceNow

if not _G.__EarlyUnlock_hooked then
    _G.__EarlyUnlock_hooked = true

    -- roda ao entrar no mundo; re-arma a cada entrada (troca de save etc.).
    -- idempotente: dedupe por IsUnlock, entao rodar de novo nao incha nada.
    pcall(function()
        RegisterHook("/Script/Engine.PlayerController:ClientRestart", function()
            _G.__EarlyUnlock_done = false
            ExecuteWithDelay(5000, function()
                if not _G.__EarlyUnlock_done then autoTry(0) end
            end)
        end)
    end)

    -- Ctrl+Shift+T: forcar unlock agora (rede de seguranca manual).
    -- O callback da tecla NAO pode chamar ExecuteInGameThread direto: com um
    -- LoopInGameThreadWithDelay ativo em outro mod (o MiniBuilds tem um), isso
    -- MATA a fila de game thread do UE4SS -- loop e fila morrem juntos e so
    -- voltam reiniciando o jogo. Empurrar pro async primeiro e o caminho seguro:
    -- dali o ExecuteInGameThread do autoTry roda como qualquer outro agendamento.
    pcall(function()
        RegisterKeyBind(Key.T, { ModifierKey.CONTROL, ModifierKey.SHIFT }, function()
            log("Ctrl+Shift+T -> forcando unlock...")
            if type(ExecuteWithDelay) == "function" then
                ExecuteWithDelay(1, forceNow)
            else
                forceNow()
            end
        end)
    end)

    log("pronto (" .. M.VERSION .. "). Auto no load (retenta ate confirmar) + Ctrl+Shift+T. " .. #TECHS .. " techs.")
end

return M
