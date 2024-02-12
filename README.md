# Beans

Garry's Mod binding library for both `CLIENT` and `SERVER`

# Usage

```lua
if SERVER then
  Beans:Assign(KEY_H, 'ExampleToggled')
    :Toggle(function(pl, toggled)
      pl:ChatPrint('SERVER: [H] -> ' .. (toggled and '' or 'Un') .. 'Toggled!')
    end)

  Beans:Assign(KEY_J, 'ExampleHold')
    :Hold(function(pl)
      pl:ChatPrint('SERVER: [J] -> Two and a half seconds!')
    end, 2.5)
else -- CLIENT
  Beans:Assign(KEY_G, 'ExamplePressed')
    :Simple(function()
      chat.AddText('CLIENT: [G] -> Pressed!')
    end)

  Beans:Assign(KEY_G, 'ExampleReleased')
    :Simple(function()
      chat.AddText('CLIENT: [G] -> Released!')
    end, true)
end

-- SHARED
Beans:Assign(KEY_O, 'ExampleShared')
  :Simple(function(pl)
    if SERVER then
      pl:Kill()
      pl:ChatPrint("SERVER -> You: I've killed you!")
      return
    end

    -- CLIENT
    chat.AddText("CLIENT: I'm gonna die... (client will execute this faster btw)")
  end)
```

```lua
-- You can also disallow usage of bind in some scenarios.

-- SHARED
hook.Add('Beans::ShouldDisallow', 'ExampleShared', function(pl, btn, name)
  if name ~= 'ExampleShared' then return end
  if pl:Alive() then return end

  return true -- to disallow
end)
```
