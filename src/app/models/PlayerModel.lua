

local PlayerModel = class("PlayerModel")

function PlayerModel:ctor( )
	self.player_id_ = 0
	self.player_name_ = 0
	self.vip_ 	= 0
	self.level_ = 0 
	self.gold_	= 0
	self.bindgold_ = 0
	self.silver_ = 0
	
	self.role_list_ = {}
end

function PlayerModel:login_get_rolelist( args )
	self.role_list_ = {}

	if args.rolelist then 
		for k,v in pairs(args.rolelist) do 
			self.role_list_[v.player_id] = v
		end
	end
end

function PlayerModel:init_playerinfo( args )
	for k,v in pairs(args) do 
		self[k.."_"] = v
		print("************ init_playerinfo:", k, v)
	end	
end


return PlayerModel