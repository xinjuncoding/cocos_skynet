
local scheduler = cc.Director:getInstance():getScheduler()

local crypt = cryptcore
local proto = require "proto.testproto"
local sproto = require "sproto"
local socket = clientsocket

local host = sproto.new(proto.s2c):host "package"
local request = host:attach(sproto.new(proto.c2s))

local stype = {
	login = 1,
	normal = 2,
}

--[[
	-- 派发消息类型：
	NETWORK_ERROR_CONNECT   : 链接失败(包括登陆验证服和游戏服都是派发此消息)
	LOGIN_AUTH_ERROR		: 登陆验证失败
	NETWORK_ERROR_LOGIN		: 登陆时网络出错
	NETWORK_ERROR_GAME		: 正常游戏网络出错
	GAME_AUTH_ERROR			: 登陆游戏服务器时握手失败
	GAME_AUTH_SUCCESS		: 登陆游戏服务器握手成功

	"REQUEST_"..name 		: 服务端主动推送的消息
	"RESPONSE_"..session	: 客户端对服务器RPC得到的结果
--]]

local last = ""

local ClientSocket = class("ClientSocket")

function ClientSocket:ctor( args )
	self.gamesvr_ip_ 	= "127.0.0.1"-- args.gamesvr_ip 
	self.gamesvr_port_ 	= "8888" -- args.gamesvr_port

	self.fd_ = 0

	cc.bind(self, "event")
end

function ClientSocket:destroy( )
	if self.slcon_sheduler_ then 
		scheduler:unscheduleScriptEntry(self.slcon_sheduler_)
		self.slcon_sheduler_ = nil
	end 
	if self.recv_sheduler_ then 
		scheduler:unscheduleScriptEntry(self.recv_sheduler_)
		self.recv_sheduler_ = nil
	end
end

function ClientSocket:reset_status( )
	self:close()
	self.stype_ = stype.login
	self.login_step_ = 1
end

function ClientSocket:close( )
	socket.close(self.fd_)
	self.fd_ = 0
	self:destroy()
	self.is_close_ = true
	last = ""
end

function ClientSocket:connect( )
	self.is_close_ = false
	self.fd_ = socket.connect(self.gamesvr_ip_, self.gamesvr_port_)

	local function _slcon()
		local ret = socket.slcon(self.fd_)
		if ret <= 0 then 
			scheduler:unscheduleScriptEntry(self.slcon_sheduler_)
			self.slcon_sheduler_ = nil

			if ret == 0 then 
				print("[ClientSocket] 连接成功！")
				self:recv()
				self:dispatchEvent({name="CONNECT_SUCCESS"})
			else 
				print("[ClientSocket] 链接失败")
				self:close()
				self:dispatchEvent({ name = "NETWORK_ERROR_CONNECT"})
			end
		end
	end
	self.slcon_sheduler_ = scheduler:scheduleScriptFunc(_slcon, 0.05, false)
end

function ClientSocket:recv( )
	local function _recv()
		self:dispatch_package()
	end
	self.recv_sheduler_ = scheduler:scheduleScriptFunc(_recv, 0.05, false)
end

function ClientSocket:send_package(pack, session)
	local package
	local size = #pack
	package = string.pack(">H", size)..pack
	
	socket.send(self.fd_, package)
end

function ClientSocket:unpack_package(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s+2 then
		return nil, text
	end

	return text:sub(3,2+s), text:sub(3+s)
end

function ClientSocket:recv_package(last)
	local result
	result, last = self:unpack_package(last)
	if result then
		return result, last
	end
	local ret, r = socket.recv(self.fd_)
	if ret > 0 then
		return nil, last
	end
	if ret < 0 then
		scheduler:unscheduleScriptEntry(self.recv_sheduler_)
		self.recv_sheduler_ = nil
		self:close()

		self:dispatchEvent({name = "NETWORK_ERROR_GAME"})
		error "Server closed"
	end
	return self:unpack_package(last .. r)
end

local session = 0

function ClientSocket:send_request(name, args)
	session = session + 1
	local str = request(name, args, session)

	self:send_package(str, session)
	print("Request:", session)
	return session
end

-- 对服务器做rpc请求
function ClientSocket:sendRequest( name, args, func )
    local session =  self:send_request(name, args)

    if not func then 
    	return
    end
    
    local function resp_callback(event, session, args)
        self:removeEventListenersByTag(session)
    	if not session then 
    		return
    	end
        func(args)
    end
    self:addEventListener("RESPONSE_"..session, resp_callback, session)

    return function() session = nil end
end

-- 侦听服务器同步过来的消息
function ClientSocket:listenServerMsg( name, func )
    local function req_callback(session, args)
        func(args)
    end
    self:addEventListener("REQUEST_"..name, req_callback, req_callback)

    return function() 
        self:removeEventListenersByTag(req_callback)
	end
end

function ClientSocket:print_request(name, args)
	print("REQUEST", name)
	self:dispatchEvent({name = "REQUEST_"..name}, args )
end

function ClientSocket:print_response(session, args)
	print("RESPONSE", session)
	self:dispatchEvent({name = "RESPONSE_"..session}, session, args )
end

function ClientSocket:print_package(t, ...)
	if t == "REQUEST" then
		self:print_request(...)
	else
		assert(t == "RESPONSE")
		self:print_response(...)
	end

	self:sendRequest("handshake")
	self:sendRequest("set", { what = "hello", value = "world" })
end

function ClientSocket:dispatch_package()
	while true do
		if self.is_close_ then 
			break
		end

		local v
		v, last = self:recv_package(last)
		if not v then
			break
		end

		self:print_package(host:dispatch(v))

	end
end

return ClientSocket

