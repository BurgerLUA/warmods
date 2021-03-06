ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "HE GRENADE"
ENT.Author = ""
ENT.Information = ""
ENT.Spawnable = false
ENT.AdminSpawnable = false 

AddCSLuaFile()

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/hunter/blocks/cube05x05x05.mdl") 
		
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:DrawShadow(false)
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		self:SetUseType(SIMPLE_USE)
		
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:Wake()
			phys:SetBuoyancyRatio(0)
			--phys:EnableCollisions(false)
		end
		
		self:SetNWEntity("Target",self.Target)

	end
end

function ENT:PhysicsCollide(data, physobj)

end


function ENT:Use(activator,caller,useType,value)

	if activator:IsPlayer() and self:CanPickup(activator) then
		WarGiveRandomMod(self:GetNWEntity("Target",self))
		SafeRemoveEntity(self)
	end

end

function ENT:CanPickup(ply)
	return self:GetNWEntity("Target",self) == ply
end


function ENT:Draw()
	if CLIENT then
		if self:CanPickup(LocalPlayer()) then
			local settings = {}

			if file.Exists("models/items/cs_gift.mdl","GAME") then
				settings["model"] = "models/items/cs_gift.mdl"
			else
				settings["model"] = "models/maxofs2d/companion_doll.mdl"
			end

			settings["pos"] = self:GetPos() - Vector(0,0,12)
			settings["angle"] = Angle(0,CurTime()*500,0)

			render.Model(settings)
		end
	end
end

