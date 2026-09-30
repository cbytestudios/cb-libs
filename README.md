+# CB Libs

CB Libs lets Codebyte resources work with RSG, VORP, or TPZ without framework-specific setup in each resource.

## Install

1. Install one supported framework and its inventory: RSG + `rsg-inventory`, VORP + `vorp_inventory`, or TPZ + `tpz_inventory`.
2. Place `cb-libs` in your resources folder.
3. Start resources in this order:

```cfg
ensure <framework>
ensure <inventory>
ensure cb-libs
ensure ox_lib
ensure oxmysql
```

CB Libs detects the started framework and inventory automatically. If more than one supported framework is running, select the framework and inventory in `shared/config.lua`.

## Custom framework

Set the framework and inventory to `custom` in `shared/config.lua`, then enable and add your bridge functions in `server/custom.lua`.
