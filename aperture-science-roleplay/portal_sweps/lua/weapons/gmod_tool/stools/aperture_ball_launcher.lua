TOOL.Tab 		= "Aperture Science"
TOOL.Category 	= "Construction"
TOOL.Name 		= "#tool.aperture_ball_launcher.name"

TOOL.ClientConVar["keyenable"] = "45"
TOOL.ClientConVar["startenabled"] = "0"
TOOL.ClientConVar["toggle"] = "0"
TOOL.ClientConVar["time"] = "1"

local LAUNCHER_MODEL = "models/aperture/combine_ball_launcher.mdl"

if CLIENT then
	language.Add("tool.aperture_ball_launcher.name", "High Energy Pellet Launcher")
	language.Add("tool.aperture_ball_launcher.desc", "Launches a High Energy Pellet. Place a catcher to recieve a signal.")
	language.Add("tool.aperture_ball_launcher.0", "LMB: Place")
	language.Add("tool.aperture_ball_launcher.enable", "Enable")
	language.Add("tool.aperture_ball_launcher.startenabled", "Starts active?")
	language.Add("tool.aperture_ball_launcher.startenabled.help", "Launcher will start active after placed.")
	language.Add("tool.aperture_ball_launcher.time", "Time before pellet explosion")
	language.Add("tool.aperture_ball_launcher.time.help", "Over a period of time the pellet will explode.")
	language.Add("tool.aperture_ball_launcher.toggle", "Toggle (unused)")
end

if SERVER then

	function MakePortalBallLauncher(ply, pos, ang, key_enable, startenabled, time, toggle, data)
		local ent = ents.Create("ent_portal_ball_launcher")
		if not IsValid(ent) then return end
		
		duplicator.DoGeneric(ent, data)

		ent:SetPos(pos)
		ent:SetAngles(ang)
		ent:SetMoveType(MOVETYPE_NONE)
		ent.Owner = ply
		ent:SetStartEnabled(tobool(startenabled))
		ent:SetToggle(tobool(toggle))
		ent:SetTime(time)
		ent:Spawn()
		
		-- initializing numpad inputs
		--ent.NumDown = numpad.OnDown(ply, key_enable, "PortalBallLauncher_Enable", ent, true)
		--ent.NumUp = numpad.OnUp(ply, key_enable, "PortalBallLauncher_Enable", ent, false)

		-- saving data
		local ttable = {
			key_enable = key_enable,
			ply = ply,
			startenabled = startenabled,
			time = time,
			toggle = toggle,
		}

		table.Merge(ent:GetTable(), ttable)

		if IsValid(ply) then
			ply:AddCleanup("#tool.aperture_ball_launcher.name", ent)
		end
		
		return ent
	end
	
	duplicator.RegisterEntityClass("ent_portal_ball_launcher", MakePortalBallLauncher, "pos", "ang", "key_enable", "startenabled", "time", "toggle", "data")
end

function TOOL:LeftClick( trace )
	-- Ignore if place target is Alive
	//if ( trace.Entity and ( trace.Entity:IsPlayer() || trace.Entity:IsNPC() || APERTURESCIENCE:GASLStuff( trace.Entity ) ) ) then return false end

	if CLIENT then return true end
	
	-- if not APERTURESCIENCE.ALLOWING.paint and not self:GetOwner():IsSuperAdmin() then self:GetOwner():PrintMessageHUD_PRINTTALK, "This tool is disabled" return end

	local ply = self:GetOwner()
	
	local key_enable = self:GetClientNumber("keyenable")
	local startenabled = self:GetClientNumber("startenabled")
	local toggle = self:GetClientNumber("toggle")
	local time = self:GetClientNumber("time")
	
	local pos = trace.HitPos
	local ang = trace.HitNormal:Angle()
	
	local ent = MakePortalBallLauncher(ply, pos, ang, key_enable, startenabled, time, toggle)
		
	undo.Create("Hight Energy Pellet Launcher")
		undo.AddEntity(ent)
		undo.SetPlayer(ply)
	undo.Finish()
	
	return true, ent
end

function TOOL:UpdateGhostPortalBallLauncher(ent, ply)
	if not IsValid(ent) then return end

	local trace = ply:GetEyeTrace()
	if not trace.Hit or trace.Entity and (trace.Entity:IsPlayer() or trace.Entity:IsNPC() or trace.Entity.IsAperture) then
		ent:SetNoDraw(true)
		return
	end
	
	local curPos = ent:GetPos()
	local pos = trace.HitPos
	local ang = trace.HitNormal:Angle()

	ent:SetPos(pos)
	ent:SetAngles(ang)
	ent:SetNoDraw(false)
end

function TOOL:RightClick(trace)

end

function TOOL:Think()
	local mdl = LAUNCHER_MODEL
	if not util.IsValidModel(mdl) then self:ReleaseGhostEntity() return end

	if not IsValid(self.GhostEntity) or self.GhostEntity:GetModel() != mdl then
		self:MakeGhostEntity(mdl, Vector(0, 0, 0), Angle(0, 0, 0))
	end

	self:UpdateGhostPortalBallLauncher(self.GhostEntity, self:GetOwner())
end

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel( CPanel )
	CPanel:AddControl("Header", {Description = "#tool.aperture_ball_launcher.desc"})
	CPanel:AddControl("CheckBox", {Label = "#tool.aperture_ball_launcher.startenabled", Command = "aperture_ball_launcher_startenabled", Help = true})
	--CPanel:AddControl("Numpad", {Label = "#tool.aperture_ball_launcher.enable", Command = "aperture_ball_launcher_keyenable"})
	--CPanel:AddControl("CheckBox", {Label = "#tool.aperture_ball_launcher.toggle", Command = "aperture_ball_launcher_toggle"})
	CPanel:NumSlider("#tool.aperture_ball_launcher.time", "aperture_ball_launcher_time", 1, 60)
	CPanel:Help("#tool.aperture_ball_launcher.time.help")
end