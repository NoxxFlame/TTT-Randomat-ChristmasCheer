local EVENT = {}

local eventnames = {}
table.insert(eventnames, "What do you get if you eat Christmas decorations? Tinselitis!")
table.insert(eventnames, "What do Santa's little helpers learn at school? The elf-abet!")
table.insert(eventnames, "Who hides in the bakery at Christmas? A mince spy!")
table.insert(eventnames, "Who delivers presents to pets? Santa Paws!")
table.insert(eventnames, "Who is Santa's favourite singer? Elf-is Presley!")
table.insert(eventnames, "What do you call a reindeer who can't see? No-eye deer!")
table.insert(eventnames, "How do snowmen get around? They ride an icicle!")
table.insert(eventnames, "What does Santa spend his wages on? Jingle bills!")
table.insert(eventnames, "What do monkeys sing at Christmas? Jungle bells!")
table.insert(eventnames, "What cars do elves drive? Toy-otas!")
table.insert(eventnames, "What do you call an obnoxious reindeer? Rude-olph!")
table.insert(eventnames, "What do the elves cook with in the kitchen? Utinsels!")

CreateConVar("randomat_christmascheer_activation_timer", 20, FCVAR_NONE, "Time in seconds before the starting elves are revealed", 5, 90)
CreateConVar("randomat_christmascheer_elf_size", 0.5, FCVAR_NONE, "The size multiplier for the elf to use when they are revealed (e.g. 0.5 = 50% size)", 0, 1)
CreateConVar("randomat_christmascheer_disable_santa", 1, FCVAR_NONE, "Whether players with the Santa role should be switched to regular detectives")


local function GetEventDescription()
    return "Someone will turn into a elf in " .. GetConVar("randomat_christmascheer_activation_timer"):GetInt() .. " seconds and spread some Christmas cheer!"
end

EVENT.Title = table.Random(eventnames)
EVENT.AltTitle = "Christmas Cheer"
EVENT.Description = GetEventDescription()
EVENT.id = "christmascheer"
EVENT.Categories = {"rolechange", "fun", "largeimpact"}

local function ActivateElf(p)
    if timer.Exists("RdmtElfActivate") then
        timer.UnPause("RdmtElfActivate")
        local remaining = timer.TimeLeft("RdmtElfActivate")
        SetGlobalFloat("ttt_elf_activate", CurTime() + remaining)
        p:GodEnable()
    else
        p:SetNWBool("ElfActive", true)
        p:GodDisable()
        p:SetHealth(GetConVar("ttt_elf_starting_health"):GetInt())
        p:SetMaxHealth(GetConVar("ttt_elf_max_health"):GetInt())
        p:PrintMessage(HUD_PRINTTALK, "You have transformed into " .. string.lower(ROLE_STRINGS_EXT[ROLE_ELF]) .. "!")

        local scale = GetConVar("randomat_christmascheer_elf_size"):GetFloat()
        p:SetPlayerScale(scale)
        local jumpPower = 160
        if scale < 1 then
            jumpPower = jumpPower + (-(120 * scale) + 125)
        end
        p:SetJumpPower(jumpPower)

        p:StripWeapons()
        p:Give("weapon_ttt_randomatcandycane")
    end
end

local function DeactivateElf(p)
    p:SetNWBool("ElfActive", false)
    p:GodDisable()
    p:ResetPlayerScale()
    p:SetJumpPower(160)
    p:StripWeapon("weapon_ttt_randomatcandycane")
    hook.Run("PlayerLoadout", p)
    if timer.Exists("RdmtElfActivate") then
        timer.Pause("RdmtElfActivate")
    end
end

function EVENT:Initialize()
    timer.Simple(1, function()
        CHRISTMASCHEER:RegisterRoles()
    end)
end

