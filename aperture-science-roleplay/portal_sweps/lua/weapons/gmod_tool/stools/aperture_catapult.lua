TOOL.Tab 		= "Aperture Science"
TOOL.Category 	= "Construction"
TOOL.Name 		= "#tool.aperture_catapult.name"
TOOL.CatapultPlaced = false
TOOL.CatapultPos = nil
TOOL.CatapultAng = nil
TOOL.CatapultEnt = nil

TOOL.ClientConVar["model"] 			= "models/aperture/faith_plate_128.mdl"
TOOL.ClientConVar["keyenable"] 		= "45"
TOOL.ClientConVar["startenabled"] 	= "0"
TOOL.ClientConVar["toggle"] 		= "0"

local TRAJECTORY_QUALITY 			= 20

if CLIENT then
	language.Add("tool.aperture_catapult.name", "Aerial Faith Plate")
	language.Add("tool.aperture_catapult.desc", "Place it, and fling!")
	language.Add("tool.aperture_catapult.0", "LMB: Place an faith plate. RMB: Once you've placed it, right clicking the plate will select it. Afterwards, left-click to set its destination.")
	language.Add("tool.aperture_catapult.enable", "Enable")
	language.Add("tool.aperture_catapult.startenabled", "Start active?")
	language.Add("tool.aperture_catapult.startenabled.help", "Faith plate will start active after placed.")
	language.Add("tool.aperture_catapult.toggle", "Toggle (unused)")
end

local function GetLineDistToSphere(startPos, dir, spherePos)
    local vec = spherePos - startPos
    local vecN = vec:GetNormalized()
    local dist = vec:Length()
    local angle = math.acos(vecN:Dot(dir))
    local height = dist * math.sin(angle)
	return height
end

if SERVER then

	function MakeCatapult(ply, pos, ang, model, key_enable, startenabled, toggle, time_of_flight, launch_vector, data)
		local ent = ents.Create("ent_catapult")
		if not IsValid(ent) then return end
		
		duplicator.DoGeneric(ent, data)

		ent:SetPos(pos)
		ent:SetModel(model)
		ent:SetAngles(ang)
		ent:SetStartEnabled(tobool(startenabled))
		if time_of_flight then ent:SetTimeOfFlight(time_of_flight) end
		if launch_vector then ent:LaunchVector(launch_vector) end
		ent:Spawn()
		
		-- initializing numpad inputs
		--ent.NumDown = numpad.OnDown(ply, key_enable, "PortalCatapult_Enable", ent, true)
		--ent.NumUp = numpad.OnUp(ply, key_enable, "PortalCatapult_Enable", ent, false)
		
		if IsValid(ply) then
			ply:AddCleanup("#tool.aperture_catapult.name", ent )
			ply:AddCount("catapults", ent)
		end
		
		return ent
	end
	
	duplicator.RegisterEntityClass("ent_catapult", MakeCatapult, "model", "key_enable", "startenabled", "toggle", "time_of_flight", "launch_vector", "data")
end

function TOOL:LeftClick( trace )
	-- Ignore if place target is Alive
	if trace.Entity and trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end
	if not IsValid(self.CatapultEnt) then self.CatapultPlaced = false end
	-- if not APERTURESCIENCE.ALLOWING.tractor_beam and not self:GetOwner():IsSuperAdmin() then self:GetOwner():PrintMessage( HUD_PRINTTALK, "This tool is disabled" ) return end

	if not self.CatapultPlaced then
		local ply = self:GetOwner()
		local model = self:GetClientInfo("model")
		local key_enable = self:GetClientNumber("keyenable")
		local startenabled = self:GetClientNumber("startenabled")
		local toggle = self:GetClientNumber("toggle")
		local pos = trace.HitPos + trace.HitNormal * 10
		local ang = trace.HitNormal:Angle() + Angle(90, 0, 0)
		
		local ent = MakeCatapult(ply, pos, ang, model, key_enable, startenabled, toggle, nil, nil)
		self.CatapultPlaced = true
		self.CatapultEnt = ent

		undo.Create("Areial Faith Plate")
			undo.AddEntity(ent)
			undo.SetPlayer(ply)
		undo.Finish()

		return true, ent
	else
		local catapult = self.CatapultEnt
		catapult:SetLandingPoint(trace.HitPos)
		-- self.CatapultPos = trace.HitPos + trace.HitNormal * 10
		-- self.CatapultAng = trace.HitNormal:Angle() + Angle(90, 0, 0)
		self.CatapultPlaced = false
	end
	
	return true
