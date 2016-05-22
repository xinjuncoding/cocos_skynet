
local FindPath = FindPath or class("FindPath")

function FindPath:ctor(map, width, height) 
	self.map_ = {}			--地图 
	self.open_ = {}			--开放列表 
	self.start_point_ = nil 
	self.end_point_ = nil 
	self.path_ = {}			--计算出的路径	 
	 
	self.width_ = width
	self.height_ = height
	local value = -1 
	 
	-- 初始化路径记录表 
	for y = 1, self.height_, 1 do 
		if self.map_[self.height_+1-y] == nil then 
			self.map_[self.height_+1-y] = {} 
			for x = 1, self.width_, 1 do 
				local tilev = map[self.width_*(y-1)+x]
				if tilev == 0 then 
					value = 1 
				else 
					value = 0 
				end 
				self.map_[self.height_+1-y][x] = {["x"]=x, ["y"]=self.height_+1-y, ["tile"]=tilev, ["value"]=value, ["block"]=false, ["open"]=false,["value_g"]=0, ["valueheight_"]=0, ["value_f"]=0, ["nodeparent"]=nil} 
			end 
		end 
	end 

end 

function FindPath:getpath_() 
	return self.path_ 
end 

--将0边限制为不可行走区域
function FindPath:canMove( end_Point ) 
	if end_Point == nil or end_Point.value ==1 then 
		print("move error.") 
		return false 
	end 

	if end_Point.y >= self.height_ or end_Point.y < 1 then 
		print("move error. end_Point.y = " .. end_Point.y .. " self.height_ = " .. self.height_ ) 
		return false 
	end 
	 
	if end_Point.x >= self.width_ or end_Point.x < 1 then 
		print("move error. end_Point.x = " .. end_Point.x .. " end_Point.y = " .. end_Point.y .." self.width_ = " .. self.width_) 
		return false 
	end 
	 
	self.end_point_ = self.map_[end_Point.y][end_Point.x] 
	 
	return true 
end 

function FindPath:find(star, end_Point) 
	self.path_ = {} 
	if star.x == 0 then star.x = 1 end 
	if star.y == 0 then star.y = 1 end 

	self.start_point_ = self.map_[star.y][star.x] 
	self.end_point_ = self.map_[end_Point.y][end_Point.x] 

	if self.end_point_ == nil or self.end_point_.value==1 then 
		print("[FindPath] FindPath:find(), 终点不行走")
		return nil 
	end 
	 
	if self.end_point_.x==self.start_point_.x and self.end_point_.y==self.start_point_.y then 
		print("[FindPath] FindPath:find(), 起始点等于结束点，无需寻路") 
		return nil 
	end 
	 
	local __getEnd = false 
	self:initBlock() 

	local __thisNode = self.start_point_ 
	while not __getEnd do 
		__thisNode.block = true 
		local __checkList = {} 
		 
		--左右上下方向 
		if __thisNode.y>1 then 
			table.insert(__checkList, self.map_[(__thisNode.y-1)][__thisNode.x]) 
		end 
		
		if __thisNode.x>1 then 
			table.insert(__checkList, self.map_[__thisNode.y][(__thisNode.x-1)]) 
		end 
		 
		if __thisNode.x < self.width_ - 1 then 
			table.insert(__checkList, self.map_[__thisNode.y][(__thisNode.x+1)]) 
		end 
		 
		if __thisNode.y<self.height_-1 then 
			table.insert(__checkList, self.map_[(__thisNode.y+1)][__thisNode.x]) 
		end 

		--对角方向 
		if __thisNode.y > 1 and __thisNode.x > 1 then 
			table.insert(__checkList, self.map_[(__thisNode.y-1)][(__thisNode.x-1)]) 
		end 
		 
		if __thisNode.y<self.height_ - 1 and __thisNode.x>1 then 
			table.insert(__checkList, self.map_[(__thisNode.y+1)][(__thisNode.x-1)]) 
		end 

		if __thisNode.y>1 and __thisNode.x<self.width_-1 then 
			table.insert(__checkList, self.map_[(__thisNode.y-1)][(__thisNode.x+1)]) 
		end 
		 
		if __thisNode.y<self.height_-1 and __thisNode.x<self.width_-1 then 
			table.insert(__checkList, self.map_[(__thisNode.y+1)][(__thisNode.x+1)]) 
		end 
		 
		--开始检测当前节点周围 
		local __len = #__checkList
		 
		for i = 1, __len, 1 do 
			--周围的每一个节点 
			local __neighboringNode = __checkList[i] 
			--判断是否是目的地 --不是对角线上的节点才和终点比较 why? 
			if __neighboringNode == self.end_point_  
					and (__neighboringNode.y == __thisNode.y or __neighboringNode.x == __thisNode.x) then 
				__neighboringNode.nodeparent = __thisNode 
				__getEnd = true 
				break 
			end 
			--是否可通行 
			if __neighboringNode.value == 0 then 
				self:count(__neighboringNode, __thisNode)--计算该节点 
			end 
		end 
		 
		if not __getEnd then 
			--如果未找到目的地 
			if #self.open_ > 0 then 
				--开发列表不为空，找出F值最小的做为下一个循环的当前节点 
				__thisNode = self.open_[self:getMin()] 
				table.remove(self.open_, self:getMin(), 1) 
			else 
				--开发列表为空，寻路失败 
				print("[FindPath] FindPath:find(), 开放列表为空，寻路失败") 
				return {} 
			end 
		end 
	end 
	self.path_ = { }
	self:drawPath() 

	return self.path_ 
