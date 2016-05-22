
local LoginController = class("LoginController", import("..ControlBase"))

LoginController.REQUEST_BINDING = {
	["annnoucelist"] = LoginController.annouce,
}

function LoginController:ctor(  )
	
end


function LoginController:annouce( args )
	
end

return LoginController

