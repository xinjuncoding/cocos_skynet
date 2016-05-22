
local ClientSocket 	= require("network.ClientSocket")
local PlayerModel 	= require("app.models.PlayerModel")

local ClientSocketde  = require("network.ClientSocketde")
local GameApp = class("GameApp", cc.load("mvc").AppBase)

function GameApp:onCreate()
	rawset(_G, self.__cname, self)

    math.randomseed(os.time())

    local args = {
        login_ip = "127.0.0.1",     -- 登陆服的地址
        login_port = 8001,          -- 登陆服的端口
        gamesvr_ip  = "127.0.0.1",  -- 游戏服的地址
        gamesvr_port = 9001,        -- 游戏服的端口

        server_name = "gate_name1", -- 游戏服名称
        user    = "test101",        -- 用户ID
        passwd  = "password",       -- 密码（或者是第三方平台返回的token）
    }

    self.network_ 	= ClientSocket.new(args)
    self.player_ 	= PlayerModel.new()

    local network = ClientSocketde.new()
    network:connect()
end

return GameApp