end 

--寻路前的初始化 
function FindPath:initBlock() 
	for y = 1, self.height_ , 1 do 
		for x = 1, self.width_, 1 do 
			self.map_[y][x].open = false 
			self.map_[y][x].block = false 
			self.map_[y][x].value_g = 0 
			self.map_[y][x].valueheight_ = 0 
			self.map_[y][x].value_f = 0 
			self.map_[y][x].nodeparent = nil	 
		end 
	end 

	self.open_ = {} 
end 

--计算每个节点 
function FindPath:count(neighboringNode, centerNode) 
	--是否在关闭列表里 
	if not neighboringNode.block then 
		--不在关闭列表里才开始判断 
		local __g = centerNode.value_g + 10 
		if math.abs(neighboringNode.x-centerNode.x) == 1 and math.abs(neighboringNode.y-centerNode.y) ==1 then 
			__g = centerNode.value_g + 14 
		else 
			__g = centerNode.value_g + 10 
		end 
		 
		--如果当前节点的上下左右四个及节点中有两个相邻节点（如上和右，右和下）是障碍物，则不能直接通过对应的对角线方向 
		--例如当前节点的上和右节点是障碍物，则不能直接走右上的对角线方向，处理的办法是为该g值增加10000 
		if neighboringNode.x > centerNode.x and neighboringNode.y < centerNode.y then 
			if self.map_[neighboringNode.y][neighboringNode.x - 1].value == 1 and self.map_[neighboringNode.y + 1][neighboringNode.x].value == 1 then 
				__g = __g + 10000 
			end 
		elseif neighboringNode.x > centerNode.x and neighboringNode.y > centerNode.y then 
			if self.map_[neighboringNode.y][neighboringNode.x - 1].value == 1 and self.map_[neighboringNode.y - 1][neighboringNode.x].value == 1 then 
				__g = __g + 10000 
			end 
		elseif neighboringNode.x < centerNode.x and neighboringNode.y > centerNode.y then 
			if self.map_[neighboringNode.y][neighboringNode.x + 1].value == 1 and self.map_[neighboringNode.y - 1][neighboringNode.x].value == 1 then 
				__g = __g + 10000 
			end 
		elseif neighboringNode.x < centerNode.x and neighboringNode.y < centerNode.y then 
			if self.map_[neighboringNode.y + 1][neighboringNode.x].value == 1 and self.map_[neighboringNode.y][neighboringNode.x + 1].value == 1 then 
				__g = __g + 10000 
			end 
		end 
		if neighboringNode.open then 
			--如果该节点已经在开放列表里 
			if neighboringNode.value_g>=__g then 
				--如果新G值小于或者等于旧值，则表明该路更优，更新其值 
				neighboringNode.value_g = __g 
				self:ghf(neighboringNode) 
				neighboringNode.nodeparent = centerNode 
			end 
		else 
			--如果该节点未在开放列表里 
			--添加至列表 
			self:addToOpen(neighboringNode) 
			--计算GHF值 
			neighboringNode.value_g = __g 
			self:ghf(neighboringNode) 
			neighboringNode.nodeparent = centerNode 
		end 
	end 
end 

--画路径 
function FindPath:drawPath() 
	local _path_Node = self.end_point_ 
	--倒过来得到路径 
	while _path_Node.x ~= self.start_point_.x or _path_Node.y ~= self.start_point_.y do 
		table.insert(self.path_, 1, cc.p(_path_Node.x, _path_Node.y)) 
		_path_Node = _path_Node.nodeparent 
	end 

	table.insert(self.path_, 1, cc.p(_path_Node.x, _path_Node.y)) 
end 

--加入开放列表 
function FindPath:addToOpen(newNode) 
	table.insert(self.open_, newNode) 
	newNode.open = true 
end 

--计算ghf各值 
function FindPath:ghf(node) 
	local __dx = math.abs(node.x-self.end_point_.x) 
	local __dy = math.abs(node.y-self.end_point_.y) 
	node.value_h = 10*(__dx+__dy) 
	node.value_f = node.value_g+node.value_h 
end 
--得到开放列表里拥有最小F值的节点在列表里的位置 
function FindPath:getMin() 
	local __len = #self.open_
	local __f = 100000 
	local __i = 0 
	 
	for i = 1, __len, 1 do 
		if __f>self.open_[i].value_f then 
			__f = self.open_[i].value_f 
			__i = i 
		end 
	end 
	 
	return __i 
end 

return FindPath

