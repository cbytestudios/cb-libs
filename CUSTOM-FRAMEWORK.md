# v3.0.0 custom framework SDK (release candidate)

This page documents the development contract. It is not a claim of production compatibility.

## Installation
Create a separate resource (for example cb-custom-bridge). Set framework = 'custom', inventory = 'custom', and customBridge = 'cb-custom-bridge' in cb-libs/shared/config.lua. Start your core and inventory, then cb-libs, then the bridge, then the products. Register on the server, not via network events. Restart the bridge after restarting cb-libs.

## Framework registration
Call exports['cb-libs']:RegisterFrameworkAdapter(def). Set apiVersion=1 and name to your framework name. Each method below must be a function. The caller must match customBridge; registration returns true or false and an error message.

| Method | Arguments | Result |
| --- | --- | --- |
| GetPlayerData | source | normalized player table or nil |
| GetIdentifier | source | stable character identifier |
| GetJob | source | job table or nil |
| GetMoney | source, account | number |
| AddMoney | source, account, amount, reason | boolean |
| RemoveMoney | source, account, amount, reason | boolean |
| HasPermission | source, permission | boolean |

The normalized player contains citizenid, charinfo.firstname, charinfo.lastname, job.name, job.label, job.grade.level, job.onduty and money.cash. Return only authorized character data; do not accept client-supplied identity or balance.

## Inventory registration
Call exports['cb-libs']:RegisterInventoryAdapter(def), with apiVersion=1 and all methods below. Methods must enforce ownership, quantity, capacity, metadata and server-side authorization.

| Method | Arguments | Result |
| --- | --- | --- |
| HasItemDefinitions | none | boolean |
| GetItemDefinition | item | definition or nil |
| GetInventory | source | array of item stacks |
| GetItem | source, item, metadata | stack or nil |
| GetItemCount | source, item, metadata | number |
| CanAddItem | source, item, amount, metadata | boolean |
| AddItem | source, item, amount, metadata, reason | boolean |
| RemoveItem | source, item, amount, metadata, reason | boolean |
| RegisterUsableItem | item, callback | boolean |
| OpenStash | source, id, options | boolean |

A stack should contain name, amount, metadata and slot where applicable. Usable callbacks receive source, item name and trusted stack data. Never grant rewards after a failed mutation. Unsupported operations must return false rather than pretend success. Registration is cleared when the bridge stops.

## Runtime
The imported CBLibs.Callback.register and CBLibs.Callback.await methods use a resource-scoped server RPC. Treat all request arguments as untrusted. Authorization must be performed inside each server handler. The library also provides RegisterContext, ShowContext, ShowTextUI, HideTextUI and ProgressBar; ox_lib is used for UI when available. The native fallback is not feature-identical and requires in-game testing.

## Framework integration status
RSG V2, RSG V3 and VORP remain runtime test targets. MULTIcore uses its own RSG compatibility aliases, not a separate Codebyte adapter. RedEM:RP Reboot and TPZ Core adapters are based on upstream revisions 5f171fe and 0eacecf; inventory references are ed5fb0a and 2db8c5b respectively. RedEM/TPZ native camp storage is available with the pinned upstream inventory compatibility patch (see install/native-storage/README.md in cb-libs). It retains native weapon IDs, unique item IDs and metadata. Unpatched servers retain the restricted managed fallback; withdraw fallback contents before switching. Live testing remains required. RedEM capacity checks are restricted to standard items and a readable literal MaxWeight setting. Do not use these adapters in production until inventory, money, permissions, lifecycle and gameplay tests pass.

Upstream: [RedEM](https://github.com/RedEM-RP/redem_roleplay), [RedEM inventory](https://github.com/RedEM-RP/redemrp_inventory), [TPZ Core](https://github.com/TPZ-CORE/tpz_core), [TPZ inventory](https://github.com/TPZ-CORE/tpz_inventory).