end

function TOOL:RightClick(trace)
	if CLIENT then return end
	
	local ply = self:GetOwner()
	
	if IsValid(self.CatapultGrabbedPoint) then
		local catapult = self.CatapultGrabbedPoint
		if self.CatapultGrabbedPointType == 1 then
			local catpos = catapult:GetPos()
			local plypos = ply:GetShootPos()
			
			local height = self.CatapultGrabbedPointHeight
			local heightPlyEnt = (plypos.z - catpos.z)
			local distXY = Vector(plypos.x, plypos.y):Distance(Vector(catpos.x, catpos.y))
			local angle = -ply:GetAngles().pitch
			local height2 = distXY * math.sin(angle * math.pi / 180) + heightPlyEnt
			
			catapult:SetLaunchHeight(height2)
			catapult:CalculateTrajectory()
			
		elseif self.CatapultGrabbedPointType == 2 then
			catapult:SetLandingPoint(trace.HitPos)
		end

		self.CatapultGrabbedPoint = nil
	else
		for k,v in pairs(ents.FindByClass("ent_catapult")) do
			
			-- Draw trajectory if player holding air faith plate tool
			if v:GetLandPoint() == Vector() then continue end
			
			local startpos = v:GetPos()
			local endpos = v:GetLandPoint()
			local height = v:GetLaunchHeight()
			local middlepos = (startpos + endpos) / 2

			local amount = math.max(4, startpos:Distance(endpos) / 200)
			local timeofFlight = v:GetTimeOfFlight()
			local launchVector = v:GetLaunchVector()
			local dTime = timeofFlight / TRAJECTORY_QUALITY
			local dVector = launchVector * dTime
			
			local point = v:GetPos()
			local gravity = math.abs(physenv.GetGravity().z) * timeofFlight / (TRAJECTORY_QUALITY - 1)
			
			for i = 1,TRAJECTORY_QUALITY do
				point = point + dVector
				dVector = dVector - Vector(0, 0, gravity * dTime)
				
				if i == math.Round(TRAJECTORY_QUALITY / 2) then
					if GetLineDistToSphere(ply:GetShootPos(), ply:EyeAngles():Forward(), point) < 64 and not IsValid(self.CatapultGrabbedPoint) then
						self.CatapultGrabbedPoint = v
						self.CatapultGrabbedPointType = 1
						self.CatapultGrabbedPointHeight = math.abs(point.z - v:GetPos().z)
						return
					end
					
					break
				end
			end
			
			if GetLineDistToSphere(ply:GetShootPos(), ply:EyeAngles():Forward(), endpos) < 64 and not IsValid(self.CatapultGrabbedPoint) then
				self.CatapultGrabbedPoint = v
				self.CatapultGrabbedPointType = 2
				return
			end
		end
	end
end

function TOOL:UpdateGhostWallProjector(ent, ply)
	if not IsValid(ent) then return end

	local trace = ply:GetEyeTrace()
	if not trace.Hit or trace.Entity and (trace.Entity:IsPlayer() or trace.Entity:IsNPC() or trace.Entity.IsAperture) then
		ent:SetNoDraw( true )
		return
	end
	
	local pos = Vector(0, 0, 0)
	if self.CatapultPlaced then pos = self.CatapultPos else pos = trace.HitPos + trace.HitNormal * 10 end
	local ang = trace.HitNormal:Angle() + Angle( 90, 0, 0 )

	ent:SetPos(pos)
	ent:SetAngles(ang)
	ent:SetNoDraw(false)
