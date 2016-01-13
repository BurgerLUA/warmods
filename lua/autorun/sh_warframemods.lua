print("War Mods Loaded!")

local WarframeMods = {}

local TransmuteCost = 2

WarframeMods["damage"] = {
	Name = "Overpacked Bullets",
	Type = "DamageMul",
	Logo = "hud/leaderboard_class_demo",
	Desc = "Increases damage output by _%",
	RankValue = {10,20,30,40,50,60,70,80,90,100},
	BaseCapacity = 5,
	CostPower = 1.25,
}

--[[
WarframeMods["health"] = {
	Name = "Skin Augmentation",
	Type = "HealthMul",
	Logo = "hud/leaderboard_class_medic",
	Desc = "Increases damage resistance by _%",
	RankValue = {5,10,15,20,25,30,35,40,45,50},
	BaseCapacity = 5,
	CostPower = 1.25,
}


WarframeMods["speed"] = {
	Name = "Adrenaline",
	Type = "SpeedMul",
	Logo = "hud/leaderboard_class_scout_giant_fast",
	Desc = "Increases speed by _%",
	RankValue = {5,10,15,20,25,30,35,40,45,50},
	BaseCapacity = 5,
	CostPower = 1.25,
}

--]]

WarframeMods["ammo"] = {
	Name = "Custom Magazine",
	Type = "ClipMul",
	Logo = "hud/leaderboard_class_heavy",
	Desc = "Increases clip size by _%",
	RankValue = {10,20,30,40,50,60,70,80,90,100},
	BaseCapacity = 5,
	CostPower = 1.25,
}

WarframeMods["accuracy"] = {
	Name = "Long Barrel",
	Type = "ClipMul",
	Logo = "hud/leaderboard_class_sniper",
	Desc = "Decreases spread by _%",
	RankValue = {7,14,21,28,35,42,49,56,63,70},
	BaseCapacity = 5,
	CostPower = 1.25,
}

WarframeMods["rate"] = {
	Name = "Barrage",
	Type = "ClipMul",
	Logo = "hud/leaderboard_class_soldier_barrage",
	Desc = "Increases fire rate by _%",
	RankValue = {5,10,15,20,25,30,35,40,45,50},
	BaseCapacity = 5,
	CostPower = 1.25,
}




local NewPlayerMods = {"damage","health"}

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
	util.AddNetworkString( "WarPickupCard" )
	util.AddNetworkString( "WarNetSendActivation")
	
	hook.Add("PlayerSpawn","War Data Player Initialize",WarDataPlayerInitalize)
	
	function WarDataGiveMod(ply,mod,rank,count) --gives rank count mod to ply, meal
	
		--print("Giving " .. count .. " rank " .. rank .. " " .. mod.. " mod(s) to " .. ply:Nick() .. "...")

		--print("PICKUP")
		
		net.Start("WarPickupCard")
			net.WriteString(mod)
			net.WriteFloat(rank)
			net.WriteFloat(count)
		net.Send(ply)
		
		local Add = DefaultDataTable
		
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
		
		if CurrentModCount >= count*TransmuteCost and rank < 10 then
			WarDataAdd(ply,mod,rank,-TransmuteCost*count)
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
		


		WarDataGiveMod(ply,SelectedModType,Rank,1)
		
	end
	

	
	
	function WarGetRandRank()
	
		local SelectedRank = 5
		
		local Rand = math.Rand(1,100)
		
		for i=1, 5 do
			if Rand > (50 / i) then
				return i
			end
		end

		return SelectedRank
		
	end
	
	function WarGetRandRankDebug()
		for i=1,100 do
			print(WarGetRandRank())
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
	
	net.Receive("WarNetSendActivation", function(len,ply)
	
		local mod = net.ReadString()
		local rank = net.ReadFloat()
		local RealData = WarframeMods[mod]
		local RealPower = RealData.RankValue[rank]
		
		WarDataAdd(ply,mod,rank,-1)
		
		ply:SetNWString("WarModClass",mod)
		ply:SetNWFloat("WarModRank",rank)
		ply:SetNWFloat("WarModPower",RealPower)
		ply:SetNWBool("WarModActivated",false)
		ply:SetNWFloat("WarModUses",3)
		
	end)
	
	function WarMod_PlayerSpawn(ply)
	
		if ply:GetNWString("WarModClass","none") ~= "none" then
			if ply:GetNWFloat("WarModUses",-1) <= 1 then
				ply:SetNWString("WarModClass","none")
				ply:SetNWBool("WarModActivated",false)
			else
				if not ply:GetNWBool("WarModActivated",false) then
					ply:SetNWBool("WarModActivated",true)
				else
					local Uses = ply:GetNWFloat("WarModUses",-1)
					ply:SetNWFloat("WarModUses", Uses - 1)
				end
			end
		end
	end
	
	hook.Add("PlayerSpawn","War Mods: Player Spawn",WarMod_PlayerSpawn)
	
	--[[
	function WarMod_ScalePlayerDamage(victim,hitgroup,dmginfo)
	
		local attacker = dmginfo:GetAttacker()
		
		if victim:IsPlayer() then
			if victim:GetNWString("WarModClass","none") == "health" and victim:GetNWBool("WarModActivated",false) then
				dmginfo:ScaleDamage( 1 - victim:GetNWFloat("WarModPower",0) * 0.01)
			end
		end
		
		if attacker:IsPlayer() then
			if attacker:GetNWString("WarModClass","none") == "damage" and attacker:GetNWBool("WarModActivated",false) then
				print("NICE MOD BRO")
				dmginfo:ScaleDamage( 1 + attacker:GetNWFloat("WarModPower",0) * 0.01)
			end
		end

	end
	
	hook.Add("ScalePlayerDamage","War Mods: Scale Damage",WarMod_ScalePlayerDamage)
	--]]
	
	

	
	
	
	--[[
	WarframeMods["ammo"] = {
		Name = "Custom Magazine",
		Type = "ClipMul",
		Logo = "hud/leaderboard_class_heavy",
		Desc = "Increases clip size by _%",
		RankValue = {20,30,40,50,60,70,80,90,100,110},
		BaseCapacity = 5,
		CostPower = 1.25,
	}
	--]]
	

