Beans = Beans or {}
Beans.Stored = Beans.Stored or {}

Beans.Current = Beans.Current or {}
Beans.Toggled = Beans.Toggled or {}
Beans.Held = Beans.Held or {}

local BIND_META = {}
BIND_META.__index = BIND_META

function Beans:Assign(btn, name)
  Beans.Stored[btn] = Beans.Stored[btn] or {}
  Beans.Stored[btn][name] = setmetatable({}, BIND_META)
  return Beans.Stored[btn][name]
end

function BIND_META:Simple(cback, onRelease)
  self.Callback = cback
  self.IsSimple = true
  self.IsOnRelease = onRelease
end

function BIND_META:Toggle(cback)
  self.Callback = cback
  self.IsToggle = true
end

function BIND_META:Hold(cback, holdTime)
  self.Callback = cback
  self.IsHold = true
  self.HoldTime = holdTime
end

hook.Add('PlayerButtonDown', 'Beans::Pressed', function(pl, btn)
  if not IsFirstTimePredicted() then return end
  if Beans.Stored[btn] == nil then return end

  for name, meta in pairs(Beans.Stored[btn]) do
    if not meta.IsOnRelease and
        not hook.Run('Beans::ShouldDisallow', pl, btn, name) then
      if meta.IsSimple then
        meta.Callback(pl)
      elseif meta.IsToggle then
        Beans.Toggled[pl] = Beans.Toggled[pl] or {}
        Beans.Toggled[pl][name] = not Beans.Toggled[pl][name]

        meta.Callback(pl, Beans.Toggled[pl][name])
      elseif meta.IsHold then
        Beans.Held[pl] = Beans.Held[pl] or {}
        Beans.Held[pl][meta] = CurTime()
      end
    end
  end

  Beans.Current[pl] = Beans.Current[pl] or {}
  Beans.Current[pl][btn] = CurTime()
end)

hook.Add('PlayerButtonUp', 'Beans::Released', function(pl, btn)
  if not IsFirstTimePredicted() then return end
  if Beans.Stored[btn] == nil then return end

  for name, meta in pairs(Beans.Stored[btn]) do
    if meta.IsOnRelease and meta.IsSimple and
        not hook.Run('Beans::ShouldDisallow', pl, btn, name) then
      meta.Callback(pl)
    elseif meta.IsHold then
      Beans.Held[pl][meta] = nil
    end
  end

  Beans.Current[pl][btn] = nil
end)

hook.Add('Think', 'Beans::Hold', function()
  for ply, held in pairs(Beans.Held) do
    for meta, state in pairs(held) do
      if state ~= true and ((state + meta.HoldTime) <= CurTime()) then
        meta.Callback(ply)
        held[meta] = true
      end
    end
  end
end)

if SERVER then
  hook.Add('PlayerDisconnected', 'Beans::ClearTables', function(pl)
    Beans.Current[pl] = nil
    Beans.Toggled[pl] = nil
    Beans.Held[pl] = nil
  end)
end
