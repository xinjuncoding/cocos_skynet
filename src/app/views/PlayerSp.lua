
local ActionFactory = import("..tools/ActionFactory")


local TAG_ACTION  = 0
local PlayerSp = class("PlayerSp", cc.Node)

function PlayerSp:ctor( obj )
	self.obj_ = obj
	self.job_ = self.obj_.job 
	self.oriented_ = 3
	self.scale_ = 1

	self.body_ = ActionFactory.getFirstSprite( self.job_, self.oriented_ )
	self:addChild(self.body_)

	self:breath()
end

function PlayerSp:play( action_id, is_loop  )
	self.body_:stopActionByTag(TAG_ACTION)

    local animate = ActionFactory.get_animation(self.job_, action_id, self.oriented_)
    local function endcallback()
    	
   	end
   	local endaction = cc.CallFunc:create(endcallback)
    local action 
    if is_loop then 
    	action = cc.RepeatForever:create(cc.Sequence:create(animate, endaction))
    else 
    	action = cc.Sequence:create(animate, endaction)
    end
    self.current_playing_ = action
    self.current_playing_:setTag(TAG_ACTION)
    self.body_:setVisible(true)
    self.body_:runAction(action)

    if self.oriented_ == 6 or self.oriented_ == 7 or self.oriented_ == 8 then 
    	self.body_:setScaleX(-self.scale_)
    else 
    	self.body_:setScaleX(self.scale_)
    end
    self.body_:setScaleY(self.scale_)
end

function PlayerSp:breath( )
	self:play(1, true)
end

function PlayerSp:run( )
	self:play(3, true)
end


return PlayerSp