end

function TOOL:Think()
	local mdl = "models/aperture/faith_plate_128.mdl"
	if not util.IsValidModel(mdl) then self:ReleaseGhostEntity() return end

	if not IsValid(self.GhostEntity) or self.GhostEntity:GetModel() != mdl then
		self:MakeGhostEntity( mdl, Vector( 0, 0, 0 ), Angle( 0, 0, 0 ) )
	end

	self:UpdateGhostWallProjector(self.GhostEntity, self:GetOwner())
end
if SERVER then
	function TOOL:Holster()
		self:ReleaseGhostEntity() -- remove if broken, wildfire
		if self.CatapultPlaced and IsValid(self.CatapultEnt) then
			self.CatapultEnt:Remove()
			self.CatapultPlaced = false
		end
	end
end

function TOOL:DrawHUD()

	cam.Start3D()
		local ply = LocalPlayer()
		for k,v in pairs(ents.FindByClass("ent_catapult")) do
			
			-- Draw trajectory if player holding air faith plate tool
			if v:GetLandPoint() == Vector() then continue end
			
			local startpos = v:GetPos()
			local endpos = v:GetLandPoint()
			local height = v:GetLaunchHeight()
			local middlepos = (startpos + endpos) / 2
			local prevBeamPos = startpos

			-- Drawing land target
			render.SetMaterial(Material("signage/mgf_overlay_bullseye"))
			render.DrawQuadEasy(endpos, Vector(0, 0, 1), 80, 80, Color(255, 255, 255), 0)
			
			-- Drawing trajectory
			render.SetMaterial(Material("effects/trajectory_path"))
			local amount = math.max(4, startpos:Distance(endpos) / 200)
			local timeofFlight = v:GetTimeOfFlight()
			local launchVector = v:GetLaunchVector()
			local dTime = timeofFlight / TRAJECTORY_QUALITY
			local dVector = launchVector * dTime
			
			local point = v:GetPos()
			local gravity = math.abs(physenv.GetGravity().z) * timeofFlight / (TRAJECTORY_QUALITY - 1)
			local middlePoint = Vector()
			
			for i = 1,TRAJECTORY_QUALITY do
				point = point + dVector
				dVector = dVector - Vector( 0, 0, gravity * dTime )
				
				render.DrawBeam(prevBeamPos, point, 120, 0, 1, Color(255, 255, 255))
				prevBeamPos = point
				if i == math.Round(TRAJECTORY_QUALITY / 2) then middlePoint = point end
			end
			
			-- Drawing height point
			render.SetMaterial(Material("sprites/sent_ball"))
			render.DrawSprite(middlePoint, 32, 32, Color(255, 255, 0))
			
			-- Drawing landpoint point
			render.SetMaterial(Material("sprites/sent_ball"))
			render.DrawSprite(endpos, 32, 32, Color(0, 255, 0))
		end
		
	cam.End3D()
end

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel(CPanel)
	CPanel:AddControl("Header", {Description = "#tool.aperture_catapult.desc"})
	CPanel:AddControl("PropSelect", {Label = "#tool.aperture_catapult.model", ConVar = "aperture_catapult_model", Models = list.Get("PortalCatapultModels"), Height = 0})
	CPanel:AddControl("CheckBox", {Label = "#tool.aperture_catapult.startenabled", Command = "aperture_catapult_startenabled", Help = 1})
	--CPanel:AddControl("Numpad", {Label = "#tool.aperture_catapult.enable", Command = "aperture_catapult_keyenable"})
	--CPanel:AddControl("CheckBox", {Label = "#tool.aperture_paint_dropper.toggle", Command = "aperture_paint_dropper_toggle"})
end

list.Set("PortalCatapultModels", "models/aperture/faith_plate_128.mdl", {})