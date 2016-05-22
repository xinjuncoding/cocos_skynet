
local ViewBase = class("ViewBase", cc.Node)

function ViewBase:ctor()
    self:enableNodeEvents()
    self.app_ = GameApp
    self.network_   = self.app_.network_
    self.player_    = self.app_.player_

    -- check CSB resource file
    local res = rawget(self.class, "RESOURCE_FILENAME")
    if res then
        self:createResoueceNode(res)
    end

    local binding = rawget(self.class, "RESOURCE_BINDING")
    if res and binding then
        self:createResoueceBinding(binding)
    end

    self:setNetWorkSession()

    if self.onCreate then self:onCreate() end
end

function ViewBase:setNetWorkSession( )
    self.msg_seesion_ = {}

    self.netnode_ = cc.Node:create()
    self:addChild(self.netnode_)

    local function onNodeEvent(event)
        if "enter" == event then
        elseif "exit" == event then
            for _, func in pairs(self.msg_seesion_) do 
                func()
            end
            self.msg_seesion_ = {}
        end
    end
    self.netnode_:registerScriptHandler(onNodeEvent)
end

function ViewBase:sendRequest( name, args, func )
    local lsn = self.network_:sendRequest(name, args, func)
    if lsn then 
        table.insert(self.msg_seesion_, lsn)
    end
end

function ViewBase:listenServerMsg( name, func )
    table.insert(self.msg_seesion_, self.network_:listenServerMsg(name, func))
end

function ViewBase:getApp()
    return self.app_
end

function ViewBase:getName()
    return self.__cname
end

function ViewBase:getResourceNode()
    return self.resourceNode_
end

function ViewBase:createResoueceNode(resourceFilename)
    if self.resourceNode_ then
        self.resourceNode_:removeSelf()
        self.resourceNode_ = nil
    end
    self.resourceNode_ = cc.CSLoader:createNode(resourceFilename)
    assert(self.resourceNode_, string.format("ViewBase:createResoueceNode() - load resouce node from file \"%s\" failed", resourceFilename))
    self:addChild(self.resourceNode_)
end

function ViewBase:createResoueceBinding(binding)
    assert(self.resourceNode_, "ViewBase:createResoueceBinding() - not load resource node")
    for nodeName, nodeBinding in pairs(binding) do
        local node = self.resourceNode_:getChildByName(nodeName)
        if nodeBinding.varname then
            self[nodeBinding.varname] = node
        end
        for _, event in ipairs(nodeBinding.events or {}) do
            if event.event == "touch" then
                node:onTouch(handler(self, self[event.method]))
            end
        end
    end
end

function ViewBase:showWithScene(transition, time, more)
    self:setVisible(true)
    local scene = display.newScene(self.name_)
    scene:addChild(self)
    display.runScene(scene, transition, time, more)
    return self
end

return ViewBase
