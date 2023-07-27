net.Receive("RandomatChristmasCheerBegin", function()
    CHRISTMASCHEER:RegisterRoles()

    hook.Add("TTTScoringWinTitle", "RandomatElfWinScoring", function(wintype, wintitle, title)
        if wintype == WIN_ELF then
            return { txt = "hilite_win_role_plural", params = { role = ROLE_STRINGS_PLURAL[ROLE_ELF]:upper() }, c = ROLE_COLORS[ROLE_ELF] }
        end
    end)

    hook.Add("TTTEventFinishText", "RandomatElfEventFinishText", function(e)
        if e.win == WIN_ELF then
            return LANG.GetTranslation("ev_win_elf")
        end
    end)

    hook.Add("TTTEventFinishIconText", "RandomatElfEventFinishText", function(e, win_string, role_string)
        if e.win == WIN_ELF then
            return win_string, ROLE_STRINGS_PLURAL[ROLE_ELF]
        end
    end)

    hook.Add("TTTTutorialRoleEnabled", "RandomatElfTutorialRoleEnabled", function(role)
        if role == ROLE_ELF and Randomat:IsEventActive("christmascheer") then
            return true
        end
    end)

    hook.Add("TTTTutorialRoleText", "RandomatElfTutorialRoleText", function(role, titleLabel)
        if role ~= ROLE_ELF then return end

        local roleColor = GetRoleTeamColor(ROLE_TEAM_INDEPENDENT)
        local html = "The " .. ROLE_STRINGS[role] .. " is an <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>independent</span> role whose job is to spread Christmas cheer to all other players and convert them into " .. ROLE_STRINGS_PLURAL[role] .. "using their <span style='color: rgb(\" .. roleColor.r .. \", \" .. roleColor.g .. \", \" .. roleColor.b .. \")'>Candy Cane</span>. Players will be frozen in place while they are being converted."
        return html
    end)

    ---------------
    -- TARGET ID --
    ---------------

    -- Reveal the loot goblin to all players once activated
    hook.Add("TTTTargetIDPlayerRoleIcon", "Elf_TTTTargetIDPlayerRoleIcon", function(ply, client, role, noz, colorRole, hideBeggar, showJester, hideBodysnatcher)
        if ply:IsActiveRole(ROLE_ELF) and ply:IsRoleActive() then
            return ROLE_ELF, false
        end
    end)

    hook.Add("TTTTargetIDPlayerRing", "Elf_TTTTargetIDPlayerRing", function(ent, client, ringVisible)
        if IsPlayer(ent) and ent:IsActiveRole(ROLE_ELF) and ent:IsRoleActive() then
            return true, ROLE_COLORS_RADAR[ROLE_ELF]
        end
    end)

    hook.Add("TTTTargetIDPlayerText", "Elf_TTTTargetIDPlayerText", function(ent, client, text, clr, secondaryText)
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

    hook.Add("TTTScoreboardPlayerRole", "Elf_TTTScoreboardPlayerRole", function(ply, client, color, roleFileName)
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

    hook.Add("TTTHUDInfoPaint", "Elf_TTTHUDInfoPaint", function(client, label_left, label_top, active_labels)
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

    hook.Add("TTTScoringSummaryRender", "Elf_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
        if finalRole == ROLE_ELF and not ply:GetNWBool("OriginalElf", false) then
            return ROLE_STRINGS_SHORT[startingRole], startingRole
        end
    end)

    ---------------------
    -- ROUND END SOUND --
    ---------------------

    hook.Add("TTTChooseRoundEndSound", "Elf_TTTChooseRoundEndSound", function(ply, result)
        if result == WIN_ELF then return "jinglebells.wav" end
    end)

end)

net.Receive("RandomatChristmasCheerEnd", function()
    hook.Remove("TTTScoringWinTitle", "RandomatElfWinScoring")
    hook.Remove("TTTEventFinishText", "RandomatElfEventFinishText")
    hook.Remove("TTTEventFinishIconText", "RandomatElfEventFinishText")
    hook.Remove("TTTTutorialRoleEnabled", "RandomatElfTutorialRoleEnabled")
    hook.Remove("TTTTutorialRoleText", "RandomatElfTutorialRoleText")
    hook.Remove("TTTTargetIDPlayerRoleIcon", "Elf_TTTTargetIDPlayerRoleIcon")
    hook.Remove("TTTTargetIDPlayerRing", "Elf_TTTTargetIDPlayerRing")
    hook.Remove("TTTTargetIDPlayerText", "Elf_TTTTargetIDPlayerText")
    hook.Remove("TTTScoreboardPlayerRole", "Elf_TTTScoreboardPlayerRole")
    hook.Remove("TTTHUDInfoPaint", "Elf_TTTHUDInfoPaint")
    hook.Remove("TTTScoringSummaryRender", "Elf_TTTScoringSummaryRender")
    -- hook.Remove("TTTChooseRoundEndSound", "Elf_TTTChooseRoundEndSound")
end)