
local FrameCache = cc.SpriteFrameCache:getInstance()
local PlayerSp = import(".PlayerSp")
local ActionFactory = import("..tools/ActionFactory")


local GameScene = class("GameScene", cc.load("mvc").ViewBase)

function GameScene:onCreate( )
    ActionFactory.loadtexture( 1 )

    self:initmap()

    -- aoi 数据
    self.aoi_obj_list_ = {}
    self.monster_list_ = {}
    self.npc_list_ 	   = {}
    self.player_list_  = {}
end

function GameScene:onEnter( )
    -- 请求后端进入场景
    local args = {
    	scene_id = self.player_.scene_id_,
    	x 		 = self.player_.pos_x_,
    	y 		 = self.player_.pos_y_,
	}
    self:sendRequest("scene_enter", args)

    -- 开始侦听场景aoi数据
    self:listenServerMsg("scene_aoi_list", handler(self, self.sceneAoiList))
    print("[加载场景成功, 请求服务端进入场景, 并且开始同步aoi数据......]")
end

-- 同步场景aoi数据
function GameScene:sceneAoiList( args )
	print("[GameScene 同步场景aoi数据中 ...................]" )
	for k,v in pairs(args.obj_list) do 
		print("同步数据, objid:",v.objid)
		self.aoi_obj_list_[v.objid] = v

		-- 在此处理aoi数据同步前端逻辑
		-- ...
	end
end

function GameScene:initmap()
    self.map_layer_ = display.newLayer():addTo(self)

    self.map_bg_ = display.newSprite("battlescene_1.jpg")
        :move(display.center)
        :addTo(self.map_layer_)

    self.map_layer_:onTouch(handler(self, self.mapMoveHandle), false, true)

    local player = PlayerSp:create({job=1}):move(display.center):addTo(self.map_layer_)
end

function GameScene:mapMoveHandle( event )
    local x = event.x
    local y = event.y
    
end


return GameScene

