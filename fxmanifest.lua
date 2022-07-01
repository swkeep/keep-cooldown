fx_version 'cerulean'
games { 'gta5' }

author "Swkeep#7049"

shared_scripts {
     'shared/shared.lua',
     'config.lua',
}

client_scripts {
     'client/lib.lua',
     'client/client_main.lua',
}

server_scripts {
     '@oxmysql/lib/MySQL.lua',
     'server/lib.lua',
     'server/server_main.lua',
}

dependency 'oxmysql'

lua54 'yes'
