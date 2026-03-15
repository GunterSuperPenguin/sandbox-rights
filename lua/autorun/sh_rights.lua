CreateConVar( "sv_rights_active","0", FCVAR_REPLICATED )
CreateConVar( "sv_ban_spawn","0" )
CreateConVar( "sv_ban_toolgun","0" )
CreateConVar( "sv_ban_physgun","0" )
CreateConVar( "sv_ban_gravgun","0" )
CreateConVar( "sv_ban_spawnweapon","0")
CreateConVar( "sv_ban_pickup","0" )
CreateConVar( "sv_ban_break", "0" )
CreateConVar( "sv_ban_noclip", "0" )
CreateConVar( "sv_ban_cmenu","0", FCVAR_REPLICATED )
CreateConVar( "sv_rights_superadmins","1", FCVAR_REPLICATED )
CreateConVar( "sv_rights_admins","0",FCVAR_REPLICATED )
CreateConVar( "sv_rights_operators","0",FCVAR_REPLICATED )

local whitelist = {}

local function GetBan( ban )
  return GetConVar( ban ):GetBool()
end

local function FindBySteamID( id )
  for k,v in ipairs( player.GetAll() ) do
    if v:SteamID() == id then
      return v
    end
  end
  return false
end

local function CheckRights( ply )
  if !GetBan( "sv_rights_active" ) then return true end
  if ply:IsListenServerHost() then return true end
  if ply:IsSuperAdmin() and GetBan( "sv_rights_superadmins" ) then return true end
  if ply:IsAdmin() and GetBan( "sv_rights_admins" ) then return true end
  if ply:GetUserGroup() == "operator" and GetBan( "sv_rights_operators" ) then return true end
  if table.HasValue( whitelist, ply:SteamID() ) then return true end
  return false
end

hook.Add( "InitPostEntity", "Get file settings", function()
	if file.Exists( "rights_settings.txt", "DATA" ) then
		local tbl = util.JSONToTable(file.Read( "rights_settings.txt", "DATA" ))
		for k,v in pairs( tbl ) do
			pcall( function() GetConVar(k):SetBool(v) end )
		end
	end
	if file.Exists( "rights_whitelist.txt", "DATA" ) and util.JSONToTable( file.Read("rights_whitelist.txt", "DATA") ) ~= {} then
		whitelist = util.JSONToTable(file.Read( "rights_whitelist.txt", "DATA" ))
	end
end )

hook.Add( "ShutDown", "Save rights data", function()
    local tbl = {}
    tbl[ "sv_rights_active" ] = GetConVar( "sv_rights_active" ):GetBool()
	tbl[ "sv_ban_spawn" ] = GetConVar( "sv_ban_spawn" ):GetBool()
	tbl[ "sv_ban_toolgun" ] = GetConVar( "sv_ban_toolgun" ):GetBool()
	tbl[ "sv_ban_physgun" ] = GetConVar( "sv_ban_physgun" ):GetBool()
	tbl[ "sv_ban_gravgun" ] = GetConVar( "sv_ban_gravgun" ):GetBool()
	tbl[ "sv_ban_spawnweapon" ] = GetConVar( "sv_ban_spawnweapon" ):GetBool()
	tbl[ "sv_ban_pickup" ] = GetConVar( "sv_ban_pickup" ):GetBool()
	tbl[ "sv_ban_cmenu" ] = GetConVar( "sv_ban_cmenu" ):GetBool()
	tbl[ "sv_rights_superadmins" ] = GetConVar( "sv_rights_superadmins" ):GetBool()
	tbl[ "sv_rights_admins" ] = GetConVar( "sv_rights_admins" ):GetBool()
	tbl[ "sv_rights_operators" ] = GetConVar( "sv_rights_operators" ):GetBool()
	file.Write( "rights_settings.txt", util.TableToJSON( tbl ) )
	file.Write( "rights_whitelist.txt", util.TableToJSON( whitelist ) )
end )

