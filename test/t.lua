local ffi=require("ffi")
local qos=ffi.load("libqos.so")
ffi.cdef("int release_token(char*,char*);")
local qos=ffi.load("libqos.so")
local server_index = "22"
local index_c_str = ffi.new("char[?]", #server_index)
ffi.copy(index_c_str, server_index)

local uri = "/"
local uri_c_str = ffi.new("char[?]", #uri)
ffi.copy(uri_c_str, uri)

local ret = qos.release_token(index_c_str,uri_c_str)
print("ret is: ",ret)

local function split(str,delimiter)
    if str==nil or str=='' or delimiter==nil then
        return nil
    end

    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
        print(result,match)
    end
    return result
end


local uri_temp = "/a/b/c?d=1"
local uri = split(uri_temp,"?")
print(uri[1])
