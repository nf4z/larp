-- Small release-manifest polling; script sources are fetched only for an update.
return function(ctx)
    local options=ctx.Settings
    if options.enabled==nil then options.enabled=true end
    local updater={Busy=false,Failures=0,RetryDelay=120}
    local tab=ctx.Tab
    tab:Section({Title="Updates"})
    local status=tab:Paragraph({Title="Script "..ctx.Version,Desc="Auto update checks every 2 minutes."})
    local function show(message) if ctx.Active() then status:SetDesc(message) end end
    local function compile(source,revision,version)
        assert(type(source)=="string","Empty release response")
        local gotRevision,gotVersion=source:match('Revision = (%d+), ScriptVersion = "(v%d+)"')
        assert(tonumber(gotRevision)==revision and gotVersion==version,"Release metadata does not match its script")
        local chunk,reason=ctx.Compile(source,"@bgsiscript-"..version)
        assert(type(chunk)=="function",tostring(reason or "Release did not compile"))
        return chunk
    end
    function updater:Check(manual)
        if self.Busy or not ctx.Active() then return false,"busy" end
        self.Busy=true
        local ok,result=pcall(function()
            show("Checking for updates...")
            local release=ctx.Manifest()
            assert(type(release)=="table" and release.schema==1,"Invalid update manifest")
            assert(type(release.revision)=="number" and release.revision%1==0 and type(release.version)=="string","Invalid release version")
            assert(release.version:match('^v%d+$') and release.path=="releases/bgsiscript/"..release.version.."-r"..release.revision..".lua","Invalid release path")
            if release.revision<=ctx.Revision then show("Up to date: "..ctx.Version);return "current" end
            if not manual and not options.enabled then return "disabled" end
            if not ctx.CanApply(release.revision,manual) then show("The last update failed. Retrying later; manual checks are available.");return "cooldown" end
            if ctx.Busy and ctx.Busy() then show("Update ready; waiting for pending hatch notifications.");return "pending" end
            show("Downloading "..release.version.."...")
            local chunk=compile(ctx.Fetch(release.path),release.revision,release.version)
            -- Stage a known working rollback before allowing the current hub to unload.
            local rollback=compile(ctx.Fetch(ctx.CurrentPath),ctx.Revision,ctx.Version)
            if not ctx.Active() or (not manual and not options.enabled) then return "cancelled" end
            if ctx.Busy and ctx.Busy() then show("Update ready; waiting for pending hatch notifications.");return "pending" end
            ctx.Save()
            if not ctx.Queue(chunk,rollback,release.revision) then return "cancelled" end
            show("Updating to "..release.version.."...")
            return "queued"
        end)
        self.Busy=false
        if ok then
            self.Failures=0;self.RetryDelay=result=="pending" and 5 or (result=="cooldown" and 600 or 120)
            return true,result
        end
        self.Failures+=1;self.RetryDelay=math.min(900,120*2^math.min(self.Failures-1,3))
        show("Update check failed; current script kept running. "..tostring(result))
        return false,result
    end
    tab:Toggle({Title="Auto Update",Desc="Checks for new releases and reloads with your saved config.",Value=options.enabled,
        Callback=function(value)
            options.enabled=value;ctx.Save()
            show(value and "Auto update enabled. Checking for a release..." or "Auto update disabled.")
            if value then task.spawn(function() updater:Check(false) end) end
        end})
    tab:Button({Title="Check For Updates",Desc="Checks now, even when automatic updates are off.",Callback=function() updater:Check(true) end})
    task.spawn(function()
        task.wait(10)
        while ctx.Active() do
            if options.enabled then updater:Check(false) end
            task.wait(options.enabled and updater.RetryDelay or 5)
        end
    end)
    return updater
end
