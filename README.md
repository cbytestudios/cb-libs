# CB Libs

CB Libs is the shared compatibility API used by Codebyte RedM resources. It
supports RSG, VORP, and TPZ without requiring customers to select a framework or
inventory in the config.

## Automatic detection

The included config is already set to `auto` for framework, inventory, and
notifications. CB Libs detects these official resource names at startup:

| Framework | Core resource | Inventory resource | Notifications |
| --- | --- | --- | --- |
| RSG | `rsg-core` | `rsg-inventory` | RSG Core |
| VORP | `vorp_core` | `vorp_inventory` | VORP Core |
| TPZ | `tpz_core` | `tpz_inventory` | TPZ Core |

No config edit is needed for these combinations. When more than one supported
provider is running, CB Libs logs what it found and uses the built-in priority:
RSG, then VORP, then TPZ.

## Install

1. Install one supported framework and its inventory.
2. Place `cb-libs` in your resources folder.
3. Start the framework and inventory before `cb-libs`, then start scripts that
   import CB Libs after it.

RSG example:

```cfg
ensure rsg-core
ensure rsg-inventory
ensure cb-libs
```

VORP example:

```cfg
ensure vorp_core
ensure vorp_inventory
ensure cb-libs
```

TPZ example:

```cfg
ensure tpz_core
ensure tpz_inventory
ensure cb-libs
```

Framework dependencies such as `ox_lib` and `oxmysql` should follow that
framework's own installation instructions. They are not additional CB Libs
configuration choices.

## Use in another resource

Add the import after any other shared dependencies:

```lua
shared_script '@cb-libs/imports/init.lua'
```

Server example:

```lua
local player = CBLibs.GetPlayer(source)
local hasItem = CBLibs.HasItem(source, 'water', 1)
local added = CBLibs.AddItem(source, 'water', 1)
```

Client notification example:

```lua
CBLibs.Notify({
    title = 'Codebyte',
    description = 'The action completed.',
    type = 'success',
    duration = 4000,
})
```

With `notifications = 'auto'`, that call uses the notification API belonging to
the automatically detected framework. Optional `bln` and `ox_lib` overrides
remain available for servers that explicitly want them.

Target interactions are automatic too. CB Libs uses `ox_target` when it is
running and otherwise supplies a built-in RedM proximity interaction fallback.
Individual Codebyte scripts do not need a target setting.

## Custom frameworks and inventories

For an unsupported framework, set `framework = 'custom'` in
`shared/config.lua`. For an unsupported inventory, set `inventory = 'custom'`.
These settings are independent, so a server can use a supported framework with
a custom inventory or the reverse.

Implement the corresponding handlers in `server/custom.lua`. Both files are
included in `escrow_ignore`, and no separate `enabled` setting is required.