if SERVER then
	util.AddNetworkString( "Update cl whitelist" )
	util.AddNetworkString( "Ask update cl whitelist" )
	util.AddNetworkString( "Delete from whitelist" )
	util.AddNetworkString( "Add to whitelist" )

	net.Receive( "Delete from whitelist", function( len, ply )
		if !ply:IsListenServerHost() then return end
		local id = net.ReadString()
		table.RemoveByValue( whitelist,id )
		net.Start( "Update cl whitelist" )
		net.WriteTable( whitelist, true )
		net.Broadcast()
	end )

	net.Receive( "Add to whitelist", function( len, ply )
		if !ply:IsListenServerHost() then return end
		local id = net.ReadString()
		whitelist[#whitelist + 1] = id
		net.Start( "Update cl whitelist" )
		net.WriteTable( whitelist, true )
		net.Broadcast()
	end )

	net.Receive( "Ask update cl whitelist", function( len, ply )
		if !ply:IsListenServerHost() then return end
		net.Start( "Update cl whitelist" )
		net.WriteTable( whitelist, true )
		net.Broadcast()
	end )

	hook.Add( "EntityTakeDamage", "BanBreak", function( target, dmginfo )
		if not GetBan( "sv_ban_break" ) then return end
		if not dmginfo then return end
		local attacker = dmginfo:GetAttacker()
		local inflictor = dmginfo:GetInflictor()
		local attackerPlayer

		if IsValid( attacker ) and attacker:IsPlayer() then
			attackerPlayer = attacker
		elseif IsValid( inflictor ) and inflictor:IsPlayer() then
			attackerPlayer = inflictor
		end
		if not attackerPlayer then return end
		if not CheckRights( attackerPlayer ) then
			if not target:IsPlayer() then
				return true
			end
		end
	end )

	hook.Add( "PlayerSpawnEffect", "BanSpawnEffects", function( ply, _ )
		if GetBan( "sv_ban_spawn" ) then
			return CheckRights( ply )
		end
	end )

	hook.Add( "PlayerSpawnNPC", "BanSpawnNPC", function( ply, _, _ )
		if GetBan( "sv_ban_spawn" ) then
			return CheckRights( ply )
		end
	end )

	hook.Add( "PlayerSpawnObject", "BanSpawnObject", function( ply, _, _ )
		if GetBan( "sv_ban_spawn" ) then
			return CheckRights(ply)
		end
	end )

	hook.Add( "PlayerSpawnProp", "BanSpawnProp", function( ply, _ )
		if GetBan( "sv_ban_spawn" ) then
			return CheckRights(ply)
		end
	end )

	hook.Add( "PlayerSpawnRagdoll", "BanSpawnRagdoll", function( ply, _ )
		if GetBan( "sv_ban_spawn" ) then
			return CheckRights(ply)
		end
	end )

	hook.Add( "PlayerSpawnSENT", "BanSpawnSENT", function( ply, _ )
		if GetBan( "sv_ban_spawn" ) then
			return CheckRights( ply )
		end
	end )

	hook.Add( "PlayerGiveSWEP", "BanSpawnSWEP", function( ply, _, _ )
		if GetBan( "sv_ban_spawnweapon" ) then
			return CheckRights( ply )
		end
	end )

	hook.Add( "PlayerGiveSWEP", "BanGiveSWEP", function( ply, _, _ )
		if GetBan( "sv_ban_spawnweapon" ) then
			return CheckRights( ply )
		end
	end )

	hook.Add( "PlayerSpawnVehicle", "BanSpawnVehicle", function( ply, _, _ , _ )
		if GetBan( "sv_ban_spawn" ) then
			return CheckRights( ply )
		end
	end )

	hook.Add( "PhysgunPickup", "BanPhysGun", function( ply, _ )
		if GetBan( "sv_ban_physgun" ) then
			return CheckRights( ply )
		end
	end )

	hook.Add( "AllowPlayerPickup", "BanPickup", function( ply, _ )
		if GetBan( "sv_ban_pickup" ) then
			return CheckRights( ply )
		end
	end )

	hook.Add( "GravGunPickupAllowed", "BanGravGun", function( ply, _ )
		if GetBan( "sv_ban_gravgun" ) then
			return CheckRights( ply )
		end
	end )
end

hook.Add( "CanProperty", "BanCMenu", function( ply )
	if GetBan( "sv_ban_cmenu" ) then
		return CheckRights ( ply )
	end
end )

hook.Add( "CanTool", "BanToolGun", function( ply, _, _, _, _ )
	if GetBan( "sv_ban_toolgun" ) then
		return CheckRights( ply )
	end
end )

hook.Add( "PlayerNoClip", "BanNoClip", function( ply, desiredNoClipState )
	if !desiredNoClipState then
		return true
	end
	if GetBan( "sv_ban_noclip" ) then
		return CheckRights( ply )
	end
end)

cvars.AddChangeCallback("sv_ban_noclip", function(convar_name, value_old, value_new)
    if value_new == "1" then
		for k, v in player.Iterator() do
			if CheckRights( v ) then continue end
			v:SetMoveType(MOVETYPE_WALK)
		end
	end
end)

if CLIENT then
	local should_updade_list = false
	local wl = {}
	local function UpdateWhitelist()
		net.Start( "Ask update cl whitelist" )
		net.SendToServer()
	end
	hook.Add( "PopulateToolMenu", "Rights interface", function()
		spawnmenu.AddToolMenuOption( "Utilities", "Admin", "Rights", "#Rights", "", "", function( panel )
		local whitelist = whitelist
		net.Receive( "Update cl whitelist", function()
			whitelist = net.ReadTable( true )
		end )

		panel:ClearControls()
			panel:CheckBox( "#rights.checkbox.activate","sv_rights_active" )
			panel:Help( "#rights.help.bansnotwork" )
			panel:CheckBox( "superadmin","sv_rights_superadmins" )
			panel:CheckBox( "admin","sv_rights_admins")
			panel:CheckBox( "operator","sv_rights_operators" )
			panel:Help( "#rights.help.whitelisthelp" )
			local list = vgui.Create( "DListView" )
			list:SetMultiSelect( false )
			list:AddColumn( "#rights.coulmn.nickname" )
			list:AddColumn( "#rights.coulmn.steamid" )
			list:SetSize(400,300)
			for k,v in ipairs(list:GetLines()) do
				list:RemoveLine(k)
			end
			for k,v in ipairs( whitelist ) do
				if FindBySteamID( v ) then
					list:AddLine(FindBySteamID( v ):Nick(), v )
				else
					list:AddLine( "", v )
				end
			end
			list.OnRowRightClick = function( _, lineID )
				local line = list:GetLine( lineID )
				net.Start( "Delete from whitelist" )
				net.WriteString( line:GetValue(2) )
				net.SendToServer()
				list:ClearSelection()
				timer.Simple( 0.1, function()
					should_updade_list = true
					notification.AddLegacy( line:GetValue(2)..' was deleted from whitelist', 1, 4 )
					surface.PlaySound( "buttons/button15.wav" )
				end )
			end
			list.Think = function()
			if should_updade_list then
			should_updade_list = false
			for k,v in ipairs( list:GetLines() ) do
				list:RemoveLine( k )
			end
			for k,v in ipairs( whitelist ) do
				if FindBySteamID( v ) then
					list:AddLine( FindBySteamID(v):Nick(), v )
				else
					list:AddLine( "", v )
				end
			end
			wl = whitelist
			end
			end
			panel:AddItem( list )
			local but = vgui.Create( "DComboBox" )
			but:SetValue( "#rights.help.listhelp" )
			but:SetSize( 10, 30 )
			but:AddChoice( 'buf' )
			but.DoClick = function()
				but.Choices = {}
				but.Data = {}
				but.ChoisesIcons = {}
				but.Spacers = {}
				but.selected = nil
				for k,v in player.Iterator() do
					if !v:IsListenServerHost() then
						but:AddChoice( v:Nick(), v:SteamID() )
					end
				end
				if but:IsMenuOpen() then
					return but:CloseMenu()
				end
				but:OpenMenu()
			end
			but.OnSelect = function( _, val, data )
				if table.HasValue( whitelist, but.Data[ val ] ) or but.Data[ val ] == "BOT" then return end
				net.Start( "Add to whitelist" )
				net.WriteString( but.Data[ val ] )
				net.SendToServer()
				timer.Simple( 0.1, function()
					should_updade_list = true
					notification.AddLegacy( data..' was added to whitelist', 2, 4 )
					surface.PlaySound( "buttons/button15.wav" )
				end )
				but:SetValue( "#rights.help.listhelp" )
			end
			panel:AddItem( but )
			panel:Help( "#rights.help.ban" )
			panel:CheckBox( "#rights.checkbox.spawnmenu", "sv_ban_spawn" )
			panel:CheckBox( "#rights.checkbox.property", "sv_ban_cmenu" )
			panel:CheckBox( "#rights.checkbox.weapons", "sv_ban_spawnweapon" )
			panel:CheckBox( "#rights.checkbox.physgun", "sv_ban_physgun" )
			panel:CheckBox( "#rights.checkbox.gravitygun", "sv_ban_gravgun" )
			panel:CheckBox( "#rights.checkbox.toolgun", "sv_ban_toolgun" )
			panel:CheckBox( "#rights.checkbox.pickup", "sv_ban_pickup" )
			panel:CheckBox( "#rights.checkbox.break", "sv_ban_break" )
			panel:CheckBox( "#rights.checkbox.noclip", "sv_ban_noclip" )
		end )

		hook.Add( "OnSpawnMenuOpen", "Update list", function()
			UpdateWhitelist()
			timer.Simple(0.1, function()
				should_updade_list = true
			end )
		end )
	end )
end