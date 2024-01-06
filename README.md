# Beans
Garry's Mod binding library for SERVER and CLIENT

# Usage
```lua
local coolPhrase = "Looooool!"

if SERVER then
  Beans:Assign(KEY_G, "DropSomeCoolPhraseInChat", function(pl)
    pl:Say(coolPhrase)
  end, 2)
else -- CLIENT
  Beans:Assign(KEY_G, "DropSomeCoolPhraseInChat", function()
    RunConsoleCommand("say", coolPhrase)
  end, 2)
end

-- it also can be shared
Beans:Assign(KEY_F, "yes, it is shared!", function(pl)
  if SERVER then
    pl:Say(coolPhrase)
    return
  end

  -- CLIENT
  RunConsoleCommand("say", coolPhrase)
end, 2)
```

```lua
-- you can also disallow usage of the bind in some scenarios
hook.Add("Beans::ShouldDisallow", "DeadManIsNotCool", function(pClient, nButton, sName)
  if sName ~= "DropSomeCoolPhraseInChat" then return end
  if pClient:Alive() then return end

  local msg = "You are dead :("
  if SERVER then
    pClient:ChatPrint(msg)
  else
    chat.AddText(msg)
  end

  return true -- to disallow
end)
```
