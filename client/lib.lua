-- this is qb-core's implementation of callbacks all credits to them
ServerCallbacks = {}

function TriggerCallback(name, cb, ...)
     ServerCallbacks[name] = cb
     TriggerServerEvent('Server:TriggerCallback', name, ...)
end

RegisterNetEvent('Client:TriggerCallback', function(name, ...)
     if ServerCallbacks[name] then
          ServerCallbacks[name](...)
          ServerCallbacks[name] = nil
     end
end)
