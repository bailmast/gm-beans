Beans = Beans or {}

local CURRENT_VERSION = 240201
if Beans._VERSION and (Beans._VERSION <= CURRENT_VERSION) then return end
Beans._VERSION = CURRENT_VERSION

Beans.Stored = Beans.Stored or {}

Beans.StoredNames = Beans.StoredNames or {}

Beans.Pressed = Beans.Pressed or {}
Beans.InProgress = Beans.InProgress or {}

local STORED_META = {}
STORED_META.__index = STORED_META

---@param keyCode number @https://wiki.facepunch.com/gmod/Enums/BUTTON_CODE
---@param bindName string @Must be unique to each key.
---@return table
function Beans:Assign(keyCode, bindName)
	local bindMeta = setmetatable({}, STORED_META)

	self.Stored[keyCode] = self.Stored[keyCode] or {}
	self.Stored[keyCode][bindName] = bindMeta

	self.StoredNames[bindName] = keyCode

	return bindMeta
end

---@param callback fun(pl?: Player)
---@param onRelease? boolean @Should the bind only activate when the key is released.
function STORED_META:SetSimple(callback, onRelease)
	self.Callback = callback
	self.OnRelease = onRelease
end

---@param callback fun(pl?: Player)
---@param holdTime number @How long (in seconds) the player must hold down the key.
function STORED_META:SetHold(callback, holdTime)
	self.Callback = callback
	self.Hold = holdTime
end

hook.Add("PlayerButtonDown", "Beans::Pressed", function(pClient, nButton)
	if not IsFirstTimePredicted() then return end
	if Beans.Stored[nButton] == nil then return end
	if Beans.Pressed[pClient] ~= nil and Beans.Pressed[pClient][nButton] then return end

	for bindName, bindMeta in pairs(Beans.Stored[nButton]) do
		if hook.Run("Beans::ShouldDisallow", pClient, nButton, bindName) then goto nextBind end
		if bindMeta.OnRelease then goto nextBind end

		if bindMeta.Hold then
			Beans.InProgress[pClient] = Beans.InProgress[pClient] or {}
			Beans.InProgress[pClient][bindName] = CurTime() + bindMeta.Hold

			goto nextBind
		end

		bindMeta.Callback(pClient)

		::nextBind::
	end

	Beans.Pressed[pClient] = Beans.Pressed[pClient] or {}
	Beans.Pressed[pClient][nButton] = true
end)

hook.Add("PlayerButtonUp", "Beans::Depressed", function(pClient, nButton)
	if not IsFirstTimePredicted() then return end
	if Beans.Stored[nButton] == nil then return end
	if Beans.Pressed[pClient] == nil or not Beans.Pressed[pClient][nButton] then return end

	Beans.Pressed[pClient][nButton] = nil

	if Beans.InProgress[pClient] ~= nil then
		for bindName in pairs(Beans.InProgress[pClient]) do
			Beans.InProgress[pClient][bindName] = nil
		end
	end

	for bindName, bindMeta in pairs(Beans.Stored[nButton]) do
		if not bindMeta.OnRelease then goto nextBind end
		if hook.Run("Beans::ShouldDisallow", pClient, nButton, bindName) then goto nextBind end

		bindMeta.Callback(pClient)

		::nextBind::
	end
end)

hook.Add("Think", "Beans::Progress", function()
	for actor, bindsInProgress in pairs(Beans.InProgress) do
		for bindName, actTime in pairs(bindsInProgress) do
			if CurTime() < actTime then goto notYet end

			Beans.InProgress[actor][bindName] = nil

			Beans.Stored[Beans.StoredNames[bindName]][bindName].Callback(actor)

			::notYet::
		end
	end
end)

if CLIENT then return end

hook.Add("PlayerDisconnected", "Beans::ClearTables", function(pl)
	Beans.Pressed[pl] = nil
	Beans.InProgress[pl] = nil
end)
