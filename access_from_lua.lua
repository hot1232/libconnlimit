local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

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

local function close_redis(red)
    if not red then
        return
    end
    --释放连接(连接池实现)
    local pool_max_idle_time = 100 --毫秒
    local pool_size = 100 --连接池大小
    local ok, err = red:set_keepalive(pool_max_idle_time, pool_size)
    if not ok then
        ngx.log(ngx.ERR,"set keepalive error : ", err)
    end
end


local uri_temp = split(ngx.var.request_uri,"?")
local uri = uri_temp[1]

local redis = require("resty.redis")

--创建实例
local red = redis:new()
--设置超时（毫秒）
red:set_timeout(100)
--建立连接
local redis_ip_ip = "192.168.9.236"
local redis_ip_port = 2500
local ok, err = red:connect(redis_ip_ip, redis_ip_port)
--red:select(20)
if not ok then
    ngx.log(ngx.ERR,"connect to redis error : ", err)
    return close_redis(red)
end

local red2 = redis:new()
red2:set_timeout(200)
local redis_uri_ip = "192.168.9.236"
local redis_uri_port = 2501
local ok1, err1 = red2:connect(redis_uri_ip, redis_uri_port)
if not ok1 then
    ngx.log(ngx.ERR,"connect to redis uri error : ", err1)
    return close_redis(red2)
end


local remote_addr = ngx.var.remote_addr
local x_forward_for = ngx.var.http_x_forwarded_for
if x_forward_for ~= nil then
	remote_addr = split(x_forward_for,",")[1]
end

local b_key = string.format("blocked:%s",remote_addr)
local blacklist,err_ip = red:get(b_key)
if not blacklist then
    ngx.log(ngx.ERR,"get data from redis uri err: ",err_ip)
    return
end
close_redis(red)
if blacklist ~= ngx.null then
	ngx.exit(ngx.HTTP_CREATED)
end

local b_key2 = string.format("blocked:%s",uri)
local uriblacklist,err_uri = red2:get(b_key2)
if not uriblacklist then
    ngx.log(ngx.ERR,"get data from redis uri err: ",err_uri)
    return
end
close_redis(red2)
if uriblacklist ~= ngx.null then
	ngx.log(ngx.INFO,"uri reject: ",uriblacklist)
	ngx.exit(ngx.HTTP_CREATED)
end

--url限流操作
ngx.log(ngx.ERR,"start qos: ",uri)

local red3 = redis:new()
red3:set_timeout(200)
local redis_uriqos_ip = "192.168.9.236"
local redis_uriqos_port = 2502
local ok2, err2 = red3:connect(redis_uriqos_ip, redis_uriqos_port)
if not ok2 then
    ngx.log(ngx.ERR,"connect to redis uri error : ", err2)
    return close_redis(red3)
end

local uri_config_key = string.format("qos:config:%s",uri)
ngx.log(ngx.ERR,"uri config key: ",uri_config_key)
ok2 = nil
err2 = nil
ok2,err2 = red3:exists(uri_config_key)
if not ok then
    ngx.log(ngx.ERR,"check uri qos config failed: ",err);
    return
end

ngx.log(ngx.ERR,"exists config key: ",ok2)
if ok2 == 0 then
    ngx.log(ngx.ERR,"config key: ",uri," not exists")
    close_redis(red3)
    return
end

local uriqos_idle = string.format("qos:%s:idle",uri)
local uriqos_used = string.format("qos:%s:%s:used",uri,ngx.shared["server_index"])

local ok3,err3 = red3:lpop(uriqos_idle)
ngx.log(ngx.ERR,"get token: ",ok3," err: ",err3)
if ok3 == ngx.null then
    ngx.log(ngx.ERR,"get token failed, close connection")
	close_redis(red3)
	ngx.exit(ngx.HTTP_CREATED)
    return
else
   
end

local ok4,err4 = red3:lpush(uriqos_used,ngx.shared["server_index"])
if not ok then
    ngx.log(ngx.ERR,"push token for uri: %s failed, error: %s",ngx.var.request_uri,err)
    return
end

close_redis(red3)
return
