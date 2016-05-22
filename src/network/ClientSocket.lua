
local scheduler = cc.Director:getInstance():getScheduler()

local crypt = cryptcore
local proto = require "proto.proto"
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
	self.login_ip_ 	 	= args.login_ip 
	self.login_port_ 	= args.login_port
	self.gamesvr_ip_ 	= args.gamesvr_ip 
	self.gamesvr_port_ 	= args.gamesvr_port

	self.server_name_ 	= args.server_name
	self.user_ 			= args.user
	self.passwd_ 		= args.passwd

	self.stype_ = stype.login  -- 用作登陆的(1),还是链接到游戏服务器的(2)
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
	if self.stype_ == stype.normal then 
		self.is_auth_ = false
		self.fd_ = socket.connect(self.gamesvr_ip_, self.gamesvr_port_)
	elseif self.stype_ == stype.login then 
		self.fd_ = socket.connect(self.login_ip_, self.login_port_)
	end

	local function _slcon()
		local ret = socket.slcon(self.fd_)
		if ret <= 0 then 
			scheduler:unscheduleScriptEntry(self.slcon_sheduler_)
			self.slcon_sheduler_ = nil

			if ret == 0 then 
				print("[ClientSocket] 连接成功！")
				if self.stype_ == stype.normal then 
					self:send_server_auth()
				end
				self:recv()
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
		if self.stype_ == stype.login then 
			self:login_package()
		elseif self.stype_ == stype.normal then 
			self:dispatch_package()
		end
	end
	self.recv_sheduler_ = scheduler:scheduleScriptFunc(_recv, 0.05, false)
end

function ClientSocket:login_send( pack )
	socket.send(self.fd_, pack .. "\n")
end

function ClientSocket:login_logic( msg )
	if not self.login_step_ then 
		self.login_step_ = 1
	end

	if self.login_step_ == 1 then 
		self.challenge_ = crypt.base64decode(msg)
		self.clientkey_ = crypt.randomkey()
		self:login_send(crypt.base64encode(crypt.dhexchange(self.clientkey_)))

	elseif self.login_step_ == 2 then 
		self.secret_ = crypt.dhsecret(crypt.base64decode(msg), self.clientkey_)
		self.hmac_ = crypt.hmac64(self.challenge_, self.secret_)
		self:login_send(crypt.base64encode(self.hmac_))

		self.token_ = {
			server 	= self.server_name_,
			user 	= self.user_,
			pass 	= self.passwd_,
		}

		local function encode_token(token)
			return string.format("%s@%s:%s",
				crypt.base64encode(token.user),
				crypt.base64encode(token.server),
				crypt.base64encode(token.pass))
		end

		local etoken = crypt.desencode(self.secret_, encode_token(self.token_))
		local b = crypt.base64encode(etoken)
		self:login_send(crypt.base64encode(etoken))

	elseif self.login_step_ == 3 then 
		local code = tonumber(string.sub(msg, 1, 3))
		self:close()
		if code == 200 then 
			self.subid_ = crypt.base64decode(string.sub(msg, 5))
			print("*** 登陆成功:", self.subid_)
			self.stype_ = stype.normal
			self:connect()
		else 
			print("*** 登陆失败, error:", msg)
			self.login_step_ = 0  -- 重置登陆步骤
			self:dispatchEvent({name = "LOGIN_AUTH_ERROR"}, msg)
		end
	end

	self.login_step_ = self.login_step_ + 1
end

function ClientSocket:login_unpack( last )
	local from = last:find("\n", 1, true)
	if from then
		return last:sub(1, from-1), last:sub(from+1)
	end
	return nil, last
end

function ClientSocket:login_recv( last )
	local result
	result, last = self:login_unpack(last)
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
		self.login_step_ = 1  -- 重置登陆步骤
		self:dispatchEvent({name = "NETWORK_ERROR_LOGIN"})
		error "Server closed"
	end
	return self:login_unpack(last .. r)
end

function ClientSocket:login_package()
	while true do
		if self.is_close_ then 
			break
		end

		local v
		v, last = self:login_recv(last)
		if not v then
			break
		end

		self:login_logic(v)
	end
end

function ClientSocket:send_server_auth( )
	if not self.index_ then 
		self.index_ = 0
	end
	self.index_ = self.index_ + 1
	local handshake = string.format("%s@%s#%s:%d", crypt.base64encode(self.token_.user), crypt.base64encode(self.token_.server),crypt.base64encode(self.subid_) , self.index_)
	local hmac = crypt.hmac64(crypt.hashkey(handshake), self.secret_)
	self:send_package(handshake .. ":" .. crypt.base64encode(hmac))
end

function ClientSocket:send_package(pack, session)
	-- local size = #pack
	-- local package = string.char(bit32.extract(size,8,8)) ..
	-- 	string.char(bit32.extract(size,0,8))..
	-- 	pack

	local package
	local size = #pack
	if session then 
		size = size + 4
		package = string.pack(">H", size)..pack..string.pack(">I", session)
	else 
		package = string.pack(">H", size)..pack
	end 
	
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
	print("====REQUEST", name)
	self:dispatchEvent({name = "REQUEST_"..name}, args )
end

function ClientSocket:print_response(session, args)
	print("=====RESPONSE", session)
	self:dispatchEvent({name = "RESPONSE_"..session}, session, args )
end

function ClientSocket:print_package(t, ...)
	if t == "REQUEST" then
		self:print_request(...)
	else
		assert(t == "RESPONSE")
		self:print_response(...)
	end
end

local function recv_response(v)
	local content = v:sub(1,-6)

	local size = #v - 5
	local ok = string.unpack(v.sub(size,1), ">p")
	local session = string.unpack(v.sub(size,4), ">I")

	return ok ~=0 , content, session
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

		if self.is_auth_ then 
			local isok, content, session = recv_response(v)
			if isok then 
				self:print_package(host:dispatch(content))
			else 
				print("********************* error:", content, session)
			end
		else
			local code = tonumber(string.sub(v, 1, 3))
			if code == 200 then 
				self.is_auth_ = true
				print("登陆server成功")
				self:dispatchEvent({name = "GAME_AUTH_SUCCESS"})
			else 
				print("********* 验证失败! 原因:", v)
				self:close()
				self:dispatchEvent({name = "GAME_AUTH_ERROR"}, v)
			end
		end

	end
end

return ClientSocket

