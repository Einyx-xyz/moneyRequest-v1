--#################################################################################################################--
--##  _____     _          ______                                          ______                           _    ##--
--## |_   _|   | |         | ___ \                                         | ___ \                         | |   ##--
--##   | |_   _| | ___ _ __| |_/ / ___     _ __ ___   ___  _ __   ___ _   _| |_/ /___  __ _ _   _  ___  ___| |_  ##--
--##   | | | | | |/ _ \  __| ___ \/ __|   |  _   _ \ / _ \|  _ \ / _ \ | | |    // _ \/ _  | | | |/ _ \/ __| __| ##--
--##   | | |_| | |  __/ |  | |_/ /\__ \   | | | | | | (_) | | | |  __/ |_| | |\ \  __/ (_| | |_| |  __/\__ \ |_  ##--
--##   \_/\__, |_|\___|_|  \____/ |___/   |_| |_| |_|\___/|_| |_|\___|\__, \_| \_\___|\__, |\__,_|\___||___/\__| ##--
--##       __/ |                                                       __/ |             | |                     ##--
--##      |___/                                                       |___/              |_|                     ##--
--#################################################################################################################--

if SERVER then
    AddCSLuaFile()
else
    --CLIENT--
    local BoxOpen = false
    local Blocked = {}

    function handleMoneyRequest( ply, amount, timeout, title, id )
        if not IsValid( ply ) then return end
        if not ply:IsPlayer() then return end
        if not amount or amount == 0 then return end
        if BoxOpen then return end
        surface.PlaySound( "plats/elevbell1.wav" )
        BoxOpen = true
        
        // FRAME
        local w = vgui.Create( "XeninUI.Frame" )
        w.Start = CurTime()
        w.Length = timeout
        w.LastSeconds = 0
        w.Timeout = timeout > 0 and true or false
        w:SetTitle( title and title or "Money Request" )
        
        w.Think = function()
            if w.Timeout then
                w.Seconds = math.Round( w.Length - ( CurTime() - w.Start ) )
                secondstring = ( w.Seconds != 1 and w.Seconds .. " seconds left." or w.Seconds .. " second left." )
                if w.Seconds != w.LastSeconds then surface.PlaySound( "garrysmod/ui_hover.wav" ) end
                
                w:SetTitle( title and title .. " - " .. secondstring or "Money Request - " .. secondstring )        
                w.LastSeconds = w.Seconds
                
                if w.Seconds <= 0 then
                    w:Remove()
                    RunConsoleCommand( "rp_timeout", id )
                    BoxOpen = false
                end
            end
        end
        
        w:SetSize( 332, 250 )
        w:Center()
        w:ShowCloseButton( false )
        w:MakePopup()

        // AVATAR 
        local a = vgui.Create( "XeninUI.Avatar", w )
        a:SetPos( 111, 48 )
        a:SetSize( 110, 110 )
        a:SetPlayer( ply, 128 )
        a:SetVertices( 128 )

        // YES BUTTON
        local y = vgui.Create( "XeninUI.ButtonV2", w )
        y:SetStartColor( Color( 0, 210, 0 ) )
        y:SetEndColor( Color( 0, 255, 0 ) )
        y:SetGradient( true )
        y:SetPos( 5, 165 )
        y:SetSize( 156, 50 )
        y:SetText( "Accept" )
        y.DoClick = function()
            if !y:GetDisabled() then
                RunConsoleCommand( "rp_acceptmoney", id )
                BoxOpen = false
                w:Remove()
            end
        end
        
        // NO BUTTON
        local n = vgui.Create( "XeninUI.ButtonV2", w )
        n:SetStartColor( Color( 210, 0, 0 ) )
        n:SetEndColor( Color( 255, 0, 0 ) )
        n:SetGradient( true )

        n:SetPos( 171, 165 )

        n:SetSize( 156, 50 )
        n:SetText( "Deny" )
        n.DoClick = function()
            if y:GetDisabled() then
                Blocked[ply:SteamID()] = true
            end
            RunConsoleCommand( "rp_denymoney", id ) 
            BoxOpen = false
            w:Remove()
        end    

        // CHECKBOX
        local c = vgui.Create( "XeninUI.CheckboxV2", w )
        c:SetPos( 5, 220 )
        c.State = false
        c.Text = "Block Money Requests from this Player?"
        c:SetSize( 350, 25 )
        c.OnStateChanged = function( self, value )
            if value then
                y:SetDisabled( true )
            else
                y:SetDisabled( false )
            end
        end
        
        y:SetCooltip( ply:Name() .. "'s E2 is asking you for $" .. amount .. ". Would you like to accept?", .1, 0, 0 )
        n:SetCooltip( ply:Name() .. "'s E2 is asking you for $" .. amount .. ". Would you like to deny?", .1, 0, 0 )
    end

    net.Receive( "moneyRequest", function()
        local ply = net.ReadEntity()
        local amount = net.ReadFloat()
        local timeout = net.ReadFloat()
        local title = net.ReadString()
        local id = net.ReadFloat()
        print( id )
         
         
        if Blocked[ ply:SteamID() ] then
            return 
        end
        handleMoneyRequest( ply, amount, timeout, title, id )
    end)

    concommand.Add( "rp_blockmoney_add", function( ply, com, args )
        Blocked[ table.concat( args, "", 1, 5 ) ] = true
        print( "Added " .. table.concat( args, "", 1, 5 ) )
    end, function()
		local ret = {}
		
		for k, v in pairs( player.GetAll() ) do 
			table.insert( ret, "rp_blockmoney_add " .. v:SteamID() .. " (" .. v:Name() .. ")")
		end
		
		return ret
	end)

    concommand.Add( "rp_blockmoney_remove", function( ply, com, args )
        Blocked[ table.concat( args, "", 1, 5 ) ] = false  
        print( "Removed " .. table.concat( args, "", 1, 5 ) )
    end, function()
		local ret = {}
		
		for k, v in pairs( player.GetAll() ) do 
			table.insert( ret, "rp_blockmoney_remove " .. v:SteamID() .. " (" .. v:Name() .. ")" ) 
		end
		
		return ret
	end)
end