-- Seals vs Frog Dogs: native game data, team boards and personal milestone rewards.
return function(context)
    local settings = context.Settings
    settings.comp = type(settings.comp) == "table" and settings.comp or {}
    local config = settings.comp
    local competition = context.Competition
    local icons = competition and competition.Icons or {}
    local tab = context.Window:Tab({Title="Comp", Icon=icons.Rewards or "rbxassetid://102958595859917"})
    tab:Section({Title=competition and competition.Name or "Competition"})
    local teamCard = tab:Paragraph({Title="Your Team", Desc="Loading competition data..."})
    tab:Section({Title="Your Contributions"})
    local cards = {
        Hatches=tab:Paragraph({Title="Hatches", Desc="Loading...", Icon=icons.Hatches}),
        Bubbles=tab:Paragraph({Title="Bubbles", Desc="Loading...", Icon=icons.Bubbles}),
    }
    tab:Section({Title="Milestone Rewards"})
    for _, metric in ipairs({"Hatches", "Bubbles"}) do
        local key = "autoClaim" .. metric
        tab:Toggle({Title="Auto Claim " .. metric, Desc="Collect earned " .. metric:lower() .. " milestones.",
            Value=config[key]==true, Callback=function(value) config[key]=value==true;context.Save() end})
    end
    local status = tab:Paragraph({Title="Reward Status", Desc="Automatic claiming is off."})
    local season = competition and competition.GetSeason()
    local standings, snapshotAt, pending = nil, -math.huge, {}
    local lastJoinAt=-math.huge
    local leaderboardPopup
    tab:Button({Title="Live Leaderboards", Desc="Both teams' top 100 in a live popout.", Callback=function()
        if not context.Active() then return end
        if not leaderboardPopup or not leaderboardPopup:IsOpen() then
            local ok, popup=pcall(context.CreateLeaderboard)
            leaderboardPopup=ok and popup or nil
        end
        if not leaderboardPopup then teamCard:SetDesc("Competition frame is not available in this server.");return end
        leaderboardPopup:Update(standings,competition)
        snapshotAt=context.Now();context.Fire("PinkVsBlueView",true)
    end})
    local function contribution()
        if type(context.Profile.IsReady)=="function" then
            local ready,value=pcall(context.Profile.IsReady,context.Profile)
            if not ready or not value then return nil,false end
        end
        local ok, current = pcall(context.Profile.Get,context.Profile)
        if not ok or type(current)~="table" then return nil,false end
        local entries=type(current.PinkVsBlue)=="table" and current.PinkVsBlue or {}
        return season and (entries[tostring(season.Id)] or entries[season.Id]) or nil,true
    end
    local function commas(value)
        local text = string.format("%.0f", math.max(0, tonumber(value) or 0))
        local result = text:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
        return result
    end
    local function teamPlace(own, metric)
        local board = standings and standings.Boards and standings.Boards[own.Team]
        board = board and board[metric]
        if type(board)~="table" then return "Waiting for standings" end
        local score, rank = tonumber(own[metric]) or 0, 1
        for index, entry in ipairs(board) do
            if tostring(entry.UserId)==tostring(context.UserId) then
                if standings.Final or score <= (tonumber(entry.Score) or 0) then return "#" .. index end
            elseif (tonumber(entry.Score) or 0)>=score then rank+=1 end
        end
        if standings.Final or score<=0 or rank>100 then return "Outside top 100" end
        return "#" .. rank
    end
    local function refresh()
        if not competition or competition.Enabled~=true or not season then
            teamCard:SetTitle("Competition Unavailable")
            teamCard:SetDesc("This server does not have an active competition.")
            for metric, card in pairs(cards) do card:SetTitle(metric);card:SetDesc("Unavailable") end
            status:SetDesc("No rewards to claim in this server.")
            return nil
        end
        local own,ready = contribution()
        local team = own and competition.Teams[own.Team]
        teamCard:SetTitle(team and team.Name or "Join a Team")
        teamCard:SetDesc(team and competition.Name or "A team will be assigned automatically while the event is active.")
        teamCard:SetIcon(team and team.Shield or nil)
        for metric, card in pairs(cards) do
            card:SetTitle(own and (commas(own[metric]) .. " " .. metric) or metric)
            card:SetDesc(own and ("Team place: " .. teamPlace(own, metric)) or "Join the event to start contributing.")
        end
        local claimed, earned, waiting = 0, 0, 0
        local claims = own and type(own.Claims)=="table" and own.Claims or {}
        for _, metric in ipairs({"Hatches", "Bubbles"}) do
            for index, reward in ipairs(season.PersonalRewards[metric] or {}) do
                local key="Personal:" .. metric .. ":" .. index
                if claims[key] then claimed+=1
                elseif own and (tonumber(own[metric]) or 0)>=reward.Requirement then
                    earned+=1
                    if pending[key] then waiting+=1 end
                end
            end
        end
        local enabled = config.autoClaimHatches==true or config.autoClaimBubbles==true
        status:SetDesc(claimed .. " claimed | " .. earned .. " ready" .. (waiting>0 and (" | " .. waiting .. " pending") or "")
            .. (enabled and "" or " | Auto claim off"))
        return own,ready
    end
    local function receive(action, snapshot)
        if not context.Active() or action~="PinkVsBlueSnapshot" or type(snapshot)~="table" then return end
        if type(snapshot.Season)~="table" or type(snapshot.Season.PersonalRewards)~="table" or type(snapshot.Standings)~="table" then return end
        if season and tostring(season.Id)~=tostring(snapshot.Season.Id) then pending={};lastJoinAt=-math.huge end
        season, standings, snapshotAt = snapshot.Season, snapshot.Standings, context.Now()
        if leaderboardPopup and leaderboardPopup:IsOpen() then leaderboardPopup:Update(standings,competition) end
        refresh()
    end
    local function step()
        if not context.Active() then return end
        local own,ready = refresh()
        if not season or not competition or competition.Enabled~=true then return end
        local refreshEvery=leaderboardPopup and leaderboardPopup:IsOpen() and 5 or 30
        if context.Now()-snapshotAt>=refreshEvery then
            snapshotAt=context.Now()
            context.Fire("PinkVsBlueView",true)
        end
        -- Use the native server-assigned random team, without a preference/toggle.
        -- Wait for replicated profile confirmation and back off rejected/slow joins.
        local wallTime=(context.WallTime or os.time)()
        local startsAt,endsAt=tonumber(season.StartsAt),tonumber(season.EndsAt)
        if ready and (not own or own.Team==nil or own.Team=="") and startsAt and endsAt
            and wallTime>=startsAt and wallTime<endsAt and context.Now()-lastJoinAt>=15 then
            lastJoinAt=context.Now()
            context.Fire("PinkVsBlueJoin")
        end
        if not own or not competition.Teams[own.Team] then return end
        local claims = type(own.Claims)=="table" and own.Claims or {}
        -- One claim per update avoids a burst when several milestones become available together.
        for _, metric in ipairs({"Hatches", "Bubbles"}) do
            if config["autoClaim" .. metric]==true then
                for index, reward in ipairs(season.PersonalRewards[metric] or {}) do
                    local key="Personal:" .. metric .. ":" .. index
                    if claims[key] then pending[key]=nil
                    elseif (tonumber(own[metric]) or 0)>=reward.Requirement
                        and (not pending[key] or context.Now()-pending[key]>=15) then
                        pending[key]=context.Now()
                        context.Fire("PinkVsBlueClaim",season.Id,metric,index)
                        refresh()
                        return
                    end
                end
            end
        end
    end
    tab:Button({Title="Refresh Competition", Desc="Updates your contributions and requests fresh team standings.", Callback=function()
        if not context.Active() then return end
        snapshotAt=-math.huge
        step()
    end})
    if competition and competition.Enabled==true then
        context.Connect(context.Signal,receive)
        context.Restore(function()
            if leaderboardPopup then leaderboardPopup:Close() end
            if not context.NativeOpen() then context.Fire("PinkVsBlueView",false) end
        end)
    end
    refresh()
    task.spawn(function()
        while context.Active() do
            local ok, err=pcall(step)
            if not ok then status:SetDesc("Competition refresh failed; retrying shortly.");warn("[@qtrzip] Comp: " .. tostring(err)) end
            task.wait(0.5)
        end
    end)
    return {Step=step,Refresh=refresh,Receive=receive,Tab=tab}
end
