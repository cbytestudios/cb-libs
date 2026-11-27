local resource = GetCurrentResourceName()

if rawget(_G, '__cbStartupPrinted') then return end
rawset(_G, '__cbStartupPrinted', true)

local version = GetResourceMetadata(resource, 'version', 0) or 'unknown'
print(('^2[%s]^7 v%s started.^7'):format(resource, version))

exports['cb-libs']:RegisterVersionCheck()
