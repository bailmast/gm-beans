Beans = Beans or {}

local CURRENT_VERSION = 240106
if Beans._VERSION and (Beans._VERSION <= CURRENT_VERSION) then return end
Beans._VERSION = CURRENT_VERSION

Beans.Stored = Beans.Stored or {}

Beans.StoredNames = Beans.StoredNames or {}

Beans.Pressed = Beans.Pressed or {}
Beans.InProgress = Beans.InProgress or {}


function Beans:Assign(keyCode, bindName, bindCallback, holdTime)
	self.Stored[keyCode] = self.Stored[keyCode] or {}
	self.Stored[keyCode][bindName] = {
		Callback = bindCallback,
		Hold = holdTime
	}

	self.StoredNames[bindName] = keyCode
end


do
	hook.Add("PlayerButtonDown", "Beans::Pressed", function(pClient, nButton)
		if not IsFirstTimePredicted() then return end
		if Beans.Stored[nButton] == nil then return end
		if Beans.Pressed[pClient] ~= nil and Beans.Pressed[pClient][nButton] then return end

		Beans.Pressed[pClient] = Beans.Pressed[pClient] or {}
		Beans.Pressed[pClient][nButton] = true

		for bindName, bindInfo in pairs(Beans.Stored[nButton]) do
			if hook.Run("Beans::ShouldDisallow", pClient, nButton, bindName) then return end

			if bindInfo.Hold then
				Beans.InProgress[pClient] = Beans.InProgress[pClient] or {}
				Beans.InProgress[pClient][bindName] = CurTime() + bindInfo.Hold

				goto shouldHold
			end

			bindInfo.Callback(pClient)

			::shouldHold::
		end
	end)

	hook.Add("PlayerButtonUp", "Beans::Depressed", function(pClient, nButton)
		if not IsFirstTimePredicted() then return end
		if Beans.Stored[nButton] == nil then return end
		if not Beans.Pressed[pClient] or not Beans.Pressed[pClient][nButton] then return end

		do
			Beans.Pressed[pClient][nButton] = nil

			if next(Beans.Pressed[pClient]) == nil then
				Beans.Pressed[pClient] = nil
			end
		end

		if not Beans.InProgress[pClient] then return end

		do
			for bindName in pairs(Beans.InProgress[pClient]) do
				Beans.InProgress[pClient][bindName] = nil
			end

			if next(Beans.InProgress[pClient]) == nil then
				Beans.InProgress[pClient] = nil
			end
		end
	end)

	hook.Add("Think", "Beans::Progress", function()
		for actor, bindsInProgress in pairs(Beans.InProgress) do
			for bindName, actTime in pairs(bindsInProgress) do
				if CurTime() < actTime then goto notYet end

				do
					Beans.InProgress[actor][bindName] = nil

					Beans.Stored[Beans.StoredNames[bindName]][bindName].Callback(actor)
				end

				::notYet::
			end
		end
	end)


	if CLIENT then return end

	hook.Add("PlayerDisconnected", "Beans::ClearTables", function(pl)
		Beans.Pressed[pl] = nil
		Beans.InProgress[pl] = nil
	end)
end
