print("War Mods Loaded!")

local WarframeMods = {}

WarframeMods["damage"] = {
	Name = "Damage Boost",
	Type = "DamageMul",
	Logo = "hud/leaderboard_class_demo",
	Desc = "Increases damage output by _%",
	RankValue = {30,40,50,60,70,80,90,100,110,120},
	BaseCapacity = 5,
	CostPower = 1.25,
}

WarframeMods["health"] = {
	Name = "Health Boost",
	Type = "HealthMul",
	Logo = "hud/leaderboard_class_medic",
	Desc = "Increases damage resistance by _%",
	RankValue = {40,45,50,55,60,65,60,65,70,75},
	BaseCapacity = 5,
	CostPower = 1.25,
}

WarframeMods["speed"] = {
	Name = "Speed Boost",
	Type = "SpeedMul",
	Logo = "hud/leaderboard_class_soldier_sergeant_crits",
	Desc = "Increases speed by %_",
	RankValue = {5,10,15,20,25,30,35,40,45,50},
	BaseCapacity = 5,
	CostPower = 1.25,
}

local NewPlayerMods = {"damage","health","speed"}

local DefaultDataString = "0 0 0 0 0 0 0 0 0 0"
local DefaultDataTable = string.Explode(" ",DefaultDataString)


if SERVER then

	local Folder = "warmods"

	function WarDataConvertSteamID(ply)
		return string.Replace(ply:SteamID(),":","_")
	end
	
	function WarDataCheckFolder(dir)
		if not file.Exists(dir,"DATA") then
			file.CreateDir(dir)
			return false
		end
		return true
	end
	
	function WarDataCheckFile(dir,data)
		if not file.Exists(dir,"DATA") then
			WarDataWrite(dir,data)
			return false
		end
		return true
	end
	
	function WarDataGetFullModDir(ply,mod)
		return Folder .. "/" .. WarDataConvertSteamID(ply) .. "/" .. mod .. ".txt"
	end
	
	function WarDataCheckFolderForServer()
		return WarDataCheckFolder(Folder)
	end
	
	function WarDataCheckFolderForPlayer(ply)
		return WarDataCheckFolder(Folder .. "/" .. WarDataConvertSteamID(ply))
	end
	
	function WarDataCheckFileForPlayer(ply,mod,data)
		return WarDataCheckFile(WarDataGetFullModDir(ply,mod),data)
	end
	
	function WarDataPlayerInitalize(ply)
	
		if not WarDataCheckFolderForServer() then
			--print("Setting up War Mods for the first time...")
		end
		
		if not WarDataCheckFolderForPlayer(ply) then
		
			--print("Setting Up War Mods for " .. ply:Nick() .. " for the first time...")
			
			for num,mod in pairs(NewPlayerMods) do
				WarDataGiveMod(ply,mod,1,1)
			end

		end

	end
	
	util.AddNetworkString( "WarDataSendToClient" )
	util.AddNetworkString( "WarNetSendTransmute" )
	
	hook.Add("PlayerSpawn","War Data Player Initialize",WarDataPlayerInitalize)
	
	function WarDataGiveMod(ply,mod,rank,count) --gives rank count mod to ply, meal
	
		--print("Giving " .. count .. " rank " .. rank .. " " .. mod.. " mod(s) to " .. ply:Nick() .. "...")

		local Add = DefaultDataTable
		
		--print("RANK:",rank)
		
		Add[rank] = Add[rank] + count

		if WarDataCheckFileForPlayer(ply,mod,WarDataImplode(Add)) then
			WarDataAdd(ply,mod,rank,count)
		end
		
	end
	
	function WarDataConsole(ply,cmd,args)
		if cmd == "war_menu" then
		
			net.Start("WarDataSendToClient")
			
				local TotalData = {}
			
				for k,v in pairs(WarframeMods) do
					local Data = WarDataGetModCountAll(ply,k)
					
					if Data then
						TotalData[k] = Data
					end
					
				end
				
				net.WriteTable(TotalData)
			
			net.Send(ply)
			
		elseif cmd == "war_givemod" and ply:IsSuperAdmin() then
			WarDataGiveMod(ply,args[1],tonumber(args[2]),tonumber(args[3]))
		elseif cmd == "war_start" and ply:IsSuperAdmin() then
			WarDataPlayerInitalize(ply)
		end
	end
	
	concommand.Add("war_start",WarDataConsole)
	concommand.Add("war_givemod",WarDataConsole)
	concommand.Add("war_menu",WarDataConsole)
	
	function WarDataGetModCountAll(ply,mod) -- gets the amount of mods as a table, meal
		local Data = WarDataExplode(WarDataRead(WarDataGetFullModDir(ply,mod,rank),"DATA"))
		return Data
	end
	
	function WarDataGetModCountSingle(ply,mod,rank) -- gets the amount of mods of this rank, meal
		local Data = WarDataExplode(WarDataRead(WarDataGetFullModDir(ply,mod,rank),"DATA"))
		return tonumber(Data[rank])
	end
	
	function WarDataAdd(ply,mod,rank,count) -- adds 1 to an existing mod file, ingredient
		local Data = WarDataGetModCountAll(ply,mod,rank)
		Data[rank] = Data[rank] + count
		WarDataWrite(WarDataGetFullModDir(ply,mod,rank),WarDataImplode(Data))
	end
	
	function WarDataTransmute(ply,mod,rank,count)

		local CurrentModCount = WarDataGetModCountSingle(ply,mod,rank)
		
		if CurrentModCount >= count*3 and rank < 10 then
			WarDataAdd(ply,mod,rank,-3*count)
			WarDataAdd(ply,mod,rank+1,count)
			ply:ChatPrint("Transmute successful")
		end
	
	end
	
	
	function WarDataImplode(data)
		if not data then return nil end
		data = string.Implode(" ",data) -- turns data into string, ingredient
		return data
	end
	
	function WarDataExplode(data)
		if not data then return nil end
		data = string.Explode(" ",data) -- turns data into table, ingredient
		return data
	end
	
	function WarDataWrite(dir,data)
		if not (dir and data) then return nil end
		--print("Writing " .. data .. " to " .. dir)
		file.Write(dir,data)
	end
	
	function WarDataRead(dir)
		if not dir then return nil end
		local Data = file.Read(dir,"DATA")
		--print("Reading " .. Data .. " from " .. dir)
		return Data
	end
	
	function WarDropMod(ply,pos)
		if not (ply and pos) then return end
		local Object = ents.Create("ent_war_mod")
		Object:SetPos( pos + Vector(0,0,10) )
		Object:SetAngles(AngleRand())
		Object.Target = ply
		Object:Spawn()
		Object:GetPhysicsObject():SetVelocity(Vector(math.random(-100,100),math.random(-100,100),500))
		SafeRemoveEntityDelayed(Object,60)
	end
	
	function WarGetAllModClasses()
	
		local Table = {}
	
		for k,v in pairs(WarframeMods) do
			table.Add(Table,{k})
		end
	
		return Table
	end
	
	function WarGiveRandomMod(ply)
		local AllMods = WarGetAllModClasses()
		local SelectedModType = AllMods[math.random(1,#AllMods)]
		local Rank = WarGetRandRank()
		--print("RANK FAGGOT",Rank)
		WarDataGiveMod(ply,SelectedModType,Rank,1)
	end
	
	function WarChancePower(power)
		return math.Rand(1,100) >= (100 / (2^power))
	end
	
	function WarGetRandRank()
	
		local SelectedRank = 1
		
		for i=1,9 do
			if WarChancePower(i) then
				SelectedRank = i + math.random(0,1)
				--print("SelectedRank: ",SelectedRank)
				return SelectedRank
			end
		end

		return SelectedRank
		
	end
	
	function WarGetRandRankDebug()
		for i=1,100 do
			WarGetRandRank()
		end
	end
	
	--WarGetRandRankDebug()
	
	function WarPlayerDeath(victim,weapon,attacker)
		if attacker:IsPlayer() and !attacker:IsBot() and attacker ~= victim then
			WarDropMod(attacker,victim:GetPos())
		end
	end
	
	hook.Add("PlayerDeath","War Player Death",WarPlayerDeath)
	
	
	net.Receive("WarNetSendTransmute",function(len,ply)
	
		local mod = net.ReadString()
		local rank = net.ReadFloat()
		local count = net.ReadFloat()
	
		WarDataTransmute(ply,mod,rank,count)
	
	end)
	
	
	
	

end


if CLIENT then

	surface.CreateFont( "WarFontTitle", {
		font = "Coolvetica", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		size = 32,
		weight = 100,
		antialias = true,
	} )
	
	surface.CreateFont( "WarFontCount", {
		font = "Coolvetica", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		size = 16,
		weight = 200,
		antialias = true,
	} )

	surface.CreateFont( "WarFontDesc", {
		font = "Coolvetica", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		size = 26,
		weight = 100,
		antialias = true,
	} )
	

	local Frame = {}
	local Title = {}
	local CountBase = {}
	local TransmuteOptions = {}
	local TitleBase = {}
	local ShinyBase = {}
	local DescBase = {}
	local Desc = {}
	local Image = {}

	net.Receive("WarDataSendToClient", function(len)
	
		local Data = net.ReadTable()
		
		--PrintTable(Data)
		
		local x = 800
		local y = 600
		
		local Small = x*0.01
	
		local BaseFrame = vgui.Create( "DFrame" ) //Create a Frame to contain everything.
		BaseFrame:SetTitle( "DIconLayout Example" )
		BaseFrame:SetSize( x,y )
		BaseFrame:Center()
		BaseFrame:MakePopup()

		local Scroll = vgui.Create( "DScrollPanel", BaseFrame ) //Create the Scroll panel
		Scroll:SetPos( Small, 20 + Small )
		Scroll:SetSize( x - Small*2, y - 40 )
		
		local List	= vgui.Create( "DIconLayout", Scroll )
		List:SetPos( 0, 0 )
		List:SetSize( x, y )
		List:SetSpaceX( Small )
		List:SetSpaceY( Small )

		for mod,array in pairs(Data) do
			for rank,count in pairs(array) do
				WarCreateCard(x,y,List,mod,rank,count)
			end
		end
				
		
	end)
	
	function WarCreateCard(x,y,List,mod,rank,count)
	
		local OfficialData = WarframeMods[mod]
					
		local BaseX = x*0.3
		local BaseY = BaseX*1.5
		local Small = x*0.01

		Count = mod .. rank

		if tonumber(count) > 0 then
		
			Frame[Count] = List:Add("DPanel")
			Frame[Count]:SetSize(BaseX,BaseY)

			CountBase[Count] = vgui.Create("DButton",Frame[Count])
			CountBase[Count]:SetPos(BaseX - BaseY*0.1 + Small,0)
			CountBase[Count]:SetSize(BaseY*0.1 - Small,BaseY*0.1 - Small)
			CountBase[Count]:SetText(count)
			CountBase[Count]:SetFont("WarFontCount")
			
			CountBase[Count].DoClick = function() 
				TransmuteOptions[Count] = vgui.Create("DMenu")
				TransmuteOptions[Count]:AddOption("Transmute X3", function()
					WarSendTransmute(x,y,List,mod,rank,1)
				end)
				TransmuteOptions[Count]:AddOption("Transmute X15", function()
					WarSendTransmute(x,y,List,mod,rank,5)
				end)
				TransmuteOptions[Count]:AddOption("Transmute X30", function()
					WarSendTransmute(x,y,List,mod,rank,10)
				end)
				
				TransmuteOptions[Count]:Open()
			end
			
			local ImgSize = math.floor(BaseX*0.25)
			
			Image[Count] = vgui.Create("DImage",Frame[Count])
			Image[Count]:SetPos(BaseX*0.5 - ImgSize/2,BaseY*0.25 - ImgSize/2)
			Image[Count]:SetSize(ImgSize,ImgSize)
			Image[Count]:SetImage( OfficialData.Logo )
			

			TitleBase[Count] = vgui.Create("DPanel",Frame[Count])
			TitleBase[Count]:SetPos(Small,BaseY*0.5 - Small)
			TitleBase[Count]:SetSize(BaseX - Small*2,BaseY*0.15 - Small*2)
			
			Title[Count] = vgui.Create("DLabel",TitleBase[Count])
			Title[Count]:SetText(OfficialData.Name)
			Title[Count]:SetDark(true)
			Title[Count]:SetFont("WarFontTitle")
			Title[Count]:SizeToContents(true)
			Title[Count]:Center()

			DescBase[Count] = vgui.Create("DPanel",Frame[Count])
			DescBase[Count]:SetPos(Small,BaseY*0.6 - Small*0.5)
			DescBase[Count]:SetSize(BaseX - Small*2,BaseY*0.35 - Small*2)
			
			
			local ValueThing = tostring(OfficialData.RankValue[rank])
			
			Desc[Count] = vgui.Create("DLabel",DescBase[Count])
			Desc[Count]:SetText( string.Replace(OfficialData.Desc,"_",ValueThing) )
			Desc[Count]:SetSize(BaseX - Small*4,BaseY*0.35 - Small*4)
			Desc[Count]:SetPos(Small,Small)
			Desc[Count]:SetDark(true)
			Desc[Count]:SetFont("WarFontDesc")
			Desc[Count]:SetAutoStretchVertical(true)
			Desc[Count]:SetWrap(true)
			--Desc[Count]:Center()
			
			ShinyBase[Count] = vgui.Create("DPanel",Frame[Count])
			ShinyBase[Count]:SetPos(Small, BaseY - BaseX*0.1 - Small )
			ShinyBase[Count]:SetSize(BaseX - Small*2,BaseX*0.1)
			
			for i=1,10 do
				if i <= rank then
					local Shiny = vgui.Create("DImage",ShinyBase[Count])
					Shiny:SetPos( (i-1)*(BaseX-Small*2)*0.1, 0 )
					Shiny:SetSize((BaseX-Small*2)*0.1,(BaseX-Small*2)*0.1)
					Shiny:SetImage("vgui/importtool_goldstar")
				end
			end
			
		end

	end
	
	
	function WarSendTransmute(x,y,List,mod,rank,count)
	
		local CurrentCount = tonumber( CountBase[mod .. rank]:GetText())
	
		if CurrentCount >= count*3 and rank < 10 then
	
			CountBase[mod .. rank]:SetText( CurrentCount - count*3)
			
			if not CountBase[mod .. rank+1] then
				WarCreateCard(x,y,List,mod,rank+1,count)
			else
				CountBase[mod .. rank+1]:SetText( tonumber( CountBase[mod .. rank+1]:GetText()) + count)
			end

			local ply = LocalPlayer()
			
			net.Start("WarNetSendTransmute")
				net.WriteString(mod)
				net.WriteFloat(rank)
				net.WriteFloat(count)
			net.SendToServer()
		
		end
	
	end
	
	
	

end