end

function WarMod_SharedThink()

	if SERVER and not game.SinglePlayer() then
		for k,v in pairs(player.GetAll()) do
			WarMod_TweakWeapon(v)
		end
	end
	
	if CLIENT or game.SinglePlayer() then
		WarMod_TweakWeapon(LocalPlayer())
	end

end

hook.Add("Think","WarMod: SharedThink",WarMod_SharedThink)

function WarMod_TweakWeapon(ply)

	local Weapon = ply:GetActiveWeapon()

	if IsValid(Weapon) and Weapon:IsScripted() then
		
		if not Weapon.HasBeenTouchedByWarmods then
	
			local IsActivated = ply:GetNWBool("WarModActivated",false)
			local ModType = ply:GetNWString("WarModClass","none")
			local ModPower = ply:GetNWFloat("WarModPower",0)
		
			local GlobalMod = (1 + (ModPower/100))
		
			--print("ASSHOLE???")
		
			--print("WHO")
		
			if IsActivated then
			
				if ModType == "damage" then
					if Weapon.Primary then
						if Weapon.Primary.Damage then
							Weapon.Primary.Damage = math.floor(Weapon.Primary.Damage * GlobalMod)
						end
						if Weapon.RecoilMul then
							Weapon.RecoilMul = Weapon.RecoilMul / GlobalMod
						end
						if Weapon.HeatMul then
							Weapon.HeatMul = Weapon.HeatMul / GlobalMod
						end
					end
				elseif ModType == "ammo" then
					if Weapon.Primary then
						if Weapon.Primary.ClipSize then
							Weapon.Primary.ClipSize = math.Clamp(math.floor(Weapon.Primary.ClipSize * GlobalMod),-1,200)
						end
					end
				elseif ModType == "accuracy" then
					if Weapon.Primary then
						if Weapon.Primary.Cone then
							Weapon.Primary.Cone = Weapon.Primary.Cone / GlobalMod
						end
					end
				elseif ModType == "rate" then
					if Weapon.Primary then
						if Weapon.Primary.Delay then
							Weapon.Primary.Delay = Weapon.Primary.Delay / GlobalMod
						end
					end				
				end
				
			end

			Weapon.HasBeenTouchedByWarmods = true

		end

	end
	
end




