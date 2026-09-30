# CB Libs capability boundary

CB Libs is a stable integration boundary for Codebyte resources. The following
capabilities are implemented and supported by this resource:

| Capability | CB Libs API | Providers |
| --- | --- | --- |
| Framework selection | `GetFramework`, `GetDetectedFrameworks` | RSG, VORP, TPZ, custom |
| Server player/economy | `GetPlayer`, `GetIdentifier`, `GetJob`, `GetMoney`, `AddMoney`, `RemoveMoney`, `HasPermission`, `CanAfford` | framework adapters |
| Client feedback | `Notify`, `Progress` | BLN Notify, ox_lib, RSG, VORP, TPZ |
| Inventory selection | `GetInventoryProvider`, `GetDetectedInventories` | RSG, VORP, TPZ, custom |
| Inventory operations | `GetInventory`, `GetItem`, `GetItemCount`, `HasItem`, `CanAddItem`, `AddItem`, `RemoveItem`, `CanUseItem`, `RegisterUsableItem`, `OpenStash` | RSG, VORP, TPZ, custom |

RSG uses its `GetItemCount`, `CanAddItem`, `AddItem`, `RemoveItem`,
`GetItemsByName`, and stash export surface. VORP uses `getItemCount`,
`canCarryItem`, `addItem`, `subItem`, and `registerUsableItem`. TPZ uses its
official `getInventoryAPI()` object for item count, carry checks, add/remove,
item data, and usable items.

## Explicit non-goals

CB Libs currently does not include general-purpose menus, cameras, entities,
prompts, NUI, or database wrappers. Those should remain resource-specific or be
added later as separate, tested CB modules.

## Provider safety

TPZ does not publish a create/open-stash API; `OpenStash` therefore delegates to
the optional `server/custom.lua` hook when TPZ is active.
