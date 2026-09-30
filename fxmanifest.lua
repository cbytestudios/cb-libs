fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'cb-libs'
author 'Codebyte Studios'
description 'Shared framework adapter and compatibility API for Codebyte RedM resources'
version '0.2.0'

shared_scripts {
    'shared/config.lua',
    'shared/api.lua',
    'init.lua',
}

server_scripts {
    'server/adapters/rsg.lua',
    'server/adapters/qbr.lua',
    'server/adapters/vorp.lua',
    'server/adapters/redem.lua',
    'server/adapters/gum.lua',
    'server/adapters/custom.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

exports {
    'GetFramework',
    'GetDetectedFrameworks',
    'Notify',
    'Progress',
}

server_exports {
    'GetFramework',
    'GetDetectedFrameworks',
    'GetPlayer',
    'GetIdentifier',
    'GetJob',
    'GetMoney',
    'AddMoney',
    'RemoveMoney',
    'HasPermission',
}
