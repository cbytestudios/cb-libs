fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'cb-libs'
author 'Codebyte Studios'
description 'Shared framework adapter and compatibility API for Codebyte RedM resources'
version '3.0.0'

shared_scripts {
    'shared/config.lua',
    'bridge/providers.lua',
}

server_scripts {
    'server/adapters/*.lua',
    'server/inventory.lua',
    'server/main.lua',
}

client_scripts {
    'imports/init.lua',
    'client/interactions.lua',
    'client/main.lua',
}
files {
    'imports/init.lua',
}

escrow_ignore {
    'shared/config.lua',
    'install/native-storage/*',
}
