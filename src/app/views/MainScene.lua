
local LoginScene = import(".LoginScene")

local MainScene = class("MainScene", cc.load("mvc").ViewBase)
function MainScene:onCreate()
    
    display.newSprite("MainSceneBg.jpg")
        :move(display.center)
        :addTo(self)

    local playButton = cc.MenuItemImage:create("PlayButton.png", "PlayButton.png")
        :onClicked(function()
            self:login_handle()
        end)
    cc.Menu:create(playButton)
        :move(display.cx, display.cy - 200)
        :addTo(self)

    local function editBoxTextEventHandle(event)
        if event.name == "began" then
        elseif event.name == "ended" then
        elseif event.name == "return" then
        elseif event.name == "changed" then
            print(event.target:getText())
        end
    end
    local editBoxSize = cc.size(200, 60)
    local EditName = cc.EditBox:create(editBoxSize, cc.Scale9Sprite:create("green_edit.png"))
    EditName:setPosition(display.center)
    local targetPlatform = cc.Application:getInstance():getTargetPlatform()
    if kTargetIphone == targetPlatform or kTargetIpad == targetPlatform then
        EditName:setFontName("Paint Boy")
    end
    EditName:setFontSize(25)
    EditName:setFontColor(cc.c3b(255,0,0))
    EditName:setPlaceHolder("Name:")
    EditName:setPlaceholderFontColor(cc.c3b(255,255,255))
    EditName:setMaxLength(8)
    EditName:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE )
    EditName:onEditHandler(editBoxTextEventHandle)
    self:addChild(EditName)

end

function MainScene:openGameScene(   )
    LoginScene.new():showWithScene()
end

function MainScene:login_handle(  )
    if self.network_ then
        self.network_:reset_status()
    end
    self.network_:connect()

    local function loginsuccess( )
        self.network_:removeEventListenersByTag(loginsuccess)
        local function resp_callback(args)
            print("************ resp_callback")
            self.player_:login_get_rolelist(args)
            self:openGameScene()
        end
        self:sendRequest("login_get_rolelist", nil, resp_callback)
    end
    self.network_:addEventListener("GAME_AUTH_SUCCESS", loginsuccess, loginsuccess)
end

return MainScene

