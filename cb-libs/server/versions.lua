local defaultUrl = 'https://raw.githubusercontent.com/cbytestudios/cb-libs/main/versions.json'
local versionUrl = GetConvar('cb-libs:versionUrl', defaultUrl)
local checksEnabled = GetConvarInt('cb-libs:checkUpdates', 1) == 1
local debugEnabled = GetConvarInt('cb-libs:versionDebug', 0) == 1
local cacheSeconds = math.max(300, GetConvarInt('cb-libs:versionCacheSeconds', 3600))
local maximumBodyBytes = 65536

local state = {
    installed = {},
    alerted = {},
    warned = {},
    catalog = nil,
    fetchedAt = 0,
    fetching = false,
    scheduled = false,
    refreshRequested = false,
    manualRequested = false,
    retryUsed = false,
}

local function parseVersion(raw)
    if type(raw) ~= 'string' then return nil end

    local major, minor, patch = raw:match('^v?(%d+)%.(%d+)%.(%d+)$')
    major, minor, patch = tonumber(major), tonumber(minor), tonumber(patch)

    if not major or not minor or not patch then return nil end
    if major > 1000000 or minor > 1000000 or patch > 1000000 then return nil end

    return { major = major, minor = minor, patch = patch, text = ('%d.%d.%d'):format(major, minor, patch) }
end

local function compareVersions(left, right)
    if left.major ~= right.major then return left.major < right.major and -1 or 1 end
    if left.minor ~= right.minor then return left.minor < right.minor and -1 or 1 end
    if left.patch ~= right.patch then return left.patch < right.patch and -1 or 1 end
    return 0
end

local function warnOnce(key, message)
    if state.warned[key] then return end

    state.warned[key] = true
    print(('^3[cb-libs]^7 Version check unavailable: %s'):format(message))
end

local function isCodebyteResource(resource)
    if type(resource) ~= 'string' or not resource:match('^cb%-%l[%l%d%-]*$') then return false end
    local author = GetResourceMetadata(resource, 'author', 0)
    return type(author) == 'string' and author:find('Codebyte Studios', 1, true) == 1
end

local function readInstalled(resource)
    if not isCodebyteResource(resource) then return nil end

    local raw = GetResourceMetadata(resource, 'version', 0)
    local version = parseVersion(raw)

    if not version then
        warnOnce('manifest:' .. resource, ('%s has an invalid manifest version.'):format(resource))
        return nil
    end

    return { name = resource, version = version }
end

local function parseCatalog(body)
    if type(body) ~= 'string' or #body == 0 or #body > maximumBodyBytes then
        return nil, 'the catalog response size was invalid'
    end

    local ok, decoded = pcall(json.decode, body)
    if not ok or type(decoded) ~= 'table' or decoded.schema ~= 1 or type(decoded.resources) ~= 'table' then
        return nil, 'the catalog JSON was invalid'
    end

    local resources = {}
    for name, entry in pairs(decoded.resources) do
        if type(name) ~= 'string' or not name:match('^cb%-%l[%l%d%-]*$') or type(entry) ~= 'table' then
            return nil, 'the catalog contained an invalid resource entry'
        end

        local version = parseVersion(entry.version)

        if not version then
            return nil, ('the catalog version for %s was invalid'):format(name)
        end

        local url = entry.url

        if url ~= nil and (type(url) ~= 'string' or #url > 500 or not url:match('^https://')) then
            return nil, ('the catalog URL for %s was invalid'):format(name)
        end

        resources[name] = { version = version, url = url }
    end

    return { resources = resources }
end

local function reconcile(resource)
    if not state.catalog then return 0 end

    local outdated = 0

    local function check(installed)
        local latest = state.catalog.resources[installed.name]
        if not latest or compareVersions(installed.version, latest.version) >= 0 then return end

        outdated = outdated + 1

        local key = ('%s|%s|%s'):format(installed.name, installed.version.text, latest.version.text)
        if state.alerted[key] then return end

        state.alerted[key] = true
        print(('^3[%s]^7 Update available: installed v%s, latest v%s.%s'):format(
            installed.name,
            installed.version.text,
            latest.version.text,
            latest.url and (' Download: ' .. latest.url) or ''
        ))
    end

    if resource then
        local installed = state.installed[resource]
        if installed then check(installed) end
    else
        for _, installed in pairs(state.installed) do check(installed) end
    end

    return outdated
end

local fetchCatalog
local function finishRequest()
    state.fetching = false
    if not state.refreshRequested then return end

    local manual = state.manualRequested
    state.refreshRequested = false
    state.manualRequested = false
    fetchCatalog(true, manual)
end

fetchCatalog = function(force, manual)
    if not checksEnabled and not manual then return end
    if not versionUrl:match('^https://') then
        warnOnce('url', 'cb-libs:versionUrl must use HTTPS.')
        return
    end
    if state.fetching then
        state.refreshRequested = state.refreshRequested or force
        state.manualRequested = state.manualRequested or manual
        return
    end
    if not force and state.catalog and os.time() - state.fetchedAt < cacheSeconds then
        reconcile()
        return
    end

    state.fetching = true
    PerformHttpRequest(versionUrl, function(status, body, _, errorData)
        status = tonumber(status) or 0
        if status == 200 then
            local catalog, parseError = parseCatalog(body)
            if catalog then
                state.catalog = catalog
                state.fetchedAt = os.time()
                state.retryUsed = false
                local outdated = reconcile()

                if manual and outdated == 0 then
                    print('^2[cb-libs]^7 All registered Codebyte resources are up to date.')
                end
            else
                warnOnce('catalog', parseError)
            end
            finishRequest()
            return
        end

        if (status == 0 or status >= 500) and not state.retryUsed then
            state.fetching = false
            state.retryUsed = true
            SetTimeout(30000, function() fetchCatalog(true, manual) end)
            return
        end

        local detail = status > 0 and ('GitHub returned HTTP %d'):format(status) or tostring(errorData or 'network error')
        state.retryUsed = false
        warnOnce('http:' .. status, detail)
        finishRequest()
    end, 'GET', '', {
        ['Accept'] = 'application/json',
        ['User-Agent'] = 'cb-libs-version-check',
    })
end

local function register(resource)
    local installed = readInstalled(resource)
    if not installed then return false end

    state.installed[resource] = installed

    if not checksEnabled then return true end
    if state.catalog and os.time() - state.fetchedAt < cacheSeconds then
        reconcile(resource)
    elseif not state.scheduled then
        state.scheduled = true
        SetTimeout(2000, function()
            state.scheduled = false
            fetchCatalog(false, false)
        end)
    end
    return true
end

exports('RegisterVersionCheck', function()
    return register(GetInvokingResource() or GetCurrentResourceName())
end)

RegisterCommand('cbversions', function(source)
    if source ~= 0 then return end
    fetchCatalog(true, true)
end, false)

CreateThread(function()
    Wait(0)
    for index = 0, GetNumResources() - 1 do
        local resource = GetResourceByFindIndex(index)
        if resource and GetResourceState(resource) == 'started' then register(resource) end
    end
    if debugEnabled then
        print(('^5[cb-libs]^7 Version checks enabled for %d registered resource(s).'):format(
            (function()
                local count = 0
                for _ in pairs(state.installed) do count = count + 1 end
                return count
            end)()
        ))
    end
end)
