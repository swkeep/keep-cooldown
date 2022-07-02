local Loaded = false
local interval = 100
local COOLDOWN = {
     cooldowns = {
          ['randomID'] = {
               isOnCooldown = false,
               timer = 0,
               cooldownLength = 0,
               usageCounter = 0,
               playerSource = nil
          }
     }
}

--------------------------
--   class functions
--------------------------
function RandomID(length)
     local string = ''
     for i = 1, length do
          local str = string.char(math.random(97, 122))
          if math.random(1, 2) == 1 then
               if math.random(1, 2) == 1 then str = str:upper() else str = str:lower() end
          else
               str = tostring(math.random(0, 9))
          end
          string = string .. str
     end
     return string
end

local function WaitUntilLoaded()
     repeat Wait(interval) until Loaded == true
end

local function save_cooldown(cooldown_hash, cType, metadata)
     local query = 'INSERT INTO keep_cooldowns (cooldown_hash, type, metadata) VALUES (:cooldown_hash, :type, :metadata) ON DUPLICATE KEY UPDATE metadata = :metadata'
     local data = {
          ['cooldown_hash'] = cooldown_hash,
          ['type'] = cType,
          ['metadata'] = json.encode(metadata),
     }
     MySQL.Async.insert(query, data)
end

local function inject_from_database(data)
     for _, _cooldown in ipairs(data) do
          local metadata = json.decode(_cooldown.metadata)
          COOLDOWN.cooldowns[_cooldown.cooldown_hash] = {
               isOnCooldown = metadata.isOnCooldown,
               timer = tonumber(metadata.timer),
               cooldownLength = tonumber(metadata.cooldownLength),
               usageCounter = tonumber(metadata.usageCounter),
               cType = cTypes[_cooldown.type]
          }
     end
end

