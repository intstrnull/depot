-- ================================================
-- ANTI-HTTP-SPY (2026) – Works before OR after spy loads
-- Uses hookfunction swap to extract spy hooks as L closures,
-- then reads their upvalues to recover true originals
-- ================================================
if getgenv().Loaded then return end
getgenv().Loaded = true

local HttpService = game:GetService("HttpService")

local detected = false

local ts = game:GetService("TweenService")

function log(msg)
    warn("[ANTI-SPY] " .. msg)
end

local deb = false

function punishment()
    if not deb then deb = true else return end
    loadstring(game:HttpGet(("https://raw.githubusercontent.com/intstrnull/depot/refs/heads/main/punish.lua")))()
end

-- ============================================
-- 1. CLONE hookfunction/hookmetamethod FOR INTERNAL USE
-- ============================================

local realHookFunction = clonefunction(hookfunction)
local realHookMetamethod = clonefunction(hookmetamethod)

-- ============================================
-- 2. RECOVER ORIGINALS
--    Detection: only islclosure check (no false positives)
--    Protection: clonefunction + hookfunction bypass (works even without detection)
--    __namecall: hookmetamethod swap + islclosure check
-- ============================================

local originals = {}
local HTTP_METHODS = { HttpGet = true, HttpPost = true, GetAsync = true, PostAsync = true, RequestAsync = true }

-- Collect all upvalue functions from fn (including inside tables), recursively
function deepCollect(fn, visited, depth)
    local found = {}
    if depth > 6 or not fn or type(fn) ~= "function" then return found end
    if visited[fn] then return found end
    visited[fn] = true

    local function process(v)
        if type(v) == "function" then
            found[v] = true
            for f in pairs(deepCollect(v, visited, depth + 1)) do
                found[f] = true
            end
        elseif type(v) == "table" and depth < 4 then
            for _, tv in pairs(v) do
                if type(tv) == "function" then
                    found[tv] = true
                    for f in pairs(deepCollect(tv, visited, depth + 2)) do
                        found[f] = true
                    end
                end
            end
        end
    end

    pcall(function()
        local ups = getupvalues(fn)
        if ups then for _, v in pairs(ups) do process(v) end end
    end)

    pcall(function()
        for i = 1, 50 do
            local a, b = getupvalue(fn, i)
            if a == nil and b == nil then break end
            process(a)
            if b ~= nil then process(b) end
        end
    end)

    pcall(function()
        for i = 1, 50 do
            local name, val = debug.getupvalue(fn, i)
            if not name then break end
            process(val)
        end
    end)

    return found
end

function recoverOriginal(fn, name)
    if not fn then return nil, false end

    local hooked = false

    -- Detection: L closure where C expected = DEFINITELY hooked
    if islclosure(fn) then
        hooked = true
        log("Detected L closure hook on " .. name)
    end

    -- Try getoriginalfunction first (some executors provide this)
    local restored
    pcall(function() restored = getoriginalfunction(fn) end)
    if restored and type(restored) == "function" and iscclosure(restored) then
        if hooked then log("Recovered " .. name .. " via getoriginalfunction") end
        pcall(function() realHookFunction(fn, restored) end)
        return restored, hooked
    end

    -- hookfunction swap: get the previous handler
    local dummy = newcclosure(function() end)
    local prev
    pcall(function() prev = realHookFunction(fn, dummy) end)

    if not prev then
        pcall(function() realHookFunction(fn, fn) end)
        local fb
        pcall(function() fb = clonefunction(fn) end)
        return fb, hooked
    end

    -- If prev is L closure = spy's hook (even if fn appeared C, hookfunction reveals it)
    if islclosure(prev) then
        hooked = true
        log("Detected hook on " .. name .. " (L closure from hookfunction)")

        -- Dig into spy's upvalues for the real C closure original
        local allFns = deepCollect(prev, {}, 0)
        for f in pairs(allFns) do
            if iscclosure(f) then
                log("Recovered " .. name .. " from spy upvalues")
                realHookFunction(fn, f)
                return f, true
            end
        end

        -- Couldn't find in upvalues, use clonefunction
        local cl
        pcall(function() cl = clonefunction(prev) end)
        if cl and iscclosure(cl) then
            realHookFunction(fn, cl)
            return cl, true
        end

        -- Last resort: put prev back, clone fn
        realHookFunction(fn, prev)
        local fb
        pcall(function() fb = clonefunction(fn) end)
        return fb or prev, true
    end

    -- prev is C closure = either the real original OR a hookfunction bypass
    -- Either way it's safe to use as our "original" - restore and return
    realHookFunction(fn, prev)
    return prev, hooked
