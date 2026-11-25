CBLibsConfig = {
    -- Use 'auto', 'rsg', 'vorp', 'redem', 'tpz', or 'custom'.
    framework = 'auto',
    -- For a custom framework set framework = 'custom' and name your trusted bridge.
    customBridge = nil,

    -- Inventories are detected independently: 'auto', 'rsg', 'vorp', 'redem', 'tpz', or 'custom'.
    inventory = 'auto',

    -- Auto uses the detected framework's notification system.
    -- Manual overrides: bln, ox_lib, rsg, vorp, redem, tpz, or none.
    notifications = 'auto',
}
