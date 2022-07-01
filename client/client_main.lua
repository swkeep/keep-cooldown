local CD = {}

local function callback(name, ...)
     local timeout = 0
     local res = nil
     TriggerCallback(name, function(result)
          res = result
     end, ...)
     repeat
          timeout = timeout + 1
          Wait(100)
     until res ~= nil and timeout < 15 -- 1.5sec
     return res
end

function CD.add(o)
     local res = callback('keep-cooldown:server:addCooldown', o)
     return res[1], res[2]
end

function CD.isOnCooldown(id)
     local res = callback('keep-cooldown:server:isOnCooldown', id)
     return res[1], res[2]
end

function CD.setOnCooldown(id)
     return callback('keep-cooldown:server:setOnCooldown', id)
end

function CD.resetCooldownUsage(id)
     return callback('keep-cooldown:server:resetCooldownUsage', id)
end

function CD.remove(id)
     return callback('keep-cooldown:server:remove', id)
end

exports('CD', function()
     return CD
end)
