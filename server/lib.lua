-- this is qb-core's implementation of callbacks all credits to them
ServerCallbacks = {}

function CreateCallback(name, cb)
     ServerCallbacks[name] = cb
end

function TriggerCallback(name, source, cb, ...)
     if not ServerCallbacks[name] then return end
     ServerCallbacks[name](source, cb, ...)
end

RegisterNetEvent('Server:TriggerCallback', function(name, ...)
     local src = source
     TriggerCallback(name, src, function(...)
          TriggerClientEvent('Client:TriggerCallback', src, name, ...)
     end, ...)
end)