end

-- Recover originals for all protected methods
local anyHooked = false

local instanceMethods = {
    { game.HttpGet,             "HttpGet",      "game.HttpGet" },
    { game.HttpPost,            "HttpPost",     "game.HttpPost" },
    { HttpService.GetAsync,     "GetAsync",     "HttpService.GetAsync" },
    { HttpService.PostAsync,    "PostAsync",    "HttpService.PostAsync" },
    { HttpService.RequestAsync, "RequestAsync", "HttpService.RequestAsync" },
}

for _, m in ipairs(instanceMethods) do
    local orig, hooked = recoverOriginal(m[1], m[3])
    originals[m[2]] = orig
    if hooked then anyHooked = true end
end

-- Global request functions
local globalFns = {
    { request,                       "request",          "request" },
    { http_request,                  "http_request",     "http_request" },
    { http and http.request,         "http_dot_request", "http.request" },
    { syn and syn.request,           "syn_request",      "syn.request" },
}

for _, g in ipairs(globalFns) do
    if g[1] then
        local orig, hooked = recoverOriginal(g[1], g[3])
        originals[g[2]] = orig
        if hooked then anyHooked = true end
    end
end

-- Replace globals with recovered originals
pcall(function() if originals.request and request then getgenv().request = originals.request end end)
pcall(function() if originals.http_request and http_request then getgenv().http_request = originals.http_request end end)
pcall(function() if originals.http_dot_request and http then http.request = originals.http_dot_request end end)
pcall(function() if originals.syn_request and syn then syn.request = originals.syn_request end end)

-- ============================================
-- 2b. DETECT AND RECOVER __namecall HOOKS
--     hookmetamethod swap: check if prev is L closure = spy hook
-- ============================================

local rawMt
pcall(function() rawMt = getrawmetatable(game) end)

local originalNc

-- Swap __namecall with dummy to pull out current handler
local ncDummy = newcclosure(function(self, ...) return nil end)
local prevNc
pcall(function() prevNc = realHookMetamethod(game, "__namecall", ncDummy) end)

if prevNc then
    if islclosure(prevNc) then
        -- L closure = spy's hook on __namecall
        anyHooked = true
        log("Detected spy hook on __namecall")

        -- Try to find original C closure in spy's upvalues
        local allFns = deepCollect(prevNc, {}, 0)
        for f in pairs(allFns) do
            if iscclosure(f) then
                originalNc = f
                log("Recovered original __namecall from spy upvalues")
                break
            end
        end

        if not originalNc then
            -- Fallback: clone the spy's handler (gets underlying fn)
            pcall(function() originalNc = clonefunction(prevNc) end)
            if not originalNc then originalNc = prevNc end
        end
    else
        -- C closure = not hooked (or hookmetamethod bypass, same thing)
        originalNc = prevNc
    end
else
    -- hookmetamethod failed, read from raw metatable
    pcall(function() originalNc = rawMt.__namecall end)
end

if anyHooked then
    detected = true
    log("HTTP SPY DETECTED - hooks neutralized")
    punishment()
end

-- ============================================
-- 2c. GC CLEANUP
--     Clears spy request log tables to prevent leaked URLs
-- ============================================

function cleanupSpyData()
	pcall(function()
		for _, obj in pairs(getgc(true)) do
			if type(obj) == "table" then
				pcall(function()
					local first = rawget(obj, 1)
					if type(first) == "table" then
						local url = rawget(first, "Url") or rawget(first, "url")
						local method = rawget(first, "Method") or rawget(first, "method")
						if type(url) == "string" and type(method) == "string" then
							for i = #obj, 1, -1 do rawset(obj, i, nil) end
						end
					end
				end)
			end
		end
	end)
end

-- Clear spy data on load (fixes leaked loadstring URLs)
cleanupSpyData()

-- Background cleanup loop
task.spawn(function()
	while task.wait(3) do
		cleanupSpyData()
	end
end)

