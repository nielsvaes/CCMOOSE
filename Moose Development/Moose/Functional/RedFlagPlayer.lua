
RED_FLAG_PLAYER = {
    ClassName = "RED_FLAG_PLAYER"
}

function RED_FLAG_PLAYER:FindByName(unit_name)
    self = BASE:Inherit(self, UNIT:FindByName(unit_name))
    if self == nil then
        self:E("Couldn't find a unit with the name " .. unit_name)
    end

    self:HandleEvent(EVENTS.Shot)

    self.is_alive = true
    self.base_ammo = UTILS.DeepCopy(UTILS.GetSimpleAmmo(self))
    self.current_ammo = UTILS.DeepCopy(self.base_ammo)


    return self
end

function RED_FLAG_PLAYER:Kill()
    self.is_alive = false
    MESSAGE:New("You have been killed! Return to a respawn zone to respawn", 20):ToClient(self:GetClient())
end

function RED_FLAG_PLAYER:Respawn()
    self.is_alive = true
    self:ResetAmmo()
    local ammo_msg = ""
    for ammo_type, amount in pairs(self.current_ammo) do
        ammo_msg = ammo_msg .. string.format("%s: %s\n", ammo_type, amount)
    end

    MESSAGE:New(ammo_msg, 20):ToClient(self:GetClient())
    MESSAGE:New("Your ammo has been reset", 20):ToClient(self:GetClient())
    MESSAGE:New("You are respawned", 20):ToClient(self:GetClient())
end

function RED_FLAG_PLAYER:ResetAmmo()
    self.current_ammo = UTILS.DeepCopy(self.base_ammo)
end

function RED_FLAG_PLAYER:OnEventShot(event_data)
    DevMessageToAll("player fire!")
    local weapon_dcs_object = event_data.weapon
    local ccweapon = CCWEAPON:New(weapon_dcs_object)

    if not self.is_alive then
        DevMessageToAll(string.format("%s: Can't fire weapon, you're dead", self:GetName()))
        return
    end

    if self.current_ammo[ccweapon:GetType()] > 0 then
        self.current_ammo[ccweapon:GetType()] = self.current_ammo[ccweapon:GetType()] - 1
    else
        DevMessageToAll(string.format("%s: Can't fire weapon, out of ammo", self:GetName()))
        weapon_dcs_object:destroy()
    end

end
