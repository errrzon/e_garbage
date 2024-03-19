fx_version 'cerulean'
name 'Garbage job'
author 'erzn'
game 'gta5'
lua54 'yes'

server_scripts {
    'server/main.lua'
}
shared_scripts {
    'config.lua'
}
client_scripts {
    'client/npc.lua',
    'client/main.lua',
}

shared_scripts {
    '@ox_lib/init.lua',
}
