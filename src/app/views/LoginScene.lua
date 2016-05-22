
local GameScene = import(".GameScene")


local LoginScene = class("LoginScene", cc.load("mvc").ViewBase)

function LoginScene:onCreate( )
    display.newSprite("MainSceneBg.jpg")
        :move(display.center)
        :addTo(self)

    self.select_player_ = nil
    self:init_role_list()

    local function touchEvent(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            self:create_role()
        end
    end         
    local button = ccui.Button:create()
    button:setTouchEnabled(true)
    button:setScale9Enabled(true)
    button:loadTextures("button_n.png", "button_p.png", "")
    button:setPosition(display.cx-180, display.cy-100)
    button:setContentSize(cc.size(150, button:getVirtualRendererSize().height * 1.5))
    button:addTouchEventListener(touchEvent)
    button:setTitleText("创建角色")
    button:setTitleFontSize(20)
    self:addChild(button)


    local function touchEvent(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            
        end
    end         
    local button = ccui.Button:create()
    button:setTouchEnabled(true)
    button:setScale9Enabled(true)
    button:loadTextures("button_n.png", "button_p.png", "")
    button:setPosition(display.cx+180, display.cy-100)
    button:setContentSize(cc.size(150, button:getVirtualRendererSize().height * 1.5))
    button:addTouchEventListener(touchEvent)
    button:setTitleText("删除角色")
    button:setTitleFontSize(20)
    self:addChild(button)

    local function touchEvent(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            self:login_login()
        end
    end         
    local button = ccui.Button:create()
    button:setTouchEnabled(true)
    button:setScale9Enabled(true)
    button:loadTextures("button_n.png", "button_p.png", "")
    button:setPosition(display.cx, display.cy-100)
    button:setContentSize(cc.size(100, 100))
    button:addTouchEventListener(touchEvent)
    button:setTitleText("登陆")
    button:setTitleFontSize(20)
    self:addChild(button)
end

function LoginScene:init_role_list(  )
    cc.MenuItemFont:setFontName("Arial")
    cc.MenuItemFont:setFontSize(24)

	local list = {}
	for k,v in pairs(self.player_.role_list_) do 
        self.select_player_ = v
	    local function menuCallback(tag,pMenuItem)
	        if nil ~= pMenuItem then
                self.select_player_ = v
	        end
	    end
	    local pMenuItem = cc.MenuItemFont:create(v.player_name)
	    pMenuItem:registerScriptTapHandler(menuCallback)
	    table.insert(list, pMenuItem)
	end

    local pMenu = cc.Menu:create(unpack(list))
    pMenu:alignItemsVertically()
    local fX = math.random() * 50
    local fY = math.random() * 50
    local menuPosX ,menuPosY = pMenu:getPosition()
    pMenu:setPosition(display.cx,display.cy+250)
    self:addChild(pMenu)
end

-- 选择角色之后登陆
-- 1、先让服务端加载这个角色的数据
-- 2、然后再去rpc请求这些数据到前端
-- 3、获取到数据之后前端开始加载场景
-- 4、加载完场景之后再rpc请求服务端进入场景
-- 5、开始进入aoi同步消息逻辑
function LoginScene:login_login(  )
    if not self.select_player_ then 
        return
    end

    local player_id = self.select_player_.player_id
    self:load_player_info(player_id)
end

function LoginScene:load_player_info( player_id )
    if not player_id then 
        return 
    end

    local function resp_callback( args )
        if args.result == 0 then 
            self:get_player_info()
        end
    end
    self:sendRequest("login_load_playerinfo", {player_id = player_id}, resp_callback)
    print("[请求服务端加载玩家数据......]")
end

function LoginScene:get_player_info(  )
    local function resp_callback(args)
        self.player_:init_playerinfo( args )
        GameScene.new():showWithScene()
    end
    self:sendRequest("login_get_player_info", nil, resp_callback)
    print("[rpc请求服务端玩家数据......]")
end

-- 创建角色
function LoginScene:create_role(  )
    local data = {
        player_name = "test101",
        job         = 1,
    }

    local function resp_callback( args )
        if args.result > 0 then 
            -- 创建成功
            self.player_.player_id_ = args.result
            -- 创建角色成功之后让后端加载数据
            self:load_player_info(self.player_.player_id_)
        else 
            -- 创建失败
        end
    end
    self:sendRequest("login_create_role", data, resp_callback)
end


return LoginScene

