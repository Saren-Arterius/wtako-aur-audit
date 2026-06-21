-- yay init.lua with AUR audit API
local json = require("json")
local API = "https://aur-audit.wtako.net/package-analysis?names="
local level = yay.opt.aur_audit_filter or "black"
local all_warnings, RECENT = {}, 1782000000

local function sanitize(names)
    return (names:lower():gsub("[^0-9a-z,_-]", ""))
end

local function get_audit(names)
    names = sanitize(names)
    if #names == 0 then return {} end

    local handle = io.popen("curl -s --max-time 3 " .. API .. names)
    if not handle then return {} end

    local response = handle:read("*a")
    handle:close()

    local ok, data = pcall(json.decode, response)
    return ok and data and data.packages or {}
end

local function warn(a, name)
    local lines = {}
    for _, f in ipairs(a.blackFlags or {}) do
        table.insert(lines, "\027[5m☠️ [DANGEROUS]\027[0m " .. name .. ": " .. f)
    end
    for _, f in ipairs(a.redFlags or {}) do
        table.insert(lines, "\027[5m🔴\027[0m " .. name .. ": " .. f)
    end
    for _, f in ipairs(a.yellowFlags or {}) do
        table.insert(lines, "🟡 " .. name .. ": " .. f)
    end
    if #lines > 0 then
        table.insert(all_warnings, table.concat(lines, "\n"))
    end
end

local function hint(msg)
    table.insert(all_warnings, "❓ " .. msg)
end

local function check(a, name)
    warn(a, name)
    if a.status ~= "scanned" then
        hint(name .. ": " .. (a.status or "Scanning"))
    end
end

local function flush_warnings()
    if #all_warnings == 0 then
        return
    end

    math.randomseed(os.time())
    local tmp_secure = string.format("/tmp/yay-audit-%d-%d.txt", os.time(), math.random(10000, 99999))

    local f = io.open(tmp_secure, "w")
    if not f then return end

    f:write(
        "\033[2K\r========== ⚠️  AUR AUDIT by wtako.net ⚠️  ==========\n",
        table.concat(all_warnings, "\n"),
        "\n==================================================\n==> "
    )
    f:close()
    all_warnings = {}

    local cmd = string.format("sleep 0.1 && cat %s >&2 && rm -f %s &", tmp_secure, tmp_secure)
    os.execute(cmd)
end

local function skip(a, lvl)
    local black_cnt = a.blackFlags and #a.blackFlags or 0
    local red_cnt = a.redFlags and #a.redFlags or 0
    local yellow_cnt = a.yellowFlags and #a.yellowFlags or 0

    return (lvl == "black" and black_cnt > 0)
        or (lvl == "red" and (black_cnt > 0 or red_cnt > 0))
        or (lvl == "yellow" and (black_cnt > 0 or red_cnt > 0 or yellow_cnt > 0))
end

yay.create_autocmd("UpgradeSelect", {
    desc = "exclude flagged packages",
    callback = function(e)
        local excl = {}
        local names = {}

        -- Fixed: Gather all package names first to execute ONE batch query
        for _, pkg in ipairs(e.data.upgrades) do
            if pkg.repository == "aur" then
                names[#names + 1] = pkg.name
            end
        end

        local audits = get_audit(table.concat(names, ","))

        for _, pkg in ipairs(e.data.upgrades) do
            if pkg.repository == "aur" then
                local a = audits[pkg.name]
                if a then
                    check(a, pkg.name)
                    if skip(a, level) then
                        excl[#excl + 1] = pkg.name
                    end
                elseif pkg.last_modified > RECENT then
                    hint(pkg.name .. ": No data")
                end
            end
        end
        flush_warnings()
        return { exclude = excl, skip_menu = false }
    end,
})

yay.create_autocmd("SearchFilter", {
    desc = "filter flagged packages",
    callback = function(e)
        if level == "none" then
            return nil
        end
        local names = {}
        for _, r in ipairs(e.data.results) do
            if r.source == "aur" then
                names[#names + 1] = r.name
            end
        end
        local audits, out = get_audit(table.concat(names, ",")), {}
        for _, r in ipairs(e.data.results) do
            local a = audits[r.name]
            if r.source ~= "aur" or not a or not skip(a, level) then
                out[#out + 1] = { source = r.source, name = r.name }
                if a then
                    check(a, r.name)
                elseif r.last_modified > RECENT then
                    hint(r.name .. ": No data")
                end
            end
        end
        flush_warnings()
        return out
    end,
})

yay.create_autocmd("AURPreInstall", {
    desc = "block flagged packages",
    callback = function(e)
        local a = get_audit(e.match)[e.match]
        if a then
            check(a, e.match)
        elseif e.data.last_modified > RECENT then
            hint(e.match .. ": No data")
        end
        flush_warnings()
        if a and skip(a, level) then
            yay.abort(e.match .. ": flagged")
        end
    end,
})
