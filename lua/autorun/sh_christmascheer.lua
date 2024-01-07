CHRISTMASCHEER = {
    registered = false
}

if SERVER then
    resource.AddFile("materials/vgui/ttt/icon_elf.vmt")
    resource.AddFile("materials/vgui/ttt/sprite_elf.vmt")
    resource.AddSingleFile("materials/vgui/ttt/sprite_elf_noz.vmt")
    resource.AddSingleFile("materials/vgui/ttt/score_elf.png")
    resource.AddSingleFile("materials/vgui/ttt/tab_elf.png")
end

function CHRISTMASCHEER:RegisterRoles()
    if self.registered then return end

    self.registered = true

    local role = {
        nameraw = "elf",
        name = "Elf",
        nameplural = "Elves",
        nameext = "an Elf",
        nameshort = "elf",
        team = ROLE_TEAM_INDEPENDENT,
        translations = {
            ["english"] = {
                ["candycant_help_pri"] = "Use {primaryfire} to spread Christmas cheer"
            }
        }
    }

    CreateConVar("ttt_elf_enabled", "0", FCVAR_REPLICATED)
    CreateConVar("ttt_elf_spawn_weight", "1")
    CreateConVar("ttt_elf_min_players", "0")
    CreateConVar("ttt_elf_starting_health", "50")
    CreateConVar("ttt_elf_max_health", "50")
    CreateConVar("ttt_elf_name", role.name, FCVAR_REPLICATED)
    CreateConVar("ttt_elf_name_plural", role.nameplural, FCVAR_REPLICATED)
    CreateConVar("ttt_elf_name_article", role.nameext, FCVAR_REPLICATED)
    CreateConVar("ttt_elf_shop_random_percent", "0", FCVAR_REPLICATED)
    CreateConVar("ttt_elf_shop_random_enabled", "0", FCVAR_REPLICATED)
    CreateConVar("ttt_elf_can_see_jesters", "0", FCVAR_REPLICATED)
    CreateConVar("ttt_elf_update_scoreboard", "0", FCVAR_REPLICATED)
    CreateConVar("ttt_elf_shop_mode", "0", FCVAR_REPLICATED)
    RegisterRole(role)

    ROLE_IS_ACTIVE[ROLE_ELF] = function(ply)
        if ply:IsRole(ROLE_ELF) then return ply:GetNWBool("ElfActive", false) end
    end

    hook.Add("TTTSpeedMultiplier", "Elf_TTTSpeedMultiplier", function(ply, mults)
        if IsPlayer(ply) and ply:IsActiveRole(ROLE_ELF) and ply:IsRoleActive() then
            table.insert(mults, 1.2)
        end
    end)

    if SERVER then
        WIN_ELF = GenerateNewWinID(ROLE_ELF)

        net.Start("TTT_SyncWinIDs")
        net.WriteTable(WINS_BY_ROLE)
        net.WriteUInt(WIN_MAX, 16)
        net.Broadcast()
    end

    if CLIENT then
        hook.Add("TTTSyncWinIDs", "RandomatElfTTTWinIDsSynced", function()
            WIN_ELF = WINS_BY_ROLE[ROLE_ELF]
        end)

        LANG.AddToLanguage("english", "win_elf", "The elves have spread Christmas cheer to everyone!")
        LANG.AddToLanguage("english", "ev_win_elf", "The elves have spread Christmas cheer to everyone!")

        LANG.AddToLanguage("english", "info_popup_elf", [[You are {role}!
Use your candy cane to spread
some Christmas cheer to everyone!]])
    end
end