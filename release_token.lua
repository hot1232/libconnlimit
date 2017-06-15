local function split(str,delimiter)
    if str==nil or str=='' or delimiter==nil then
        return nil
    end

    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end


local ffi=require("ffi")
local qos=ffi.load("/lib64/libconnlimit.so")
ffi.cdef("int release_token(char*,char*);")

local server_index = ngx.shared["server_index"]
local index_c_str = ffi.new("char[?]", #server_index)
ffi.copy(index_c_str, server_index)

local uri_temp = split(ngx.var.request_uri,"?")
local uri = uri_temp[1]
local uri_c_str = ffi.new("char[?]", #uri)
ffi.copy(uri_c_str, uri)

ngx.log(ngx.ERR,"ready to release token for uri: ",uri)
local ret = qos.release_token(index_c_str,uri_c_str)
if ret == 0 then
	ngx.log(ngx.ERR,"release token for : ",uri," failed")
end
ngx.log(ngx.ERR,"ready to release token for uri: ",uri," over")
return