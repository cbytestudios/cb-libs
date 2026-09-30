CBLibsConfig = {
    -- Supported values: 'auto', 'rsg', 'qbr', 'vorp', 'redem',
    -- 'redemreboot', 'gum', and 'custom'. Set explicitly if more than one
    -- supported core is started.
    framework = 'auto',

    -- The first detected framework wins. Change this only when a server
    -- intentionally runs multiple compatibility cores.
    detectionPriority = { 'rsg', 'qbr', 'vorp', 'redemreboot', 'redem', 'gum' },

    -- Extend these lists if a framework resource has been renamed.
    frameworkResources = {
        rsg = { 'rsg-core' },
        qbr = { 'qbr-core' },
        vorp = { 'vorp_core' },
        redem = { 'redemrp' },
        redemreboot = { 'redem_roleplay', 'redemrp_reboot' },
        gum = { 'gum_core', 'gum-core' },
    },

    -- Set to the resource exporting GetCoreObject for your GUM distribution.
    gumCoreResource = 'gum_core',

    -- For a proprietary framework use framework = 'custom' and add adapter
    -- functions here (GetPlayer, GetIdentifier, GetJob, GetMoney, AddMoney,
    -- RemoveMoney, and HasPermission).
    custom = {},

    -- Client notification provider: 'auto', 'ox_lib', 'rsg', 'qbr', 'vorp', or 'none'.
    notifications = 'auto',
}
