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
    local function contribution()
        local ok, current = pcall(context.Profile.Get,context.Profile)
        if not ok or type(current)~="table" then return nil end
        return season and current and type(current.PinkVsBlue)=="table" and current.PinkVsBlue[tostring(season.Id)] or nil
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
        local own = contribution()
        local team = own and competition.Teams[own.Team]
        teamCard:SetTitle(team and team.Name or "Join a Team")
        teamCard:SetDesc(team and competition.Name or "Join Seals or Frog Dogs at the event pad.")
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
        return own
    end
    local function receive(action, snapshot)
        if not context.Active() or action~="PinkVsBlueSnapshot" or type(snapshot)~="table" then return end
        if type(snapshot.Season)~="table" or type(snapshot.Season.PersonalRewards)~="table" or type(snapshot.Standings)~="table" then return end
        if season and tostring(season.Id)~=tostring(snapshot.Season.Id) then pending={} end
        season, standings, snapshotAt = snapshot.Season, snapshot.Standings, context.Now()
        refresh()
    end
    local function step()
        if not context.Active() then return end
        local own = refresh()
        if not season or not competition or competition.Enabled~=true then return end
        if context.Now()-snapshotAt>=30 then
            snapshotAt=context.Now()
            context.Fire("PinkVsBlueView",true)
        end
        if not own then return end
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
