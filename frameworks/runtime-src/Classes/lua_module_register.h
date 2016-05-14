#ifndef __LUA_TEMPLATE_RUNTIME_FRAMEWORKS_RUNTIME_SRC_CLASSES_LUA_MODULE_REGISTER_H__
#define __LUA_TEMPLATE_RUNTIME_FRAMEWORKS_RUNTIME_SRC_CLASSES_LUA_MODULE_REGISTER_H__

#include "lua.h"
#include "scripting/lua-bindings/manual/Lua-BindingsExport.h"

CC_LUA_DLL  int  lua_module_register(lua_State* L);

extern "C" {
CC_LUA_DLL  int luaopen_sproto_core(lua_State *L);
CC_LUA_DLL  int luaopen_lpeg (lua_State *L);
CC_LUA_DLL  int luaopen_clientsocket(lua_State *L);
}

#endif  // __LUA_TEMPLATE_RUNTIME_FRAMEWORKS_RUNTIME_SRC_CLASSES_LUA_MODULE_REGISTER_H__

