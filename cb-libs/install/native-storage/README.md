# Native storage compatibility (v3.0.0 candidate)

Codebyte uses native storage for RSG and VORP. MULTIcore uses its own RSG compatibility exports. For RedEM:RP Reboot and TPZ Core, install the Codebyte native storage compatibility patch into your **editable upstream inventory resource** to enable its native inventory UI, weapons, unique items and metadata.

## Supported upstream revisions

- RedEM redemrp_inventory: ed5fb0a2cabfb780e2b4eefa239c68323a34a2fc
- TPZ tpz_inventory: 2db8c5bb83b23e9d7784844fd264818edd4fd3d1

The patch installer verifies the normalized source file SHA-256 and refuses unknown or already modified versions. Do not overwrite a customized inventory file. Contact your inventory developer for a port to another revision.

## Installation

Stop the server and back up the inventory resource and database. With Python 3.12 or compatible Python 3 installed, run from the cb-libs resource directory:

~~~sh
python install/native-storage/apply-native-storage.py redem /path/to/redemrp_inventory
python install/native-storage/apply-native-storage.py tpz /path/to/tpz_inventory
~~~

Run only the command for your installed provider. The TPZ path must point to the actual resource folder containing fxmanifest.lua, not its containing Git repository. The installer creates a .codebyte-original backup next to the changed Lua file. Restart your inventory, cb-libs and Codebyte resources in that order, preferably by restarting the server. The patch is applied to your own inventory files, not to protected Codebyte files.

## How it works

The library grants access only to the calling resource's named stash, scoped to the character, with an authorization callback rechecked at every protected native read/transfer. Wilderness rechecks camp membership, proximity and enabled module state. The native patch rejects alternate network mutations of Codebyte containers and uses server-owned item metadata and capacity. Native TPZ transfers move the actual item row, preserving weapon and unique item IDs rather than generating replacements. Different metadata on the same TPZ stack cannot be merged; move the existing stack elsewhere first.

RedEM uses the upstream item/weapon transfer functions. Native save behavior and persistence remain those of the installed inventory; crash consistency and interactions with other inventory resources must be tested. The patch protects only the reserved cb-secure namespace, not unrelated inventory endpoints.

Without the patch, Wilderness retains the ordinary-stack managed storage fallback. Existing fallback contents are not silently migrated; withdraw them before switching to the native stash. An interrupted ambiguous fallback transfer requires administrator reconciliation. Native storage is a release candidate: application and mocked tests passed against the pinned sources; live testing of the inventory interface, reconnects, persistence, weapons, metadata, capacity and adversarial access is required.

## Developer API

Server exports: HasNativeStash() returns whether the active RedEM/TPZ inventory reports native patch API v1. OpenStash(source, id, options) accepts label, slots, weight in grams, acceptWeapons, and authorize(source,id). The authorize callback is mandatory for patched RedEM/TPZ and must return true only when the current character may use the stash. Never expose OpenStash as an unrestricted network event. Resource-owned stash IDs are namespaced by the library. CanAccessNativeStash is an internal inventory integration export and is not a public authorization bypass.
