# CB Libs

`cb-libs` is the framework bridge shared by Codebyte RedM resources. It exposes
a stable `CBLibs` API for the integrations Codebyte resources need.

## Supported frameworks

Auto-detection supports RSG, VORP, and TPZ. `custom` is available for a private
framework. Detection is based on a started core resource, rather than a
hard-coded value in every CB script.

If multiple cores are running, cb-libs uses its built-in priority and logs every
detected core. The detection registry lives in `bridge/providers.lua`; it is
internal bridge code, not part of `shared/config.lua`.

## Inventory bridge

Inventory detection is independent of framework detection. The bridge detects
RSG Inventory, VORP Inventory, and TPZ Inventory. All three have dedicated
adapters:

~~~lua
CBLibs.GetInventoryProvider()
CBLibs.GetItemCount(source, 'water')
CBLibs.HasItem(source, 'water', 2)
CBLibs.CanAddItem(source, 'water', 1)
CBLibs.AddItem(source, 'water', 1, { quality = 'fresh' }, 'fishing reward')
CBLibs.RemoveItem(source, 'water', 1)
CBLibs.RegisterUsableItem('bandage', function(source, item) end)
CBLibs.OpenStash(source, 'camp_stash', { label = 'Camp Stash', slots = 20, weight = 40000 })
~~~

TPZ's official inventory API does not provide a public create/open-stash
operation. Add that server-specific UI flow in `server/custom.lua` only if your
server needs it.

## TPZ API mapping

TPZ is detected from `tpz_core` and `tpz_inventory`. CB Libs uses TPZ's official
`getCoreAPI()` player object (`GetPlayer`, character identifier, name, job,
grade, and account methods) and `getInventoryAPI()` methods (`getItemQuantity`,
`canCarryItem`, `addItem`, `removeItem`, `getItemData`, and
`registerUsableItem`). No TPZ API names appear in Codebyte resources.

## Configuration and custom hooks

`shared/config.lua` contains only three optional overrides: `framework`,
`inventory`, and `notifications`. Leave them as `auto` for standard resources;
set a provider name only when a server uses a renamed/non-standard resource.

`server/custom.lua` is the server-only extension point for a private framework
or inventory. Both files are listed in `escrow_ignore`, so server owners can
edit them when cb-libs is escrowed.

## Installation

Start the framework and its inventory first. `cb-libs` must start after both,
then start the shared dependencies and Codebyte resources:

~~~cfg
ensure rsg-core
ensure rsg-inventory
ensure cb-libs
ensure ox_lib
ensure oxmysql
ensure cb-wilderness
~~~

Replace `rsg-core` and `rsg-inventory` with the framework and inventory your
server uses (`vorp_core` / `vorp_inventory` or `tpz_core` / `tpz_inventory`).
The required order is always:

1. Framework
2. Inventory
3. `cb-libs`
4. `ox_lib`
5. `oxmysql`
6. Codebyte resources

TPZ's own inventory lists `tpz_characters` as a prerequisite, so its practical
startup sequence is `tpz_core` → `tpz_characters` → `tpz_inventory` →
`cb-libs`.

In every dependent resource, add the dependency and import the initiator:

~~~lua
dependency 'cb-libs'

shared_scripts {
    '@cb-libs/imports/init.lua'
}
~~~

There is one public entry point: `@cb-libs/imports/init.lua`.

## API

Server: `CBLibs.GetFramework`, `GetDetectedFrameworks`, `GetPlayer`,
`GetIdentifier`, `GetJob`, `GetMoney`, `AddMoney`, `RemoveMoney`, and
`HasPermission`; plus `GetInventoryProvider`, `GetDetectedInventories`,
`GetInventory`, `GetItem`, `GetItemCount`, `HasItem`, `CanAddItem`, `AddItem`,
`RemoveItem`, `RegisterUsableItem`, `OpenStash`, `CanAfford`, and `CanUseItem`.

Client: `CBLibs.GetFramework`, `GetDetectedFrameworks`, `Notify`, and
`Progress`.

`Notify` automatically uses `bln_notify` when it is started. Set
`CBLibsConfig.notifications = 'bln'` to require it. Its default title and
placement are `Codebyte` and `middle-right`; each notification can override
both fields.
