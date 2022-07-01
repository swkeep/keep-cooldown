# keep-cooldown

- A small fivem resource to make server-side cooldowns
- check wiki for more information

# example

```lua
-- client-side
local CD = exports["keep-cooldown"]:CD()

local cd_id =
    CD.add(
    {
        id = "keep_blackmarket_payphone" .. PlayerPedId(),
        cooldownLength = 30,
        cType = "temporary" -- or persistent
    }
)

local state, remaining = CD.isOnCooldown(cd_id)

if state then
    print("on CD " .. remaining)
    return
end

if not state then
    CD.setOnCooldown(cd_id)
end
```

```lua
--server-side
local CD = exports["keep-cooldown"]:CD()

local cd_id =
    CD.add(
    {
        id = "keep_blackmarket_payphone_2",
        cooldownLength = 30,
        cType = "persistent" -- or persistent
    }
)

local state, remaining = CD.isOnCooldown(cd_id)
print(state, remaining)
if state then
    print("on CD " .. remaining)
    return
end

if not state then
    CD.setOnCooldown(cd_id)
end

state, remaining = CD.isOnCooldown(cd_id)
print(state, remaining)

```
