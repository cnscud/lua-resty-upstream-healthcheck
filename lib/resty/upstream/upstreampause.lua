-- lua module for pause peer in nginx upstream, work with health check.
--
-- Note: if you don't need health check, you can create a timer by your self, set_peer_down by your code
--
-- @author: Felix Zhang by cnscud@gmail.com
-- @since: 2018/2/1 17:33
--

local tostring = tostring
local pcall = pcall

local _M = {
    _VERSION = '0.01'
}

if not ngx.config
        or not ngx.config.ngx_lua_version
        or ngx.config.ngx_lua_version < 9005
then
    error("ngx_lua 0.9.5+ required")
end

local ok, upstream = pcall(require, "ngx.upstream")
if not ok then
    error("ngx_upstream_lua module required")
end

local shared = ngx.shared
local get_primary_peers = upstream.get_primary_peers
local get_backup_peers = upstream.get_backup_peers


local function gen_peer_key(prefix, u, is_backup, id)
    if is_backup then
        return prefix .. u .. ":b" .. id
    end
    return prefix .. u .. ":p" .. id
end


local function check_mark_peer_pause(dict, ckpeers, pausevalue, u, servername, is_backup)
    if ckpeers then
        local npeers = #ckpeers
        for i = 1, npeers do
            local peer = ckpeers[i]
            if peer.name == servername then
                local key_d = gen_peer_key("pd:", u, is_backup, peer.id)
                local ok, err
                if pausevalue then
                    ok, err = dict:set(key_d, 1) -- 1 = init set , 11 = set and checked
                else
                    ok, err = dict:delete(key_d) -- remove = normal peer
                end

                if not ok then
                    ngx.log(ngx.ERR, "failed set peer pause_status " .. peer.name .. " value: " .. tostring(pausevalue) .. " on upstream " .. u)
                    return -1, "failed on set peer pause_status"
                end

                ngx.log(ngx.ERR, "ok set peer pause_status " .. peer.name .. " value: " .. tostring(pausevalue) .. " on upstream " .. u)
                return 1, "ok on store peer pause_status"
            end
        end
    end
    -- not find the server, will find in next group (backup peers)
    return 0, ""
end

function _M.pause(opts)

    local u = opts.upstream
    if not u then
        return nil, "\"upstream\" option required"
    end

    local server_ip = opts.ip
    if not server_ip then
        return nil, "\"ip\" option required"
    end

    local server_port = opts.port
    if not server_port then
        return nil, "\"port\" option required"
    end

    local tostatus = opts.pause

    local shm = opts.shm
    if not shm then
        return nil, "\"shm\" option required"
    end

    local dict = shared[shm]
    if not dict then
        return nil, "shm \"" .. tostring(shm) .. "\" not found"
    end

    local servername = server_ip .. ":" .. server_port
    local value
    if tostatus == "true" then
        value = true
    end

    local ppeers, err = get_primary_peers(u)
    local ret, err = check_mark_peer_pause(dict, ppeers, value, u, servername, false)
    if ret ~=0 then
        if ret ==1 then
            return true
        else
            return nil, err
        end
    end

    local bpeers, err = get_backup_peers(u)
    local ret, err = check_mark_peer_pause(dict, bpeers, value, u, servername, true)
    if ret ~=0 then
        if ret ==1 then
            return true
        else
            return nil, err
        end
    end

    ngx.log(ngx.ERR, "not find your server" .. servername .. " on upstream " .. u)
    return nil, "not find your server to mark"
end

return _M
