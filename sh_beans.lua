Beans = Beans or {}

local CURRENT_VERSION = 240201
if Beans._VERSION and (Beans._VERSION <= CURRENT_VERSION) then return end
Beans._VERSION = CURRENT_VERSION

Beans.Stored = Beans.Stored or {}

Beans.StoredNames = Beans.StoredNames or {}

Beans.Pressed = Beans.Pressed or {}
Beans.InProgress = Beans.InProgress or {}
Beans.Toggled = Beans.Toggled or {}

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

---@param cback fun(pl?: Player)
---@param onRelease? boolean @Should the bind only activate when the key is released.
function STORED_META:SetSimple(cback, onRelease)
	self.Callback = cback
	self.OnRelease = onRelease
end

---@param cback fun(pl?: Player)
---@param holdTime number @How long (in seconds) the player must hold down the key.
function STORED_META:SetHold(cback, holdTime)
	self.Callback = cback
	self.Hold = holdTime
end

---@param cback fun(pl?: Player, toggled: boolean)
---@param onRelease boolean
function STORED_META:SetToggle(cback, onRelease)
	self.Callback = cback
	self.Toggle = true
	self.OnRelease = onRelease
end

local function handleToggle(client, bindName, bindMeta)
	Beans.Toggled[client] = Beans.Toggled[client] or {}

	if Beans.Toggled[client][bindName] == nil then
		Beans.Toggled[client][bindName] = CurTime()
		bindMeta.Callback(client, true)
	else
		Beans.Toggled[client][bindName] = nil
		bindMeta.Callback(client, false)
	end
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

		if bindMeta.Toggle then
			handleToggle(pClient, bindName, bindMeta, true)
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

		if bindMeta.Toggle then
			handleToggle(pClient, bindName, bindMeta, false)
			goto nextBind
		end

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

if SERVER then
	hook.Add("PlayerDisconnected", "Beans::ClearTables", function(pClient)
		Beans.Pressed[pClient] = nil
		Beans.InProgress[pClient] = nil
		Beans.Toggled[pClient] = nil
	end)
end