function EVENT:Begin()
    for _, p in ipairs(self:GetPlayers(false)) do
        p:SetNWBool("ElfActive", false)
        p:SetNWBool("OriginalElf", false)
    end

    self:AddHook("TTTPrintResultMessage", function(win_type)
        if win_type == WIN_ELF then
            LANG.Msg("win_elf")
            ServerLog("Result: Elves win.\n")
            return true
        end
    end)

    self:AddHook("TTTCheckForWin", function()
        local elf_alive = false
        local other_alive = false
        for _, v in ipairs(player.GetAll()) do
            if v:Alive() and v:IsTerror() then
                if v:IsRole(ROLE_ELF) then
                    elf_alive = true
                elseif not v:ShouldActLikeJester() then
                    other_alive = true
                end
            end
        end

        if elf_alive and not other_alive then
            return WIN_ELF
        elseif elf_alive then
            return WIN_NONE
        end
    end)

    local choice = nil
    -- First try and change a jester to the elf
    for _, p in ipairs(self:GetAlivePlayers(true)) do
        if Randomat:IsJesterTeam(p) and choice == nil then
            choice = p
        end
    end
    -- If there are no jesters, change a non-detective innocent to the elf
    if choice == nil then
        for _, p in ipairs(self:GetAlivePlayers(true)) do
            if Randomat:IsInnocentTeam(p) and not Randomat:IsDetectiveLike(p) and choice == nil then
                choice = p
            end
        end
    end

    Randomat:SetRole(choice, ROLE_ELF)
    choice:SetNWBool("OriginalElf", true)
    choice:GodEnable()
    choice:SetHealth(GetConVar("ttt_elf_starting_health"):GetInt())
    choice:SetMaxHealth(GetConVar("ttt_elf_max_health"):GetInt())
    self:StripRoleWeapons(choice)
    local activateTime = GetConVar("randomat_christmascheer_activation_timer"):GetInt()
    timer.Simple(0.5, function()
        choice:PrintMessage(HUD_PRINTTALK, "You are the " .. ROLE_STRINGS[ROLE_ELF] .. "! You have " .. activateTime .. " seconds until you are revealed and are invulnerable until then!")
    end)
    SetGlobalFloat("ttt_elf_activate", CurTime() + activateTime)

    if GetConVar("randomat_christmascheer_disable_santa"):GetBool() then
        ROLE_SANTA = ROLE_SANTA or -1
        if ROLE_SANTA ~= -1 then
            for _, p in ipairs(self:GetPlayers(false)) do
                if p:GetRole() == ROLE_SANTA then
                    Randomat:SetRole(p, ROLE_DETECTIVE)
                    self:StripRoleWeapons(p)
                end
            end
        end
    end

    SendFullStateUpdate()

    timer.Create("RdmtElfActivate", GetConVar("randomat_christmascheer_activation_timer"):GetInt(), 1, function()
        timer.Remove("RdmtElfActivate")
        for _, p in ipairs(self:GetPlayers(false)) do
            if p:GetRole() == ROLE_ELF then
                ActivateElf(p)
            else
                local message = string.Capitalize(ROLE_STRINGS_EXT[ROLE_ELF]) .. " has been spotted!"
                p:PrintMessage(HUD_PRINTTALK, message)
                p:PrintMessage(HUD_PRINTCENTER, message)
            end
        end
    end)

    self:AddHook("TTTPlayerRoleChanged", function(ply, oldRole, newRole)
        if oldRole ~= newRole then
            if oldRole == ROLE_ELF then
                DeactivateElf(ply)
            end
            if newRole == ROLE_ELF then
                ActivateElf(ply)
            end
        end
    end)

    self:AddHook("ScalePlayerDamage", function(ply, hitgroup, dmginfo)
        local att = dmginfo:GetAttacker()
        if IsPlayer(att) and GetRoundState() >= ROUND_ACTIVE then
            if att:IsRole(ROLE_ELF) then
                dmginfo:ScaleDamage(0)
            end
        end
    end)

    self:AddHook("PlayerCanPickupWeapon", function(ply, wep)
        if not IsValid(wep) or not IsValid(ply) then return end
        if ply:IsSpec() then return false end

        if wep:GetClass() == "weapon_ttt_randomatcandycane" then
            return ply:IsRole(ROLE_ELF)
        end

        if ply:IsRole(ROLE_ELF) and ply:IsRoleActive() and GetRoundState() == ROUND_ACTIVE then
            return false
        end
    end)
end

function EVENT:End()
    timer.Remove("RdmtElfActivate")
    for _, p in ipairs(self:GetPlayers(false)) do
        p:SetNWBool("ElfActive", false)
        p:SetNWBool("OriginalElf", false)
    end
end

function EVENT:Condition()
    if not CR_VERSION or not CRVersion("1.0.14") then return false end

    local options = 0
    for _, p in ipairs(self:GetAlivePlayers()) do
        if Randomat:IsIndependentTeam(p) or (Randomat:IsInnocentTeam(p) and not Randomat:IsDetectiveLike(p)) then
            options = options + 1
        end
    end

    return options > 0
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"activation_timer", "elf_size"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = v,
                dsc = convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax(),
                dcm = 0
            })
        end
    end

    local checks = {}
    for _, v in ipairs({"disable_santa"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(checks, {
                cmd = v,
                dsc = convar:GetHelpText()
            })
        end
    end

    return sliders, checks
end

Randomat:register(EVENT)