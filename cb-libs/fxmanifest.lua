fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'cb-libs'
author 'Codebyte Studios'
description 'Shared framework adapter and compatibility API for Codebyte RedM resources'
version '0.3.0'

escrow_ignore {
    'shared/config.lua',
    'server/custom.lua',
}

shared_scripts {
    'shared/config.lua',
    'bridge/providers.lua',
}

server_scripts {
    'server/custom.lua',
    'server/adapters/*.lua',
    'server/inventory.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

-- Public import file for dependent resources:
-- shared_script '@cb-libs/imports/init.lua'
files {
    'imports/init.lua',
}

escrow_ignore {
    'shared/config.lua',
    'server/custom.lua',
}

