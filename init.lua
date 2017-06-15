local ffi = require "ffi"
local C = ffi.C

ffi.cdef[[
int gethostname(char *name, size_t len);
]]

local size = 50
local buf = ffi.new("unsigned char[?]", size)

local redis_server_list = {
        [0] = {
                ip = "192.168.9.236",
                port = 2500,
                },
        [1] = {
                ip = "192.168.9.236",
                port = 2501,
                },
        [2] = {
                ip = "192.168.9.236",
                port = 2502,
                },
        [3] = {
                ip = "192.168.9.236",
                port = 2503,
                },
        [4] = {
                ip = "192.168.9.236",
                port = 2504,
                },
        [5] = {
                ip = "192.168.9.236",
                port = 2505,
                },
        [6] = {
                ip = "192.168.9.236",
                port = 2506,
                },
}

local res = C.gethostname(buf, size)
if res == 0 then
    local hostname = ffi.string(buf, size)

    local host = string.gsub(hostname, "%z+$", "")

    local server_index = tonumber(string.sub(host,-2, -1))
    local s_server_index = string.sub(host,-2, -1)
    ngx.shared["server_index"] = s_server_index
    ngx.shared["redis"]={
                ip = redis_server_list[server_index%3].ip,
                port = redis_server_list[server_index%3].port,
        }
local ffi=require("ffi")
local qos=ffi.load("/lib64/libconnlimit.so")
ffi.cdef("int clear_used_token_list(char*);")

local index_c_str = ffi.new("char[?]", #s_server_index)
ffi.copy(index_c_str, s_server_index)

local ret = qos.clear_used_token_list(index_c_str)
if ret == 0 then
ngx.log(ngx.ERR,"clean token for : %s failed",index_c_str)
end
end