local function fetch_cooldowns()
     local res = MySQL.Sync.fetchAll('SELECT * FROM keep_cooldowns', {})
     inject_from_database(res)
     Loaded = true
     print(Colors.green .. string.format('successfully loaded %d cooldowns', #res))
end

------------------
--    class
------------------
---make a new cooldown
function COOLDOWN:add(o)
     local ID = nil
     if type(o.cType) ~= "string" then
          print(Colors.red 'cType must be a string')
          return nil
     end

     -- id cooldownLength, cType
     if not o.id then
          ID = RandomID(20)
     elseif not (cTypes[o.cType] == 1 or cTypes[o.cType] == 3) then
          ID = RandomID(20)
     else
          ID = o.id
     end

     if self.cooldowns[ID] and next(self.cooldowns[ID]) ~= nil then return ID, true end
     self.cooldowns[ID] = {
          isOnCooldown = false,
          timer = 0,
          cooldownLength = o.cooldownLength,
          usageCounter = 0,
          cType = o.cType
     }

     if o.id and cTypes[o.cType] ~= nil then
          -- save persistent types
          if cTypes[o.cType] == 1 or cTypes[o.cType] == 3 then
               save_cooldown(ID, cTypes[o.cType], self.cooldowns[ID])
          end
     elseif o.id and cTypes[o.cType] == nil then
          print(Colors.red .. 'Failed to insert cooldown: missing cooldown type')
     end
     return ID, false
end

---set value of cooldown to it's cooldownLength
---@param ID any
---@return boolean
function COOLDOWN:setOnCooldown(ID)
     if self.cooldowns[ID] then
          self.cooldowns[ID].isOnCooldown = true
          self.cooldowns[ID].timer = self.cooldowns[ID].cooldownLength
          self.cooldowns[ID].usageCounter = self.cooldowns[ID].usageCounter + 1
          if Config.StateChange.Client_side then
               TriggerClientEvent('keep-cooldown:client:cooldownStateChange', -1, self.cooldowns[ID].isOnCooldown, ID)
          end
          if Config.StateChange.Server_side then
               TriggerEvent('keep-cooldown:server:cooldownStateChange', self.cooldowns[ID].isOnCooldown, ID)
          end
          return true
     end
     return false
end

--- reset cooldown's usage
---@param ID any
function COOLDOWN:resetCooldownUsage(ID)
     if self.cooldowns[ID] then
          self.cooldowns[ID].usageCounter = 0
          return true
     end
     return false
end

--- removes a cooldown from runtime
---@param ID any
function COOLDOWN:remove(ID)
     if self.cooldowns[ID] then
          self.cooldowns[ID] = nil
          return true
     end
     return false
end

-- check cooldown state
function COOLDOWN:isOnCooldown(ID)
     if self.cooldowns[ID] then
          return self.cooldowns[ID].isOnCooldown, self.cooldowns[ID].timer
     end
     return nil, nil
end

-- list of all active cooldowns
function COOLDOWN:listAll()
     return self.cooldowns
end

-- flush all active cooldowns
function COOLDOWN:flushAll()
     self.cooldowns = {}
end

-- count active cooldowns
function COOLDOWN:activeCooldowns()
     local count = 0
     for _ in pairs(self.cooldowns) do count = count + 1 end
     return count
end

--------------------------
--   functions
--------------------------

local function Cooldown_logic(DATA, ID)
     if DATA.timer == nil then DATA.timer = 0 return end
     if DATA.timer > 0 then
          DATA.timer = DATA.timer - 1
          return
     else
          DATA.timer = 0
     end

     if DATA.timer == 0 and DATA.isOnCooldown == false then
          return
     elseif DATA.timer == 0 and DATA.isOnCooldown == true then
          DATA.isOnCooldown = false
          if Config.StateChange.Client_side then
               TriggerClientEvent('keep-cooldown:client:cooldownStateChange', -1, DATA.isOnCooldown, ID)
          end
          if Config.StateChange.Server_side then
               TriggerEvent('keep-cooldown:server:cooldownStateChange', DATA.isOnCooldown, ID)
          end
          return
     end
end

------------------
--    Threads
------------------

Citizen.CreateThread(function()
     COOLDOWN:flushAll()
     fetch_cooldowns()
     WaitUntilLoaded()
     while true do
          for ID, DATA in pairs(COOLDOWN:listAll()) do
               Cooldown_logic(DATA, ID)
          end
          Wait(1000)
     end
end)

------------------
--    events
------------------

AddEventHandler('onResourceStop', function(resourceName)
     if (GetCurrentResourceName() ~= resourceName) then return end

     for ID, DATA in pairs(COOLDOWN:listAll()) do
          local cType = cTypes[DATA.cType]
          if cType ~= nil then
               -- save persistent types
               if cType == 1 or cType == 3 then
                    save_cooldown(ID, cType, DATA)
               end
          end
     end
end)

--------------------------------
--    client-side callbacks
--------------------------------

CreateCallback('keep-cooldown:server:addCooldown', function(source, cb, o)
     if not o then o = {} end
     local id = o.id or RandomID(20)
     local cooldownLength = o.cooldownLength or 10
     local cType = o.cType
     if not cType then
          cType = 'user-server-temporary'
     end

     local ID, doExist = COOLDOWN:add({
          id = id,
          cooldownLength = cooldownLength,
          cType = cType
     })
     cb({ ID, doExist })
end)

CreateCallback('keep-cooldown:server:isOnCooldown', function(source, cb, id)
     if not id then cb({ nil, nil }) end
     local state, timer = COOLDOWN:isOnCooldown(id)
     cb({ state, timer })
end)

CreateCallback('keep-cooldown:server:setOnCooldown', function(source, cb, id)
     if not id then cb(nil) end
     cb(COOLDOWN:setOnCooldown(id))
end)

CreateCallback('keep-cooldown:server:resetCooldownUsage', function(source, cb, id)
     if not id then cb(nil) end
     cb(COOLDOWN:resetCooldownUsage(id))
end)

CreateCallback('keep-cooldown:server:remove', function(source, cb, id)
     if not id then cb(nil) end
     cb(COOLDOWN:remove(id))
end)
--------------------------------------
--    serve-side/exports+wrapper
--------------------------------------
local CD = {}

function CD.add(o)
     return COOLDOWN:add(o)
end

function CD.remove(id)
     return COOLDOWN:remove(id)
end

function CD.setOnCooldown(id)
     return COOLDOWN:setOnCooldown(id)
end

function CD.isOnCooldown(id)
     return COOLDOWN:isOnCooldown(id)
end

function CD.resetCooldownUsage(id)
     return COOLDOWN:resetCooldownUsage(id)
end

function CD.countActiveCooldowns()
     return COOLDOWN:activeCooldowns()
end

exports('CD', function()
     return CD
end)
