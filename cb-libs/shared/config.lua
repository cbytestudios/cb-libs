CBLibsConfig = {
    -- Use 'auto' for RSG, VORP, or TPZ. Use 'custom' to enable the framework
    -- handlers in server/custom.lua.
    framework = 'auto',

    -- Inventories are detected independently. Use 'custom' to enable the
    -- inventory handlers in server/custom.lua.
    inventory = 'auto',

    -- Auto uses the detected framework's notification system.
    -- Manual overrides: bln, ox_lib, rsg, vorp, tpz, or none.
    notifications = 'auto',
}
