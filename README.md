# Beans

Garry's Mod binding library for both CLIENT and SERVER

# Usage

```lua
if CLIENT then
  Beans:Assign(KEY_G, "Example")
    :SetSimple(function()
      RunConsoleCommand("say", "You pressed [G]!")
    end)

  Beans:Assign(KEY_G, "ExampleRelease")
    :SetSimple(function()
      RunConsoleCommand("say", "You released [G]!")
    end, true)

  Beans:Assign(KEY_G, "ExampleHold")
    :SetHold(function()
      RunConsoleCommand("say", "You held [G] for 2 seconds!")
    end, 2)
else -- SERVER
  Beans:Assign(KEY_G, "ExampleServer")
    :SetSimple(function(pl)
      pl:ChatPrint("Hello from the SERVER, you pressed [G]!")
    end)
end

-- SHARED
Beans:Assign(KEY_F, "ExampleShared")
  :SetSimple(function(pl)
    if SERVER then
      pl:Kill()
      return
    end

    -- CLIENT
    RunConsoleCommand("say", "Oh no! I pressed [F]...")
  end)
```

```lua
-- you can also disallow usage of the bind in some scenarios
hook.Add("Beans::ShouldDisallow", "AlreadyDead", function(pClient, nButton, sName)
  if sName ~= "ExampleShared" then return end
  if pClient:Alive() then return end

  if SERVER then
    pClient:ChatPrint("No punishment for you this time!")
  else -- CLIENT
    chat.AddText("No punishment because I'm already dead...")
  end

  return true -- to disallow
end)
```