if CLIENT then

	local Frame = {}
	local Title = {}
	local CountBase = {}
	local TransmuteOptions = {}
	local TitleBase = {}
	local ShinyBase = {}
	local DescBase = {}
	local DescBase = {}
	local Desc = {}
	local Image = {}
	
	local Theme = Color(255,255,255,255)
	local Corner = 8
	
	local xsize = 800
	local ysize = 600
	
	
	if WarPickupCardList then 
		WarPickupCardList:Remove()
		WarPickupCardList = nil
	end
	
	if WarActivatedCardList then
		WarActivatedCardList:Remove()
		WarActivatedCardList = nil
	end
	
	if WarActivatedCard then
		WarActivatedCard:Remove()
		WarActivatedCard = nil
	end
	
	net.Receive("WarPickupCard", function()

		local mod = net.ReadString()
		local rank = net.ReadFloat()
		local count = net.ReadFloat()
		local Card = WarCreateCard(xsize,ysize,WarPickupCardList,mod,rank,count)
		
		timer.Simple(5,function() Card:Remove() end)
		
	end)
	
	local CurrentCardMod = nil
	local First = false
	
	function War_Think()
	
		local ply = LocalPlayer()
		
		if not First then 
	
			WarPickupCardList = vgui.Create( "DIconLayout", Scroll )
			WarPickupCardList:SetPos( ScrW()*0.9 - xsize*0.1, ScrH()*0.9 - ysize*0.75 )
			WarPickupCardList:SetSize( ScrW()*0.1 + xsize*0.1,ScrH()*0.1 + ysize*0.1 )
			WarPickupCardList:SetSpaceX( ScrW()*0.01 )
			WarPickupCardList:SetSpaceY( ScrW()*0.01 )
			
			WarActivatedCardList = vgui.Create( "DIconLayout", Scroll )
			WarActivatedCardList:SetPos( ScrW()*0.01, ScrH()*0.01 )
			WarActivatedCardList:SetSize( ScrW()*0.9 - xsize*0.1,ScrH()*0.9 - ysize*0.1 )
			WarActivatedCardList:SetSpaceX( ScrW()*0.01 )
			WarActivatedCardList:SetSpaceY( ScrW()*0.01 )
	
			First = true
		
		end
	
		local mod = ply:GetNWString("WarModClass","none")
		local rank = ply:GetNWFloat("WarModRank",0)
		local count = ply:GetNWFloat("WarModUses",0)
		
		local Activated = ply:GetNWBool("WarModActivated",false)

		local Benchmark = mod .. "_" .. rank .. "_" .. count
		
		--print(CurrentCardMod,Benchmark)
		
		
		if not CurrentCardMod or (CurrentCardMod and CurrentCardMod ~= Benchmark) then
			
			if WarActivatedCard then
				WarActivatedCard:Remove()
				WarActivatedCard = nil
			end
			
			CurrentCardMod = Benchmark
		end
		
		if mod ~= "none" and rank ~= 0 and count ~= 0 and Activated then
			if not WarActivatedCard then
				WarActivatedCard = WarCreateCard(xsize,ysize,WarActivatedCardList,mod,rank,count)
				timer.Simple(10,function() WarActivatedCard:Remove() end)
			end
		end
		

	end
	
	hook.Add("Think","WarMod: Think",War_Think)
	

	function TranslateTheme(Mul)
		return Color(Theme.r*Mul,Theme.g*Mul,Theme.b*Mul,Theme.a)
	end

	net.Receive("WarDataSendToClient", function(len)
	
		local Data = net.ReadTable()
		
		--PrintTable(Data)
		
		local x = 800
		local y = 600
		
		local Small = x*0.01
	
		local BaseFrame = vgui.Create( "DFrame" ) //Create a Frame to contain everything.
		BaseFrame:SetTitle( "DIconLayout Example" )
		BaseFrame:SetSize( x - Small*3,y )
		BaseFrame:Center()
		BaseFrame:MakePopup()
		
		function BaseFrame:Paint(w,h)
			draw.RoundedBox( Corner, 0, 0, w, h, TranslateTheme(0.1) )
		end
	
		local Scroll = vgui.Create( "DScrollPanel", BaseFrame ) //Create the Scroll panel
		Scroll:SetPos( Small, 20 + Small )
		Scroll:SetSize( x - Small*5, y - 40 )
		
		local Scrollbar = Scroll:GetVBar()
		
		function Scrollbar:Paint( w, h )
			draw.RoundedBox( Corner, 0, 0, Small*2, h, TranslateTheme(0.25) )
		end
		
		function Scrollbar.btnUp:Paint( w, h )
			draw.RoundedBox( Corner, 0, 0, Small*2, h, TranslateTheme(0.5) )
		end
		
		function Scrollbar.btnDown:Paint( w, h )
			draw.RoundedBox( Corner, 0, 0, Small*2, h, TranslateTheme(0.5) )
		end
		
		function Scrollbar.btnGrip:Paint( w, h )
			draw.RoundedBox( Corner, 0, 0, Small*2, h, TranslateTheme(0.75) )
		end
		
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
	
		surface.CreateFont( "WarFontTitle", {
			font = "Coolvetica",
			size = math.floor(y*0.05),
			weight = 100,
			antialias = true,
		} )
	
		surface.CreateFont( "WarFontCount", {
			font = "Coolvetica",
			size = math.floor(y*0.025),
			weight = 200,
			antialias = true,
		} )

		surface.CreateFont( "WarFontDesc", {
			font = "Coolvetica",
			size = math.floor(y*0.04),
			weight = 100,
			antialias = true,
		} )
	
		local OfficialData = WarframeMods[mod]
					
		local BaseX = x*0.3
		local BaseY = BaseX*1.5
		local Small = x*0.01

		Count = mod .. rank

		if tonumber(count) > 0 then
		
			Frame[Count] = List:Add("DPanel")
			Frame[Count]:SetSize(BaseX,BaseY)
			--[[
			local FuckYou = Frame[Count]
			function FuckYou:Paint(w,h)
				draw.RoundedBox( Corner, 0, 0, w, h, TranslateTheme(1) )
			end
			--]]

			CountBase[Count] = vgui.Create("DButton",Frame[Count])
			CountBase[Count]:SetPos(BaseX - BaseY*0.1 + Small,0)
			CountBase[Count]:SetSize(BaseY*0.1 - Small,BaseY*0.1 - Small)
			--CountBase[Count]:SetImage("vgui/backpack_jewel_modify_target_b_g")
			CountBase[Count]:SetText(count)
			CountBase[Count]:SetFont("WarFontCount")
			CountBase[Count]:SetColor(TranslateTheme(0.1))
			
			local FuckYou = CountBase[Count]
			function FuckYou:Paint(w,h)
				draw.RoundedBox( Corner, 0, 0, w, h, TranslateTheme(0.80) )
			end
			
			CountBase[Count].DoClick = function() 
				TransmuteOptions[Count] = vgui.Create("DMenu")
				TransmuteOptions[Count]:AddOption("Activate (3 Charges)", function()
					WarSendActivation(x,y,List,mod,rank)
					chat.AddText(Color(255,255,255,255),"Activated mod. Will apply on next spawn.")
				end)
				TransmuteOptions[Count]:AddOption("Transmute x" .. TransmuteCost, function()
					WarSendTransmute(x,y,List,mod,rank,1)
				end)
				TransmuteOptions[Count]:AddOption("Transmute x" .. TransmuteCost*5, function()
					WarSendTransmute(x,y,List,mod,rank,5)
				end)
				TransmuteOptions[Count]:AddOption("Transmute x" .. TransmuteCost*10, function()
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
			--[[
			local FuckYou = TitleBase[Count]
			function FuckYou:Paint(w,h)
				draw.RoundedBox( Corner, 0, 0, w, h, TranslateTheme(0.80) )
			end
			--]]
			
			
			
			Title[Count] = vgui.Create("DLabel",TitleBase[Count])
			Title[Count]:SetText(OfficialData.Name)
			Title[Count]:SetColor(TranslateTheme(0.10))
			Title[Count]:SetFont("WarFontTitle")
			Title[Count]:SizeToContents(true)
			Title[Count]:Center()

			DescBase[Count] = vgui.Create("DPanel",Frame[Count])
			DescBase[Count]:SetPos(Small,BaseY*0.6 - Small*0.5)
			DescBase[Count]:SetSize(BaseX - Small*2,BaseY*0.35 - Small*2)
			
			--[[
			local FuckYou = DescBase[Count]
			function FuckYou:Paint(w,h)
				draw.RoundedBox( Corner, 0, 0, w, h, TranslateTheme(0.80) )
			end
			--]]
			
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
		
		return Frame[Count]

	end
	
	
	function WarSendTransmute(x,y,List,mod,rank,count)
	
		local CurrentCount = tonumber( CountBase[mod .. rank]:GetText())
	
		if CurrentCount >= count*TransmuteCost and rank < 10 then
	
			CountBase[mod .. rank]:SetText( CurrentCount - count*TransmuteCost)
			
			if IsValid(CountBase[mod .. rank+1]) then
				CountBase[mod .. rank+1]:SetText( tonumber( CountBase[mod .. rank+1]:GetText()) + count)
			else
				WarCreateCard(x,y,List,mod,rank+1,count)
			end

			local ply = LocalPlayer()
			
			net.Start("WarNetSendTransmute")
				net.WriteString(mod)
				net.WriteFloat(rank)
				net.WriteFloat(count)
			net.SendToServer()
		
		end
	
	end
	
	function WarSendActivation(x,y,List,mod,rank)
	
		local CurrentCount = tonumber( CountBase[mod .. rank]:GetText())
	
		if CurrentCount >= 1 then
	
			CountBase[mod .. rank]:SetText( CurrentCount - 1)

			local ply = LocalPlayer()
			
			net.Start("WarNetSendActivation")
				net.WriteString(mod)
				net.WriteFloat(rank)
			net.SendToServer()
		
		end

	end
	
	
	

end

