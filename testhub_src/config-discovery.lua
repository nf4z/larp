-- Read-only workspace discovery. Parsed values are discarded after metadata extraction.
return function(ctx)
    local detector={Records={},Selected=nil}
    local sections={auto=true,eggs=true,pets=true,webhook=true,rift=true,quest=true,potions=true,enchant=true,event=true,shrine=true,diceboard=true,activity=true,updates=true}
    local flat={autoHatch=true,autoBubble=true,selectedEgg=true,webhookURL=true,potionType=true,RebirthMachineEnabled=true,autoOpenMystery=true,lastSeenScriptVersion=true}
    local function basename(path) return path:gsub('\\','/'):match('([^/]+)$') or path end
    local function family(name)
        local key=name:lower()
        local account=key:match('^1rzhubliteconfig_(%d+)%.json$')
        if account then return 'Larplite',account end
        if key=='qtrzip_settings.json' then return '@qtrzip' end
    end
    local function candidate(name)
        local key=name:lower()
        return key:sub(-5)=='.json' and (family(name)~=nil or key:find('config',1,true)~=nil or key:find('settings',1,true)~=nil)
    end
    function detector:Scan()
        if type(ctx.Read)~='function' or type(ctx.Decode)~='function' then self.Records={};return {},'File reading is unavailable in this executor.' end
        local paths,limited
        if type(ctx.List)=='function' then
            for _,root in ipairs({'.',''}) do
                local ok,value=pcall(ctx.List,root)
                if ok and type(value)=='table' then
                    paths=paths or {}
                    for _,path in ipairs(value) do table.insert(paths,path) end
                end
            end
        end
        if not paths then
            paths={'qtrzip_settings.json'}
            if tonumber(ctx.UserId) then table.insert(paths,'1rzHubLiteConfig_'..tostring(ctx.UserId)..'.json') end
            limited=true
        end
        local records,seen={},{}
        for _,path in ipairs(paths) do
            if type(path)=='string' then
                local name=basename(path)
                if candidate(name) and not seen[name:lower()] then
                    seen[name:lower()]=true
                    local exists=true
                    if ctx.IsFile then
                        local ok,value=pcall(ctx.IsFile,path)
                        exists=ok and value==true
                        if not exists and path~=name then local good,found=pcall(ctx.IsFile,name);exists=good and found==true end
                    end
                    if exists then
                        local ok,raw=pcall(ctx.Read,path)
                        if not ok and path~=name then ok,raw=pcall(ctx.Read,name) end
                        if ok and type(raw)=='string' then
                            if raw:sub(1,3)=='\239\187\191' then raw=raw:sub(4) end
                            local kind,account=family(name)
                            local record={Name=name,Kind=kind or 'Unknown',Account=account,Current=name:lower()=='qtrzip_settings.json',Count=0,Sections={}}
                            if #raw>1024*1024 then record.Issue='File exceeds the 1 MB discovery limit.'
                            else
                                local decoded,data=pcall(ctx.Decode,raw)
                                if not decoded or type(data)~='table' then record.Issue='Invalid JSON settings object.'
                                else
                                    local flatMatches,nestedMatches=0,0
                                    for key,value in pairs(data) do
                                        record.Count+=1
                                        if flat[key] then flatMatches+=1 end
                                        if sections[key] and type(value)=='table' then nestedMatches+=1;table.insert(record.Sections,key) end
                                    end
                                    table.sort(record.Sections)
                                    if not kind and flatMatches>=2 then record.Kind='Larplite'
                                    elseif not kind and nestedMatches>=2 then record.Kind='Hub settings'
                                    elseif not kind then record.Issue='Unrecognized config format.' end
                                end
                            end
                            table.insert(records,record)
                            if #records>=200 then break end
                        elseif not limited then
                            local kind,account=family(name)
                            table.insert(records,{Name=name,Kind=kind or 'Unknown',Account=account,Current=name:lower()=='qtrzip_settings.json',Count=0,Sections={},Issue='Could not read this file.'})
                        end
                    end
                end
            end
        end
        table.sort(records,function(a,b)
            if a.Current~=b.Current then return a.Current==true end
            local ownA,ownB=a.Account==tostring(ctx.UserId),b.Account==tostring(ctx.UserId)
            if ownA~=ownB then return ownA end
            return a.Name:lower()<b.Name:lower()
        end)
        self.Records=records
        return records,limited and 'Workspace listing unavailable; checked known filenames only.' or nil
    end
    if not ctx.Tab then return detector end
    local tab=ctx.Tab
    tab:Section({Title='Detected Configs'})
    local summary=tab:Paragraph({Title='Workspace Configs',Desc='Scanning config filenames...'})
    local preview
    local picker=tab:Dropdown({Title='Config File',Values={},Callback=function(name) if preview then preview(name) end end})
    local format=tab:Paragraph({Title='Format',Desc='Select a detected config.'})
    local account=tab:Paragraph({Title='Account',Desc='No config selected.'})
    local details=tab:Paragraph({Title='Saved Settings',Desc='Detection is read-only; your active settings stay unchanged.'})
    preview=function(name)
        detector.Selected=name
        local selected
        for _,record in ipairs(detector.Records) do if record.Name==name then selected=record;break end end
        if not selected then
            format:SetDesc('No config selected.');account:SetDesc('No config selected.')
            details:SetDesc('Detection is read-only; your active settings stay unchanged.');return
        end
        format:SetDesc(selected.Kind..(selected.Issue and (' â€” '..selected.Issue) or (selected.Current and ' â€” active settings file' or ' â€” recognized format')))
        if selected.Account then
            account:SetDesc((selected.Account==tostring(ctx.UserId) and 'Current player: ' or 'Other account: ')..selected.Account)
        else account:SetDesc('Shared file; no account ID in its filename.') end
        local sectionText=#selected.Sections>0 and (' | Sections: '..table.concat(selected.Sections,', ')) or ''
        details:SetDesc(tostring(selected.Count)..' top-level keys'..sectionText..'. No settings applied.')
    end
    local function refresh()
        local records,note=detector:Scan()
        local values,selected={},nil
        for _,record in ipairs(records) do
            local title=record.Current and '@qtrzip (active)' or (record.Kind=='Larplite' and record.Account and ('Larplite | '..record.Account) or record.Name)
            table.insert(values,{Title=title,Value=record.Name})
            if record.Name==detector.Selected then selected=record.Name end
        end
        selected=selected or (records[1] and records[1].Name)
        picker:Refresh(values);picker:Select(selected,true);preview(selected)
        summary:SetDesc((#records>0 and ('Found '..#records..' config file(s).') or 'No config files detected.')..(note and (' '..note) or ''))
    end
    tab:Button({Title='Rescan Configs',Desc='Refresh compatible and config-like JSON files in the workspace root.',Callback=refresh})
    refresh()
    return detector
end
