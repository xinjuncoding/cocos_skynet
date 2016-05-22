
local FrameCache = cc.SpriteFrameCache:getInstance()

local ActionAnchorPoint = {
    [1] = { 
            [1] = { ["bm"] = cc.p(0.5, 0.4), ["zm"] = cc.p(0.5, 0.3), ["rl"] = cc.p(0.5, 0.2) }, 
            [2] = { ["bm"] = cc.p(0.5, 0.1), ["zm"] = cc.p(0.5, 0.3), ["rl"] = cc.p(0.5, 0.2) }, 
            [3] = { ["bm"] = cc.p(0.5, 0.5), ["zm"] = cc.p(0.5, 0.5), ["rl"] = cc.p(0.5, 0.2) }, 
            [4] = { ["bm"] = cc.p(0.5, 0.4), ["zm"] = cc.p(0.5, 0.5), ["rl"] = cc.p(0.5, 0.2) }, 
    },
}

local ActionOriend = {
    [1] = "bm",
    [2] = "x2",
    [3] = "rl",
    [4] = "x4",
    [5] = "zm",
    [6] = "x4",
    [7] = "rl",
    [8] = "x2",
}

local ActionFactory = {}

function ActionFactory.get_animation(type, actionid, oriend)
    local animFrames = {}
    local str
    for k = 1, 60 do
        local frame = FrameCache:getSpriteFrame("action_"..type.."_"..actionid.."_"..ActionOriend[oriend].."_"..k)
        if frame then 
            animFrames[k] = frame
        else 
            break
        end
    end

    local animation = cc.Animation:createWithSpriteFrames(animFrames, 0.1)
    return cc.Animate:create(animation)
end

function ActionFactory.getFirstSprite( type, oriend )
    local sp = cc.Sprite:createWithSpriteFrameName("action_"..type.."_1_"..ActionOriend[oriend].."_1")
    sp:setAnchorPoint(ActionAnchorPoint[type][1][ActionOriend[oriend]])
    return sp 
end

function ActionFactory.loadtexture( job )
    FrameCache:addSpriteFrames("action/action_"..job.."_1.plist")
    FrameCache:addSpriteFrames("action/action_"..job.."_2.plist")
    FrameCache:addSpriteFrames("action/action_"..job.."_3.plist")
    FrameCache:addSpriteFrames("action/action_"..job.."_4.plist")
end

return ActionFactory