-- ============================================
-- 3. INSTALL __namecall HANDLER
--    Routes HTTP methods to recovered originals.
--    Non-HTTP calls pass to original __namecall.
-- ============================================

local ncHandler = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if HTTP_METHODS[method] and originals[method] then
        return originals[method](self, ...)
    end
    if originalNc then
        return originalNc(self, ...)
    end
end)

pcall(function() realHookMetamethod(game, "__namecall", ncHandler) end)

pcall(function()
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    mt.__namecall = ncHandler
    setreadonly(mt, true)
end)

-- ============================================
-- 4. RESTORE FUNCTION (for future detections)
-- ============================================

function restoreAll()
    log("Restoring original functions...")

    pcall(function() if originals.HttpGet then realHookFunction(game.HttpGet, originals.HttpGet) end end)
    pcall(function() if originals.HttpPost then realHookFunction(game.HttpPost, originals.HttpPost) end end)
    pcall(function() if originals.GetAsync then realHookFunction(HttpService.GetAsync, originals.GetAsync) end end)
    pcall(function() if originals.PostAsync then realHookFunction(HttpService.PostAsync, originals.PostAsync) end end)
    pcall(function() if originals.RequestAsync then realHookFunction(HttpService.RequestAsync, originals.RequestAsync) end end)

    pcall(function() if originals.request and request then realHookFunction(request, originals.request) end end)
    pcall(function() if originals.http_request and http_request then realHookFunction(http_request, originals.http_request) end end)
    pcall(function() if originals.http_dot_request and http and http.request then realHookFunction(http.request, originals.http_dot_request) end end)
    pcall(function() if originals.syn_request and syn and syn.request then realHookFunction(syn.request, originals.syn_request) end end)

    log("All functions restored.")
end

-- ============================================
-- 5. PROACTIVE INTERCEPTION: Block future hooks on HTTP functions
-- ============================================

function isProtectedFunction(fn)
    if not fn or type(fn) ~= "function" then return false end
    if fn == game.HttpGet or fn == game.HttpPost then return true end
    if fn == HttpService.GetAsync or fn == HttpService.PostAsync or fn == HttpService.RequestAsync then return true end
    if request and fn == request then return true end
    if http_request and fn == http_request then return true end
    if http and http.request and fn == http.request then return true end
    if syn and syn.request and fn == syn.request then return true end
    return false
end

-- Block hookfunction on protected methods
realHookFunction(hookfunction, newcclosure(function(target, hook)
    if isProtectedFunction(target) then
        log("BLOCKED hookfunction attempt on HTTP function")
        detected = true
        punishment()
        return target
    end
    return realHookFunction(target, hook)
end))

-- Wrap hookmetamethod: any __namecall hook gets wrapped so HTTP methods still use originals
realHookFunction(hookmetamethod, newcclosure(function(obj, method, hook)
    if obj == game and method == "__namecall" and type(hook) == "function" then
        local actualHook = hook
        return realHookMetamethod(obj, method, newcclosure(function(self, ...)
            local m = getnamecallmethod()
            if HTTP_METHODS[m] and originals[m] then
                return originals[m](self, ...)
            end
            return actualHook(self, ...)
        end))
    end
    return realHookMetamethod(obj, method, hook)
end))

-- ============================================
-- 6. SAFE REQUEST WRAPPERS
-- ============================================

local safeRequestFn = originals.request or originals.http_request or originals.syn_request or originals.http_dot_request

function safePost(url, body, headers)
    if not safeRequestFn then
        warn("[ANTI-SPY] No safe request function available")
        return nil, 0
    end
    headers = headers or { ["Content-Type"] = "application/json" }
    local ok, response = pcall(safeRequestFn, {
        Url = url,
        Method = "POST",
        Headers = headers,
        Body = body,
    })
    if ok and response then return response.Body, response.StatusCode end
    warn("[ANTI-SPY] safePost failed: " .. tostring(response))
    return nil, 0
end

function safeGet(url, headers)
    if not safeRequestFn then return nil, 0 end
    headers = headers or {}
    local ok, response = pcall(safeRequestFn, {
        Url = url,
        Method = "GET",
        Headers = headers,
    })
    if ok and response then return response.Body, response.StatusCode end
    return nil, 0
end

getgenv().safePost = safePost
getgenv().safeGet = safeGet

log("Loaded - full protection active")
log("Use safePost / safeGet for requests that bypass any hooks")
