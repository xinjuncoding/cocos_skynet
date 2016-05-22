local sprotoparser = require "sprotoparser"

local proto = {}

proto.c2s = sprotoparser.parse( require "proto.c2s" )
proto.s2c = sprotoparser.parse( require "proto.s2c" )

return proto
