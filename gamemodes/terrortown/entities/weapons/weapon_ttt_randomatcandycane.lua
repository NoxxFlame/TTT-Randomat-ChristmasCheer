AddCSLuaFile()

local IsValid = IsValid
local math = math
local surface = surface
local timer = timer
local util = util

if CLIENT then
    SWEP.PrintName = "Candy Cane"
    SWEP.EquipMenuData = {
        type = "Weapon",
        desc = "Left-click to convert another player"
    };

    SWEP.Slot = 8 -- add 1 to get the slot number key
    SWEP.ViewModelFOV = 41
    SWEP.ViewModelFlip = false
    SWEP.UseHands = true
end

SWEP.InLoadoutFor = { }

SWEP.Base = "weapon_tttbase"
SWEP.Category = WEAPON_CATEGORY_ROLE

SWEP.HoldType = "melee"

SWEP.ViewModel = Model("models/weapons/melee/v_crowbar.mdl")
SWEP.WorldModel = Model("models/weapons/melee/w_crowbar.mdl")

SWEP.Primary.Automatic = false
SWEP.Secondary.Automatic = false

SWEP.Kind = WEAPON_ROLE
SWEP.LimitedStock = false
SWEP.AllowDrop = false

SWEP.TargetEntity = nil

local STATE_ERROR = -1
local STATE_NONE = 0
local STATE_CONVERT = 1

local sound_christmas = Sound("jinglebells.wav")

function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "State")
    self:NetworkVar("Int", 1, "DeviceDuration")
    self:NetworkVar("Float", 0, "StartTime")
    self:NetworkVar("String", 0, "Message")

    if SERVER then
        self:SetDeviceDuration(5)
        self:Reset()
    end
end

function SWEP:Initialize()
    if CLIENT then
        self:AddHUDHelp("candycant_help_pri", nil, true)
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:Deploy()
    self:SetNextPrimaryFire(CurTime())
end

function SWEP:Holster()
    self:FireError()
    return true
end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:OnRemove()
    if IsPlayer(self.TargetEntity) then
        self:CancelUnfreeze(self.TargetEntity)
        self:DoUnfreeze()
    end
    if SERVER then
        self:Reset()
    end
end

function SWEP:PrimaryAttack()
    if CLIENT then return end

    local tr = self:GetTraceEntity()
    if IsValid(tr.Entity) then
        local ent = tr.Entity
        if ent:IsPlayer() then
            if ent:IsRole(ROLE_ELF) then
                self:Error("TARGET IS AN ALLY")
            else
                self:Convert(ent)
            end
        end
    end
end

function SWEP:CancelUnfreeze(entity)
    if CLIENT then return end
    if not IsPlayer(entity) then return end
    if not IsValid(self:GetOwner()) then return end
    local timerid = "ElfUnfreezeDelay_" .. self:GetOwner():Nick() .. "_" .. entity:Nick()
    if timer.Exists(timerid) then
        self:AdjustFreezeCount(entity, -1, 1)
        timer.Remove(timerid)
    end
end

function SWEP:AdjustFreezeCount(ent, adj, def)
    if CLIENT then return end
    local freeze_count =  math.max(0, ent:GetNWInt("ElfFreezeCount", def) + adj)
    ent:SetNWInt("ElfFreezeCount", freeze_count)
    return freeze_count
end

function SWEP:DoFreeze()
    if CLIENT then return end
    self:AdjustFreezeCount(self.TargetEntity, 1, 0)
    self.TargetEntity:Freeze(true)
end

function SWEP:DoUnfreeze()
    if CLIENT then return end
    local freeze_count = self:AdjustFreezeCount(self.TargetEntity, -1, 1)
    if freeze_count == 0 then
        self.TargetEntity:Freeze(false)
    end
    self.TargetEntity = nil
end

function SWEP:Convert(entity)
    local owner = self:GetOwner()
    if IsValid(owner) then
        owner:EmitSound(sound_christmas)
    end

    self:SetState(STATE_CONVERT)
    self:SetStartTime(CurTime())
    self:SetMessage("SPREADING CHRISTMAS CHEER")
    self:CancelUnfreeze(entity)

    entity:PrintMessage(HUD_PRINTCENTER, "Someone is spreading Christmas cheer to you!")
    self.TargetEntity = entity
    self:DoFreeze()

    self:SetNextPrimaryFire(CurTime() + self:GetDeviceDuration())
end

