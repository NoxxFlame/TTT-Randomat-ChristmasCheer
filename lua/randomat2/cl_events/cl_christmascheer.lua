local EVENT = {}
EVENT.id = "christmascheer"

function EVENT:Initialize()
    timer.Simple(1, function()
        CHRISTMASCHEER:RegisterRoles()
    end)
end

function EVENT:Begin()
    self:AddHook("TTTScoringWinTitle", function(wintype, wintitle, title)
        if wintype == WIN_ELF then
            return { txt = "hilite_win_role_plural", params = { role = ROLE_STRINGS_PLURAL[ROLE_ELF]:upper() }, c = ROLE_COLORS[ROLE_ELF] }
        end
    end)

    self:AddHook("TTTEventFinishText", function(e)
        if e.win == WIN_ELF then
            return LANG.GetTranslation("ev_win_elf")
        end
    end)

    self:AddHook("TTTEventFinishIconText", function(e, win_string, role_string)
        if e.win == WIN_ELF then
            return win_string, ROLE_STRINGS_PLURAL[ROLE_ELF]
        end
    end)

    self:AddHook("TTTTutorialRoleEnabled", function(role)
        if role == ROLE_ELF and Randomat:IsEventActive("christmascheer") then
            return true
        end
    end)

    self:AddHook("TTTTutorialRoleText", function(role, titleLabel)
        if role ~= ROLE_ELF then return end

        local roleColor = GetRoleTeamColor(ROLE_TEAM_INDEPENDENT)
        local html = "The " .. ROLE_STRINGS[role] .. " is an <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>independent</span> role whose job is to spread Christmas cheer to all other players and convert them into " .. ROLE_STRINGS_PLURAL[role] .. "using their <span style='color: rgb(\" .. roleColor.r .. \", \" .. roleColor.g .. \", \" .. roleColor.b .. \")'>Candy Cane</span>. Players will be frozen in place while they are being converted."
        return html
    end)

    ---------------
    -- TARGET ID --
    ---------------

    -- Reveal the loot goblin to all players once activated
    self:AddHook("TTTTargetIDPlayerRoleIcon", function(ply, client, role, noz, colorRole, hideBeggar, showJester, hideBodysnatcher)
        if ply:IsActiveRole(ROLE_ELF) and ply:IsRoleActive() then
            return ROLE_ELF, false
        end
    end)

    self:AddHook("TTTTargetIDPlayerRing", function(ent, client, ringVisible)
        if IsPlayer(ent) and ent:IsActiveRole(ROLE_ELF) and ent:IsRoleActive() then
            return true, ROLE_COLORS_RADAR[ROLE_ELF]
        end
    end)

    self:AddHook("TTTTargetIDPlayerText", function(ent, client, text, clr, secondaryText)
        if IsPlayer(ent) and ent:IsActiveRole(ROLE_ELF) and ent:IsRoleActive() then
            return string.upper(ROLE_STRINGS[ROLE_ELF]), ROLE_COLORS_RADAR[ROLE_ELF]
        end
    end)

    ROLE_IS_TARGETID_OVERRIDDEN[ROLE_ELF] = function(ply, target)
        if not IsPlayer(target) then return end
        if not target:IsActiveRole(ROLE_ELF) then return end
        if not target:IsRoleActive() then return end

        ------ icon, ring, text
        return true, true, true
    end

    ----------------
    -- SCOREBOARD --
    ----------------

    self:AddHook("TTTScoreboardPlayerRole", function(ply, client, color, roleFileName)
        if ply:IsActiveRole(ROLE_ELF) and ply:IsRoleActive() then
            return ROLE_COLORS_SCOREBOARD[ROLE_ELF], ROLE_STRINGS_SHORT[ROLE_ELF]
        end
    end)

    ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[ROLE_ELF] = function(ply, target)
        if not IsPlayer(target) then return end
        if not target:IsActiveRole(ROLE_ELF) then return end
        if not target:IsRoleActive() then return end

        ------ name,  role
        return false, true
    end

    ---------
    -- HUD --
    ---------

    self:AddHook("TTTHUDInfoPaint", function(client, label_left, label_top, active_labels)
        local hide_role = false
        if ConVarExists("ttt_hide_role") then
            hide_role = GetConVar("ttt_hide_role"):GetBool()
        end

        if hide_role then return end

        if client:IsActiveRole(ROLE_ELF) and not client:IsRoleActive() then
            surface.SetFont("TabLarge")
            surface.SetTextColor(255, 255, 255, 230)

            local remaining = math.max(0, GetGlobalFloat("ttt_elf_activate", 0) - CurTime())
            local text = LANG.GetParamTranslation("lootgoblin_hud", { time = util.SimpleTime(remaining, "%02i:%02i") })
            local _, h = surface.GetTextSize(text)

            -- Move this up based on how many other labels here are
            label_top = label_top + (20 * #active_labels)

            surface.SetTextPos(label_left, ScrH() - label_top - h)
            surface.DrawText(text)

            -- Track that the label was added so others can position accurately
            table.insert(active_labels, "elf")
        end
    end)

    -------------
    -- SUMMARY --
    -------------

    self:AddHook("TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
        if finalRole == ROLE_ELF and not ply:GetNWBool("OriginalElf", false) then
            return ROLE_STRINGS_SHORT[startingRole], startingRole
        end
    end)

    ---------------------
    -- ROUND END SOUND --
    ---------------------

    self:AddHook("TTTChooseRoundEndSound", function(ply, result)
        if result == WIN_ELF then return "jinglebells.wav" end
    end)

end

Randomat:register(EVENT)