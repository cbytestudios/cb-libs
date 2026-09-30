# CB Libs

`cb-libs` is the framework bridge shared by Codebyte RedM resources. It follows
the resource-first import style of jo_libs while exposing a small, stable
`CBLibs` API.

## Supported frameworks

Auto-detection supports RSG, QBR, VORP, RedEM, RedEM:Reboot, and GUM. `custom`
is available for proprietary frameworks. Detection is based on a started core
resource, rather than a hard-coded value in every CB script.

If multiple cores are running, the first framework in
`CBLibsConfig.detectionPriority` wins and cb-libs logs every detected core. Set
`CBLibsConfig.framework` explicitly in that situation.

## Installation

Start the framework before cb-libs, then the CB resources:

~~~cfg
ensure rsg-core
ensure cb-libs
ensure cb-wilderness
~~~

In every dependent resource, add the dependency and import the initiator:

~~~lua
dependency 'cb-libs'

shared_scripts {
    '@cb-libs/init.lua'
}
~~~

`@cb-libs/shared/import.lua` remains supported for existing resources.

## API

Server: `CBLibs.GetFramework`, `GetDetectedFrameworks`, `GetPlayer`,
`GetIdentifier`, `GetJob`, `GetMoney`, `AddMoney`, `RemoveMoney`, and
`HasPermission`.

Client: `CBLibs.GetFramework`, `GetDetectedFrameworks`, `Notify`, and
`Progress`.