function SWEP:DoConvert()
    local ply = self.TargetEntity
    ply:SetRole(ROLE_ELF)

    -- Not actually an error, but it resets the things we want
    self:FireError()
    self:DoUnfreeze()

    SendFullStateUpdate()
    -- Reset the victim's max health
    SetRoleMaxHealth(ply)
end

function SWEP:UnfreezeTarget()
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsPlayer(self.TargetEntity) then return end

    self:CancelUnfreeze(self.TargetEntity)

    local delay = 2
    if delay <= 0 or not IsPlayer(owner) then
        self:DoUnfreeze()
    else
        timer.Create("ElfUnfreezeDelay_" .. owner:Nick() .. "_" .. self.TargetEntity:Nick(), delay, 1, function()
            if not IsPlayer(self.TargetEntity) then return end
            self:DoUnfreeze()
        end)
    end
end

function SWEP:FireError()
    local owner = self:GetOwner()
    if IsValid(owner) then
        owner:StopSound(sound_christmas)
    end
    self:SetState(STATE_NONE)
    self:UnfreezeTarget()
    self:SetNextPrimaryFire(CurTime() + 0.1)
end

function SWEP:Think()
    if CLIENT then return end

    if self:GetState() > STATE_NONE then
        if not IsValid(self:GetOwner()) then
            self:FireError()
            return
        end

        local tr = self:GetTraceEntity()
        if not self:GetOwner():KeyDown(IN_ATTACK) or tr.Entity ~= self.TargetEntity then
            self:Error("ABORTED")
            return
        end

        -- If there is a target and they have been turned to a communist by someone else, stop trying to drain them
        if not IsPlayer(self.TargetEntity) or self.TargetEntity:IsCommunist() then
            self:Error("ABORTED")
            return
        end

        if CurTime() >= self:GetStartTime() + self:GetDeviceDuration() then
            self:DoConvert()
        end
    end
end

if CLIENT then
    function SWEP:DrawHUD()
        local x = ScrW() / 2.0
        local y = ScrH() / 2.0

        y = y + (y / 3)

        local w, h = 255, 20

        if self:GetState() > STATE_NONE then
            local progress = math.TimeFraction(self:GetStartTime(), self:GetStartTime() + self:GetDeviceDuration(), CurTime())

            if progress < 0 then return end

            progress = math.Clamp(progress, 0, 1)

            surface.SetDrawColor(0, 255, 0, 155)

            surface.DrawOutlinedRect(x - w / 2, y - h, w, h)

            surface.DrawRect(x - w / 2, y - h, w * progress, h)

            surface.SetFont("TabLarge")
            surface.SetTextColor(255, 255, 255, 180)
            surface.SetTextPos((x - w / 2) + 3, y - h - 15)
            surface.DrawText(self:GetMessage())
        elseif self:GetState() == STATE_ERROR then
            surface.SetDrawColor(200 + math.sin(CurTime() * 32) * 50, 0, 0, 155)

            surface.DrawOutlinedRect(x - w / 2, y - h, w, h)

            surface.DrawRect(x - w / 2, y - h, w, h)

            surface.SetFont("TabLarge")
            surface.SetTextColor(255, 255, 255, 180)
            surface.SetTextPos((x - w / 2) + 3, y - h - 15)
            surface.DrawText(self:GetMessage())
        end
    end
else
    function SWEP:Reset()
        local owner = self:GetOwner()
        if IsValid(owner) then
            owner:StopSound(sound_christmas)
        end
        self:SetState(STATE_NONE)
        self:SetStartTime(-1)
        self:SetMessage('')
        self:SetNextPrimaryFire(CurTime() + 0.1)
    end

    function SWEP:Error(msg)
        local owner = self:GetOwner()
        if IsValid(owner) then
            owner:StopSound(sound_christmas)
        end
        self:SetState(STATE_ERROR)
        self:SetStartTime(CurTime())
        self:SetMessage(msg)
        self:SetNextPrimaryFire(CurTime() + 0.75)
        self:UnfreezeTarget()

        timer.Simple(0.75, function()
            if IsValid(self) then self:Reset() end
        end)
    end

    function SWEP:GetTraceEntity()
        local spos = self:GetOwner():GetShootPos()
        local sdest = spos + (self:GetOwner():GetAimVector() * 70)
        local kmins = Vector(1,1,1) * -10
        local kmaxs = Vector(1,1,1) * 10

        return util.TraceHull({start=spos, endpos=sdest, filter=self:GetOwner(), mask=MASK_SHOT_HULL, mins=kmins, maxs=kmaxs})
    end
end